#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
AUDIT_LOG="${1:-$PROJECT_ROOT/logs/audit.log}"

echo "===== LOCAL AI LOG SUMMARY ====="
date
echo "AUDIT_LOG=$AUDIT_LOG"

if [ ! -f "$AUDIT_LOG" ]; then
  echo "ERROR: audit log not found"
  exit 1
fi

echo
echo "===== EVENT COUNTS ====="
for key in \
  AUTH_SUCCESS \
  AUTH_FAILURE \
  MODEL_SWAP_START \
  MODEL_LOAD_START \
  MODEL_LOAD_SUCCESS \
  MODEL_LOAD_FAILED \
  MODEL_REUSE \
  INFERENCE_START \
  INFERENCE_COMPLETE \
  INFERENCE_FAILED \
  MAX_TOKENS_CLAMPED \
  REQUEST_BODY_KEYS \
  SANITIZER_BLOCKED_TOOL_CALL
do
  count="$(grep -c "$key" "$AUDIT_LOG" 2>/dev/null || true)"
  printf '%-34s %s\n' "$key" "$count"
done

echo
echo "===== LAST ACTIVE MODEL EVENTS ====="
grep -E "MODEL_LOAD_SUCCESS|MODEL_REUSE|INFERENCE_START" "$AUDIT_LOG" 2>/dev/null | tail -n 10 || true

echo
echo "===== LAST FIVE ERRORS OR FAILURES ====="
grep -Ei "ERROR|FAILED|Traceback|Exception|TemplateError|AUTH_FAILURE" "$AUDIT_LOG" 2>/dev/null | tail -n 5 || true

echo
echo "===== LAST FIVE REQUEST SHAPES ====="
grep "REQUEST_BODY_KEYS" "$AUDIT_LOG" 2>/dev/null | tail -n 5 || true

echo
echo "===== MAX TOKEN CLAMPS ====="
grep "MAX_TOKENS_CLAMPED" "$AUDIT_LOG" 2>/dev/null | tail -n 10 || true

echo
echo "===== SANITIZER EVENTS ====="
grep "SANITIZER_BLOCKED_TOOL_CALL" "$AUDIT_LOG" 2>/dev/null | tail -n 10 || true
