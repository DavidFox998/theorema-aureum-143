#!/usr/bin/env python3
"""Verify the Genesis (lines 1-5) of data/hits.txt against a baked-in hash.

Exits 0 if the seal matches, non-zero otherwise. kernel.probe calls this
before any append, so a tampered Genesis halts the lab.
"""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HITS = REPO_ROOT / "data" / "hits.txt"

# SHA-256 of the exact five Genesis lines, each terminated by '\n'.
# Recompute with:
#   head -n 5 data/hits.txt | sha256sum
EXPECTED_SEAL = "88e6f4ff87592e10492a247dd0385af4ed37c1d4219bd67014e9ee83c05010c0"

GENESIS_LINES = 5


def compute_seal(path: Path = HITS) -> str:
    if not path.exists():
        raise SystemExit(f"FATAL: {path} missing.")
    with path.open("rb") as f:
        raw = f.read()
    text = raw.decode("utf-8")
    lines = text.split("\n")
    if len(lines) < GENESIS_LINES:
        raise SystemExit(
            f"FATAL: {path} has fewer than {GENESIS_LINES} lines; Genesis missing."
        )
    body = "\n".join(lines[:GENESIS_LINES]) + "\n"
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


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
