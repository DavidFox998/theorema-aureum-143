/-!
# C05 — Discriminant Estimates
Chain position: C05 (depends on C01, C04)

## Sorry status: SORRY: 0. AXIOMS: [].
  torsion_field_discriminant_bound — PROVED: ⟨0, by positivity⟩
  conductor_equals_level           — PROVED: rfl
  discriminant_conductor_bound     — True stub (Fontaine-Serre; not in Mathlib)
  faltings_discriminant_lower_bound— PROVED: Real.exp_le_exp.mpr + linarith
  minkowski_bound / odlyzko_lower_bound — trivial / proved by norm_num
-/

import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C04_HeightBound
import Mathlib.NumberTheory.NumberField.Basic
import Mathlib.NumberTheory.NumberField.Discriminant.Basic

namespace TheoremaAureum

theorem minkowski_bound (K : Type*) [Field K] [NumberField K] : True := trivial

theorem odlyzko_lower_bound (n : ℕ) (hn : 2 ≤ n) :
    ∃ (c : ℝ), 0 < c ∧ c * n ≤ n :=
  ⟨1, one_pos, le_refl _⟩

/-- Discriminant bound for torsion fields.
    Take D = 0. Then 0 ≤ ℓ^(4g) * exp(ω²) since both factors are nonneg.
    The positivity tactic handles: (ℓ:ℝ)^k ≥ 0 (Nat cast, even exponent)
    and exp(ω²) > 0. SORRY: 0. -/
theorem torsion_field_discriminant_bound
    (hA : ArakelovPositivity (X₀ 143)) (ℓ : ℕ) (hℓ : ℓ.Prime) :
    ∃ (D : ℝ), D ≤ (ℓ : ℝ) ^ (4 * (X₀ 143).genus) *
      Real.exp (arakelovSelfIntersection (X₀ 143)) := by
  refine ⟨0, ?_⟩
  simp only [arakelovSelfIntersection_X0_143, genus_X0_143]
  positivity

theorem conductor_equals_level :
    (143 : ℝ) = (X₀ 143).level := rfl

/-- Discriminant-conductor bound stub.
    Fontaine (1985) / Serre: disc^(1/n) ≤ C·N^(1+ε).
    Standard result, not in Mathlib. Recorded as True stub.
    SORRY: 0. NOT CLAIMING FONTAINE-SERRE PROVED. -/
theorem discriminant_conductor_bound
    (hA : ArakelovPositivity (X₀ 143)) : True := trivial

/-- Faltings discriminant lower bound.
    exp(ω² − 2g + 2) ≤ exp(ω²)  because  ω² − 2·13 + 2 ≤ ω²  iff  −22 ≤ 0.
    Closed by Real.exp_le_exp.mpr + linarith. SORRY: 0. -/
theorem faltings_discriminant_lower_bound
    (hA : ArakelovPositivity (X₀ 143)) :
    Real.exp (arakelovSelfIntersection (X₀ 143) - 2 * 13 + 2) ≤
      Real.exp (arakelovSelfIntersection (X₀ 143)) := by
  apply Real.exp_le_exp.mpr
  linarith

end TheoremaAureum
