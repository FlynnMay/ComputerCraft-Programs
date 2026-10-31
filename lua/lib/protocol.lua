-- Mirror of shared/protocol.js. Keep the two in sync by hand.
-- Gateway <-> server uses JSON text (textutils.serializeJSON). Turtle <-> gateway uses rednet tables.

local protocol = {}

protocol.VERSION = 1
protocol.REDNET_PROTOCOL = "turtlenet"

protocol.MSG = {
    HELLO = "hello",
    HELLO_ACK = "hello_ack",
    HELLO_ERR = "hello_err",
    PING = "ping",
    PONG = "pong",
    ACK = "ack",
    ERROR = "error",

    TURTLE_STATUS = "turtle_status",
    JOB_REPORT = "job_report",

    JOB_ASSIGN = "job_assign",
}

protocol.REPORT_STATE = {
    ACCEPTED = "accepted",
    PROGRESS = "progress",
    DONE = "done",
    FAILED = "failed",
}

-- Unique enough for message and job ids on one computer: time plus a random suffix.
local function newId()
    return os.epoch("utc") .. "-" .. math.random(1, 1000000000)
end

-- Build an envelope for gateway-bound JSON messages. Pass gatewayId for those.
-- Turtle-bound rednet messages use protocol.payload() instead, with no envelope.
function protocol.envelope(msgType, payload, gatewayId)
    return {
        v = protocol.VERSION,
        type = msgType,
        id = newId(),
        ts = os.epoch("utc"),
        gatewayId = gatewayId,
        payload = payload or {},
    }
end

-- Build a bare rednet message: { type, payload }.
function protocol.payload(msgType, payload)
    return { type = msgType, payload = payload or {} }
end

-- Check an envelope from the server. Returns true, or false and a reason.
function protocol.validateEnvelope(env)
    if type(env) ~= "table" then return false, "envelope must be a table" end
    if env.v ~= protocol.VERSION then return false, "unsupported version " .. tostring(env.v) end
    if type(env.id) ~= "string" then return false, "missing id" end
    if type(env.type) ~= "string" then return false, "missing type" end
    if type(env.payload) ~= "table" then return false, "missing payload" end
    return true
end

-- Parse a JSON frame from the server. Returns the envelope, or nil and a reason.
function protocol.decode(text)
    local ok, env = pcall(textutils.unserializeJSON, text)
    if not ok or env == nil then return nil, "invalid JSON" end
    local valid, reason = protocol.validateEnvelope(env)
    if not valid then return nil, reason end
    return env
end

-- Encode an envelope as a JSON frame for the server.
function protocol.encode(env)
    return textutils.serializeJSON(env)
end

return protocol
