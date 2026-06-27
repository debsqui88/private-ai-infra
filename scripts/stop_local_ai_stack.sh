#!/usr/bin/env bash
set -euo pipefail

# Resolve project root from this script's own location (portable; no hardcoded paths).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

GATEWAY="src/private_ai_gateway/app.py"
NGINX_CONF="deploy/nginx/nginx.conf"

echo "Stopping Nginx..."
nginx -p "$PROJECT_ROOT/" -c "$NGINX_CONF" -s quit 2>/dev/null || true

echo "Stopping Flask..."
if [ -f logs/flask.pid ]; then
  old_pid="$(cat logs/flask.pid || true)"
  if [ -n "${old_pid:-}" ] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
  fi
fi

pkill -f "$PROJECT_ROOT/$GATEWAY" 2>/dev/null || true

echo "Stopped."
