#!/usr/bin/env python3
"""File share server for ComputerCraft computers.

Serves a directory (default: ../Programs) over HTTP so CC computers can
list, download and upload files with the built-in `http` API.

    GET  /list            -> newline separated relative file paths
    GET  /files/<path>    -> raw file contents
    POST /files/<path>    -> create/overwrite file with the request body
    DELETE /files/<path>  -> delete file (only with --allow-delete)

If --token is set, every request must send the header `X-Token: <token>`.

Note: the CC mod blocks local/LAN addresses by default. Remove or edit the
`$private` rule in the `http.rules` section of computercraft-server.toml
(or the singleplayer world config) to allow connecting to this machine.
"""

import argparse
import hmac
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

MAX_UPLOAD = 16 * 1024 * 1024


class ShareHandler(BaseHTTPRequestHandler):
    root: Path
    token: str | None
    allow_write: bool
    allow_delete: bool

    server_version = "CCFileShare/1.0"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    # -- helpers ---------------------------------------------------------

    def _reply(self, code: int, body: bytes = b"", ctype: str = "text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _authorised(self) -> bool:
        if not self.token:
            return True
        given = self.headers.get("X-Token", "")
        if hmac.compare_digest(given, self.token):
            return True
        self._reply(401, b"Invalid or missing X-Token\n")
        return False

    def _resolve(self, rel: str) -> Path | None:
        """Map a URL path to a file inside root, refusing traversal."""
        rel = unquote(rel).lstrip("/")
        if not rel:
            return None
        target = (self.root / rel).resolve()
        if target != self.root and self.root not in target.parents:
            return None
        return target

    def _file_target(self) -> Path | None:
        path = urlparse(self.path).path
        if not path.startswith("/files/"):
            self._reply(404, b"Not found\n")
            return None
        target = self._resolve(path[len("/files/"):])
        if target is None:
            self._reply(400, b"Bad path\n")
        return target

    # -- verbs -----------------------------------------------------------

    def do_GET(self):
        if not self._authorised():
            return
        path = urlparse(self.path).path

        if path in ("/", "/list"):
            files = sorted(
                p.relative_to(self.root).as_posix()
                for p in self.root.rglob("*")
                if p.is_file() and not any(part.startswith(".") for part in p.relative_to(self.root).parts)
            )
            self._reply(200, ("\n".join(files) + "\n").encode())
            return

        target = self._file_target()
        if target is None:
            return
        if not target.is_file():
            self._reply(404, b"No such file\n")
            return
        self._reply(200, target.read_bytes(), "application/octet-stream")

    do_HEAD = do_GET

    def do_POST(self):
        if not self._authorised():
            return
        if not self.allow_write:
            self._reply(403, b"Uploads disabled\n")
            return
        target = self._file_target()
        if target is None:
            return
        if target.is_dir():
            self._reply(400, b"Path is a directory\n")
            return

        try:
            length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self._reply(411, b"Content-Length required\n")
            return
        if length > MAX_UPLOAD:
            self._reply(413, b"Too large\n")
            return

        data = self.rfile.read(length)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        self._reply(200, f"Saved {target.relative_to(self.root).as_posix()} ({len(data)} bytes)\n".encode())

    do_PUT = do_POST

    def do_DELETE(self):
        if not self._authorised():
            return
        if not self.allow_delete:
            self._reply(403, b"Deletes disabled\n")
            return
        target = self._file_target()
        if target is None:
            return
        if not target.is_file():
            self._reply(404, b"No such file\n")
            return
        target.unlink()
        self._reply(200, b"Deleted\n")


def main():
    default_root = Path(__file__).resolve().parent.parent / "Programs"
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=default_root, help="directory to share (default: %(default)s)")
    ap.add_argument("--host", default="0.0.0.0", help="bind address (default: %(default)s)")
    ap.add_argument("--port", type=int, default=8080, help="port (default: %(default)s)")
    ap.add_argument("--token", default=os.environ.get("CC_SHARE_TOKEN"),
                    help="shared secret clients must send as X-Token (or set CC_SHARE_TOKEN)")
    ap.add_argument("--read-only", action="store_true", help="disable uploads")
    ap.add_argument("--allow-delete", action="store_true", help="enable DELETE")
    args = ap.parse_args()

    root = args.root.resolve()
    root.mkdir(parents=True, exist_ok=True)

    ShareHandler.root = root
    ShareHandler.token = args.token
    ShareHandler.allow_write = not args.read_only
    ShareHandler.allow_delete = args.allow_delete

    server = ThreadingHTTPServer((args.host, args.port), ShareHandler)
    print(f"Sharing {root} on http://{args.host}:{args.port}  "
          f"(token: {'yes' if args.token else 'NO'}, uploads: {'off' if args.read_only else 'on'})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped")


if __name__ == "__main__":
    main()
