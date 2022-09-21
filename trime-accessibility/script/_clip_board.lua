require "import"
import "android.os.*"
import "android.util.TypedValue"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*" --载入包

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local data = {}
local views = {}

local json = require "cjson"
local f = io.open(service.LuaDir .. "/clipboard.json", "r")
local clipboard = json.decode(f:read("*a"))
f:close()
f = nil

local adapter = LuaAdapter(service, data, {
	LinearLayout,
	layout_width = "match",
	layout_height = "52dp",
	backgroundColor = backColor,
	elevation = "2dp",
	{
		TextView,
		id = "tv",
		layout_width = "fill",
		layout_height = "fill",
		backgroundResource = backgroundRId,
		gravity = "center_vertical",
		MaxLines = 2,
		padding = "4dp",
		textColor = textColor,
		textSize = "16sp"
	}
})

local contentView = loadlayout({
	LinearLayout,
	layout_height = "match",
	layout_width = "match",
	backgroundColor = keyboardBackColor,
	orientation = "vertical",
	{
		LinearLayout,
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
		layout_weight = 5,
		backgroundColor = backColor,
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
			text = "剪貼板",
			textColor = textColor,
			textSize = "16sp"
		},
		{
			View,
			layout_width = "10%w",
			layout_height = "match",
		}
	},
	{
		GridView,
		id = "gv",
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		layout_weight = 1,
		adapter = adapter,
		clipToPadding = false,
		horizontalSpacing = "8dp",
		numColumns = 2,
		padding = "8dp",
		verticalSpacing = "8dp"
	}
}, views)

local function refresh()
	table.clear(data)
	for k, v in ipairs(clipboard) do
		data[k] = {
			tv = v:sub(1, 0x100)
		}
	end
	adapter.notifyDataSetChanged()
end

views.gv.onItemClick = function(parent, view, position, id)
	position = position + 1
	local s = clipboard[position]
	service.commitText(s)
	if position > 1 then
		table.remove(clipboard, position)
		table.insert(clipboard, 1, s)
		io.open(service.LuaDir .. "/clipboard.json", "w"):write(json.encode(clipboard)):close()
		refresh()
	end
end

views.gv.onItemLongClick = function(parent, view, position, id)
	position = position + 1
	local s = clipboard[position]
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
				table.remove(clipboard, position)
				table.insert(clipboard, 1, s)
				io.open(service.LuaDir .. "/clipboard.json", "w"):write(json.encode(clipboard)):close()
				refresh()
			end
		end)
		.setButton2("刪除", function()
			table.remove(clipboard, position)
			io.open(service.LuaDir .. "/clipboard.json", "w"):write(json.encode(clipboard)):close()
			refresh()
		end)
		.show()
	return true
end

refresh()

service.setInputView(contentView)