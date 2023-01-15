require "import"

import "android.graphics.drawable.StateListDrawable"
import "android.view.*"
import "android.widget.*"
import "com.osfans.trime.*"

local arg = ...

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = colorScheme and 0xff3f3f3f or 0xffdfdfdf
local backColor = colorScheme and 0xff1f1f1f or 0xffffffff
local textColor = colorScheme and 0xffc0c0c0 or 0xff000000

local function Back()
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
		p.setColor(hilitedBackColor)
		c.drawRect(b.left, b.top, b.right, b.bottom, p)
	end))
	return stb
end

local views = {}

local layout = {
	LinearLayout,
	layout_width = "match",
	layout_height = "match",
}

local category = arg:match("^(.+)_")
local lang = arg:match("_(.*)$")
local rows = {}
if category == "consonant" or arg == nil then
	local manners, places = {}, {}
	local text = ""
	local mannersTextSize, placesTextSize = "15sp", "15sp"
	local textSize = "15sp"
	local ll = {
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		{
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			orientation = "vertical",
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "wrap",
			}
		}
	}
	local sv = {
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		ll
	}
	if lang == "" then
		manners = {"鼻音", "內爆音", "塞音", "塞擦音", "擦音", "近音", "閃音", "顫音", "邊塞擦音", "邊擦音", "邊近音", "邊閃音", "搭嘴音", "邊搭嘴音", "碰擊音"}
		places = {"雙脣", "硬齶雙脣", "脣齒", "硬齶脣齒", "齒", "脣齒齦", "齒齦", "硬齶齒齦", "軟齶齒齦", "脣齦後", "齦後", "捲舌齦後", "硬齶齦後", "捲舌", "脣硬齶", "硬齶", "硬軟齶", "脣軟齶", "硬齶軟齶", "軟齶", "小舌", "軟齶咽", "咽", "會厭", "聲門"}
		rows = {
			" m ᶆ ɱ       n ȵ           ɳ   ɲ       ŋ ɴ        ",
			"ƥɓ          ƭɗ             ᶑ  ƈʄ      ƙɠʠʛ        ",
			"pbᶈᶀȹȸ      tdȶȡ          ʈɖ  cɟ    ᶄᶃkɡqɢ    ʡ ʔ ",
			"            ƾƻʨʥ    ʧʤ                            ",
			"ɸβ  fvᶂᶌθðσƍszɕʑ  ƪƺʃʒᶘᶚᶋ ʂʐ  çʝɧ   ᶍ xɣχʁʩ ħʕʜʢhɦ",
			"     ʋ       ɹ             ɻ ɥ j  ʍw   ɰ          ",
			"     ⱱ       ɾ             ɽ                      ",
			" ʙ           r ᶉ                         ʀ        ",
			"            ƛλ                                    ",
			"            ɬɮ            ꞎ                       ",
			"             l ȴ ɫ           ɭ ʎ       ʟ          ",
			"             ɺ                                    ",
			"ʘ   ǀ ǃ      ‼ ǂ   ʞ     ",
			"      ǁ                  ",
			"ʬ   ʭ ¡                  "
		}
		mannersTextSize, placesTextSize = "8sp", "8sp"
		textSize = "10sp"
		ll = {
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			{
				LinearLayout,
				layout_width = "2700px",
				layout_height = "match",
				orientation = "vertical",
				{
					LinearLayout,
					layout_width = "match",
					layout_height = "wrap",
				}
			}
		}
		sv = {
			HorizontalScrollView,
			layout_width = "match",
			layout_height = "match",
			ll
		}
	elseif lang == "cantonese" then
		manners = {"鼻音", "塞音", "塞擦音", "擦音", "近音", "邊近音"}
		places = {"雙脣", "脣齒", "齒齦", "硬齶", "脣軟齶", "軟齶", "聲門"}
		rows = {
			" m   n     ŋ  ",
			"p   t     k ʔ ",
			"    ƾ         ",
			"  f s       h ",
			"       j w    ",
			"     l        ",
		}
	elseif lang == "english" then
		manners = {"鼻音", "塞音", "塞擦音", "擦音", "近音", "邊近音"}
		places = {"雙脣", "脣齒", "齒", "齒齦", "軟齶齒齦", "齦後", "硬齶", "脣軟齶", "軟齶", "聲門"}
		rows = {
			" m ɱ   n         ŋ  ",
			"pb    td        kɡʔ ",
			"      ƾƻ  ʧʤ        ",
			"  fvθðsz  ʃʒ      hɦ",
			"       ɹ     jʍw    ",
			"       l ɫ          "
		}
		text = "\n"
	elseif lang == "mandarin" then
		manners = {"鼻音", "塞音", "塞擦音", "擦音", "近音", "邊近音"}
		places = {"雙脣", "脣齒", "齒齦", "硬齶齒齦", "捲舌", "脣硬齶", "硬齶", "脣軟齶", "軟齶", "聲門"}
		rows = {
			" m   n           ŋ  ",
			"p   t   ʈ       k ʔ ",
			"    ƾ ʨ             ",
			"  f s ɕ ʂʐ      xɣ  ",
			"         ɻ ɥ j w    ",
			"     l              "
		}
		text = "\n"
	end
	local consonants = {
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		BackgroundColor = 0xffe7e7e7,
		{
			LinearLayout,
			layout_width = "wrap",
			layout_height = "match",
			orientation = "vertical",
			{
				TextView,
				layout_width = "wrap",
				layout_height = "wrap",
				gravity = "center",
				text = text,
				textSize = placesTextSize
			}
		},
		sv
	}
	for k, v in ipairs(manners) do
		consonants[2][k + 2] = {
			TextView,
			layout_width = "wrap",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center",
			text = v,
			textSize = mannersTextSize
		}
	end
	for k, v in ipairs(places) do
		consonants[3][2][2][2][k + 1] = {
			TextView,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center",
			text = v,
			textSize = placesTextSize
		}
	end
	for k, v in ipairs(rows) do
		local row = {
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			BackgroundColor = 0xffe7e7e7,
		}
		local l = utf8.len(v)
		for c = 1, l do
			row[c + 1] = {
				TextView,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Background = Back(),
				gravity = "center",
				layout_marginLeft = k < 13 and (c % 2) .. "dp" or "1dp",
				layout_marginRight = k < 13 and (1 - c % 2) .. "dp" or "1dp",
				layout_marginTop = "1dp",
				layout_marginBottom = "1dp",
				text = utf8.sub(v, c, c),
				textColor = 0xff000000,
				textSize = textSize,
				onClick = function (v, e)
					if v.text ~= " " then
						service.commitText(v.text)
					end
				end
			}
		end
		consonants[3][2][2][k + 2] = row
	end
	layout[2] = consonants
