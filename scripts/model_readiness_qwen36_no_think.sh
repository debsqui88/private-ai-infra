#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
MODEL_ID="mlx-community/Qwen3.6-27B-OptiQ-4bit"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/logs/model_readiness_qwen36_no_think-$RUN_TS.log"

mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/model_cache/hf_home" "$PROJECT_ROOT/model_cache/hub"

export HF_HOME="$PROJECT_ROOT/model_cache/hf_home"
export HF_HUB_CACHE="$PROJECT_ROOT/model_cache/hub"
export HF_XET_HIGH_PERFORMANCE=1
export TOKENIZERS_PARALLELISM=false

cd "$PROJECT_ROOT"

{
  echo "===== QWEN3.6 NO-THINK VALIDATION ====="
  date
  echo "PROJECT_ROOT=$PROJECT_ROOT"
  echo "MODEL_ID=$MODEL_ID"
  echo "HF_HOME=$HF_HOME"
  echo "HF_HUB_CACHE=$HF_HUB_CACHE"
  echo

  if [ -d "$PROJECT_ROOT/venv" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/venv/bin/activate"
    echo "VENV=active"
  else
    echo "ERROR: venv not found at $PROJECT_ROOT/venv"
    exit 2
  fi

  python3 - <<'PY'
from mlx_lm import load, generate

MODEL_ID = "mlx-community/Qwen3.6-27B-OptiQ-4bit"

bad_markers = [
    "<|tool_call",
    "<tool_call",
    "<|channel",
    "<channel|>",
    "<think",
    "</think",
    "thinking process",
    "analyze user input",
    "let's think",
    "we need answer",
    "reasoning:",
    "analysis:",
    "step 1:",
]

tests = []

print(f"LOAD_START={MODEL_ID}")
model, tokenizer = load(MODEL_ID)
print(f"LOAD_SUCCESS={MODEL_ID}")
print()

messages_base = [
    {
        "role": "system",
        "content": (
            "You are in no-thinking validation mode. "
            "Return only final user-visible text. "
            "Do not reveal reasoning, analysis, planning, hidden thoughts, control tokens, or tool calls."
        ),
    },
    {
        "role": "user",
        "content": "Return exactly one word: READY",
    },
]

def try_prompt_variant(name, builder):
    print(f"===== TEST_VARIANT={name} =====")
    try:
        prompt = builder()
        print("PROMPT_BUILD=OK")
    except Exception as e:
        print("PROMPT_BUILD=FAIL")
        print(f"ERROR={repr(e)}")
        return {
            "name": name,
            "status": "PROMPT_BUILD_FAIL",
            "response": "",
            "bad_found": [],
        }

    try:
        response = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=12,
            verbose=False,
        )
        response = str(response).strip()
        print(f"RAW_RESPONSE={response!r}")
    except Exception as e:
        print("GENERATION=FAIL")
        print(f"ERROR={repr(e)}")
        return {
            "name": name,
            "status": "GENERATION_FAIL",
            "response": "",
            "bad_found": [],
        }

    lower = response.lower()
    bad_found = [m for m in bad_markers if m.lower() in lower]

    if bad_found:
        print("VARIANT_STATUS=FAIL")
        print("BAD_MARKERS_FOUND=" + ",".join(bad_found))
        status = "FAIL"
    elif response.upper().strip(" .!`'\"") == "READY":
        print("VARIANT_STATUS=PASS")
        status = "PASS"
    elif "READY" in response.upper() and len(response.split()) <= 5:
        print("VARIANT_STATUS=PASS_SOFT")
        status = "PASS_SOFT"
    else:
        print("VARIANT_STATUS=WARN")
        print("REASON=no bad markers, but response was not exactly READY")
        status = "WARN"

    print()
    return {
        "name": name,
        "status": status,
        "response": response,
        "bad_found": bad_found,
    }

tests.append(try_prompt_variant(
    "apply_chat_template_enable_thinking_false",
    lambda: tokenizer.apply_chat_template(
        messages_base,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False,
    )
))

tests.append(try_prompt_variant(
    "apply_chat_template_enable_and_preserve_false",
    lambda: tokenizer.apply_chat_template(
        messages_base,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False,
        preserve_thinking=False,
    )
))

messages_no_think = [
    {
        "role": "system",
        "content": (
            "/no_think\n"
            "You are in no-thinking validation mode. "
            "Return only final user-visible text. "
            "No reasoning. No analysis. No tool calls."
        ),
    },
    {
        "role": "user",
        "content": "/no_think\nReturn exactly one word: READY",
    },
]

tests.append(try_prompt_variant(
    "slash_no_think_prompt",
    lambda: tokenizer.apply_chat_template(
        messages_no_think,
        tokenize=False,
        add_generation_prompt=True,
    )
))

tests.append(try_prompt_variant(
    "raw_minimal_prompt",
    lambda: (
        "/no_think\n"
        "System: Return only final answer text. No reasoning. No analysis. No tool calls.\n"
        "User: Return exactly one word: READY\n"
        "Assistant:"
    )
))

print("===== NO-THINK MODEL VALIDATION SUMMARY =====")

passing = [t for t in tests if t["status"] in ("PASS", "PASS_SOFT")]
warnings = [t for t in tests if t["status"] == "WARN"]
failures = [t for t in tests if t["status"] == "FAIL"]

for t in tests:
    print(f"{t['name']}={t['status']}")

if passing:
    print(f"BEST_VARIANT={passing[0]['name']}")
    print("MODEL_NO_THINK_VALIDATION=PASS")
    print("MODEL_READY_FOR_GATEWAY_PATCH=YES")
elif warnings and not failures:
    print(f"BEST_VARIANT={warnings[0]['name']}")
    print("MODEL_NO_THINK_VALIDATION=WARN")
    print("MODEL_READY_FOR_GATEWAY_PATCH=REVIEW_REQUIRED")
else:
    print("MODEL_NO_THINK_VALIDATION=FAIL")
    print("MODEL_READY_FOR_GATEWAY_PATCH=NO")
    raise SystemExit(4)
PY

  echo
  echo "===== FINAL ====="
  echo "LOG_FILE=$LOG_FILE"
  echo "Paste output from '===== NO-THINK MODEL VALIDATION SUMMARY =====' through '===== FINAL =====' back to ChatGPT."

} 2>&1 | tee "$LOG_FILE"
