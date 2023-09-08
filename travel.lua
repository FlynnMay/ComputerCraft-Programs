-- Helper Functions--
local function calibrateHeading()
    local locOrigin = vector.new(gps.locate(2, false))

    if not turtle.forward() then
        turtle.dig()
        turtle.forward()
    end
    local locEnding = vector.new(gps.locate(2, false))

    local heading = locEnding - locOrigin
    
    --[[
        -x = 1
        -z = 2
        +x = 3
        +z = 4
    --]]

    return ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
end

-- Main Code --
if #arg < 3 then
    print("Usage: travel <x> <y> <z>");
end

local pos = gps.locate()

local target = vector.new(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]))

print(calibrateHeading())