elseif category == "vowel" then
	local front_back, close_open = {}, {}
	local text = ""
	if lang == "" then
		front_back = {"前", "央", "後"}
		close_open = {"(舌尖)\n閉", "閉", "次閉", "半閉", "中", "半開", "次開", "開"}
		rows = {
			"  iyɪʏeøᴇ ɛœæ aɶ",
			"ʅʯɨʉᵻᵿɘɵə ɜɞɐ ᴀ ",
			"ɿʮɯu ʊɤoⱻωʌɔ  ɑɒ"
		}
		text = "\n"
	elseif lang == "cantonese" then
		front_back = {"前", "央", "後"}
		close_open = {"閉", "次閉", "半閉", "半開", "次開", "開"}
		rows = {
			"iyɪ e ɛœ  a ",
			"     ɵ  ɐ   ",
			" u ʊ o ɔ    "
		}
	elseif lang == "english" then
		front_back = {"前", "央", "後"}
		close_open = {"閉", "次閉", "半閉", "中", "半開", "次開", "開"}
		rows = {
			"i ɪ e   ɛ æ a ",
			"      ə ɜ     ",
			" u ʊ    ʌɔ  ɑɒ"
		}
	elseif lang == "mandarin" then
		front_back = {"前", "央", "後"}
		close_open = {"(舌尖)\n閉", "閉", "次閉", "半閉", "中", "半開", "開"}
		rows = {
			"  iy  e ᴇ ɛ a ",
			"ʅ ɨ     ə   ᴀ ",
			"ɿ ɯu ʊɤo    ɑ "
		}
		text = "\n"
	end
	local vowels = {
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		BackgroundColor = 0xffe7e7e7,
		{
			LinearLayout,
			layout_width = "wrap",
			layout_height = "match",
			orientation = "vertical",
			{
				TextView,
				layout_width = "wrap",
				layout_height = "wrap",
				gravity = "center",
				text = text
			}
		},
		{
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			orientation = "vertical",
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "wrap",
			}
		}
	}
	for k, v in ipairs(front_back) do
		vowels[2][k + 2] = {
			TextView,
			layout_width = "wrap",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center",
			text = v
		}
	end
	for k, v in ipairs(close_open) do
		vowels[3][2][k + 1] = {
			TextView,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			gravity = "center|bottom",
			text = v
		}
	end
	for k, v in ipairs(rows) do
		local row = {
			LinearLayout,
			layout_width = "match",
			layout_height = "match",
			layout_weight = 1,
			BackgroundColor = 0xffe7e7e7,
			padding = "1dp"
		}
		local l = utf8.len(v)
		for c = 1, l do
			row[c + 1] = {
				TextView,
				layout_width = "match",
				layout_height = "match",
				layout_weight = 1,
				Background = Back(),
				gravity = "center",
				layout_marginLeft = (c % 2 + 1) .. "dp",
				layout_marginRight = (2 - c % 2) .. "dp",
				layout_marginTop = "2dp",
				layout_marginBottom = "2dp",
				text = utf8.sub(v, c, c),
				textColor = textColor,
				textSize = "16sp",
				onClick = function (v, e)
					if v.text ~= " " then
						service.commitText(v.text)
					end
				end
			}
		end
		vowels[3][k + 2] = row
	end
	layout[2] = vowels
