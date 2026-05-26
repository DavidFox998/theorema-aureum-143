import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

_HITS = REPO_ROOT / "data" / "hits.txt"
_CHECKPOINT = REPO_ROOT / "data" / "hits.txt.checkpoint"


@pytest.fixture(scope="session", autouse=True)
def _snapshot_ledger_for_session():
    """Snapshot data/hits.txt and data/hits.txt.checkpoint at session
    start; restore at session end (pass or fail).

    Why (task #58): `tests/test_kernel.py` runs real `kernel.probe()`
    calls. The kernel module's module-level constants `kernel.HITS` and
    `kernel.CHECKPOINT` point at the canonical ledger files. Tests
    monkeypatch `kernel.HITS` to a throwaway tmp_path, but
    `kernel.CHECKPOINT` is not monkeypatched, so every probe rewrites
    the real `data/hits.txt.checkpoint` with `(size_of_fake, sha_of_fake)`.
    Other tamper-tests deliberately mutate `data/hits.txt` in place.
    The net effect: after `pytest` finishes, `git status` is dirty on
    both files, and contributors have to remember to
    `git restore data/hits.txt data/hits.txt.checkpoint` by hand.

    This session-scoped autouse fixture snapshots both files once at
    session start (in-memory bytes) and atomically restores them at
    session teardown, regardless of test pass/fail. Per-test fixtures
    (`hits_backup`, `fresh_checkpoint`) keep working unchanged — they
    handle intra-test restore for the tampering body of a single test;
    this fixture is the outer safety net for cross-suite side effects
    like the kernel.CHECKPOINT rewrites.
    """
    # Task #59 — restore policy:
    #
    # * `data/hits.txt.checkpoint` is ALWAYS restored at session end.
    #   The checkpoint file is a tiny `(size, sha)` summary that
    #   `kernel.probe()` rewrites every call, even when tests
    #   monkeypatch `kernel.HITS` to a tmp_path — `kernel.CHECKPOINT`
    #   is not monkeypatched, so the real checkpoint gets stamped
    #   with the fake ledger's hash. That's the original reason this
    #   fixture exists (task #58). Restoring it is cheap and there
    #   is no concurrent writer racing against the checkpoint —
    #   `_update_checkpoint` always runs under
    #   `kernel.hits_exclusive_lock()` via `_append_line`, and we
    #   acquire the same lock here.
    #
    # * `data/hits.txt` is NOT restored from a session-start
    #   snapshot. Pre-task #59 this fixture restored it defensively,
    #   but that snapshot is fundamentally stale once the session
    #   begins: a concurrent cross-process probe workflow that
    #   legitimately appends during the session would have its line
    #   overwritten at teardown. Holding the sidecar flock across
    #   the entire session would prevent that, but it also dead-
    #   locks any test that spawns its own appender thread (e.g.
    #   `test_snapshot_restore_does_not_lose_concurrent_appends`)
    #   because the per-process RLock semantics block cross-thread
    #   acquisitions. The correct guarantee is the one task #59
    #   actually delivers: every test that intentionally mutates
    #   `data/hits.txt` goes through the `hits_backup` fixture,
    #   which holds `kernel.hits_exclusive_lock()` for its full
    #   snapshot → test-body → restore window. The lint test
    #   `test_no_non_append_writes_to_hits_txt` enforces that no
    #   other test path writes directly. So if `hits_backup`
    #   cleaned up correctly, no session-level restore is needed;
    #   if it didn't, restoring from a session-start snapshot
    #   wouldn't be safe anyway (overwrites concurrent appends).
    import kernel

    with kernel.hits_exclusive_lock():
        cp_snapshot = _CHECKPOINT.read_bytes() if _CHECKPOINT.exists() else None
    try:
        yield
    finally:
        with kernel.hits_exclusive_lock():
            if cp_snapshot is not None:
                _atomic_restore(_CHECKPOINT, cp_snapshot)
            elif _CHECKPOINT.exists():
                _CHECKPOINT.unlink()


def _atomic_restore(path: Path, data: bytes) -> None:
    """Restore `path` to `data` via sibling tempfile + os.replace.

    Uses the same atomic-write pattern as tests/test_morningstar.py
    `_atomic_write_bytes` so we don't briefly truncate the ledger
    during teardown — concurrent appender workflows must always see
    either the old bytes or the new bytes, never an empty file.
    """
    import os as _os

    tmp = path.with_name(path.name + ".session-restore.tmp")
    tmp.write_bytes(data)
    _os.replace(tmp, path)
