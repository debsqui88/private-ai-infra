# Roadmap

The value of this project is not that a model can run locally — it is the control
boundary around it. The roadmap reflects that: harden the boundary first, broaden
capability second.

## Done — boundary hardening

- **Fail-closed auth** — the gateway refuses to start without `PRIVATE_AI_AUTH_TOKEN`,
  compares the bearer token in constant time, and no longer logs the `Authorization`
  header.
- **Request-size limit** — `MAX_CONTENT_LENGTH` bounds the input side.
- **Security-path tests** — auth pass/fail, empty-token-denies-all, and the size limit
  are covered by `tests/unit/test_auth.py`.

## Near-term — remaining hardening

- **Rate limiting** — a per-client request-rate cap (only body size and output tokens
  are bounded today).
- **More security-path coverage** — alias routing and the tool-call-block fallback.

## Medium-term — observability and packaging

- Structured JSONL audit logs (machine-parseable, OpenTelemetry-style GenAI fields).
- True token-by-token streaming (the current SSE path emits a single chunk).
- Container packaging and a documented deploy path.

## Longer-term — capability, behind the same boundary

- Local RAG over project documentation.
- A model-output safety eval harness (regression tests for the sanitizer against
  adversarial outputs).
- An optional, explicitly-gated tool registry — only if it can be added without
  weakening the "model output is not authority" guarantee.

## Non-goals

- Multi-tenant SaaS operation.
- Public/internet exposure (this is loopback-first by design).
- Autonomous agent loops driving execution without an operator in the loop.
