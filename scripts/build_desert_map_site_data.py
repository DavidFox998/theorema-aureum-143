#!/usr/bin/env python3
"""Build the DERIVED bridge / H4 / tolerance layer for the Desert Map site.

This reads the CERTIFIED, FROZEN data/desert_map.csv (the 9-column deliverable,
left byte-identical) and computes a separate, reproducible derived layer:

  - The BDP "bridge" witness  |q*kappa^m - p - k*pi| < 1  with kappa to 15
    digits (kappa = phi_c/108 = 4.84330141945946).  HONESTY: this is only
    computable where the propagated kappa-uncertainty (~ p*m*1e-15) stays below
    1.  That holds ONLY at P5 (and trivially at P1-P4 where q=p, m=0 => error
    =0).  For P6-P20 the residue (q*kappa^m - p) mod pi is fully indeterminate
    at 15-digit kappa -- it is recorded as BEYOND_TOLERANCE, never as a pass.
    Even with exact kappa, k = round(./pi) forces |.| <= pi/2 by construction,
    so "error<1" is near-trivial; P5 is the one tight, computable witness.

  - The H4 12->1 "self-symmetry" classification (a Coxeter reading, NUMERICAL,
    NOT derived, NOT a proof): 12 active axes on the classical set P1-P4, 1 on
    the post-boundary P5-P20.  The 4 classical invariants I_k = log(p_k)/(p_k-1)
    are real; the other 8 axes are zero (only 4 primes carry all 12 symmetries).

Writes:
  - data/desert_map_bridge.csv          (derived layer, additive, separate file)
  - artifacts/theorema-certs/src/data/desert-map.json  (bundle for the web page)

Run from repo root:  python3 scripts/build_desert_map_site_data.py
Requires: mpmath.
"""
import sys, json, hashlib, math
sys.set_int_max_str_digits(2_000_000)
from mpmath import mp, mpf, log as mlog, pi as mpi, nint, nstr

mp.dps = 80  # ample for P5 (191*kappa^16 ~ 1.75e13); giants are not evaluated

KAPPA_STR = "4.84330141945946"        # phi_c / 108, to 15 digits (as given)
KAPPA = mpf(KAPPA_STR)
KAPPA_DIGITS = 15
BOUND = "7.21110255"                   # 2*sqrt(13), the classical bound
S4 = [2, 3, 19, 191]
SINGLE_AXIS = mpf(BOUND) / 12          # 0.600925...

CSV = "data/desert_map.csv"


def htail(n, head=20, tail=14, full_below=46):
    s = str(n)
    if len(s) <= full_below:
        return s
    return f"{s[:head]}\u2026{s[-tail:]}"


def read_certified():
    lines = open(CSV).read().splitlines()
    hdr = lines[0].split(",")
    col = {name: i for i, name in enumerate(hdr)}
    rows = []
    for ln in lines[1:]:
        if ln.strip():
            c = ln.split(",")
            rows.append({k: c[i] for k, i in col.items()})
    return rows


def kappa_uncertainty_log10(p, m):
    """log10 of the absolute uncertainty in q*kappa^m from a 15-digit kappa.

    rel. error of kappa ~ 0.5e-15; rel. error of kappa^m ~ m * that; absolute
    ~ |q*kappa^m| * m * 0.5e-15, and |q*kappa^m| ~ p.  Returns log10(abs unc).
    """
    return math.log10(p) + math.log10(max(m, 1)) + math.log10(0.5e-15)


def p5_bridge(p5):
    """The one computable, tight witness: q=191, m=16."""
    q, m = 191, 16
    val = mpf(q) * KAPPA ** m              # 191 * kappa^16
    k = int(nint((val - p5) / mpi))        # nearest multiple of pi
    err = abs(val - p5 - k * mpi)
    # tolerance: d(q*kappa^m) from a 0.5e-15 wobble in kappa
    tol = mpf(q) * m * KAPPA ** (m - 1) * mpf("0.5e-15")
    return q, m, k, err, tol


