if #arg < 3 then
    print("Usage: quarry size: <width> <length> <depth>");
end

local w = tonumber(arg[1]);
local l = tonumber(arg[2]);
local d = tonumber(arg[3]);

peripheral.find("modem", rednet.open)

local pos = vector.new(gps.locate())

rednet.send(0, "quarry.lua ".. w .. " " .. l .. " " .. d .. " " .. pos.x .. " " .. (pos.y - 2) .. " "  .. pos.z)