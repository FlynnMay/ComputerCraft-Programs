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

local function sortCoordinatesDescending(vec)
    print(tostring(vec))
    local coordinatePairs = { { "x", vec.x }, { "y", vec.y }, { "z", vec.z } }
    table.sort(coordinatePairs, function(a, b)
        return a[2] > b[2]
    end)

    return coordinatePairs
end

-- local function wrap(value, min, max)
--     if value > max then
--         return wrap(max - value, min, max)
--         elseif value < min then
--             return
--     end


-- end

local function buildTravelActions(heading, distances)
    local lastHeading = heading
    local actions = {}

    local headingDecodeMap = {}
    headingDecodeMap[1] = "-x"
    headingDecodeMap[2] = "-z"
    headingDecodeMap[3] = "+x"
    headingDecodeMap[4] = "+z"

    local headingEncodeMap = {}
    headingEncodeMap["-x"] = 1
    headingEncodeMap["-z"] = 2
    headingEncodeMap["+x"] = 3
    headingEncodeMap["+z"] = 4

    for _, axisPair in ipairs(distances) do
        local axisName = axisPair[1]
        local length = axisPair[2]
        local axisHeading = (length < 0 and "-" or "+") .. axisName

        -- if axisHeading ~= headingDecodeMap[lastHeading] then
        local targetHeading = headingEncodeMap[axisHeading];
        for i = 1, targetHeading % lastHeading do
            table.insert(actions, turtle.turnRight)
        end

        for i = 1, length do
            table.insert(actions, turtle.forward)
        end
        lastHeading = targetHeading;
        -- end
    end
end

-- Main Code --
if #arg < 3 then
    print("Usage: travel <x> <y> <z>");
end

local heading = calibrateHeading();

local pos = gps.locate()

local target = vector.new(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]))

local travelDistances = sortCoordinatesDescending(target - pos);

local actions = buildTravelActions(heading, travelDistances)

for _, action in ipairs(actions) do
    action()
end
