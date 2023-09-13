rednet.open("top")


while true do
    local senderID, message, protocol = rednet.receive()
    redstone.setOutput("bottom", true)

    if protocol == "location" then
        print("Location: " .. message)
        redstone.setOutput("bottom", false)
        print("door found")
    end
end
