---
name: towers-build merge churn
description: Why the mathlib pin + oleans keep getting wiped on merges, and why the dashboard e2e flakes en masse — both trace to the towers-build workflow.
---

# towers-build is the recurring churn source

On every task merge, workflow reconciliation **restarts already-running
workflows**. `towers-build` (`scripts/check-towers.sh`) is registered as a
persistent workflow, so it restarts on each merge and runs `lake update`
(destructive: re-resolves `inputRev: v4.12.0`, can wipe the mathlib `.git`
tag and the olean cache down to ~1 file). It also self-heals mid-run
(`restore-lake-git` + `lake exe cache get`), but a failed/interrupted run can
leave the towers mathlib oleans wiped (count → 1) even when the tag survives.

**Why this matters (two symptoms, one cause):**
1. The mathlib `v4.12.0` pin / oleans I keep having to restore are wiped by
   *this* workflow's `lake update`, not by anything I did.
2. The theorema-certs Playwright e2e fails *en masse* (uniform "element not
   found" across unrelated specs) when a merge runs the suite while
   towers-build is doing its full `lake build` — pure CPU contention, NOT a real
   regression. Confirm by screenshotting the live dashboard: if it renders fine,
   the e2e failures are contention.

**Diagnostic — `.git` wipe looks like an outer-repo HEAD.** When the churn wipes
the *whole* mathlib `.git` (not just the tag), `git -C
lean-proof-towers/.lake/packages/mathlib rev-parse HEAD` silently walks up to
the **outer** workspace repo and returns *its* HEAD (you'll see the outer repo's
commit message + `main` branch, a SHA that isn't a mathlib commit). The mathlib
worktree files and oleans can still be present. That mismatch (HEAD ≠ manifest
`rev`) is the tell — restore from the vendored tar, don't trust the reported
HEAD.

**How to apply:**
- Don't run `towers-build` casually; it is the churn engine.
- Recovery after a wipe: `restore-lake-git.sh` (×2) → recreate tag
  (`git -C lean-proof-towers/.lake/packages/mathlib tag -f v4.12.0
  809c3fb3b5c8f5d7dace56e200b426187516535a`) → `scripts/fetch-mathlib-oleans.sh`.
- post-merge.sh runs the strict e2e in the **background** (mirrors the
  deep-audit tamper guard) so merges no longer time out or false-fail under
  this contention; the `theorema-certs-e2e` validation workflow is the
  authoritative blocking gate.
- Durable fix (needs user sign-off): stop towers-build auto-restarting on
  merges and/or make check-towers.sh use the non-destructive lake path
  (assert tag → restore → `cache get` → `lake build`, never `lake update`).
