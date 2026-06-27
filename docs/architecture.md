# Architecture

## Goal

A local-first, OpenAI-compatible inference gateway for Apple Silicon (MLX), designed
around one principle: **a model's ability to produce text is not authority to act.**
Model access is mediated through a controlled gateway and a loopback boundary rather
than wired directly into tool execution.

## Request path

```text
OpenAI-compatible client (SDK or agent CLI)
  -> http://127.0.0.1:8081/v1        nginx loopback boundary   deploy/nginx/nginx.conf
  -> http://127.0.0.1:8080/v1        Flask gateway             src/private_ai_gateway/app.py
  -> MLX / mlx_lm                     local inference           Apple Silicon
  -> local model                     mlx-community/*
```

## Planes

The system separates *deciding what to do* from *doing it* — the boundary that keeps a
local model from silently gaining execution authority.

```text
Control plane
  - any OpenAI-compatible client (agent CLI, SDK, curl)
  - planning, review, drafting — text only
  - no trusted tool execution through the gateway

Gateway layer  (src/private_ai_gateway/app.py + deploy/nginx)
  - nginx loopback boundary (127.0.0.1 only)
  - Flask OpenAI-compatible API
  - bearer auth
  - alias-based model routing
  - output sanitization (thinking / tool / control markers)
  - per-request max-token clamp
  - audit logging

Operator wrappers  (agents/wrappers/, owner-run only)
  - opencode.sh: read-only engineering inspection + syntax tests, project-root jailed
  - openclaw.sh: monitoring-only status / log summarization, no process control
  - these are deliberately least-privilege; see agents/README.md

Model layer
  - MLX / mlx_lm
  - local model cache
  - stable aliases (clients never hardcode model names)
```

## Model routing

Clients request a stable **alias**; the gateway resolves it to a concrete model and
lazily swaps models on demand (clearing the MLX cache between loads).

| Alias | Model | Purpose |
|---|---|---|
| `strategy` | `mlx-community/Qwen3.6-27B-OptiQ-4bit` | planning, architecture, review |
| `engineering` | `mlx-community/Qwen3-Coder-30B-A3B-Instruct-8bit` | code / script-heavy work |
| `offsec` | `mlx-community/Llama-3-70B-Instruct-Gradient-1048k-4bit` | long-context security analysis |

The alias table is the single source of truth in `ROUTE_MAP`
([app.py](../src/private_ai_gateway/app.py)).

## Gateway controls

- Qwen thinking disabled via `enable_thinking=False`.
- Multiple system messages merged before chat-template rendering (Qwen constraint).
- Visible `<think>` wrappers stripped from output.
- Tool / channel / control markers stripped from output.
- Attempted tool-call output **blocked** and replaced with a text-only fallback — the
  gateway refuses to fake tool execution rather than passing it through.
- Per-request output tokens clamped to a per-model cap.
- All requests audit-logged.

See [security-model.md](security-model.md) for the trust boundaries and known limits.

## Direction

Near-term hardening and roadmap items are tracked in [roadmap.md](roadmap.md):
fail-closed auth, request-size limits, structured JSONL audit logs, TLS, and broader
test coverage on the security-critical paths.
