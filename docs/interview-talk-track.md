# Interview Talk Track

## 30-Second Pitch

I built a local AI security infrastructure lab on Apple Silicon that routes Hermes CLI through a local OpenAI-compatible gateway into MLX models. The project demonstrates model routing, local inference, gateway hardening, output sanitization, safe agent wrappers, persistent operational memory, observability scripts, and DevSecOps-oriented security workflows.

## 60-Second Pitch

This project started as a local LLM setup but evolved into a governed AI security infrastructure lab. Hermes acts as the strategy plane, the Flask and Nginx gateway serves local MLX models through an OpenAI-compatible endpoint, and safe wrappers define future boundaries for OpenCode and OpenClaw. I hardened the gateway against visible reasoning, fake tool calls, oversized token requests, and Qwen chat-template issues. The result is a portfolio project that shows how I think about AI infrastructure, security boundaries, observability, and DevSecOps workflows.

## 3-Minute Story

The main engineering lesson was that local AI infrastructure is not just about getting a model to respond. The hard part is making it reliable and safe enough to support repeatable workflows.

I started with Hermes connected to a local endpoint. Large model requests and huge max_tokens values caused reliability issues, so I added output caps. Then I moved the strategy route to Qwen3.6 because it fit the planning and coding-adjacent strategy workload better. That exposed new issues: visible thinking tags, Qwen system-message template constraints, and fake tool-call output. I patched the gateway to enforce enable_thinking=False, merge system messages, strip think wrappers, and block plain tool-call output.

After that, I added persistent memory files, safe wrappers, and utility scripts for logs and benchmarking. The project now shows a controlled path toward governed agentic DevSecOps without pretending that full autonomy is already safe.

## Failure Story

A large autonomous prompt failed because the model emitted fake tool-call syntax and command-heavy prompts risked shell corruption. Instead of forcing autonomy, I redesigned the workflow around deterministic owner-run scripts, gateway guardrails, explicit approval gates, and persistent project memory.

## Security Control Story

The gateway is loopback-only, bearer-authenticated, output-sanitized, and max-token-clamped. Tool execution is not trusted. Any risky change requires explicit approval. Wrappers restrict future execution to the project root and log invocations.

## Why This Matters for Security Roles

This project connects AI infrastructure with practical security engineering. It demonstrates threat modeling, secure-by-default boundaries, operational logging, approval gates, local-first data handling, and a realistic path toward AppSec and DevSecOps automation.

## Best Positioning

Use this phrase:

A local AI security infrastructure lab for governed agentic DevSecOps workflows.

## Interview Angle by Role

- Security Analyst: focus on logging, guardrails, model output control, and operational validation.
- AppSec Engineer: focus on secure coding workflows, secret remediation, CodeQL triage, and safe patch review.
- DevSecOps Engineer: focus on gateway controls, CI/CD future roadmap, validation scripts, and supply-chain roadmap.
- AI Security Engineer: focus on prompt injection, tool misuse, output sanitization, memory governance, and model routing.
