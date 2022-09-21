require "import"

local arg = ...
privacy = privacy or "private"
if arg == "record" then
	local name = service.getRootView().getChildAt(1).getChildAt(2).getChildAt(0).getKeyboard().getName()
	local id = "letter"
	if utf8.sub(name, 1, 2) == "字母" then
		id = "letter"
	elseif utf8.sub(name, 1, 4) == "預設數字" then
		id = "number"
	end
	if privacy == "record" then
		LuaDialog(service)
			.setTitle("即將轉去第三方應用程式")
			.setPosButton("取消（我誤觸使彈出此對話框）")
			.setNegativeButton("轉去程式", function()
				privacy = "private"
				service.sendEvent("Keyboard_" .. id .. (service.isLandscape() and "_land" or "") .. "_private")
			end)
			.show()
	else
		privacy = "record"
		service.sendEvent("Keyboard_" .. id .. (service.isLandscape() and "_land" or "") .. "_record")
	end
else
	service.sendEvent("Keyboard_" .. arg .. "_" .. privacy)
end