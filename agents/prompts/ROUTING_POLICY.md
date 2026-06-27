# Agent Routing Policy

## Default Routing

| Task | Agent Wrapper | Model Alias |
|---|---|---|
| Architecture / governance | Hermes only | strategy |
| Code/script inspection | opencode.sh inspect | engineering later |
| Safe syntax validation | opencode.sh test | none required |
| Patch suggestion | opencode.sh suggest_patch | engineering later |
| Operations status | openclaw.sh status | none required |
| Log tailing | openclaw.sh tail_audit / tail_nginx | none required |
| Log summarization | openclaw.sh summarize_logs | strategy later |
| OffSec local lab | not enabled yet | offsec only with approval |

## Approval Gates

Do not allow active OpenCode/OpenClaw execution through Hermes until:

1. wrapper tests pass,
2. logs are reviewed,
3. approval gates are documented,
4. rollback is defined,
5. tool schemas are explicit,
6. scope is limited to `~/private-ai-infra`.

## Current Rule

Wrappers are owner-run only.
