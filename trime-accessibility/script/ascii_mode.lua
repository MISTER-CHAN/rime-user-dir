require "import"

local am = Rime.getOption("ascii_mode") and "true" or "false"
if am ~= ... then
	Rime.setOption("ascii_mode", ... == "true")
end