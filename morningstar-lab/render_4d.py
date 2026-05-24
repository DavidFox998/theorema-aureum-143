"""Layer 6 (Presentation) — render_4d.py.

Projects a probed 4D point (W=h, Z=N, X=Re, Y=Im) to a 2D ASCII tag.
Honest-scope: no plotting library, no fabricated visuals. Pure text
summary suitable for piping into a log.
"""

from __future__ import annotations

import json
import sys


def render(point: dict) -> str:
    w = point.get("h", "?")
    z = point.get("N", "?")
    x = point.get("RH_ok", "?")
    path = point.get("path", "generic")
    status = point.get("status", "?")
    return f"[4D] W=h={w}  Z=N={z}  on-critical-line={x}  path={path}  status={status}"


if __name__ == "__main__":
    raw = sys.stdin.read().strip() or "{}"
    print(render(json.loads(raw)))
