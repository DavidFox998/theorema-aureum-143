/-
================================================================
Towers / Attempts / T_g  (Batch 19.1c — Track 3)

**The two hard surfaces for the transfer operator `T_g`.**

Parked here as `sorry`-bearing stubs. NOT registered in BRICKS —
see `scripts/check-towers.sh`. Their presence does NOT promote
any tower; YM stays `Status: Open` (`docs/ROADMAP.md` § 2) and
`MassGap_YM4_Clay` stays a schema.

  1. `Transfer_compact` — `T_g` is compact on `ℋ_phys`. **This is
     the mass gap for `g > 0`.** Cluster expansion / Glimm-Jaffe
     ch. 19 surface; no honest one-batch discharge.

  2. `Perron_Frobenius_for_transfer` — the real bound
     `0 < g → spectral_radius_def D g < 1`. Requires the cluster
     expansion plus the Perron-Frobenius theorem for positive
     compact operators on the OS-reconstructed Hilbert space.

These sit alongside the three Batch 18 stubs (`Perron.lean`,
`UniformGap.lean`, `Enstrophy.lean`) — same discipline, same
no-auto-promotion guarantee.
================================================================
-/

import Towers.YM.OSReconstruction
import Towers.YM.SpectralGap

namespace TheoremaAureum
namespace Towers
namespace Attempts
namespace T_g

open TheoremaAureum.Towers.YM.OSReconstruction
open TheoremaAureum.Towers.YM.SpectralGap

/-- **`T_g` is compact on `ℋ_phys`.** Cluster-expansion surface;
the named witness here is the still-NAMED `physHilbert_isHilbert`
Prop, used as a Prop-level stand-in for "the construction has
produced a real compact operator on a real Hilbert space". The
proof is left as `sorry`. -/
theorem Transfer_compact (D : OSPreHilbert) (_g : ℝ) :
    D.physHilbert_isHilbert := by
  sorry

/-- **Real Perron–Frobenius bound: `r(T_g) < 1` for `g > 0`.**

Honest scope: with the current placeholder `spectral_radius_def := 1`,
this statement is **false on its face** (`(1 : ℝ) < 1` is `False`).
That mismatch is intentional — it is the tripwire telling the next
batch that promoting `spectral_radius_def` away from the literal
`1` placeholder will require landing the real cluster-expansion
bound here. Marked `sorry`; lives outside BRICKS so the axiom
footprint of the green wall is untouched. -/
theorem Perron_Frobenius_for_transfer (D : OSPreHilbert)
    (g : ℝ) (_hg : 0 < g) :
    spectral_radius_def D g < 1 := by
  sorry

end T_g
end Attempts
end Towers
end TheoremaAureum
