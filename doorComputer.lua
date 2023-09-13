rednet.open("top")


while true do
    local senderID, message, protocol = rednet.receive()

    if protocol == "location" then
        print("Location: " .. message)
        redstone.setOutput("bottom", true)
        print("door found")
    else
        redstone.setOutput("bottom", false)
        print("door not found")
    end

    os.sleep(.4)
end
