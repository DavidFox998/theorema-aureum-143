#!/usr/bin/env python3
"""Print the most recent ledger-integrity alerts from the on-disk ring
buffer (`data/ledger-alerts.jsonl`) for operators who are SSH'd into a
degraded server and don't want to boot the React dashboard.

Task #93. Reads `kernel.read_recent_alerts()` and renders one line per
entry, newest first, with timestamp, workflow, failure_mode, and the
per-transport delivery status.

Task #103. Cross-references the dashboard's dismissal sidecar
(`data/ledger-alerts.ack.json`) so on-call engineers running the CLI
don't see ghost incidents that the dashboard already considers
handled. By default acked entries are skipped; pass
`--include-acknowledged` to print them with an `ack'd <ts>` suffix.
Missing or malformed sidecar is a soft failure (matches the server's
behavior in `artifacts/api-server/src/lib/alertAckStore.ts`).

Exit code is always 0 when the log is missing or empty: this is an
informational surface, not a correctness gate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import kernel  # noqa: E402

ALERTS_ACK_PATH = REPO_ROOT / "data" / "ledger-alerts.ack.json"
_ACK_KEY_RE = re.compile(r"^[0-9a-f]{64}$")


def _compute_alert_id(timestamp: str, message: str) -> str:
    """Mirror `computeAlertId` in `artifacts/api-server/src/lib/alertAckStore.ts`:
    sha256 of `timestamp + "\\n" + message`, hex-encoded."""
    return hashlib.sha256((timestamp + "\n" + message).encode("utf-8")).hexdigest()


def _read_ack_map(path: Path) -> "dict[str, str]":
    """Read the dashboard's dismissal sidecar. Missing or malformed
    file is a soft failure — return `{}` rather than raising, matching
    `readAckMap` on the server side."""
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError:
        return {}
    trimmed = raw.strip()
    if not trimmed:
        return {}
    try:
        parsed = json.loads(trimmed)
    except json.JSONDecodeError:
        return {}
    if not isinstance(parsed, dict):
        return {}
    out: "dict[str, str]" = {}
    for k, v in parsed.items():
        if isinstance(k, str) and _ACK_KEY_RE.match(k) and isinstance(v, str):
            out[k] = v
    return out


def _fmt_transport(name: str, info: object) -> str:
    if not isinstance(info, dict):
        return f"{name}=?"
    status = info.get("status", "?")
    if status == "failed":
        err = info.get("error", "")
        if err:
            return f"{name}=failed({err})"
        return f"{name}=failed"
    return f"{name}={status}"


def _fmt_entry(entry: dict, ack_ts: "str | None" = None) -> str:
    ts = entry.get("timestamp", "?")
    workflow = entry.get("workflow", "?")
    failure_mode = entry.get("failure_mode", "?")
    delivery = entry.get("delivery") or {}
    transports = " ".join(
        _fmt_transport(name, delivery.get(name))
        for name in ("webhook", "email")
    )
    line = f"{ts}  {workflow}  {failure_mode}  [{transports}]"
    if ack_ts:
        line += f"  ack'd {ack_ts}"
    return line


def main(argv: "list[str] | None" = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Show the most recent ledger-integrity alerts and their "
            "per-transport delivery status."
        )
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="How many of the newest entries to show (default: 10).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a JSON array instead of a human-readable table.",
    )
    parser.add_argument(
        "--include-acknowledged",
        action="store_true",
        help=(
            "Also print alerts that operators dismissed via the "
            "dashboard (sidecar `data/ledger-alerts.ack.json`). "
            "Default is to hide them so the CLI and dashboard agree."
        ),
    )
    args = parser.parse_args(argv)

    limit = max(0, args.limit)
    if limit == 0:
        entries: "list[dict]" = []
    else:
        ack_map = _read_ack_map(ALERTS_ACK_PATH)
        if args.include_acknowledged or not ack_map:
            entries = kernel.read_recent_alerts(limit=limit)
        else:
            # Over-fetch so that, after dropping acked entries, we can
            # still return up to `limit` actionable ones. `+ len(ack_map)`
            # is a tight upper bound: every acked id must correspond to
            # an entry still on disk for it to actually filter one out.
            fetch_n = limit + len(ack_map)
            raw_entries = kernel.read_recent_alerts(limit=fetch_n)
            entries = []
            for e in raw_entries:
                ts = e.get("timestamp", "")
                msg = e.get("message", "")
                if isinstance(ts, str) and isinstance(msg, str):
                    alert_id = _compute_alert_id(ts, msg)
                    if alert_id in ack_map:
                        continue
                entries.append(e)
                if len(entries) >= limit:
                    break

    if args.json:
        if args.include_acknowledged:
            for e in entries:
                ts = e.get("timestamp", "")
                msg = e.get("message", "")
                if isinstance(ts, str) and isinstance(msg, str):
                    aid = _compute_alert_id(ts, msg)
                    ack_ts = _read_ack_map(ALERTS_ACK_PATH).get(aid)
                    if ack_ts:
                        e["acknowledged_at"] = ack_ts
        json.dump(entries, sys.stdout, indent=2, sort_keys=True, default=str)
        sys.stdout.write("\n")
        return 0

    if not entries:
        print(
            f"No alerts recorded (log: {kernel.ALERTS_LOG}).",
            file=sys.stderr,
        )
        return 0

    print(f"# {len(entries)} most-recent alert(s) from {kernel.ALERTS_LOG}")
    print("# timestamp                         workflow  failure_mode  [transports]")
    ack_map_for_render = (
        _read_ack_map(ALERTS_ACK_PATH) if args.include_acknowledged else {}
    )
    for entry in entries:
        ack_ts = None
        if args.include_acknowledged:
            ts = entry.get("timestamp", "")
            msg = entry.get("message", "")
            if isinstance(ts, str) and isinstance(msg, str):
                ack_ts = ack_map_for_render.get(_compute_alert_id(ts, msg))
        print(_fmt_entry(entry, ack_ts=ack_ts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
