"""Adversarial security evals for the gateway's enforced controls.

Where OpenClaw verifies *evidence after the fact*, the eval harness is active: it drives
the gateway (and the egress guardrail) with attack-shaped inputs and asserts the control
holds. Each eval is tagged with the OWASP LLM / agentic risk it exercises, and the suite
emits a pass/fail report that exits non-zero if any control failed — an artifact a
security reviewer can run.

The thesis the project enforces — *capability is not authority* — only means something if
it survives someone trying to get around it. These evals are that someone.
"""

__version__ = "0.9.0"
