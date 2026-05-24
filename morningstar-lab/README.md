# MorningStar-Lab v1.0 — 4D Sandbox

**Status:** Sandbox / playground. **NOT part of the v1.8-BC certified spine.**

This directory implements the seven-layer 4D research space described in the
MorningStar-Lab spec. It lives outside `lean-proof/` on purpose: the certified
spine (M1–M10 + M13, `main_theorem` axiom debt `[]`) must not depend on
anything in this folder, and the strict CI guard (`scripts/check-lean-proof.sh`)
must continue to pass independently.

## Axes

| Axis | Meaning |
|------|---------|
| W    | Class number h |
| Z    | Conductor N |
| X    | Re(s) |
| Y    | Im(s) |

## Seven Layers (OSI-style)

| # | Name         | Job                 | File              |
|---|--------------|---------------------|-------------------|
| 7 | Application  | What you touch      | `lab.py`          |
| 6 | Presentation | Makes it human      | `render_4d.py`    |
| 5 | Session      | Keeps state         | `data/state.json` |
| 4 | Transport    | Guarantees delivery | `kernel.py`       |
| 3 | Network      | Routes the math     | `router.py`       |
| 2 | Data         | Formats proofs      | `lean_bridge.py`  |
| 1 | Physical     | Truth on disk       | `data/hits.txt`   |

## Layer 1 — Append-only ledger

`data/hits.txt` is **append-only**. The seed line
`437\n1094\naxioms=[] 2026-05-24` is never modified. Every `probe()` call
appends a SHA-256 hash line; existing lines are never rewritten or deleted.

`data/M13_CERT.txt` records the SHA-256 of the parent checkpoint and is
written exactly once.

## Honest-scope notes (read these before reading anything else)

1. `kernel.probe()` is a **placeholder transport**. It does not actually call
   SageMath or PARI; it returns a structurally correct dict and logs an
   audit-trail hash to `data/hits.txt`. `L_nonvanish` is reported as
   `None` (unknown), not a fabricated boolean. `RH_ok` is the literal
   predicate `re_s == 0.5` — i.e. "did the caller probe on the critical
   line", not a claim about ζ.
2. `lean/AutoLemmas.lean` proves `theorem hit_437 : True := trivial` and
   `theorem hit_1094 : True := trivial`. These are tautologies whose **names**
   reference the OpenCV cube counts from README Appendix A; their
   **statements** are just `True`. Nothing here claims 437 or 1094 has any
   number-theoretic meaning. Axiom check: `#print axioms hit_437` prints `[]`.
3. The `M17` (Mazur, N=19) and `M18` (Stark, N=547) probes are
   **labelled placeholders**. They return `{"status": "not_yet_proved"}`.
   No certificate, no Lean theorem, no claim of a Stark unit.
4. This sandbox uses its own minimal Lean project (no mathlib). It does
   **not** import `TheoremaAureum`, and `TheoremaAureum` does not import it.

## Run

```bash
# 1. one-time setup (idempotent: re-writing seed is a no-op)
python morningstar-lab/lab.py --seed

# 2. probe (appends an audit hash to data/hits.txt)
python morningstar-lab/lab.py -c "probe(1,19,0.5,0)"

# 3. emit and verify the trivial Lean lemmas
python morningstar-lab/lean_bridge.py
( cd morningstar-lab/lean && lean AutoLemmas.lean )

# 4. full validation
bash morningstar-lab/run.sh
```

`run.sh` exits 0 iff both the probe and the Lean axiom check succeed, and
prints the spec's ready line on success.
