require "import"
import "android.os.*"
import "android.util.TypedValue"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local json = require "cjson"
local f = io.open(service.LuaDir .. "/sheet_lines.json", "r")
local sheetLines = json.decode(f:read("*a"))
f:close()
f = nil

local data = {}
local views = {}

local adapter = LuaAdapter(service, data, {
	LinearLayout,
	layout_width = "match",
	layout_height = "52dp",
	BackgroundColor = backColor,
	elevation = "2dp",
	{
		TextView,
		id = "tv",
		layout_width = "match",
		layout_height = "match",
		backgroundResource = backgroundRId,
		gravity = "center_vertical",
		MaxLines = 1,
		padding = "4dp",
		textColor = textColor,
		textSize = "16sp",
	}
})

local function refresh()
	table.clear(data)
	for k, v in ipairs(sheetLines) do
		data[k] = {
			tv = v:gsub("{Tab}", " | ")
		}
	end
	adapter.notifyDataSetChanged()
end

local function addSheetLine()
	service.setInputView(service.getRootView())
	LuaDialog(service)
		.setTitle("新增")
		.setView(loadlayout({
			LinearLayout,
			layout_width = "match",
			layout_height = "wrap",
			orientation = "horizontal",
			padding = "24dp",
			{
				EditText,
				id = "et",
				layout_width = "0dp",
				layout_height = "wrap",
				layout_weight = 1
			},
			{
				Button,
				layout_width = "10%w",
				layout_height = "wrap",
				text = "|",
				onClick = function (v)
					views.et.append(" | ")
				end
			}
		}, views))
		.setPositiveButton("確定", function ()
			local line = views.et.text:gsub(" ?%| ?", "{Tab}")
			table.insert(sheetLines, 1, line)
			io.open(service.LuaDir .. "/sheet_lines.json", "w"):write(json.encode(sheetLines)):close()
			print("已新增行")
		end)
		.setNegButton("取消")
		.show()
	views.et.requestFocus()
end

local function editSheetLine(position)
	service.setInputView(service.getRootView())
	LuaDialog(service)
		.setTitle("編輯")
		.setView(loadlayout({
			LinearLayout,
			layout_width = "match",
			layout_height = "wrap",
			padding = "24dp",
			{
				EditText,
				id = "et",
				layout_width = "0dp",
				layout_height = "wrap",
				layout_weight = 1,
				text = data[position].tv
			},
			{
				Button,
				layout_width = "10%w",
				layout_height = "wrap",
				text = "|",
				onClick = function (v)
					views.et.append(" | ")
				end
			}
		}, views))
		.setPositiveButton("確定", function ()
			local line = views.et.text:gsub(" ?%| ?", "{Tab}")
			sheetLines[position] = line
			io.open(service.LuaDir .. "/sheet_lines.json", "w"):write(json.encode(sheetLines)):close()
			print("已編輯行")
		end)
		.setNegButton("取消")
		.show()
	views.et.requestFocus()
end

local contentView = loadlayout({
	LinearLayout,
	layout_height = "match",
	layout_width = "match",
	BackgroundColor = keyboardBackColor,
	orientation = "vertical",
	{
		LinearLayout,
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
		layout_weight = 5,
		BackgroundColor = backColor,
		elevation ="4dp",
		{
			Button,
			layout_width = "10%w",
			layout_height = "match",
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "＜",
			textColor = textColor,
			onClick = function(v, e)
				service.setInputView(service.getRootView())
			end
		},
		{
			TextView,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center",
			text = "塡表",
			textColor = textColor,
			textSize = "16sp"
		},
		{
			Button,
			layout_width = "10%w",
			layout_height = "match",
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "＋",
			textColor = textColor,
			onClick = function(v, e)
				addSheetLine()
			end
		}
	},
	{
		ListView,
		id = "lv",
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		layout_weight = 1,
		adapter = adapter,
		clipToPadding = false,
		padding = "8dp",
	}
}, views)

views.lv.onItemClick = function(parent, view, position, id)
	position = position + 1
	local s = sheetLines[position]
	service.sendEvent(s)
end

views.lv.onItemLongClick = function(parent, view, position, id)
	position = position + 1
	local s = sheetLines[position]
	LuaDialog(service)
		.setTitle("預覽")
		.setView(loadlayout({
			TextView,
			padding = "16dp",
			textIsSelectable = true,
			text = data[position].tv
		 }))
		.setButton("置頂", function()
			if position > 1 then
				table.remove(sheetLines, position)
				table.insert(sheetLines, 1, s)
				io.open(service.LuaDir .. "/sheet_lines.json", "w"):write(json.encode(sheetLines)):close()
				refresh()
			end
		end)
		.setButton2("編輯", function()
			editSheetLine(position)
			io.open(service.LuaDir .. "/sheet_lines.json", "w"):write(json.encode(sheetLines)):close()
			refresh()
		end)
		.setButton3("刪除", function()
			table.remove(sheetLines, position)
			io.open(service.LuaDir .. "/sheet_lines.json", "w"):write(json.encode(sheetLines)):close()
			refresh()
		end)
		.show()
	return true
end

refresh()

service.setInputView(contentView)