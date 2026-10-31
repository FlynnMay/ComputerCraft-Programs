-- Turtle agent: sends heartbeats to the gateway and runs one job at a time.
-- Config lives in "/turtle/agent.config" on the turtle. See agent.config.example.
-- Each job type needs an entry in JOB_RUNNERS and a matching one in shared/protocol.js.

package.path = package.path .. ";/lib/?.lua"
local protocol = require("protocol")
local MSG = protocol.MSG
local REPORT_STATE = protocol.REPORT_STATE

local config = dofile("/turtle/agent.config")

local HEARTBEAT_EVERY = config.heartbeatEvery or 15

local currentJob = nil
local pendingJob = nil
-- Last finished job report. Resent on every heartbeat until the turtle takes a new job,
-- because rednet doesn't say whether the gateway got it.
local pendingReport = nil

local function log(...)
    print(os.date("%H:%M:%S"), ...)
end

local function send(msgType, payload)
    rednet.send(config.gatewayComputerId, protocol.payload(msgType, payload), protocol.REDNET_PROTOCOL)
end

-- Each runner gets the job args and returns true when the job succeeded.
local JOB_RUNNERS = {
    quarry = function(args)
        return shell.run(("/turtle/quarry.lua %d %d %d %d %d %d"):format(
            args.width, args.length, args.depth, args.x, args.y, args.z
        ))
    end,
}

-- Run a job with its timeout. Returns the report fields for the outcome.
local function runJob(job)
    local runner = JOB_RUNNERS[job.type]
    if runner == nil then
        return { state = REPORT_STATE.FAILED, error = "unknown job type " .. tostring(job.type) }
    end

    local outcome = nil
    parallel.waitForAny(
        function()
            local ok, result = pcall(runner, job.args)
            if ok and result then
                outcome = { state = REPORT_STATE.DONE }
            else
                outcome = { state = REPORT_STATE.FAILED, error = ok and "program failed" or tostring(result) }
            end
        end,
        function()
            local timer = os.startTimer(job.timeoutSec)
            repeat
                local _, id = os.pullEvent("timer")
            until id == timer
            outcome = { state = REPORT_STATE.FAILED, error = "timed out" }
        end
    )
    return outcome
end

local function sendHeartbeat()
    local fuel = turtle.getFuelLevel()
    send(MSG.TURTLE_STATUS, {
        label = os.getComputerLabel(),
        -- Creative turtles report "unlimited" here, which isn't a number.
        fuel = type(fuel) == "number" and fuel or nil,
        job = currentJob and { jobId = currentJob.jobId } or nil,
    })
    if pendingReport then
        send(MSG.JOB_REPORT, pendingReport)
    end
end

local function handleGatewayMessage(message)
    if type(message) ~= "table" or message.type ~= MSG.JOB_ASSIGN then return end

    local job = message.payload
    if type(job) ~= "table" or job.turtleId ~= os.getComputerID() then return end
    if type(job.jobId) ~= "string" then return end

    if currentJob or pendingJob then
        log("rejected job", job.jobId, "- busy")
        return send(MSG.JOB_REPORT, { jobId = job.jobId, state = REPORT_STATE.FAILED, error = "busy" })
    end

    pendingReport = nil
    pendingJob = job
    os.queueEvent("job_ready")
end

-- Takes jobs off pendingJob one at a time. Runs in parallel with the network loop,
-- so heartbeats keep going during a long job.
local function jobLoop()
    while true do
        while pendingJob == nil do
            os.pullEvent("job_ready")
        end

        local job = pendingJob
        pendingJob = nil
        currentJob = job

        log("job", job.jobId, job.type)
        send(MSG.JOB_REPORT, { jobId = job.jobId, state = REPORT_STATE.ACCEPTED })

        local outcome = runJob(job)
        outcome.jobId = job.jobId
        log("job", job.jobId, outcome.state, outcome.error or "")

        currentJob = nil
        pendingReport = outcome
        send(MSG.JOB_REPORT, outcome)
    end
end

local function networkLoop()
    sendHeartbeat()
    local heartbeat = os.startTimer(HEARTBEAT_EVERY)

    while true do
        local event, a, b, c = os.pullEvent()

        if event == "rednet_message" then
            -- a = sender id, b = message, c = protocol
            if a == config.gatewayComputerId and c == protocol.REDNET_PROTOCOL then
                handleGatewayMessage(b)
            end

        elseif event == "timer" and a == heartbeat then
            sendHeartbeat()
            heartbeat = os.startTimer(HEARTBEAT_EVERY)
        end
    end
end

rednet.open(config.modemSide)
log("agent", os.getComputerID(), "starting, gateway", config.gatewayComputerId)
parallel.waitForAny(networkLoop, jobLoop)
