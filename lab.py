"""Layer 7 (Application) — MorningStar-Lab REPL/CLI.

Usage:
  python lab.py                            # banner + interactive REPL
  python lab.py -c "probe(1,19,0.5,0)"     # one-shot probe expression
  python lab.py                            # interactive: type 'probe 2 547 0 0'
"""

from __future__ import annotations

import argparse
import json
import re
import sys

import kernel

BANNER = "MorningStar-Lab 4D Ready. Axes: W=h Z=N X=Re Y=Im"


def _parse_probe(expr: str) -> tuple[int, int, float, float]:
    """Parse 'probe(h,N,re,im)' or 'probe h N re im'."""
    s = expr.strip()
    if not s.startswith("probe"):
        raise ValueError(f"unknown command: {expr!r}")
    rest = s[len("probe") :].strip()
    if rest.startswith("(") and rest.endswith(")"):
        rest = rest[1:-1]
    parts = [p for p in re.split(r"[,\s]+", rest) if p]
    if len(parts) != 4:
        raise ValueError(f"probe needs 4 args (h N re_s im_s); got {len(parts)}")
    h, N, re_s, im_s = parts
    return int(h), int(N), float(re_s), float(im_s)


def _format_result(out: dict) -> str:
    pretty = {k: v for k, v in out.items() if k != "ledger_line"}
    return json.dumps(pretty, sort_keys=True, indent=2) + "\n  ledger: " + out["ledger_line"]


def run_one(expr: str) -> int:
    h, N, re_s, im_s = _parse_probe(expr)
    out = kernel.probe(h, N, re_s, im_s)
    print(_format_result(out))
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
    ap = argparse.ArgumentParser(prog="lab.py")
    ap.add_argument("-c", "--command", help="one-shot probe expression")
    args = ap.parse_args()
    if args.command:
        return run_one(args.command)
    return repl()


if __name__ == "__main__":
    sys.exit(main())
