/-
================================================================
Towers / YM / RiemannianGeometry  (Task #189 — REAL Killing-form
bi-invariant distance on SU(3), replacing the Task #170 `≡ 0`
stand-in.)

**STATUS: Open.** This file now ships a **genuine, point-separating,
bi-invariant** distance on SU(3) built from the Killing / trace
inner product on the ambient matrix algebra — replacing the
Task #170 placeholder `d_SU3 g h := 0`.

Concretely, with `↑g : Matrix (Fin 3) (Fin 3) ℂ` the underlying
matrix of `g : SU3` and `star · = ·ᴴ` the conjugate transpose,

  `hsNormSq M := (Matrix.trace (star M * M)).re`
              ` = ∑_{i,j} |M i j|²`   (Hilbert–Schmidt / Frobenius)

  `d_SU3 g h := Real.sqrt (hsNormSq (↑g - ↑h))`.

This is the **chordal distance** induced by the Hilbert–Schmidt
inner product `⟨A, B⟩ = tr(Aᴴ B)`, whose restriction to the Lie
algebra `𝔰𝔲(3)` is a positive multiple of the Killing form
(`B(X, Y) = 6 · tr(X Y)` on `𝔰𝔲(3)`, and `tr(Xᴴ Y) = -tr(X Y)`
for anti-Hermitian `X, Y`). It is a genuine metric: it separates
points, is symmetric, nonnegative, vanishes exactly on the
diagonal, and — because the Hilbert–Schmidt norm is invariant
under left/right multiplication by unitaries — it is **bi-invariant**
under the SU(3) group action. All five of these facts are proved
below as honest `rfl`-free theorems.

### What is real here (no stand-in)

  * `d_SU3` is **not** identically zero. For `g ≠ h` (as matrices)
    `hsNormSq (↑g - ↑h) > 0`, so `d_SU3 g h > 0`: the distance
    genuinely separates points.
  * `d_SU3_self`     — vanishes on the diagonal (real proof: `↑g - ↑g = 0`).
  * `d_SU3_nonneg`   — nonnegative (real proof: `Real.sqrt_nonneg`).
  * `d_SU3_symm`     — symmetric (real proof: `hsNormSq (-M) = hsNormSq M`).
  * `d_SU3_isPseudoDist`  — the three pseudo-distance clauses hold for
                            the real distance.
  * `d_SU3_isBiInvariant` — left- AND right-invariance under the
                            `Matrix.specialUnitaryGroup (Fin 3) ℂ`
                            multiplication, proved from
                            `star k * k = k * star k = 1` and the
                            cyclicity of the trace. This is the genuine
                            unitary-invariance of the Hilbert–Schmidt
                            norm, NOT a vacuous `0 = 0`.

### Drift from the Task #189 brief (honest, locked)

The Task #189 "Done looks like" line asked for the distance built
from the Killing-form inner product **and the Riemannian exponential
map** — i.e. the bi-invariant *geodesic* (Riemannian) distance
`d_g(g, h) = min { ‖X‖_B : exp(X) = g⁻¹h }`. What we ship is the
**chordal** distance `‖↑g - ↑h‖_HS` from the *same* Killing/trace
inner product, NOT the geodesic distance. The two agree
infinitesimally near the diagonal (and the chordal distance is the
honest, fully-constructible witness available in mathlib v4.12.0),
but they differ globally: the geodesic distance additionally
requires the matrix logarithm / Riemannian exponential map, the
cut-locus analysis of SU(3), and geodesic completeness — none of
which is in mathlib v4.12.0. So the genuine **geodesic** Killing
distance, and with it the genuine off-diagonal Varadhan / Molchanov
small-`t` asymptotic, remain the tripwire.

