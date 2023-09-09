
if #arg < 6 then 
    print("Usage: quarry size: <width> <length> <depth> position: <x> <y> <z>");
end

local extendedTurtle = require("extendedTurtle")

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
    end
    extendedTurtle.down()
    extendedTurtle.turnRight()
    extendedTurtle.turnRight()
    -- write("D 180 \n")

end