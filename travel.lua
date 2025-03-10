-- Helper Functions--
local function calibrateHeading()
    local locOrigin = vector.new(gps.locate(2, false))

    if not turtle.forward() then
        turtle.dig()
        turtle.forward()
    end
    local locEnding = vector.new(gps.locate(2, false))

    local heading = locEnding - locOrigin

    return ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
end

local function sortCoordinatesDescending(vec)
    local coordinatePairs = { { "x", vec.x }, { "y", vec.y }, { "z", vec.z } }
    table.sort(coordinatePairs, function(a, b)
        return a[2] > b[2]
    end)

    return coordinatePairs
end

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

        if (axisName == "y") then
            for i = 1, math.abs(length) do
                if length > 0 then
                    table.insert(actions, turtle.digUp)
                    table.insert(actions, turtle.up)
                elseif length < 0 then
                    table.insert(actions, turtle.digDown)
                    table.insert(actions, turtle.down)
                end
            end
        else
            local targetHeading = headingEncodeMap[axisHeading];
            local neededRot = targetHeading - lastHeading;
            for i = 1, math.abs(neededRot) do
                table.insert(actions, neededRot > 0 and turtle.turnRight or turtle.turnLeft)
            end

            for i = 1, math.abs(length) do
                    table.insert(actions, turtle.dig)
                    table.insert(actions, turtle.forward)
            end
            lastHeading = targetHeading;
        end
        -- end
    end

    return actions;
end

-- Main Code --
if #arg < 3 then
    print("Usage: travel <x> <y> <z>");
end

local heading = calibrateHeading();

local pos = vector.new(gps.locate())

local target = vector.new(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]))

local travelDistances = sortCoordinatesDescending(target - pos);

local actions = buildTravelActions(heading, travelDistances)

for _, action in ipairs(actions) do
    action()
end
