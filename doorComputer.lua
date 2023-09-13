local modem = peripheral.wrap("top")
local SERVER_PORT = 1876
local CLIENT_PORT = 43

modem.open(SERVER_PORT)


while true do
    modem.transmit(CLIENT_PORT, SERVER_PORT, "ping")

    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    if event ~= nil and message == "pong" and channel == CLIENT_PORT then
        redstone.setOutput("bottom", 0)
    else
        redstone.setOutput("bottom", 1)
    end
    os.sleep(.4)
end