/-
  # Towers.YM.MassGap

  **Mostly-statement file. Currently contains SEVEN trio-clean
  theorems and two remaining `sorry`-backed schema defs**
  (`YMHamiltonian`, `IsEigenstate`). `HilbertSpace` was upgraded
  to the canonical separable infinite-dim ℓ²(ℕ,ℂ) via Branch A
  of Task #55 (2026-05-26) — see the "Task #55 decision" block
  near line ~117 for the full honest-scoping argument. This file
  pins the Clay Yang-Mills mass-gap conjecture as a future
  formalisation target, using a structured (rather than
  single-`sorry`) schema.

  The seven trio-clean SU(3) bricks proved below are:
  `SU3Connection_one_mul`, `SU3Connection_component_unitary`,
  `SU3Connection_component_det_one`, `SU3Connection_mul_one`,
  `SU3Connection_one_one`, `SU3Connection_component_mul_unitary`,
  `SU3Connection_component_mul_det_one`. Each is real SU(3)
  monoid / submonoid algebra (no `TrivialConfiguration` shortcut)
  with axiom footprint a subset of `{propext, Classical.choice,
  Quot.sound}`. None of them advances the YM tower past
  `Status: Open` (see `docs/ROADMAP.md` § 2); they are foundation
  bricks under the schema, not Millennium claims.

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

    * `YMHamiltonian`        — `∫ tr(F_A ∧ ★F_A)`
    * `IsEigenstate`         — eigenstate predicate

  `HilbertSpace` is no longer `sorry` — it is now `lp (fun _ : ℕ
  => ℂ) 2`, the canonical separable infinite-dim complex Hilbert
  space (ℓ²(ℕ,ℂ)). See the "Task #55 decision" block below for
  the explicit caveat: this is a placeholder Hilbert space, not
  the YM physical state space.

  The remaining two are still `sorry`. mathlib v4.12.0 has no
  `Distribution.SobolevSpace` and no Yang-Mills Hamiltonian, so
  the `sorry` markers are paired with explicit `TODO:` comments
  naming the mathlib module that would have to land first.

  Because two bodies are still `sorry`, `#print axioms
  YM_mass_gap_statement` will still display `[sorryAx]`. That is
  expected and visible — `YM_mass_gap_statement` is NOT a brick,
  is NOT in `scripts/check-towers.sh BRICKS`, and is NOT imported
  by any of the bricks that ARE in BRICKS.

  ## What this file IS now (post-refactor)

  * Seven real trio-clean SU(3) bricks (listed above) using the
    concrete `SU3Connection` type and the real
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid structure.
    Axiom footprint of each = subset of mathlib's classical trio.
  * Stable citable Lean identifiers for future plans to point at.
  * A flagged TODO surface: every remaining `sorry` is paired with a
    `TODO:` comment naming the mathlib module that would replace it.

  ## Status

  Per `docs/ROADMAP.md` § 2. Yang-Mills mass gap: **Open.** No
  promotion. The fact that `SU3Connection` is now concrete,
  `HilbertSpace` is now `ℓ²(ℕ,ℂ)`, and `SU3Connection_one_mul`
  proves a real monoid identity does NOT change the tower's
  status. The Hamiltonian and the eigenstate predicate are still
  `sorry`, and even with the two remaining sorries replaced, the
  resulting `YM_mass_gap_statement` would still be a statement
  about ℓ²(ℕ,ℂ) — NOT the real YM Hilbert space, which requires an
  Osterwalder–Schrader reconstruction not present in mathlib
  v4.12.0. The mass gap is not proved, not stated precisely as
  Yang-Mills physics, and not in sight.
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.InnerProductSpace.l2Space

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

