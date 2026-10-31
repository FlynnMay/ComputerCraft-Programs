local FILE_PATH = ".quarry_blacklist"

local function getBlacklist()
    local blacklist = {}

    if fs.exists(FILE_PATH) then
        local f = fs.open(FILE_PATH, "r")
        local line = f.readLine()
        while line do
            blacklist[line] = true;
            line = f.readLine()
        end
        f.close()
    end
    return blacklist
end

local function setBlacklist(blacklist)
    local f = fs.open(FILE_PATH, "w")
    for item, _ in pairs(blacklist) do
        f.write(item .. "\n")
    end
    f.close()
end

local function clear()
    local f = fs.open(FILE_PATH, "w")
    f.close()
end

local function registerBlacklistItem(itemName)
    local blacklist = getBlacklist()

    if blacklist[itemName] then
        print("EXISTS: " .. itemName)
        return
    end

    blacklist[itemName] = true
    setBlacklist(blacklist)
    print("Blacklisted: " .. itemName)
end

return {
    get = getBlacklist,
    set = setBlacklist,
    registerItem = registerBlacklistItem,
    clear = clear
}
