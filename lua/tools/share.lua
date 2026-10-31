-- Client for share/file_share.py
-- Usage:
--   share list
--   share get <file> [file...]    download (overwrites)
--   share put <file> [file...]    upload
--   share pull                    download every file on the server
--   share get all                 same as pull
--   share config <url> [token]    save server address, e.g. http://192.168.1.5:8080

local CONFIG = ".share_config"

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

local function get(cfg, name)
    local data = request(cfg, "/files/" .. textutils.urlEncode(name):gsub("%%2F", "/"))
    local dir = fs.getDir(name)
    if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
    local f = fs.open(name, "wb")
    f.write(data)
    f.close()
    print("Downloaded: " .. name)
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
elseif cmd == "pull" or (cmd == "get" and arg[2] == "all") then
    local cfg = loadConfig()
    for name in request(cfg, "/list"):gmatch("[^\n]+") do get(cfg, name) end
else
    print("Usage: share config <url> [token]")
    print("       share list | pull")
    print("       share get <file...> | put <file...>")
end
