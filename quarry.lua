-- Requirements --
local extendedTurtle = require("extendedTurtle")
local inventory = require("inventory")

-- Functions --

local function checkInventory()
    if not inventory.allSlotsContainItems() then return end

    local containerName = "kibe:entangled_chest"
    local found, slot = inventory.findItem(containerName)

    if not found then return end

    inventory.placeItemUpFromSlotFromSlot(slot)
    
    for i = 1, 16 do
        turtle.select(i)

        local containerHasSpace = turtle.dropUp()
        while containerHasSpace and inventory.hoveringOverItem() do
            containerHasSpace = turtle.dropUp()
        end
    end

    extendedTurtle.clearObstructionsUp()
end

-- Main Code --

if #arg < 6 then 
    print("Usage: quarry size: <width> <length> <depth> position: <x> <y> <z>");
end

local w = tonumber(arg[1]);
local l = tonumber(arg[2]);
local d = tonumber(arg[3]);
local startPoint = vector.new(tonumber(arg[4]), tonumber(arg[5]), tonumber(arg[6]))

extendedTurtle.moveTo(startPoint)

local dirToggle = true;

for i = 1, d, 1 do
    for j = 1, l, 1 do
        for k = 2, w, 1 do
            extendedTurtle.forward();
        end

        if j ~= l then 
            
            if dirToggle then
                extendedTurtle.turnRight();
                extendedTurtle.forward()
                extendedTurtle.turnRight()
                -- write("R F R ")

            else
                extendedTurtle.turnLeft()
                extendedTurtle.forward()
                extendedTurtle.turnLeft()
                -- write("L F L ")

            end

            dirToggle = not dirToggle;
        end

        checkInventory()
    end
    extendedTurtle.down()
    extendedTurtle.turnRight()
    extendedTurtle.turnRight()
    -- write("D 180 \n")

end