"""Structured decision audit for the governance plane.

The human-readable audit.log is good for tailing; a governance plane also needs a
machine-parseable record of *authorization decisions* (who, what, allow/deny, why)
that a SIEM or log pipeline can ingest. This module appends one JSON object per
decision to ``decisions.jsonl``.

Auditing must never break the request path: any failure to write is swallowed.
"""

from __future__ import annotations

import json
import time
from typing import Any


class DecisionLog:
    """Append-only JSONL writer for authorization decisions."""

    def __init__(self, path: str):
        self._path = path

    def record(
        self,
        *,
        request_id: str,
        principal: str | None,
        method: str,
        path: str,
        model: str | None,
        decision: str,
        reason: str,
        status: int,
    ) -> None:
        event: dict[str, Any] = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "request_id": request_id,
            "principal": principal,
            "method": method,
            "path": path,
            "model": model,
            "decision": decision,
            "reason": reason,
            "status": status,
        }
        try:
            with open(self._path, "a", encoding="utf-8") as fh:
                fh.write(json.dumps(event, separators=(",", ":")) + "\n")
        except OSError:
            # Never let audit-logging failure break the request path.
            pass
