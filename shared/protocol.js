// Message schema shared by the PC server, the web UI, and (mirrored by hand) lua/lib/protocol.lua.
//
// Two links use this schema:
//   gateway <-> server   WebSocket, JSON text frames. Envelope carries gatewayId.
//   turtle  <-> gateway  rednet, Lua tables. No envelope gatewayId; the gateway adds
//                        turtleId from the rednet sender id when it forwards upward.
//
// Turtles are identified by the pair (gatewayId, turtleId). Computer ids are only unique
// within one world, so turtleId alone is not enough once there is more than one gateway.

export const PROTOCOL_VERSION = 1;

export const MSG = {
  // gateway <-> server
  HELLO: 'hello',
  HELLO_ACK: 'hello_ack',
  HELLO_ERR: 'hello_err',
  PING: 'ping',
  PONG: 'pong',
  ACK: 'ack',
  ERROR: 'error',

  // turtle -> gateway -> server
  TURTLE_STATUS: 'turtle_status',
  JOB_REPORT: 'job_report',

  // server -> gateway -> turtle
  JOB_ASSIGN: 'job_assign',
};

// Job lifecycle. Server owns the transitions; turtles only send job_report.
export const JOB_STATE = {
  QUEUED: 'queued',
  ASSIGNED: 'assigned',
  RUNNING: 'running',
  DONE: 'done',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
  TIMED_OUT: 'timed_out',
};

// Reports a turtle may send about a job it was given.
export const REPORT_STATE = {
  ACCEPTED: 'accepted',
  PROGRESS: 'progress',
  DONE: 'done',
  FAILED: 'failed',
};

const isObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const isId = (v) => typeof v === 'string' && v.length > 0 && v.length <= 64;
const isInt = (v) => Number.isInteger(v);
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);
const isPos = (v) => v === null || (isObject(v) && isInt(v.x) && isInt(v.y) && isInt(v.z));

// Job types. `args` validates the job-specific argument object.
// Add a new job type here and in lua/turtle/agent.lua together.
export const JOB_TYPES = {
  quarry: {
    timeoutSec: 60 * 60,
    args: (a) =>
      isObject(a) &&
      isInt(a.x) && isInt(a.y) && isInt(a.z) &&
      isInt(a.width) && a.width > 0 &&
      isInt(a.length) && a.length > 0 &&
      isInt(a.depth) && a.depth > 0,
  },
};

// Payload validators, keyed by message type. Each returns true when the payload is well formed.
const PAYLOAD = {
  [MSG.HELLO]: (p) =>
    isObject(p) &&
    isId(p.gatewayId) &&
    typeof p.secret === 'string' &&
    (p.name === undefined || typeof p.name === 'string'),
  [MSG.HELLO_ACK]: (p) => isObject(p) && isId(p.gatewayId) && isInt(p.serverTime),
  [MSG.HELLO_ERR]: (p) => isObject(p) && typeof p.reason === 'string',
  // Ping and pong carry no data. Accept any payload, because CC may encode an empty table as [].
  [MSG.PING]: () => true,
  [MSG.PONG]: () => true,
  [MSG.ACK]: (p) => isObject(p) && isId(p.ref),
  [MSG.ERROR]: (p) => isObject(p) && typeof p.message === 'string',

  [MSG.TURTLE_STATUS]: (p) =>
    isObject(p) &&
    (p.turtleId === undefined || isInt(p.turtleId)) &&
    (p.label === undefined || typeof p.label === 'string') &&
    (p.fuel === undefined || p.fuel === null || isInt(p.fuel)) &&
    isPos(p.pos ?? null) &&
    (p.job === undefined || p.job === null || (isObject(p.job) && isId(p.job.jobId))),

  [MSG.JOB_REPORT]: (p) =>
    isObject(p) &&
    isId(p.jobId) &&
    (p.turtleId === undefined || isInt(p.turtleId)) &&
    Object.values(REPORT_STATE).includes(p.state) &&
    (p.progress === undefined || (isNum(p.progress) && p.progress >= 0 && p.progress <= 1)) &&
    (p.result === undefined || isObject(p.result)) &&
    (p.error === undefined || typeof p.error === 'string'),

  [MSG.JOB_ASSIGN]: (p) =>
    isObject(p) &&
    isId(p.jobId) &&
    isInt(p.turtleId) &&
    Object.hasOwn(JOB_TYPES, p.type) &&
    JOB_TYPES[p.type].args(p.args) &&
    isNum(p.timeoutSec) && p.timeoutSec > 0,
};

// Build an envelope. Gateway-bound messages should pass gatewayId; turtle-bound
// messages leave it out.
export function makeEnvelope(type, payload, { id, gatewayId, ts = Date.now() } = {}) {
  const env = { v: PROTOCOL_VERSION, type, id: id ?? randomId(), ts, payload };
  if (gatewayId !== undefined) env.gatewayId = gatewayId;
  return env;
}

// Check an incoming envelope. Returns null when valid, otherwise a short reason string.
export function validateEnvelope(env) {
  if (!isObject(env)) return 'envelope must be an object';
  if (env.v !== PROTOCOL_VERSION) return `unsupported protocol version ${env.v}`;
  if (!isId(env.id)) return 'missing or invalid id';
  if (!isInt(env.ts)) return 'missing or invalid ts';
  if (!Object.hasOwn(PAYLOAD, env.type)) return `unknown message type ${env.type}`;
  if (!PAYLOAD[env.type](env.payload)) return `bad payload for ${env.type}`;
  return null;
}

// Validate a payload directly (used for rednet messages, which have no envelope gatewayId).
export function validatePayload(type, payload) {
  if (!Object.hasOwn(PAYLOAD, type)) return false;
  return PAYLOAD[type](payload);
}

function randomId() {
  return globalThis.crypto.randomUUID();
}
