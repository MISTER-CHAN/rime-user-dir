if service.isLandscape() and service.getRootView().getChildAt(1).getChildAt(2).getChildAt(0).getKeyboard().getName():find("橫屛") == nil then
	service.sendEvent("Keyboard_default")
end