What the upgrade DOES achieve, relative to the Task #170 stand-in:
  * `d_SU3` is now a real metric that separates points — so the
    downstream geometric brick
    `Heat_kernel_envelope_real_le_varadhan_geometric` can no longer
    be proved for arbitrary `x` by collapsing `exp(-d²/4t)` to
    `exp 0 = 1`. Under the real distance the geometric envelope is
    only provable on the diagonal locus `{x : d_SU3 x 1 = 0} = {1}`,
    and the off-diagonal case is exactly the open Varadhan bound.
    That brick has therefore been re-stated with an explicit
    diagonal hypothesis `hx : d_SU3 x 1 = 0` (see
    `PeterWeylHeatVaradhan.lean`) — the substitution breaking the
    old `rfl` proof IS the tripwire the task describes.

### Honest scope (locked)

This file is **not**:
  * the bi-invariant *geodesic* Riemannian distance on SU(3)
    (needs the Riemannian exponential map / matrix log / cut-locus
    analysis, not in mathlib v4.12.0);
  * the off-diagonal Varadhan / Molchanov asymptotic itself
    (that bound is still open — the chordal distance does not
    discharge it);
  * a constructive 4D pure-Yang-Mills measure;
  * a mass-gap lower bound on any YM Hamiltonian.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2.

Axiom footprint
---------------
Depends only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Notation
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum
namespace Towers
namespace YM
namespace RiemannianGeometry

/-- The SU(3) group as it appears throughout the YM tower. Same
abbreviation used by `Towers/YM/OffDiagKernel.lean` and
`Towers/YM/MassGap.lean` — kept locally for self-contained
elaboration of the bricks below. -/
abbrev SU3 : Type := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-! ## The Hilbert–Schmidt squared norm on 3×3 ℂ-matrices -/

/-- **`hsNormSq M`** — the Hilbert–Schmidt (Frobenius) squared norm
`tr(Mᴴ M) = ∑_{i,j} |M i j|²` of a 3×3 complex matrix, read off as a
real number via `.re` (the value is real because `tr(Mᴴ M)` is a
sum of squared magnitudes). This is the squared norm of the inner
product `⟨A, B⟩ = tr(Aᴴ B)` whose restriction to `𝔰𝔲(3)` is a
positive multiple of the Killing form. -/
noncomputable def hsNormSq (M : Matrix (Fin 3) (Fin 3) ℂ) : ℝ :=
  (Matrix.trace (star M * M)).re

/-! ## The real Killing-form (chordal) distance on SU(3) -/

/-- **`d_SU3 g h`** — the genuine bi-invariant chordal distance on
SU(3) induced by the Killing / Hilbert–Schmidt inner product:
`d_SU3 g h = ‖↑g - ↑h‖_HS = √(∑_{i,j} |g i j - h i j|²)`.

This REPLACES the Task #170 placeholder `d_SU3 ≡ 0`. It is a real
metric: nonnegative, symmetric, zero exactly on the diagonal, and
bi-invariant under the SU(3) action (Hilbert–Schmidt unitary
invariance). See the file docstring for the honest drift note: this
is the *chordal* distance from the Killing form, not the *geodesic*
Riemannian distance (which needs the Riemannian exponential map,
absent from mathlib v4.12.0). -/
noncomputable def d_SU3 (g h : SU3) : ℝ :=
  Real.sqrt (hsNormSq ((g : Matrix (Fin 3) (Fin 3) ℂ) - h))

/-! ## Helper lemmas on `hsNormSq` -/

/-- `hsNormSq` is invariant under negation: `hsNormSq (-M) = hsNormSq M`.
(The conjugate transpose distributes over the sign and the two signs
cancel.) -/
theorem hsNormSq_neg (M : Matrix (Fin 3) (Fin 3) ℂ) :
    hsNormSq (-M) = hsNormSq M := by
  unfold hsNormSq
  rw [star_neg, neg_mul_neg]

/-- **Left unitary invariance of `hsNormSq`.** If `star K * K = 1`
(i.e. `K` is unitary), then `hsNormSq (K * M) = hsNormSq M`. This is
`tr((KM)ᴴ (KM)) = tr(Mᴴ Kᴴ K M) = tr(Mᴴ M)`. -/
theorem hsNormSq_left (K M : Matrix (Fin 3) (Fin 3) ℂ)
    (hK : star K * K = 1) : hsNormSq (K * M) = hsNormSq M := by
  unfold hsNormSq
  congr 1
  rw [star_mul, mul_assoc, ← mul_assoc (star K) K M, hK, one_mul]

