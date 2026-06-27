# Agent Wrappers

Last updated: 2026-06-21 20:21:24 EDT

This directory contains safe local wrappers for future OpenCode and OpenClaw use.

## Roles

- `opencode.sh`: engineering wrapper for inspection, safe tests, and patch suggestions.
- `openclaw.sh`: operations wrapper for local status, logs, finite health checks, and summaries.

## Safety Model

These wrappers are intentionally conservative.

- No autonomous project modification by default.
- No paths outside `~/private-ai-infra`.
- No service restarts.
- No process killing.
- No package installation.
- No infinite loops.
- All invocations log to `logs/agents.log`.

## Current Integration Status

OpenCode and OpenClaw are not integrated as active Hermes tools.

Hermes remains the text-only strategy/control plane.

The owner runs deterministic shell commands.
