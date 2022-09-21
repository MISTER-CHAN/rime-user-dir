local f = io.open(service.LuaDir .. "/record.txt", "r+")
f:read()
f:write(...)
f:close()