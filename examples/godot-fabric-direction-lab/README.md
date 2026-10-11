# Fabric Direction & Pattern Placement — Sewlore

A source-based Godot 4 teaching project about the difference between an axis and a direction. The draggable rectangle is a synthetic digital teaching piece. Rotating a piece 180° preserves its grain axis but can reverse a one-way nap or directional print; folding and asymmetric mirroring impose different questions.

## Open the demo

Extract the source ZIP to a new folder and import `project.godot` in Godot 4.3+. Run the project. Drag the rectangle, use the angle slider or On grain/Bias/Half turn buttons, and toggle the one-way nap, mirror or fold requirements. Reset restores the diagram.

The diagram checks rotated corners against the fabric rectangle. It shows the arrow's angular deviation from the warp axis with a default two-degree teaching tolerance. A 45° result is labelled a bias *candidate*, not proof that a real textile behaves appropriately. The left edge-on-fold example is intentionally restricted to the unrotated teaching piece. Screen pixels have no physical dimension; no nesting efficiency, cutting yield, fit or fabric-test claim is made.

## Reuse the geometry helper

`addons/sewlore_fabric_direction/fabric_rules.gd` is an independent RefCounted helper, not an editor plugin. `corners` returns a rotated polygon; `axial_difference` distinguishes an axis from an arrow; `validate` returns booleans, corner geometry and an ordered list of actionable issues. Copy the helper into a teaching app or use the complete demo.

```gdscript
var result = SewloreFabricRules.validate(
    Rect2(0, 0, 400, 500), Rect2(80, 100, 100, 160),
    180.0, 2.0, true # one-way nap enabled
)
assert(result.grain_ok and not result.nap_ok)
```

The source link in the demo opens [Sewlore's measurement methods](https://sewlore.com/pages/fabric-measurement-methods-guide). Further [Sewlore sewing resources](https://sewlore.com/) can help readers keep the observation and its interpretation separate.

## Tests and limits

Run `godot --headless --path . --script res://tests/test_rules.gd` and `godot --headless --path . --script res://tests/test_demo.gd`. The tests exercise the native engine, including button/slider/check signals and digital drag handlers. This is not a claim that a human manually used a tablet or mouse, that a garment was sewn, or that a physical print was calibrated.

## AI disclosure and licence

AI assistance was used to write the GDScript, project structure and documentation. All included diagrams are original procedural source drawings. The project was inspected and exercised with the official native Godot engine. No external AI API, generated photo, telemetry or account connection is included. MIT applies to the code, source drawings and documentation. Store approval and publication have not occurred during local preparation.
