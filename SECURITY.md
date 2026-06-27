# Security Policy

## Scope

This is a local-first lab. The gateway binds to `127.0.0.1` only and is intended for
loopback use behind an nginx reverse proxy. It is not hardened for public exposure.

## Security model

See [docs/security-model.md](docs/security-model.md) for the full threat model and controls:
loopback-only binding, bearer authentication, model-output sanitization (think-tags,
fake tool-calls, control tokens), per-model max-token clamping, and audit logging.

## Secrets and sensitive material

- The gateway auth token **must** be provided via the `PRIVATE_AI_AUTH_TOKEN` environment
  variable for any non-local use. The value in `.env.example` is a placeholder, not a secret.
- TLS material (`certs/`), model caches (`model_cache/`), the virtualenv (`venv/`), and
  runtime logs (`logs/`) are git-ignored and must never be committed.

## Reporting a vulnerability

Open a private security advisory on GitHub. Please do not file public issues for
security reports.
