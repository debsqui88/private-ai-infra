# Private AI Gateway

A local-first, **OpenAI-compatible LLM inference gateway** for Apple Silicon (MLX). It serves
local models behind a hardened Flask gateway and an nginx loopback proxy — with bearer auth,
audit logging, output sanitization, and alias-based model routing.

Built as a *governed* AI-infrastructure lab: the thesis is that **AI capability should not
automatically become AI authority**. The value isn't that a model can run locally — it's the
control boundaries around it (loopback-only binding, auth, sanitization, token clamping, audit
trail, and explicit agent wrappers).

## Architecture

```text
client (OpenAI SDK / agent CLI)
  └─▶ nginx loopback proxy          127.0.0.1:8081   deploy/nginx/nginx.conf
        └─▶ Flask OpenAI gateway    127.0.0.1:8080   src/private_ai_gateway/app.py
              └─▶ MLX inference                       Apple Silicon
                    └─▶ local model                   mlx-community/*
```

Requests route by a stable **alias** so clients never hardcode model names:

| alias | model |
|-------|-------|
| `strategy` | `mlx-community/Qwen3.6-27B-OptiQ-4bit` |
| `engineering` | `mlx-community/Qwen3-Coder-30B-A3B-Instruct-8bit` |
| `offsec` | `mlx-community/Llama-3-70B-Instruct-Gradient-1048k-4bit` |

The gateway lazily swaps models on demand (clearing the MLX cache between loads), strips visible
thinking/tool-call/control markers from output, refuses to fake tool execution, and clamps
output tokens per model.

## Quickstart

```bash
python -m venv venv && source venv/bin/activate
make install                       # runtime deps (Apple Silicon / MLX)
cp .env.example .env               # set PRIVATE_AI_AUTH_TOKEN
make start                         # launch Flask + nginx
make status

curl -s http://127.0.0.1:8081/v1/models \
  -H "Authorization: Bearer $PRIVATE_AI_AUTH_TOKEN" | python3 -m json.tool

make stop
```

## Project layout

```text
src/private_ai_gateway/   # the Flask OpenAI-compatible gateway (app.py)
deploy/nginx/             # nginx loopback reverse-proxy config
scripts/                  # operational entrypoints (start/stop/status/benchmark)
agents/                   # owner-run operator wrappers (least-privilege, monitoring/inspection)
tests/                    # unit/ (pytest) + integration/ (stack smoke test)
docs/                     # architecture, security model, runbook, roadmap
```

## Security

Loopback-only, bearer-authenticated, output-sanitized, max-token-clamped, audit-logged. Tool
execution is intentionally **not** trusted. See [SECURITY.md](SECURITY.md) and
[docs/security-model.md](docs/security-model.md).

## Development

```bash
make install-dev
make lint        # ruff
make test        # pytest (MLX-dependent tests auto-skip off Apple Silicon)
```

## Status & limitations

- Gateway is text-compatible, not real tool-execution-compatible (by design).
- TLS is planned, not active; the gateway is intended for loopback use.
- MLX is Apple-Silicon only.

See [docs/roadmap.md](docs/roadmap.md) for direction.

## License

[MIT](LICENSE)
