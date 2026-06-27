#!/usr/bin/env bash
set -euo pipefail

# Resolve project root from this script's own location (portable; no hardcoded paths).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

GATEWAY="src/private_ai_gateway/app.py"
NGINX_CONF="deploy/nginx/nginx.conf"
AUTH="${PRIVATE_AI_AUTH_TOKEN:-private-portfolio-token}"

mkdir -p logs

echo "Stopping old services if present..."
nginx -p "$PROJECT_ROOT/" -c "$NGINX_CONF" -s quit 2>/dev/null || true

if [ -f logs/flask.pid ]; then
  old_pid="$(cat logs/flask.pid || true)"
  if [ -n "${old_pid:-}" ] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
    sleep 2
  fi
fi

pkill -f "$PROJECT_ROOT/$GATEWAY" 2>/dev/null || true

echo "Starting Flask gateway on 127.0.0.1:8080..."
nohup python "$PROJECT_ROOT/$GATEWAY" \
  > "$PROJECT_ROOT/logs/flask.stdout.log" \
  2> "$PROJECT_ROOT/logs/flask.stderr.log" &

echo $! > "$PROJECT_ROOT/logs/flask.pid"

sleep 3

echo "Checking Flask..."
curl -sS http://127.0.0.1:8080/health | python3 -m json.tool

echo "Starting Nginx on 127.0.0.1:8081..."
nginx -p "$PROJECT_ROOT/" -c "$NGINX_CONF" -t
nginx -p "$PROJECT_ROOT/" -c "$NGINX_CONF"

sleep 1

echo "Checking listeners..."
lsof -nP -iTCP:8080 -sTCP:LISTEN || true
lsof -nP -iTCP:8081 -sTCP:LISTEN || true

echo "Testing Nginx -> Flask model discovery..."
curl -sS http://127.0.0.1:8081/v1/models \
  -H "Authorization: Bearer ${AUTH}" | python3 -m json.tool

echo "Stack started."
echo "Logs:"
echo "  tail -f $PROJECT_ROOT/logs/audit.log"
echo "  tail -f $PROJECT_ROOT/logs/nginx.access.log $PROJECT_ROOT/logs/nginx.error.log"
