import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.DirichletCharacter.Basic
import Mathlib.Analysis.Complex.Basic

namespace TheoremaAureum

open Complex

/-- The Riemann Hypothesis -/
def RiemannHypothesis : Prop := 
  ∀ ρ : ℂ, riemannZeta ρ = 0 ∧ ρ ≠ 1 ∧ 0 < ρ.re ∧ ρ.re < 1 → ρ.re = 1/2

/-- Hasse-Weil L-function of E: y² = x³ - x + 1, conductor 143.
Mathlib doesn't have this curve yet, so we axiom the function and GRH. -/
axiom E_143a1_LFunction : ℂ → ℂ
axiom GRH_E_143a1 : Prop := 
  ∀ ρ : ℂ, E_143a1_LFunction ρ = 0 ∧ 0 < ρ.re ∧ ρ.re < 1 → ρ.re = 1/2

end TheoremaAureum
