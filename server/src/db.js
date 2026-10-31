import { DatabaseSync } from 'node:sqlite';
import { mkdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const schemaPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'schema.sql');

// Open the database, creating the schema on first run.
export function openDatabase(path) {
  mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path);

  const { user_version: version } = db.prepare('PRAGMA user_version').get();
  if (version === 0) {
    db.exec(readFileSync(schemaPath, 'utf8'));
  }

  return db;
}

// Record an audit event. Failures here must not take the server down, so they are logged and swallowed.
export function logEvent(db, { kind, sourceIp = null, userId = null, gatewayId = null, detail = null }) {
  try {
    db.prepare(
      'INSERT INTO events (ts, kind, source_ip, user_id, gateway_id, detail_json) VALUES (?, ?, ?, ?, ?, ?)'
    ).run(Date.now(), kind, sourceIp, userId, gatewayId, detail === null ? null : JSON.stringify(detail));
  } catch (err) {
    console.error('failed to write event', kind, err);
  }
}
