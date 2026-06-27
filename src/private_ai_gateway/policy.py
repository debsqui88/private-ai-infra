"""Policy-as-code: identity and authorization for the gateway.

A *governance plane* needs externalized, auditable policy rather than logic baked
into the request handler. This module loads principals (API-key identities) from a
TOML policy file and answers two questions for each request:

  1. Identity  — which principal does this bearer token belong to?
  2. Authority — is that principal allowed to use the requested model, and under
                 what output-token cap?

API keys are never stored in plaintext: the policy file holds the SHA-256 hash of
each key, and the gateway hashes the presented token to look up the principal. If
no policy file exists, the gateway falls back to single-principal mode using
``PRIVATE_AI_AUTH_TOKEN`` (see app.py), which keeps local development zero-config.

TOML is parsed with the standard-library ``tomllib`` (Python 3.11+), so this adds
no runtime dependency.
"""

from __future__ import annotations

import hashlib
import tomllib
from dataclasses import dataclass


@dataclass(frozen=True)
class Principal:
    """An authenticated identity and what it is permitted to do."""

    name: str
    allowed_models: frozenset[str]
    max_output_tokens: int | None = None

    def may_use(self, alias: str) -> bool:
        """True if this principal may call the given model alias."""
        return "*" in self.allowed_models or alias in self.allowed_models


def hash_token(token: str) -> str:
    """Return the lowercase hex SHA-256 of a bearer token."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class Policy:
    """A set of principals indexed by the SHA-256 hash of their API key."""

    def __init__(self, principals_by_hash: dict[str, Principal]):
        self._by_hash = dict(principals_by_hash)

    @property
    def principal_count(self) -> int:
        return len(self._by_hash)

    @classmethod
    def load(cls, path: str) -> "Policy":
        """Load principals from a TOML file; return an empty policy if absent.

        Malformed entries are skipped rather than crashing the gateway — a single
        bad policy line should not take the whole control plane down.
        """
        try:
            with open(path, "rb") as fh:
                raw = tomllib.load(fh)
        except FileNotFoundError:
            return cls({})

        principals: dict[str, Principal] = {}
        for entry in raw.get("principals", []):
            try:
                key_hash = str(entry["key_sha256"]).strip().lower()
                if not key_hash:
                    continue
                cap = entry.get("max_output_tokens")
                principals[key_hash] = Principal(
                    name=str(entry.get("name", "unnamed")),
                    allowed_models=frozenset(entry.get("allowed_models", [])),
                    max_output_tokens=int(cap) if cap is not None else None,
                )
            except (KeyError, TypeError, ValueError):
                continue
        return cls(principals)

    def identify(self, bearer_token: str) -> Principal | None:
        """Return the principal for a bearer token, or None if unknown."""
        if not bearer_token:
            return None
        return self._by_hash.get(hash_token(bearer_token))