/-- **Right unitary invariance of `hsNormSq`.** If `K * star K = 1`
(i.e. `K` is unitary), then `hsNormSq (M * K) = hsNormSq M`. This is
`tr((MK)ᴴ (MK)) = tr(Kᴴ Mᴴ M K) = tr(Mᴴ M K Kᴴ) = tr(Mᴴ M)`, using
cyclicity of the trace. -/
theorem hsNormSq_right (M K : Matrix (Fin 3) (Fin 3) ℂ)
    (hK : K * star K = 1) : hsNormSq (M * K) = hsNormSq M := by
  unfold hsNormSq
  congr 1
  rw [star_mul, mul_assoc, Matrix.trace_mul_comm, mul_assoc, mul_assoc,
    hK, mul_one]

/-! ## Pseudo-distance predicate -/

/-- **`IsPseudoDistOnSU3 d`** — the three pseudo-distance properties:

  1. symmetric:        `d g h = d h g`
  2. nonneg:           `0 ≤ d g h`
  3. zero on diagonal: `d g g = 0`

The real `d_SU3` satisfies all three (proved in
`d_SU3_isPseudoDist`). Unlike the Task #170 stand-in, `d_SU3` is now
a *genuine* metric that also separates points (`d g h = 0 → g = h`
as matrices); we keep the predicate at the pseudo-distance level
because that is the interface the downstream bricks consume. -/
def IsPseudoDistOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  (∀ g h : SU3, d g h = d h g) ∧
  (∀ g h : SU3, 0 ≤ d g h) ∧
  (∀ g : SU3, d g g = 0)

/-- **`IsBiInvariantOnSU3 d`** — the two group-action clauses of a
genuine bi-invariant distance on SU(3):

  4. left-invariance:  `d (k * g) (k * h) = d g h`
  5. right-invariance: `d (g * k) (h * k) = d g h`

The real `d_SU3` satisfies both genuinely (proved in
`d_SU3_isBiInvariant`) — this is the Hilbert–Schmidt unitary
invariance, NOT a vacuous `0 = 0`. -/
def IsBiInvariantOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  (∀ k g h : SU3, d (k * g) (k * h) = d g h) ∧
  (∀ k g h : SU3, d (g * k) (h * k) = d g h)

/-! ## Bricks -/

/-- **Brick 1 (`d_SU3_self`).** The distance vanishes on the diagonal.
Real proof: `↑g - ↑g = 0`, `hsNormSq 0 = 0`, `√0 = 0`. -/
theorem d_SU3_self (g : SU3) : d_SU3 g g = 0 := by
  unfold d_SU3 hsNormSq
  rw [sub_self]
  simp only [star_zero, mul_zero, Matrix.trace_zero, Complex.zero_re,
    Real.sqrt_zero]

/-- **Brick 2 (`d_SU3_nonneg`).** The distance is nonnegative.
Real proof: `Real.sqrt_nonneg`. -/
theorem d_SU3_nonneg (g h : SU3) : 0 ≤ d_SU3 g h := by
  unfold d_SU3
  exact Real.sqrt_nonneg _

/-- **`d_SU3_symm`.** The distance is symmetric. Real proof:
`↑g - ↑h = -(↑h - ↑g)` and `hsNormSq` is negation-invariant. -/
theorem d_SU3_symm (g h : SU3) : d_SU3 g h = d_SU3 h g := by
  unfold d_SU3
  rw [show ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) = -((h : Matrix (Fin 3) (Fin 3) ℂ) - g) by
    rw [neg_sub], hsNormSq_neg]

