-- Client for share/file_share.py
-- Usage:
--   share list
--   share get <file> [file...]    download (overwrites)
--   share put <file> [file...]    upload
--   share pull [type]             download this computer's files, e.g. share pull turtle
--   share get all                 same as pull with no type
--   share config <url> [token]    save server address, e.g. http://192.168.1.5:8080
--
-- Server folders keep their names on the computer: turtle/agent.lua -> /turtle/agent.lua.
-- A pull of <type> brings down <type>/ and lib/, plus every *.conf and *.config file.
-- tools/share.lua always lands at /share.lua, whatever the type.

local CONFIG = "/.share_config"
local SHARED_FOLDER = "lib"
local SELF_PATH = "tools/share.lua"
local SELF_DEST = "/share.lua"

local function loadConfig()
    if not fs.exists(CONFIG) then
        error("Not configured. Run: share config <url> [token]", 0)
    end
    local f = fs.open(CONFIG, "r")
    local cfg = textutils.unserialize(f.readAll())
    f.close()
    return cfg
end

local function request(cfg, path, body)
    local headers = {}
    if cfg.token then headers["X-Token"] = cfg.token end
    local url = cfg.url:gsub("/+$", "") .. path
    local res, err, errRes
    if body then
        res, err, errRes = http.post(url, body, headers, true)
    else
        res, err, errRes = http.get(url, headers, true)
    end
    if not res then
        local detail = err or "unknown error"
        if errRes then detail = detail .. " (" .. errRes.getResponseCode() .. ")" end
        error("Request failed: " .. detail, 0)
    end
    local data = res.readAll()
    res.close()
    return data
end

-- Where a server file goes on this computer, or nil when a pull of typeName skips it.
-- With no typeName every file is kept.
local function destinationFor(serverPath, typeName)
    if serverPath == SELF_PATH then return SELF_DEST end
    if typeName == nil then return "/" .. serverPath end

    local folder = serverPath:match("^([^/]+)/")
    if folder == typeName or folder == SHARED_FOLDER then return "/" .. serverPath end

    -- Root-level config files come down for every type. Folder configs stay with their folder,
    -- so a turtle never gets the gateway's secret.
    local isConfig = serverPath:match("%.conf$") or serverPath:match("%.config$")
    if folder == nil and isConfig then return "/" .. serverPath end
    return nil
end

local function get(cfg, name, dest)
    dest = dest or name
    local data = request(cfg, "/files/" .. textutils.urlEncode(name):gsub("%%2F", "/"))
    local dir = fs.getDir(dest)
    if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
    local f = fs.open(dest, "wb")
    f.write(data)
    f.close()
    print("Downloaded: " .. dest)
end

local function pull(cfg, typeName)
    local pulled = 0
    for serverPath in request(cfg, "/list"):gmatch("[^\n]+") do
        local dest = destinationFor(serverPath, typeName)
        if dest then
            get(cfg, serverPath, dest)
            pulled = pulled + 1
        end
    end
    if pulled == 0 then error("Nothing on the server for: " .. (typeName or "all"), 0) end
end

local function put(cfg, name)
    if not fs.exists(name) or fs.isDir(name) then
        print("Skipping (not a file): " .. name)
        return
    end
    local f = fs.open(name, "rb")
    local data = f.readAll()
    f.close()
    request(cfg, "/files/" .. textutils.urlEncode(name):gsub("%%2F", "/"), data)
    print("Uploaded: " .. name)
end

local cmd = arg[1]

if cmd == "config" and arg[2] then
    local f = fs.open(CONFIG, "w")
    f.write(textutils.serialize({ url = arg[2], token = arg[3] }))
    f.close()
    print("Saved.")
elseif cmd == "list" then
    print(request(loadConfig(), "/list"))
elseif cmd == "get" and arg[2] and arg[2] ~= "all" then
    local cfg = loadConfig()
    for i = 2, #arg do get(cfg, arg[i]) end
elseif cmd == "put" and arg[2] then
    local cfg = loadConfig()
    for i = 2, #arg do put(cfg, arg[i]) end
elseif cmd == "pull" then
    pull(loadConfig(), arg[2])
elseif cmd == "get" and arg[2] == "all" then
    pull(loadConfig(), nil)
else
    print("Usage: share config <url> [token]")
    print("       share list")
    print("       share pull [type]        e.g. share pull turtle | gateway")
    print("       share get <file...> | put <file...>")
end
