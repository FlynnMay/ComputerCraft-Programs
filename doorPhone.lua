local modem = peripheral.wrap("back")
local SERVER_PORT = 1876
local CLIENT_PORT = 43

modem.open(CLIENT_PORT)

while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    
    if message == "ping" then
        modem.transmit(SERVER_PORT, CLIENT_PORT, "pong")
    end
    print(message)
    
end