require "import"

local arg = ...
if Rime.getCompositionText() == nil then
	service.sendEvent(arg)
else
	local candidate = Rime.getCandidates()[0].text
	if utf8.len(candidate) >= 2 then
		if arg == "Left" then
			service.sendEvent("Retype")
			service.commitText(utf8.sub(candidate, 1, 1))
		elseif arg == "Right" then
			service.sendEvent("Retype")
			service.commitText(utf8.sub(candidate, -1))
		end
	else
		service.sendEvent("space")
	end
end