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


-- Main Code --
if #arg < 1 then
    print("Usage: doorComputer <open threshold> <power output dir>")
end

local openThreshold = tonumber(arg[1])
local outputDir = arg[2]

rednet.open("top")
local pos = vector.new(gps.locate())

while true do
    local senderID, message, protocol = rednet.receive()
    local arguments = string.split(message, ' ')
    local clientPos = stringTableToVector(arguments)
    local distance = (pos - clientPos).length()
    
    redstone.setOutput(outputDir, distance <= openThreshold)
end
