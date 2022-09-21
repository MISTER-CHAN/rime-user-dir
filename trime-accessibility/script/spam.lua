require "import"

local arg = ...
if arg ~= "spam" then
	local f = io.open(service.LuaDir .. "/spam.txt", "r+")
	service.sendEvent("select_all")
	local st = service.getCurrentInputConnection().getSelectedText(0)
	if st == nil then
		local r = f:read("*a")
		if r ~= "" then
			service.commitText(r)
		else
			print("請先輸入文本")
		end
	else
		f:write(st)
	end
	f:close()
	service.sendEvent(string.rep("{Right}", tonumber(arg) + 1) .. "{Return}" .. string.rep("{Left}", tonumber(arg)))
else
	print("無法自動識別當前應用程式，請先手動選擇。")
end