"""Create deterministic reference PDFs and explicitly programmatic detector controls.

These outputs are NOT native browser or printer measurements. Real native output
must be captured separately in incoming/ and accompanied by a settings receipt.
"""
from __future__ import annotations
import csv
import hashlib
import io
import json
from pathlib import Path

from reportlab.pdfgen import canvas
from reportlab.lib.units import mm, inch
from reportlab.lib.colors import HexColor
from pypdf import PdfReader, PdfWriter, Transformation

ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT / "fixtures"
CONTROLS = ROOT / "controls-programmatic"
PAPER_MM = {"a4": (210.0, 297.0), "letter": (215.9, 279.4)}
MARKERS = {
    "metric-square": {"rgb": [0.0, 0.45, 0.38], "width_mm": 100.0, "height_mm": 100.0},
    "inch-rectangle": {"rgb": [0.07, 0.31, 0.59], "width_mm": 50.8, "height_mm": 25.4},
    "long-horizontal": {"rgb": [0.80, 0.35, 0.02], "width_mm": 180.0, "height_mm": 0.0},
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def reference(paper: str) -> Path:
    width, height = PAPER_MM[paper]
    path = REFERENCE / f"sewlore-print-geometry-{paper}.pdf"
    c = canvas.Canvas(str(path), pagesize=(width * mm, height * mm), invariant=1, pageCompression=1)
    c.setTitle(f"Sewlore PDF Geometry Reference - {paper.upper()}")
    c.setAuthor("Sewlore")
    c.setSubject("Known vector geometry; digital reference, not a physical printer test")
    c.setCreator("Sewlore deterministic ReportLab reference generator v1")
    c.setFillColor(HexColor("#18332E"))
    c.setFont("Helvetica-Bold", 18)
    c.drawString(20 * mm, (height - 23) * mm, "SEWLORE / PDF GEOMETRY")
    c.setFont("Helvetica", 10)
    c.drawString(20 * mm, (height - 32) * mm, f"{paper.upper()} reference | {width:g} x {height:g} mm | version 1.0")
    c.setFont("Helvetica", 9)
    c.drawString(20 * mm, (height - 42) * mm, "Measure path centre lines. Screen zoom does not establish printed size.")
    c.drawString(20 * mm, (height - 48) * mm, "Digital fixture only. Validate your own physical print with a ruler.")

    x, y = 30 * mm, 110 * mm
    c.setStrokeColorRGB(*MARKERS["metric-square"]["rgb"])
    c.setLineWidth(0.45)
    c.rect(x, y, 100 * mm, 100 * mm, fill=0, stroke=1)
    c.setFillColor(HexColor("#18332E"))
    c.setFont("Helvetica-Bold", 12)
    c.drawString(x + 10 * mm, y + 53 * mm, "100 mm x 100 mm")
    c.setFont("Helvetica", 9)
    c.drawString(x + 10 * mm, y + 45 * mm, "Green path: metric-square")
    c.drawString(x + 10 * mm, y + 38 * mm, "Width and height are separate checks.")

    x2, y2 = 30 * mm, 69 * mm
    c.setStrokeColorRGB(*MARKERS["inch-rectangle"]["rgb"])
    c.rect(x2, y2, 2 * inch, inch, fill=0, stroke=1)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(90 * mm, 85 * mm, "2 in x 1 in")
    c.setFont("Helvetica", 9)
    c.drawString(90 * mm, 79 * mm, "50.8 mm x 25.4 mm")
    c.drawString(90 * mm, 73 * mm, "Blue path: inch-rectangle")

    c.setStrokeColorRGB(*MARKERS["long-horizontal"]["rgb"])
    c.line(15 * mm, 48 * mm, 195 * mm, 48 * mm)
    c.setFillColor(HexColor("#18332E"))
    c.setFont("Helvetica", 9)
    c.drawCentredString(105 * mm, 42 * mm, "Orange path: long-horizontal | 180 mm")
    c.setStrokeColor(HexColor("#97AAA4"))
    c.setLineWidth(0.3)
    c.rect(5 * mm, 5 * mm, (width - 10) * mm, (height - 10) * mm, fill=0, stroke=1)
    c.setFont("Helvetica", 7)
    c.drawString(20 * mm, 21 * mm, "Inset border: 5 mm from each source page edge. Inspect clipping visually.")
    c.drawString(20 * mm, 16 * mm, "Methods: sewlore.com/pages/printing-assembly")
    c.linkURL("https://sewlore.com/pages/printing-assembly", (20 * mm, 14 * mm, 139 * mm, 20 * mm), relative=0)
    c.showPage()
    c.save()
    return path

def transformed(source: Path, name: str, sx: float, sy: float, target_paper: str) -> Path:
    reader = PdfReader(source)
    page = reader.pages[0]
    src_w, src_h = float(page.mediabox.width), float(page.mediabox.height)
    target_w, target_h = (value * mm for value in PAPER_MM[target_paper])
    transform = Transformation().scale(sx, sy).translate((target_w - src_w * sx) / 2, (target_h - src_h * sy) / 2)
    page.add_transformation(transform, expand=False)
    # Calibration controls have no active links; avoid stale annotation coordinates.
    page.pop("/Annots", None)
    page.mediabox.upper_right = (target_w, target_h)
    page.cropbox.lower_left = (0, 0)
    page.cropbox.upper_right = (target_w, target_h)
    # Make the origin and altered dimensions unmistakable on the downloaded PDF.
    # This overlay is outside the uniquely colored measurement geometry.
    overlay_stream = io.BytesIO()
    overlay = canvas.Canvas(overlay_stream, pagesize=(target_w, target_h), invariant=1)
    overlay.setFillColorRGB(1, 1, 1)
    overlay.rect(0, target_h - 31 * mm, target_w, 31 * mm, fill=1, stroke=0)
    overlay.setFillColor(HexColor("#18332E"))
    overlay.setFont("Helvetica-Bold", 11)
    overlay.drawString(15 * mm, target_h - 12 * mm, f"PROGRAMMATIC CONTROL | width {sx * 100:.4f}% | height {sy * 100:.4f}%")
    overlay.setFont("Helvetica", 8)
    overlay.drawString(15 * mm, target_h - 19 * mm, "Known software transform. NOT native browser output or a physical printer result.")
    overlay.drawString(15 * mm, target_h - 25 * mm, "Labels below describe original source geometry; paths have been transformed.")
    overlay.save()
    overlay_stream.seek(0)
    page.merge_page(PdfReader(overlay_stream).pages[0])
    writer = PdfWriter()
    writer.add_page(page)
    writer.add_metadata({"/Title": f"Sewlore PROGRAMMATIC CONTROL - {name}", "/Author": "Sewlore", "/Producer": "Sewlore pypdf control generator", "/Subject": "Known software transform; NOT browser output or physical printer result"})
    path = CONTROLS / f"{name}.pdf"
    with path.open("wb") as stream:
        writer.write(stream)
    return path

def main() -> None:
    for folder in (REFERENCE, CONTROLS, ROOT / "incoming", ROOT / "results", ROOT / "qa-renders"):
        folder.mkdir(parents=True, exist_ok=True)
    refs = {paper: reference(paper) for paper in PAPER_MM}
    specs = [
        ("a4-uniform-95-percent", "a4", .95, .95, "a4"),
        ("letter-uniform-95-percent", "letter", .95, .95, "letter"),
        ("a4-anisotropic-96x104-percent", "a4", .96, 1.04, "a4"),
        ("a4-to-letter-whole-paper-fit-model", "a4", min(215.9 / 210, 279.4 / 297), min(215.9 / 210, 279.4 / 297), "letter"),
    ]
    entries = []
    for paper, path in refs.items():
        entries.append({"case_id": f"reference-{paper}", "path": path.relative_to(ROOT).as_posix(), "origin": "programmatic-reference", "source_paper": paper, "output_paper": paper, "expected_sx": 1.0, "expected_sy": 1.0, "sha256": sha(path)})
    for name, source_paper, sx, sy, target_paper in specs:
        path = transformed(refs[source_paper], name, sx, sy, target_paper)
        entries.append({"case_id": name, "path": path.relative_to(ROOT).as_posix(), "origin": "programmatic-detector-control", "source_paper": source_paper, "output_paper": target_paper, "expected_sx": sx, "expected_sy": sy, "sha256": sha(path)})
    manifest = {"schema_version": 1, "atlas_version": "1.0.0", "prepared_date": "2026-10-10", "publisher": "Sewlore", "scope": "Digital PDF path geometry only; no native or physical print outcomes claimed by generated files.", "point_definition": "72 PDF points per inch; 1 inch = 25.4 mm", "paper_mm": PAPER_MM, "markers": MARKERS, "geometry_extraction_tolerance_mm": .005, "color_matching_tolerance": .025, "native_cases_completed": 0, "files": entries}
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    with (ROOT / "expected-geometry.csv").open("w", encoding="utf-8", newline="") as stream:
        fields = ["case_id", "origin", "marker", "expected_width_mm", "expected_height_mm", "expected_sx", "expected_sy", "source_paper", "output_paper"]
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for entry in entries:
            for name, marker in MARKERS.items():
                writer.writerow({"case_id": entry["case_id"], "origin": entry["origin"], "marker": name, "expected_width_mm": round(marker["width_mm"] * entry["expected_sx"], 8), "expected_height_mm": round(marker["height_mm"] * entry["expected_sy"], 8), "expected_sx": entry["expected_sx"], "expected_sy": entry["expected_sy"], "source_paper": entry["source_paper"], "output_paper": entry["output_paper"]})
    print(json.dumps({"reference_pdfs": len(refs), "programmatic_controls": len(specs), "native_cases_completed": 0, "manifest": str(ROOT / "manifest.json")}))

if __name__ == "__main__":
    main()
