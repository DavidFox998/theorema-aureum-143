---
name: Rigorous Bessel I0 series tail enclosure in Lean (mathlib v4.12.0)
description: How to bracket besselI_series 0 (rational arg) via partial sum + geometric tail majorant; the summable_nat_add_iff HOU trap and the div_eq_mul_inv wrong-slash trap.
---

# Enclosing `besselI_series 0 (x)` for a rational argument

Unlike `Real.exp` (alternating Lagrange bracket), `I₀(x) = ∑ (x/2)^{2k}/(k!)²`
has **all-positive terms**, so the bracket is one-sided:
`S_N ≤ I₀(x) ≤ S_N + err`, where `S_N` is the partial sum and `err` is a
**geometric tail majorant**:
`err = a_{N+1} / (1 - t/(N+2))` with `t = (x/2)²`, `a_k = (x/2)^{2k}/(k!)²`,
valid when `t/(N+2) < 1`.

- Lower bound: `sum_le_tsum` over nonnegative terms (partial sum ≤ total).
- Upper bound: split the series at `N+1` (`sum_add_tsum_nat_add`), bound the tail
  by the geometric majorant, rewrite to `S_N + err`.
- Build the interval with `min/max` so structural `lo ≤ hi` is free; point case
  collapses via `min_eq_left`/`max_eq_right` from `err ≥ 0`.

The tail term-domination key fact: `(N+1)! · (N+2)^i ≤ (i+N+1)!`
(`Nat.factorial_mul_pow_le_factorial`); square it for the `(k!)²` denominator,
giving `a_{i+N+1} ≤ a_{N+1} · (t/(N+2))^i`. Then `tsum_le_tsum` +
`tsum_geometric_of_lt_one` closes it. At `N=40`, `x=β₀/3≈0.693`, width ≈ 3.6e-137
(≪ any 5e-8 target).

## Two traps that cost compiles

- **`summable_nat_add_iff` HOU timeout.** Writing
  `have h : Summable (fun i => <BIG explicit lambda in (i+(N+1))>) := (summable_nat_add_iff (N+1)).mpr hT`
  makes Lean unify the *expected* type's function against `fun n => ?f (n+(N+1))`
  FIRST — higher-order, must abstract every occurrence of `i+(N+1)` in the big
  expression → `isDefEq`/`whnf` heartbeat timeout (200000). Fix: let `hT`
  determine `?f` first — `by have h := (summable_nat_add_iff (N+1)).mpr hT; exact h`.
  Now `?f` = hT's explicit lambda, the result beta-reduces, and `exact h` is a
  cheap defeq check. **Lesson:** when an iff/lemma's `.mpr`/`.mp` would force HOU
  from the goal, bind the determining hypothesis with `have := …` (no expected
  type) and close with `exact`, never write it as a directly-typed term.
- **`rw [div_eq_mul_inv]` rewrites the WRONG slash.** Goal
  `X * c⁻¹ = X / c` where `X` contains `(y/2)` — `rw [div_eq_mul_inv]` hits the
  first `/` it finds (`y/2`), not the outer division, leaving an unsolved goal.
  Fix: close field identities like this with `ring`, not a targeted `rw`.

## Verifying the numerics (sanity, NOT the proof)

Same as the exp recipe: Lean machine-check + `#print axioms` = classical trio is
ground truth. Widths ~1e-137 are absurdly below double epsilon; use `mpmath`
(`mp.dps` huge) built from the exact integer ratio if a sanity check is wanted.
