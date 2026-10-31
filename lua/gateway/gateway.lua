-- Gateway: relays between turtles (rednet) and the PC server (WebSocket).
-- Config lives in "gateway.config" on the gateway computer. See gateway.config.example.

local protocol = require("protocol")
local MSG = protocol.MSG

local config = dofile("gateway.config")

local OUTBOX_LIMIT = 500
local PING_EVERY = 15
local RECONNECT_MIN = 2
local RECONNECT_MAX = 60

local running = true
local ws = nil
local connected = false
local reconnectDelay = RECONNECT_MIN
local reconnectTimer = nil
local pingTimer = nil

-- Messages waiting for an ack from the server. Resent after every reconnect.
local outbox = {}

local function log(...)
    print(os.date("%H:%M:%S"), ...)
end

local function sendRaw(env)
    if ws == nil then return false end
    local ok, err = pcall(ws.send, protocol.encode(env))
    if not ok then log("send failed:", err) end
    return ok
end

local function removeFromOutbox(id)
    for i, env in ipairs(outbox) do
        if env.id == id then
            table.remove(outbox, i)
            return
        end
    end
end

local function queue(env)
    table.insert(outbox, env)
    -- Drop the oldest entries when the server stays away too long, so memory can't grow forever.
    while #outbox > OUTBOX_LIMIT do
        table.remove(outbox, 1)
    end
    if connected then sendRaw(env) end
end

local function flush()
    for _, env in ipairs(outbox) do
        sendRaw(env)
    end
end

local function scheduleReconnect()
    log("reconnecting in", reconnectDelay, "s")
    reconnectTimer = os.startTimer(reconnectDelay)
    reconnectDelay = math.min(reconnectDelay * 2, RECONNECT_MAX)
end

local function connect()
    local socket, err = http.websocket(config.url)
    if not socket then
        log("connect failed:", err)
        return scheduleReconnect()
    end

    ws = socket
    -- The hello is sent directly, not queued. It has to be the first frame on each connection.
    local hello = protocol.envelope(MSG.HELLO, {
        gatewayId = config.gatewayId,
        secret = config.secret,
        name = config.name,
    }, config.gatewayId)

    if not sendRaw(hello) then
        log("could not send hello")
        ws = nil
        scheduleReconnect()
    end
end

local function handleServerFrame(text)
    local env, reason = protocol.decode(text)
    if env == nil then
        return log("bad frame from server:", reason)
    end

    if env.type == MSG.HELLO_ACK then
        connected = true
        reconnectDelay = RECONNECT_MIN
        log("connected as", env.payload.gatewayId)
        flush()
        pingTimer = os.startTimer(PING_EVERY)
    elseif env.type == MSG.HELLO_ERR then
        -- Wrong secret or unknown id. Retrying won't help, so stop.
        log("server refused hello:", env.payload.reason)
        running = false
    elseif env.type == MSG.ACK then
        removeFromOutbox(env.payload.ref)
    elseif env.type == MSG.ERROR then
        log("server error:", env.payload.message)
    end
end

local function handleTurtleMessage(senderId, message)
    if type(message) ~= "table" or type(message.type) ~= "string" then return end

    if message.type ~= MSG.TURTLE_STATUS and message.type ~= MSG.JOB_REPORT then
        return log("ignored", message.type, "from turtle", senderId)
    end

    -- The turtle doesn't know its own gateway. Its computer id goes into the payload here.
    local payload = message.payload or {}
    payload.turtleId = senderId
    queue(protocol.envelope(message.type, payload, config.gatewayId))
end

rednet.open(config.modemSide)
log("gateway", config.gatewayId, "starting, server", config.url)
connect()

while running do
    local event, a, b, c = os.pullEvent()

    if event == "websocket_message" then
        handleServerFrame(b)

    elseif event == "websocket_closed" then
        log("connection closed")
        connected = false
        ws = nil
        pingTimer = nil
        if running then scheduleReconnect() end

    elseif event == "rednet_message" then
        -- a = sender id, b = message, c = protocol
        if c == protocol.REDNET_PROTOCOL then
            handleTurtleMessage(a, b)
        end

    elseif event == "timer" then
        if a == reconnectTimer then
            reconnectTimer = nil
            connect()
        elseif a == pingTimer and connected then
            sendRaw(protocol.envelope(MSG.PING, {}, config.gatewayId))
            pingTimer = os.startTimer(PING_EVERY)
        end
    end
end

if ws then pcall(ws.close) end
log("gateway stopped")
