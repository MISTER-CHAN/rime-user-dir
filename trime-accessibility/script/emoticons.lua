require "import"
import "android.graphics.drawable.StateListDrawable"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local keyboardBackColor = colorScheme and 0xff1f1f1f or 0xffe7e7e7
local returnKeyBackColor = colorScheme and 0xff1f1f1f or 0xff0060e0
local returnKeyTextColor = colorScheme and 0xffc0c0c0 or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000
local undoKeyBackColor = colorScheme and 0xff1f1f1f or 0xffbfbfbf

local function Back(backColor, pressedBackColor)
	pressedBackColor = pressedBackColor or hilitedBackColor
	local stb = StateListDrawable()
	stb.addState({
		-android.R.attr.state_pressed
	}, LuaDrawable(function(c, p, d)
		local b = d.bounds
		p.setColor(backColor)
		c.drawRect(b.left, b.top, b.right, b.bottom, p)
	end))
	stb.addState({
		android.R.attr.state_pressed
	}, LuaDrawable(function(c, p, d)
		local b = d.bounds
		p.setColor(pressedBackColor)
		c.drawRect(b.left, b.top, b.right, b.bottom, p)
	end))
	return stb
end

local width = service.getWidth()

local views = {}

local item = {
	TextView,
	layout_width = "match",
	layout_height = "match",
	id = "tv",
	gravity = "center",
	padding = "4dp",
    textColor = textColor,
    textSize = "20sp"
}

local smileysData = {}
local smileys = "โนโบโป๐ฟ๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐๐ ๐ก๐ข๐ฃ๐ค๐ฅ๐ฆ๐ง๐จ๐ฉ๐ช๐ซ๐ฌ๐ญ๐ฎ๐ฏ๐ฐ๐ฑ๐ฒ๐ณ๐ด๐ต๐ถ๐ท๐๐๐๐๐ค๐ค๐ค๐ค๐ค๐ค๐ค๐ค ๐คก๐คข๐คฃ๐คค๐คฅ๐คง๐คจ๐คฉ๐คช๐คซ๐คฌ๐คญ๐คฎ๐คฏ๐ฅฐ๐ฅฑ๐ฅณ๐ฅด๐ฅต๐ฅถ๐ฅธ๐ฅบ๐ง"
local smileysLen = utf8.len(smileys)
for i = 1, smileysLen do
	smileysData[#smileysData + 1] = {
		tv = utf8.sub(smileys, i, i)
	}
end
local smileysAdapter = LuaAdapter(service, smileysData, item)

local peopleData = {}
local people = "โโโโโ๐๐๐๐๐๐๐๐๐๐๐๐๐ช๐๐๐๐๐๐๐๐๐๐ค๐ค๐ค๐ค๐ค๐ค๐ค๐ค๐ค๐ค๐คฒ๐ฆต๐ฆถ๐ถ๐ง๐ฆ๐ง๐จ๐ฉ๐ง๐ด๐ตโ๐ป๐ผ๐ฝ๐พ๐ฟ"
local peopleLen = utf8.len(people)
for i = 1, peopleLen do
	peopleData[#peopleData + 1] = {
		tv = utf8.sub(people, i, i)
	}
end
local peopleAdapter = LuaAdapter(service, peopleData, item)

local function Tab(text, content, tooltip)
	return {
		Button,
		layout_width = width / 5,
		layout_height = "match",
		Background = Back(backColor),
		text = text,
		textColor = textColor,
		onClick = function (v, e)
			local b = views.tabs.getChildCount() - 1
			for i = 1, b do
				views.tabs.getChildAt(i).Background = Back(backColor)
			end
			v.Background = Back(hilitedBackColor)
			views[content].bringToFront()
		end,
		onLongClickListener = {
			onLongClick = function (v, e)
				print(tooltip)
				return true
			end
		}
	}
end

local function Emoticon(icon)
	return {
		Button,
		layout_width = "match",
		layout_height = "match",
		layout_weight = 1,
		layout_margin = "1dp",
		Background = Back(backColor),
		text = icon,
		textColor = textColor,
		onClick = function (v, e)
			service.commitText(icon)
		end
	}
end

