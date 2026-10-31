// Stands in for the in-game gateway. Run with the server already started:
//   npm run test:gateway
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';
import { MSG, makeEnvelope } from '../../shared/protocol.js';

const serverDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const config = JSON.parse(readFileSync(join(serverDir, 'config.json'), 'utf8'));
const gw = config.gateways[0];
const url = `ws://${config.host}:${config.port}/gateway`;

function open(origin) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url, origin ? { headers: { Origin: origin } } : undefined);
    ws.once('open', () => resolve(ws));
    ws.once('error', reject);
  });
}

// Wait for the next message of a given type from the server.
function nextOfType(ws, type) {
  return new Promise((resolve) => {
    const onMessage = (data) => {
      const env = JSON.parse(data.toString());
      if (env.type === type) {
        ws.off('message', onMessage);
        resolve(env);
      }
    };
    ws.on('message', onMessage);
  });
}

const results = [];
function check(name, ok, detail = '') {
  results.push(ok);
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ` (${detail})` : ''}`);
}

// 1. Wrong secret is rejected.
{
  const ws = await open();
  const reply = nextOfType(ws, MSG.HELLO_ERR);
  ws.send(JSON.stringify(makeEnvelope(MSG.HELLO, { gatewayId: gw.id, secret: 'wrong' }, { gatewayId: gw.id })));
  const env = await reply;
  check('wrong secret gets hello_err', env.payload.reason === 'authentication failed');
}

// 2. Origin header is rejected (browsers send one, gateways don't).
{
  // The server accepts the handshake and then closes, so wait for the close.
  const s = new WebSocket(url, { headers: { Origin: 'https://evil.example' } });
  const closed = await new Promise((resolve) => s.once('close', (code) => resolve(code)));
  check('browser origin is rejected', closed === 1008);
}

// 3. Correct hello gets hello_ack. Then a status message is acked, a duplicate is still acked,
//    and a ping gets a pong.
const ws = await open();
{
  const ack = nextOfType(ws, MSG.HELLO_ACK);
  ws.send(JSON.stringify(makeEnvelope(MSG.HELLO, { gatewayId: gw.id, secret: gw.secret, name: 'test' }, { gatewayId: gw.id })));
  const env = await ack;
  check('correct hello gets hello_ack', env.payload.gatewayId === gw.id);
}

const status = makeEnvelope(
  MSG.TURTLE_STATUS,
  { turtleId: 7, label: 'quarry-1', fuel: 500, pos: { x: 10, y: 64, z: -3 }, job: null },
  { gatewayId: gw.id }
);

{
  const ack = nextOfType(ws, MSG.ACK);
  ws.send(JSON.stringify(status));
  const env = await ack;
  check('status is acked', env.payload.ref === status.id);
}

{
  const ack = nextOfType(ws, MSG.ACK);
  ws.send(JSON.stringify(status));
  const env = await ack;
  check('duplicate status is still acked', env.payload.ref === status.id);
}

{
  const pong = nextOfType(ws, MSG.PONG);
  ws.send(JSON.stringify(makeEnvelope(MSG.PING, {}, { gatewayId: gw.id })));
  await pong;
  check('ping gets pong', true);
}

// 4. A message with a gatewayId that doesn't match the connection is refused.
{
  const err = nextOfType(ws, MSG.ERROR);
  ws.send(JSON.stringify(makeEnvelope(MSG.TURTLE_STATUS, { turtleId: 1 }, { gatewayId: 'someone-else' })));
  const env = await err;
  check('mismatched gatewayId is refused', env.payload.message.includes('does not match'));
}

ws.close();

const failed = results.filter((ok) => !ok).length;
console.log(failed === 0 ? `all ${results.length} checks passed` : `${failed} of ${results.length} checks failed`);
process.exit(failed === 0 ? 0 : 1);
