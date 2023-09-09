local extendedTurtle = require("extendedTurtle")

-- Main Code --
if #arg < 3 then
    print("Usage: travel <x> <y> <z>");
end

local target = vector.new(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]))

extendedTurtle.init()

extendedTurtle.moveTo(target)