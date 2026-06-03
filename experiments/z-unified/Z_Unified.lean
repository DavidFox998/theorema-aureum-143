/-
  Z_Unified.lean — mathlib-free, computable companion to the unified Z-protocol
  harness (experiments/z-unified/). THREE test functions, one per module.

  HONEST SCOPE (identical contract to the Bessel-Z file)
  ------------------------------------------------------
  For every function:
    * tool = true  [T=1]: tool-assisted — a DETERMINISTIC in-kernel computation.
    * tool = false [T=0]: "LLM generates directly". A Lean kernel cannot call an
      LLM, so we do NOT fabricate a value: we return NaN (0/0) and print a note.
      The real T=0 measurements live in Z_COMM_CHANNEL.csv / Z_POLYMER.csv /
      Z_BOSTCONNES.csv (genuine LLM calls, billed to credits).

  No theorem, no law, no claim is asserted. Lean core only (mathlib OFF);
  no `sorry` / `axiom` / `decide`-claim. Tool paths use truncated/Float series,
  so tool=true values are deterministic APPROXIMATIONS (disclosed), not certified.
-/

namespace ZUnified

/-- log base 2 via natural log. -/
def log2 (x : Float) : Float := Float.log x / Float.log 2.0

/-- Binary entropy H2(p) = -p log2 p - (1-p) log2(1-p), with the endpoint = 0. -/
def H2 (p : Float) : Float :=
  if p == 0.0 || p == 1.0 then 0.0
  else (-p) * log2 p - (1.0 - p) * log2 (1.0 - p)

/-- 1. Z_COMMUNICATIONS_TEST: BSC capacity C(p) = 1 - H2(p) in bits.
    tool=true ⟹ deterministic Float capacity; tool=false ⟹ NaN + note. -/
def commZ (p : Float) (tool : Bool) : IO Float := do
  if tool then
    pure (1.0 - H2 p)
  else
    IO.eprintln s!"[commZ] p={p} tool=false (LLM-direct, T=0): not evaluable \
in-kernel; real data in experiments/z-unified/Z_COMM_CHANNEL.csv. Returning NaN."
    pure (0.0 / 0.0)

/-- decimal value of a list of bits (MSB first), e.g. [1,0,1,1] ↦ 11. -/
def bitsToNat (bits : List Nat) : Nat :=
  bits.foldl (fun acc b => acc * 2 + b) 0

/-- 2. Z_POLYMER_HARNESS: binary polymer config -> base-10 integer.
    tool=true ⟹ exact decimal value (as Float); tool=false ⟹ NaN + note. -/
def polymerZ (bits : List Nat) (tool : Bool) : IO Float := do
  if tool then
    pure (Float.ofNat (bitsToNat bits))
  else
    IO.eprintln s!"[polymerZ] L={bits.length} tool=false (LLM-direct, T=0): not \
evaluable in-kernel; real data in experiments/z-unified/Z_POLYMER.csv. Returning NaN."
    pure (0.0 / 0.0)

/-- Truncated Bost-Connes partition sum Z(β)=ζ(β)=Σ_{k=1}^{terms} k^(-β). -/
def zetaSum (beta : Float) (terms : Nat) : Float :=
  (List.range terms).foldl
    (fun acc k => acc + Float.exp (-beta * Float.log (Float.ofNat (k + 1)))) 0.0

/-- 3. Z_BOST_CONNES_TEST: partition function Z(β)=ζ(β) at KMS temperature β.
    tool=true ⟹ deterministic truncated series (β>1); tool=false ⟹ NaN + note. -/
def bostConnesZ (beta : Float) (tool : Bool) : IO Float := do
  if tool then
    pure (zetaSum beta 100000)
  else
    IO.eprintln s!"[bostConnesZ] beta={beta} tool=false (LLM-direct, T=0): not \
evaluable in-kernel; real data in experiments/z-unified/Z_BOSTCONNES.csv. Returning NaN."
    pure (0.0 / 0.0)

-- ===== #eval lines: T=0 (NaN, no fabrication) and T=1 (deterministic tool) =====

-- COMM: C(0.1) ≈ 0.531004 bits ; C(0.5) = 0
#eval commZ 0.1 false
#eval commZ 0.1 true
#eval commZ 0.5 true

-- POLY: 1011b = 11 ; 10000111b = 135
#eval polymerZ [1,0,1,1] false
#eval polymerZ [1,0,1,1] true
#eval polymerZ [1,0,0,0,0,1,1,1] true

-- BC: truncated 100000-term Σ k^(-β) (tail dropped, NOT exact ζ):
--   β=2 ⇒ 1.644924 (full ζ(2)=π²/6≈1.644934; ~1e-5 short) ; β=3 ⇒ 1.202057 ; β=4 ⇒ 1.082323
#eval bostConnesZ 2.0 false
#eval bostConnesZ 2.0 true
#eval bostConnesZ 3.0 true
#eval bostConnesZ 4.0 true

end ZUnified
