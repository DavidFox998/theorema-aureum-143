#!/bin/bash
set -e
pnpm install --frozen-lockfile
pnpm --filter db push

# Rehydrate `.lake/packages/<pkg>/.git/` for every vendored Lake
# dependency from its committed tar under `lean-proof-towers/lake-deps/`.
# The outer repo cannot carry nested `.git/` directories, so they vanish
# on every merge and have to be restored here before any Lake operation
# can run safely. Task #76 (follow-up to Task #66).
./scripts/restore-lake-git.sh

# Guard against silent Lean proof drift. Fails the merge if `lean-proof/**`
# changed in a way that breaks the axiom-debt check or leaves VERIFY.txt stale.
# When `lake` is unavailable the check prints a visible warning and exits 0
# so merges aren't blocked in environments without a Lean toolchain.
./scripts/check-lean-proof.sh

# Re-verify the Genesis-seal tamper-evidence guarantees on every merge.
# This fails the merge if anyone "fixes" check-genesis-seal.py,
# lean_bridge._guard, or kernel.probe() in a way that weakens the
# tamper detection covered by tests/test_morningstar.py.
echo ">> running tests/test_morningstar.py (Genesis-seal tamper-evidence)" >&2
python -m pytest tests/test_morningstar.py -q

# At-rest integrity guard against silent truncation / in-place rewrite of
# the probe ledger. The Genesis seal only covers the 9-line preamble; this
# catches a stray truncating-write (mode 'w', Path.write_text, or a
# shell-redirect overwrite) that preserves the preamble but wipes the
# body. Task #53.
echo ">> running scripts/check-ledger-integrity.py (at-rest ledger guard)" >&2
python scripts/check-ledger-integrity.py

./scripts/print-direction.sh >&2
