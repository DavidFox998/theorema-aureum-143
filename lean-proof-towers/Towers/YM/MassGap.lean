/-
  # Towers.YM.MassGap

  **Statement-only file. Contains no theorems and no proofs.** This
  file pins the Clay Yang-Mills mass-gap conjecture as a future
  formalisation target. The current body is `sorry`, deliberately,
  because mathlib v4.12.0 has none of the prerequisite machinery:

    * No principal `SU(3)`-bundle on `ℝ⁴`.
    * No Lie-algebra-valued connection 1-forms, no curvature, no
      Yang-Mills action.
    * No Wightman / Osterwalder-Schrader axiomatic QFT framework.
    * No constructive 4D Yang-Mills Hamiltonian, no Hilbert space
      of physical states, no orthogonality-to-vacuum predicate.

  Because the right-hand side is `sorry`, `#print axioms
  YM_mass_gap_statement` will display `sorryAx`. That is **expected
  and visible**: the placeholder cannot be silently mistaken for a
  proved or even a precisely-stated theorem.

  ## What this file is NOT

  * It is **not** a proof of the Yang-Mills mass gap.
  * It is **not** a precise Lean statement of the Clay conjecture
    (we cannot write one without QFT machinery).
  * It is **not** counted by `scripts/check-towers.sh` in the
    `BRICKS` axiom-footprint check. The script only verifies the
    seven real bricks (RH / BSD / NS / YM gauge-action). This file
    deliberately ships with `sorryAx` and is therefore NOT a brick.

  ## What this file IS

  * A stable, citable Lean identifier
    (`TheoremaAureum.Towers.YM.YM_mass_gap_statement`) that future
    plans can point to in papers and roadmaps as the future
    target.
  * A flagged TODO: the `sorry` is visible, intentional, and
    documented. It does not propagate into the brick footprints
    (`gauge_action_one_smul`, `gauge_action_mul_smul`) because no
    brick imports this file.

  ## Status

  Per `docs/ROADMAP.md` § 2. Yang-Mills mass gap: **Open.** No
  promotion. The existence of this `sorry`-backed schema does not
  change the tower's status; it only names the target.

  ## Honest-scope reminder

  The repo's locked rule (see `replit.md`, "Honest-scope wording is
  locked"): no tower is promoted past `Status: Open` unless the
  Lean spine actually closes that named theorem with axioms = [].
  This file emphatically does NOT close anything.
-/

namespace TheoremaAureum
namespace Towers
namespace YM

/-- **The Clay Millennium Yang-Mills mass-gap statement.**

    Informal statement (Jaffe-Witten, *Quantum Yang-Mills theory*,
    Clay Mathematics Institute Millennium Problem description,
    2000): for the compact simple gauge group `SU(3)` on `ℝ⁴`,
    the constructive 4D Yang-Mills quantum field theory exists and
    exhibits a mass gap `Δ > 0` — the spectrum of the Hamiltonian
    above the vacuum state is bounded below by `Δ`.

    **TODO: replace `sorry` with the real statement once mathlib
    ships `Mathlib.QuantumField.YangMills.Hamiltonian` (or an
    equivalent constructive 4D QFT framework), the `SU(3)` Lie
    group with its Lie algebra, principal-bundle theory on `ℝ⁴`,
    and the physical-state Hilbert space.** Until then, the
    right-hand side is `sorry` to make the gap visible to `#print
    axioms`.

    Note: `#print axioms YM_mass_gap_statement` will show
    `[sorryAx]`. This is intentional and documented. The brick
    theorems `gauge_action_one_smul` and `gauge_action_mul_smul`
    do NOT import this file, so their axiom footprints remain in
    `{propext, Classical.choice, Quot.sound}` as verified by
    `scripts/check-towers.sh`. -/
def YM_mass_gap_statement : Prop := sorry

end YM
end Towers
end TheoremaAureum