elseif category == "other" then
	if lang == "" then
		rows = {
			{"記音", "/|‖{}~+()⸨⸩[]⟦⟧"},
			{"連結號", "͜͡"},
			{"擠喉音", "ʼ"},
			{"變音符號", "̥̬̊ʰʱ˭̹̜̟͗͑˖̠˗̩̯̈̽̍˞̤̰͍ꟹʸᵝᶹ̼̪̺̻͇͆ʴʳʵᶣʲʷ̫ˠʶ͌ˤ̴̃͊͋ⁿˡᶿˣᵊ̝̚˔̞˕̘̙͈͉\\↓↑͔˱͕˲͎̣͢ꟸ!‼"},
			{"超音段成分", "ˈˌːˑ̆|‖.‿"},
			{"音調與重音", "̋́̄̀̏˥˦˧˨˩̌̂᷄᷅᷇᷆᷈᷉ꜜꜛ↗↘"},
			{"韻律", "().{}ₚ"}
		}
	elseif lang == "cantonese" then
		rows = {
			{"記音", "/|‖{}~+()⸨⸩[]⟦⟧"},
			{"連結號", "͜͡"},
			{"變音符號", "ʰ˭̩̯̍ʷ̚"},
			{"超音段成分", "ː."},
			{"音調與重音", "̋́̄̀̏˥˦˧˨˩̌̂᷄᷅᷇᷆᷈᷉ꜜꜛ↗↘"}
		}
	elseif lang == "english" then
		rows = {
			{"記音", "/|‖{}~+()⸨⸩[]⟦⟧"},
			{"連結號", "͜͡"},
			{"變音符號", "̥̬̊ʰ˭̩̯̍˞ʷˠ̴"},
			{"超音段成分", "ˈˌː.‿"},
		}
	elseif lang == "mandarin" then
		rows = {
			{"記音", "/|‖{}~+()⸨⸩[]⟦⟧"},
			{"連結號", "͜͡"},
			{"變音符號", "ʰ˭̟˖̠˗̩̯̍˞̪ᶣʲʷ"},
			{"超音段成分", "."},
			{"音調與重音", "̋́̄̀̏˥˦˧˨˩̌̂᷄᷅᷇᷆᷈᷉ꜜꜛ↗↘"},
		}
	end
	local other = {
		LinearLayout,
		layout_width = "match",
		layout_height = "match",
		BackgroundColor = 0xffe7e7e7,
		{
			ScrollView,
			layout_width = "match",
			layout_height = "match",
			{
				LinearLayout,
				layout_width = "match",
				layout_height = "wrap",
				orientation = "vertical"
			}
		}
	}
	for k, v in ipairs(rows) do
		other[2][2][#other[2][2] + 1] = {
			TextView,
			layout_width = "wrap",
			layout_height = "wrap",
			text = v[1]
		}
		local row = {}
		local l = utf8.len(v[2])
		for c = 1, l do
			if (c - 1) % 10 == 0 then
				row[#row + 1] = {
					LinearLayout,
					layout_width = "match",
					layout_height = "match",
					layout_weight = 1,
					BackgroundColor = 0xffe7e7e7,
				}
				other[2][2][#other[2][2] + 1] = row[#row]
			end
			row[#row][#row[#row] + 1] = {
				TextView,
				layout_width = "40dp",
				layout_height = "wrap",
				Background = Back(),
				gravity = "center",
				layout_margin = "1dp",
				text = utf8.sub(v[2], c, c),
				textColor = textColor,
				textSize = "24sp",
				onClick = function (v, e)
					if v.text ~= " " then
						service.commitText(v.text)
					end
				end
			}
		end
	end
	layout[2] = other
end

service.setKeyboard(loadlayout(layout, views))