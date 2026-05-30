/-
`Wall255_JensenObstruction.lean` — **HONEST mean-energy obstruction (a NO-GO).**

This file is the *dual* of `Wall257_StrongCoupling.vacuum_breaks_energy_lb`: it
proves, via Jensen's inequality, that the **mean** plaquette energy can NEVER
deliver the Kotecký–Preiss per-polymer smallness bound `polymerActivity ≤
(1/8)^|γ|`. It records WHY the `S4Numerics` entropy input plus a mean-energy
scale `e_bar` is *insufficient*, and isolates the genuine open problem as the
**large-deviation rate function**, not the mean.

WHAT IS GENUINE / UNCONDITIONAL (no hypotheses, classical trio):
* `plaquetteEnergy_le_two` — closes the *deferred analytic input* noted in
  `WilsonAction.plaquetteEnergy`: `plaquetteEnergy ≤ 2`, i.e. `Re tr P ≥ -3`,
  via `traceRe_le_three (-P)` (the plaquette `-P` is unitary too).
* `meanEnergy_le_two_card`, `e_bar_le_two` — the mean per-polymer energy is at
  most `2·|γ|`, hence `e_bar := meanEnergy/|γ| ≤ 2`.
* `jensen_obstruction` — the heart. For EVERY `β`,
    `exp(-(β · meanEnergy L γ)) ≤ polymerActivity L β γ`
  via `ConvexOn.map_integral_le` (Jensen for the convex `exp` against the
  probability measure `haarN`). This is a LOWER bound on the activity.

WHAT IS CONDITIONAL (on a single NAMED, genuinely-TRUE input):
* `mean_threshold_fails` — at the mean-energy threshold `β₀ := log 8 / e_bar`,
    `(1/8)^|γ| ≤ polymerActivity L β₀ γ`,
  taking `hpos : 0 < meanEnergy L γ` as a hypothesis. `0 < meanEnergy` is TRUE
  (the per-plaquette energy is positive off the `haarN`-null vacuum set) but its
  proof needs character orthogonality (`∫ tr = 0` / Peter–Weyl) or
  non-atomicity of `haarN`, NEITHER of which exists in mathlib v4.12.0 — the same
  measure-theoretic surface the tower already treats as OPEN
  (`Transfer.trivial_polymer_set_null`). It is a HYPOTHESIS, NOT `by sorry`, so
  NO `sorryAx`. `e_bar_pos_of_meanEnergy_pos` derives `0 < e_bar` from it.

THE HONEST CONCLUSION (the point of the file):
The Jensen bound points the WRONG WAY for Kotecký–Preiss: at the mean-energy
threshold the activity is `≥ (1/8)^|γ|`, not `≤`. So KP smallness CANNOT be
extracted from the mean energy `e_bar`; it is governed by the **large-deviation
rate function** of the plaquette-energy distribution (the Legendre transform),
not by its first moment. `S4Numerics` remains the exact ENTROPY side of KP; the
ENERGY side reduces to that rate function — the real open problem.

This file makes NO mass-gap / `μ > 0` / Surface-#1 claim, establishes NO KP
convergence, does NOT beat the `7ⁿ` entropy, does NOT give `ρ(T) < 1`, and does
NOT touch or discharge the disclaimed `Transfer.kotecky_preiss_criterion`
`sorry`. YM stays `Status: Open`.
-/
import Towers.YM.Transfer
import Mathlib.Analysis.Convex.Integral
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.Positivity

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Wall255Jensen

open Real MeasureTheory
open Wilson LatticeGauge SU3Instances Transfer

/-! ### `plaquetteEnergy ≤ 2` — closing the deferred `Re tr ≥ -3` direction -/

