"""Layer 4 (Transport) — kernel.probe.

Honest-scope placeholder: this does NOT call SageMath. It returns a
structurally correct dict and appends a SHA-256 audit hash to
data/hits.txt (append-only ledger). It must exit 0 and must not raise.

The returned dict reports:
  h, N         : echoed inputs
  L_nonvanish  : None  (unknown; we do not fabricate a boolean)
  RH_ok        : re_s == 0.5  (literal: did the caller probe on the
                 critical line? This is NOT a claim about zeta.)
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
from typing import Any

HITS = Path(__file__).resolve().parent / "data" / "hits.txt"


def _append_hash(payload: dict[str, Any]) -> str:
    """Append a SHA-256 of the JSON payload to hits.txt and return it.

    Append-only: never rewrites or deletes existing lines.
    """
    body = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    digest = hashlib.sha256(body.encode("utf-8")).hexdigest()
    HITS.parent.mkdir(parents=True, exist_ok=True)
    with HITS.open("a", encoding="utf-8") as f:
        f.write(f"probe {digest}\n")
    return digest


def probe(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    inputs = {"h": int(h), "N": int(N), "re_s": float(re_s), "im_s": float(im_s)}
    result: dict[str, Any] = {
        "h": inputs["h"],
        "N": inputs["N"],
        "L_nonvanish": None,
        "RH_ok": inputs["re_s"] == 0.5,
    }
    digest = _append_hash({"in": inputs, "out": result})
    result["audit_sha256"] = digest
    return result


if __name__ == "__main__":
    import sys

    args = [float(x) for x in sys.argv[1:]]
    if len(args) != 4:
        print("usage: kernel.py h N re_s im_s", file=sys.stderr)
        sys.exit(2)
    out = probe(int(args[0]), int(args[1]), args[2], args[3])
    print(json.dumps(out, sort_keys=True))
