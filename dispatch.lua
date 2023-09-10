local inventory = require("inventory")

local function createRect(x, z, width, height)
    return { x, z, width, height }
end

local function divideRect(n, x, z, width, length)
    local subRectangles = {}

    if n <= 0 then
        print("cannot divide into 0 rectangles")
        return nil
    end

    if n == 1 then
        -- Return the starting rectangle if no divisions are required
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
            local subX = x + col * subWidth
            local subZ = z + row * subLength
            table.insert(subRectangles, createRect(subX, subZ, subWidth, subLength))
        end
    end

    return subRectangles
end

local function deploy(pos, w, l, d)
    -- place turtle
    local found, slot = inventory.findItem("computercraft:turtle_expanded")
    
    if not found then
        print("dispatch requires units!")
        return
    end

    inventory.placeItemUpFromSlot(slot)    
    
    -- provide fuel

    -- provide ender chest

    -- send away

    -- instruct return
end

-- Main Code --

rednet.open("left")

local command = ""
local instrunctions = {}
local validCommands = { "travel.lua", "quarry.lua", "betaTravel.lua" }
local recommendedMaxBlocksPerUnit = 1000

repeat
    local id, msg = rednet.receive()
    print(("Computer %d sent message %s"):format(id, msg))

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
local availableUnitCount = inventory.getTotalItemCount("computercraft:turtle_expanded")

local subRectangles = {} | nil
if availableUnitCount > recommendedUnitCount then
    -- Send recommendedUnitCount
    subRectangles = divideRect(recommendedUnitCount, pos.x, pos.z, w, l)
else
    -- Send availableUnitCount
    subRectangles = divideRect(recommendedUnitCount, pos.x, pos.z, w, l)
end

for i = 1, #subRectangles do
    local subRectangle = subRectangles[i]

    deploy(vector.new(subRectangle.x, pos.y - 2, subRectangle.z), vector.new(w, l, d))
end
