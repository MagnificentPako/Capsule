local args = {...}
local tempName = "/.capsule-temp"

if(args[1] == "install-capsule-internal") then
  fs.makeDir("/usr/bin/capsule.deps")
  shell.run("/usr/bin/glue init /usr/bin/capsule.deps")
  local handle = fs.open("/usr/bin/capsule.deps/GlueFile","w")
  handle.write([[
  depend "Progdor" version "2" method "ignore"
  depend "json" namespace "JSON" method "dofile"
  ]])
elseif(args[1] == "uninstall-capsule-internal") then
  fs.delete("/usr/bin/capsule.deps")
else

end
