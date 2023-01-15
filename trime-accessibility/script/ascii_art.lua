require "import"
import "android.graphics.*"
import "android.util.TypedValue"
import "android.view.*"
import "android.widget.*"

local colorScheme = Config.get().getColorScheme() == "black"
local hilitedBackColor = (colorScheme and 0xff3f3f3f or 0xffdfdfdf) - 0x100000000
local backColor = (colorScheme and 0xff1f1f1f or 0xffffffff) - 0x100000000
local textColor = (colorScheme and 0xffc0c0c0 or 0xff000000) - 0x100000000

local outValue = TypedValue()
service.getTheme().resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
local backgroundRId = outValue.resourceId

local width, height = service.getWidth(), service.getLastKeyboardHeight()

local strokeRadius = 20

local resolution = {}
local rwpiw, rhpih = 0, 0
local charSize = {
	width = 0,
	height = 0
}
local dotSize = {}
local quadrantSize = {}
local chars = {}
local imageLeft = 0

local fullBlock = "⣿"

local bitmap = {}
local bDots = {}

local canvas = Canvas(bitmap)
local cDots = Canvas(bDots)

local paint = Paint() {
	color = textColor,
	strokeWidth = strokeRadius * 2,
}
local pBack = Paint() {
	color = backColor
}
local pText = Paint() {
	color = textColor
}

local prevX, prevY = 0, 0

local preview

local views = {}

local function isColored(color)
	return textColor - 0x100000 < color and color < textColor + 0x100000
end

local function sign(color)
	return isColored(color) and 1 or 0
end

local function getBlockByBitmap(x, y)
	local tl, tr, bl, br = isColored(bitmap.getPixel(x, y)), isColored(bitmap.getPixel(x + quadrantSize.width, y)), isColored(bitmap.getPixel(x, y + quadrantSize.height)), isColored(bitmap.getPixel(x + quadrantSize.width, y + quadrantSize.height))
	if not tl and not tr and not bl and not bl then
		return " "
	elseif tl and tr and not bl and not br then
		return "▀"
	elseif not tl and not tr and bl and br then
		return "▄"
	elseif tl and tr and bl and br then
		return "█"
	elseif tl and not tr and bl and not br then
		return "▌"
	elseif not tl and tr and not bl and br then
		return "▐"
	elseif not tl and not tr and bl and not br then
		return "▖"
	elseif not tl and not tr and not bl and br then
		return "▗"
	elseif tl and not tr and not bl and not br then
		return "▘"
	elseif tl and not tr and bl and br then
		return "▙"
	elseif tl and not tr and not bl and br then
		return "▚"
	elseif tl and tr and bl and not br then
		return "▛"
	elseif tl and tr and not bl and br then
		return "▜"
	elseif not tl and tr and not bl and not br then
		return "▝"
	elseif not tl and tr and bl and not br then
		return "▞"
	elseif not tl and tr and bl and br then
		return "▟"
	end
	return ""
end

local function getBrailleByBitmap(x, y)
	return utf8.char(0x2800
		+ sign(bitmap.getPixel(x, y)) + sign(bitmap.getPixel(x + dotSize.width, y)) * 0x8
		+ sign(bitmap.getPixel(x, y + dotSize.height)) * 0x2 + sign(bitmap.getPixel(x + dotSize.width, y + dotSize.height)) * 0x10
		+ sign(bitmap.getPixel(x, y + dotSize.height * 2)) * 0x4 + sign(bitmap.getPixel(x + dotSize.width, y + dotSize.height * 2)) * 0x20
		+ sign(bitmap.getPixel(x, y + dotSize.height * 3)) * 0x40 + sign(bitmap.getPixel(x + dotSize.width, y + dotSize.height * 3)) * 0x80)
end

local getCharByBitmap = getBrailleByBitmap

local function resize(w, h)
	resolution = {
		width = w,
		height = h
	}
	local lineWidth, charHeight = 0
	local U2800 = "⠀"
	pText.textSize = 0
	while true do
		pText.textSize = pText.textSize + 1
		lineWidth = pText.measureText(U2800:rep(w))
		charHeight = pText.descent() - pText.ascent()
		if lineWidth <= width then
			charSize.width = lineWidth / resolution.width
			charSize.height = charHeight
			imageLeft = (width - lineWidth) / 2
		else
			break
		end
	end
	pText.textSize = pText.textSize - 1
	height = charSize.height * h
	bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
	bDots = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
	bitmap.eraseColor(backColor)
	bDots.eraseColor(backColor)
	canvas = Canvas(bitmap)
	cDots = Canvas(bDots)
	pcall(function ()
		local lp = views.ll_canvas.getLayoutParams()
		lp.height = height
		views.ll_canvas.setLayoutParams(lp)
	end)
	rwpiw, rhpih = resolution.width / (charSize.width * resolution.width), resolution.height / height
	dotSize = {
		width = charSize.width / 2,
		height = charSize.height / 4
	}
	quadrantSize = {
		width = charSize.width / 2,
		height = charSize.height / 2
	}
	chars = {}
	for r = 1, resolution.height do
		chars[r] = string.rep(U2800, resolution.width)
	end
