Paper Pattern Tile Corner Datum Gauge 0.1.0 — Sewlore

An original L-shaped reference for checking the square trimmed corner of a
paper-pattern tile. This is an unprinted CAD prototype, not a cutting guide or
a certified calibration instrument. Place the two inside edges against the
tile corner on a flat support. Check the printed pattern's test square with an
independent ruler before assembling any tiles; this gauge does not fix scale.

CAD dimensions (millimetres):
  70 x 70 x 3 overall; both arms are 12 wide.
  Inside datum corner at (12,12).
  Top-face ticks 10,25,50 along each arm from the inside corner, 0.5 deep.
  Two through-windows, diameter 4; centres (54,6) and (6,54).

STL does not encode length units. Import as MILLIMETRES, then independently check
the slicer reports 70 x 70 x 3 mm. The SVG/PNG dimension drawing is explanatory;
it is not a one-to-one paper template.

Use the included editable OpenSCAD source to change leg_length, arm_width,
thickness, view_hole_diameter, engrave_depth and tick_offsets. OpenSCAD assertions
reject invalid ranges. OpenSCAD 2021.01 native export was used for this release.
Rebuild: openscad -o gauge.stl paper_pattern_tile_corner_datum_gauge.scad

The exact STL was checked for closed edges, consistent winding, one connected
body, zero degenerate triangles, two through-hole tunnels and 70 x 70 x 3 mm
bounds. It has 636 triangles. CAD rendering and topology checks are not physical
print, dimensional tolerance, paper-alignment or material testing.

No slicer/material/temperature recipe is claimed to have been tested. A user who
prints an adaptation must choose their own settings, measure it and document
the actual result. No images supplied here show a physical printed object.

Copyright 2026 Sewlore. Source: MIT. CAD outputs and guide: CC BY 4.0.
See the two included licence files for scope and terms.
Sewlore sewing references: https://sewlore.com/
