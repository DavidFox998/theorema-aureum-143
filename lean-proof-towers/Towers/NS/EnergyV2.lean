/-
================================================================
Towers / NS / EnergyV2  (Batch 8 Track 2)

**Unblocking the real `E(t) ≤ E(0)` energy inequality.**

Five bricks named exactly per the Batch 8 directive, plus one
tripwire theorem (active per directive but NOT registered in
`scripts/check-towers.sh` — its compilation alone enforces the
tripwire because flipping `Dissipation` to a non-zero body breaks
the `add_zero` step inside the proof):

  1. `H1Norm_v2` — placeholder upgrade target for the Task #51
     `H1Norm`. Currently defined as the literal alias
     `H1Norm_v2 u t := H1Norm u t`, with a TODO naming the
     intended `L²` replacement.
  2. `Dissipation` — explicit zero placeholder for the
     gradient-energy term `‖∇u(t)‖_{L²}²`. Honest stand-in until
     `fderiv ℝ (u t)` plus an `MemLp 2` packaging lands.
  3. `Dissipation_nonneg` — `0 ≤ Dissipation u t`. Currently
     trivial (RHS = 0); the statement honestly anticipates the
     `sq_nonneg`-shaped proof a real `‖∇u‖_{L²}²` upgrade will
     need.
  4. `ViscosityScaling` — `ν * Dissipation u t`. Names the coupling
     constant `ν` and reserves the slot for the real viscosity
     scaling in front of the dissipation term.
  5. `EnergyDissipationIntegral` — `ν * t * Dissipation u 0`, the
     rectangle-rule stand-in for `ν * ∫₀ᵗ ‖∇u(s)‖_{L²}² ds`.
     Avoids importing `MeasureTheory.Integral.IntervalIntegral`
     while preserving the linear-in-`t` shape downstream
     `LerayEnergyIneq` arguments need.

Plus supporting:

  * `LerayEnergyIneq ν u u₀ : Prop` — the named
    `½ ‖u(t)‖² + ν ∫₀ᵗ ‖∇u‖² ds ≤ ½ ‖u₀(0)‖²` shape on the
    placeholders. Real `Prop` over real arithmetic.
  * `LerayEnergyIneq_dissipation_zero_simplifies` — the active
    tripwire. Currently `LerayEnergyIneq ν u u₀ ↔ ∀ t,
    ½ (H1Norm u t)² ≤ ½ (H1Norm u₀ 0)²` because the dissipation
    term collapses to zero. Flipping `Dissipation` to any
    non-zero body intentionally breaks the `add_zero` step in
    the proof, signalling that a real dissipation term has landed
    and the Leray-Hopf surface needs a real proof of monotonicity
    against the dissipation.

### Honest scope

What this file claims:

  * `H1Norm_v2` is the *alias* `H1Norm` (the Task #51 placeholder
    Euclidean norm of `u t 0`). NOT the real H¹ Sobolev norm,
    NOT an `L²` norm — explicit alias awaiting a future
    refactor.
  * `Dissipation` is the literal zero function. NOT the real
    dissipation `ν ‖∇u(t)‖_{L²}²`, NOT an `L²` gradient norm.
  * `ViscosityScaling` is `ν * 0 = 0` definitionally; the
    coupling constant `ν` is genuinely quantified.
  * `EnergyDissipationIntegral` is `ν * t * 0 = 0` definitionally
    on the placeholder. NOT a real Lebesgue integral, NOT the
    Leray-Hopf cumulative dissipation.
  * `LerayEnergyIneq` is a real `Prop` over real arithmetic; its
    *content* is the placeholder schema, not the Clay
    conjecture's energy inequality.
  * `LerayEnergyIneq_dissipation_zero_simplifies` is a genuine
    `Iff` and the tripwire mechanism: the proof closes only
    because `Dissipation = 0`. Any non-zero upgrade breaks it.

