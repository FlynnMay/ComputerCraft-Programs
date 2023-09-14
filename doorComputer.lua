function string.split(inputString, delimiter)
    local substrings = {}
    local pattern = "[^" .. delimiter .. "]+"

    for match in inputString:gmatch(pattern) do
        table.insert(substrings, match)
    end

    return substrings
end

function stringTableToVector(strTable)
    return vector.new(tonumber(strTable[1]), tonumber(strTable[2]), tonumber(strTable[3]))
end

function keyHoldersToString(keyHolders)
    local clients = ""

    for _, value in ipairs(keyHolders) do
        clients = clients .. " " .. value
    end
    
    return clients
end

local function getDistance(vecA, vecB)
    return (vecA - vecB):length()
end

-- Main Code --
if #arg < 1 then
    print("Usage: doorComputer <tracking server ID> <open threshold> <power output dir> <...ID's to track>")
end

local trackingServerID = tonumber(arg[1])
local openThreshold = tonumber(arg[2])
local outputDir = arg[3]
local keyHolders = {}

for i = 4, #arg, 1 do
    table.insert(keyHolders, arg[i])
end

rednet.open("top")
local pos = vector.new(gps.locate())

while true do
    rednet.send(trackingServerID, keyHoldersToString(), "check")

    local senderID, message, protocol;
    repeat
        senderID, message, protocol = rednet.receive()
    until senderID == trackingServerID and protocol == "returned_values"
    
    local holderPositions = string.split(message, ",")
    local redstoneEnabled = false
    
    for i, keyHolderPosition in ipairs(holderPositions) do
        if getDistance(stringTableToVector(string.split(keyHolderPosition, " ")), pos) <= openThreshold then
            redstoneEnabled = true
            break
        end
    end
    
    redstone.setOutput(outputDir, redstoneEnabled)
end