/-
  **Task #55 decision (2026-05-26) — supersedes Task #51 audit for
  `HilbertSpace` only.** Branch A (the `lp`/ℓ² route) was chosen
  and landed below. `YMHamiltonian` and `IsEigenstate` remain
  `sorry` and remain governed by the Task #51 audit (see TODO
  blocks below). Branches B (symmetric Fock space) and C
  (su(3)-valued L²) are real follow-up work — not feasible in
  the same turn as Branch A because (B) mathlib v4.12.0 has no
  `SymmetricFockSpace` / no Hilbert-completion of a tensor
  algebra / no second-quantization machinery; (C) requires first
  defining `𝔰𝔲(3)` as a subtype with `InnerProductSpace ℝ`
  instances and lifting to `Lp` — bigger than this turn's
  budget. Both should be tracked as follow-up tasks.

  **Honest-scoping rule that survives the upgrade.** The chosen
  `HilbertSpace` below (`ℓ²(ℕ, ℂ)`) is THE canonical separable
  infinite-dimensional complex Hilbert space, but it is NOT the
  Yang-Mills physical Hilbert space. The actual YM Hilbert space
  is built by an Osterwalder–Schrader reconstruction from a
  constructed Euclidean YM measure that does not exist in
  mathlib v4.12.0 (and is itself an open research problem for
  4D pure YM). The `YM_mass_gap_statement` def below now
  type-checks against ℓ²(ℕ,ℂ), but THAT TYPE-CHECKING IS NOT A
  FORMALIZATION OF THE CLAY CONJECTURE. The statement, expanded
  modulo the two remaining `sorry`s, is a Prop about ℓ²(ℕ,ℂ)
  and two sorried operators — vacuous as Yang-Mills physics.
  Tower status: **Open** (see `docs/ROADMAP.md` § 2). Promoting
  past `Open` requires the real YM Hilbert space and Hamiltonian,
  neither of which is plumbed up.
-/

/-- **Hilbert space placeholder for the schema.**

    Defined as `lp (fun _ : ℕ => ℂ) 2`, the canonical separable
    infinite-dimensional complex Hilbert space (ℓ²(ℕ, ℂ)) —
    `NormedAddCommGroup`, `InnerProductSpace ℂ`, and `CompleteSpace`
    all come from mathlib's `Mathlib.Analysis.InnerProductSpace.l2Space`.

    **This is NOT the Yang-Mills physical state space.** It is a
    real, infinite-dimensional, mathlib-backed Hilbert space chosen
    so the schema below (`YM_mass_gap_statement`) typechecks against
    something real instead of a `sorry`. The actual YM Hilbert space
    requires an Osterwalder–Schrader reconstruction from a
    constructed 4D Euclidean YM measure, which is not in mathlib
    v4.12.0 and is itself an open research problem. See the
    "Task #55 decision" block immediately above for the full
    honest-scoping argument. -/
abbrev HilbertSpace : Type := lp (fun _ : ℕ => ℂ) 2
-- TODO (mathlib v4.13+ / OS-reconstruction): replace with the actual
-- physical-state Hilbert space of the YM Hamiltonian.

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

