if #arg < 1 then
    print("Usage: doorPhone <trackingServerId>")
end 

local trackingServerId = tonumber(arg[1])

rednet.open("back")

while true do
    -- Get input from the player or the environment
    local x, y, z = gps.locate()
    local payload = string.format("%d %d %d", x, y, z)
    
    -- Send the input to the main computer
    rednet.send(trackingServerId, payload, "location")
end