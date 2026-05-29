/-
Wall 574 / [YM1] — Real Yang–Mills transfer Hamiltonian mass gap (SCAFFOLD).

HONEST SCOPE — DOCUMENTATION STUB, NOT A PROOF:
  This file states the TARGET of Wall 574 only. It carries a `sorry`.

  Task #248 Step 5 WIRED the real Step-4/Step-5 machinery in:
    * `H`              — now the genuine action-weighted Hamiltonian
                         `H U = wilsonAction U • 𝟙` (Step 4,
                         `LatticePositivityReal.lean`), the `−log` of the
                         Step-3 transfer operator `T = exp(−S_W[U]) · 𝟙`.
                         This is the SCALAR / Perron-sector shadow, NOT
                         yet the full Wilson transfer operator on
                         `L²(∏ SU(3), Haar)` (that construction is the
                         open Wall 574 work).
    * `spectrum_bound` — the real predicate from Step 5
                         (`SpectrumBound.lean`):
                         `spectrum_bound T m := ∀ ψ, m·‖ψ‖² ≤ ⟪ψ,Tψ⟫_ℝ`.

  The statement now ELABORATES against real symbols; only the `sorry`
  remains.

WHY THE HYPOTHESIS, AND WHY THE `sorry` STILL STANDS:
  By the Step-5 reduction `spectrum_bound_H_iff`, for the scalar `H U`
    `∃ m > 0, spectrum_bound (H U) m  ↔  0 < wilsonAction U`.
  i.e. the scalar-shadow "gap" is EXACTLY the deferred STRICT Wilson
  action positivity. That positivity FAILS at the vacuum configuration
  (`wilsonAction (const 1) = 0`, Step 2), so the bare universally-`U`
  form would be FALSE. We therefore carry `0 < wilsonAction U` as an
  EXPLICIT HYPOTHESIS (`hpos`) — making the statement true and honest
  rather than vacuum-false — and DELIBERATELY retain the `sorry`:

    * We make NO gap claim. Even granting `hpos`, this is only the
      SCALAR shadow `H U = wilsonAction U • 𝟙`, NOT the real Yang–Mills
      transfer operator. Discharging this conditional scalar statement
      (which `spectrum_bound_H_iff` + `hpos` would in fact permit) would
      misleadingly suggest progress on Surface #1, so we do NOT.
    * `hpos` itself (strict SU(3) action positivity off the vacuum) is a
      DEFERRED analytic input, not proved anywhere in the tower.
    * The genuine obligation is the FULL transfer operator (Wall 574);
      this file only WIRES the typed scaffold.

INVARIANT-LOCKED:
  * Makes NO mass-gap / μ>0 / Surface-#1-CLOSED claim while the `sorry`
    stands. Surface #1 stays OPEN; `∃ m > 0` for the real YM `H` is
    UNPROVEN. YM Status: Open.
  * Carries a `sorry`; deliberately NOT a `lean_lib` root and NOT
    registered in `scripts/check-towers.sh` BRICKS. A `sorry`-bearing
    declaration must never enter the wall. Script-reported wall unchanged.
-/
import Towers.YM.SpectrumBound

namespace TheoremaAureum.YM_MassGap

/-- Wall 574 TARGET (scaffold, carries `sorry`). For the Step-4 scalar
    Hamiltonian `H U`, `spectrum_bound_H_iff` makes this equivalent to
    `0 < wilsonAction U`, carried here as the explicit hypothesis `hpos`
    (the deferred strict action positivity; it fails at the vacuum, see
    the file header). The `sorry` is retained DELIBERATELY: this is only
    the scalar shadow, NOT the real transfer operator, so we make NO
    mass-gap claim and Surface #1 stays OPEN. -/
theorem YM_mass_gap {d L n : ℕ} [NeZero L] [NeZero n]
    (U : GaugeConfig d L) (hpos : 0 < wilsonAction U) :
    ∃ m > 0, spectrum_bound (E := PiLp 2 (fun _ : Fin n => ℝ)) (H U) m := by
  sorry -- invariant-locked: real Wilson transfer Hamiltonian unbuilt (Wall 574)

end TheoremaAureum.YM_MassGap
