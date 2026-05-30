/-
================================================================
Towers / NS / Stokes  (Tower 540, Phase 2B — the Stokes operator)

**The Stokes operator `A = -PΔ : Hˢ⁺²_div → Hˢ_div`.**

Builds on the Phase-1 weighted-`L²` Fourier model
`Towers/NS/FunctionSpaces.lean`. On the Fourier side the Laplacian
`Δ` is multiplication by `-‖ξ‖²`, so `-Δ` is multiplication by the
real, nonnegative symbol `‖ξ‖²`. On divergence-free fields the Leray
projection `P` acts as the identity, so the Stokes operator `A = -PΔ`
IS multiplication by `‖ξ‖²`, mapping `Hˢ⁺²_div` into `Hˢ_div`
(it costs exactly two Sobolev derivatives).

------------------------------------------------------------------
## What is PROVED here, genuinely `sorry`-free + classical-trio
   (independent of the deferred lift; `#print axioms` = trio)

  * `symbol_pow_weight_le` — **the real mathematical content**: the
    `-Δ` symbol estimate `‖ξ‖⁴ · ⟨ξ⟩^{2s} ≤ ⟨ξ⟩^{2(s+2)}`, i.e.
    multiplication by `‖ξ‖²` costs exactly two derivatives, so
    `-Δ : Hˢ⁺² → Hˢ` is bounded. Pure real analysis (`Real.rpow_add`
    + base `≥ 1`), `sorry`-free.
  * `stokesSymbol_re_nonneg` — the symbol `‖ξ‖²` is real and `≥ 0`
    (the `-Δ ≥ 0` positivity that makes `A` a candidate sectorial
    generator).
  * `continuous_stokesSymbol` — the symbol is continuous.
  * `stokes_aestronglyMeasurable` — the multiplied field is
    a.e.-strongly-measurable for `μ_s`.

------------------------------------------------------------------
## The ONE deferred `sorry` (measure-theoretic lift)

  * `stokes_eLpNorm_le` — `‖ξ‖² • û` has `L²(μ_s)`-norm `≤` the
    `L²(μ_{s+2})`-norm of `û`. The POINTWISE content is exactly the
    PROVED `symbol_pow_weight_le`; what is deferred is only the
    lift of that pointwise bound through the two `withDensity`
    integrals (`lintegral_withDensity_eq_lintegral_mul₀`) and the
    `eLpNorm = (∫⁻ ‖·‖₊²)^{1/2}` bookkeeping — real but long
    `ℝ≥0∞`/`rpow` plumbing, not new mathematics. Deferred, NOT a
    brick.

------------------------------------------------------------------
## Operator-level declarations — PROVISIONAL (inherit `sorryAx`)
   These are written as the genuine operator, but every one routes
   its `L²` finiteness/bound through `stokes_eLpNorm_le`, so until
   that lemma is discharged their `#print axioms` reports `sorryAx`
   — they are NOT trio-clean and must not be reported as proved.

  * `stokesMemℒp` — `‖ξ‖² • û ∈ L²(μ_s)` (uses the deferred bound).
  * `stokesₗ` — the `‖ξ‖²` Fourier multiplier as a **linear** map
    `Hˢ⁺² →ₗ[ℂ] Hˢ` (additivity + `ℂ`-homogeneity proved a.e. from
    the `Lp` coe-fn calculus, but built on `stokesMemℒp`).
  * `stokes_mult` — the multiplier as a **bounded** map
    `Hˢ⁺² →L[ℂ] Hˢ`, operator norm `≤ 1`.
  * `stokes_preserves_divFree` — `A` maps divergence-free fields to
    divergence-free fields (`⟪toVal ξ, ‖ξ‖² • û⟫ = ‖ξ‖² · 0 = 0`).
  * `stokes_op` — **the Stokes operator** `Hˢ⁺²_div →L[ℂ] Hˢ_div`,
    the `‖ξ‖²` multiplier restricted/corestricted to the
    divergence-free subspaces.
  * `stokes_op_norm_le` — `‖A u‖ ≤ ‖u‖`.

