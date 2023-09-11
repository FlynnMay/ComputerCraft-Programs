local SERVER_PORT = 1997
local CLIENT_PORT = 18

local inventory = require("inventory")
local extendedTurtle = require("extendedTurtle")
local modem = peripheral.wrap("left")
modem.open(SERVER_PORT)


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


local function createRect(x, z, width, length)
    local rect = {}
    rect.width = width
    rect.length = length
    rect.x = x
    rect.z = z

    return rect
end

local function divideRect(n, x, z, width, length)
    local subRectangles = {}

    if n <= 0 then
        print("cannot divide into 0 rectangles")
        return subRectangles
    end

    if n == 1 then
        -- Return the starting rectangle if no divisions are required
        print(string.format("Pos: [x: %d, z: %d] | Size: [w: %d, l: %d]", x, z, width, length))
        table.insert(subRectangles, createRect(x, z, width, length))
        return subRectangles
    end

    -- Calculate the number of rows and colums for the sub rectangles
    local numRows = math.sqrt(n)
    local numCols = n / numRows

    -- Calculate the width and height of each sub rectangle
    local subWidth = width / numCols
    local subLength = length / numRows

    -- Generate the sub rectangles
    for row = 1, numRows do
        for col = 1, numCols do
            local subX = x + (col - 1) * subWidth
            local subZ = z + (row - 1) * subLength
            table.insert(subRectangles, createRect(subX, subZ, subWidth, subLength))
        end
    end

    return subRectangles
end

local function getDirectionToCoordinate(targetX, targetZ)
    local currentX, _, currentZ = gps.locate()

    if not currentX then
        print("GPS signal not found. Unable to determine current position.")
        return nil
    end

    local deltaX = targetX - currentX
    local deltaZ = targetZ - currentZ

    if math.abs(deltaX) > math.abs(deltaZ) then
        if deltaX < 0 then
            return 1 -- -x
        else
            return 3 -- +x
        end
    else
        if deltaZ < 0 then
            return 2 -- -z
        else
            return 4 -- +z
        end
    end
end

local function deploy(targetPos, w, l, d)
    -- turn to closest position
    local desiredHeading = getDirectionToCoordinate(targetPos.x, targetPos.z)
    extendedTurtle.face(desiredHeading)

    -- place turtle
    local found, slot = inventory.findItem("computercraft:turtle_normal")

    if not found then
        print("dispatch requires units!")
        return
    end

    inventory.placeItemFromSlot(slot)
    os.sleep(.4)
    peripheral.call("front", "turnOn")
    -- provide ender chest
    local found, slot = inventory.findItem("kibe:entangled_chest")

    if found then
        turtle.select(slot)
        turtle.drop(1)
    end
    
    -- wait for client to connect to the server
    local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")

    if msg ~= "Dispatched_Connection_Established" then
        print("Client not found")
        os.exit()
    end

    -- provide fuel

    -- send away
    local payload = string.format("%d %d %d %d %d %d %d", w, l, d, targetPos.x, targetPos.y, targetPos.z, found)
    print(payload)
    modem.transmit(CLIENT_PORT, SERVER_PORT, payload)
end

-- Main Code --

rednet.open("left")

extendedTurtle.init()
extendedTurtle.turnRight()
extendedTurtle.turnRight()
extendedTurtle.forward()

local command = ""
local instrunctions = {}
local validCommands = { "dispatch" }
local recommendedMaxBlocksPerUnit = 100

repeat
    local id, msg = rednet.receive()
    -- print(("Computer %d sent message %s"):format(id, msg))

    if msg ~= nil then
        instrunctions = string.split(msg, ' ')
        command = table.remove(instrunctions, 1)
    end
until tableContainsValue(validCommands, command)

local w = tonumber(instrunctions[1])
local l = tonumber(instrunctions[2])
local d = tonumber(instrunctions[3])
local pos = vector.new(tonumber(instrunctions[4]), tonumber(instrunctions[5]), tonumber(instrunctions[6]))

local totalBlocksToMine = w * l * d
local recommendedUnitCount = totalBlocksToMine / recommendedMaxBlocksPerUnit
local availableUnitCount = inventory.getTotalItemCount("computercraft:turtle_normal")

local subRectangles = {}
-- if availableUnitCount > recommendedUnitCount then
--     -- Send recommendedUnitCount
--     subRectangles = divideRect(recommendedUnitCount < 1 and 1 or recommendedUnitCount, pos.x, pos.z, w, l)
-- else
--     -- Send availableUnitCount
--     subRectangles = divideRect(availableUnitCount, pos.x, pos.z, w, l)
-- end
subRectangles = divideRect(availableUnitCount, pos.x, pos.z, w, l)

for i = 1, #subRectangles do
    while turtle.detect() do
        os.sleep(.3)
    end

    local subRectangle = subRectangles[i]
    deploy(vector.new(subRectangle.x, pos.y, subRectangle.z), subRectangle.width, subRectangle.length, d)
end