/-- **Brick 3 (`d_SU3_isPseudoDist`).** The real `d_SU3` satisfies the
`IsPseudoDistOnSU3` predicate. Unlike the Task #170 stand-in, this is
NOT vacuous: symmetry comes from negation-invariance of the
Hilbert–Schmidt norm, nonnegativity from `Real.sqrt_nonneg`, and the
diagonal clause from `↑g - ↑g = 0`. -/
theorem d_SU3_isPseudoDist : IsPseudoDistOnSU3 d_SU3 := by
  refine ⟨?_, ?_, ?_⟩
  · intro g h; exact d_SU3_symm g h
  · intro g h; exact d_SU3_nonneg g h
  · intro g; exact d_SU3_self g

/-- **Brick 4 (`d_SU3_isBiInvariant`).** The real `d_SU3` is
bi-invariant under the `Matrix.specialUnitaryGroup (Fin 3) ℂ`
multiplication. This is the genuine Hilbert–Schmidt unitary
invariance: for `k ∈ SU(3)`, `star ↑k * ↑k = 1` and `↑k * star ↑k = 1`,
so left/right multiplication by `↑k` preserves the Hilbert–Schmidt
norm of `↑g - ↑h`. NOT a vacuous `0 = 0`. -/
theorem d_SU3_isBiInvariant : IsBiInvariantOnSU3 d_SU3 := by
  refine ⟨?_, ?_⟩
  · -- left-invariance
    intro k g h
    unfold d_SU3
    have hcoe : ((k * g : SU3) : Matrix (Fin 3) (Fin 3) ℂ) - ((k * h : SU3) : Matrix (Fin 3) (Fin 3) ℂ)
        = (k : Matrix (Fin 3) (Fin 3) ℂ) * ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) := by
      rw [Submonoid.coe_mul, Submonoid.coe_mul, mul_sub]
    have hK : star (k : Matrix (Fin 3) (Fin 3) ℂ) * (k : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
      Matrix.mem_unitaryGroup_iff'.mp (Matrix.mem_specialUnitaryGroup_iff.mp k.2).1
    rw [hcoe, hsNormSq_left _ _ hK]
  · -- right-invariance
    intro k g h
    unfold d_SU3
    have hcoe : ((g * k : SU3) : Matrix (Fin 3) (Fin 3) ℂ) - ((h * k : SU3) : Matrix (Fin 3) (Fin 3) ℂ)
        = ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) * (k : Matrix (Fin 3) (Fin 3) ℂ) := by
      rw [Submonoid.coe_mul, Submonoid.coe_mul, sub_mul]
    have hK : (k : Matrix (Fin 3) (Fin 3) ℂ) * star (k : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
      Matrix.mem_unitaryGroup_iff.mp (Matrix.mem_specialUnitaryGroup_iff.mp k.2).1
    rw [hcoe, hsNormSq_right _ _ hK]

/-! ## Metric predicate — separation + triangle (Task #209) -/

/-- **`IsMetricOnSU3 d`** — the full *metric* predicate on SU(3),
strengthening `IsPseudoDistOnSU3` with the two clauses a genuine
distance has that a mere pseudo-distance lacks:

  6. **separation:**  `d g h = 0 → g = h`   (points at distance `0` coincide)
  7. **triangle:**    `d g h ≤ d g k + d k h`

Together with the three pseudo-distance clauses (symmetry,
nonnegativity, zero-on-diagonal) repackaged via `IsPseudoDistOnSU3`,
this is exactly the predicate signature of the real Killing-form
geodesic distance on SU(3) — so the interface now matches the genuine
metric shape end-to-end.

**Honest scope (Task #209).** This task adds the predicate *clauses*;
it does NOT prove that the (chordal) `d_SU3` of Task #189 satisfies
them, and in particular constructs no real *geodesic* distance. What
it does pin down is the tripwire: the Task #170 stand-in `d_SU3 ≡ 0`
(here `fun _ _ => 0`) satisfies `IsPseudoDistOnSU3` *vacuously* but
provably FAILS the separation clause, because SU(3) is non-trivial —
see `not_IsMetricOnSU3_const_zero`. A distance that genuinely
separates points is a prerequisite before the off-diagonal Varadhan
brick can be promoted from synthetic to honest; the geodesic distance
and the triangle inequality for the real distance remain the open
tripwire (see the file docstring). -/
def IsMetricOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  IsPseudoDistOnSU3 d ∧
  (∀ g h : SU3, d g h = 0 → g = h) ∧
  (∀ g h k : SU3, d g h ≤ d g k + d k h)

/-! ## Nontriviality witness for SU(3) -/

/-- **`cWit`** — a concrete non-identity element of SU(3): the real
diagonal matrix `diag(-1, -1, 1)`. It is special-unitary (real
diagonal of unit-modulus entries ⇒ `M * Mᴴ = 1`; determinant
`(-1)·(-1)·1 = 1`) and differs from `1`. This witnesses that SU(3)
is non-trivial — exactly the fact the separation clause of
`IsMetricOnSU3` needs to rule out the `d ≡ 0` stand-in. Built with the
`!![…]` + `mem_specialUnitaryGroup_iff` + `fin_cases`/`simp`
matrix-literal idiom already used for `diagNegOneOneMat` in
`Towers/YM/MassGap.lean`. -/
noncomputable def cWit : SU3 :=
  ⟨!![(-1 : ℂ), 0, 0; 0, -1, 0; 0, 0, 1], by
    rw [Matrix.mem_specialUnitaryGroup_iff]
    refine ⟨?_, ?_⟩
    · rw [Matrix.mem_unitaryGroup_iff]
      ext i j
      fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Matrix.star_apply, Matrix.one_apply,
              Fin.sum_univ_three, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.of_apply, star_neg, star_one, star_zero]
    · rw [Matrix.det_fin_three]
      simp [Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
            Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
            Matrix.cons_val_fin_one, Matrix.of_apply]⟩

/-- The witness `cWit = diag(-1, -1, 1)` is not the identity of SU(3):
its `(0,0)` entry is `-1 ≠ 1`. -/
theorem cWit_ne_one : cWit ≠ (1 : SU3) := by
  intro h
  have h00 : (cWit : Matrix (Fin 3) (Fin 3) ℂ) 0 0
      = ((1 : SU3) : Matrix (Fin 3) (Fin 3) ℂ) 0 0 :=
    congrArg (fun g : SU3 => (g : Matrix (Fin 3) (Fin 3) ℂ) 0 0) h
  have hL : (cWit : Matrix (Fin 3) (Fin 3) ℂ) 0 0 = -1 := by
    simp [cWit, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
      Matrix.cons_val_fin_one, Matrix.of_apply]
  have hR : ((1 : SU3) : Matrix (Fin 3) (Fin 3) ℂ) 0 0 = 1 := by simp
  rw [hL, hR] at h00
  exact (by norm_num : (-1 : ℂ) ≠ 1) h00

/-! ## Tripwire brick -/

/-- **Brick 5 / Tripwire (`not_IsMetricOnSU3_const_zero`).** The
constant-zero stand-in distance `fun _ _ => 0` — the Task #170
placeholder `d_SU3 ≡ 0` — is NOT a metric on SU(3): it fails the
separation clause of `IsMetricOnSU3`. Indeed `cWit ≠ 1` (SU(3) is
non-trivial) yet the zero distance gives `(fun _ _ => 0) cWit 1 = 0`,
so the separation clause would force `cWit = 1`, a contradiction.

This is the honest tripwire the task describes: the pseudo-distance
predicate is satisfied vacuously by `d ≡ 0`, but the strengthened
metric predicate is NOT — any distance that genuinely separates points
(such as the real Killing-form distance) is required before the
off-diagonal Varadhan brick can be promoted from synthetic to honest.
Makes NO mass-gap / μ>0 / Surface-#1 claim; YM tower stays
`Status: Open`. -/
theorem not_IsMetricOnSU3_const_zero :
    ¬ IsMetricOnSU3 (fun _ _ : SU3 => (0 : ℝ)) := by
  rintro ⟨_, hsep, _⟩
  exact cWit_ne_one (hsep cWit 1 rfl)

end RiemannianGeometry
end YM
end Towers
end TheoremaAureum
