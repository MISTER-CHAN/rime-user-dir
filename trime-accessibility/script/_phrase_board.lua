require "import"
import "android.graphics.drawable.StateListDrawable"
import "android.os.*"
import "android.util.TypedValue"
import "android.view.*"
import "android.view.inputmethod.InputMethodManager"
import "android.widget.*"
import "com.osfans.trime.*"

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local function Back(color)
	color = color or backColor
	local stb = StateListDrawable()
	stb.addState({
		-android.R.attr.state_pressed
	}, LuaDrawable(function(c, p, d)
		local b = d.bounds
		p.setColor(color)
		c.drawRect(b.left, b.top, b.right, b.bottom, p)
	end))
	stb.addState({
		android.R.attr.state_pressed
	}, LuaDrawable(function(c, p, d)
		local b = d.bounds
		p.setColor(hilitedBackColor)
		c.drawRect(b.left, b.top, b.right, b.bottom, p)
	end))
	return stb
end

local views = {}
local data, dataOl = {}, {}

local json = require "cjson"
local f
f = io.open(service.LuaDir .. "/phrase.json", "r")
local phrase = json.decode(f:read("*a"))
f:close()
f = io.open(service.LuaDir .. "/phrase_ol.json", "r")
local phraseOl = json.decode(f:read("*a"))
f:close()
f = nil

local item, itemContents = {
	LinearLayout,
	layout_width = "match",
	layout_height = "47dp",
	BackgroundColor = backColor,
	elevation = "4dp",
	{
		TextView,
		id = "tv",
		layout_width = "match",
		layout_height = "match",
		backgroundResource = backgroundRId,
		gravity = "left|center",
		MaxLines = 2,
		paddingLeft = "8dp",
		paddingRight = "8dp",
		textColor = textColor,
		textSize = "16sp"
	}
},
{
	LinearLayout,
	layout_width = "match",
	layout_height = "44dp",
	BackgroundColor = backColor,
	elevation = "4dp",
	{
		LinearLayout,
		id = "ll",
		layout_width = "match",
		layout_height = "match",
		backgroundResource = backgroundRId,
		gravity = "center",
		{
			TextView,
			id = "tv",
			layout_width = "0dp",
			layout_height = "wrap",
			layout_weight = 1,
			MaxLines = 2,
			paddingLeft = "8dp",
			paddingRight = "8dp",
			textColor = textColor,
			textSize = "16sp"
		},
		{
			TextView,
			layout_width = "wrap",
			layout_height = "wrap",
			paddingRight = "16dp",
			text = "＞",
			textColor = textColor,
			textSize = "16sp"
		}
	}
}

local adapter, adapterOlContents, adapterOl =
	LuaAdapter(service, data, item),
	LuaAdapter(service, itemContents),
	LuaAdapter(service, dataOl, item)

local function addPhrase()
	service.setInputView(service.getRootView())
	LuaDialog(service)
		.setTitle("新增")
		.setView(loadlayout({
			LinearLayout,
			layout_width = "match",
			layout_height = "wrap",
			padding = "24dp",
			{
				EditText,
				id = "et",
				layout_width = "match",
				layout_height = "wrap"
			}
		}, views))
		.setPositiveButton("確定", function ()
			service.loadPhrase()
			service.addPhrase(views.et.text)
			table.insert(phrase, 1, views.et.text)
			print("已新增短語")
		end)
		.setNegButton("取消")
		.show()
	views.et.requestFocus()
end

local function editPhrase(position)
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
				layout_width = "match",
				layout_height = "wrap",
				text = phrase[position]
			}
		}, views))
		.setPositiveButton("確定", function ()
			phrase[position] = views.et.text
			io.open(service.LuaDir .. "/phrase.json", "w"):write(json.encode(phrase)):close()
			print("已編輯短語")
		end)
		.setNegButton("取消")
		.show()
	views.et.requestFocus()
end

