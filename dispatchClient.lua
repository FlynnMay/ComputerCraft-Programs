local SERVER_PORT = 1997
local CLIENT_PORT = 18
 
local modem = peripheral.wrap("left")
modem.open(CLIENT_PORT)

modem.transmit(SERVER_PORT, CLIENT_PORT, "Dispatched_Connection_Established")
local event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")

shell.run("quarry", msg)