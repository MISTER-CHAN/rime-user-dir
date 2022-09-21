require "import"
import "android.util.TypedValue"
import "android.view.*"
import "android.webkit.*"
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

local views = {}

local line = {
	LinearLayout,
	layout_width = "wrap",
	layout_height = "wrap",
	orientation = "horizontal"
}

local char = {
	LinearLayout,
	layout_width = "wrap",
	layout_height = "wrap",
	gravity = "center_horizontal",
	orientation = "vertical",
	padding = "4dp",
	{
		TextView,
		id = "tv_char",
		layout_width = "wrap",
		layout_height = "wrap",
		maxLines = 1,
		textColor = textColor,
		textSize = "24dp"
	},
	{
		TextView,
		id = "tv_code",
		layout_width = "wrap",
		layout_height = "wrap"
	}
}

local function showCodes()
	local ic = service.getCurrentInputConnection()
	local str = ic.getSelectedText(0)
	if str == nil then
		service.sendEvent("select_all")
		str = ic.getSelectedText(0)
		if str == nil then
			return
		end
	end
	views.ll_result.removeAllViews()
	local lastLine = loadlayout(line)
	views.ll_result.addView(lastLine)
	len = utf8.len(str)
	for i = 1, len do
		local c = utf8.sub(str, i, i)
		local charViews = {}
		local ll = loadlayout(char, charViews)
		charViews.tv_char.text = c
		charViews.tv_code.text = string.format("U+%0X", utf8.codepoint(c))
		lastLine.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
		ll.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
		if lastLine.measuredWidth + ll.measuredWidth > views.ll_result.width then
			lastLine = loadlayout(line)
			views.ll_result.addView(lastLine)
		end
		lastLine.addView(ll)
		if c == "\n" then
			lastLine = loadlayout(line)
			views.ll_result.addView(lastLine)
		end
	end
end

service.setInputView(loadlayout({
	LinearLayout,
	layout_width = "match",
	layout_height = "wrap",
	backgroundColor = backColor,
	orientation = "vertical",
	{
		FrameLayout,
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
		backgroundColor = backColor,
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
			TextView,
			layout_width = "match",
			layout_height = "match",
			gravity = "center",
			text = "字符串審査",
			textColor = textColor,
			textSize = "16sp"
		},
		{
			Button,
			layout_width = "20%w",
			layout_height = "match",
			layout_gravity = "right",
			backgroundResource = backgroundRId,
			padding = "0dp",
			text = "顯示編碼",
			textColor = textColor,
			onClick = function (v, e)
				showCodes()
			end
		}
	},
	{
		ScrollView,
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		{
			LinearLayout,
			id = "ll_result",
			layout_width = "match",
			layout_height = "wrap",
			orientation = "vertical"
		}
	}
}, views))