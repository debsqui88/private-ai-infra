#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
SUMMARY_FILE="$PROJECT_ROOT/docs/VALIDATION_SUMMARY.md"
OVERALL=0

cd "$PROJECT_ROOT" || exit 1
mkdir -p docs logs

start_summary() {
  : > "$SUMMARY_FILE"
  printf "%s\n" "# Validation Summary" >> "$SUMMARY_FILE"
  printf "%s\n" "" >> "$SUMMARY_FILE"
  printf "%s\n" "Generated: $(date)" >> "$SUMMARY_FILE"
  printf "%s\n" "" >> "$SUMMARY_FILE"
}

section() {
  printf "%s\n" "" >> "$SUMMARY_FILE"
  printf "%s\n" "## $1" >> "$SUMMARY_FILE"
  printf "%s\n" "" >> "$SUMMARY_FILE"
  echo
  echo "===== $1 ====="
}

pass() {
  echo "PASS: $1"
  printf "%s\n" "- PASS: $1" >> "$SUMMARY_FILE"
}

fail() {
  echo "FAIL: $1"
  printf "%s\n" "- FAIL: $1" >> "$SUMMARY_FILE"
  OVERALL=1
}

skip() {
  echo "SKIP: $1"
  printf "%s\n" "- SKIP: $1" >> "$SUMMARY_FILE"
}

check_nonempty_file() {
  if [ -s "$1" ]; then pass "$1 exists and is non-empty"; else fail "$1 missing or empty"; fi
}

check_executable() {
  if [ -x "$1" ]; then pass "$1 exists and is executable"; else fail "$1 missing or not executable"; fi
}

start_summary

section "Project Root"
echo "PROJECT_ROOT=$PROJECT_ROOT"
printf "%s\n" "- PROJECT_ROOT=$PROJECT_ROOT" >> "$SUMMARY_FILE"
if [ -d "$PROJECT_ROOT" ]; then pass "project root exists"; else fail "project root missing"; fi

section "Core Portfolio Docs"
for f in README.md ARCHITECTURE.md SECURITY_MODEL.md RUNBOOK.md FUTURE.md INTERVIEW_TALK_TRACK.md; do
  check_nonempty_file "$f"
done

section "Memory Files"
for f in memory/PROJECT_STATE.md memory/PROJECT_STATE.json memory/DECISION_LOG.md memory/RUN_HISTORY.md memory/NEXT_ACTIONS.md memory/KNOWN_ISSUES.md memory/MODEL_ROUTING_POLICY.md; do
  check_nonempty_file "$f"
done
if python3 -m json.tool memory/PROJECT_STATE.json >/dev/null 2>&1; then pass "memory/PROJECT_STATE.json is valid JSON"; else fail "memory/PROJECT_STATE.json is invalid JSON"; fi

section "Scripts"
for f in scripts/start_local_ai_stack.sh scripts/stop_local_ai_stack.sh scripts/test_local_ai_stack.sh scripts/status_local_ai_stack.sh scripts/log_summary.sh scripts/benchmark_local_ai_stack.sh scripts/validate_project_state.sh; do
  check_executable "$f"
  if [ -f "$f" ]; then if bash -n "$f"; then pass "$f bash syntax valid"; else fail "$f bash syntax invalid"; fi; fi
done

section "Agent Wrappers"
for f in agents/opencode.sh agents/openclaw.sh agents/README.md agents/ROUTING_POLICY.md agents/HERMES_STRATEGY_BOOT_PROMPT.md; do
  check_nonempty_file "$f"
done
for f in agents/opencode.sh agents/openclaw.sh; do
  check_executable "$f"
  if bash -n "$f"; then pass "$f bash syntax valid"; else fail "$f bash syntax invalid"; fi
done

section "Gateway Files"
check_nonempty_file gateway/app.py
check_nonempty_file config/nginx.conf
if python3 -m py_compile gateway/app.py >/dev/null 2>&1; then pass "gateway/app.py Python compile check passed"; else fail "gateway/app.py Python compile check failed"; fi

section "Logs and Benchmarks"
check_nonempty_file logs/audit.log
if [ -f logs/benchmark.csv ]; then pass "logs/benchmark.csv exists"; else skip "logs/benchmark.csv not present yet"; fi

section "Optional Online Checks"
if lsof -nP -iTCP:8081 -sTCP:LISTEN >/dev/null 2>&1; then
  if curl -sS http://127.0.0.1:8081/v1/models -H "Authorization: Bearer private-portfolio-token" >/tmp/private_ai_models_check.json 2>/dev/null; then
    pass "model discovery endpoint reachable through 8081"
  else
    fail "model discovery endpoint failed through 8081"
  fi
else
  skip "stack not running on 8081, online checks skipped"
fi

section "Overall Result"
if [ "$OVERALL" -eq 0 ]; then
  pass "project validation passed"
  echo "VALIDATION_STATUS=PASS"
  printf "%s\n" "" >> "$SUMMARY_FILE"
  printf "%s\n" "VALIDATION_STATUS=PASS" >> "$SUMMARY_FILE"
  exit 0
else
  fail "project validation failed"
  echo "VALIDATION_STATUS=FAIL"
  printf "%s\n" "" >> "$SUMMARY_FILE"
  printf "%s\n" "VALIDATION_STATUS=FAIL" >> "$SUMMARY_FILE"
  exit 1
fi
