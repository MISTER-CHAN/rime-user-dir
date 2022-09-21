require "import"

local arg = ...
if arg ~= "schema" then
	Rime.select_schema(arg)
	if service.isLandscape() then
		io.open(service.LuaDir .. "/schema_switching.txt", "w"):write("1"):close()
		service.sendEvent("Hide")
	end
	return
end

import "android.app.*"
import "android.util.TypedValue"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"
import "java.io.File"
import "java.text.SimpleDateFormat"
import "yaml"

local sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local views = {}

local layout = {
	LinearLayout,
	layout_width = "match",
	layout_height = "match",
	paddingBottom = "24dp",
	paddingTop = "24dp",
	{
		ScrollView,
		layout_width = "match",
		layout_height = "match",
		id = "sv",
		{
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			id = "ll_list",
			orientation = "vertical",
			paddingBottom = "24dp"
		}
	}
}
local list = layout[2][2]

local contentView = loadlayout(layout, views)

local dialog = LuaDialog(service)
	.setTitle("TRIME 輸入法")
	.setView(contentView)
	.setButton("設定", function()
		service.sendEvent("Settings")
	end)
	.setButton2("導入方案", function()
		service.sendEvent("Schema_settings")
	end)

local function checkUpdate(resource, id, name, branch)
	branch = branch or "master"
	print("請稍候")
	Http.get("https://github.com/" .. resource, function (code, content, cookie, header)
		if code // 100 == 2 then
			local view = {
				ScrollView,
				layout_width = "match",
				layout_height = "match",
				padding = "16dp",
				{
					LinearLayout,
					layout_width = "match",
					layout_height = "wrap",
					orientation = "vertical",
				}
			}
			local ll = view[2]
			local s = content:match(" <relative%-time datetime=\"(.-)\" class=\"no%-wrap\">.-</relative%-time>\n")
			if s ~= nil then
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					text = "最新版本發佈時間："
				}
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					text = s:gsub("[TZ]", " "),
					textColor = 0xff000000,
					textSize = "30sp"
				}
			end
			local b = true
			local f = {}
			local lm = 0
			for name, description, time in content:gmatch("<a class=\"js%-navigation%-open Link%-%-primary\" title=\"(.-)\" data%-pjax=\"#repo%-content%-pjax%-container\".-<a data%-pjax=\"true\" title=\"(.-)\".-<time%-ago datetime=\"(.-)\" data%-view%-component=\"true\"") do
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					maxLines = 1,
					text = name,
					textColor = 0xff000000,
					textSize = "22.5"
				}
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					textColor = 0xff000000
				}
				time = time:gsub("[TZ]", " ")
				f = File("/sdcard/Android/rime/" .. name)
				if f.exists() and not f.isDirectory()  then
					lm = f.lastModified()
					if sdf.parse(time).getTime() > lm then
						time = time .. " ← " .. sdf.format(lm)
						ll[#ll].textColor = 0xffff0000
					end
				end
				ll[#ll].text = time
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					layout_marginBottom = "8dp",
					text = description
				}
				b = false
			end
			if b then
				b = true
				for time in content:gmatch("datetime=\"(.-)\"") do
					ll[#ll + 1] = {
						TextView,
						layout_width = "match",
						layout_height = "wrap",
					}
					time = time:gsub("[TZ]", " ")
					f = File("/sdcard/Android/rime/" .. name)
					if f.exists() and not f.isDirectory() then
						lm = f.lastModified()
						if sdf.parse(time).getTime() > lm then
							time = time .. " ← " .. sdf.format(lm)
							ll[#ll].textColor = 0xffff0000
						end
					end
					ll[#ll].text = time
					b = false
				end
			end
			if s == nil and b then
				ll[#ll + 1] = {
					TextView,
					layout_width = "match",
					layout_height = "wrap",
					gravity = "center",
					text = "無法獲取詳細資訊"
				}
			end
			LuaDialog(service)
				.setTitle(name)
				.setView(loadlayout(view))
				.setButton("覆蓋安裝", function ()
					local httpTask = Http.download("https://github.com/" .. resource .. "/archive/refs/heads/" .. branch .. ".zip", "/sdcard/download/" .. id .. "-" .. branch .. ".zip", function ()
						httpTask = nil
						ZipUtil.unzip("/sdcard/download/" .. id .. "-" .. branch .. ".zip", "/sdcard/download/" .. id .. "-" .. branch .. "/")
						local files = File("/sdcard/download/" .. id .. "-" .. branch .. "/" .. id .. "-" .. branch .. "/").listFiles()
						for i = 0, #files - 1 do
							local file = files[i]
							local name = file.getName()
							if name ~= "AUTHORS" and name:find("LICENSE") == nil and name:find("README") == nil and name:find("^%.") == nil and name ~= "demo" then
								LuaUtil.copyDir(file, File(service.getLuaDir() .. "/" .. name))
							end
						end
						File("/sdcard/download/" .. id .. "-" .. branch .. ".zip").delete()
						LuaUtil.rmDir(File("/sdcard/download/" .. id .. "-" .. branch .. "/"))
						downloadDialog.dismiss()
						LuaDialog(service)
							.setTitle(name)
							.setMessage("完成")
							.setPositiveButton("部署", function ()
								Rime.deploy()
								LuaDialog(service)
									.setTitle(name)
									.setMessage("完成")
									.show()
							end)
							.setNegButton("稍後")
							.show()
					end)
					local f = File("/sdcard/download/" .. id .. "-" .. branch .. ".zip")
					downloadDialog = {}
					local function showProgress(show)
						if show then
							local b = f.length()
							print("已下載：\n  " .. b .. " B\n= " .. b / 1024 .. " KiB\n= " .. b / 1024 / 1024 .. " MiB")
						end
						downloadDialog = LuaDialog(service)
						.setTitle(name)
						.setMessage("下載中")
						.setPositiveButton("進度", function ()
							showProgress(true)
						end)
						.setNegativeButton("中止", function ()
							httpTask.cancel()
							httpTask = nil
							f.delete()
							f = nil
							print("已中止任務並刪除文件")
						end)
						.setCancelable(false)
						.show()
					end
					showProgress(false)
				end)
				.show()
		else
			LuaDialog(service)
				.setTitle(name)
				.setMessage("錯誤：" .. code)
				.show()
		end
	end)
end

local function selectSchema(index)
	dialog.dismiss()
	updateComposing = nil
	service.sendEvent("Keyboard_default")
	Rime.selectSchema(tonumber(index))
	if Rime.getSchemaIds()[index] == "english" then
		function updateComposing(i, c)
			if c:find(" ") ~= nil then
				local comp = Rime.getComposingText()
				local s = c:find(" ")
				repeat
					if comp:sub(s + 1, s+ 1) ~= "'" then
						comp = comp:sub(1, s - 1) .. " " .. comp:sub(s)
					end
					s = c:find(" ", s + 1)
				until s == nil
				service.addCandidates({comp})
			end
		end
	end
	if service.isLandscape() then
		service.sendEvent("Hide")
	end
end

local itemLayout = {
	LinearLayout,
	id = "ll",
	layout_width = "match",
	layout_height = "match",
	backgroundResource = backgroundRId,
	gravity = "center",
	paddingLeft = "24dp",
	onClick = function (v, e)
		selectSchema(v.tag)
	end,
	onLongClickListener = {
		onLongClick = function (v, e)
			local id = Rime.getSchemaIds()[v.tag]
			local resources = {
				bopomofo = "rime/rime-bopomofo",
				cangjie5 = "rime/rime-cangjie",
				english = "BlindingDark/rime-easy-en",
				ipa_xampa = "rime/rime-ipa",
				jyut6ping3 = "rime/rime-cantonese",
				pinyin = "rime/rime-luna-pinyin",
				quick5 = "rime/rime-quick",
				stroke = "rime/rime-stroke",
				wubi86 = "rime/rime-wubi"
			}
			local resource = resources[id]
			local name = Rime.getSchemaNames()[v.tag]
			local branch = "master"
			if id == "jyut6ping3" then
				branch = "main"
			end
			if resource ~= nil then
				local function f()
					checkUpdate(resource, resource:match("/([^/]+)"), name, branch)
				end
				local d = LuaDialog(service)
					.setTitle(name)
				if id == "bopomofo" then
					d.setButton("檢査更新：注音", f)
					d.setButton2("檢査更新：地球拼音", function ()
						checkUpdate("rime/rime-terra-pinyin", "rime-terra-pinyin", name)
					end)
				elseif id == "english" then
					d.setButton("檢査更新：Easy English", f)
				elseif id == "pinyin" then
					d.setButton("檢査更新：朙月拼音", f)
				else
					d.setButton("檢査更新", f)
				end
				d.show()
			end
			return true
		end
	},
	{
		RadioButton,
		layout_width = "wrap",
		layout_height = "match",
		id = "rb",
		checked = false,
		padding = "8dp",
		onClick = function (v, e)
			selectSchema(v.tag)
		end
	},
	{
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		layout_weight = 1,
		orientation = "vertical",
		padding = "8dp",
		{
			TextView,
			layout_width = "wrap",
			layout_height= "wrap",
			id = "subtitle"
		},
		{
			TextView,
			layout_width = "wrap",
			layout_height = "wrap",
			id = "title",
			textColor = 0xff000000,
			textSize = "20sp"
		}
	}
}

local section = {
	TextView,
	layout_width = "match",
	layout_height = "wrap",
	paddingLeft = "32dp",
	paddingTop = "36dp",
	paddingBottom = "8dp"
}

views.ll_list.addView(loadlayout(section).setText("必需品"))
local prelude = {}
views.ll_list.addView(loadlayout(itemLayout, prelude))
prelude.ll.onClick = function (v, e)
end
prelude.ll.onLongClickListener = {
	onLongClick = function (v, e)
		LuaDialog(service)
			.setTitle("基礎配置")
			.setButton("檢査更新", function ()
				checkUpdate("rime/rime-prelude", "rime-prelude", "基礎配置")
			end)
			.show()
		return true
	end
}
prelude.rb.visibility = View.GONE
prelude.subtitle.visibility = View.GONE
prelude.title.text = "基礎配置"
local essay = {}
views.ll_list.addView(loadlayout(itemLayout, essay))
essay.ll.onClick = function (v, e)
end
essay.ll.onLongClickListener = {
	onLongClick = function (v, e)
		LuaDialog(service)
			.setTitle("八股文")
			.setButton("檢査更新", function ()
				checkUpdate("rime/rime-essay", "rime-essay", "八股文")
			end)
			.show()
		return true
	end
}
essay.rb.visibility = View.GONE
essay.subtitle.visibility = View.GONE
essay.title.text = "八股文"
views.ll_list.addView(loadlayout(section).setText("輸入法方案"))
local index = Rime.getSchemaIndex()
local names = Rime.getSchemaNames()
local name = Rime.getSchemaName()
local selected = 0
for i = 0, #names - 1 do
	local s = names[i]
	local item = {}
	local llItem = loadlayout(itemLayout, item)
	if s:find("%[.*%]$") == nil then
		local a, b = "", ""
		if s:find("-") ~= nil then
			a = s:match("(.*) ?%- ?.*")
			b = s:match(".* ?%- ?(.*)")
		else
			b = s
		end
		if i == index or s == name:gsub(" ?%[.*%] ?$", "") then
			item.rb.checked = true
			selected = i
		end
		if a ~= "" and a ~= nil then
			item.subtitle.text = a
		else
			item.subtitle.visibility = View.GONE
		end
		item.title.text = b
		item.ll.tag = i
		item.rb.tag = i
	else
		item.ll.visibility = View.GONE
	end
	views.ll_list.addView(llItem)
end
views.ll_list.addView(loadlayout(section).setText("雜項"))
local emoji = {}
views.ll_list.addView(loadlayout(itemLayout, emoji))
emoji.ll.onClick = function (v, e)
end
emoji.ll.onLongClickListener = {
	onLongClick = function (v, e)
		LuaDialog(service)
			.setTitle("繪文字")
			.setButton("檢査更新", function ()
				checkUpdate("rime/rime-emoji", "rime-emoji", "繪文字")
			end)
			.show()
		return true
	end
}
emoji.rb.visibility = View.GONE
emoji.subtitle.visibility = View.GONE
emoji.title.text = "繪文字濾鏡"
views.sv.post(function ()
	views.sv.scrollTo(0, views.ll_list.getChildAt(selected + 4).getTop() + views.ll_list.getChildAt(selected).getHeight() / 2 - views.sv.getHeight() / 2)
end)

dialog.show()
