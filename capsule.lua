local args = {...}
local tempName = "/.capsule-temp" .. math.random(99999999)
local fsc = fs.combine

local function pack(src,out)

  local function mapFolder(path)
    local content = {}
    for k,v in pairs(fs.list(fsc(src,path))) do
      if(fs.isDir(fsc(fsc(src,path),v))) then
        content[fsc(path,v)] = mapFolder(fsc(path,v))
      else
        local handle = fs.open(fsc(fsc(src,path),v),"r")
        local fileCont = handle.readAll()
        handle.close()
        content[fsc(path,v)] = fileCont
      end
    end
    return content
  end

  local compressed = mapFolder("/")
  local handle = fs.open(out,"w")
  handle.write(textutils.serialize(compressed))
  handle.close()

end

local function unpack(input,baseout)
  local handle = fs.open(input, "r")
  local content = handle.readAll()
  handle.close()
  local compressed = loadstring("return "..content)()

  local function reverse(tbl)
    for k,v in pairs(tbl) do
      if(type(v) == "table") then
        fs.makeDir(fsc(baseout,k))
        reverse(v)
      else
        local handle = fs.open(fsc(baseout,k),"w")
        handle.write(v)
        handle.close()
      end
    end
  end

  reverse(compressed)

end

if(args[1] == "install-capsule-internal") then
  fs.makeDir("/usr/bin/capsule.deps")
  shell.run("/usr/bin/glue init /usr/bin/capsule.deps")
  local handle = fs.open("/usr/bin/capsule.deps/GlueFile","w")
  handle.write([[
  depend "json" namespace "JSON" method "dofile"
  ]])
  handle.close()
  local oldDir = shell.dir()
  shell.setDir("/usr/bin/capsule.deps")
  shell.run("glue install")
  shell.setDir(oldDir)
elseif(args[1] == "uninstall-capsule-internal") then
  fs.delete("/usr/bin/capsule.deps")
else

  shell.run("/usr/bin/capsule.deps/.glue/autoload.lua")

  if(args[1] == "init") then
    local cur
    if(args[2] ~= nil) then
      if(not fs.exists(shell.resolve(args[2]))) then
        fs.makeDir(shell.resolve(args[2]))
      end
      cur = shell.resolve(args[2])
    else
      cur = shell.dir()
    end
    local conf = {}
    conf.name = ""
    conf.version = ""
    conf.author = ""
    conf.command = ""
    local handle = fs.open(fsc(cur,"capsule.json"),"w")
    handle.write(JSON.stringify(conf):gsub("{","{\n"):gsub(",",",\n"):gsub("}","\n}"))
    handle.close()
    shell.run("glue init",args[2])

  elseif(args[1] == "install") then
    local cur = shell.dir()
    if(not fs.exists(fsc(cur, "capsule.json"))) then error() end
    if(not fs.exists(fsc(cur, "GlueFile"))) then error() end
    local handle = fs.open(fsc(cur, "capsule.json"),"r")
    local conf = JSON.parse(handle.readAll())
    handle.close()
    fs.delete(fsc(cur,".glue"))
    fs.delete(fsc(cur,conf.name .. ".capsule"))
    pack(cur,fsc(cur,conf.name .. ".capsule"))
    shell.run("glue install")
  elseif(args[1] == "run") then
    if(args[2] == nil) then error() end
    local file = shell.resolve(args[2])
    local fileName = fs.getName(file)
    print("Starting capsule '"..fileName.."'")
    if(fs.exists(tempName)) then fs.delete(tempName) end
    fs.makeDir(tempName)
    fs.copy(file, fsc(tempName,fileName))
    fs.makeDir(fsc(tempName, "capsule"))
    unpack(fsc(tempName, fileName),fsc(tempName, "capsule"))
    fs.delete(fsc(tempName, fileName))
    local oldDir = shell.dir()
    shell.setDir(fsc(tempName,"capsule"))
    print("Installing dependencies")
    shell.run("glue install")
    local handle = fs.open(fsc(fsc(tempName,"capsule"),"capsule.json"),"r")
    local conf = JSON.parse(handle.readAll())
    handle.close()
    shell.run(conf.command)
    print("Capsule stopped.")
    print("cleaning up...")
    fs.delete(tempName)
    shell.setDir(oldDir)
    print("Done!")
end

end