/-- **Brick (`plaquetteEnergy_le_two`).** The per-plaquette Wilson energy
`(3 - Re tr P)/3` is at most `2`. This is the *loaded* upper endpoint deferred in
`WilsonAction.plaquetteEnergy`: it amounts to `Re tr P ≥ -3`, which follows from
`traceRe_le_three` applied to `-P` (the negative of a unitary is unitary, and
`tr (-P) = -tr P`). Classical-trio, unconditional. -/
theorem plaquetteEnergy_le_two {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    plaquetteEnergy U x μ ν ≤ 2 := by
  have hunit : star (-(wilsonPlaquette U x μ ν)) * (-(wilsonPlaquette U x μ ν)) = 1 := by
    rw [star_neg, neg_mul_neg]
    exact wilsonPlaquette_star_mul_self U x μ ν
  have hb := traceRe_le_three (-(wilsonPlaquette U x μ ν)) hunit
  rw [Matrix.trace_neg, Complex.neg_re] at hb
  unfold plaquetteEnergy
  rw [div_le_iff (by norm_num : (0 : ℝ) < 3)]
  linarith

/-- The polymer energy is at most `2·|γ|` (a finite sum of `≤ 2` terms). -/
theorem polymerEnergy_le_two_card {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (γ : Finset (Lattice d L × Fin d × Fin d)) :
    polymerEnergy U γ ≤ 2 * γ.card := by
  unfold polymerEnergy
  calc γ.sum (fun p => plaquetteEnergy U p.1 p.2.1 p.2.2)
      ≤ γ.sum (fun _ => (2 : ℝ)) :=
        Finset.sum_le_sum (fun p _ => plaquetteEnergy_le_two U p.1 p.2.1 p.2.2)
    _ = 2 * γ.card := by rw [Finset.sum_const, nsmul_eq_mul]; ring

/-! ### The mean polymer energy and its bounds -/

/-- **Mean polymer energy** `meanEnergy L γ := ∫ polymerEnergy(toGauge w) γ
∂haarN` — the first moment of the polymer energy under the Haar configuration
measure. This is the *only* energy scale the entropy/KP heuristic uses; the
obstruction below shows it is the WRONG scale. -/
noncomputable def meanEnergy (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) : ℝ :=
  ∫ w, polymerEnergy (toGauge L w) γ ∂(haarN (4 * L ^ 4))

/-- The polymer energy `w ↦ polymerEnergy (toGauge w) γ` is `haarN`-integrable:
continuous (`continuous_polymerEnergy_toGauge`) and bounded on the compact
configuration space, hence `L¹` of the probability measure. Mirrors the
`integrable_polymerWeight` technique, without the `exp`. -/
theorem integrable_polymerEnergy (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    Integrable (fun w => polymerEnergy (toGauge L w) γ) (haarN (4 * L ^ 4)) := by
  haveI : CompactSpace (Fin (4 * L ^ 4) → SU3Instances.SU3) := Pi.compactSpace
  haveI : SecondCountableTopology (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold Matrix; infer_instance
  haveI : SecondCountableTopology (↥SU3Instances.SU3) :=
    TopologicalSpace.Subtype.secondCountableTopology
      (SU3Instances.SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
  haveI : SecondCountableTopology (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  haveI : BorelSpace (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  have hcont := continuous_polymerEnergy_toGauge L γ
  obtain ⟨C, hC⟩ := (isCompact_range (continuous_norm.comp hcont)).bddAbove
  exact (Memℒp.of_bound hcont.aestronglyMeasurable C
    (ae_of_all _ (fun w => hC (Set.mem_range_self w)))).integrable one_le_two

/-- `meanEnergy ≥ 0` (integral of the non-negative `polymerEnergy`). -/
theorem meanEnergy_nonneg (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    0 ≤ meanEnergy L γ :=
  integral_nonneg (fun w => polymerEnergy_nonneg (toGauge L w) γ)

/-- `meanEnergy L γ ≤ 2·|γ|` (`integral_mono` against the constant `2·|γ|`,
using `polymerEnergy_le_two_card` pointwise and `haarN` a probability measure). -/
theorem meanEnergy_le_two_card (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    meanEnergy L γ ≤ 2 * γ.card := by
  unfold meanEnergy
  have h : (∫ w, polymerEnergy (toGauge L w) γ ∂(haarN (4 * L ^ 4)))
      ≤ ∫ _w, (2 * (γ.card : ℝ)) ∂(haarN (4 * L ^ 4)) := by
    refine integral_mono (integrable_polymerEnergy L γ) (integrable_const _) ?_
    exact fun w => polymerEnergy_le_two_card (toGauge L w) γ
  rwa [integral_const, measure_univ, ENNReal.one_toReal, smul_eq_mul, one_mul] at h

/-! ### The mean-energy scale `e_bar` -/

/-- **Mean per-plaquette energy of the polymer** `e_bar L γ := meanEnergy/|γ|`
— the average energy *per* plaquette. The KP heuristic would set the
strong-coupling threshold at `β₀ = log 8 / e_bar`; `mean_threshold_fails` shows
that threshold is mis-calibrated. -/
noncomputable def e_bar (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) : ℝ :=
  meanEnergy L γ / γ.card

/-- `e_bar L γ ≤ 2` (proven, unconditional): from `meanEnergy ≤ 2·|γ|`. -/
theorem e_bar_le_two (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (hγ : γ.Nonempty) :
    e_bar L γ ≤ 2 := by
  unfold e_bar
  rw [div_le_iff (by exact_mod_cast Finset.card_pos.mpr hγ)]
  exact meanEnergy_le_two_card L γ

/-- `0 < e_bar L γ` **CONDITIONAL** on the named TRUE input `0 < meanEnergy L γ`
(unprovable in mathlib v4.12.0 — needs `∫ tr = 0` / Haar non-atomicity). -/
theorem e_bar_pos_of_meanEnergy_pos (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (hγ : γ.Nonempty)
    (hpos : 0 < meanEnergy L γ) : 0 < e_bar L γ := by
  unfold e_bar
  exact div_pos hpos (by exact_mod_cast Finset.card_pos.mpr hγ)

/-! ### The Jensen obstruction (the heart) -/

/-- Helper: `(1/8)^n = exp(-(log 8)·n)` (replicated from
`Wall257_StrongCoupling.inv8_pow_eq_exp_neg`). -/
theorem inv8_pow_eq_exp_neg (n : ℕ) :
    ((1 : ℝ) / 8) ^ n = Real.exp (-(Real.log 8) * (n : ℝ)) := by
  have hlog : Real.log ((1 : ℝ) / 8) = -(Real.log 8) := by
    rw [one_div, Real.log_inv]
  rw [← Real.rpow_natCast ((1 : ℝ) / 8) n,
    Real.rpow_def_of_pos (by norm_num), hlog]

/-- **`jensen_obstruction` — the heart (GENUINE, UNCONDITIONAL).** For every
`β`, the polymer activity is bounded BELOW by the Jensen exponential of the mean:
`exp(-(β · meanEnergy L γ)) ≤ polymerActivity L β γ`. Direct from
`ConvexOn.map_integral_le` for the convex `exp` against the probability measure
`haarN`. This is the wrong direction for KP smallness (a lower bound). -/
theorem jensen_obstruction (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (β : ℝ) :
    Real.exp (-(β * meanEnergy L γ)) ≤ polymerActivity L β γ := by
  have hfi : Integrable (fun w => -β * polymerEnergy (toGauge L w) γ)
      (haarN (4 * L ^ 4)) := (integrable_polymerEnergy L γ).const_mul (-β)
  have hgi : Integrable (fun w => Real.exp (-β * polymerEnergy (toGauge L w) γ))
      (haarN (4 * L ^ 4)) := integrable_polymerWeight L β γ
  have hjen := convexOn_exp.map_integral_le (μ := haarN (4 * L ^ 4))
      Real.continuous_exp.continuousOn isClosed_univ
      (ae_of_all _ (fun w => Set.mem_univ
        (-β * polymerEnergy (toGauge L w) γ))) hfi hgi
  have hmean : (∫ w, (-β * polymerEnergy (toGauge L w) γ) ∂(haarN (4 * L ^ 4)))
      = -(β * meanEnergy L γ) := by
    rw [integral_const_mul, neg_mul]; rfl
  rw [hmean] at hjen
  exact hjen

/-- **`mean_threshold_fails` — the obstruction corollary (CONDITIONAL).** At the
mean-energy strong-coupling threshold `β₀ := log 8 / e_bar L γ`, the activity is
bounded BELOW by `(1/8)^|γ|`:
  `(1/8)^|γ| ≤ polymerActivity L (log 8 / e_bar L γ) γ`.
So a per-polymer bound `polymerActivity ≤ (1/8)^|γ|` is FALSE at exactly the
mean-energy threshold — the mean cannot drive KP smallness.

CONDITIONAL on `hpos : 0 < meanEnergy L γ` (a named TRUE input; see header). -/
theorem mean_threshold_fails (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (hγ : γ.Nonempty)
    (hpos : 0 < meanEnergy L γ) :
    ((1 : ℝ) / 8) ^ γ.card ≤ polymerActivity L (Real.log 8 / e_bar L γ) γ := by
  have hm : meanEnergy L γ ≠ 0 := ne_of_gt hpos
  have hc : (γ.card : ℝ) ≠ 0 := by exact_mod_cast Finset.card_ne_zero.mpr hγ
  rw [inv8_pow_eq_exp_neg]
  refine le_trans (le_of_eq ?_) (jensen_obstruction L γ (Real.log 8 / e_bar L γ))
  congr 1
  unfold e_bar
  field_simp
  ring

end Wall255Jensen
end YM
end Towers
end TheoremaAureum
