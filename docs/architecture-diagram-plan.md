# Architecture Diagram Plan

## 1. Diagram Purpose

This document defines the public-safe architecture diagram plan for the Private AI Infrastructure Lab.

The diagram should explain the project as a governed local AI infrastructure system for security engineering, DevSecOps, AI security, and controlled agentic workflows.

The diagram is not meant to expose private runtime internals, raw logs, secrets, local machine details, interview preparation material, private prompts, or operational memory.

The purpose is to show:

* local-first model execution
* gateway control boundary
* model routing
* executive agent role separation
* audit and memory paths
* validation and control paths
* human approval gates
* future controlled autonomy path
* public/private release boundary

## 2. Target Audience

The diagram should be understandable to:

* security architects
* DevSecOps engineers
* AI infrastructure engineers
* AppSec teams
* platform security teams
* finance technology teams
* hedge fund technology teams
* HFT engineering teams
* big tech AI platform teams
* AI governance and model-risk teams
* recruiters and hiring managers with technical screening responsibility

The diagram should avoid unnecessary implementation noise.

It should show why the project is disciplined, scalable, security-aware, and relevant to high-control environments.

## 3. Public-Safe Boundaries

The public-safe diagram may show:

* Human Owner
* Hermes CEO / governance plane
* OpenCode CTO / future engineering plane
* OpenClaw CIO+CISO / future assurance plane
* local gateway boundary
* Nginx loopback proxy
* Flask OpenAI-compatible gateway
* MLX local inference
* local model routes
* audit log category path
* memory/governance category path
* public release candidate
* future MCP/A2A layer as not yet implemented

The public-safe diagram must not show:

* tokens
* auth headers
* secrets
* local usernames
* machine-specific paths
* raw audit log contents
* raw prompts
* private runtime memory
* interview prep
* private handoff text
* cleanup candidates
* internal file hashes unless intentionally published
* operational commands
* provider config details

No image files created in this phase.

## 4. System Components

Core components:

* Human Owner
* Hermes CLI
* Local OpenAI-compatible provider
* Nginx loopback boundary
* Flask OpenAI-compatible gateway
* MLX inference layer
* Strategy model route
* Engineering model route
* Future lab-validation route
* Memory/governance store
* Audit log store
* Public release candidate
* Future OpenCode execution plane
* Future OpenClaw assurance plane
* Future MCP/A2A interoperability layer

The diagram should show implemented components separately from future / not yet implemented components.

## 5. Trust Boundaries

Trust boundaries:

1. Human approval boundary.
2. Hermes governance boundary.
3. Localhost gateway boundary.
4. Gateway authentication boundary.
5. Model routing boundary.
6. Agent execution boundary.
7. Public/private artifact boundary.
8. Future protocol boundary for MCP/A2A.

The most important architecture message:

Autonomy does not cross trust boundaries without approval.

## 6. Runtime Request Path

Current runtime request path:

Hermes CLI
-> local OpenAI-compatible provider
-> 127.0.0.1:8081/v1
-> Nginx loopback proxy
-> Flask OpenAI-compatible gateway
-> MLX
-> local model

The diagram should show this as a controlled local request path, not a generic chatbot or generic API call.

## 7. Executive Agent Role Separation

Hermes:

* strategy
* governance
* phase gates
* risk classification
* portfolio direction
* approval/rejection of proposed scopes

OpenCode:

* future engineering execution
* code review
* test proposal
* patch proposal
* DevSecOps automation
* not currently approved for execution expansion

OpenClaw:

* future validation and assurance
* audit review
* artifact inventory
* side-effect checks
* security control validation
* not currently approved as autonomous monitor

Human Owner:

* final approval authority
* runs commands
* approves side effects
* controls publication
* controls cleanup/deletion/archive decisions

This separation models how real organizations should treat agentic AI: strategy, execution, assurance, and final approval should not collapse into one uncontrolled agent.

## 8. Audit and Logging Path

The diagram should show audit events flowing from the gateway into an audit evidence layer.

Relevant audit event categories:

* authentication success/failure
* max-token clamp events
* request body key events
* model load events
* model reuse events
* model swap events
* inference start events
* inference completion events

The public diagram should show event categories, not raw log contents.

Raw logs remain private by default.

## 9. Memory and Governance Path

The diagram should show memory/governance files as institutional project state.

Examples of memory/governance categories:

* project state
* next actions
* run history
* cleanup plans
* governance docs
* roadmap docs
* validation history

Public release should not include raw private memory.

The diagram should distinguish:

* public-safe docs
* private portfolio docs
* private runtime memory

## 10. Validation and Control Path

The system validates actions using:

* secret scans
* selected-file exposure
* copied sandboxes
* hash checks
* JSON validation
* JSONL structural checks
* process checks
* global-state checks
* code-fence checks for documentation
* required-denial checks
* human approval gates

The diagram should show validation as a control layer around agent expansion.

Validation should be shown as part of the architecture, not as an afterthought.

