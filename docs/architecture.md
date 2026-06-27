# Architecture

## Architecture Goal

The goal is to create a local-first AI security infrastructure lab that can evolve toward governed agentic workflows without pretending full autonomy exists today.

## Current Request Path

```text
Hermes CLI
  -> custom OpenAI-compatible provider
  -> http://127.0.0.1:8081/v1
  -> Nginx loopback gateway
  -> Flask OpenAI-compatible gateway
  -> MLX
  -> local model
```

## Architecture Planes

```text
Human Owner
  |
  v
Hermes CLI
  - text-only strategy/control plane
  - planning, review, architecture, governance
  - no trusted tool execution through current gateway

Safe Wrappers
  - agents/opencode.sh for engineering inspection/tests
  - agents/openclaw.sh for operations/log checks
  - owner-run only

Gateway Layer
  - Nginx loopback boundary
  - Flask OpenAI-compatible API
  - bearer auth
  - model routing
  - output sanitization
  - max-token clamp

Model Layer
  - MLX / mlx_lm
  - local model cache
  - model aliases

Memory Layer
  - memory/PROJECT_STATE.md
  - memory/PROJECT_STATE.json
  - memory/DECISION_LOG.md
  - memory/RUN_HISTORY.md
  - memory/NEXT_ACTIONS.md
```

## Model Routing

| Alias | Model | Purpose |
|---|---|---|
| strategy | mlx-community/Qwen3.6-27B-OptiQ-4bit | architecture, governance, planning |
| engineering | mlx-community/Qwen3-Coder-30B-A3B-Instruct-8bit | code/script-heavy work later |
| lab_validation | local authorized lab-validation model | defensive local lab validation only |
| rollback_strategy | mlx-community/Hermes-3-Llama-3.1-70B-4bit | fallback only |

## Gateway Safety Controls

- Qwen thinking disabled with enable_thinking=False.
- Qwen system messages merged before template rendering.
- think wrappers stripped.
- tool/channel/control markers stripped.
- fake tool-call output blocked with safe fallback.
- max_tokens clamped to 4096.

## North Star Architecture

```text
Human Owner
    |
    v
Hermes strategy/control plane
    |
    v
Deterministic owner-run execution
    |
    +--> OpenCode wrapper for engineering tasks
    |
    +--> OpenClaw wrapper for operational checks
    |
    v
Local AI gateway + MLX model runtime
    |
    v
Persistent project memory + portfolio docs
```

## Future Architecture

Future work may add local dashboarding, structured JSONL audit logs, OpenTelemetry-style GenAI spans, local RAG over project memory, MCP-style tool registry, GitHub Actions hardening, and sanitized demo workflows.
