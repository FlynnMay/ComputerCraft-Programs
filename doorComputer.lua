rednet.open("top")


while true do
    local senderID, message, protocol = rednet.receive()

    if protocol == "location" then
        print("Location: " .. message)
        redstone.setOutput("bottom", true)
    else
        redstone.setOutput("bottom", false)
    end

    os.sleep(.4)
end
