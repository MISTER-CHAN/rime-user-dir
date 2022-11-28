require "import"

if Rime.getOption("ascii_mode") and "true" or "false" ~= ... then
	Rime.setOption("ascii_mode", ... == "true")
end