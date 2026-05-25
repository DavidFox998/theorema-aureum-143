#!/usr/bin/env bash
# check-towers.sh — Build the opt-in Towers Lean library (mathlib-backed
# first bricks for RH / Yang-Mills / Navier-Stokes) and verify the
# axiom debt of `N_monotone_in_sigma` is empty.
#
# This script targets the SIBLING package at `lean-proof-towers/`. The
# main spine package `lean-proof/` is deliberately untouched: it stays
# mathlib-free so the fast spine drift guard (`check-lean-proof.sh`)
# keeps running in seconds.
#
# Cost (cold cache, no mathlib oleans on disk):
#   - `lake update` resolves the mathlib v4.12.0 git dep (sources).
#   - `lake exe cache get` downloads ~2 GB of prebuilt mathlib oleans
#     from the Lean community CDN. Typically 5–15 min on a reasonable
#     connection.
#   - `lake build Towers` then compiles the Towers library on top of
#     mathlib. Typically <1 min on warm cache.
#
# Cost (warm cache, mathlib oleans already on disk under
#       `lean-proof-towers/.lake/packages/mathlib/.lake/build/`):
#   - 10–30 seconds total.
#
# Behaviour when `lake` is missing or the cache fetch fails (e.g.
# offline sandbox): exits non-zero with a clear message. There is no
# "soft skip" mode — the towers-build workflow is the canonical place
# to surface mathlib-availability problems.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOWERS_DIR="$REPO_ROOT/lean-proof-towers"
cd "$TOWERS_DIR"

if ! command -v lake >/dev/null 2>&1; then
  echo "error: \`lake\` (Lean 4) not on PATH." >&2
  echo "       Install Lean 4 via elan (https://leanprover.github.io/lean4/doc/setup.html)." >&2
  exit 127
fi

echo ">> lake update (resolve mathlib v4.12.0 manifest)" >&2
lake update

echo ">> lake exe cache get (fetch ~2 GB prebuilt mathlib oleans)" >&2
lake exe cache get

echo ">> lake build Towers" >&2
lake build Towers

echo ">> axiom-debt check: TheoremaAureum.Towers.RH.N_monotone_in_sigma" >&2
VERIFIER_DIR="$(mktemp -d)"
VERIFIER="$VERIFIER_DIR/VerifyTowers.lean"
AXIOM_LOG="$(mktemp)"
trap 'rm -f "$AXIOM_LOG"; rm -rf "$VERIFIER_DIR"' EXIT

cat > "$VERIFIER" <<'EOF'
import Towers.RH.ZeroDensity
#print axioms TheoremaAureum.Towers.RH.N_monotone_in_sigma
EOF

if ! lake env lean "$VERIFIER" 2>&1 | tee "$AXIOM_LOG"; then
  echo "error: lake env lean on Towers verifier failed." >&2
  exit 1
fi

# Acceptable axiom footprint: either truly zero axioms (no mathlib lemmas
# touched the proof term — unusual for a mathlib-backed lemma) OR the
# canonical mathlib classical trio {propext, Classical.choice, Quot.sound}
# and nothing else. These three are mathlib's foundational core; relying
# on them is NOT a research-grade debt. We refuse any other axiom name —
# in particular `sorryAx` (an unfinished proof), `Classical.em` if used
# directly outside the trio, or any user-declared `axiom`.
ZERO_LINE="'TheoremaAureum.Towers.RH.N_monotone_in_sigma' does not depend on any axioms"
TRIO_RE="^'TheoremaAureum\.Towers\.RH\.N_monotone_in_sigma' depends on axioms: \[((propext|Classical\.choice|Quot\.sound)(, (propext|Classical\.choice|Quot\.sound)){0,2})\]$"

if grep -qF "$ZERO_LINE" "$AXIOM_LOG"; then
  echo "ok: N_monotone_in_sigma has axiom debt = [] (no axioms used at all)." >&2
elif grep -qE "$TRIO_RE" "$AXIOM_LOG"; then
  echo "ok: N_monotone_in_sigma axiom footprint = subset of mathlib's classical trio" >&2
  echo "    {propext, Classical.choice, Quot.sound}. No research-grade axioms." >&2
else
  echo "error: axiom-debt check failed for N_monotone_in_sigma." >&2
  echo "       Allowed: (a) no axioms at all, or" >&2
  echo "                (b) a subset of {propext, Classical.choice, Quot.sound}." >&2
  echo "       Got:" >&2
  cat "$AXIOM_LOG" >&2
  exit 2
fi

echo "ok: Towers library built; N_monotone_in_sigma axiom footprint accepted." >&2
