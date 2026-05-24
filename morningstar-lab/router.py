"""Layer 3 (Network) — router.route.

Routes a probe to the right placeholder path:
  N == 19   -> Mazur (M17) placeholder
  h == 2    -> Stark (M18) placeholder
  otherwise -> generic kernel.probe

Honest-scope: M17/M18 are NOT proved. The router returns a labelled
placeholder so callers can see exactly which path was taken without
any number-theoretic claim being smuggled in.
"""

from __future__ import annotations

from typing import Any

import kernel


def route(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    base = kernel.probe(h, N, re_s, im_s)
    if N == 19:
        base["path"] = "M17_Mazur"
        base["status"] = "not_yet_proved"
    elif h == 2:
        base["path"] = "M18_Stark"
        base["status"] = "not_yet_proved"
    else:
        base["path"] = "generic"
        base["status"] = "logged"
    return base
