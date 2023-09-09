peripheral.find("modem", rednet.open)

local pos = vector.new(gps.locate())

rednet.send(0, "betaTravel.lua " .. pos.x .. " " .. pos.y.. " "  .. pos.z)