local contentView = loadlayout({
	LinearLayout,
	layout_width = "match",
	layout_height = "match",
	orientation = "vertical",
	{
		LinearLayout,
		id = "tabs",
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
		BackgroundColor = backColor,
		elevation = "4dp",
		{
			Button,
			layout_width = width / 5,
			layout_height = "match",
			Background = Back(backColor),
			text = "๏ผ",
			textColor = textColor,
			onClick = function (v, e)
				service.setInputView(service.getRootView())
			end,
			onLongClickListener = {
				onLongClick = function (v, e)
					print("่ฟๅ")
					return true
				end
			}
		},
		Tab("(^_^)", "basic", "้กๆๅญ"),
		Tab("๐", "smileys", "็นชๆๅญ๏ผ่กจๆ"),
		Tab("๐", "people", "็นชๆๅญ๏ผไบบ็ฉ")
	},
	{
		FrameLayout,
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		BackgroundColor = backColor,
		{
			LinearLayout,
			id = "basic",
			layout_width = "match",
			layout_height = "match",
			BackgroundColor = keyboardBackColor,
			orientation = "vertical",
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Emoticon(":-)"),
				Emoticon(":D"),
				Emoticon("XD"),
				Emoticon(":("),
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Emoticon("( โขฬ อ โข ฬ)"),
				Emoticon("> ฯ <"),
				Emoticon("โ โ โ"),
				Emoticon("๏ฟข_๏ฟข||"),
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Emoticon("โฅ๏นโฅ"),
				Emoticon("(ฬธใปฬธฯฬธใปฬธ)ฬธ"),
				Emoticon("( อกยฐ อส อกยฐ)"),
				Emoticon("(;ยดเผเบถะเผเบถ`)"),
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Emoticon("ฮฃ(ใะดใ|)!!"),
				Emoticon("ูฉ(เน> โ <)?ถ โก"),
			},
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Emoticon("(โฏ๏ผ๏ผฟ๏ผ)โฏโทโท"),
				{
					LinearLayout,
					layout_width = "match",
					layout_height = "match",
					layout_weight = 1,
					{
						Button,
						layout_width = "match",
						layout_height = "match",
						layout_weight = 1,
						Background = Back(undoKeyBackColor),
						text = "โถ",
						textColor = textColor,
						onClick = function (v, e)
							service.sendEvent("undo")
						end
					},
					{
						Button,
						layout_width = "match",
						layout_height = "match",
						layout_weight = 1,
						Background = Back(returnKeyBackColor),
						text = "โต",
						textColor = returnKeyTextColor,
						onClick = function (v, e)
							service.sendEvent("Return")
						end
					}
				}
			}
		},
		{
			FrameLayout,
			id = "smileys",
			layout_width = "match",
			layout_height = "match",
			BackgroundColor = backColor,
			{
				GridView,
				id = "gv_smileys",
				layout_width = "match",
				layout_height = "match",
				adapter = smileysAdapter,
				clipToPadding = false,
				numColumns = service.isLandscape() and 16 or 8,
				padding = "8dp"
			},
			{
				LinearLayout,
				layout_width = "63dp",
				layout_height = "35dp",
				layout_gravity = "right|bottom",
				layout_marginBottom = "8dp",
				BackgroundColor = 0x7f9f9f9f,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(0x7fdfdfdf, 0x7f5f5f5f),
					gravity = "center",
					padding="8dp",
					text = "โซ",
					textColor=0xbf000000,
					textSize="20dp",
					onClick = function(v, e)
						service.sendEvent("BackSpace")
					end
				}
			}
		},
		{
			FrameLayout,
			id = "people",
			layout_width = "match",
			layout_height = "match",
			BackgroundColor = backColor,
			{
				GridView,
				id = "gv_people",
				layout_width = "match",
				layout_height = "match",
				adapter = peopleAdapter,
				clipToPadding = false,
				numColumns = service.isLandscape() and 20 or 10,
				padding = "8dp"
			},
			{
				LinearLayout,
				layout_width = "63dp",
				layout_height = "35dp",
				layout_gravity = "right|bottom",
				layout_marginBottom = "8dp",
				BackgroundColor = 0x7f9f9f9f,
				elevation = "4dp",
				{
					Button,
					layout_width = "match",
					layout_height = "match",
					Background = Back(0x7fdfdfdf, 0x7f5f5f5f),
					gravity = "center",
					padding="8dp",
					text = "โซ",
					textColor=0xbf000000,
					textSize="20dp",
					onClick = function(v, e)
						service.sendEvent("BackSpace")
					end
				}
			}
		}
	}
}, views)

views.gv_smileys.onItemClick = function (parent, view, position, id)
	service.commitText(view.text)
end
views.gv_people.onItemClick = function (parent, view, position, id)
	service.commitText(view.text)
end

smileysAdapter.notifyDataSetChanged()
peopleAdapter.notifyDataSetChanged()

views.basic.bringToFront()
views.tabs.getChildAt(1).Background = Back(hilitedBackColor)

service.setInputView(contentView)
