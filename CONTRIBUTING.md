# Contributing

## Development setup

```bash
python -m venv venv && source venv/bin/activate
make install-dev          # ruff + pytest (+ runtime deps; MLX requires Apple Silicon)
cp .env.example .env      # then edit PRIVATE_AI_AUTH_TOKEN
```

## Workflow

```bash
make lint                 # ruff check
make fmt                  # ruff format
make test                 # pytest (MLX-dependent tests auto-skip off Apple Silicon)
make start / make stop    # run the local stack
```

## Conventions

- Code lives under `src/private_ai_gateway/`; tests mirror it under `tests/`.
- Keep the gateway loopback-only and text-only. Tool execution is intentionally not trusted.
- No secrets, TLS material, model caches, or runtime logs in commits (see `.gitignore`).
- Lint and tests must pass (`make lint && make test`) before opening a PR.
