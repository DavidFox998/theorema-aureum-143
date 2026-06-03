#!/usr/bin/env python3
"""
Z_PROTOCOL_PROOF_DUMP — deterministic (mpmath / integer-rule) artifacts ONLY.

HONESTY CONSTRAINT RESOLUTION
-----------------------------
In this protocol:
  * T=1 = tool / rule path  -> deterministic (mpmath, int(bits,2), literal echo).
  * T=0 = LLM-direct path   -> REQUIRES the Anthropic API (no tool).

The user set "NO APIS. mpmath only", so NO T=0 (LLM) trials can be generated
this run. Every T=0 cell is recorded as NOT_RUN_NO_API and is NEVER fabricated.
The prior digit file (experiments/z-metastability/Z_MEASURE.csv) is, by its own
harness note, the T=1 tool path (printf/${#s}); it is NOT relabeled as T=0.

Because no real T=0 error variance exists and T=1 is deterministic (all errors
0, zero variance), no logistic can be fit: UNIFIED_FIT.json reports R^2 = null
for every module with an explicit reason. No claim is emitted.

Outputs (this dir):
  Z_BESSEL_I_COMPLETE.csv, Z_DIGITS_T0.csv, Z_POLYMER_RESULTS.csv,
  PREDICTION_TEST.csv, UNIFIED_FIT.json
"""
import os, csv, json
from mpmath import mp, besseli, besselj, mpf, nstr
mp.dps = 30

HERE = os.path.dirname(os.path.abspath(__file__))
POLY_CSV = os.path.join(HERE, "..", "z-local", "Z_POLYMER_TEST.csv")
DIGITS_JSON = os.path.join(HERE, "..", "z-metastability", "Z_INPUT_SET.json")
TRIALS = 100
NA = "NOT_RUN_NO_API"  # T=0 needs the LLM API (forbidden this run); not fabricated


def w(path, header, rows):
    with open(path, "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(header)
        wr.writerows(rows)
    print(f"wrote {os.path.basename(path)}: {len(rows)} rows")


# ---- 1. Z_BESSEL_I_COMPLETE: I_n(x), n in {0,1,2,3}, x in {.5,1,2,5,10} ----
def bessel_i():
    ns, xs = [0, 1, 2, 3], [0.5, 1.0, 2.0, 5.0, 10.0]
    rows = []
    for n in ns:
        sym = 1 if n in (0, 1) else 2
        for x in xs:
            v = besseli(n, mpf(repr(x)))
            # T=1 tool: deterministic mpmath, identical across 100 trials -> 0 errors
            rows.append([n, x, sym, 1, "tool_mpmath", TRIALS, 0, "0.0000",
                         nstr(v, 15), ""])
            # T=0 LLM: forbidden under NO-API -> not run, not fabricated
            rows.append([n, x, sym, 0, "LLM_direct", 0, NA, NA, NA,
                         "T=0 requires LLM API (NO-API set)"])
    w(os.path.join(HERE, "Z_BESSEL_I_COMPLETE.csv"),
      ["n", "x", "sym", "T", "method", "trials", "errors", "error_rate",
       "value_15dp", "note"], rows)


# ---- 2. Z_DIGITS_T0: the 50 strings from z-metastability ----
def digits():
    with open(DIGITS_JSON) as f:
        items = json.load(f)
    rows = []
    for e in items:
        s = e["s"]
        sym = "null" if e["sym"] is None else e["sym"]
        # T=1 rule: exact literal reproduction -> 0 errors
        rows.append([s, e["digits"], e["zero_run"], sym, 1, "rule_echo",
                     TRIALS, 0, "0.0000", s, ""])
        # T=0 LLM (what the filename asks for): forbidden -> not run, not fabricated
        rows.append([s, e["digits"], e["zero_run"], sym, 0, "LLM_direct",
                     0, NA, NA, NA, "T=0 requires LLM API (NO-API set)"])
    w(os.path.join(HERE, "Z_DIGITS_T0.csv"),
      ["s", "digits", "zero_run", "sym", "T", "method", "trials", "errors",
       "error_rate", "value", "note"], rows)


# ---- 3. Z_POLYMER_RESULTS: the 100 poly bits, T=0=LLM predict, T=1=rule ----
def polymer():
    with open(POLY_CSV) as f:
        recs = list(csv.DictReader(f))
    rows = []
    for r in recs:
        bits, L, zr = r["bits"], r["L"], r["zero_run"]
        dec = int(bits, 2)
        # T=1 rule: int(bits,2) deterministic -> 0 errors
        rows.append([r["id"], bits, L, zr, 1, 1, "rule_int", TRIALS, 0,
                     "0.0000", dec, ""])
        # T=0 LLM predict: forbidden -> not run, not fabricated
        rows.append([r["id"], bits, L, zr, 1, 0, "LLM_predict", 0, NA, NA, NA,
                     "T=0 requires LLM API (NO-API set)"])
    w(os.path.join(HERE, "Z_POLYMER_RESULTS.csv"),
      ["id", "bits", "L", "zero_run", "sym", "T", "method", "trials", "errors",
       "error_rate", "decimal_value", "note"], rows)


# ---- 4. PREDICTION_TEST: BesselJ_1(0.0), T=0 and T=1 ----
def prediction():
    v = besselj(1, mpf("0"))  # J_1(0) = 0 exactly
    rows = [
        ["besselJ_1", 0.0, 1, "tool_mpmath", TRIALS, 0, "0.0000", nstr(v, 15), ""],
        ["besselJ_1", 0.0, 0, "LLM_direct", 0, NA, NA, NA,
         "T=0 requires LLM API (NO-API set)"],
    ]
    w(os.path.join(HERE, "PREDICTION_TEST.csv"),
      ["fn", "x", "T", "method", "trials", "errors", "error_rate",
       "value_15dp", "note"], rows)


# ---- UNIFIED_FIT.json: honest nulls (no real T=0 variance to fit) ----
def unified_fit():
    reason = ("T=1 deterministic (all errors 0, zero variance); "
              "T=0 NOT_RUN_NO_API (LLM API forbidden) -> no variance to fit")
    mod = lambda: {"t1_error_rate": 0.0, "t0_error_rate": None,
                   "R2": None, "reason": reason}
    obj = {
        "constraint": "NO_API_mpmath_only",
        "t0_status": ("NOT_RUN_NO_API: T=0 = LLM-direct requires the Anthropic "
                      "API, which was forbidden; zero T=0 trials generated; "
                      "none fabricated"),
        "model": "E = (1-T)*sigma(a|Sym-1| + b*zero_run + c*L + d*feature)",
        "modules": {
            "bessel_I": mod(),
            "digits": mod(),
            "polymer": mod(),
            "prediction_besselJ1_0": mod(),
        },
        "unified_R2": None,
        "claim": ("NO CLAIM: no real T=0 (LLM) error data under NO-API; "
                  "T=1 is deterministic with zero variance. R^2 undefined."),
    }
    p = os.path.join(HERE, "UNIFIED_FIT.json")
    with open(p, "w") as f:
        json.dump(obj, f, indent=2)
    print(f"wrote {os.path.basename(p)}")


if __name__ == "__main__":
    bessel_i()
    digits()
    polymer()
    prediction()
    unified_fit()
