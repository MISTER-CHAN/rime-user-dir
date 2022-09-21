require "import"

local arg = ...

local ic = service.getCurrentInputConnection()

local str = ic.getSelectedText(0)
if str == nil then
	service.sendEvent("select_all")
	str = ic.getSelectedText(0)
	if str == nil then
		return
	end
end

local result = ""
if arg == "uppercase" then
	result = str:upper()
end

service.commitText(result)