def main():
    rows = read_certified()
    assert len(rows) == 20

    csv_sha = hashlib.sha256(open(CSV, "rb").read()).hexdigest()
    p5v = int(rows[4]["prime_exact"])
    q5, m5, k5, err5, tol5 = p5_bridge(p5v)
    err5_ratio = err5 / p5v

    # 4 real classical H4 invariants I_k = log(p)/(p-1)
    invariants = []
    for axis, p in enumerate(S4, start=1):
        invariants.append({
            "axis": axis, "prime": p,
            "value": nstr(mlog(p) / (p - 1), 6),
        })
    sumI = sum((mlog(p) / (p - 1) for p in S4), mpf(0))
    kappa_axis_p5 = (mlog(191) / (191 - 1)) * KAPPA ** 16  # I_4 * kappa^16

    out_primes = []
    derived_csv = [
        "k,regime,H4_axes_active,bdp_q,bdp_m,bdp_k,"
        "bdp_error,bdp_error_ratio,bdp_tolerance_log10,bdp_kappa_digits,bdp_status"
    ]
    for r in rows:
        k = int(r["k"])
        p = int(r["prime_exact"])
        dig = int(r["digits"])
        if k <= 4:
            regime, axes = "Classical-Z", 12
            q, m, kk = p, 0, 0
            err, ratio, tol_l10 = "0", "0", ""
            status = "EXACT"
        elif k == 5:
            regime, axes = "Bridge", 1
            q, m, kk = q5, m5, k5
            err = nstr(err5, 6)
            ratio = nstr(err5_ratio, 4)
            tol_l10 = f"{float(mp.log10(tol5)):.2f}"
            status = "VERIFIED"
        else:
            regime, axes = "Desert", 1
            m_est = round(float(mlog(p) / mlog(KAPPA)))
            q, m, kk = "", "", ""
            err, ratio = "", ""
            tol_l10 = f"{kappa_uncertainty_log10(p, m_est):.1f}"
            status = "BEYOND_TOLERANCE"

        derived_csv.append(",".join(str(x) for x in [
            k, regime, axes, q, m, kk, err, ratio, tol_l10, KAPPA_DIGITS, status]))

        out_primes.append({
            "k": k,
            "digits": dig,
            "display": htail(p),
            "full": str(p),
            "gap_from_prev": r["gap_from_prev"],
            "desert_width": r["desert_width"],
            "desert_width_display": htail(int(r["desert_width"])) if r["desert_width"] != "0" else "0",
            "r": r["r"],
            "c_unwt_cum": r["C_unwt_cum"],
            "c_wt_cum": r["C_wt_cum"],
            "regime": regime,
            "h4_axes_active": axes,
            "bdp": {
                "q": q if q != "" else None,
                "m": m if m != "" else None,
                "k": str(kk) if kk != "" else None,
                "error": err if err != "" else None,
                "error_ratio": ratio if ratio != "" else None,
                "tolerance_log10": tol_l10 if tol_l10 != "" else None,
                "status": status,
            },
        })

    bundle = {
        "meta": {
            "kappa": KAPPA_STR,
            "kappa_digits": KAPPA_DIGITS,
            "bound_2sqrt13": BOUND,
            "single_axis_bound": nstr(SINGLE_AXIS, 6),
            "classical_set": S4,
            "c_unwt_s4": rows[3]["C_unwt_cum"],
            "c_unwt_s20": rows[19]["C_unwt_cum"],
            "c_wt_s4": rows[3]["C_wt_cum"],
            "c_wt_s5": rows[4]["C_wt_cum"],
            "c_wt_s20": rows[19]["C_wt_cum"],
            "sum_classical_invariants": nstr(sumI, 6),
            "kappa_axis_p5": nstr(kappa_axis_p5, 7),
            "p5": str(p5v),
            "p5_desert_width": rows[4]["desert_width"],
            "certified_csv_sha256": csv_sha,
        },
        "classical_invariants": invariants,
        "primes": out_primes,
    }

    open("data/desert_map_bridge.csv", "w").write("\n".join(derived_csv) + "\n")
    out_json = "artifacts/theorema-certs/src/data/desert-map.json"
    import os
    os.makedirs(os.path.dirname(out_json), exist_ok=True)
    open(out_json, "w").write(json.dumps(bundle, indent=2) + "\n")

    print(f"# certified CSV sha256 = {csv_sha}  (UNCHANGED)")
    print(f"# kappa = {KAPPA_STR}  ({KAPPA_DIGITS} digits)")
    print(f"# P5 bridge: q={q5}, m={m5}, k={k5}")
    print(f"#   191*kappa^16 - P5 - k*pi = {nstr(err5, 8)}  +/- {nstr(tol5, 3)}  (< 1 robustly)")
    print(f"#   error_ratio = error/P5 = {nstr(err5_ratio, 4)}")
    print(f"# kappa_axis(P5) = I_4 * kappa^16 = {nstr(kappa_axis_p5, 8)}  > single-axis {nstr(SINGLE_AXIS,6)}")
    print(f"# sum of 4 classical invariants = {nstr(sumI, 7)}  < {BOUND}")
    print(f"# WROTE data/desert_map_bridge.csv  +  {out_json}")


if __name__ == "__main__":
    main()
