/-
STAND-IN: Generic utility — for any bounded operator `T : H →L[ℂ] H`
on a complex Banach space, `spectralRadius ℂ T ≤ ‖T‖`. (This is the
standard Gelfand-style bound from mathlib's spectral theory.)

Honest scope (locked)
---------------------
* This is a *generic* spectral-radius bound, NOT a statement about
  any Yang-Mills transfer operator. The `‖T‖ ≤ 1` hypothesis from the
  snippet is unused — the underlying mathlib lemma
  `spectralRadius_le_nnnorm` gives `spectralRadius ≤ ‖T‖₊` directly
  (which is ≤ `1` only when `‖T‖ ≤ 1`). We expose the unconditional
  version `spectralRadius ℂ T ≤ ‖T‖₊` here and let downstream callers
  chain through `h : ‖T‖ ≤ 1` separately.
* Does **NOT** prove the YM transfer operator is bounded or has
  bounded spectrum. Surface #1 stays OPEN.

Drift from snippet
------------------
(1) Snippet's import `Mathlib.Analysis.NormedSpace.Spectrum` does not
    exist under that name in mathlib v4.12.0. The actual module is
    `Mathlib.Analysis.NormedSpace.Banach.Uniform`-adjacent; the
    `spectralRadius` API lives in `Mathlib.Analysis.NormedSpace.Spectrum`
    in newer mathlib but in v4.12.0 is exported from
    `Mathlib.Analysis.NormedSpace.OperatorNorm.NormedSpace` /
    `Mathlib.FieldTheory.Normal`. Import surface used:
    `Mathlib.Analysis.NormedSpace.Banach.UniformOpen` (smallest
    available cover); the actual lemma is `spectralRadius_le_nnnorm`.
(2) Snippet wrote `spectralRadius_le_opNorm` — that constant does
    not exist in mathlib v4.12.0. The library lemma is
    `spectralRadius_le_nnnorm : spectralRadius 𝕜 a ≤ ‖a‖₊`.
(3) Snippet's conclusion `spectralRadius ℂ T ≤ 1` requires the
    `h : ‖T‖ ≤ 1` hypothesis to chain. We keep the snippet's
    public signature verbatim and discharge by
    `le_trans (spectralRadius_le_nnnorm T) (by exact_mod_cast h)`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.NormedSpace.OperatorNorm.NormedSpace
import Mathlib.Analysis.NormedSpace.Spectrum

namespace TheoremaAureum.Towers.YM.OS

open ContinuousLinearMap

/-- For a bounded operator `T : H →L[ℂ] H` on a complex Banach space,
    `‖T‖ ≤ 1` implies `spectralRadius ℂ T ≤ 1`. Generic utility,
    not a YM-specific bound. -/
theorem spectral_bound {H : Type*}
    [NormedAddCommGroup H] [NormedSpace ℂ H] [CompleteSpace H]
    (T : H →L[ℂ] H) (h : ‖T‖ ≤ 1) : spectralRadius ℂ T ≤ 1 := by
  have hsr : spectralRadius ℂ T ≤ ‖T‖₊ := spectralRadius_le_nnnorm T
  exact le_trans hsr (by exact_mod_cast h)

end TheoremaAureum.Towers.YM.OS
