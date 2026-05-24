"""Layer 7 (Application) — lab.py.

Usage:
  python lab.py                      # banner + interactive REPL
  python lab.py -c "probe(2,547,0,0)"  # one-shot
  python lab.py --seed               # ensure data/hits.txt seed exists
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import kernel
import router

BANNER = "MorningStar-Lab 4D Ready. Axes: W=h Z=N X=Re Y=Im"
SEED = "437\n1094\naxioms=[] 2026-05-24\n"
HITS = Path(__file__).resolve().parent / "data" / "hits.txt"


def ensure_seed() -> None:
    HITS.parent.mkdir(parents=True, exist_ok=True)
    if not HITS.exists():
        HITS.write_text(SEED, encoding="utf-8")
        return
    # Append-only invariant: the first three seed lines must match.
    existing = HITS.read_text(encoding="utf-8").splitlines()
    expected = SEED.splitlines()
    if existing[: len(expected)] != expected:
        raise SystemExit(
            "FATAL: data/hits.txt seed has been modified; Layer 1 invariant broken."
        )


def _parse_probe(expr: str):
    """Parse 'probe(h,N,re,im)' (or 'probe h N re im') into 4 numbers."""
    expr = expr.strip()
    if expr.startswith("probe"):
        rest = expr[len("probe") :].strip()
        if rest.startswith("(") and rest.endswith(")"):
            rest = rest[1:-1]
        parts = [p.strip() for p in rest.replace(",", " ").split() if p.strip()]
        if len(parts) != 4:
            raise ValueError(f"probe needs 4 args, got {len(parts)}")
        h, N, re_s, im_s = parts
        return int(h), int(N), float(re_s), float(im_s)
    raise ValueError(f"unknown command: {expr!r}")


def run_one(expr: str) -> int:
    h, N, re_s, im_s = _parse_probe(expr)
    out = router.route(h, N, re_s, im_s)
    print(json.dumps(out, sort_keys=True))
    return 0


def repl() -> int:
    print(BANNER)
    print("type 'probe h N re_s im_s' or 'quit'")
    while True:
        try:
            line = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not line:
            continue
        if line in ("quit", "exit"):
            return 0
        try:
            run_one(line)
        except Exception as e:  # noqa: BLE001
            print(f"error: {e}", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("-c", "--command", help="one-shot probe expression")
    ap.add_argument("--seed", action="store_true", help="ensure hits.txt seed")
    args = ap.parse_args()
    ensure_seed()
    if args.seed and not args.command:
        print(BANNER)
        return 0
    if args.command:
        return run_one(args.command)
    return repl()


if __name__ == "__main__":
    sys.exit(main())
