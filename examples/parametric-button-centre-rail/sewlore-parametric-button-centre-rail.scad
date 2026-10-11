// Sewlore Parametric Button-Centre Rail, version 0.1.0.
// Copyright (c) 2026 Sewlore. SPDX-License-Identifier: MIT.
// Original AI-assisted CAD source; see LICENSE and NOTICE.
// Millimetres. Digital prototype; no physical printing or sewing tests.
// This file has no imported geometry, external libraries, fonts or network calls.

/* [Button positions] */
// Spacing derives rail length; Length derives equal centre spacing.
layout_mode = "Spacing"; // [Spacing, Length]
// Number of centre-marking holes (not button diameter).
button_count = 5; // [2:1:20]
// Adjacent centre spacing; used only in Spacing mode (mm).
centre_spacing = 32.5; // [5:0.5:80]
// Overall rail length; used only in Length mode (mm).
rail_length = 160; // [40:0.5:250]
// Left edge to first hole centre (mm).
left_margin = 15; // [4:0.5:40]
// Right edge to last hole centre (mm).
right_margin = 15; // [4:0.5:40]

/* [Rail and marker] */
// Centre-marking aperture diameter, not a finished print tolerance (mm).
guide_diameter = 2.8; // [0.8:0.1:6]
// Rail width; centre-marking holes run down its middle (mm).
rail_width = 18; // [10:0.5:30]
// Flat solid thickness (mm).
rail_thickness = 2.4; // [1.2:0.1:5]
// Outside corner radius, zero for square corners (mm).
corner_radius = 2; // [0:0.5:5]

/* [Hidden] */
$fn = 96;
minimum_wall = 1.5;
cut_overlap = 0.1;
total_length = layout_mode == "Spacing"
    ? left_margin + (button_count - 1) * centre_spacing + right_margin
    : rail_length;
actual_spacing = layout_mode == "Spacing"
    ? centre_spacing
    : (rail_length - left_margin - right_margin) / (button_count - 1);

assert(layout_mode == "Spacing" || layout_mode == "Length",
    "Choose Spacing or Length layout mode.");
assert(button_count == floor(button_count) && button_count >= 2 && button_count <= 20,
    "Button count must be an integer from 2 to 20.");
assert(centre_spacing >= 5 && centre_spacing <= 80,
    "Centre spacing setting must be between 5 and 80 mm.");
assert(rail_length >= 40 && rail_length <= 250,
    "Rail length setting must be between 40 and 250 mm.");
assert(left_margin >= 4 && left_margin <= 40 && right_margin >= 4 && right_margin <= 40,
    "Each edge-to-centre margin must be between 4 and 40 mm.");
assert(guide_diameter >= 0.8 && guide_diameter <= 6,
    "Guide diameter must be between 0.8 and 6 mm.");
assert(rail_width >= 10 && rail_width <= 30,
    "Rail width must be between 10 and 30 mm.");
assert(rail_thickness >= 1.2 && rail_thickness <= 5,
    "Rail thickness must be between 1.2 and 5 mm.");
assert(corner_radius >= 0 && corner_radius <= 5 && 2 * corner_radius < rail_width,
    "Corner radius must be 0 to 5 mm and less than half the rail width.");
assert(total_length >= 40 && total_length <= 250,
    "Resulting rail is outside 40-250 mm. Reduce count/spacing or change margins.");
assert(actual_spacing >= 5 && actual_spacing <= 80,
    "Resulting centre spacing is outside 5-80 mm. Change count, length or margins.");
assert(actual_spacing - guide_diameter >= minimum_wall,
    "Adjacent guide holes must leave at least 1.5 mm of digital material.");
assert(min(left_margin, right_margin, rail_width / 2) - guide_diameter / 2 >= minimum_wall,
    "Guide holes must leave at least 1.5 mm of digital material at rail edges.");
// A corner cannot intersect the end hole because its centre is inward of
// the corner's straight vertical wall. This is a conservative geometric rule.
assert(min(left_margin, right_margin) >= corner_radius + guide_diameter / 2,
    "End-hole margins must clear the rounded corners. Increase margins or reduce radius.");

echo(version="0.1.0", units="mm", length=total_length,
    width=rail_width, thickness=rail_thickness, count=button_count,
    spacing=actual_spacing, hole_diameter=guide_diameter,
    centres=[for (i=[0:button_count-1]) left_margin + i * actual_spacing]);

module outer_plan() {
    if (corner_radius == 0)
        square([total_length, rail_width]);
    else
        translate([corner_radius, corner_radius])
            offset(r=corner_radius)
                square([total_length - 2 * corner_radius,
                        rail_width - 2 * corner_radius]);
}

// All cutters extend beyond both faces to avoid coplanar Boolean artifacts.
module button_centre_rail() {
    difference() {
        linear_extrude(height=rail_thickness) outer_plan();
        for (i=[0:button_count-1])
            translate([left_margin + i * actual_spacing,
                       rail_width / 2, -cut_overlap])
                cylinder(h=rail_thickness + 2 * cut_overlap, d=guide_diameter);
    }
}

button_centre_rail();
