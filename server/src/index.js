import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { openDatabase } from './db.js';
import { createGatewayServer } from './gateways.js';

const serverDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const config = JSON.parse(readFileSync(join(serverDir, 'config.json'), 'utf8'));

const db = openDatabase(join(serverDir, config.databasePath));

// Plain HTTP for now. The UI and its login come in step 6.
const httpServer = createServer((req, res) => {
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('not found');
});

createGatewayServer({ httpServer, db, config });

httpServer.listen(config.port, config.host, () => {
  console.log(`turtlenet server listening on ${config.host}:${config.port} (gateways at /gateway)`);
});

function shutdown() {
  console.log('shutting down');
  httpServer.close();
  db.close();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
