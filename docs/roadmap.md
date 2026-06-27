# Roadmap

The value of this project is not that a model can run locally — it is the control
boundary around it. The roadmap reflects that: harden the boundary first, broaden
capability second.

## Near-term — harden the boundary

These close the gaps named in [security-model.md](security-model.md):

- **Fail-closed auth** — refuse to start without `PRIVATE_AI_AUTH_TOKEN` set; use a
  constant-time comparison; stop logging the `Authorization` header on auth failure.
- **Request-size limit** — set `MAX_CONTENT_LENGTH` so the input side is bounded, not
  just output tokens.
- **Rate limiting** on the gateway.
- **Test coverage on security paths** — auth pass/fail, alias routing, token clamping,
  and the tool-call-block fallback (today only the sanitizer is covered).

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
