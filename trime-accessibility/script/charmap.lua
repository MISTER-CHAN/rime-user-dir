require "import"
import "android.util.TypedValue"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*" --载入包

local arg = ...

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7

local numColumns = service.isLandscape() and 0x20 or 0x10

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local ranges = {"U+0000 ~ U+0FFF", "U+1000 ~ U+1FFF", "U+2000 ~ U+2FFF", "U+3000 ~ U+3FFF", "U+4000 ~ U+9FFF", "U+A000 ~ U+AFFF", "U+B000 ~ U+EFFF", "U+F000 ~ U+FFFF", "U+10000 ~ U+10FFFF"}

local data = {}
local views = {}

local adapter = LuaAdapter(service, data, {
	TextView,
	layout_width = -1,
	layout_height = -1,
	id = "char",
	gravity = 17,
	textColor = textColor
})

local function showChars(code)
	table.clear(data)
	for c = code, code + 0xff
		data[#data + 1] = {
			char = utf8.char(c)
		}
	end
	adapter.notifyDataSetChanged()
	views.gv.tag = code
	views.et.text = string.format("%04X", code)
	views.gv.requestFocus()
end

local function setSpinnerSelection()
	local p = views.gv.tag
	local c = #ranges
	for i = 1, c do
		if tonumber(ranges[i]:match("U%+([0-9A-F]+) ~ U%+[0-9A-F]+"), 16) <= p
			and p < tonumber(ranges[i]:match("U%+[0-9A-F]+ ~ U%+([0-9A-F]+)"), 16) then
			views.s.setSelection(i - 1)
			break
		end
	end
end

local contentView = loadlayout({
	LinearLayout,
	layout_width = "fill",
	layout_height = "wrap",
	id = "ll",
	BackgroundColor = backColor,
	orientation = "vertical",
	{
		LinearLayout,
		layout_width = -1,
		layout_height = -2,
		BackgroundColor = backColor,
		elevation = "4dp",
		padding = "8dp",
		{
			Button,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 2,
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "＜",
			textColor = textColor,
			onClick = function ()
				service.sendEvent("Keyboard_default")
				service.setInputView(service.getRootView())
			end
		},
		{
			EditText,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 1,
			id = "et",
			textColor = textColor
		},
		{
			LinearLayout,
			layout_width = -1,
			layout_height = -1,
			layout_weight = 2,
			{
				Spinner,
				layout_width = -1,
				layout_height = -1,
				id = "s",
				Adapter = ArrayAdapter(service, android.R.layout.simple_spinner_dropdown_item, ranges),
				padding = "0dp",
				OnItemSelectedListener = {
					onItemSelected = function (parent, view, position, id)
						local p = views.gv.tag
						local from = tonumber(ranges[position + 1]:match("U%+([0-9A-F]+) ~ U%+[0-9A-F]+"), 16)
						local to = tonumber(ranges[position + 1]:match("U%+[0-9A-F]+ ~ U%+([0-9A-F]+)"), 16)
						if p < from or to < p then
							showChars(from)
						end
					end
				}
			}
		},
		{
			Button,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 2,
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "→",
			textColor = textColor,
			onClick = function (v, e)
				local s = views.et.text
				local c = 0
				if s:find("^[0-9A-Fa-f]+$") ~= nil then
					c = tonumber(s, 16)
				else
					c = utf8.codepoint(s)
				end
				showChars(math.floor(c / 0x100) * 0x100)
				setSpinnerSelection()
			end
		},
		{
			Button,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 2,
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "⌫",
			textColor = textColor,
			onClick = function (v, e)
				local et = views.et.text
				if not views.et.hasFocus() then
					service.sendEvent("BackSpace")
				else
					local selStart = views.et.selectionStart
					local selEnd = views.et.selectionEnd
					if selEnd == #et then
						views.et.text = et:sub(1, selStart - 1)
						views.et.setSelection(selStart - 1)
					elseif selStart == selEnd then
						views.et.text = et:sub(1, selStart - 1) .. et:sub(selEnd - #et)
						views.et.setSelection(selStart - 1)
					else
						views.et.text = et:sub(1, selStart) .. et:sub(selEnd - #et)
						views.et.setSelection(selStart)
					end
				end
			end
		},
		{
			Button,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 2,
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "◀",
			textColor = textColor,
			onClick = function (v, e)
				if views.gv.tag >= 0x100 then
					showChars(views.gv.tag - 0x100)
					setSpinnerSelection()
				end
			end
		},
		{
			Button,
			layout_width = -1,
			layout_height = -2,
			layout_weight = 2,
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "▶",
			textColor = textColor,
			onClick = function (v, e)
				if views.gv.tag < 0x110000 - 0x100 then
					showChars(views.gv.tag + 0x100)
					setSpinnerSelection()
				end
			end
		}
	},
	{
		GridView,
		id = "gv",
		layout_width = -1,
		layout_height = -1,
		adapter = adapter,
		numColumns = numColumns,
		padding = "8dp",
		tag = 0
	}
}, views)

views.gv.onItemClick = function (l, v, p)
	local t = v.text
	local et = views.et.text
	if not views.et.hasFocus() then
		service.commitText(t)
	else
		local selStart = views.et.selectionStart
		local selEnd = views.et.selectionEnd
		if selEnd == #et then
			views.et.text = et:sub(1, selStart) .. t
		else
			views.et.text = et:sub(1, selStart) .. t .. et:sub(selEnd - #et)
		end
		views.et.setSelection(selStart + 1)
	end
end

showChars(0)

service.setInputView(contentView)