# Sewlore Pattern Annotation Subset

Version 1.0.0 · 12 original symbols · 24 SVG files

Small reference illustrations for vector layouts, teaching sheets and sewing-pattern documentation. Light and dark variants share the same geometry. Each icon has a plain-language title and description. These marks need the supplied legend; no standardized care-label, ISO or AATCC compliance is claimed.

## Download and use

1. Open `icons/light/` for dark strokes on light paper or `icons/dark/` for pale strokes on a dark background. Download the required SVG. The repository's Code → Download ZIP command also includes this folder.
2. Import the SVG into an SVG-capable editor and resize proportionally. The 64-unit viewBox defines geometry, not millimetres or inches.
3. Keep an explanatory label beside it. Follow the actual pattern's own instructions; state dimensions, cut counts and seam allowances in text.
4. Inspect your exported page at its final size. The reference-square icon has no calibrated physical dimension and cannot test a printer's scale.

[Open the visual legend](index.html) or see the machine-readable `icon-map.json`. SVGs contain only geometry, title/description and explicit stroke colours: no fonts, scripts, tracking or external resources. Stroke widths scale with the artwork. Add suitable alternative text to exported bitmaps.

## Legend

- **Grain direction** (`grain-direction.svg`): A two-ended arrow for a documented reference direction.
- **Fold edge** (`fold-edge.svg`): A boundary line with two arrows pointing towards it.
- **Single alignment mark** (`alignment-single.svg`): One V-shaped alignment mark against a reference edge.
- **Double alignment mark** (`alignment-double.svg`): Two V-shaped alignment marks against a reference edge.
- **Centre reference** (`centre-reference.svg`): A dashed reference axis and a short transverse centre mark.
- **Seam offset** (`seam-offset.svg`): Two parallel angular paths with a perpendicular distance indicator.
- **Cut edge** (`cut-edge.svg`): A continuous angular outline used with an explicit cut-edge label.
- **Stitch path** (`stitch-path.svg`): A dashed curved path with distinct start and end markers.
- **Drill reference** (`drill-reference.svg`): A circular reference target; not a safe drilling instruction.
- **Pleat pair** (`pleat-pair.svg`): A pair of fold references with arrows directed toward the middle.
- **Button position** (`button-position.svg`): A circular button position with two hole references.
- **Reference square** (`reference-square.svg`): An uncalibrated square and side indicators for a labelled reference feature.

## Editable source and checks

`generate_icons.py` contains the original coordinates and uses Python's standard library. Running `python generate_icons.py` regenerates all 24 SVGs beside the script. The SVGs were XML-checked, and the regenerated files were compared byte-for-byte with the supplied files. The contact sheets were rendered from the same geometry. No native vector-editor import or physical print test has been performed; inspect compatibility and final output in your own application.

The coordinate geometry and documentation were prepared with AI assistance. No third-party icon set, font outline, existing desktop theme or protected care-label artwork was traced. This is an illustration subset with a legend, rather than a complete desktop theme.

## Recording context

The [Sewlore fabric measurement methods guide](https://sewlore.com/pages/fabric-measurement-methods-guide) explains why direction, dimension, unit and comparison method should accompany a reading. It does not standardize these symbols. [Sewlore's annotation resource page](https://sewlore.com/pages/pattern-annotation-symbols) explains the subset and links to these source files.

## Licence

MIT License; see `LICENSE.txt`. Retain its copyright and permission notice when redistributing copies or substantial portions. The licence grants no trademark rights in the Sewlore name or marks.
