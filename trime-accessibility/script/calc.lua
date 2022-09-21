require "import"

local e = 0
local exp = ""
local ic = service.getCurrentInputConnection()
local n = 0
local s = ""

if ic.getTextBeforeCursor(1, 0) == "=" then
	e = 1
	n = 1
end

while true do
	n = n + 1
	s = tostring(ic.getTextBeforeCursor(n, 0))
	s = s:sub(1, #s - e)
	if s ~= exp and s:find("^[()*+%-./0-9^]+$") ~= nil then
		exp = s
	else
		break
	end
end

if exp:find("^-?[.0-9]*$") == nil then
	local result = ""
	if pcall(function ()
		result = tostring(loadstring("return " .. exp)())
	end) then
		if e == 0 then
			service.sendEvent(string.rep("{BackSpace}", n - 1))
			repeat
			until tostring(ic.getTextBeforeCursor(1, 0)):find("^[()*+%-./0-9^]$") == nil
		end
		service.commitText(result)
	else
		service.sendEvent("paste")
	end
else
	service.sendEvent("paste")
end
