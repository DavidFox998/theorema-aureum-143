#!/usr/bin/env python3
"""Print the last N ledger integrity alerts from `data/ledger-alerts.jsonl`.

Surfaces the on-disk ring buffer that `kernel._fire_ledger_alert`
writes on every invocation (task #71). The point: the next morning's
operator can see what fired, what was delivered, and what wasn't —
even after a server restart and even if both webhook and SMTP
transports were down at the time of the alert.

Usage:
  python scripts/show-ledger-alerts.py            # last 20 entries
  python scripts/show-ledger-alerts.py --limit 5  # last 5 entries
  python scripts/show-ledger-alerts.py --json     # raw JSON lines

Exits 0 always (informational surface). Empty log prints "(no alerts
on record)" — that is the normal healthy state.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import kernel  # noqa: E402


def _fmt(entry: dict) -> str:
    ts = entry.get("timestamp", "?")
    wf = entry.get("workflow", "?")
    mode = entry.get("failure_mode", "?")
    delivery = entry.get("delivery") or {}
    if not delivery:
        delivery_str = "no transports configured"
    else:
        parts = []
        for transport, info in sorted(delivery.items()):
            status = info.get("status", "?") if isinstance(info, dict) else "?"
            parts.append(f"{transport}={status}")
        delivery_str = ", ".join(parts)
    return (
        f"{ts}  workflow={wf}  failure_mode={mode}\n"
        f"  delivery: {delivery_str}\n"
        f"  expected_size={entry.get('expected_size')}  "
        f"actual_size={entry.get('actual_size')}\n"
        f"  message: {entry.get('message', '')}"
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=20, help="entries to show")
    ap.add_argument("--json", action="store_true", help="raw JSON output")
    args = ap.parse_args()

    entries = kernel.read_recent_alerts(limit=args.limit)
    if not entries:
        print("(no alerts on record)")
        return 0
    if args.json:
        for e in entries:
            print(json.dumps(e, sort_keys=True))
        return 0
    for e in entries:
        print(_fmt(e))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
