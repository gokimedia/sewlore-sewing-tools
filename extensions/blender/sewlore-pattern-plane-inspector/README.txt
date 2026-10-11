Sewlore Pattern Plane Inspector 0.1.0

An offline Blender extension for inspecting flat pattern surface meshes.
Select mesh objects in Object Mode, open the Measurement sidebar, and choose
Inspect Selected Meshes. Set Scene > Units > Unit Scale deliberately: one scene
unit is treated as that many metres, including when the unit system is None.

The extension measures evaluated geometry with object transforms, or the base
mesh when Evaluate Modifiers is disabled. Boundary length includes hole outlines
and disconnected outlines. Surface area comes from Blender's loop-triangle
tessellation in world space, not a bounding rectangle or a triangle fan.
Units use exactly 25.4 mm per inch; square units use the squared conversion.

Plane deviation is the largest absolute distance from the plane of the largest
world-space triangle. This is a reference-plane diagnostic, not a best-fit
plane. Outside-tolerance surfaces still report triangulated surface area; this
must not be interpreted as a flat fabric area. Default tolerance is 0.1 mm.

Reinspect after changing geometry, transforms, modifiers, Unit Scale or tolerance.
Display-unit changes convert the last measurement without altering the mesh.
Results are per object; overlapping pieces are not unioned or de-duplicated.
Self-intersections, overlapping faces and physical printer/cloth behaviour are
not assessed. Closed volumes, loose geometry, duplicate faces, non-manifold edges
and degenerate triangles are rejected instead of producing a misleading result.

Minimum declared version: Blender 5.2.2. The QA guide describes the versions
actually tested; compatibility with earlier versions is not asserted.
No network, telemetry, external Python dependencies, binary assets or commercial
advertisements are included. No additional accounts or services are needed.

Copyright 2026 Sewlore. Code: GNU GPL version 3 or later; see LICENSE.
Documentation URL proposed for publication with this package:
https://gokimedia.github.io/sewlore-sewing-tools/extensions/blender/sewlore-pattern-plane-inspector/
This local preparation does not establish that the proposed URL is already live.
