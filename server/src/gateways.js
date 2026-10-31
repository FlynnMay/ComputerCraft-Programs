import { createHash, timingSafeEqual } from 'node:crypto';
import { WebSocketServer } from 'ws';
import { MSG, makeEnvelope, validateEnvelope } from '../../shared/protocol.js';
import { logEvent } from './db.js';

const HELLO_TIMEOUT_MS = 5000;
const MAX_FRAME_BYTES = 64 * 1024;

const digest = (text) => createHash('sha256').update(text).digest();

// Compare hashes so both inputs are the same length, then compare in constant time.
const sameSecret = (given, expected) => timingSafeEqual(digest(given), digest(expected));

// Accepts gateway WebSocket connections on /gateway. Only gateways listed in the config may connect.
export function createGatewayServer({ httpServer, db, config }) {
  const gateways = new Map(config.gateways.map((g) => [g.id, g]));
  const maxFailures = config.auth.maxFailures;
  const blockMs = config.auth.blockMinutes * 60 * 1000;

  const online = new Map(); // gatewayId -> ws
  const failures = new Map(); // ip -> { count, blockedUntil }

  const upsertGateway = db.prepare(
    `INSERT INTO gateways (id, name) VALUES (?, ?)
     ON CONFLICT(id) DO UPDATE SET name = excluded.name`
  );
  const setOnline = db.prepare('UPDATE gateways SET online = ?, last_seen = ? WHERE id = ?');
  const insertMessage = db.prepare(
    `INSERT OR IGNORE INTO messages (gateway_id, msg_id, direction, type, payload_json, acked, created_at)
     VALUES (?, ?, 'in', ?, ?, 1, ?)`
  );

  for (const g of config.gateways) upsertGateway.run(g.id, g.name);

  const wss = new WebSocketServer({ server: httpServer, path: '/gateway', maxPayload: MAX_FRAME_BYTES });

  function isBlocked(ip) {
    const entry = failures.get(ip);
    return entry !== undefined && entry.blockedUntil > Date.now();
  }

  function recordFailure(ip, kind, detail) {
    const entry = failures.get(ip) ?? { count: 0, blockedUntil: 0 };
    entry.count += 1;
    if (entry.count >= maxFailures) {
      entry.blockedUntil = Date.now() + blockMs;
      entry.count = 0;
    }
    failures.set(ip, entry);
    logEvent(db, { kind, sourceIp: ip, detail });
  }

  function send(ws, type, payload) {
    ws.send(JSON.stringify(makeEnvelope(type, payload)));
  }

  function reject(ws, ip, kind, reason) {
    recordFailure(ip, kind, { reason });
    try {
      send(ws, MSG.HELLO_ERR, { reason });
    } finally {
      ws.close(1008, reason);
    }
  }

  wss.on('connection', (ws, req) => {
    const ip = req.socket.remoteAddress;

    // Gateways are computers, so they never send an Origin header. A browser always does.
    if (req.headers.origin !== undefined) {
      logEvent(db, { kind: 'origin_rejected', sourceIp: ip, detail: { origin: req.headers.origin } });
      ws.close(1008, 'origin not allowed');
      return;
    }

    if (isBlocked(ip)) {
      logEvent(db, { kind: 'blocked_ip_rejected', sourceIp: ip });
      ws.close(1008, 'too many failed attempts');
      return;
    }

    let gatewayId = null;

    const helloTimer = setTimeout(() => {
      if (gatewayId === null) reject(ws, ip, 'auth_failed', 'hello timeout');
    }, HELLO_TIMEOUT_MS);

    ws.on('message', (data) => {
      let env;
      try {
        env = JSON.parse(data.toString());
      } catch {
        return gatewayId === null ? reject(ws, ip, 'auth_failed', 'invalid JSON') : undefined;
      }

      const problem = validateEnvelope(env);
      if (problem !== null) {
        if (gatewayId === null) return reject(ws, ip, 'auth_failed', problem);
        return send(ws, MSG.ERROR, { message: problem });
      }

      if (gatewayId === null) {
        clearTimeout(helloTimer);
        return handleHello(ws, env, ip);
      }

      if (env.gatewayId !== gatewayId) {
        return send(ws, MSG.ERROR, { message: 'gatewayId does not match this connection' });
      }

      handleMessage(ws, env);
    });

    function handleHello(socket, env, sourceIp) {
      const claimed = env.payload;
      const known = gateways.get(claimed.gatewayId);
      const valid =
        env.type === MSG.HELLO &&
        env.gatewayId === claimed.gatewayId &&
        known !== undefined &&
        sameSecret(claimed.secret, known.secret);

      if (!valid) {
        // Same message for every failure, so an attacker can't tell which gateway ids exist.
        return reject(socket, sourceIp, 'auth_failed', 'authentication failed');
      }

      // A reconnect replaces the old socket for the same gateway.
      const previous = online.get(known.id);
      if (previous !== undefined && previous !== socket) previous.close(1000, 'replaced by new connection');

      gatewayId = known.id;
      online.set(gatewayId, socket);
      failures.delete(sourceIp);
      setOnline.run(1, Date.now(), gatewayId);
      logEvent(db, { kind: 'gateway_connected', sourceIp, gatewayId });
      console.log(`gateway ${gatewayId} connected from ${sourceIp}`);

      send(socket, MSG.HELLO_ACK, { gatewayId, serverTime: Date.now() });
    }

    function handleMessage(socket, env) {
      if (env.type === MSG.PING) return send(socket, MSG.PONG, {});

      // Store the message and ack it. The gateway clears its outbox on the ack. A duplicate
      // (same id after a reconnect) is ignored by the UNIQUE constraint but still acked.
      insertMessage.run(gatewayId, env.id, env.type, JSON.stringify(env.payload), Date.now());
      console.log(`[${gatewayId}] ${env.type} ${env.id}`);
      send(socket, MSG.ACK, { ref: env.id });
    }

    ws.on('close', () => {
      clearTimeout(helloTimer);
      if (gatewayId === null) return;
      if (online.get(gatewayId) === ws) {
        online.delete(gatewayId);
        setOnline.run(0, Date.now(), gatewayId);
        logEvent(db, { kind: 'gateway_disconnected', sourceIp: ip, gatewayId });
        console.log(`gateway ${gatewayId} disconnected`);
      }
    });

    ws.on('error', (err) => {
      console.error(`socket error from ${ip}:`, err.message);
    });
  });

  return { wss, online };
}
