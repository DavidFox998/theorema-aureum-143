#!/usr/bin/env bash
# MorningStar-Lab v1.0 validation runner.
# Exits 0 iff:
#   - lab.py probe runs cleanly
#   - lean_bridge.py emits AutoLemmas.lean with no sorry/axiom
#   - `lean AutoLemmas.lean` reports `does not depend on any axioms`
#     for hit_437 and hit_1094
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

echo ">> lab.py --seed"
python lab.py --seed >/dev/null

echo ">> lab.py probe(1,19,0.5,0)"
python lab.py -c "probe(1,19,0.5,0)" >/dev/null

echo ">> lean_bridge.py"
python lean_bridge.py >/dev/null

echo ">> guard: no sorry, no axiom in AutoLemmas.lean"
if grep -nE '(^|[^A-Za-z_])(sorry|axiom)([^A-Za-z_]|$)' lean/AutoLemmas.lean; then
  echo "FATAL: AutoLemmas.lean contains sorry/axiom" >&2
  exit 1
fi

echo ">> lean AutoLemmas.lean (axiom check)"
LEAN_OUT="$(cd lean && lean AutoLemmas.lean)"
echo "$LEAN_OUT"
echo "$LEAN_OUT" | grep -qE "MorningStarLab\.hit_437.*does not depend on any axioms" \
  || { echo "FATAL: hit_437 axiom check failed" >&2; exit 1; }
echo "$LEAN_OUT" | grep -qE "MorningStarLab\.hit_1094.*does not depend on any axioms" \
  || { echo "FATAL: hit_1094 axiom check failed" >&2; exit 1; }

echo
echo "MorningStar-Lab v1.0 online. 4D stable. W=h Z=N X=Re Y=Im. CERTIFICATE at morningstar-lab/data/M13_CERT.txt"
