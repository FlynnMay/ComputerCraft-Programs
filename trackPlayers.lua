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

local function setSendersPositionInTable(senderID, message, positionTable)
    local arguments = string.split(message, ' ')
    local clientPos = stringTableToVector(arguments)
    positionTable[senderID] = clientPos

    print(string.format("Location Updated: User[%d] Positon[%d %d %d]", senderID, clientPos.x, clientPos.y, clientPos.z))
end

local function sendUsersPositionInTable(returnID, message, positionTable)
    local clientsToGet = string.split(message, ' ')
    local payload = ""

    for _, client in ipairs(clientsToGet) do
        local cPos = positionTable[tonumber(client)]
        if cPos ~= nil then
            payload = payload .. "," .. string.format("%d %d %d", cPos.x, cPos.y, cPos.z)
        end
    end

    rednet.send(returnID, payload, "returned_values")
end


playerPositions = {}

rednet.open("top")

while true do
    local senderID, message, protocol = rednet.receive()
    if senderID == nil then return end

    if protocol == "location" then
        setSendersPositionInTable(senderID, message, playerPositions)
    else
        if protocol == "check" then
            sendUsersPositionInTable(senderID, message, playerPositions)
        end
    end
end
