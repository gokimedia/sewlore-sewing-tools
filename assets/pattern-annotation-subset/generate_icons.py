"""Rebuild Sewlore's 24 SVGs from original coordinate geometry.

Python 3.9+, standard library only. Outputs icons/light and icons/dark next
to this script. No network, browser, account or publication actions.
Copyright (c) 2026 Sewlore. MIT License; see LICENSE.txt.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)

ICONS = [
    ("grain-direction", "Grain direction", "A two-ended arrow for a documented reference direction.", [
        ("line", (32, 10, 32, 54)),
        ("polyline", [(24, 18), (32, 10), (40, 18)]),
        ("polyline", [(24, 46), (32, 54), (40, 46)])]),
    ("fold-edge", "Fold edge", "A boundary line with two arrows pointing towards it.", [
        ("line", (18, 10, 18, 54)), ("line", (18, 10, 25, 10)), ("line", (18, 54, 25, 54)),
        ("line", (47, 23, 25, 23)), ("polyline", [(31, 17), (25, 23), (31, 29)]),
        ("line", (47, 42, 25, 42)), ("polyline", [(31, 36), (25, 42), (31, 48)])]),
    ("alignment-single", "Single alignment mark", "One V-shaped alignment mark against a reference edge.", [
        ("polyline", [(10, 25), (26, 25), (32, 35), (38, 25), (54, 25)]),
        ("line", (32, 40, 32, 52))]),
    ("alignment-double", "Double alignment mark", "Two V-shaped alignment marks against a reference edge.", [
        ("polyline", [(8, 24), (18, 24), (23, 34), (28, 24), (36, 24), (41, 34), (46, 24), (56, 24)]),
        ("line", (23, 40, 23, 51)), ("line", (41, 40, 41, 51))]),
    ("centre-reference", "Centre reference", "A dashed reference axis and a short transverse centre mark.", [
        ("dashline", (32, 8, 32, 56)), ("line", (20, 32, 44, 32)),
        ("line", (20, 27, 20, 37)), ("line", (44, 27, 44, 37))]),
    ("seam-offset", "Seam offset", "Two parallel angular paths with a perpendicular distance indicator.", [
        ("polyline", [(12, 49), (12, 16), (49, 16)]),
        ("dashpolyline", [(24, 49), (24, 28), (49, 28)]),
        ("line", (36, 16, 36, 28)), ("line", (32, 16, 40, 16)), ("line", (32, 28, 40, 28))]),
    ("cut-edge", "Cut edge", "A continuous angular outline used with an explicit cut-edge label.", [
        ("polyline", [(13, 51), (13, 18), (29, 10), (51, 20), (51, 51)]),
        ("line", (8, 51, 18, 51)), ("line", (46, 51, 56, 51))]),
    ("stitch-path", "Stitch path", "A dashed curved path with distinct start and end markers.", [
        ("dashcurve", ((11, 46), (15, 12), (49, 10), (53, 44))),
        ("ellipse", (8, 43, 14, 49)), ("line", (49, 44, 57, 44)), ("line", (53, 40, 53, 48))]),
    ("drill-reference", "Drill reference", "A circular reference target; not a safe drilling instruction.", [
        ("ellipse", (21, 21, 43, 43)), ("line", (32, 12, 32, 26)),
        ("line", (32, 38, 32, 52)), ("line", (12, 32, 26, 32)), ("line", (38, 32, 52, 32))]),
    ("pleat-pair", "Pleat pair", "A pair of fold references with arrows directed toward the middle.", [
        ("dashline", (22, 12, 22, 52)), ("dashline", (42, 12, 42, 52)),
        ("line", (8, 32, 28, 32)), ("polyline", [(22, 26), (28, 32), (22, 38)]),
        ("line", (56, 32, 36, 32)), ("polyline", [(42, 26), (36, 32), (42, 38)])]),
    ("button-position", "Button position", "A circular button position with two hole references.", [
        ("ellipse", (13, 13, 51, 51)), ("ellipse", (22, 28, 30, 36)),
        ("ellipse", (34, 28, 42, 36)), ("line", (32, 6, 32, 10)), ("line", (32, 54, 32, 58))]),
    ("reference-square", "Reference square", "An uncalibrated square and side indicators for a labelled reference feature.", [
        ("polyline", [(19, 19), (45, 19), (45, 45), (19, 45), (19, 19)]),
        ("line", (19, 10, 45, 10)), ("line", (19, 6, 19, 14)), ("line", (45, 6, 45, 14)),
        ("line", (54, 19, 54, 45)), ("line", (50, 19, 58, 19)), ("line", (50, 45, 58, 45))]),
]

def points_string(points):
    return " ".join(f"{x},{y}" for x, y in points)

def svg_icon(name, title, desc, primitives, colour):
    root = ET.Element(f"{{{NS}}}svg", {"viewBox": "0 0 64 64", "width": "64", "height": "64", "role": "img", "aria-labelledby": f"{name}-title {name}-desc"})
    ET.SubElement(root, f"{{{NS}}}title", {"id": f"{name}-title"}).text = title
    ET.SubElement(root, f"{{{NS}}}desc", {"id": f"{name}-desc"}).text = desc + " Sewlore original illustration; use the supplied legend."
    group = ET.SubElement(root, f"{{{NS}}}g", {"fill": "none", "stroke": colour, "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round"})
    for kind, data in primitives:
        attr = {"stroke-dasharray": "4 4"} if kind.startswith("dash") else {}
        if "line" in kind and "poly" not in kind:
            x1,y1,x2,y2 = data
            ET.SubElement(group, f"{{{NS}}}line", dict(attr, x1=str(x1), y1=str(y1), x2=str(x2), y2=str(y2)))
        elif "polyline" in kind:
            ET.SubElement(group, f"{{{NS}}}polyline", dict(attr, points=points_string(data)))
        elif kind == "ellipse":
            x1,y1,x2,y2 = data
            ET.SubElement(group, f"{{{NS}}}ellipse", {"cx":str((x1+x2)/2), "cy":str((y1+y2)/2), "rx":str((x2-x1)/2), "ry":str((y2-y1)/2)})
        elif "curve" in kind:
            a,b,c,d = data
            ET.SubElement(group, f"{{{NS}}}path", dict(attr, d=f"M {a[0]} {a[1]} C {b[0]} {b[1]} {c[0]} {c[1]} {d[0]} {d[1]}"))
        else:
            raise ValueError(kind)
    return ET.tostring(root, encoding="unicode", xml_declaration=False) + "\n"

def main():
    base = Path(__file__).resolve().parent
    for variant, colour in (("light", "#1b2838"), ("dark", "#f0f5f9")):
        folder = base / "icons" / variant
        folder.mkdir(parents=True, exist_ok=True)
        for name, title, description, primitives in ICONS:
            (folder / (name + ".svg")).write_text(
                svg_icon(name, title, description, primitives, colour),
                encoding="utf-8")

if __name__ == "__main__":
    main()
