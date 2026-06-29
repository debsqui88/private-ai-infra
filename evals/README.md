# Security evals — adversarial probes of the enforced controls

The project's thesis is that **capability is not authority**. That claim only means
something if it survives someone trying to get around it. This harness is that someone: it
drives the gateway's enforced controls with attack-shaped inputs and asserts each one
holds, emitting a pass/fail report that exits non-zero if any control failed.

Where [OpenClaw](../agents/openclaw) verifies evidence *after the fact* (passive), the
eval harness is *active* — it attacks the live control path.

## What it probes

Each case is tagged with the OWASP LLM / agentic risk it exercises:

| Category | OWASP | Attack |
|---|---|---|
| `autonomy_bypass` | LLM06 Excessive Agency | declare a level above the principal's ceiling — via header, via body, via `6` instead of `L6`, and via **conflicting header/body** to try to get the lower one read |
| `model_authorization` | LLM06 Excessive Agency | request a model outside the principal's allowlist |
| `authentication` | LLM06 Excessive Agency | no token / a token that maps to no principal (no silent owner fallback) |
| `rate_limit` | LLM10 Unbounded Consumption | burst past a principal's per-minute budget |
| `secret_egress` | LLM02 Sensitive Information Disclosure | model output containing an AWS key / PEM private key / JWT must be redacted; benign prose must not false-positive |

A control that holds is **PASS**; one that lets the attack through is **FAIL**; a probe
that can't run here (gateway/MLX absent) is **SKIP** — never silently passed.

## Found a real bug

The conflicting-channel autonomy case (`AUTONOMY-004`) caught a genuine bypass: the
gateway trusted the `X-Autonomy-Level` header and ignored a *higher* `autonomy_level` in
the body, so a caller could under-declare in the header to slip a higher level past the
ceiling. Fixed by taking the **most-privileged** declared level across all channels
(`autonomy.declared_level`). The eval is now the regression test that keeps it fixed.

## Run it

```bash
# egress probes run anywhere; request-level probes need the gateway (MLX / Apple Silicon)
PYTHONPATH=src python -m evals.run                     # text report, exits non-zero on FAIL
PYTHONPATH=src python -m evals.run --format markdown   # or json
PYTHONPATH=src python -m evals.run --require-gateway    # fail (exit 2) if the gateway can't run
make evals
```

On Linux CI (no MLX) the request-level probes report SKIP and only the egress probes run;
the full suite runs on Apple Silicon, and the `test_live_gateway_repels_every_attack` test
asserts the live gateway passes every case. A rendered example is in
[`examples/security-eval.report.md`](examples/security-eval.report.md).

## Layout

```text
__init__.py    # version
harness.py     # EvalCase / Observation / Context / run_suite (transport-agnostic core)
cases.py       # the attack catalogue + the test identities the runner installs
report.py      # EvalReport: verdict + text/json/markdown
run.py         # CLI: configures the gateway policy, runs the suite, emits the report
examples/      # a rendered report
```