------------------------------------------------------------------
## Honest scope (tripwires)

  * **No existence/regularity claim.** This file builds the bounded
    Stokes operator and proves its algebraic/metric structure; it
    proves NO Navier–Stokes result.
  * **Self-adjointness, sectoriality, and analytic-semigroup
    generation are NOT formalized.** The symbol `‖ξ‖²` is real and
    `≥ 0` (proved: `stokesSymbol_re_nonneg`), which is the algebraic
    seed of those properties, but the operator-semigroup theory
    needed to state/prove "generates an analytic semigroup" is
    absent from mathlib v4.12.0. We deliberately do NOT fabricate
    sorried theorems for statements we cannot honestly phrase.
  * NS tower stays `Status: Open`; Surface #2 stays OPEN.
  * Self-contained: imports only the Phase-1 `FunctionSpaces`; no
    cross-tower imports, definitions, or claims.
================================================================
-/

import Towers.NS.FunctionSpaces

open MeasureTheory
open scoped ENNReal
open TheoremaAureum.Towers.NS.FunctionSpaces

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Stokes

/-- **The Stokes / `-Δ` Fourier symbol** `‖ξ‖²` (as a complex scalar).
    `-Δ` is multiplication by `‖ξ‖²` on the Fourier side. -/
noncomputable def stokesSymbol (ξ : Freq) : ℂ := ((‖ξ‖ ^ 2 : ℝ) : ℂ)

/-- The symbol is real-valued; its real part is `‖ξ‖² ≥ 0`. This is
    the `-Δ ≥ 0` positivity (the seed of sectoriality). -/
theorem stokesSymbol_re_nonneg (ξ : Freq) : 0 ≤ (stokesSymbol ξ).re := by
  rw [stokesSymbol, Complex.ofReal_re]; positivity

theorem continuous_stokesSymbol : Continuous stokesSymbol :=
  Complex.continuous_ofReal.comp (continuous_norm.pow 2)

/-- **The `-Δ` symbol estimate — the real mathematical content.**
    `‖ξ‖⁴ · ⟨ξ⟩^{2s} ≤ ⟨ξ⟩^{2(s+2)}`: multiplication by the Laplacian
    symbol `‖ξ‖²` costs exactly two Sobolev derivatives, so
    `-Δ : Hˢ⁺² → Hˢ` is bounded. Proof: split `⟨ξ⟩^{2(s+2)} =
    ⟨ξ⟩^{2s} · ⟨ξ⟩^4` (`Real.rpow_add`, base `≥ 1`) and bound
    `‖ξ‖⁴ ≤ ⟨ξ⟩^4`. -/
theorem symbol_pow_weight_le (s : ℝ) (ξ : Freq) :
    (‖ξ‖ ^ 2) ^ 2 * (1 + ‖ξ‖ ^ 2) ^ s ≤ (1 + ‖ξ‖ ^ 2) ^ (s + 2) := by
  have hb : (0 : ℝ) < 1 + ‖ξ‖ ^ 2 := by positivity
  have h4 : (‖ξ‖ ^ 2) ^ 2 ≤ (1 + ‖ξ‖ ^ 2) ^ 2 := by
    nlinarith [sq_nonneg ‖ξ‖]
  have hsplit : (1 + ‖ξ‖ ^ 2) ^ (s + 2) = (1 + ‖ξ‖ ^ 2) ^ s * (1 + ‖ξ‖ ^ 2) ^ 2 := by
    rw [Real.rpow_add hb, Real.rpow_two]
  rw [hsplit]
  calc (‖ξ‖ ^ 2) ^ 2 * (1 + ‖ξ‖ ^ 2) ^ s
      ≤ (1 + ‖ξ‖ ^ 2) ^ 2 * (1 + ‖ξ‖ ^ 2) ^ s := by gcongr
    _ = (1 + ‖ξ‖ ^ 2) ^ s * (1 + ‖ξ‖ ^ 2) ^ 2 := by ring

