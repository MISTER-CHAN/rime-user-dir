require "import"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"

local arg = ...

local colorScheme = Config.get().getColorScheme() == "black"
local backColor = (colorScheme and 0xff1f1f1f or 0xffffffff) - 0x100000000
local textColor = (colorScheme and 0xffc0c0c0 or 0xff000000) - 0x100000000

local views = {}

local prevX, prevY = 0, 0
local selecting = ""

local ic = service.getCurrentInputConnection()

local function showChars()
	local prev, next = ic.getTextBeforeCursor(1, 0), ic.getTextAfterCursor(1, 0)
	views.prev_char.text = prev
	views.prev_codepoint.text = prev == "" and "" or string.format("U+%0X", utf8.codepoint(prev))
	views.next_char.text = next
	views.next_codepoint.text = next == "" and "" or string.format("U+%0X", utf8.codepoint(next))
end

local function move(x, y)
	prevX, prevY = x, y
	for i = 0x0, 0x200000 do
	end
	showChars()
end

service.setKeyboard(loadlayout({
	LinearLayout,
	layout_width = "match",
	layout_height = "match",
	gravity = "center",
	OnTouchListener = {
		onTouch = function (v, e)
			local action = e.getAction()
		    if action == MotionEvent.ACTION_DOWN then
		        prevX, prevY = e.getX(), e.getY()
			elseif action == MotionEvent.ACTION_MOVE then
				local x, y = e.getX(), e.getY()
				if x < prevX - 20 then
					service.sendEvent(selecting .. "Left")
					move(x, y)
				elseif x > prevX + 20 then
					service.sendEvent(selecting .. "Right")         
					move(x, y)
				end
				if y < prevY - 40 then
					service.sendEvent(selecting .. "Up")     
					move(x, y)
				elseif y > prevY + 40 then
					service.sendEvent(selecting .. "Down")
					move(x, y)
				end
		    elseif action == MotionEvent.ACTION_UP then
		        service.sendEvent(arg)
			elseif action == MotionEvent.ACTION_POINTER_2_DOWN then
				selecting = "Shift_"
			elseif action == MotionEvent.ACTION_POINTER_2_UP then
				selecting = ""
			end
		    return true
		end
    },
    {
    	LinearLayout,
		layout_width = "match",
		layout_height = "wrap",
		gravity = "center",
		orientation = "horizontal",
		{
			LinearLayout,
			layout_width = "0dp",
			layout_height = "wrap",
			layout_weight = "1",
			gravity = "right",
			orientation = "vertical",
			padding = "2dp",
			{
				TextView,
				id = "prev_char",
				layout_width = "wrap",
				layout_height = "wrap",
				maxLines = 1,
				textColor = textColor,
				textSize = "32sp"
			},
			{
				TextView,
				id = "prev_codepoint",
				layout_width = "wrap",
				layout_height = "wrap"
			}
		},
		{
			View,
			layout_width = "2dp",
			layout_height = "64dp",
			BackgroundColor = textColor
		},
		{
			LinearLayout,
			layout_width = "0dp",
			layout_height = "wrap",
			layout_weight = "1",
			gravity = "left",
			orientation = "vertical",
			padding = "2dp",
			{
				TextView,
				id = "next_char",
				layout_width = "wrap",
				layout_height = "wrap",
				maxLines = 1,
				textColor = textColor,
				textSize = "32sp"
			},
			{
				TextView,
				id = "next_codepoint",
				layout_width = "wrap",
				layout_height = "wrap"
			}
		}
	}
}, views))

showChars()