## 11. Future-State Overlays

Future overlays may show:

* OpenClaw finite read-only verifier
* eval harness
* OpenTelemetry-style GenAI trace schema
* policy engine
* signed tool descriptors
* MCP tool/resource layer
* A2A agent delegation layer
* human-approved patch workflow
* public/private release pipeline

These must be labeled as future / not yet implemented.

The diagram should not imply production readiness.

The diagram should not imply that OpenCode, OpenClaw, MCP, A2A, or autonomous loops are already active.

## 12. What Must Not Be Shown Publicly

Do not show:

* interview preparation
* private pitch notes
* private prompts
* private handoffs
* local operational memory
* raw audit logs
* raw run history
* local user paths
* internal hashes unless needed
* any token/auth examples
* cleanup/delete candidates
* sensitive gateway internals
* anything implying production readiness
* anything suggesting unrestricted autonomous execution

The public project should show the control model, not private working notes.

## 13. Mermaid Draft Diagram

This Mermaid draft is intentionally stored as plain text without code fences to avoid shell-paste corruption.

Mermaid draft:

flowchart LR

```
Owner["Human Owner / Final Approval Authority"]

subgraph Governance["Governance Plane"]
    Hermes["Hermes / CEO / Strategy / Gates"]
    Memory["Memory and Governance Store / Project State / Run History / Roadmaps"]
end

subgraph LocalBoundary["Localhost Control Boundary"]
    Provider["Local OpenAI-Compatible Provider"]
    Nginx["Nginx / 127.0.0.1:8081"]
    Gateway["Flask OpenAI-Compatible Gateway / 127.0.0.1:8080"]
    MLX["MLX Local Inference"]
    Strategy["Strategy Model Route"]
    Engineering["Engineering Model Route"]
    Lab["Future Lab Validation Route"]
end

subgraph FutureAgents["Future Agent Planes"]
    OpenCode["OpenCode / CTO / Engineering Execution / Not Yet Expanded"]
    OpenClaw["OpenClaw / CIO+CISO / Assurance / Verifier First"]
end

subgraph Evidence["Evidence and Controls"]
    Audit["Audit Logs"]
    Validation["Validation Controls / Hashes / Secret Scans / JSONL / Process Checks"]
end

subgraph PublicPrivate["Public / Private Artifact Boundary"]
    Public["Public Release Candidate / Sanitized"]
    Private["Private Portfolio and Runtime Notes / Not Public By Default"]
end

Owner --> Hermes
Hermes --> Memory
Hermes --> Provider
Provider --> Nginx
Nginx --> Gateway
Gateway --> MLX
MLX --> Strategy
MLX --> Engineering
MLX --> Lab

Gateway --> Audit
Audit --> Validation
Memory --> Validation

Hermes -. future gated delegation .-> OpenCode
Hermes -. future gated assurance request .-> OpenClaw
OpenCode -. future evidence .-> OpenClaw
OpenClaw -. future control report .-> Hermes

Memory --> PublicPrivate
Validation --> PublicPrivate
PublicPrivate --> Public
PublicPrivate --> Private
```

## 14. draw.io / Lucidchart Guidance

Recommended visual structure:

Left side:

* Human Owner
* Hermes governance plane

Center:

* Localhost control boundary
* local provider
* Nginx
* Flask gateway
* MLX
* model routes

Right side:

* future OpenCode
* future OpenClaw
* future MCP/A2A

Bottom:

* audit logs
* validation controls
* memory/governance store

Far bottom or side:

* public/private artifact boundary

Use labels:

* implemented
* validated
* future / not yet implemented
* private / not public

Avoid icons that make the project look like a generic chatbot.

Make it look like an enterprise control plane.

The public diagram should be clean, high-level, and defensible.

## 15. Interview Explanation Script

Short version:

This architecture shows a local-first AI infrastructure lab where model access is mediated through a controlled gateway instead of letting agents directly run commands. Hermes acts as the governance plane, OpenCode is the future engineering execution plane, and OpenClaw is the future assurance plane. The system uses audit logs, model routing, sandbox validation, memory governance, and human approval gates to keep autonomy controlled.

Technical version:

The request path goes from Hermes through a local OpenAI-compatible provider into an Nginx loopback boundary, then into a Flask OpenAI-compatible gateway backed by MLX local inference. The gateway enforces authentication behavior, model routing, max-token clamps, and audit logging. OpenCode and OpenClaw are intentionally future-gated. The system validates each access expansion through copied sandboxes, secret scans, hash checks, JSONL checks, process checks, and global-state checks.

Strategic version:

The goal is not to build an agent that can do everything. The goal is to build a governance and control plane for private agentic AI adoption in high-trust environments. That is why the architecture separates strategy, execution, assurance, and final human approval.

Public-release version:

The public project should show the architecture, control model, security posture, governance discipline, and future roadmap. It should not include private interview preparation, private prompts, raw operational memory, raw logs, or sensitive local implementation details.
