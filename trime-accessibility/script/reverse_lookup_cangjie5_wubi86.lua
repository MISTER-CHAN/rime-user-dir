require "import"
service.sendEvent("Keyboard_" .. (Rime.getOption("simplification") and "wubi86" or "cangjie5") .. "_reverse_lookup" .. (service.isLandscape() and "_land" or ""))