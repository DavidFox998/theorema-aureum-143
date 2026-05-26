/-
  # Towers.NS.EnergyIneq

  **Statement-only file. Contains no theorems and no proofs.** This
  file pins the Clay 3D incompressible Navier-Stokes global
  regularity conjecture as a future formalisation target. The
  current body is `sorry`, deliberately, because mathlib v4.12.0
  has none of the prerequisite machinery:

    * No Sobolev spaces `H^k(ℝ³; ℝ³)` for vector fields.
    * No Leray projector, no Helmholtz decomposition.
    * No Navier-Stokes operator
      `∂_t u + (u · ∇) u - Δ u + ∇p = 0`, `div u = 0`.
    * No notion of a global-in-time smooth solution on
      `[0, ∞) × ℝ³`, no `L²` energy inequality, no Beale-Kato-Majda
      blow-up criterion.

  Because the right-hand side is `sorry`, `#print axioms
  NS_global_regular_statement` will display `sorryAx`. That is
  **expected and visible**: the placeholder cannot be silently
  mistaken for a proved or even a precisely-stated theorem.

  ## What this file is NOT

  * It is **not** a proof of Navier-Stokes global regularity.
  * It is **not** an energy inequality, blow-up criterion, or any
    other PDE result.
  * It is **not** a precise Lean statement of the Clay conjecture
    (we cannot write one without Sobolev / NS-operator machinery).
  * It is **not** counted by `scripts/check-towers.sh` in the
    `BRICKS` axiom-footprint check. The script only verifies the
    seven real bricks (RH / BSD / NS / YM gauge-action). This file
    deliberately ships with `sorryAx` and is therefore NOT a brick.

  ## What this file IS

  * A stable, citable Lean identifier
    (`TheoremaAureum.Towers.NS.NS_global_regular_statement`) that
    future plans can point to in papers and roadmaps as the future
    target.
  * A flagged TODO: the `sorry` is visible, intentional, and
    documented. It does not propagate into the brick footprints
    (`divergence_add`, `divergence_smul`) because no brick imports
    this file.

  ## Status

  Per `docs/ROADMAP.md` § 3. Navier-Stokes global regularity:
  **Open.** No promotion. The existence of this `sorry`-backed
  schema does not change the tower's status; it only names the
  target.

  ## Honest-scope reminder

  The repo's locked rule (see `replit.md`, "Honest-scope wording is
  locked"): no tower is promoted past `Status: Open` unless the
  Lean spine actually closes that named theorem with axioms = [].
  This file emphatically does NOT close anything.
-/

namespace TheoremaAureum
namespace Towers
namespace NS

/-- **The Clay Millennium Navier-Stokes global regularity statement.**

    Informal statement (Fefferman, *Existence and smoothness of
    the Navier-Stokes equation*, Clay Mathematics Institute
    Millennium Problem description, 2000): for every smooth,
    divergence-free, finite-energy initial datum
    `u₀ : ℝ³ → ℝ³`, there exists a global smooth solution
    `u : [0, ∞) × ℝ³ → ℝ³` of the 3D incompressible Navier-Stokes
    equations matching that initial datum.

    **TODO: replace `sorry` with the real statement once mathlib
    ships `Mathlib.Analysis.NavierStokes.Leray` (or an equivalent
    PDE framework), Sobolev spaces `H^k(ℝ³; ℝ³)`, the Leray
    projector, the Navier-Stokes operator, and a notion of global
    smooth solution.** Until then, the right-hand side is `sorry`
    to make the gap visible to `#print axioms`.

    Note: `#print axioms NS_global_regular_statement` will show
    `[sorryAx]`. This is intentional and documented. The brick
    theorems `divergence_add` and `divergence_smul` do NOT import
    this file, so their axiom footprints remain in
    `{propext, Classical.choice, Quot.sound}` as verified by
    `scripts/check-towers.sh`. -/
def NS_global_regular_statement : Prop := sorry

end NS
end Towers
end TheoremaAureum
