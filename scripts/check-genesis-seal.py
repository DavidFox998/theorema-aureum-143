#!/usr/bin/env python3
"""Verify the Genesis preamble of data/hits.txt against a baked-in hash.

The preamble is everything from line 1 through (and including) the
"--- GENESIS SEAL ---" marker. Exits 0 if the seal matches, non-zero
otherwise. kernel.probe calls this before any append, so a tampered
Genesis halts the lab.
"""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HITS = REPO_ROOT / "data" / "hits.txt"

# SHA-256 of the immutable preamble (header comments + 5 Genesis lines
# + "--- GENESIS SEAL ---" marker), each terminated by '\n'.
# Recompute with:
#   awk '{print} /^--- GENESIS SEAL ---$/{exit}' data/hits.txt | sha256sum
EXPECTED_SEAL = "eecbcd9a540aa7a2c90edd23827c73e4d1bb5af641d352f70a5de849b21f875f"

SEAL_MARKER = "--- GENESIS SEAL ---"


def preamble_bytes(path: Path = HITS) -> bytes:
    if not path.exists():
        raise SystemExit(f"FATAL: {path} missing.")
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    try:
        marker_idx = lines.index(SEAL_MARKER)
    except ValueError as e:
        raise SystemExit(
            f"FATAL: {path} missing required marker {SEAL_MARKER!r}."
        ) from e
    body = "\n".join(lines[: marker_idx + 1]) + "\n"
    return body.encode("utf-8")


def compute_seal(path: Path = HITS) -> str:
    return hashlib.sha256(preamble_bytes(path)).hexdigest()


def main() -> int:
    got = compute_seal()
    if got != EXPECTED_SEAL:
        print(
            f"FATAL: Genesis seal mismatch.\n  expected: {EXPECTED_SEAL}\n  got:      {got}",
            file=sys.stderr,
        )
        return 1
    print(f"ok: Genesis seal verified ({got})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
