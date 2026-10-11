// SPDX-FileCopyrightText: 2026 Sewlore
// SPDX-License-Identifier: MIT
// Original CAD model. Dimensions are millimetres; this is an unprinted prototype.

leg_length = 70;       // Overall X and Y extent, mm
arm_width = 12;        // Both arms, mm
thickness = 3;         // Body height, mm
view_hole_diameter = 4;
engrave_depth = 0.5;
tick_width = 0.6;
tick_offsets = [10, 25, 50]; // Distance along each inner edge from the inside corner
$fn = 64;

assert(leg_length >= 65 && leg_length <= 250, "leg_length must be 65..250 mm");
assert(arm_width >= 8 && arm_width <= 20, "arm_width must be 8..20 mm");
assert(thickness >= 2 && thickness <= 8, "thickness must be 2..8 mm");
assert(view_hole_diameter > 0 && view_hole_diameter < arm_width - 2, "Hole leaves at least 1 mm each side");
assert(engrave_depth > 0 && engrave_depth < thickness / 2, "Engraving must leave the body intact");

module datum_gauge() {
    difference() {
        union() {
            cube([leg_length, arm_width, thickness]);
            cube([arm_width, leg_length, thickness]);
        }
        // Two windows through the body, away from the datum and reference ticks.
        translate([leg_length - 16, arm_width / 2, -1])
            cylinder(h = thickness + 2, d = view_hole_diameter);
        translate([arm_width / 2, leg_length - 16, -1])
            cylinder(h = thickness + 2, d = view_hole_diameter);
        for (offset = tick_offsets) {
            if (arm_width + offset < leg_length - 2) {
                translate([arm_width + offset - tick_width / 2, arm_width - 4, thickness - engrave_depth])
                    cube([tick_width, 4.1, engrave_depth + 1]);
                translate([arm_width - 4, arm_width + offset - tick_width / 2, thickness - engrave_depth])
                    cube([4.1, tick_width, engrave_depth + 1]);
            }
        }
    }
}
datum_gauge();
