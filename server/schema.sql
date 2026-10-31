-- PC server database schema (node:sqlite). Applied on startup when PRAGMA user_version is 0.
-- Bump user_version and add a migration file for any later change.

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- UI accounts. Passwords are scrypt hashes, never plain text.
CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL,
    created_at    INTEGER NOT NULL
);

-- Browser sessions. Only a hash of the token is stored.
CREATE TABLE sessions (
    token_hash TEXT    PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    source_ip  TEXT
);
CREATE INDEX sessions_expires ON sessions(expires_at);

-- One row per gateway. Gateway secrets live in the server config, not here.
-- Rows are created or refreshed from config on startup; last_seen is updated on each hello.
CREATE TABLE gateways (
    id         TEXT    PRIMARY KEY,
    name       TEXT    NOT NULL,
    last_seen  INTEGER,
    online     INTEGER NOT NULL DEFAULT 0
);

-- Turtles are keyed by (gateway, turtle computer id). Computer ids are only unique within a world.
CREATE TABLE turtles (
    gateway_id TEXT    NOT NULL REFERENCES gateways(id) ON DELETE CASCADE,
    turtle_id  INTEGER NOT NULL,
    label      TEXT,
    fuel       INTEGER,
    x          INTEGER,
    y          INTEGER,
    z          INTEGER,
    current_job_id TEXT REFERENCES jobs(id) ON DELETE SET NULL,
    last_seen  INTEGER,
    PRIMARY KEY (gateway_id, turtle_id)
);

-- Jobs. A job is queued with no target; the server assigns it to an idle turtle, which sets
-- target_gateway_id and target_turtle_id. The pair can also be fixed at submit time.
CREATE TABLE jobs (
    id                TEXT    PRIMARY KEY,
    type              TEXT    NOT NULL,
    args_json         TEXT    NOT NULL,
    state             TEXT    NOT NULL,
    progress          REAL    NOT NULL DEFAULT 0,
    submitted_by      INTEGER REFERENCES users(id) ON DELETE SET NULL,
    target_gateway_id TEXT,
    target_turtle_id  INTEGER,
    attempts          INTEGER NOT NULL DEFAULT 0,
    timeout_sec       INTEGER NOT NULL,
    created_at        INTEGER NOT NULL,
    assigned_at       INTEGER,
    started_at        INTEGER,
    finished_at       INTEGER,
    result_json       TEXT,
    error             TEXT,
    FOREIGN KEY (target_gateway_id, target_turtle_id)
        REFERENCES turtles(gateway_id, turtle_id) ON DELETE SET NULL
);
CREATE INDEX jobs_state ON jobs(state);
CREATE INDEX jobs_target ON jobs(target_gateway_id, target_turtle_id);

-- Every envelope or rednet message seen, for dedupe and audit. A gateway resends unacked
-- reports after reconnect, so (gateway_id, msg_id) must be unique.
CREATE TABLE messages (
    id          INTEGER PRIMARY KEY,
    gateway_id  TEXT,
    msg_id      TEXT,
    direction   TEXT    NOT NULL CHECK (direction IN ('in', 'out')),
    type        TEXT    NOT NULL,
    payload_json TEXT   NOT NULL,
    acked       INTEGER NOT NULL DEFAULT 0,
    created_at  INTEGER NOT NULL,
    UNIQUE (gateway_id, msg_id)
);
CREATE INDEX messages_unacked ON messages(gateway_id, acked) WHERE acked = 0;

-- Audit log: logins, failed auth, gateway connects, job submissions and changes.
CREATE TABLE events (
    id          INTEGER PRIMARY KEY,
    ts          INTEGER NOT NULL,
    kind        TEXT    NOT NULL,
    source_ip   TEXT,
    user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
    gateway_id  TEXT,
    detail_json TEXT
);
CREATE INDEX events_ts ON events(ts);

PRAGMA user_version = 1;
