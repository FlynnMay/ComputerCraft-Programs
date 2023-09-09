function string.split(inputString, delimiter)
    local substrings = {}
    local pattern = "[^" .. delimiter .. "]+"
    
    for match in inputString:gmatch(pattern) do
        table.insert(substrings, match)
    end
    
    return substrings
end

local function tableContainsValue(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end


rednet.open("left")

local command = ""
local instrunctions = {}
local validCommands = {"travel.lua"}

repeat
    local id, msg = rednet.receive()
    print(("Computer %d sent message %s"):format(id, msg))

    if msg ~= nil then
        instrunctions = string.split(msg, ' ')
        command = table.remove(instrunctions, 1)
    end
        
until tableContainsValue(validCommands, command)

local args = ""
for _, value in ipairs(instrunctions) do
    args = args .. " " .. value
end

os.run({}, command, args)