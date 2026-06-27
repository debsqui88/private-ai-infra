#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
MODEL_ID="mlx-community/Qwen3.6-27B-OptiQ-4bit"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/logs/model_readiness_qwen36_strategy-$RUN_TS.log"

mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/model_cache/hf_home" "$PROJECT_ROOT/model_cache/hub" "$PROJECT_ROOT/tmp"

export HF_HOME="$PROJECT_ROOT/model_cache/hf_home"
export HF_HUB_CACHE="$PROJECT_ROOT/model_cache/hub"
export HF_XET_HIGH_PERFORMANCE=1
export TOKENIZERS_PARALLELISM=false

cd "$PROJECT_ROOT"

{
  echo "===== QWEN3.6 STRATEGY MODEL READINESS ====="
  date
  echo "PROJECT_ROOT=$PROJECT_ROOT"
  echo "MODEL_ID=$MODEL_ID"
  echo "HF_HOME=$HF_HOME"
  echo "HF_HUB_CACHE=$HF_HUB_CACHE"
  echo

  echo "===== PYTHON ENV ====="
  if [ -d "$PROJECT_ROOT/venv" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/venv/bin/activate"
    echo "VENV=active"
  else
    echo "ERROR: venv not found at $PROJECT_ROOT/venv"
    echo "PASTE_THIS_BACK_TO_CHATGPT"
    exit 2
  fi

  python3 - <<'PY'
import sys
print("python=", sys.executable)
try:
    import mlx
    import mlx_lm
    print("mlx_import=OK")
    print("mlx_lm_import=OK")
except Exception as e:
    print("mlx_import=FAIL")
    print(repr(e))
    raise SystemExit(3)
PY

  echo
  echo "===== MODEL LOAD + GENERATION TEST ====="
  python3 - <<'PY'
from mlx_lm import load, generate

model_id = "mlx-community/Qwen3.6-27B-OptiQ-4bit"

print(f"LOAD_START={model_id}")
model, tokenizer = load(model_id)
print(f"LOAD_SUCCESS={model_id}")

messages = [
    {
        "role": "system",
        "content": (
            "You are in text-only validation mode. "
            "Do not emit tool calls, XML tags, hidden thoughts, or control tokens."
        ),
    },
    {
        "role": "user",
        "content": "Say READY only.",
    },
]

try:
    prompt = tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
    )
except Exception:
    prompt = "system: You are in text-only validation mode.\nuser: Say READY only.\nassistant:"

response = generate(
    model,
    tokenizer,
    prompt=prompt,
    max_tokens=16,
    verbose=False,
)

response = str(response).strip()
print(f"RAW_RESPONSE={response!r}")

bad_markers = [
    "<|tool_call",
    "<tool_call",
    "<|channel",
    "<channel|>",
    "<|start",
    "<|end",
    "```json",
]

bad_found = [m for m in bad_markers if m.lower() in response.lower()]

if bad_found:
    print("MODEL_VALIDATION_STATUS=FAIL")
    print("BAD_MARKERS_FOUND=" + ",".join(bad_found))
    raise SystemExit(4)

if "READY" not in response.upper():
    print("MODEL_VALIDATION_STATUS=WARN")
    print("REASON=response did not contain READY exactly, but no bad markers were found")
else:
    print("MODEL_VALIDATION_STATUS=PASS")

print("MODEL_READY_FOR_GATEWAY_ROUTE_TEST=YES")
PY

  echo
  echo "===== CACHE CONFIRMATION ====="
  echo "Looking for downloaded model cache under:"
  echo "$HF_HUB_CACHE"
  find "$HF_HUB_CACHE" -maxdepth 3 -type d -name "models--mlx-community--Qwen3.6-27B-OptiQ-4bit" -print || true
  echo
  du -sh "$HF_HUB_CACHE" 2>/dev/null || true

  echo
  echo "===== FINAL ====="
  echo "If MODEL_VALIDATION_STATUS=PASS or WARN and LOAD_SUCCESS is present, paste this final section back to ChatGPT."
  echo "LOG_FILE=$LOG_FILE"

} 2>&1 | tee "$LOG_FILE"