/-- **Each component of an SU(3) connection is unitary
    (second real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i`
    satisfies the unitarity equation

      `(A i).1 * star ((A i).1) = 1`

    where `.1` extracts the underlying `Matrix (Fin 3) (Fin 3) ℂ`
    from the `specialUnitaryGroup` subtype.

    The proof unfolds membership through mathlib's
    `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    to extract the unitarity component, then unfolds that through
    `Matrix.mem_unitaryGroup_iff`
    (`A ∈ unitaryGroup n α ↔ A * star A = 1`).

    Unlike `SU3Connection_one_mul` (which only used the abstract
    monoid identity), this brick is **substantive**: it proves the
    defining property of the unitary subgroup — `M M* = I` — using
    the real mathlib `Matrix.unitaryGroup` API, instantiated at the
    SU(3) connection components of our trivial-bundle schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema is in fact unitary — which it is by typing. No claim
    about the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. The Hamiltonian and eigenstate predicate are still
    `sorry` in this file; `HilbertSpace` was upgraded to
    `ℓ²(ℕ,ℂ)` by Task #55 but that is NOT the YM physical
    Hilbert space (see the "Task #55 decision" block). -/
theorem SU3Connection_component_unitary (A : SU3Connection) (i : Fin 4) :
    (A i).1 * star (A i).1 = 1 := by
  have h := Matrix.mem_specialUnitaryGroup_iff.mp (A i).2
  exact Matrix.mem_unitaryGroup_iff.mp h.1

/-- **Each component of an SU(3) connection has determinant 1
    (third real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i` has
    determinant `1`:

      `(A i).1.det = 1`.

    This is the *special* in **S**U(3) — the determinant-one
    constraint that distinguishes the special unitary group from
    the full unitary group. The proof unfolds membership through
    mathlib's `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    and projects out the determinant component.

    Together with `SU3Connection_component_unitary` (just above),
    this completes the pair of defining properties of the SU(3)
    subgroup acting on each component of our trivial-bundle
    connection schema: each component matrix is *unitary* AND has
    *determinant one*. These two bricks are the most informative
    use so far of the post-refactor `MassGap.lean` surface —
    actually proving things about the SU(3) structure, not just
    abstract monoid identities.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema has det 1 — which it does by typing. No claim about the
    YM Hamiltonian, mass gap, eigenstates, or any QFT statement. -/
theorem SU3Connection_component_det_one (A : SU3Connection) (i : Fin 4) :
    (A i).1.det = 1 :=
  (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).2

/-- **Right-identity for SU(3) connection components
    (fourth brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i`.

    The proof is a one-line delegation to mathlib's `mul_one` on
    the monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`.
    This is the right-identity companion to `SU3Connection_one_mul`
    (left-identity); together they say the SU(3) monoid identity
    fixes every component on both sides.

    This is **not** new mathematics — it is the trivial right-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `x * 1 = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_mul_one (A : SU3Connection) (i : Fin 4) :
    A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i :=
  mul_one (A i)

/-- **The SU(3) monoid identity squares to itself
    (fifth brick in `MassGap.lean`).**

    `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1`.

    A one-line `mul_one 1` on the SU(3) submonoid. Trivial as
    monoid arithmetic, but the *type* is real SU(3) — not a stub,
    not a placeholder. The lemma exists to give downstream proofs
    a stable rewrite for `1 * 1` simplifications on SU(3) elements.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that `1 * 1 = 1` in the SU(3) submonoid. No claim about
    the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. -/
theorem SU3Connection_one_one :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1 :=
  mul_one 1

/-- **Product of two SU(3)-connection components is unitary
    (sixth brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `(A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ`.

    The proof invokes `Submonoid.mul_mem` on the unitary submonoid:
    if `A i` is unitary and `B i` is unitary, their matrix product
    is unitary. The unitarity of each factor is `component_unitary`
    extracted via `Matrix.mem_specialUnitaryGroup_iff.mp _ |>.1`.

    Genuine algebraic content: it exercises submonoid closure of
    `Matrix.unitaryGroup` under multiplication, a real mathlib
    structure result, not just a definitional unfolding.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that U(3) is closed under matrix multiplication — true by
    definition of the unitary group. No claim about Yang-Mills
    dynamics, mass gap, or any QFT result. -/
theorem SU3Connection_component_mul_unitary
    (A B : SU3Connection) (i : Fin 4) :
    (A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ :=
  (Matrix.unitaryGroup (Fin 3) ℂ).mul_mem
    (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).1
    (Matrix.mem_specialUnitaryGroup_iff.mp (B i).2).1

/-- **Product of two SU(3)-connection components still has determinant 1
    (seventh brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `((A i).1 * (B i).1).det = 1`.

    The proof uses `Matrix.det_mul` (the genuine multiplicative
    property of the determinant — a real mathlib theorem, not a
    definitional unfolding) together with `component_det_one` on
    each factor; `mul_one` finishes.

    Genuine algebraic content: it exercises `Matrix.det_mul`,
    which is the key fact that `det : Matrix n n R → R` is a
    monoid homomorphism. This is the closure-under-multiplication
    proof for the determinant-1 hyperplane, the SL-side of the
    SU(3) algebraic structure (companion to
    `SU3Connection_component_mul_unitary`, the U-side).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that SL(3) ⊃ SU(3) is closed under matrix multiplication
    — true by multiplicativity of the determinant. No claim about
    the Yang-Mills mass gap, dynamics, or any QFT result. -/
theorem SU3Connection_component_mul_det_one
    (A B : SU3Connection) (i : Fin 4) :
    ((A i).1 * (B i).1).det = 1 := by
  rw [Matrix.det_mul, SU3Connection_component_det_one,
      SU3Connection_component_det_one, mul_one]

end YM
end Towers
end TheoremaAureum
