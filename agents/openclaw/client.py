"""Read-only metrics client: OpenClaw scrapes ``/metrics`` as its own L0 principal.

When asked to reconcile the audit against live counters, OpenClaw fetches the Prometheus
text from the gateway. It authenticates as the ``openclaw`` principal and declares
autonomy **L0 (observe)** — it only ever issues a ``GET``. It never posts, never runs
inference, never changes state. The metrics endpoint is the single surface it touches.

Standard library only (``urllib``); no ``requests`` dependency.
"""

from __future__ import annotations

import urllib.error
import urllib.parse
import urllib.request


class MetricsError(RuntimeError):
    """Raised when the metrics endpoint cannot be read."""


class MetricsClient:
    def __init__(
        self,
        base_url: str,
        token: str,
        *,
        autonomy_level: str = "L0",
        timeout: float = 30.0,
    ):
        scheme = urllib.parse.urlparse(base_url).scheme
        if scheme not in ("http", "https"):
            raise ValueError(f"base_url must be http(s), got scheme {scheme!r}")
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.autonomy_level = autonomy_level
        self.timeout = timeout

    def fetch(self) -> str:
        """GET /metrics and return the Prometheus text body."""
        req = urllib.request.Request(
            f"{self.base_url}/metrics",
            method="GET",
            headers={
                "Authorization": f"Bearer {self.token}",
                "X-Autonomy-Level": self.autonomy_level,
            },
        )
        try:
            # Scheme is constrained to http(s) in __init__, so B310 (file:/custom
            # schemes) does not apply here.
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:  # nosec B310
                return resp.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")
            raise MetricsError(f"metrics endpoint returned {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise MetricsError(f"cannot reach gateway at {self.base_url}: {exc}") from exc
