# Rectangular area and two side reductions

![Two rectangles at the same scale show why reducing width by 10% and height by 5% reduces area by 14.5%, with the shared removed corner highlighted.](rectangular-area-two-axis-change.svg)

This original vector diagram explains an elementary area calculation. Both rectangles use the same drawing scale: one arbitrary unit is four SVG units. The dashed boundary in the right panel shows the original rectangle, the blue region shows the remaining rectangle, and the hatched corner shows the overlap between the two removed strips. The numbers are illustrative mathematical values, not measurements of a physical sample.

## Calculation

The original rectangle is 100 × 100 units, so its area is 10,000 square units. A 10% width reduction leaves 90 units, and a 5% height reduction leaves 95 units. The remaining area is:

`90 × 95 = 8,550 square units`

The removed area is 1,450 square units. As a percentage of the original area:

`(10,000 − 8,550) ÷ 10,000 × 100 = 14.5%`

The same result follows from multiplying the retained side fractions: `0.90 × 0.95 = 0.855`, or 85.5% of the original area retained.

Adding the two side reductions gives 15%, which counts their common corner twice. The width strip has area `10 × 100 = 1,000`; the height strip has area `5 × 100 = 500`. Their overlap has area `10 × 5 = 50`, or 0.5% of the original area. Subtracting that double count gives `1,000 + 500 − 50 = 1,450`. Thus the correction to the additive estimate is **0.5 percentage points**: `15% − 0.5 percentage points = 14.5%`.

More generally, for fractional side reductions `a` and `b`, the area reduction is `a + b − ab`. This identity describes rectangular geometry; it does not establish how any material behaves.

## Source, provenance and license

- SVG source: [rectangular-area-two-axis-change.svg](rectangular-area-two-axis-change.svg), 1400 × 1180 SVG units. It contains its own accessible title and description, with no scripts, external assets, logos or product links.
- Generated programmatically with AI-assisted code using **OpenAI Codex**; prepared for Sewlore. The vector source, explanatory text and supporting checks were prepared with that assistance. No human visual author is claimed, and no exact model version is asserted.
- This is a digital mathematical illustration. It contains no photograph, physical fabric test, laboratory result or measured dataset.
- This new SVG and its accompanying explanation are distributed under the repository's [MIT license](../LICENSE), including the notice **Copyright (c) 2026 Sewlore**, for any applicable copyright. That notice is not a claim that purely algorithmic or AI-generated material necessarily has copyright protection, nor a claim of exclusive human authorship.

Any reuse should retain the applicable MIT notice and describe the programmatic, AI-assisted provenance accurately. A prospective Wikimedia Commons contribution is separate from this source distribution and must follow Commons' current licensing and AI disclosure requirements.
