"""The security eval report: score the probes, render them, decide a verdict.

A control that held is a PASS; one that let the attack through is a FAIL. The verdict is
**FAIL** if any control failed, otherwise **PASS**. SKIPPED probes (couldn't run in this
environment) are listed explicitly so coverage gaps are visible, never hidden. As a CI
gate, ``exit_code()`` returns 1 only on FAIL — a regression that weakens a control breaks
the build.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import datetime, timezone

from evals.harness import FAIL, PASS, SKIP, EvalResult

VERDICT_FAIL = "FAIL"
VERDICT_PASS = "PASS"  # nosec B105 — verdict label, not a credential


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


@dataclass
class EvalReport:
    results: list[EvalResult] = field(default_factory=list)
    generated_at: str = field(default_factory=_utc_now_iso)
    component: str = "security-evals"

    def counts(self) -> dict[str, int]:
        c = {PASS: 0, FAIL: 0, SKIP: 0}
        for r in self.results:
            c[r.status] = c.get(r.status, 0) + 1
        return c

    @property
    def verdict(self) -> str:
        return VERDICT_FAIL if any(r.status == FAIL for r in self.results) else VERDICT_PASS

    def exit_code(self) -> int:
        return 1 if self.verdict == VERDICT_FAIL else 0

    def to_dict(self) -> dict:
        return {
            "component": self.component,
            "generated_at": self.generated_at,
            "verdict": self.verdict,
            "counts": self.counts(),
            "results": [
                {
                    "id": r.case.id,
                    "category": r.case.category,
                    "owasp": r.case.owasp,
                    "attack": r.case.attack,
                    "expectation": r.case.expectation,
                    "status": r.status,
                    "observed": {
                        "status": r.observation.status,
                        "code": r.observation.code,
                        "note": r.observation.note,
                    },
                }
                for r in self.results
            ],
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2) + "\n"

    def to_markdown(self) -> str:
        c = self.counts()
        lines = [
            "# Security eval report",
            "",
            f"- Generated: {self.generated_at}",
            f"- Verdict: **{self.verdict}**",
            f"- Probes: {c[PASS]} pass · {c[FAIL]} fail · {c[SKIP]} skipped",
            "",
            "| ID | Category | OWASP | Attack | Result |",
            "|---|---|---|---|---|",
        ]
        for r in self.results:
            attack = r.case.attack.replace("|", "\\|")
            lines.append(
                f"| `{r.case.id}` | {r.case.category} | {r.case.owasp} | {attack} "
                f"| {r.status.upper()} |"
            )
        lines.append("")
        return "\n".join(lines)

    def to_text(self) -> str:
        c = self.counts()
        lines = [
            "Security eval report",
            f"generated: {self.generated_at}",
            f"verdict:   {self.verdict}  "
            f"({c[PASS]} pass / {c[FAIL]} fail / {c[SKIP]} skipped)",
            "",
        ]
        for r in self.results:
            glyph = {PASS: "PASS", FAIL: "FAIL", SKIP: "SKIP"}.get(r.status, r.status)
            lines.append(f"[{glyph}] {r.case.id}  ({r.case.owasp})")
            lines.append(f"       attack:   {r.case.attack}")
            lines.append(f"       expected: {r.case.expectation}")
            obs = r.observation
            seen = obs.note or f"status={obs.status} code={obs.code!r}"
            lines.append(f"       observed: {seen}")
            lines.append("")
        return "\n".join(lines)


def build_report(results: list[EvalResult]) -> EvalReport:
    return EvalReport(results=results)
