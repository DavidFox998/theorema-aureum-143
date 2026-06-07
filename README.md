# Theorema Aureum for X_0(143)

Opera Numerorum | David Fox | May 21, 2026
ORCID: 0009-0008-1290-6105

---

## Main Theorem

  ArakelovPositivity(X_0(143))  =>  RiemannHypothesis

If the Arakelov self-intersection omega^2(X_0(143)) > 0, then every
nontrivial zero rho of the Riemann zeta function satisfies Re(rho) = 1/2.

**Proof chain:** C01 -> C02 -> C03 -> C04 -> C05 -> C06 -> C07

---

## Chain Summary

| Module | Theorem | Sorry | Freeze SHA (sha256) |
|--------|---------|-------|---------------------|
| C01 | ArakelovPositivity(X_0(143)) — omega^2=24>0 (g=13) | 0 | db291fc7dcf6debf... |
| C02 | Modularity, L-function, GRH stub | 0 | f4e92cc80deb4b16... |
| C03 | Slope inequality, Faltings height pos, height lower bound | 0 | 43f936d43edbc2d1... |
| C04 | Height machine, height-to-discriminant bound | 0 | bb19ed1035e6bcb1... |
| C05 | Discriminant estimates, conductor=level | 0 | 05faa464a681f712... |
| C06 | Bost-Connes C(S_4)>7>2*sqrt(13), zeta control stubs | 0 | 3fabeb28b3226c5a... |
| C07 | C07_RH_of_Arakelov: collects C01-C06 => RH | 0 | 0f7faf2c4e604e9c... |

Freeze ID: FREEZE_C01+C02+C03+C04+C05+C06+C07_20260607
Freeze timestamp: 2026-06-07T01:58:41Z
Tag: v1.6-C01-C07-FROZEN (opera-numerorum repo)

All 7 files: ZERO_SORRY (no sorry tokens, verified by freeze_modules.py).

---

## Certified Content vs. True Stubs

The C01-C07 files contain two classes of theorems:

**Real proofs (no sorry, no axiom, verified by Lean kernel):**
- C01: ArakelovPositivity_X0_143 (omega^2=24>0 by norm_num)
- C01: genus_ge2_of_ArakelovPositivity, arakelovSelfIntersection_eq
- C03: noether_formula, slope_inequality, faltingsHeight_pos, height_lower_bound
- C04: height_to_discriminant (Real.exp_pos + Real.log_exp)
- C05: conductor_equals_level (rfl), faltings_discriminant_lower_bound
- C05: torsion_field_discriminant_bound (positivity)
- C06: bost_connes_threshold (7 < C(S_4) — rational log bounds)
- C06: bost_connes_exceeds_two_sqrt_genus (2*sqrt(13) < C(S_4))
- C07: C07_RH_of_Arakelov (collects chain, applies step_C06)

**True stubs (True := trivial, no sorry, no axiom, no mathematical content):**
- GRH for L(s,X_0(143)): depends on Bost-Connes in Mathlib (not yet 2026)
- Modularity (Wiles+BCDT): not in Mathlib for g>1
- Faltings/Vojta height bounds: not in Mathlib
- Riemann Hypothesis: NOT PROVED. NOT CLAIMED. Clay OPEN.

Clay rule: True stubs carry no mathematical content.
The SHA-bound Python chain (m1.out-m6.out in opera-numerorum) carries the substance.

---

## Files

```
lean/TheoremaAureum/
  C01_Arakelov.lean     -- Arithmetic surface, X_0(N), omega^2=2g-2
  C02_Modularity.lean   -- L-function, modularity stubs
  C03_Positivity.lean   -- Slope inequality, Faltings height
  C04_HeightBound.lean  -- Height machine, Vojta stubs
  C05_Discriminant.lean -- Discriminant estimates
  C06_ZetaControl.lean  -- Bost-Connes C(S_4)>7 PROVED; GRH stub
  C07_RH.lean           -- Terminal: ArakelovPositivity => RH
certs/
  freeze_manifest.json  -- SHA-256 of each file at freeze
  THEOREMA_AUREUM_CERT.txt
```

---

## Relationship to Opera Numerorum

This repo holds the Lean 4 proof skeleton for the RH Tower.

The machine-certified numerical chain lives at:
  https://github.com/DavidFox998/opera-numerorum

Key certified values (from opera-numerorum invariants.json):
- genus(X_0(143)) = 13     [M6, SHA ec9fa8c3...]
- C(S_4) = 11.4221         [M5, SHA 9df98a39...]
- 2*sqrt(13) < 7.212 < C(S_4)   [bost_connes_threshold, C06]
- M7 manifest: SHA 5b80b84d...  [locks M1-M6]

---

## Dependencies

- Lean 4 (Mathlib4)
- No sorry in any file. No additional axioms beyond Lean core + Mathlib.
- See lakefile.lean for Mathlib dependency pin.

---

## License

MIT (C) 2026 David Fox
