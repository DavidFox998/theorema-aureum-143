#!/usr/bin/env python3
"""
w1_repo_normalization.py
Single-plaquette SU(3) Haar weight under the REPO action normalization:
    w1(beta) = integral_{SU(3)} exp(-beta * S(U)) d haar(U)
    S(U) = plaquetteEnergy(U) = (3 - Re tr U)/3 = 1 - (Re tr U)/3
(Towers/YM/WilsonPositivity.lean:27 ; Towers/YM/WilsonAction.lean:134).

Method: deterministic Weyl integration over the SU(3) maximal torus.
  eigenangles t1,t2,t3 = -t1-t2 ; Re tr U = cos t1 + cos t2 + cos t3 ;
  Weyl density |Delta|^2 = prod_{j<k} (2 - 2 cos(tj - tk)) ;
  w1(beta) = (integral exp(-beta S) |Delta|^2) / (integral |Delta|^2)  [self-normalized].

VALIDATION (n=2400): w1(0)=1.000000 ; w1(0.86)=0.432367
  (Monte Carlo, 2e6 Haar-SU(3) draws, gives 0.4324 -> agree).
RESULT: minimal beta0 with w1(beta0)=1/7 is beta0 ~= 2.07942.
  => w1(0.86)=0.4324 > 1/7 : D4 FAILS at beta=0.86 under repo action.

OUT-OF-TOWER: numerical only; NOT a Lean object, NOT trio-clean, NOT a rigorous
(Arb/MPFI) interval certificate. Establishes only a numerical estimate.
"""
import numpy as np


def build_grid(n=2400):
    t = np.linspace(-np.pi, np.pi, n, endpoint=False)
    dt = 2 * np.pi / n
    T1, T2 = np.meshgrid(t, t, indexing="ij")
    T3 = -T1 - T2
    chord = lambda a: 2 - 2 * np.cos(a)
    D2 = chord(T1 - T2) * chord(T1 - T3) * chord(T2 - T3)   # |Delta|^2
    S = 1 - (np.cos(T1) + np.cos(T2) + np.cos(T3)) / 3.0    # repo plaquetteEnergy
    return S, D2, dt


S, D2, DT = build_grid()
Z = np.sum(D2) * DT * DT


def w1(beta):
    return float(np.sum(np.exp(-beta * S) * D2) * DT * DT / Z)


def beta0(target=1.0 / 7.0, lo=0.5, hi=8.0, iters=80):
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if w1(mid) < target:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


def mc_check(n=2_000_000, beta=0.86, seed=0):
    """Optional independent Monte-Carlo validation over Haar SU(3)."""
    rng = np.random.default_rng(seed)
    Zc = (rng.standard_normal((n, 3, 3)) + 1j * rng.standard_normal((n, 3, 3))) / np.sqrt(2)
    Q, R = np.linalg.qr(Zc)
    d = np.einsum("...ii->...i", R)
    Q = Q * (d / np.abs(d))[:, None, :]
    U = Q / (np.linalg.det(Q) ** (1 / 3))[:, None, None]
    Re = np.einsum("...ii->...", U).real
    return float(np.mean(np.exp(-beta * (1 - Re / 3.0))))


if __name__ == "__main__":
    assert abs(w1(0.0) - 1.0) < 1e-6, "normalization check failed"
    print("w1(0)      =", round(w1(0.0), 6), "(must be 1.0)")
    print("w1(0.86)   =", round(w1(0.86), 6), " < 1/7 ?", w1(0.86) < 1 / 7)
    b0 = beta0()
    print("1/7        =", 1 / 7)
    print("minimal beta0 (repo action) =", round(b0, 5))
    print("w1(beta0)  =", round(w1(b0), 6), "; w1(beta0+0.01) =", round(w1(b0 + 0.01), 6))
    # print("MC w1(0.86) =", round(mc_check(), 6))  # uncomment for the 2e6-draw cross-check
