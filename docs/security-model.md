# Security Model

## Security Posture

This project uses governed local execution rather than uncontrolled autonomy.

Current rule:

The model may plan.
The owner executes deterministic commands.
The gateway must not pretend tool execution exists.

## Trust Boundaries

| Boundary | Current Control |
|---|---|
| Network | loopback only, 127.0.0.1 |
| API | bearer token required |
| Model output | sanitizer strips thinking, tool, and control markers |
| Tools | not executed through gateway |
| Filesystem | owner-run deterministic scripts only |
| Agents | wrappers only, no active Hermes integration |
| GitHub | publication blocked until sanitization |

## Approval Required

Explicit approval is required before:

- editing gateway/app.py
- editing config/nginx.conf
- editing ~/.hermes/config.yaml
- enabling TLS
- using sudo
- installing packages
- deleting files
- killing processes
- creating launchd services
- enabling MCP servers
- integrating active autonomous tools
- committing or pushing to Git
- publishing to GitHub

## AI Security Risks Addressed

This lab is aligned to common AI and agentic risk themes:

- prompt injection
- insecure output handling
- excessive agency
- tool misuse
- fake tool execution
- system prompt leakage
- memory poisoning
- unbounded action loops
- sensitive information disclosure
- model denial-of-service through huge output requests

## Current Mitigations

- max-token clamp to 4096
- local-only endpoint
- bearer authentication
- output sanitizer
- no real tool execution through the gateway
- owner-run scripts
- persistent decision log
- known-issues tracking
- wrapper path restrictions
- finite health loops only
- GitHub publication block until sanitization

## Gateway-Specific Controls

- Qwen thinking disabled through enable_thinking=False.
- Qwen system messages merged before template rendering.
- think wrappers stripped from model output.
- tool/channel/control markers stripped from model output.
- plain tool-call markers blocked with safe text fallback.
- unsupported OpenAI/Hermes extras accepted but not executed.

## Framework Alignment

This project is conceptually aligned to:

- NIST AI RMF and Generative AI Profile concepts
- OWASP LLM and Agentic AI risk themes
- MITRE ATLAS-style AI threat modeling
- OpenTelemetry-style GenAI observability
- OpenSSF Scorecard-style repository health
- SLSA-style provenance roadmap
- CISA Secure by Design principles

This is not a claim of formal compliance. It is framework-aligned lab design.
