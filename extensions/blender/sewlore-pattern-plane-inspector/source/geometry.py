# SPDX-FileCopyrightText: 2026 Sewlore
# SPDX-License-Identifier: GPL-3.0-or-later
"""World-space surface measurements; no Blender API or third-party dependency."""
from __future__ import annotations
import math
from collections import Counter

FACTORS = {"MM": 1000.0, "CM": 100.0, "IN": 1.0 / 0.0254}


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def norm(v):
    return math.sqrt(dot(v, v))


def display_values(result, unit):
    """Convert metre-based results, using the exact 25.4 mm international inch."""
    if unit not in FACTORS:
        raise ValueError("Unsupported display unit")
    factor = FACTORS[unit]
    return {
        "perimeter": result["perimeter_m"] * factor,
        "area": result["surface_area_m2"] * factor * factor,
        "deviation": result["max_plane_distance_m"] * factor,
        "unit": {"MM": "mm", "CM": "cm", "IN": "in"}[unit],
    }


def measure(vertices, triangles, polygons, edges, scale_length=1.0, tolerance_mm=0.1):
    """Measure a face mesh already transformed to world space.

    Triangles must come from Blender's native loop-triangle tessellation, not a
    fan triangulation. Boundary lengths include hole and disconnected outlines.
    Flatness is deviation from the largest non-degenerate triangle's plane.
    It is a deterministic reference-plane diagnostic, not a best-fit plane.
    """
    if not math.isfinite(scale_length) or scale_length <= 0:
        raise ValueError("Scene Unit Scale must be finite and positive")
    if not math.isfinite(tolerance_mm) or tolerance_mm < 0:
        raise ValueError("Flatness tolerance must be finite and nonnegative")
    points = [tuple(float(v) for v in p) for p in vertices]
    if not points or any(len(p) != 3 or any(not math.isfinite(v) for v in p) for p in points):
        raise ValueError("Vertices must have three finite coordinates")
    if not polygons or not triangles:
        raise ValueError("Select a mesh with surface faces")
    vertex_count = len(points)
    def valid_indices(indices, minimum):
        if len(indices) < minimum or any(not isinstance(i, int) or i < 0 or i >= vertex_count for i in indices):
            raise ValueError("Invalid face or edge indices")
        if len(set(indices)) != len(indices):
            raise ValueError("A face or edge repeats a vertex")
    used = set()
    face_signatures = set()
    edge_usage = Counter()
    for polygon in polygons:
        valid_indices(polygon, 3)
        signature = tuple(sorted(polygon))
        if signature in face_signatures:
            raise ValueError("Duplicate faces would double-count surface area")
        face_signatures.add(signature)
        used.update(polygon)
        for a, b in zip(polygon, polygon[1:] + polygon[:1]):
            edge_usage[tuple(sorted((a, b)))] += 1
    if used != set(range(vertex_count)):
        raise ValueError("Loose vertices are not part of the pattern surface")
    mesh_edges = set()
    for edge in edges:
        valid_indices(edge, 2)
        mesh_edges.add(tuple(sorted(edge)))
    if mesh_edges != set(edge_usage):
        raise ValueError("Loose or inconsistent edges are not part of the pattern surface")
    if any(count > 2 for count in edge_usage.values()):
        raise ValueError("Non-manifold edges have more than two incident faces")
    boundary = [edge for edge, count in edge_usage.items() if count == 1]
    if not boundary:
        raise ValueError("A closed volume has no pattern boundary")
    minima = [min(p[axis] for p in points) for axis in range(3)]
    maxima = [max(p[axis] for p in points) for axis in range(3)]
    diagonal = norm(sub(maxima, minima))
    if diagonal <= 0 or not math.isfinite(diagonal):
        raise ValueError("Surface has no finite extent")
    length_floor = diagonal * 1e-12
    area_floor = diagonal * diagonal * 1e-14
    lengths = [norm(sub(points[a], points[b])) for a, b in boundary]
    if any(length <= length_floor for length in lengths):
        raise ValueError("Surface has a zero-length boundary edge")
    areas = []
    largest = None
    for tri in triangles:
        valid_indices(tri, 3)
        if len(tri) != 3:
            raise ValueError("Triangulation must contain three-index triangles")
        a, b, c = (points[i] for i in tri)
        vector = cross(sub(b, a), sub(c, a))
        magnitude = norm(vector)
        area = magnitude / 2.0
        if not math.isfinite(area) or area <= area_floor:
            raise ValueError("Surface has a degenerate triangle")
        areas.append(area)
        if largest is None or area > largest[0]:
            largest = (area, a, tuple(v / magnitude for v in vector))
    _, origin, normal = largest
    max_distance = max(abs(dot(sub(p, origin), normal)) for p in points) * scale_length
    return {
        "perimeter_m": math.fsum(lengths) * scale_length,
        "surface_area_m2": math.fsum(areas) * scale_length * scale_length,
        "max_plane_distance_m": max_distance,
        "within_tolerance": max_distance <= tolerance_mm / 1000.0,
        "tolerance_mm": tolerance_mm,
        "vertex_count": vertex_count,
        "face_count": len(polygons),
        "triangle_count": len(triangles),
        "boundary_edge_count": len(boundary),
        "internal_edge_count": sum(count == 2 for count in edge_usage.values()),
        "reference_plane": "largest world-space triangle",
    }
