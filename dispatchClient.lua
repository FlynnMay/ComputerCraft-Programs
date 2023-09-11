local SERVER_PORT = 1997
local CLIENT_PORT = 18
 
local function findModem()
    local sides = {"top", "bottom", "front", "back", "left", "right"}

    for _, side in pairs(sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            local modem = peripheral.wrap(side)
            if modem.isWireless() then
                return modem;    
            end
        end
        
    end
end

local modem = findModem()

modem.open(CLIENT_PORT)

modem.transmit(SERVER_PORT, CLIENT_PORT, "Dispatched_Connection_Established")
local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")

shell.run("quarry", msg)