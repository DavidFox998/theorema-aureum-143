---
name: BDP bridge tolerance limit
description: Why the κ-power "bridge" relation for the exceptional primes is only verifiable at P5, not the giants.
---

# BDP bridge is computable only at P5

The "bridge" relation `|q·κ^m − p − k·π| < 1` (q∈S₄={2,3,19,191},
κ = φc/108 = 4.84330141945946, **given only to 15 digits**) was floated as a
structural link from the classical set to all 20 exceptional primes of
α₀ = 299 + π/10. It is **not** honestly assertable for the giants.

**Rule:** treat the bridge as VERIFIED only where the propagated κ-uncertainty
`≈ p·m·10⁻¹⁵` (with `m ≈ ln p / ln κ`) stays below 1. That holds at:
- **P1–P4** — trivially: q=p, m=0, k=0 ⟹ error = 0 exactly.
- **P5** (3,993,746,143,633): q=191, m=16, error ≈ 0.038 ± 0.029 ⟹ `< 1` robustly.
- **P6–P20** — uncertainty runs 10^1.9 … 10^3537, so the residue
  `(q·κ^m − p) mod π` is fully indeterminate. Mark **BEYOND_TOLERANCE**, never a pass.

**Why:** with κ to 15 sig figs, `q·κ^m` (~10^(digits of p)) is known to ~15 sig
figs, so for a multi-digit p nothing after the decimal point is known — the mod-π
residue is unknowable. Separately, `k = round(·/π)` forces `|·| ≤ π/2` **by
construction**, so "error<1" is near-vacuous even with exact κ; P5 is the one
tight, computable witness. Getting more digits of κ would make giants *computable*
but still wouldn't make "error<1" a *meaningful* certificate.

**How to apply:** never publish "bridge holds / error<1" for P6–P20. Keep "error
rate" (the measured BDP defect) distinct from "self-symmetry" (the H4 12→1 Coxeter
reading — an interpretation, not a proof). The user's chosen posture is an honest
*mystery*: "do not claim it holds; do not claim it fails." The certified
`data/desert_map.csv` (9 cols, sha256 e0ea8b28…) stays byte-identical; the bridge/
H4/tolerance layer is a separate derived file (`data/desert_map_bridge.csv` +
`artifacts/theorema-certs/src/data/desert-map.json`) built by
`scripts/build_desert_map_site_data.py`.
