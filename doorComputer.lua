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

local function getDirectionToCoordinate(vecA, vecB)
    return (vecA - vecB):normalize()
end

-- Main Code --
if #arg < 1 then
    print("Usage: doorComputer <tracking server ID> <open threshold> <power output dir> <detectDirX> <detectDirY> <detectDirZ> <...ID's to track>")
end

local trackingServerID = tonumber(arg[1])
local openThreshold = tonumber(arg[2])
local outputDir = arg[3]
local detectDir = vector.new(tonumber(arg[4]),tonumber(arg[5]), tonumber(arg[6]))
local keyHolders = {}

for i = 7, #arg, 1 do
    table.insert(keyHolders, arg[i])
end

rednet.open("top")
local pos = vector.new(gps.locate())

while true do
    rednet.send(trackingServerID, keyHoldersToString(keyHolders), "check")

    local senderID, message, protocol = rednet.receive(nil, 1)
    local redstoneEnabled = false
    if senderID == trackingServerID and protocol == "returned_values" then
        local holderPositions = string.split(message, ",")

        for i, keyHolderPosition in ipairs(holderPositions) do
            local target = stringTableToVector(string.split(keyHolderPosition, " "))
            local distance = getDistance(target, pos)
            local dirToTarget = getDirectionToCoordinate(target, pos);
            if distance <= openThreshold and dirToTarget:dot(detectDir) > 0.5 then
                redstoneEnabled = true
                break
            end
        end
    end

    redstone.setOutput(outputDir, redstoneEnabled)
end
