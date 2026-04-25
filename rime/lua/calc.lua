return function (input, seg, env)
  if not seg:has_tag("calc") then return end
  local exp = input:sub(2)
  local f, err = load("return " .. exp)
  if type(f) ~= "function" then return end
  local status, err = pcall(f)
  yield(Candidate("string", seg.start, seg._end, tostring(err), "〔計數機〕"))
  if status then
    yield(Candidate("string", seg.start, seg._end, exp .. "=" .. err, "〔計數機〕"))
  end
end
