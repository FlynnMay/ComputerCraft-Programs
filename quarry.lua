
if #arg < 3 then 
    print("Usage: quarry <width> <length> <depth>");
end

local w = tonumber(arg[1]);
local l = tonumber(arg[2]);
local d = tonumber(arg[3]);

local dirToggle = true;

for i = 1, d, 1 do
    for j = 1, l, 1 do
        for k = 2, w, 1 do
            turtle.dig();
            turtle.forward();
            -- write("F ")
        end

        if j ~= l then 
            
            if dirToggle then
                turtle.turnRight()
                turtle.dig()
                turtle.forward()
                turtle.turnRight()
                -- write("R F R ")

            else
                turtle.turnLeft()
                turtle.dig()
                turtle.forward()
                turtle.turnLeft()
                -- write("L F L ")

            end

            dirToggle = not dirToggle;
        end
    end
    turtle.digDown()
    turtle.down()
    turtle.turnRight()
    turtle.turnRight()
    -- write("D 180 \n")

end