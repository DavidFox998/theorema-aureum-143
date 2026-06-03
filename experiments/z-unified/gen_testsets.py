#!/usr/bin/env python3
"""
Generate the three Z-protocol test sets (true values from exact/mpmath).

Modules (each input carries the unified-model features):
  COMM  (Z_COMMUNICATIONS_TEST) — BSC capacity C(p)=1-H2(p) bits.
        feature: |Sym-1|. sym is a STIPULATED label: sym=1 if p<=0.25
        ("ordered" low-noise) else sym=2. (label, not derived.)
  POLY  (Z_POLYMER_HARNESS) — binary string -> base-10 integer (a 1D polymer
        config; 0/1 monomers). features: zero_run (longest 0-run), L (length).
  BC    (Z_BOST_CONNES_TEST) — Bost-Connes partition fn Z(beta)=zeta(beta).
        feature: beta_KMS (KMS inverse temperature) = beta.

Outputs: COMM_TEST_SET.json, POLYMER_TEST_SET.json, BOSTCONNES_TEST_SET.json
"""
import os, json, math
from mpmath import mp, zeta, mpf, nstr
mp.dps = 30

HERE = os.path.dirname(os.path.abspath(__file__))


def H2(p):
    if p in (0.0, 1.0):
        return 0.0
    return -p * math.log2(p) - (1 - p) * math.log2(1 - p)


def gen_comm():
    ps = [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.45, 0.5]
    out = []
    for i, p in enumerate(ps):
        sym = 1 if p <= 0.25 else 2
        out.append({"id": f"comm{i}", "p": p, "sym": sym,
                    "true_value": 1.0 - H2(p)})
    return out


def longest_zero_run(s):
    best = cur = 0
    for ch in s:
        cur = cur + 1 if ch == "0" else 0
        best = max(best, cur)
    return best


def gen_poly():
    # (L, zero_run) chosen to DECORRELATE length from zero-run.
    pairs = [(8, 1), (8, 4), (16, 2), (16, 8), (24, 3), (24, 12), (40, 5), (40, 20)]
    out = []
    for i, (L, zr) in enumerate(pairs):
        bits = "1" + "0" * zr + "1" * (L - 1 - zr)
        assert len(bits) == L and longest_zero_run(bits) == zr, (bits, L, zr)
        out.append({"id": f"poly{i}", "bits": bits, "L": L,
                    "zero_run": longest_zero_run(bits), "sym": 1,
                    "true_value": int(bits, 2)})
    return out


def gen_bc():
    betas = [1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0]
    out = []
    for i, b in enumerate(betas):
        v = zeta(mpf(repr(b)))
        out.append({"id": f"bc{i}", "beta_KMS": b, "sym": 1,
                    "true_value": float(v), "true_value_15dp": nstr(v, 15)})
    return out


def main():
    sets = {
        "COMM_TEST_SET.json": gen_comm(),
        "POLYMER_TEST_SET.json": gen_poly(),
        "BOSTCONNES_TEST_SET.json": gen_bc(),
    }
    for fn, data in sets.items():
        with open(os.path.join(HERE, fn), "w") as f:
            json.dump(data, f, indent=2)
        print(f"wrote {fn}: {len(data)} inputs")


if __name__ == "__main__":
    main()
