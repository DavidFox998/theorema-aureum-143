---
name: Deterministic docs-visual toolchain
description: How to build honesty-locked figures (SVG/PNG) for the proof tower without AI, and the font/glyph + verify gotchas.
---

# Deterministic docs figures (no AI image gen)

The Morning Star project wants its docs figures (e.g. `docs/Wall256_*`,
`docs/H4_*`) built **deterministically** — hand-authored SVG strings + Pillow
PNGs, never AI image generation. Reproducibility is part of the honesty story.

**How to apply:**
- Fonts live at `/usr/share/fonts/truetype/dejavu/` (DejaVuSans.ttf,
  DejaVuSans-Bold.ttf, DejaVuSansMono.ttf). Use these with `ImageFont.truetype`.
- Verify any SVG by rasterizing through an **ephemeral** tool, no project deps:
  `uvx --from cairosvg cairosvg in.svg -o /tmp/x.png`, then `read` the PNG.
  Inspect codepoint coverage with `uvx --from fonttools`.
- **Glyph gotcha:** DejaVu Sans Mono LACKS the long arrows ⟹ (U+27F9) / ⟺
  (U+27FA). Use the short ⇒ (U+21D2) / ⇔ (U+21D4) instead, or render arrows in
  proportional DejaVu Sans (which has them).
- **Footer overflow:** long footers (file list + axiom trio) clip past the SVG
  width / PNG edge — split into two lines rather than shrinking to illegible.
- Supersample PNGs (draw at 2× then `Image.LANCZOS` downscale) for crisp text;
  draw edges on an RGBA overlay with alpha then `alpha_composite` for soft
  overlap (used for the 600-cell projection).

**Honesty review is mandatory** for these figures (architect / code_review):
the hard invariant is they must not overstate what is *formalized* vs
*documentary* vs *open*. See the per-figure source Lean files for the exact
scope; a figure that labels a documentary/hand-computed step as "machine-checked"
is a severe (blocking) issue.

**Whether to keep the generator script:** if a task is explicitly "docs-only /
no other files changed", delete the generator after producing the figures.
Otherwise keeping a deterministic generator (e.g.
`scripts/gen_h4_hypericosahedron.py`) is good — it proves the figure was
computed, not faked.
