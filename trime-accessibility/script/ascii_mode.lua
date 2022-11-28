require "import"

local am = ... == "true"
if Rime.getOption("ascii_mode") ~= am then
	Rime.setOption("ascii_mode", am)
end