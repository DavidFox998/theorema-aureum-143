---
name: Lean `star` vs `starRingEnd ℂ` defeq gap
description: Why `rw` leaves an unsolved goal when one side is `star z` and the other `(starRingEnd ℂ) z`, and how to finish.
---

# `star z` vs `(starRingEnd ℂ) z` (`conj`) — defeq but not syntactic

`conj z` notation = `(starRingEnd ℂ) z`, which is **definitionally equal** to
`star z` but NOT syntactically equal. `rw` only closes a goal by *syntactic* rfl,
so after e.g. `rw [Matrix.star_apply, Complex.normSq_eq_conj_mul_self]` you can be
left with an "unsolved goals" like:

    ⊢ star (A k j) * A k j = (starRingEnd ℂ) (A k j) * A k j

**Fix:** finish with `exact` (or `exact_mod_cast`) rather than `rw`, because
`exact` checks up to *defeq*:

    rw [Matrix.star_apply]
    exact Complex.normSq_eq_conj_mul_self.symm

**Why:** `exact`/`apply` unify up to definitional equality; `rw`'s trailing
auto-`rfl` does not. Whenever a `rw` chain dies on a `star`/`conj`/`starRingEnd`
mismatch (or any reducible-def wrapper), switch the final step to `exact`.
