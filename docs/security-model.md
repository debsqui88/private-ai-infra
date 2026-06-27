# Security Model

## Thesis

A model's ability to produce text is not authority to act. This gateway exists to make
that boundary explicit: local models are reachable only over loopback, behind
authentication, and their output is treated as untrusted — in particular, the gateway
**refuses to fake tool execution**.

This is a defensive lab design, not a compliance claim.

## Scope

In scope: the Flask gateway (`src/private_ai_gateway/app.py`) and its nginx loopback
boundary (`deploy/nginx/nginx.conf`).

Out of scope: the model weights themselves, the host OS, and any client that calls the
gateway. The operator wrappers (`agents/wrappers/`) are owner-run and covered briefly
below.

## Trust boundaries

| Boundary | Control | Status |
|---|---|---|
| Network | bind to `127.0.0.1` only (Flask + nginx) | active |
| Authentication | constant-time bearer check; fail-closed (won't start without a token) | active, see limits |
| Model output | sanitizer strips thinking / tool / control markers | active (defense-in-depth) |
| Tool execution | not performed by the gateway; tool-call output blocked + text fallback | active |
| Input volume | request body capped via `MAX_CONTENT_LENGTH` (default 8 MiB) | active |
| Output volume | per-request `max_tokens` clamped to a per-model cap | active |
| Observability | every request audit-logged (Authorization header never logged) | active |
| Operator wrappers | project-root jail, read-only inspection, monitoring-only ops | active |

## Risks addressed (OWASP LLM / MITRE ATLAS framing)

This gateway targets a focused subset rather than claiming broad coverage:

- **LLM01 Prompt injection / LLM06 Excessive agency** — the gateway never grants the
  model execution authority; tool-call output is blocked, not forwarded. A compromised
  prompt cannot turn into an action through this path.
- **LLM02 Insecure output handling** — model output is sanitized before it reaches the
  client (thinking wrappers, fake tool calls, stray control tokens removed).
- **Model denial-of-service (output)** — per-model output-token caps bound runaway
  generations.
- **Unbounded autonomy** — there is no agent loop in the gateway; the operator runs
  deterministic commands.

ATLAS-style: the design assumes the model may attempt to emit
adversarial/agentic output and contains it at the boundary rather than trusting it.

## Limitations and non-goals (read this)

Honesty about what is *not* yet hardened is part of the design:

- **Authentication is a single static bearer token** (`PRIVATE_AI_AUTH_TOKEN`).
  It is fail-closed (the gateway refuses to start without one) and compared in
  constant time, but there is still no rotation and no per-client tokens. Treat it as a
  loopback gate, not a public multi-client auth system.
- **The output sanitizer is a regex denylist.** It is defense-in-depth for *known*
  marker shapes, not a guarantee against novel or obfuscated markers. Do not rely on it
  as a sole control.
- **No per-client rate limiting yet.** Request body size is bounded
  (`MAX_CONTENT_LENGTH`) and output tokens are clamped, but there is no request-rate cap.
- **No TLS.** The gateway is intended for loopback use only; do not expose it.
- **Single-user by construction** (one global model reference, single-threaded) — this
  is not a multi-tenant service.

These are tracked as hardening work in [roadmap.md](roadmap.md).

## Operator wrappers

`agents/wrappers/opencode.sh` and `openclaw.sh` are owner-run helpers, intentionally
least-privilege: a realpath-based project-root jail, read-only inspection and syntax
tests only, no process control or service restarts, and patch application is a no-op
behind an explicit `--confirm`. They are not wired into the gateway as autonomous tools.
