"""Layer 4 (Transport) — MorningStar-Lab kernel.

probe(h, N, re_s, im_s) -> dict.

Honest-scope: SageMath is NOT installed, so L_nonvanish is a deterministic
stub (always True) and the appended ledger line carries a NEEDS_SAGE tag
so the value can never be mistaken for a real L-function evaluation.

Append-only invariant: before any write, this module shells out to
scripts/check-genesis-seal.py and refuses to proceed if the Genesis
(lines 1-5 of data/hits.txt) has been altered.
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent
HITS = REPO_ROOT / "data" / "hits.txt"
SEAL_CHECK = REPO_ROOT / "scripts" / "check-genesis-seal.py"


def _verify_seal() -> None:
    """Run check-genesis-seal.py; raise if it fails."""
    result = subprocess.run(
        [sys.executable, str(SEAL_CHECK)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Genesis seal verification failed (exit {result.returncode}):\n"
            f"{result.stderr.strip() or result.stdout.strip()}"
        )


def _append_line(line: str) -> None:
    """Append exactly one line + newline to hits.txt and fsync."""
    HITS.parent.mkdir(parents=True, exist_ok=True)
    with HITS.open("a", encoding="utf-8") as f:
        f.write(line + "\n")
        f.flush()
        os.fsync(f.fileno())


def probe(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    """Run a single 4D probe and append exactly one ledger line.

    Returns a dict with keys: h, N, L_nonvanish, RH_ok, sha, ledger_line.
    """
    _verify_seal()

    ts = time.time_ns()
    inputs = {"h": int(h), "N": int(N), "re_s": float(re_s), "im_s": float(im_s)}

    # Honest-scope stub: L_nonvanish is deterministically True (no Sage call).
    # The NEEDS_SAGE tag on the ledger line marks it as unverified.
    output = {
        "h": inputs["h"],
        "N": inputs["N"],
        "L_nonvanish": True,
        "RH_ok": inputs["re_s"] == 0.5,
    }

    digest_payload = {"ts": ts, "in": inputs, "out": output, "tag": "NEEDS_SAGE"}
    body = json.dumps(digest_payload, sort_keys=True, separators=(",", ":"))
    sha = hashlib.sha256(body.encode("utf-8")).hexdigest()

    ledger_line = (
        f"probe ts={ts} h={inputs['h']} N={inputs['N']} "
        f"re={inputs['re_s']} im={inputs['im_s']} "
        f"L_nonvanish={output['L_nonvanish']} RH_ok={output['RH_ok']} "
        f"NEEDS_SAGE sha={sha}"
    )
    _append_line(ledger_line)

    return {**output, "sha": sha, "ledger_line": ledger_line}


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("usage: kernel.py h N re_s im_s", file=sys.stderr)
        sys.exit(2)
    out = probe(int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]))
    print(json.dumps(out, sort_keys=True))
