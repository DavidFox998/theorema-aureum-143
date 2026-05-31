---
name: Direct-lean verification bypass for towers bricks
description: How to compile/verify a Lean towers brick without lake when the mathlib pin is broken (main-agent git is blocked).
---

# Verifying a towers brick without `lake` (broken mathlib pin)

When the vendored mathlib `v4.12.0` git tag is unresolved (`git -C
lean-proof-towers/.lake/packages/mathlib rev-parse v4.12.0` fails) AND the
worktree is unhydrated, `lake env lean` re-resolves `inputRev: v4.12.0`, fetches
from remote, and WIPES the oleans. The documented recovery (`restore-lake-git.sh`
×2 + recreate the tag) needs `git checkout` / `git tag`, both BLOCKED for the
main agent. So neither `lake` nor the recovery script is usable by main agent.

**But the oleans usually survive** (`.lake/packages/*/.lake/build/lib` +
`.lake/build/lib` for the local Towers). A new brick only needs mathlib's
*oleans*, not its *source*, to elaborate. So bypass lake entirely:

```bash
cd lean-proof-towers
LP=".lake/build/lib"; for d in .lake/packages/*/.lake/build/lib; do LP="$LP:$d"; done
LEAN_PATH="$LP" lean Towers/YM/<File>.lean      # EXIT=0 == compiles
```

The toolchain `lean`/`lake` are on PATH via elan and are already v4.12.0
(`lean-toolchain` = `leanprover/lean4:v4.12.0`), so the kernel/stdlib match the
oleans. Confirm axioms by appending `#print axioms <FullyQualified.name>` lines
(qualify them — they run after `end namespace`), recompile, then revert.

**Why:** this is the only verification path open to the main agent when the pin
is broken; it is non-destructive (no git, no lake re-resolve, oleans untouched).
**How to apply:** before ANY `lake env lean`, assert the tag resolves; if it
doesn't, use the direct-`lean` path above instead and document the brick as
verified-by-direct-lean (not via `check-towers.sh`, which runs the destructive
`lake build`).