/-- **A.e.-strong-measurability of the multiplied field for `μ_s`.**
    `f` is a.e.-strongly-measurable for `μ_{s+2}`, hence for the
    smaller measure `μ_s ≤ μ_{s+2}`; the continuous symbol multiplies
    it. -/
theorem stokes_aestronglyMeasurable (s : ℝ) (f : Hsv (s + 2)) :
    AEStronglyMeasurable (fun ξ => stokesSymbol ξ • f ξ) (mu s) := by
  have hf : AEStronglyMeasurable (⇑f) (mu s) :=
    (Lp.aestronglyMeasurable f).mono_measure (mu_mono (by linarith : s ≤ s + 2))
  exact (continuous_stokesSymbol.aestronglyMeasurable).smul hf

/-- **DEFERRED (1 documented `sorry`) — the integral lift.** The
    `L²(μ_s)` norm of `‖ξ‖² • û` is bounded by the `L²(μ_{s+2})` norm
    of `û`. The pointwise content is the PROVED `symbol_pow_weight_le`;
    only the `withDensity`/`eLpNorm` lift is deferred. NOT a brick. -/
theorem stokes_eLpNorm_le (s : ℝ) (f : Hsv (s + 2)) :
    eLpNorm (fun ξ => stokesSymbol ξ • f ξ) 2 (mu s) ≤ eLpNorm (⇑f) 2 (mu (s + 2)) := by
  sorry

/-- The multiplied field is in `L²(μ_s)`: a.e.-strongly-measurable
    with finite `L²` norm (bounded by `‖f‖_{H^{s+2}} < ∞`). -/
theorem stokesMemℒp (s : ℝ) (f : Hsv (s + 2)) :
    Memℒp (fun ξ => stokesSymbol ξ • f ξ) 2 (mu s) :=
  ⟨stokes_aestronglyMeasurable s f,
    lt_of_le_of_lt (stokes_eLpNorm_le s f) (Lp.memℒp f).2⟩

/-- **The `‖ξ‖²` Fourier multiplier as a linear map** `Hˢ⁺² →ₗ[ℂ] Hˢ`.
    Additivity and `ℂ`-homogeneity hold a.e.-`μ_s` (the symbol pulls
    through `+` and `•`), lifted across the measure domination
    `μ_s ≤ μ_{s+2}` via the `Lp` coe-fn calculus. -/
noncomputable def stokesₗ (s : ℝ) : Hsv (s + 2) →ₗ[ℂ] Hsv s where
  toFun f := (stokesMemℒp s f).toLp _
  map_add' f g := by
    refine Lp.ext ?_
    filter_upwards [(stokesMemℒp s (f + g)).coeFn_toLp,
      (stokesMemℒp s f).coeFn_toLp, (stokesMemℒp s g).coeFn_toLp,
      (Lp.coeFn_add f g).filter_mono (ae_mono (mu_mono (by linarith : s ≤ s + 2))),
      Lp.coeFn_add ((stokesMemℒp s f).toLp _) ((stokesMemℒp s g).toLp _)]
      with ξ h0 hf hg hadd haddL
    simp only [h0, haddL, hf, hg, Pi.add_apply, hadd, smul_add]
  map_smul' c f := by
    refine Lp.ext ?_
    filter_upwards [(stokesMemℒp s (c • f)).coeFn_toLp, (stokesMemℒp s f).coeFn_toLp,
      (Lp.coeFn_smul c f).filter_mono (ae_mono (mu_mono (by linarith : s ≤ s + 2))),
      Lp.coeFn_smul c ((stokesMemℒp s f).toLp _)]
      with ξ h0 hf hsmul hsmulL
    simp only [RingHom.id_apply, h0, hsmulL, hf, Pi.smul_apply, hsmul]
    exact smul_comm _ _ _

