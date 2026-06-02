---
name: Toeplitz det interval norm_num cost (Wall256 w1_weyl)
description: Measured cost + recipe for evaluating the assembled Bessel-Toeplitz det enclosure via norm_num, and what it does/doesn't discharge.
---

# Evaluating `toeplitzDetInterval k` (Wall256 w1_weyl finite enclosure) via `norm_num`

**Recipe (the two non-obvious requirements):**
- You MUST add `β₀_rat` to the `norm_num [...]` unfold set. If left as a `def`,
  every term stays symbolic (`(β₀_rat/3/2)^82`), norm_num evaluates nothing, and
  `min_def`/`max_def` expand into a giant unresolved nested-`ite` blowup.
- Include `min_def, max_def` (RatInterval.mul uses min/max) plus the def names:
  `toeplitzDetInterval, detI, besselIn_beta0_interval, besselIn_interval,
  besselIn_partial, besselIn_error, RatInterval.mul/add/sub/neg, ofRat,
  Finset.sum_range_succ, Finset.sum_range_zero, Nat.factorial, Fin.isValue`.
  Set `maxHeartbeats 0`.

**Measured cost (direct-lean, v4.12.0):** linear in #shifts.
`cost(n) ≈ 19s + 6s·n` (1-det 25s, 3-det 37s, 5-det 49s; ~13s is the Mathlib
import). Full 51-shift window (|k|≤25) ≈ **325s (~5.4 min), < 600s, ~4GB RSS**.
Trio-clean — norm_num uses no `native_decide`, no new axioms.

**Gotcha:** a `⊢ False` left by norm_num is SUCCESS-at-evaluating — it computed the
exact rational and the comparison was actually false. The central det
`(toeplitzDetInterval 0).hi` ≈ 1.13 (I0(β₀/3)≈1.124 dominates the 3×3), NOT small;
pick a true threshold (`< 100`) for a clean exit-0 cost measurement.

**What this DOES and does NOT buy (honesty):** Layer-5 feasibility only addresses
the arithmetic of `w1_weyl_partial.hi < 1/7` for the FINITE |k|≤25 enclosure. To
discharge the named axiom `w1_weyl_beta0_lt : w1_weyl β₀ < 1/7` you still need
(a) a k>25 `tsum`-tail bound (analytic, not norm_num; small — I_{25}(0.69)~1e-37,
but must be a formal lemma), and (b) the containment chain (toeplitz_det_contains
already gives per-k real membership). Even fully done, this removes at most ONE of
the two Hw1 axioms; `w1_eq_weyl` (the Weyl/character identity w1 = w1_weyl) needs
SU(3) representation theory absent from mathlib v4.12.0. So `hw1` reaches axiom
count 4 at best, NEVER the classical trio, via this route.
**Why:** keeps future work from over-claiming "hw1 discharged / trio-clean."
