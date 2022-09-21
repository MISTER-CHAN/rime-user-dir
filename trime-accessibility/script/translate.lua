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

local json = require "cjson"
local f = io.open(service.LuaDir .. "/translate.json", "r")
local object = json.decode(f:read("*a"))
f:close()

local urls = {"Google", "DeepL", "有道"}

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local views = {}

local function setListener()
	commitText = function (text)
		if text == "。" or text == "！" or text == "？" then
			local ic = service.getCurrentInputConnection()
			local sentence = ""
			local n = 0
			local s = ""
			while true do
				n = n + 1
				s = tostring(ic.getTextBeforeCursor(n, 0))
				if s ~= sentence and s:find("^[^\t\n!.?]+$") ~= nil then
					sentence = s
				else
					break
				end
			end
			if sentence:sub(1, 1) == " " then
				sentence = sentence:sub(2, #sentence)
				n = n - 1
			end
			local result = ""
			local function finally()
				service.sendEvent(string.rep("{BackSpace}", n))
				repeat
				until tostring(ic.getTextBeforeCursor(1, 0)):find("^[^\t\n!.?]$") == nil
				if ic.getTextBeforeCursor(1, 0):find("^[!.?]$") ~= nil then
					result = " " .. result
				end
				service.commitText(result)
			end
			if object.url == "有道" then
				Http.get("http://fanyi.youdao.com/translate?doctype=json&type=ZH_CN2EN&i=" .. sentence .. text, function (code, content)
					if code == 200 then
						result = json.decode(content).translateResult[1][1].tgt
						finally()
					else
						print(code)
					end
				end)
			else
				local exp = ""
				local views = {}
				local view = loadlayout({
					FrameLayout,
					layout_width = "match",
					layout_height = "match",
					{
						WebView,
						layout_width = "match",
						layout_height ="match",
						id = "wv",
						--[[webViewClient = WebViewClient() {
							onPageFinished = function (view, url)
								service.commitText("hi")
								print(9)
							end
						}]]
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						layout_gravity = "center|bottom",
						layout_margin = "32dp",
						backgroundColor = backColor,
						elevation = "4dp",
						{
							Button,
							layout_width = "match",
							layout_height = "wrap",
							backgroundResource = backgroundRId,
							text = "上屛",
							onClick = function (view, e)
								views.wv.evaluateJavascript("document.getElementsByTagName('html')[0].innerHTML", function (value)
									result = value:match(exp)
									if result ~= nil and result ~= "" then
										service.sendEvent("Keyboard_default")
										views.wv.clearHistory()
										views.wv.clearCache(true)
										views.wv.loadUrl("about:blank")
										views.wv.freeMemory()
										views.wv.pauseTimers()
										views.wv.destroy()
										finally()
									end
								end)
							end
						}
					}
				}, views)
				views.wv.getSettings().setJavaScriptEnabled(true)
				if object.url == "DeepL" then
					views.wv.loadUrl("https://www.deepl.com/translator#zh/en/" .. sentence .. text)
					exp = '\\u003Cdiv id=\\"target%-dummydiv\\" class=\\"lmt__textarea lmt__textarea_dummydiv\\">(.-)\\r\\n\\u003C/div>'
				elseif object.url == "Google" then
					views.wv.loadUrl("https://translate.google.com/?sl=zh&tl=en&text=" .. sentence .. text .. "&op=translate")
				end
				service.setKeyboard(view)
			--elseif object.url == "Google" then
				--[[Http.get("https://translate.google.cn/translate_a/single?client=gtx&sl=zh&tl=en&dt=t&q=" .. sentence .. text, function (code, content)
					print(code, content)
				end)]]
				--[[Http.get("https://translate.google.com/sl=en&tl=zh_TW&text=a%0A%0A%op=translate", function (code, content)
					service.commitText(content)
				end)]]
			end
		end
	end
end

service.setInputView(loadlayout({
	LinearLayout,
	layout_width = "match",
	layout_height = "wrap",
	BackgroundColor = backColor,
	orientation = "vertical",
	{
		FrameLayout,
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
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
			text = "翻譯",
			textColor = textColor,
			textSize = "16sp"
		},
		{
			Switch,
			layout_width = "20%w",
			layout_height = "match",
			layout_gravity = "right",
			checked = object.enabled,
			onClick = function(view)
				local c = view.checked
				object.enabled = c
				io.open(service.LuaDir .. "/translate.json", "w"):write(json.encode(object)):close()
				if c then
					setListener()
				else
					commitText = nil
				end
			end
		}
	},
	{
		LinearLayout,
		layout_width = "match",
		layout_height = service.getLastKeyboardHeight(),
		orientation = "vertical",
		padding = "32dp",
		{
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center",
			{
				TextView,
				layout_width = "wrap",
				layout_height = "wrap",
				text = "譯者",
				textColor = textColor
			},
			{
				Spinner,
				layout_width = "match",
				layout_height = "wrap",
				id = "url",
				Adapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, urls).setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item),
				OnItemSelectedListener = {
					onItemSelected = function (parent, view, position, id)
						object.url = urls[position + 1]
						io.open(service.LuaDir .. "/translate.json", "w"):write(json.encode(object)):close()
					end
				}
			}
		},
		{
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			{
				TextView,
				layout_width = "wrap",
				layout_height = "wrap",
				text = "語言",
				textColor = textColor
			},
			{
				Spinner,
				layout_width = "match",
				layout_height = "wrap",
				layout_weight = 1,
				Adapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, {"中文"}),
				enabled = false
			},
			{
				TextView,
				layout_width = "wrap",
				layout_height = "wrap",
				text = "→",
				textColor = textColor
			},
			{
				Spinner,
				layout_width = "match",
				layout_height = "wrap",
				layout_weight = 1,
				Adapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, {"English"}),
				enabled = false
			}
		}
	}
}, views))

for u = 1, #urls do
	if urls[u] == object.url then
		views.url.selection = u - 1
		break
	end
end