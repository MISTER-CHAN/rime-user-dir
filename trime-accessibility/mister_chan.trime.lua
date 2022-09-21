local map = ...


---------------------------------
-- Set swipe to commit symbols
---------------------------------

local function setSwipeToCommitSymbols(keyboard)
	local keys = map.preset_keyboards[keyboard].keys
	for i = 0, #keys - 1 do
		local key = keys[i]
		local lc = key.long_click
		if lc ~= nil then
			if utf8.len(lc) == 1 then
				key.swipe_left = key.long_click
				key.swipe_right = key.long_click
				key.swipe_up = key.long_click
			elseif lc == "(){Left}" then
				key.swipe_up = key.long_click
			elseif lc == "[]{Left}" then
				key.swipe_up = key.long_click
			end
		end
	end
end

local function setSwipeToCommitSymbolsAscii(keyboard)
	local keys = map.preset_keyboards[keyboard].keys
	for i = 0, #keys - 1 do
		local key = keys[i]
		local lc = key.long_click
		if lc ~= nil and lc:sub(1, 19) == "{Enable_ascii_mode}" then
			lc = lc:sub(20)
			if utf8.len(lc) == 1 then
				key.swipe_left = key.long_click
				key.swipe_right = key.long_click
				key.swipe_up = key.long_click
			elseif lc == "(){Left}" then
				key.swipe_up = key.long_click
			elseif lc == "[]{Left}" then
				key.swipe_up = key.long_click
			end
		end
	end
end

setSwipeToCommitSymbolsAscii("letter")
setSwipeToCommitSymbolsAscii("letter_land")
setSwipeToCommitSymbolsAscii("letter_uppercase")
setSwipeToCommitSymbolsAscii("letter_uppercase_land")


-----------------------------
-- Create Record Keyboards
-----------------------------

local c = ""
for b = 32, 126 do
	c = utf8.char(b)
	map.preset_keys["Record_" .. b] = {send = "function", command = "record.lua", option = c}
end
map.preset_keys.Record_space_latin = {label = "Latina", functional = false, text = " {Record_32}"}
map.preset_keys.Record_space_number = {label = "數字", functional = false, text = " {Record_32}"}
map.preset_keys.Record_space_symbols = {label = "符號", functional = false, text = " {Record_32}"}
map.preset_keys.Record_8592 = {send = "function", command = "record.lua", option = "←"}
map.preset_keys.Record_BackSpace = {label = "⌫", repeatable = true, text = "{BackSpace}{Record_8592}"}

local function createRecordKeyboard(keyboard)
	local keys = map.preset_keyboards[keyboard].keys
	for i = 0, #keys - 1 do
		local key = keys[i]
		local c = key.click
		local lc = key.long_click
		if c ~= nil then
			if utf8.len(c) == 1 then
				key.click = c .. "{Record_" .. utf8.byte(c) .."}"
			elseif c == "Exclamation_mark" then
				key.click = "!{Record_33}"
			elseif c == "Question_mark" then
				key.click = "?{Record_63}"
			elseif c == "<>{Left}" then
				key.click = c .. "{Record_60}{Record_62}"
				key.swipe_left = "<{Record_60}"
				key.swipe_right = ">{Record_62}"
			elseif c == "[]{Left}" then
				key.click = c .. "{Record_91}{Record_93}"
				key.swipe_left = "[{Record_91}"
				key.swipe_right = "]{Record_93}"
			elseif c == "{}{Left}" then
				key.click = c .. "{Record_123}{Record_125}"
				key.swipe_left = "{{Record_123}"
				key.swipe_right = "}{Record_125}"
			elseif c == "BackSpace" then
				key.click = "Record_BackSpace"
			elseif c:sub(1, 5) == "space" then
				key.click = "Record_" .. c
			end
		end
		if lc ~= nil then
			if utf8.len(lc) == 1 then
				key.long_click = lc .. "{Record_" .. utf8.byte(lc) .."}"
				key.swipe_left = key.long_click
				key.swipe_right = key.long_click
				key.swipe_up = key.long_click
			elseif lc == "(){Left}" then
				key.long_click = lc .. "{Record_40}{Record_41}"
				key.swipe_left = "({Record_40}"
				key.swipe_right = "){Record_41}"
			elseif lc == "[]{Left}" then
				key.long_click = lc .. "{Record_91}{Record_93}"
				key.swipe_left = "[{Record_91}"
				key.swipe_right = "]{Record_93}"
			end
		end
	end
