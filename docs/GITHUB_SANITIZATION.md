# GitHub Sanitization Checklist

## Purpose

This checklist prepares the Private AI Infrastructure Lab for safe portfolio publication.

This phase does not commit, push, or publish anything.

## Publication Rule

Do not publish until the local publication readiness scan passes and the owner manually reviews the repository.

## Must Not Publish

- secrets
- bearer tokens
- API keys
- private logs with sensitive prompts
- model cache directories
- virtual environments
- local process files
- personal machine paths if unnecessary
- private Hermes configuration
- desktop state files
- raw audit logs unless sanitized
- raw benchmark logs if they contain private prompts

## Files That Are Reasonable to Publish After Review

- README.md
- ARCHITECTURE.md
- SECURITY_MODEL.md
- RUNBOOK.md
- FUTURE.md
- INTERVIEW_TALK_TRACK.md
- docs/VALIDATION_SUMMARY.md
- docs/GITHUB_SANITIZATION.md
- scripts/*.sh after review
- agents/*.sh after review
- memory/*.md after review and redaction

## Files That Need Special Review

- gateway/app.py
- config/nginx.conf
- memory/PROJECT_STATE.json
- memory/RUN_HISTORY.md
- memory/DECISION_LOG.md
- memory/NEXT_ACTIONS.md
- logs/benchmark.csv

## Recommended .gitignore Categories

- venv/
- model_cache/
- logs/
- backups/
- tmp/
- .env
- *.pem
- *.key
- *.crt
- .DS_Store

## Manual Review Questions

- Does any file expose a real token or secret?
- Does any file expose private prompts or private work context?
- Does any file expose machine-specific paths that should be generalized?
- Does any file imply real tool autonomy that does not exist yet?
- Does any file claim compliance instead of framework alignment?
- Does any file include offensive-security content that should remain private?

## Publication Decision

Publication is blocked until:

- validation harness passes
- publication readiness scan passes
- .gitignore is reviewed
- sensitive files are excluded
- owner explicitly approves Git operations
