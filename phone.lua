peripheral.find("modem", rednet.open)

local pos = vector.new(gps.locate())

rednet.send(0, "travel " .. pos.x .. " " .. pos.y.. " "  .. pos.z)
