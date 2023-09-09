
if #arg < 6 then 
    print("Usage: quarry size: <width> <length> <depth> position: <x> <y> <z>");
end


local w = tonumber(arg[1]);
local l = tonumber(arg[2]);
local d = tonumber(arg[3]);
local startPoint = vector.new(tonumber(arg[4]), tonumber(arg[5], tonumber(arg[6])))

shell.run("travel.lua",   startPoint.x .. " " .. startPoint.y .. " " .. startPoint.z)

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