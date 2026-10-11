# SPDX-FileCopyrightText: 2026 Sewlore
# SPDX-License-Identifier: GPL-3.0-or-later
"""Sewlore Pattern Plane Inspector: offline measurement of selected surface meshes."""
import json
import bpy
from bpy.props import BoolProperty, EnumProperty, FloatProperty, PointerProperty, StringProperty
from .geometry import measure, display_values


def inspect_object(obj, scene, depsgraph, use_modifiers=True, tolerance_mm=0.1):
    """Read evaluated geometry and world transforms without changing the source."""
    if obj.type != "MESH":
        raise ValueError("Select mesh objects")
    evaluated = obj.evaluated_get(depsgraph) if use_modifiers else obj
    mesh = evaluated.to_mesh()
    try:
        mesh.calc_loop_triangles()
        points = [tuple(evaluated.matrix_world @ vertex.co) for vertex in mesh.vertices]
        result = measure(
            points,
            [tuple(triangle.vertices) for triangle in mesh.loop_triangles],
            [tuple(polygon.vertices) for polygon in mesh.polygons],
            [tuple(edge.vertices) for edge in mesh.edges],
            scene.unit_settings.scale_length,
            tolerance_mm,
        )
        result.update(name=obj.name, modifiers_evaluated=bool(use_modifiers))
        return result
    finally:
        evaluated.to_mesh_clear()


class SEWLORE_PPI_Properties(bpy.types.PropertyGroup):
    units: EnumProperty(name="Display Units", items=(("MM", "Millimetres", "mm"), ("CM", "Centimetres", "cm"), ("IN", "Inches", "Exact 25.4 mm inch")), default="MM")
    tolerance_mm: FloatProperty(name="Flatness Tolerance (mm)", default=0.1, min=0.0, max=1000.0, precision=3)
    use_modifiers: BoolProperty(name="Evaluate Modifiers", default=True, description="Measure the evaluated mesh instead of the original mesh")
    results_json: StringProperty(default="", options={"HIDDEN"})


class SEWLORE_OT_inspect_pattern_planes(bpy.types.Operator):
    bl_idname = "sewlore.inspect_pattern_planes"
    bl_label = "Inspect Selected Meshes"
    bl_description = "Measure boundary, tessellated surface area and reference-plane deviation"
    @classmethod
    def poll(cls, context):
        return context.mode == "OBJECT" and any(obj.type == "MESH" for obj in context.selected_objects)

    def execute(self, context):
        settings = context.scene.sewlore_pattern_plane_inspector
        depsgraph = context.evaluated_depsgraph_get()
        records = []
        for obj in context.selected_objects:
            if obj.type != "MESH":
                continue
            try:
                records.append(inspect_object(obj, context.scene, depsgraph, settings.use_modifiers, settings.tolerance_mm))
            except (ValueError, RuntimeError) as exc:
                records.append({"name": obj.name, "error": str(exc)})
        settings.results_json = json.dumps(records, ensure_ascii=False, allow_nan=False)
        failures = sum("error" in record for record in records)
        self.report({"WARNING" if failures else "INFO"}, f"Inspected {len(records)} mesh(es); {failures} rejected")
        return {"FINISHED"}


class SEWLORE_PT_pattern_plane_inspector(bpy.types.Panel):
    bl_label = "Pattern Plane Inspector"
    bl_idname = "SEWLORE_PT_pattern_plane_inspector"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Measurement"

    def draw(self, context):
        layout = self.layout
        settings = context.scene.sewlore_pattern_plane_inspector
        layout.prop(settings, "units")
        layout.prop(settings, "tolerance_mm")
        layout.prop(settings, "use_modifiers")
        layout.label(text=f"1 scene unit = {context.scene.unit_settings.scale_length:g} m")
        layout.operator(SEWLORE_OT_inspect_pattern_planes.bl_idname)
        layout.label(text="Reinspect after changing geometry")
        if not settings.results_json:
            return
        records = json.loads(settings.results_json)
        for record in records:
            box = layout.box()
            box.label(text=record["name"])
            if "error" in record:
                box.label(text=record["error"], icon="ERROR")
                continue
            values = display_values(record, settings.units)
            unit = values["unit"]
            box.label(text=f"Boundary: {values['perimeter']:.6g} {unit}")
            box.label(text=f"Surface area: {values['area']:.6g} {unit}²")
            box.label(text=f"Plane deviation: {values['deviation']:.6g} {unit}")
            box.label(text="Within tolerance" if record["within_tolerance"] else "Outside tolerance", icon="CHECKMARK" if record["within_tolerance"] else "ERROR")
            box.label(text=f"{record['face_count']} faces; {record['boundary_edge_count']} boundary edges")


CLASSES = (SEWLORE_PPI_Properties, SEWLORE_OT_inspect_pattern_planes, SEWLORE_PT_pattern_plane_inspector)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)
    bpy.types.Scene.sewlore_pattern_plane_inspector = PointerProperty(type=SEWLORE_PPI_Properties)


def unregister():
    del bpy.types.Scene.sewlore_pattern_plane_inspector
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)
