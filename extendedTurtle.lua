local trackedHeading = 0;

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

local function clearObstructions()
    while turtle.detect() do
        turtle.dig();
    end
end

local function clearObstructionsUp()
    while turtle.detectUp() do
        turtle.digUp();
    end
end

local function clearObstructionsDown()
    while turtle.detectDown() do
        turtle.digDown();
    end
end

local function down()
    clearObstructionsDown()
    turtle.down()
end

local function up()
    clearObstructionsUp()
    turtle.up()
end

local function forward()
    clearObstructions()
    turtle.forward()
end

local function turnRight()
    turtle.turnRight()
    trackedHeading = trackedHeading + 1
    if trackedHeading > 4 then trackedHeading = trackedHeading - 4 end
end

local function turnLeft()
    turtle.turnLeft()
    trackedHeading = trackedHeading - 1
    if trackedHeading < 1 then trackedHeading = trackedHeading + 4 end
end

local function face(encodedAxis)
    local neededRot = encodedAxis - trackedHeading;
    for i = 1, math.abs(neededRot) do
        if neededRot > 0 then
            turnRight()
        else
            turnLeft()
        end
    end
end

local function init()
    trackedHeading = calibrateHeading();
end

local function sortCoordinatesDescending(vec)
    local coordinatePairs = { { "x", vec.x }, { "y", vec.y }, { "z", vec.z } }
    table.sort(coordinatePairs, function(a, b)
        return a[2] > b[2]
    end)

    return coordinatePairs
end

local function encodeAxis(rawAxis)
    local headingEncodeMap = {}
    headingEncodeMap["-x"] = 1
    headingEncodeMap["-z"] = 2
    headingEncodeMap["+x"] = 3
    headingEncodeMap["+z"] = 4

    return headingEncodeMap[rawAxis]
end

local function decodeAxis(encodedAxis)
    local headingDecodeMap = {}
    headingDecodeMap[1] = "-x"
    headingDecodeMap[2] = "-z"
    headingDecodeMap[3] = "+x"
    headingDecodeMap[4] = "+z"

    return headingDecodeMap[encodedAxis]
end

local function moveTo(coords)
    local heading = calibrateHeading();

    local pos = vector.new(gps.locate())

    local travelDistances = sortCoordinatesDescending(coords - pos);

    for _, axisPair in ipairs(travelDistances) do
        local axisName = axisPair[1]
        local length = axisPair[2]

        if axisName == "y" then
            for i = 1, length do
                if length > 0 then
                    up()
                elseif length < 0 then
                    down()
                end
            end
        else
            local axisHeading = (length < 0 and "-" or "+") .. axisName

            face(encodeAxis(axisHeading));

            for i = 1, length do
                forward()
            end
        end
    end
end

return {
    calibrateHeading = calibrateHeading,
    clearObstructions = clearObstructions,
    clearObstructionsDown = clearObstructionsDown,
    clearObstructionsUp = clearObstructionsUp,
    down = down,
    up = up,
    forward = forward,
    turnRight = turnRight,
    turnLeft = turnLeft,
    face = face,
    init = init,
    sortCoordinatesDescending = sortCoordinatesDescending,
    encodeAxis = encodeAxis,
    decodeAxis = decodeAxis,
    moveTo = moveTo
}
