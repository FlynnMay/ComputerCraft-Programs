local w = 5;
local l = 5;
local d = 5;

local dirToggle = true;

for i = 0, d -1, 1 do
    for j = 0, l -1, 1 do
        for k = 0, w -1, 1 do
            turtle.dig();
            turtle.forward();
            -- write("F ")
        end

        if j ~= l -1 then 
            
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