end

local function setChar(c, r, char)
	chars[r] = utf8.sub(chars[r], 1, c - 1) .. char .. utf8.sub(chars[r], c + 1, resolution.width)
end

local function update(left, top, right, bottom)
	left = left >= 1 and left or 1
	top = top >= 1 and top or 1
	right = right <= resolution.width and right or resolution.width
	bottom = bottom <= resolution.height and bottom or resolution.height
	for r = top, bottom do
		for c = left, right do
			setChar(c, r, getCharByBitmap(imageLeft + (c - 1) * charSize.width + dotSize.width / 2, (r - 1) * charSize.height + dotSize.height / 2))
		end
	end
	for r = top, bottom do
		cDots.drawRect(0, (r - 1) * charSize.height, width, r * charSize.height, pBack)
		cDots.drawText(chars[r], imageLeft, charSize.height * (r - 0.3), pText)
	end
end

local layout = {
	LinearLayout,
	layout_width = "match",
	layout_height = "match",
	backgroundColor = backColor,
	orientation = "vertical",
	{
		LinearLayout,
		layout_width = "match",
		layout_height = service.getCandidateView().getHeight(),
		{
			Button,
			layout_width = "wrap",
			layout_height = "match",
			backgroundResource = backgroundRId,
			text = "＜",
			textColor = textColor,
			onClick = function (v, event)
				bitmap.recycle()
				bDots.recycle()
				service.setInputView(service.getRootView())
			end
		},
		{
			Button,
			layout_width = "wrap",
			layout_height = "match",
			backgroundResource = backgroundRId,
			text = "上屛",
			textColor = textColor,
			onClick = function (v, event)
				local s = ""
				for line = 1, resolution.height do
					s = s .. chars[line] .. "\n"
				end
				service.commitText(utf8.sub(s, 1, utf8.len(s) - 1))
				bitmap.recycle()
				bDots.recycle()
				service.setInputView(service.getRootView())
			end
		},
		{
			Button,
			layout_width = "wrap",
			layout_height = "match",
			backgroundResource = backgroundRId,
			text = "設定",
			textColor = textColor,
			onClick = function (v, event)
				local dialogViews = {}
				local dialogContentView = loadlayout({
					LinearLayout,
					layout_width = "match",
					layout_height = "wrap",
					orientation = "vertical",
					padding = "16dp",
					{
						TextView,
						layout_width = "wrap",
						layout_height = "wrap",
						text = "解析度",
						textColor = textColor,
						textSize = "18sp"
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						gravity = "center",
						{
							TextView,
							layout_width = "wrap",
							layout_height = "wrap",
							text = "寬: "
						},
						{
							TextView,
							id = "tv_width",
							layout_width = "wrap",
							layout_height = "wrap",
							text = tostring(resolution.width)
						},
						{
							SeekBar,
							layout_width = "match",
							layout_height = "wrap",
							max = 72,
							min = 1,
							progress = resolution.width,
							onSeekBarChangeListener = {
								onProgressChanged = function (seekBar, progress, fromUser)
									dialogViews.tv_width.text = tostring(progress)
								end
							}
						}
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						gravity = "center",
						{
							TextView,
							layout_width = "wrap",
							layout_height = "wrap",
							text = "髙: "
						},
						{
							TextView,
							id = "tv_height",
							layout_width = "wrap",
							layout_height = "wrap",
							text = tostring(resolution.height)
						},
						{
							SeekBar,
							layout_width = "match",
							layout_height = "wrap",
							max = 96,
							min = 1,
							progress = resolution.height,
							onSeekBarChangeListener = {
								onProgressChanged = function (seekBar, progress, fromUser)
									dialogViews.tv_height.text = tostring(progress)
								end
							}
						}
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						layout_marginTop = 64,
						gravity = "center",
						{
							TextView,
							layout_width = "match",
							layout_height = "wrap",
							layout_weight = 1,
							text = "畫布",
							textColor = textColor,
							textSize = "18sp"
						},
						{
							CheckBox,
							id = "cb_fill",
							layout_width = "wrap",
							layout_height = "wrap",
							text = "塡充",
							onCheckedChangeListener = {
								onCheckedChanged = function (buttonView, isChecked)
									if isChecked then
										dialogViews.cb_erase.checked = false
									end
								end
							}
						},
						{
							CheckBox,
							id = "cb_erase",
							layout_width = "wrap",
							layout_height = "wrap",
							text = "淸除",
							onCheckedChangeListener = {
								onCheckedChanged = function (buttonView, isChecked)
									if isChecked then
										dialogViews.cb_fill.checked = false
									end
								end
							}
						}
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						layout_marginTop = 64,
						gravity = "center",
						{
							TextView,
							layout_width = "match",
							layout_height = "wrap",
							layout_weight = 1,
							text = "畫筆顏色",
							textColor = textColor,
							textSize = "18sp"
						},
						{
							ToggleButton,
							id = "tb_color",
							layout_width = "wrap",
							layout_height = "wrap",
							checked = paint.color == textColor,
							textOff = "背景色",
							textOn = "前景色"
						}
					},
					{
						TextView,
						layout_width = "wrap",
						layout_height = "wrap",
						layout_marginTop = 64,
						text = "筆畫寬度",
						textColor = textColor,
						textSize = "18sp"
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						gravity = "center",
						{
							TextView,
							id = "tv_stroke",
							layout_width = "wrap",
							layout_height = "wrap",
							text = tostring(strokeRadius)
						},
						{
							SeekBar,
							layout_width = "match",
							layout_height = "wrap",
							max = 48,
							min = 1,
							progress = strokeRadius,
							onSeekBarChangeListener = {
								onProgressChanged = function (seekBar, progress, fromUser)
									dialogViews.tv_stroke.text = tostring(progress)
								end
							}
						}
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						layout_marginTop = 64,
						gravity = "center",
						{
							TextView,
							layout_width = "match",
							layout_height = "wrap",
							layout_weight = 1,
							text = "筆畫字符",
							textColor = textColor,
							textSize = "18sp"
						},
						{
							ToggleButton,
							id = "tb_char",
							layout_width = "wrap",
							layout_height = "wrap",
							checked = getCharByBitmap == getQuadrantByBitmap,
							textOff = "點字",
							textOn = "方形"
						}
					},
					{
						LinearLayout,
						layout_width = "match",
						layout_height = "wrap",
						layout_marginTop = 64,
						gravity = "center",
						{
							TextView,
							layout_width = "wrap",
							layout_height = "wrap",
							text = "卽時預覽",
							textColor = textColor,
							textSize = "18sp"
						},
						{
							Switch,
							id = "s",
							layout_width = "match",
							layout_height = "wrap",
							checked = preview == bDots
						}
					}
				}, dialogViews)
				LuaDialog(service)
					.setTitle("設定")
					.setView(dialogContentView)
					.setPositiveButton("確定", function ()
						local w, h = tonumber(dialogViews.tv_width.text), tonumber(dialogViews.tv_height.text)
						if w ~= resolution.width or h ~= resolution.height then
							resize(w, h)
						end
						preview = dialogViews.s.checked and bDots or bitmap
						views.iv.imageBitmap = preview
						paint.color = dialogViews.tb_color.checked and textColor or backColor
						if dialogViews.tb_char.checked then
							fullBlock = "█"
							getCharByBitmap = getBlockByBitmap
						else
							fullBlock = "⣿"
							getCharByBitmap = getBrailleByBitmap
						end
						if dialogViews.cb_fill.checked or dialogViews.cb_erase.checked then
							local groundColor, groundChar = 0, ""
							if dialogViews.cb_fill.checked then
								groundColor = textColor
								groundChar = fullBlock
							elseif dialogViews.cb_erase.checked then
								groundColor = backColor
								groundChar = "⠀"
							end
							for r = 1, resolution.height do
								chars[r] = groundChar:rep(resolution.width)
							end
							canvas.drawColor(groundColor)
							cDots.drawColor(backColor)
							for r = 1, resolution.height do
								cDots.drawText(chars[r], imageLeft, charSize.height * (r - 0.3), pText)
							end
							views.iv.imageBitmap = preview
						end
						strokeRadius = tonumber(dialogViews.tv_stroke.text)
						paint.strokeWidth = strokeRadius * 2
					end)
					.setNegButton("取消")
					.show()
			end
		}
	},
	{
		LinearLayout,
		id = "ll_canvas",
		layout_width = "match",
		layout_height = height,
		{
			ImageView,
			id = "iv",
			layout_width = "match",
			layout_height = "match",
			imageBitmap = preview,
			onTouchListener = {
				onTouch = function (v, event)
					local x, y = event.x, event.y
					if imageLeft <= x and x < width - imageLeft then
						local action = event.action
						if action == MotionEvent.ACTION_DOWN then
							canvas.drawCircle(x, y, strokeRadius, paint)
						elseif action == MotionEvent.ACTION_MOVE then
							canvas.drawCircle(x, y, strokeRadius, paint)
							canvas.drawLine(prevX, prevY, x, y, paint)
						end
						update(math.floor(rwpiw * (math.min(x, prevX) - strokeRadius - imageLeft)), math.floor(rhpih * (math.min(y, prevY) - strokeRadius)), math.ceil(rwpiw * (math.max(x, prevX) + strokeRadius)), math.ceil(rhpih * (math.max(y, prevY) + strokeRadius)))
						prevX, prevY = x, y
						v.imageBitmap = preview
					end
					return true
				end
			}
		}
	}
}

resize(24, 10)
preview = bitmap

service.setInputView(loadlayout(layout, views))