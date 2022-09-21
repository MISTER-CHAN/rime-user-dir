require "import"
import "android.graphics.RectF"
import "android.graphics.drawable.StateListDrawable"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local hilitedOffKeyBackColor = colorScheme and 0xff3f3f3f or 0xff7f7f7f
local hilitedReturnKeyBackColor = colorScheme and 0xff3f3f3f or 0xff808080
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7
local offKeyBackColor = colorScheme and 0xff1f1f1f or 0xffbfbfbf
local returnKeyBackColor = colorScheme and 0xff1f1f1f or 0xff0060e0
local returnKeyTextColor = colorScheme and 0xffc0c0c0 or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000

local function Back(color, pressedColor)
  local stb = StateListDrawable()
  stb.addState({-android.R.attr.state_pressed}, LuaDrawable(function(c, p, d)
    local b = d.bounds
    p.setColor(color)
    c.drawRect(RectF(b.left, b.top, b.right, b.bottom), p)
  end))
  stb.addState({android.R.attr.state_pressed}, LuaDrawable(function(c, p, d)
    local b = d.bounds
    p.setColor(pressedColor)
    c.drawRect(RectF(b.left, b.top, b.right, b.bottom), p)
  end))
  return stb
end

local views = {}
local data = {}

local col = 99
local maxCol = 0

local notAll = 0

local candidate = {}

local adapter = LuaAdapter(service, data, {
	LinearLayout,
	layout_width = "fill",
	layout_height = "fill",
	{
		GridView,
		layout_width = "fill",
		layout_height = "fill",
		id = "gv",
		horizontalSpacing = "2dp",
		numColumns = 1,
		paddingTop = "1dp",
		paddingBottom = "1dp"
	}
})

local function commit(text)
	if views.cb_comp.checked then
		text = Rime.openccConvert(text, "utc.json")
	end
	service.commitText(text)
	service.setInputView(service.getRootView())
end

local function getCandidates()
	for n = 1, notAll * 4 do
		service.sendEvent("Page_Down")
	end
	local c = {}, nrc, rc
	nrc = Rime.getCandidates()
	for p = 0, 3 do
		rc = nrc
		for i = 1, #rc do
			c[p * 32 + i] = rc[i - 1]
		end
		service.sendEvent("Page_Down")
		nrc = Rime.getCandidates()
		if rc[0].text == nrc[0].text then
			if notAll > 0 or p > 0 then
				service.sendEvent("Home")
			end
			return c, false
		end
	end
	service.sendEvent("Home")
	return c, true
end

