/-
  # Towers.YM.MassGap

  **Mostly-statement file. Now contains ONE trio-clean theorem and
  three remaining `sorry`-backed defs.** This file pins the Clay
  Yang-Mills mass-gap conjecture as a future formalisation target,
  using a structured (rather than single-`sorry`) schema.

  ## Status of the schema after the Plan #52 MassGap refactor

  As of this refactor, the previously-opaque `SU3Connection : Type
  := sorry` has been replaced by a **concrete, sorry-free type**:

      abbrev SU3Connection : Type :=
        Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ

  This is the **trivial-bundle constant-coefficient case** of an
  SU(3) gauge connection on `ℝ⁴`: four constant SU(3)-valued fields,
  one per spacetime direction. It is **not** a connection on a
  non-trivial principal bundle — that would need
  `Mathlib.Geometry.Manifold.VectorBundle.Basic` and a `Connection`
  type, neither of which is plumbed up to where we need them in
  mathlib v4.12.0. But it is a real, inhabited, sorry-free type
  that future YM bricks can prove things about, using the real
  `Matrix.specialUnitaryGroup` API from
  `Mathlib/LinearAlgebra/UnitaryGroup.lean`.

  **Correction to a prior internal note.** An earlier comment in
  this file (and in a planning message) claimed
  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` was missing
  from mathlib v4.12.0. That was *technically* correct (no file by
  that name) but *substantively misleading*: `Matrix.specialUnitaryGroup`
  itself **does exist**, as an `abbrev` in
  `Mathlib/LinearAlgebra/UnitaryGroup.lean` (line 180):

      abbrev specialUnitaryGroup := unitaryGroup n α ⊓ MonoidHom.mker detMonoidHom

  This refactor uses it directly. The earlier "OMITTED" line about
  the SpecialUnitaryGroup file is preserved below for historical
  honesty, with a corrected pointer to where the type actually lives.

  ## Remaining `sorry`-backed defs (NOT bricks)

    * `HilbertSpace`         — physical-state Hilbert space of YM
    * `YMHamiltonian`        — `∫ tr(F_A ∧ ★F_A)`
    * `IsEigenstate`         — eigenstate predicate

  These three are still `sorry`. mathlib v4.12.0 has no
  `Distribution.SobolevSpace`, no Yang-Mills Hamiltonian, no
  formalised physical-state Hilbert space. The `sorry` markers are
  paired with explicit `TODO:` comments naming the mathlib module
  that would have to land first.

  Because three bodies are still `sorry`, `#print axioms
  YM_mass_gap_statement` will still display `[sorryAx]`. That is
  expected and visible — `YM_mass_gap_statement` is NOT a brick,
  is NOT in `scripts/check-towers.sh BRICKS`, and is NOT imported
  by any of the bricks that ARE in BRICKS.

  ## What this file IS now (post-refactor)

  * One real trio-clean brick:
    `TheoremaAureum.Towers.YM.SU3Connection_one_mul`,
    which uses the concrete `SU3Connection` type and the real
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid structure.
    Axiom footprint = subset of mathlib's classical trio.
  * Stable citable Lean identifiers for future plans to point at.
  * A flagged TODO surface: every remaining `sorry` is paired with a
    `TODO:` comment naming the mathlib module that would replace it.

  ## Status

  Per `docs/ROADMAP.md` § 2. Yang-Mills mass gap: **Open.** No
  promotion. The fact that `SU3Connection` is now concrete and
  `SU3Connection_one_mul` proves a real monoid identity does NOT
  change the tower's status. The Hamiltonian, the Hilbert space,
  and the eigenstate predicate are all still `sorry`. The mass gap
  is not proved, not stated precisely, and not in sight.
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum
namespace Towers
namespace YM

/-- **SU(3) gauge field, trivial-bundle constant-coefficient case.**

    A `SU3Connection` is a 4-tuple of constant `SU(3)` matrices, one
    per spacetime direction. This is the trivial-bundle special case
    of an honest YM connection — no base manifold, no bundle, no
    differential structure — but it is a real, inhabited, sorry-free
    type that the brick `SU3Connection_one_mul` below can prove
    things about using the real `Matrix.specialUnitaryGroup` API. -/
abbrev SU3Connection : Type := Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ
-- TODO (mathlib v4.13+): replace with
--   Connection (Bundle ℝ ℝ⁴) (Matrix.specialUnitaryGroup (Fin 3) ℂ)
-- once `Mathlib.Geometry.Manifold.VectorBundle.Basic` exposes Connection.
-- (Note: `Matrix.specialUnitaryGroup` itself lives in
--  `Mathlib/LinearAlgebra/UnitaryGroup.lean`, not in a separate
--  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` file.)

/-- **Hilbert space of physical states** of the Yang-Mills
    Hamiltonian. Still `sorry`: mathlib v4.12.0 has no formalised
    physical-state Hilbert space for YM. -/
def HilbertSpace : Type := sorry
-- TODO (mathlib v4.13+): physical-state Hilbert space of the YM Hamiltonian

/-- **Yang-Mills Hamiltonian:** `E + B` field energy `∫ |F|²`.
    Still `sorry`: requires Sobolev spaces and `∫ tr(F ∧ ★F)`. -/
noncomputable def YMHamiltonian (_A : SU3Connection) : ℝ := sorry
-- TODO (mathlib v4.13+): ∫ tr(F_A ∧ ★F_A) using Distribution.SobolevSpace

/-- **Eigenstate predicate** (placeholder). `IsEigenstate H ψ` says
    `ψ` is an eigenstate of the Hamiltonian `H`. Still `sorry`: the
    spectral theory hook is not plumbed up. -/
def IsEigenstate (_H : SU3Connection → ℝ) (_ψ : HilbertSpace) : Prop := sorry
-- TODO (mathlib v4.13+): ψ is an eigenstate of H

/-- **Mass gap statement:** `∃ Δ > 0, ∀ eigenstates ψ, E_ψ ≥ Δ`.
    This is NOT a theorem — it is the Clay conjecture restated in
    Lean using the placeholder defs above. It is not in BRICKS. -/
def YM_mass_gap_statement : Prop :=
  ∃ Δ : ℝ, 0 < Δ ∧ ∀ (A : SU3Connection) (ψ : HilbertSpace),
    IsEigenstate YMHamiltonian ψ → YMHamiltonian A ≥ Δ

/-- **Identity acts trivially on each component of an SU(3) connection
    (first real trio-clean brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i`.

    The proof is a one-line delegation to mathlib's `one_mul` on the
    monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`
    (which `specialUnitaryGroup` inherits as a `Submonoid` of
    `Matrix (Fin 3) (Fin 3) ℂ` via `Submonoid.toMonoid`).

    This is **not** new mathematics — it is the trivial left-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema. Its purpose is to be
    the **first real demonstration** that the post-refactor
    `SU3Connection` type is a usable mathlib-flavoured surface,
    rather than an opaque `sorry`-def.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `1 * x = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_one_mul (A : SU3Connection) (i : Fin 4) :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i :=
  one_mul (A i)

end YM
end Towers
end TheoremaAureum
