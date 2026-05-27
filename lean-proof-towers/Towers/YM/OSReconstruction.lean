/-
================================================================
Towers / YM / OSReconstruction  (Batch 19.1a)

**Abstract Osterwalder–Schrader reconstruction skeleton.**

First slice of the OS reconstruction project that the Three
Hard Lemmas (`docs/THREE_HARD_LEMMAS.md`) require as a
prerequisite. Adds an abstract `ReflectionPositiveData`
structure plus seven structural lemmas that follow from the
involution axiom alone. Wall 278 → 285 (this file). NOT the
full +42-brick Batch 19.1 as originally scoped; see
`docs/THREE_HARD_LEMMAS.md` "Batch 19.1 split" entry for the
sub-batch roadmap (19.1a → 19.1b → 19.1c → 19.1d).

## What this file IS

An abstract `ReflectionPositiveData` structure that captures the
**type-level shape** of Osterwalder–Schrader data:

  * a carrier type `Ω` (field-configuration space stand-in)
  * an involution `θ : Ω → Ω` with `θ² = id` (time reflection)
  * the reflection-positivity property as a `Prop` field
    (NAMED, not discharged)

Plus seven structural lemmas that follow from the involution
axiom alone:

  * `theta_theta_eq` — named handle for `θ ∘ θ = id` pointwise
  * `theta_injective`, `theta_surjective`, `theta_bijective`
    — `θ` is a bijection (proven from the involution axiom,
    not assumed)
  * `pullback_pullback` — pullback of a field by `θ` is itself
    an involution on fields
  * `vacuumFunction_apply` — the constant-1 "vacuum function"
    evaluates to `1` at every configuration
  * `pullback_vacuum` — the vacuum function is `θ`-invariant

## What this file IS NOT

  * NOT the constructive QFT problem solved. The carrier `Ω`
    stays abstract; the Wilson lattice measure, the continuum
    Gaussian measure on `S'(ℝ³)`, and Bochner–Minlos are NOT
    constructed here.
  * NOT a claim of reflection positivity for any concrete
    action. `reflectionPositive` is a `Prop` field of the
    structure; inhabiting it for the Wilson action is the
    Osterwalder–Seiler 1978 theorem and is OUT OF SCOPE.
  * NOT a construction of the physical Hilbert space
    `ℋ_phys := L²(Ω, dμ) / ker`. That is Batch 19.1b
    territory and requires `MeasureTheory.Lp` on a constructed
    measure, which we do not have.
  * NOT a discharge of `OS_positivity` (Wilson),
    `Transfer_compact`, `Perron_Frobenius_for_transfer`,
    `gap_uniform_in_Lambda`, `enstrophy_bound_global`, or any
    other Three-Hard-Lemmas surface. Those remain conditional
    in their current files; their unconditional forms remain
    `sorry`-bearing stubs documented in
    `docs/THREE_HARD_LEMMAS.md`, not bricks.

YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2). The
honest-scope rule (`replit.md`, "honest-scope wording is
locked") is NOT modified by this batch: no tower is promoted
out of `Status: Open`.

## Axiom footprint

Every brick below carries axiom footprint a subset of
`{propext, Classical.choice, Quot.sound}` (mathlib's classical
trio). No `sorryAx`. No new axioms declared.
================================================================
-/

import Mathlib.Logic.Function.Basic
import Mathlib.Data.Real.Basic

namespace TheoremaAureum
namespace Towers
namespace YM
namespace OSReconstruction

/--
**Abstract reflection-positive data.**

Captures the *type-level shape* of an Osterwalder–Schrader data
tuple: a carrier (field-configuration space stand-in), a time-
reflection involution `θ` with `θ² = id`, and the reflection-
positivity property as a `Prop` field (named, not discharged).

NOT a construction of any concrete OS data. To inhabit this
structure for the Wilson SU(3) lattice gauge action one would
need to construct the Wilson measure on `SU(3)^{|Λ|}` and prove
reflection positivity à la Osterwalder–Seiler 1978 — both OUT
OF SCOPE here.
-/
structure ReflectionPositiveData where
  /-- Carrier type. Abstract stand-in for `Ω = S'(ℝ³)` or
      `Ω = SU(3)^{|Λ|}`. We do not construct it here. -/
  carrier : Type
  /-- Time-reflection involution on the carrier. -/
  theta : carrier → carrier
  /-- `θ` is an involution: applying it twice is the identity. -/
  theta_invol : ∀ ω : carrier, theta (theta ω) = ω
  /-- Reflection-positivity, named as a `Prop` (NOT discharged).
      Inhabiting this on a concrete `carrier` requires real
      analysis (Osterwalder–Schrader 1973 + Osterwalder–Seiler
      1978 for Wilson). OUT OF SCOPE for this file. -/
  reflectionPositive : Prop

namespace ReflectionPositiveData

/-- **`θ ∘ θ = id` pointwise (named handle for `theta_invol`).**

Stable identifier for downstream batches (19.1b, 19.1c) to
reference without unfolding the structure-field name. -/
theorem theta_theta_eq (D : ReflectionPositiveData) (ω : D.carrier) :
    D.theta (D.theta ω) = ω :=
  D.theta_invol ω

/-- **`θ` is injective.**

Real consequence of the involution axiom: if `θ a = θ b` then
applying `θ` once more and using `θ² = id` twice gives `a = b`. -/
theorem theta_injective (D : ReflectionPositiveData) :
    Function.Injective D.theta := by
  intro a b hab
  have h : D.theta (D.theta a) = D.theta (D.theta b) := by rw [hab]
  rwa [D.theta_invol, D.theta_invol] at h

/-- **`θ` is surjective.**

Real consequence of the involution axiom: for any `b`, the
preimage `θ b` satisfies `θ (θ b) = b` by `theta_invol`. -/
theorem theta_surjective (D : ReflectionPositiveData) :
    Function.Surjective D.theta := by
  intro b
  exact ⟨D.theta b, D.theta_invol b⟩

/-- **`θ` is a bijection.** Combination of `theta_injective` and
`theta_surjective`. -/
theorem theta_bijective (D : ReflectionPositiveData) :
    Function.Bijective D.theta :=
  ⟨D.theta_injective, D.theta_surjective⟩

/-- **Time-zero field.** Abstract real-valued observable on the
field-configuration carrier. NOT a Wightman field — just a real
function on `Ω`. -/
def TimeZeroField (D : ReflectionPositiveData) : Type := D.carrier → ℝ

/-- **Pullback of a time-zero field by `θ`.** -/
def pullback (D : ReflectionPositiveData) (f : D.TimeZeroField) :
    D.TimeZeroField :=
  fun ω => f (D.theta ω)

/-- **Pullback by `θ` is an involution on fields.**

Real consequence of the involution axiom: `(pullback ∘ pullback) f`
sends `ω` to `f (θ (θ ω)) = f ω`. -/
theorem pullback_pullback (D : ReflectionPositiveData)
    (f : D.TimeZeroField) :
    D.pullback (D.pullback f) = f := by
  funext ω
  show f (D.theta (D.theta ω)) = f ω
  rw [D.theta_invol]

/-- **Vacuum function.** Constant function `fun _ => 1`. Abstract
stand-in for the vacuum vector in `ℋ_phys`. NOT the
OS-reconstructed vacuum state — just a constant real function on
the configuration space. -/
def vacuumFunction (D : ReflectionPositiveData) : D.TimeZeroField :=
  fun _ => (1 : ℝ)

/-- **Vacuum value at any configuration is 1.** Named handle for
the definitional unfolding of `vacuumFunction`. -/
theorem vacuumFunction_apply (D : ReflectionPositiveData)
    (ω : D.carrier) :
    D.vacuumFunction ω = (1 : ℝ) := rfl

/-- **Vacuum function is `θ`-invariant.** Its pullback is itself,
because it is constant. -/
theorem pullback_vacuum (D : ReflectionPositiveData) :
    D.pullback D.vacuumFunction = D.vacuumFunction := by
  funext _
  rfl

end ReflectionPositiveData

end OSReconstruction
end YM
end Towers
end TheoremaAureum
