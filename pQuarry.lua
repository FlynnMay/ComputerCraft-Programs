if #arg < 3 then
    print("Usage: quarry size: <width> <length> <depth>");
end

local w = tonumber(arg[1]);
local l = tonumber(arg[2]);
local d = tonumber(arg[3]);

peripheral.find("modem", rednet.open)

local pos = vector.new(gps.locate())

rednet.send(0, "dispatch ".. w .. " " .. l .. " " .. d .. " " .. math.floor(pos.x) - (w / 2).. " " .. math.floor((pos.y) - 2) .. " "  .. math.floor(pos.z) - (l / 2))