What this file does NOT claim:

  * The Leray-Hopf energy inequality
    `½ ‖u(t)‖_{L²}² + ν ∫₀ᵗ ‖∇u‖_{L²}² ds ≤ ½ ‖u₀‖_{L²}²`;
  * Any actual NS time-evolution operator (no `Φ_t` is constructed);
  * NS global regularity, weak-strong uniqueness, or any other
    Clay-style result.

NS tower status unchanged: **Open** (`docs/ROADMAP.md` § 3).

### Zero shared imports

This file imports only `Towers.NS.EnergyIneq` (the Task #51 / #56
/ #62 / #69 / #70 NS schema foundation). It does NOT import
`Towers.Spectral.OperatorV2` or `Towers.YM.Spectrum` — the other
two Batch 8 tracks are independent and run in parallel.
================================================================
-/

import Towers.NS.EnergyIneq

namespace TheoremaAureum
namespace Towers
namespace NS
namespace EnergyV2

open TheoremaAureum.Towers.NS

/-! ### Schema defs (5) — one per Batch 8 directive item -/

/-- **Brick 1 (`H1Norm_v2`).** Placeholder-upgrade target for
the Task #51 `H1Norm`. Currently the literal alias
`H1Norm_v2 u t := H1Norm u t`. The aliasing is intentional: it
reserves the `_v2` name for the real Sobolev / `L²` replacement
without forcing a rename of every downstream caller when the
upgrade lands.

TODO (mathlib v4.13+): replace the body with
`(∫ x, ‖u t x‖^2 ∂volume).sqrt` on `MeasureTheory.MemLp 2`. -/
noncomputable def H1Norm_v2 (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t

/-- **Brick 2 (`Dissipation`).** Placeholder gradient-energy term.
Currently the literal zero function. Honest stand-in for
`‖∇u(t)‖_{L²}²` until `fderiv ℝ (u t)` plus an `MemLp 2` packaging
lands.

TODO (mathlib v4.13+): replace the body with
`∫ x, ‖fderiv ℝ (u t) x‖^2 ∂volume` on `MeasureTheory.MemLp 2`. -/
def Dissipation (_u : VelocityField) (_t : ℝ) : ℝ := 0

/-- **Brick 3 (`Dissipation_nonneg`).** `0 ≤ Dissipation u t`.
Currently trivial because the placeholder body is `0`. The
statement honestly anticipates the `sq_nonneg`-shaped proof a real
`‖∇u‖_{L²}²` upgrade will need; updating the body to a real
integral of squared norms keeps this brick provable via
`integral_nonneg` + `sq_nonneg`. -/
theorem Dissipation_nonneg (u : VelocityField) (t : ℝ) :
    0 ≤ Dissipation u t := by
  unfold Dissipation
  exact le_refl 0

/-- **Brick 4 (`ViscosityScaling`).** Names the coupling-constant
scaling `ν * Dissipation u t`. Reserves the slot for the
viscosity coefficient in front of the dissipation term in the
Leray-Hopf inequality. On the current placeholder
(`Dissipation = 0`) this is `ν * 0 = 0` definitionally. -/
noncomputable def ViscosityScaling
    (ν : ℝ) (u : VelocityField) (t : ℝ) : ℝ :=
  ν * Dissipation u t

/-- **Brick 5 (`EnergyDissipationIntegral`).** Rectangle-rule
stand-in for `ν * ∫₀ᵗ ‖∇u(s)‖_{L²}² ds`. Defined as
`ν * t * Dissipation u 0` to preserve the linear-in-`t` shape
downstream `LerayEnergyIneq` arguments need without importing
`MeasureTheory.Integral.IntervalIntegral`. On the current
placeholder (`Dissipation = 0`) this is `ν * t * 0 = 0`
definitionally.

TODO (mathlib v4.13+): replace the body with
`ν * ∫ s in (0 : ℝ)..t, Dissipation u s` via `intervalIntegral`. -/
noncomputable def EnergyDissipationIntegral
    (ν : ℝ) (u : VelocityField) (t : ℝ) : ℝ :=
  ν * t * Dissipation u 0

/-! ### Supporting: `LerayEnergyIneq` + active tripwire -/

/-- **Placeholder-flavoured Leray-Hopf energy inequality.**
`∀ t, ½ (H1Norm u t)² + EnergyDissipationIntegral ν u t
≤ ½ (H1Norm u₀ 0)²`. Real `Prop` over real arithmetic on the
Task #51 / Batch 8 placeholders. NOT the Leray-Hopf energy
inequality — `H1Norm` is the Task #51 placeholder, `Dissipation`
is the Batch 8 zero placeholder, `EnergyDissipationIntegral` is
the rectangle-rule stand-in. -/
def LerayEnergyIneq (ν : ℝ) (u u₀ : VelocityField) : Prop :=
  ∀ t : ℝ,
    (1 / 2) * (H1Norm u t) ^ 2 + EnergyDissipationIntegral ν u t
      ≤ (1 / 2) * (H1Norm u₀ 0) ^ 2

/-- **Active tripwire — directive: `Tripwire active`.**

With the current `Dissipation = 0` placeholder, the
`EnergyDissipationIntegral` term in `LerayEnergyIneq` collapses,
so the predicate degenerates to a pointwise `H1Norm` square
inequality. The `Iff` is provable now because `add_zero` discharges
the dissipation column; flipping `Dissipation` to any non-zero body
(`ν ‖∇u‖_{L²}²`, or even a non-trivial stand-in like
`fun u t => 1`) intentionally breaks the proof, signalling that a
real dissipation term has landed and the Leray-Hopf surface needs
a real proof of monotonicity against the dissipation. -/
theorem LerayEnergyIneq_dissipation_zero_simplifies
    (ν : ℝ) (u u₀ : VelocityField) :
    LerayEnergyIneq ν u u₀ ↔
      ∀ t : ℝ,
        (1 / 2) * (H1Norm u t) ^ 2 ≤ (1 / 2) * (H1Norm u₀ 0) ^ 2 := by
  unfold LerayEnergyIneq EnergyDissipationIntegral Dissipation
  constructor
  · intro h t
    have := h t
    linarith
  · intro h t
    have := h t
    linarith

/-! ### Batch 9 (5) — real (non-zero) dissipation track

Adds a SECOND dissipation surface (`Dissipation_real`) and a
SECOND Leray-flavoured energy inequality (`LerayEnergyIneq_real`)
that uses it, **without touching** the Batch 8 `Dissipation`
(`= 0`) or its `LerayEnergyIneq_dissipation_zero_simplifies`
tripwire above. The tripwire stays green; the new track exposes
the "real" shape that downstream work can specialise.

**Honest scope.** None of these advance the NS tower past
`Status: Open`. They prove only:

  * `H1Norm_real` — squared placeholder H¹-norm `(‖u t 0‖)²`.
    NOT the real L² spatial integral.
  * `Dissipation_real` — non-zero placeholder dissipation
    `(‖u t 0‖)²`. Shape of `ν ‖∇u‖_{L²}²`, NOT the gradient
    L² norm.
  * `LerayEnergyIneq_real` — `Prop` shape
    `½ E(t) + ∫ D ≤ ½ E(0)` over the new defs. No proof —
    the Leray-Hopf inequality is **not** proved here.
  * `Dissipation_positive_ae` — `0 ≤ Dissipation_real u t` via
    `mul_self_nonneg`.
  * `EnergyDecayBound` — `0 ≤ H1Norm_real u t`; trivial lower
    bound on the squared placeholder, NOT a real decay theorem. -/

/-- **Brick (`H1Norm_real`).** Squared placeholder H¹-norm:
`(H1Norm u t)²` written as `H1Norm u t * H1Norm u t`. Real,
non-negative, deterministic function of `(u, t)`. NOT the L²
spatial integral of `|∇u|²`; just the square of the Task #51
placeholder evaluated at the spatial origin. -/
noncomputable def H1Norm_real (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t

/-- **Brick (`Dissipation_real`).** Non-zero placeholder dissipation,
shaped like `‖∇u‖²_{L²}` but using the Task #51 placeholder norm
in place of a real gradient. Concretely `H1Norm u t * H1Norm u t`.
NOT the L² norm of the velocity gradient; just a non-negative real
that downstream `LerayEnergyIneq_real` can refer to. The Batch 8
`Dissipation = 0` placeholder above is intentionally NOT changed
so the existing `LerayEnergyIneq_dissipation_zero_simplifies`
tripwire stays compileable. -/
noncomputable def Dissipation_real (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t

/-- **Brick (`LerayEnergyIneq_real`).** Leray-flavoured energy
inequality over the *real* (non-zero) dissipation placeholder:
`∀ t, ½ H1Norm_real u t + ν * t * Dissipation_real u 0
     ≤ ½ H1Norm_real u₀ 0`. A real `Prop` over real arithmetic on
the Batch 9 placeholders. **Not proved here** — the inequality is
the Clay-flavoured target, not a theorem on placeholders. NOT the
Leray-Hopf energy inequality; the constituent norms are
placeholders. -/
def LerayEnergyIneq_real (ν : ℝ) (u u₀ : VelocityField) : Prop :=
  ∀ t : ℝ,
    (1 / 2) * H1Norm_real u t + ν * t * Dissipation_real u 0
      ≤ (1 / 2) * H1Norm_real u₀ 0

/-- **Brick (`Dissipation_positive_ae`).** Pointwise non-negativity
of the Batch 9 `Dissipation_real` placeholder at every `(u, t)`.
Via `mul_self_nonneg`, since the body is `x * x`. Honest scope:
this is non-negativity of the *placeholder*, not the "almost
everywhere" positivity of a real dissipation density. -/
theorem Dissipation_positive_ae (u : VelocityField) (t : ℝ) :
    0 ≤ Dissipation_real u t := by
  unfold Dissipation_real
  exact mul_self_nonneg _

/-- **Brick (`EnergyDecayBound`).** Trivial pointwise lower bound on
the Batch 9 squared placeholder H¹-norm: `0 ≤ H1Norm_real u t`.
Honest scope: this is *not* a decay theorem; it's the floor of the
squared placeholder, available unconditionally via
`mul_self_nonneg`. A real energy-decay statement would require the
Leray-Hopf inequality, which is `LerayEnergyIneq_real` above and
is **not** proved. -/
theorem EnergyDecayBound (u : VelocityField) (t : ℝ) :
    0 ≤ H1Norm_real u t := by
  unfold H1Norm_real
  exact mul_self_nonneg _

/-! ### Batch 10 (5) — global-regularity scaffolds (BKM + small-data)

Five bricks naming the two classical paths to NS global regularity:
the Beale-Kato-Majda continuation criterion (vorticity-Linfty
blow-up controls regularity) and the small-data (Fujita-Kato) global
existence theorem. Both are NAMED schemas here — `Prop` predicates
parameterized over the placeholder `VelocityField` surface, not
proved. The `Enstrophy` brick adds a third non-zero placeholder
(distinct from `H1Norm_real` and `Dissipation_real`), and
`EnstrophyBalance` / `EnergyEnstrophy_interpolation` name the two
balance / interpolation shapes the BKM proof depends on.

**Honest scope.** NS tower stays **Open** (`docs/ROADMAP.md` § 3).
None of these are proofs; they are schema-level Prop predicates
plus one placeholder def. The Batch 8 `Dissipation = 0` tripwire
(`LerayEnergyIneq_dissipation_zero_simplifies`) is intentionally
untouched. -/

/-- **Brick (`Enstrophy`).** Placeholder enstrophy
`E(t) := ½ ‖ω(t)‖_{L²}²` (where `ω = curl u` is the vorticity).
Currently `Enstrophy u t := H1Norm u t * H1Norm u t * (1 / 2)` —
the squared placeholder H¹-norm scaled by `½`, since mathlib v4.12.0
does not provide a vorticity operator on plain `VelocityField`.
Non-negative real. NOT the real `L²` norm of `curl u`; honest
stand-in for the global-regularity track. -/
noncomputable def Enstrophy (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t * (1 / 2)

/-- **Schema (`EnstrophyBalance`).** Prop predicate "enstrophy
satisfies the differential balance"
`E(t) = E(0) − 2ν ∫₀ᵗ ‖∇ω(s)‖_{L²}² ds + ∫₀ᵗ ⟨ω⊗ω, ∇u⟩ ds`.
Here on the placeholder it reduces to the equality
`Enstrophy u t = Enstrophy u 0` (i.e. constant in `t`), reflecting
the absence of a real vortex-stretching term. Real Prop on the
placeholder; **not** the real Constantin-Foias enstrophy balance.
The unconditional `EnstrophyBalance u ν` is NOT proved here. -/
def EnstrophyBalance (u : VelocityField) (_ν : ℝ) : Prop :=
  ∀ t : ℝ, Enstrophy u t = Enstrophy u 0

/-- **Schema (`BealeKatoMajda_criterion_schema`).** Named Prop
predicate for the Beale-Kato-Majda continuation criterion: a smooth
NS solution on `[0, T)` extends to `T` iff
`∫₀ᵀ ‖ω(s)‖_{L^∞} ds < ∞`. On the placeholder this is rendered as
the implication
`(∀ t < T, Enstrophy u t ≤ M) → ∀ t ≤ T, Enstrophy u t ≤ M` —
the "uniform-bound continuation" *shape*, not the BKM theorem.
Real Prop over real arithmetic; the implication is NOT proved here
(would require local existence + uniform bound continuation, both
out of scope on placeholders). NS tower stays Open. -/
def BealeKatoMajda_criterion_schema
    (u : VelocityField) (T M : ℝ) : Prop :=
  (∀ t : ℝ, t < T → Enstrophy u t ≤ M) →
    ∀ t : ℝ, t ≤ T → Enstrophy u t ≤ M

/-- **Schema (`SmallDataGlobal_schema`).** Named Prop predicate for
Fujita-Kato small-data global existence: if the initial H¹-norm
`H1Norm u₀ 0` is below an explicit threshold `δ > 0`, the solution
exists globally with `H1Norm u t` bounded by a universal multiple
of `H1Norm u₀ 0` for all `t`. On the placeholder this is the
implication shape
`H1Norm u₀ 0 ≤ δ → ∀ t, H1Norm u t ≤ 2 * H1Norm u₀ 0` over
arbitrary `(u, u₀, δ)`. Real Prop over real arithmetic; NOT proved
here — would require the contraction-mapping argument in critical
Besov / Sobolev space which mathlib v4.12.0 does not surface. -/
def SmallDataGlobal_schema
    (u u₀ : VelocityField) (δ : ℝ) : Prop :=
  H1Norm u₀ 0 ≤ δ →
    ∀ t : ℝ, H1Norm u t ≤ 2 * H1Norm u₀ 0

/-- **Schema (`EnergyEnstrophy_interpolation`).** Named Prop
predicate for the standard interpolation inequality coupling
energy and enstrophy:
`‖u‖_{L^∞}² ≤ C * ‖u‖_{L²} * ‖∇u‖_{L²}` (Agmon / Sobolev in 3D),
which yields `H1Norm_real u t ≤ C * (Enstrophy u t) * (H1Norm u t)`
after squaring and re-grouping the placeholders. Real Prop with
universal `C` quantifier; the inequality is NOT proved here —
genuine Sobolev embedding theorems on placeholders are out of
scope. Honest scope: this NAMES the interpolation step the BKM
proof depends on, without supplying it. -/
def EnergyEnstrophy_interpolation (u : VelocityField) (t : ℝ) : Prop :=
  ∃ C : ℝ, 0 ≤ C ∧
    H1Norm_real u t ≤ C * Enstrophy u t * H1Norm u t

/-! ### Batch 11 (5) — small-data global existence track

Five bricks that promote the Batch 10 BKM / Fujita-Kato scaffolding
one step toward an existence witness:

  1. `Enstrophy_bound_from_small_data` — combinator: from a
     `SmallDataGlobal_schema u u₀ δ` hypothesis with `H1Norm u₀ 0 ≤
     δ`, derive a quadratic Enstrophy bound `Enstrophy u t ≤
     2 * (H1Norm u₀ 0) * (H1Norm u₀ 0)`. Real algebra on the
     placeholder; the bound is the squared Fujita-Kato bound on
     `H1Norm u t` times the `½` in `Enstrophy`'s definition, scaled
     up — schema-level, NOT the real enstrophy bound from PDE
     analysis.
  2. `BealeKatoMajda_implies_global` — combinator: from a
     `BealeKatoMajda_criterion_schema u T M` hypothesis AND the
     uniform Enstrophy bound, conclude `∀ t ≤ T, Enstrophy u t ≤ M`.
     Schema → result bridge; this is BKM elimination on the
     placeholder, NOT a proof of BKM itself.
  3. `SmallDataGlobal_proven` — actually PROVE
     `SmallDataGlobal_schema 0 0 δ` for any `δ`, the zero velocity
     field. With `H1Norm 0 t = 0` for all `t` (via Task #51's
     `H1Norm_zero`), the implication chain collapses: `0 ≤ δ →
     ∀ t, 0 ≤ 2 * 0` is `True`. Honest scope: trivial-on-zero
     witness; NOT the real Fujita-Kato theorem.
  4. `Energy_decay_exponential` — NAMED Prop schema for
     `∃ C η, 0 < η ∧ H1Norm u t ≤ C * Real.exp (-η * t)`. NOT
     proved — exponential decay needs a real dissipation
     mechanism which the placeholder does not have.
  5. `LerayHopf_weak_solution_exists` — NAMED Prop schema for
     existence of a Leray-Hopf weak solution: `∃ u, EnergyMonotone
     u u₀`. NOT proved — existence of weak solutions on the
     placeholder surface is out of scope.

**Tripwire active (directive Track 2).** Since
`BealeKatoMajda_implies_global` is a combinator that takes
`BealeKatoMajda_criterion_schema` as a hypothesis (NOT a proof of
the criterion itself), `SmallDataGlobal_proven` is restricted to
the vacuous-on-zero case. Both honestly reflect that BKM and
Fujita-Kato remain unproven on the placeholder. NS tower stays
**Open** (`docs/ROADMAP.md` § 3). -/

/-- **Brick (`Enstrophy_bound_from_small_data`).** Combinator: from
`SmallDataGlobal_schema u u₀ δ` AND `H1Norm u₀ 0 ≤ δ`, derive the
quadratic enstrophy bound `Enstrophy u t ≤ 2 * H1Norm u₀ 0 * H1Norm
u₀ 0` (the squared `2 * H1Norm u₀ 0` Fujita-Kato bound, times
`½` from `Enstrophy`'s definition, gives `2 * (H1Norm u₀ 0)²`). Real
algebra: square the supplied `H1Norm u t ≤ 2 * H1Norm u₀ 0` bound
via `mul_le_mul` (both sides non-negative) and absorb the `(1/2)`
factor. Honest scope: this is the *placeholder* bound on the
placeholder Enstrophy; NOT the real Fujita-Kato enstrophy bound
from PDE analysis. -/
theorem Enstrophy_bound_from_small_data
    (u u₀ : VelocityField) (δ : ℝ)
    (h_schema : SmallDataGlobal_schema u u₀ δ)
    (h_small : H1Norm u₀ 0 ≤ δ) :
    ∀ t : ℝ, Enstrophy u t ≤ 2 * H1Norm u₀ 0 * H1Norm u₀ 0 := by
  intro t
  have h_u : H1Norm u t ≤ 2 * H1Norm u₀ 0 := h_schema h_small t
  have h_nonneg_u : 0 ≤ H1Norm u t := H1Norm_nonneg u t
  have h_nonneg_u₀ : 0 ≤ H1Norm u₀ 0 := H1Norm_nonneg u₀ 0
  have h_two_nonneg : (0 : ℝ) ≤ 2 * H1Norm u₀ 0 :=
    mul_nonneg (by norm_num) h_nonneg_u₀
  have h_sq : H1Norm u t * H1Norm u t ≤
      (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) :=
    mul_le_mul h_u h_u h_nonneg_u h_two_nonneg
  unfold Enstrophy
  have h_half : H1Norm u t * H1Norm u t * (1 / 2) ≤
      (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) * (1 / 2) :=
    mul_le_mul_of_nonneg_right h_sq (by norm_num)
  have h_simp : (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) * (1 / 2) =
      2 * H1Norm u₀ 0 * H1Norm u₀ 0 := by ring
  linarith [h_half, h_simp.le, h_simp.ge]

/-- **Brick (`BealeKatoMajda_implies_global`).** Combinator: from
`BealeKatoMajda_criterion_schema u T M` (which IS itself the
implication "uniform bound on `[0, T)` extends to `[0, T]`") AND a
uniform Enstrophy bound on `[0, T)`, conclude the uniform bound on
`[0, T]`. Direct application of the schema. Honest scope: this is
BKM *elimination* on the placeholder — given the schema's
implication, apply it — NOT a proof of the BKM criterion itself.
Directive tripwire: if the caller cannot supply
`BealeKatoMajda_criterion_schema u T M`, the conclusion is
unreachable. -/
theorem BealeKatoMajda_implies_global
    (u : VelocityField) (T M : ℝ)
    (h_bkm : BealeKatoMajda_criterion_schema u T M)
    (h_bound : ∀ t : ℝ, t < T → Enstrophy u t ≤ M) :
    ∀ t : ℝ, t ≤ T → Enstrophy u t ≤ M :=
  h_bkm h_bound

/-- **Brick (`SmallDataGlobal_proven`).** Actual proof of
`SmallDataGlobal_schema 0 0 δ` for ANY `δ : ℝ`, the zero velocity
field as both initial data and solution. With `H1Norm (0 :
VelocityField) t = 0` (via Task #51's `H1Norm_zero`), the
implication is `0 ≤ δ → ∀ t, 0 ≤ 2 * 0`, both sides identically
`0`. Honest scope: trivial-on-zero witness; NOT the real
Fujita-Kato global existence theorem. The directive's Track 2
tripwire ("if BKM fails, SmallDataGlobal must be schema") is
honored: this brick proves the schema only on the zero field, the
general statement is still `SmallDataGlobal_schema`. -/
theorem SmallDataGlobal_proven (δ : ℝ) :
    SmallDataGlobal_schema (0 : VelocityField) (0 : VelocityField) δ := by
  intro _h_small t
  rw [H1Norm_zero t, H1Norm_zero 0]
  norm_num

/-- **Schema (`Energy_decay_exponential`).** Named Prop predicate for
exponential energy decay: `∃ C η > 0, ∀ t ≥ 0, H1Norm u t ≤ C *
Real.exp (-η * t)`. Real Prop over real arithmetic; NOT proved here
— exponential decay needs a real dissipation mechanism the
placeholder does not have. NS tower stays Open. -/
def Energy_decay_exponential (u : VelocityField) : Prop :=
  ∃ C η : ℝ, 0 < C ∧ 0 < η ∧
    ∀ t : ℝ, 0 ≤ t → H1Norm u t ≤ C * Real.exp (-η * t)

/-- **Schema (`LerayHopf_weak_solution_exists`).** Named Prop
predicate for existence of a Leray-Hopf weak solution to NS with
initial data `u₀`: `∃ u, EnergyMonotone u u₀`. Real Prop; NOT
proved here — Leray's 1934 existence theorem on the placeholder
surface (which lacks a real weak-formulation of NS) is out of
scope. NS tower stays Open. -/
def LerayHopf_weak_solution_exists (u₀ : VelocityField) : Prop :=
  ∃ u : VelocityField, EnergyMonotone u u₀

end EnergyV2
end NS
end Towers
end TheoremaAureum
