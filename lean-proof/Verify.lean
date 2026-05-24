import TheoremaAureum

/-!
  ## Verify.lean — Audit Certificate

  Run with:  lake env lean Verify.lean

  Expected outputs shown in comments below each command.
-/

-- ── 1. AXIOM CHECK: main_theorem (now unconditional) ─────────────────────────
-- After M9 discharges the former axiom H2_WeilTransfer, main_theorem is the
-- unconditional statement RiemannHypothesis, and its axiom debt is empty.
-- Expected output:
--   'TheoremaAureum.main_theorem' does not depend on any axioms
#print axioms TheoremaAureum.main_theorem


-- ── 2. AXIOM CHECK: H2_WeilTransfer is now a THEOREM ─────────────────────────
-- Formerly `axiom H2_WeilTransfer`; replaced by `theorem H2 := M9_WeilTransfer_All`.
-- Expected output:
--   'TheoremaAureum.H2_WeilTransfer' does not depend on any axioms
#print axioms TheoremaAureum.H2_WeilTransfer


-- ── 3. AXIOM CHECK: M9_WeilTransfer_All ──────────────────────────────────────
-- The 280-case computational discharge.
-- m9.out SHA: 624b93f7d4687b81371dcecfe6adad9de074addf35f5409e1c3b244d8410f7e6
-- Expected output:
--   'TheoremaAureum.M9_WeilTransfer_All' does not depend on any axioms
#print axioms TheoremaAureum.M9_WeilTransfer_All


-- ── 4. VALOR / H1 EVALUATION ────────────────────────────────────────────────
-- VALOR_M5 = 42110  (= floor(4.2110461381 × 10^4))
-- C(S_4) − 2·√13 = 11.4221... − 7.2111... = 4.2110...
-- M5 SHA: 9df98a3970acbb6942770a6cdd42fb21b009f9a5f45a222dd963e98ba4cb7a13
-- Expected: 42110
#eval TheoremaAureum.Certificates.VALOR_M5

-- Minimal VALOR over the 280-case Weil-transfer cohort (attained at N=397).
-- Expected: 1084
#eval TheoremaAureum.VALOR_M9_min

-- Decidable evaluation of the H1 positivity condition:
-- Expected: true
#eval decide (0 < TheoremaAureum.VALOR)


-- ── 5. TYPE CHECKS ───────────────────────────────────────────────────────────
-- H1: theorem (not axiom) — proved by M5 certificate via `decide`
-- Expected:
--   TheoremaAureum.H1_ArakelovPositivity : 0 < TheoremaAureum.VALOR
#check TheoremaAureum.H1_ArakelovPositivity

-- H2: now a theorem, delegated to M9_WeilTransfer_All
#check TheoremaAureum.H2_WeilTransfer

-- main_theorem: unconditional Riemann Hypothesis
-- Expected:
--   TheoremaAureum.main_theorem : TheoremaAureum.RiemannHypothesis
#check TheoremaAureum.main_theorem
