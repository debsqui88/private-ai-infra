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

## Repository protections

Controls on the repository itself (industry-standard for a single-maintainer public repo):

- **Protected default branch (`main`)** via a ruleset — branch **deletion** and **force-push
  (non-fast-forward)** are blocked, every change must arrive through a **pull request**, and
  required status checks (`lint-and-scan`, `test`) must pass before merge.
- **Secret scanning + push protection** block credential-shaped commits before they land.
- **Dependabot** vulnerability alerts and automated security updates are enabled.
- **Least-privilege CI** — the default `GITHUB_TOKEN` is read-only and workflows cannot
  approve pull requests. CI runs `ruff`, `bandit` (SAST), and `pip-audit` on every push/PR;
  CodeQL analyzes the code separately.

The gateway's own trust boundaries plus a **MITRE ATLAS / OWASP technique map** (pertinent vs.
out-of-scope) are in [docs/security-model.md](docs/security-model.md).

## Reporting a vulnerability

Use **GitHub → Security → Report a vulnerability** (private vulnerability reporting). Please
do not file public issues for security reports. This is a portfolio/research repo — there is
no bounty.