local function load()
	local c, isntAll = getCandidates()
	local isLandscape = service.isLandscape()
	local t = ""
	local len = 0
	for i = 1, #c do
		t = c[i].text
		if t ~= nil then
			if col >= maxCol then
				data[#data + 1] = {
					gv = {
						adapter = LuaAdapter(service, candidate),
						numColumns = 0
					}
				}
				col = 0
				maxCol = isLandscape and 10 or 5
			end
			len = utf8.len(t)
			if len > 2 then
				if isLandscape then
					local mc = math.floor(26.3 / len - 0.6 + 0.5)
					if maxCol > mc then
						maxCol = mc
					end
				else
					local mc = math.floor(14.7 / len - 0.8 + 0.5)
					if maxCol > mc then
						maxCol = mc
					end
				end
			end
			if maxCol < 1 then
				maxCol = 1
			end
			if col >= maxCol then
				data[#data + 1] = {
					gv = {
						adapter = LuaAdapter(service, candidate),
						numColumns = 0
					}
				}
				col = 0
			end
			data[#data].gv.adapter.add({
				ll = {
					background = Back(backColor, hilitedBackColor)
				},
				tv_text = {
					text = t .. "\n" .. notAll * 32 * 4 + i - 1
				},
				tv_comment = {
					text = c[i].comment,
				}
			})
			data[#data].gv.numColumns = data[#data].gv.numColumns + 1
		end
		col = col + 1
	end
	if isntAll then
		notAll = notAll + 1
	else
		notAll = 0
		if col < maxCol then
			data[#data].gv.numColumns = data[#data].gv.numColumns + maxCol - col
		end
	end
	adapter.notifyDataSetChanged()
end

local function refresh()
	table.clear(data)
	notAll = 0
	col = 99
	maxCol = 0
	load()
end

local function deleteCandidate(p)
	service.sendEvent(string.rep("{Page_Down}", p // 32) .. string.rep("{Right}", p % 32) .. "{DeleteCandidate}")
	refresh()
end

local function commitCandidate(p, text)
	if views.cb_comp.checked then
		commit(text)
		return
	end
	if Rime.getCompositionText() ~= nil then
		local len = utf8.len(text)
		service.sendEvent(string.rep("{Page_Down}", p // 32) .. string.rep("{Right}", p % 32) .. "{space}")
		if Rime.getCompositionText() ~= nil then
			refresh()
			views.lv.smoothScrollToPosition(0)
		else
			service.setInputView(service.getRootView())
		end
	else
		service.commitText(text)
		service.setInputView(service.getRootView())
	end
end

candidate = {
	FrameLayout,
	layout_width = "fill",
	layout_height = "fill",
	id = "ll",
	onClick = function (v, e)
		service.sendEvent("Keyboard_last_lock")
		local t = v.getChildAt(1).text
		commitCandidate(t:match("\n(%d+)$"), t:match("^(.+)\n"))
	end,
	onLongClickListener = {
		onLongClick = function (v, e)
			service.sendEvent("Keyboard_last_lock")
			local ct = Rime.getComposingText()
			if ct ~= nil then
				local s = utf8.sub(ct, 1, utf8.len(ct) - utf8.len(Rime.getCandidates()[0].text))
				if s ~= "" then
					service.sendEvent("Escape")
					commit(s)
				end
				service.sendEvent("Escape")
				Rime.clearComposition()
				commit(v.getChildAt(1).text:match("^(.+)\n"))
			else
				commit(v.getChildAt(1).text:match("^(.+)\n"))
			end
			return true
		end
	},
	{
		TextView,
		layout_width = "fill",
		layout_height = "wrap",
		layout_gravity = "center|top",
		id = "tv_comment",
		gravity = "center",
		maxLines = 1,
		textSize = "10sp"
	},
	{
		TextView,
		layout_width = "fill",
		layout_height = "fill",
		id = "tv_text",
		gravity = "center",
		maxLines = 1,
		paddingBottom = "8dp",
		paddingTop = "8dp",
		textColor = textColor,
		textSize = "24sp"
	}
}

local contentView = loadlayout({
	LinearLayout,
	layout_width = "fill",
	layout_height = "fill",
	BackgroundColor = keyboardBackColor,
	orientation = "vertical",
	{
		LinearLayout,
		layout_width = "fill",
		layout_height = service.getCandidateView().getHeight(),
		BackgroundColor = backColor,
		elevation = "4dp",
		{
			LinearLayout,
			layout_width = "fill",
			layout_height ="fill",
			layout_weight = 1,
			gravity = "left|center",
			paddingLeft = "8dp",
			{
				LinearLayout,
				layout_width = "wrap",
				layout_height = "wrap",
				id = "ll_filters",
				visibility = "gone",
				{
					TextView,
					layout_width = "wrap",
					layout_height = "wrap",
					text = "濾鏡：",
					textColor = textColor
				},
				{
					CheckBox,
					layout_width = "wrap",
					layout_height = "wrap",
					id = "cb_comp",
					text = "相容",
					textColor = textColor
				}
			}
		},
		{
			TextView,
			layout_width = "42dp",
			layout_height = "fill",
			gravity = "center",
			padding = "0dp",
			text = "△",
			textColor = textColor,
			textSize = "20sp",
			onClick = function ()
				service.sendEvent("Keyboard_last_lock")
				service.setInputView(service.getRootView())
			end,
			onLongClickListener = {
				onLongClick = function ()
					views.ll_filters.visibility = View.VISIBLE
					return true
				end
			}
		}
	},
	{
		LinearLayout,
		layout_width = "fill",
		layout_height = service.getLastKeyboardHeight(),
		{
			ListView,
			id = "lv",
			layout_width = "fill",
			layout_height = "fill",
			layout_weight = 1,
			adapter = adapter,
			clipToPadding = false,
			padding = "8dp",
			onScrollListener = {
				onScrollStateChanged = function (view, scrollState)
					if notAll > 0 then
						if view.getLastVisiblePosition() >= view.getCount() - 1 - 10 then
							service.sendEvent("Keyboard_last_lock")
							load()
						end
					end
				end
			}
		},
		{
			LinearLayout,
			layout_width = "fill",
			layout_height = "fill",
			layout_weight = 5,
			orientation = "vertical",
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				layout_margin = "4dp",
				BackgroundColor = offKeyBackColor,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(offKeyBackColor, hilitedOffKeyBackColor),
					text = "▲",
					textColor = textColor,
					onClick = function (v, e)
						views.lv.smoothScrollToPosition(views.lv.getFirstVisiblePosition() - 3)
					end
				}
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				layout_margin = "4dp",
				BackgroundColor = offKeyBackColor,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(offKeyBackColor, hilitedOffKeyBackColor),
					text = "▼",
					textColor = textColor,
					onClick = function (v, e)
						views.lv.smoothScrollToPosition(views.lv.getLastVisiblePosition() + 3)
					end
				}
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				layout_margin = "4dp",
				BackgroundColor = offKeyBackColor,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(offKeyBackColor, hilitedOffKeyBackColor),
					text = "⌫",
					textColor = textColor,
					onClick = function (v, e)
						service.sendEvent("Keyboard_last_lock")
						service.sendEvent("{End}{BackSpace}")
						if Rime.getCompositionText() ~= nil then
							refresh()
						else
							service.setInputView(service.getRootView())
						end
					end
				}
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				layout_margin = "4dp",
				BackgroundColor = returnKeyBackColor,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(returnKeyBackColor, hilitedReturnKeyBackColor),
					text = "↵",
					textColor = returnKeyTextColor,
					onClick = function (v, e)
						
					end
				}
			}
		}
	}
}, views)

refresh()

service.setInputView(contentView)