local function refresh()
	table.clear(data)
	for k, v in ipairs(phrase) do
		data[k] = {
			tv = {
				text = v:sub(1, 0x100)
			}
		}
	end
	adapter.notifyDataSetChanged()
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
		elevation = "4dp",
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
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			{
				Button,
				id = "tab",
				layout_width = "wrap",
				layout_height = "match",
				background = Back(hilitedBackColor),
				gravity = "center",
				text = "常用",
				textColor = textColor,
				textSize = "16sp",
				onClick = function (v, e)
					v.background = Back(hilitedBackColor)
					views.t_ol.background = Back()
					views.lv.bringToFront()
					views.b_add.visibility = View.VISIBLE
				end
			},
			{
				Button,
				id = "t_ol",
				layout_width = "wrap",
				layout_height = "match",
				background = Back(),
				gravity = "center",
				text = "已下載",
				textColor = textColor,
				textSize = "16sp",
				onClick = function (v, e)
					v.background = Back(hilitedBackColor)
					views.tab.background = Back()
					views.b_add.visibility = View.INVISIBLE
					views.gv_ol_contents.bringToFront()
					views.lv_ol.smoothScrollToPosition(0)
				end
			}
		},
		{
			Button,
			id = "b_add",
			layout_width = "10%w",
			layout_height = "match",
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "＋",
			textColor = textColor,
			onClick = function(v, e)
				addPhrase()
			end
		}
	},
	{
		FrameLayout,
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		layout_weight = 1,
		{
			ListView,
			id = "lv",
			layout_width = "match",
			layout_height = "match",
			adapter = adapter,
			backgroundColor = backColor,
			clipToPadding = false,
			padding = "8dp"
		},
		{
			GridView,
			id = "gv_ol_contents",
			layout_width = "match",
			layout_height = "match",
			adapter = adapterOlContents,
			backgroundColor = backColor,
			clipToPadding = false,
			horizontalSpacing = "4dp",
			numColumns = 2,
			padding = "8dp",
			verticalSpacing = "4dp"
		},
		{
			ListView,
			id = "lv_ol",
			layout_width = "match",
			layout_height = "match",
			adapter = adapterOl,
			backgroundColor = backColor,
			clipToPadding = false,
			padding = "8dp"
		}
	}
}, views)

views.lv.onItemClick = function(parent, view, position, id)
	position = position + 1
	local s = phrase[position]
	service.commitText(s)
	if position > 1 then
		table.remove(phrase, position)
		table.insert(phrase, 1, s)
		io.open(service.LuaDir .. "/phrase.json", "w"):write(json.encode(phrase)):close()
		refresh()
	end
end

views.lv.onItemLongClick = function(parent, view, position, id)
	position = position + 1
	local s = phrase[position]
	LuaDialog(service)
		.setTitle("預覽")
		.setView(loadlayout({
			TextView,
			padding = "16dp",
			textIsSelectable = true,
			text = utf8.sub(s, 1, 0x1000) .. (utf8.len(s) > 0x1000 and "\n..." or ""),
		 }))
		.setButton("置頂", function()
			if position > 1 then
				table.remove(phrase, position)
				table.insert(phrase, 1, s)
				io.open(service.LuaDir .. "/phrase.json", "w"):write(json.encode(phrase)):close()
				refresh()
			end
		end)
		.setButton2("編輯", function()
			editPhrase(position)
			io.open(service.LuaDir .. "/phrase.json", "w"):write(json.encode(phrase)):close()
			refresh()
		end)
		.setButton3("刪除", function()
			table.remove(phrase, position)
			io.open(service.LuaDir .. "/phrase.json", "w"):write(json.encode(phrase)):close()
			refresh()
		end)
		.show()
	return true
end

views.gv_ol_contents.onItemClick = function (parent, view, position, id)
	table.clear(dataOl)
	if not Rime.getOption("simplification") then
		for k, v in ipairs(phraseOl[position + 1].phrase) do
			dataOl[k] = {
				tv = {
					text = v
				}
			}
		end
	else
		for k, v in ipairs(phraseOl[position + 1].phrase) do
			dataOl[k] = {
				tv = {
					text = Rime.openccConvert(v, "t2s.json")
				}
			}
		end
	end
	adapterOl.notifyDataSetChanged()
	views.lv_ol.bringToFront()
end

views.lv_ol.onItemClick = function (parent, view, position, id)
	service.commitText(view.getChildAt(0).text)
end

views.lv.bringToFront()

refresh()

for k, v in ipairs(phraseOl) do
	adapterOlContents.add({
		ll = {
			
		},
		tv = {
			text = v.name
		}
	})
end

service.sendEvent("Keyboard_last")
service.setInputView(contentView)