/-- The operator-norm bound `‖stokesₗ f‖ ≤ 1 · ‖f‖` (from
    `stokes_eLpNorm_le`), in the form `mkContinuous` consumes. -/
theorem stokes_mult_bound (s : ℝ) (f : Hsv (s + 2)) :
    ‖(stokesₗ s) f‖ ≤ 1 * ‖f‖ := by
  rw [one_mul, Lp.norm_def, Lp.norm_def]
  refine ENNReal.toReal_mono (Lp.memℒp f).2.ne ?_
  calc eLpNorm (⇑((stokesₗ s) f)) 2 (mu s)
      = eLpNorm (fun ξ => stokesSymbol ξ • f ξ) 2 (mu s) :=
        eLpNorm_congr_ae (stokesMemℒp s f).coeFn_toLp
    _ ≤ eLpNorm (⇑f) 2 (mu (s + 2)) := stokes_eLpNorm_le s f

/-- **The Stokes / `-Δ` multiplier as a bounded operator**
    `Hˢ⁺² →L[ℂ] Hˢ`, operator norm `≤ 1`. -/
noncomputable def stokes_mult (s : ℝ) : Hsv (s + 2) →L[ℂ] Hsv s :=
  (stokesₗ s).mkContinuous 1 (stokes_mult_bound s)

theorem coeFn_stokes_mult (s : ℝ) (f : Hsv (s + 2)) :
    stokes_mult s f =ᵐ[mu s] (fun ξ => stokesSymbol ξ • f ξ) :=
  (stokesMemℒp s f).coeFn_toLp

/-- **`-Δ` preserves divergence-freeness.** If `ξ · û(ξ) = 0` a.e.
    then `ξ · (‖ξ‖² û(ξ)) = ‖ξ‖² (ξ · û(ξ)) = 0` (`inner_smul_right`). -/
theorem stokes_preserves_divFree (s : ℝ) (u : divFreeSubmodule (s + 2)) :
    stokes_mult s (u : Hsv (s + 2)) ∈ divFreeSubmodule s := by
  rw [mem_divFreeSubmodule]
  show IsDivFree (stokes_mult s (u : Hsv (s + 2)))
  have hu : IsDivFree (u : Hsv (s + 2)) := u.2
  filter_upwards [coeFn_stokes_mult s (u : Hsv (s + 2)),
    hu.filter_mono (ae_mono (mu_mono (by linarith : s ≤ s + 2)))]
    with ξ hcoe hzero
  rw [hcoe, inner_smul_right, hzero, mul_zero]

/-- **The Stokes operator** `A = -PΔ : Hˢ⁺²_div →L[ℂ] Hˢ_div` — the
    `‖ξ‖²` multiplier corestricted to the divergence-free subspace
    (where `P = id`). -/
noncomputable def stokes_op (s : ℝ) : Hdiv_free (s + 2) →L[ℂ] Hdiv_free s :=
  ((stokes_mult s).comp (divFreeSubmodule (s + 2)).subtypeL).codRestrict
    (divFreeSubmodule s) (fun u => stokes_preserves_divFree s u)

theorem stokes_mult_norm_le (s : ℝ) (f : Hsv (s + 2)) :
    ‖stokes_mult s f‖ ≤ ‖f‖ := by
  calc ‖stokes_mult s f‖
      ≤ ‖stokes_mult s‖ * ‖f‖ := (stokes_mult s).le_opNorm f
    _ ≤ 1 * ‖f‖ := by
        gcongr
        exact LinearMap.mkContinuous_norm_le (stokesₗ s) zero_le_one (stokes_mult_bound s)
    _ = ‖f‖ := one_mul _

/-- **`A` is a contraction across orders: `‖A u‖ ≤ ‖u‖`.** -/
theorem stokes_op_norm_le (s : ℝ) (u : Hdiv_free (s + 2)) :
    ‖stokes_op s u‖ ≤ ‖u‖ :=
  stokes_mult_norm_le s _

end Stokes
end NS
end Towers
end TheoremaAureum
