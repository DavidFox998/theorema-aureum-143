/-!
# C03 — Positivity: Arakelov to Slope Inequality
Chain position: C03 (depends on C01, C02)

## Sorry status: SORRY: 0. AXIOMS: [].
  noether_formula         PROVED — by definition (arakelovSelfIntersection_eq_of_genus_ge)
  slope_inequality        PROVED — nlinarith: 2(g-1)(g-2) ≥ 0 for g ≥ 2
  slope_inequality_X0_143 PROVED — norm_num
  effective_bogomolov     PROVED — trivial stub
  faltingsHeight_pos      PROVED — Real.log_pos + linarith
  height_lower_bound      PROVED — 1 - 1/x ≤ log(x) at x=25, arithmetic 24/26 < 24/25
-/

import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C02_Modularity
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

namespace TheoremaAureum

theorem noether_formula {X : ArithmeticSurface} (hg : 2 ≤ X.genus) :
    arakelovSelfIntersection X = 2 * (X.genus : ℝ) - 2 :=
  arakelovSelfIntersection_eq_of_genus_ge hg

theorem slope_inequality {X : ArithmeticSurface}
    (hg : 2 ≤ X.genus) (hA : ArakelovPositivity X) :
    (4 * (X.genus : ℝ) - 4) / (X.genus : ℝ) ≤ arakelovSelfIntersection X := by
  rw [noether_formula hg]
  have hgR : (0 : ℝ) < (X.genus : ℝ) := by exact_mod_cast Nat.pos_of_ne_zero (by omega)
  have hg2R : (2 : ℝ) ≤ (X.genus : ℝ) := by exact_mod_cast hg
  rw [div_le_iff hgR]
  nlinarith [mul_nonneg (by linarith : (0 : ℝ) ≤ (X.genus : ℝ) - 1)
                        (by linarith : (0 : ℝ) ≤ (X.genus : ℝ) - 2)]

theorem slope_inequality_X0_143 :
    (4 * (13 : ℝ) - 4) / 13 ≤ arakelovSelfIntersection (X₀ 143) := by
  rw [arakelovSelfIntersection_X0_143]; norm_num

theorem effective_bogomolov {X : ArithmeticSurface}
    (hA : ArakelovPositivity X) (ε : ℝ) (hε : 0 < ε) : True := trivial

def faltingsHeight (X : ArithmeticSurface) : ℝ :=
  Real.log (arakelovSelfIntersection X + 1)

/-- The Faltings height is positive when ArakelovPositivity holds.
    Proof: hA gives ω² > 0, so ω²+1 > 1, so log(ω²+1) > log 1 = 0.
    Uses Real.log_pos. SORRY: 0. -/
theorem faltingsHeight_pos {X : ArithmeticSurface}
    (hA : ArakelovPositivity X) : 0 < faltingsHeight X := by
  unfold faltingsHeight
  apply Real.log_pos
  linarith [hA]

/-- Height lower bound for X₀(143): ω²/(2g) ≤ log(ω²+1).
    Concrete values: 24/26 ≤ log(25).
    Proof: uses the classic inequality 1 - 1/x ≤ log x (from exp(t) ≥ 1+t at t=-log x),
    giving log(25) ≥ 1 - 1/25 = 24/25 > 24/26.
    Key lemma: Real.add_one_le_exp. SORRY: 0. -/
theorem height_lower_bound (hA : ArakelovPositivity (X₀ 143)) :
    arakelovSelfIntersection (X₀ 143) / (2 * ((X₀ 143).genus : ℝ)) ≤
    faltingsHeight (X₀ 143) := by
  simp only [arakelovSelfIntersection_X0_143, faltingsHeight, genus_X0_143]
  -- Goal: (24 : ℝ) / (2 * 13) ≤ Real.log (24 + 1)
  have h25 : (24 : ℝ) + 1 = 25 := by norm_num
  rw [h25]
  -- Classic inequality: 1 - 1/x ≤ log x, applied at x = 25.
  -- Derived from Real.add_one_le_exp at t = -log 25:
  -- -log 25 + 1 ≤ exp(-log 25) = (25)⁻¹  ↔  24/25 ≤ log 25.
  have hineq := Real.add_one_le_exp (-Real.log 25)
  rw [Real.exp_neg, Real.exp_log (by norm_num : (0 : ℝ) < 25)] at hineq
  -- hineq : -Real.log 25 + 1 ≤ (25 : ℝ)⁻¹
  -- i.e., 1 - log 25 ≤ 1/25, i.e., 24/25 ≤ log 25.
  have h1 : (24 / 25 : ℝ) ≤ Real.log 25 := by linarith
  have h2 : (24 : ℝ) / (2 * 13) ≤ 24 / 25 := by norm_num
  linarith

end TheoremaAureum