end

local function createRecordKeyboardAscii(keyboard)
	local keyName = keyboard
	if keyName:sub(#keyName - 11) == "_record_land" then
		keyName = keyName:sub(1, #keyName - 12) .. "_land_record"
	end
	local keys = map.preset_keyboards[keyboard].keys
	for i = 0, #keys - 1 do
		local key = keys[i]
		local a = key.ascii
		local c = key.click
		local lc = key.long_click
		if c ~= nil then
			if a ~= nil then
				if utf8.len(a) == 1 then
					key.ascii = a .. "{Record_" .. utf8.byte(a) .."}"
					key.click = "{Enable_ascii_mode}" .. a .. "{Record_" .. utf8.byte(a) .."}"
				end
			elseif c == "BackSpace" then
				key.click = "Record_BackSpace"
			elseif c:sub(1, 5) == "space" then
				key.click = "Record_" .. c
			end
		end
		if lc ~= nil and lc:sub(1, 19) == "{Enable_ascii_mode}" then
			lc = lc:sub(20)
			if utf8.len(lc) == 1 then
				key.long_click = lc .. "{Record_" .. utf8.byte(lc) .."}"
				key.swipe_left = key.long_click
				key.swipe_right = key.long_click
				key.swipe_up = key.long_click
			elseif lc == "(){Left}" then
				key.long_click = lc .. "{Record_40}{Record_41}"
				key.swipe_left = "({Record_40}"
				key.swipe_right = "){Record_41}"
			elseif lc == "[]{Left}" then
				key.long_click = lc .. "{Record_91}{Record_93}"
				key.swipe_left = "[{Record_91}"
				key.swipe_right = "]{Record_93}"
			end
		end
	end
end

local function createRecordPresetKeys(key, keyboard)
	keyboard = keyboard or key
	if keyboard:sub(#key - 4) ~= "_land" then
		key_r = key .. "_record"
	else
		key_r = keyboard:sub(1, #key - 5) .. "_record_land"
	end
	map.preset_keys["Keyboard_" .. key .. "_private"] = {select = keyboard, send = "Eisu_toggle"}
	map.preset_keys["Keyboard_" .. key .. "_record"] = {select = key_r, send = "Eisu_toggle"}
end

local function createRecordSwitcher(keyboard, index)
	map.preset_keyboards[keyboard].keys[index].swipe_up = "Record_switch"
	if keyboard:find("_record") == nil then
		map.preset_keyboards[keyboard].keys[index].swipe_left = "Record_switch"
		map.preset_keyboards[keyboard].keys[index].swipe_right = "Record_switch"
	end
end

createRecordKeyboard("number_record")
createRecordKeyboard("number_record_land")
createRecordKeyboard("number_symbols_record")
createRecordKeyboard("number_symbols_record_land")
createRecordKeyboard("symbols_record")
createRecordKeyboard("symbols_us_international_record")
createRecordKeyboardAscii("letter_record")
createRecordKeyboardAscii("letter_record_land")
createRecordKeyboardAscii("letter_uppercase_record")
createRecordKeyboardAscii("letter_uppercase_record_land")
createRecordPresetKeys("letter")
createRecordPresetKeys("letter_land")
createRecordPresetKeys("letter_uppercase")
createRecordPresetKeys("letter_uppercase_land")
createRecordPresetKeys("number")
createRecordPresetKeys("number_land")
createRecordPresetKeys("number_symbols")
createRecordPresetKeys("number_symbols_land")
createRecordPresetKeys("symbols")
createRecordPresetKeys("symbols_", "symbols")
createRecordPresetKeys("symbols_us_international")

createRecordSwitcher("letter", 35)
createRecordSwitcher("letter_land", 40)
createRecordSwitcher("letter_record", 35)
createRecordSwitcher("letter_record_land", 40)
createRecordSwitcher("number", 15)
createRecordSwitcher("number_land", 27)
createRecordSwitcher("number_record", 15)
createRecordSwitcher("number_record_land", 27)
