---
name: SU(3) Haar measure instance stack (Lean4 / mathlib v4.12.0)
description: What MeasureTheory haarMeasure actually requires, and how to give SU(3)=specialUnitaryGroup the missing instances when Matrix has no canonical metric.
---

# Building `haarMeasure` on `SU(3) = Matrix.specialUnitaryGroup (Fin 3) ℂ`

Reference implementation: `lean-proof-towers/Towers/YM/SU3Instances.lean`.
The non-obvious, reusable facts when equipping a matrix subgroup for Haar measure:

## What `MeasureTheory.Measure.haarMeasure` actually needs
Signature requires ONLY: `[Group G] [TopologicalSpace G] [TopologicalGroup G]
[MeasurableSpace G] [BorelSpace G]` + a `PositiveCompacts G` argument.
It does **NOT** need `LocallyCompactSpace` / `T2Space` / `SecondCountableTopology`
for the *definition* to elaborate (those matter for Haar *properties*, not the def).
`(⊤ : PositiveCompacts G)` exists from `[CompactSpace G] [Nonempty G]`.

**Why this matters:** you only have to manufacture five instances + nonemptiness,
not the whole locally-compact-T2 stack people assume.

## What mathlib ships (v4.12.0) and what is missing
- `specialUnitaryGroup n α := unitaryGroup n α ⊓ MonoidHom.mker detMonoidHom`
  (a `Submonoid (Matrix n n α)`). Ships with `TopologicalSpace` ONLY — not even `Group`.
- `unitaryGroup n α := unitary (Matrix n n α)` — has auto `Group`
  (`unitary.instGroup…`) but no `TopologicalGroup`/`CompactSpace`/`MeasurableSpace`.
- `Matrix (Fin 3)(Fin 3) ℂ` has `TopologicalSpace` (= the PRODUCT/Pi topology),
  `T2`, `ContinuousMul`, `TopologicalRing`, `ContinuousStar` — but **NO** canonical
  `MetricSpace`/`NormedAddCommGroup`/`ProperSpace` (matrices have many norms, so
  mathlib leaves the norm scoped/opt-in to avoid diamonds).

## The compactness route (the hard part)
Because there is no metric on `Matrix`, you CANNOT use metric Heine-Borel
(`Metric.isCompact_of_isClosed_isBounded` needs `ProperSpace`). Instead:
1. SU(3) is CLOSED: `isClosed_eq` on the two continuous conditions
   `A * star A = 1` (use `continuous_id.mul continuous_star`) and `A.det = 1`
   (`Continuous.matrix_det continuous_id`); intersect.
2. SU(3) ⊆ the compact poly-disc `Set.univ.pi (fun _ => Set.univ.pi (fun _ =>
   Metric.closedBall (0:ℂ) 1))`, compact by `isCompact_univ_pi` (twice) +
   `isCompact_closedBall` (ℂ is proper). The Matrix topology IS the Pi topology,
   so `isCompact_univ_pi` applies directly with a `: Set (Matrix …)` ascription.
3. Entries of a unitary are bounded by 1 (`norm_entry_le_one`): from
   `star A * A = 1`, the `(j,j)` entry gives `∑ₖ ‖A k j‖² = 1`
   (`Matrix.mul_apply`, `Matrix.star_apply`, `Complex.normSq_eq_conj_mul_self`,
   `Finset.single_le_sum`), so each `‖A i j‖ ≤ 1`.
4. `IsCompact.of_isClosed_subset` then `isCompact_iff_compactSpace`.

## Group/Measurable instances
- `Group`: build `{ (inferInstance : Monoid SU3) with inv := star, inv_mul_cancel := … }`
  so `Group.toMonoid` reuses the Submonoid monoid (no diamond). Field is
  `inv_mul_cancel` (`mul_left_inv` is deprecated). `star A ∈ SU3` because unitary
  is `star`-closed (`unitary.star_mem`) and `det (star A)=star(det A)=star 1=1`
  (`Matrix.star_eq_conjTranspose`, `Matrix.det_conjTranspose`).
- `TopologicalGroup`: `Continuous.subtype_mk` of restricted ambient mul / star
  (inverse on this group IS `star`).
- `MeasurableSpace := borel _`; `BorelSpace := ⟨rfl⟩`; `Nonempty := ⟨1⟩`.

**Result:** `haarMeasure ⊤` elaborates with axioms `[propext, Classical.choice,
Quot.sound]` (classical trio, no `sorryAx`). Verified via `lake env lean <file>`
+ `#print axioms`. Axioms are transitive, so trio on the final `def` certifies
the whole stack.
