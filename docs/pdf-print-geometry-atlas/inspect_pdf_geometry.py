"""Read PDF vector markers; never infer missing/rasterized/clipped geometry.

Baseline/control inspection: --all-generated
Native output: --native-receipt incoming/<case>.receipt.json
Browser-engine HTML output: --browser-engine-receipt incoming/<case>.receipt.json
Receipt values must come from observed UI, not guesses. The analyzer refuses
generated fixtures masquerading as native output and requires the source hash.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import re
from pathlib import Path
import pdfplumber
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
PT_TO_MM = 25.4 / 72

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def color_match(actual, expected, tolerance):
    return isinstance(actual, (tuple, list)) and len(actual) == 3 and all(abs(float(a) - float(b)) <= tolerance for a, b in zip(actual, expected))

def extract(path: Path, manifest: dict) -> dict:
    reader = PdfReader(path)
    if len(reader.pages) != 1:
        raise ValueError("A captured case must be exactly one page; investigate extra pages before measurement.")
    page = reader.pages[0]
    with pdfplumber.open(path) as document:
        parsed = document.pages[0]
        objects = [*parsed.rects, *parsed.curves, *parsed.lines]
        metrics = []
        for name, marker in manifest["markers"].items():
            found = [item for item in objects if item.get("stroke", True) and color_match(item.get("stroking_color"), marker["rgb"], manifest["color_matching_tolerance"])]
            if not found:
                metrics.append({"marker": name, "status": "not-extractable", "explanation": "No uniquely colored vector path found. Rasterization, recoloring, clipping or another conversion may require separate visual/manual inspection."})
                continue
            x0, x1 = min(item["x0"] for item in found), max(item["x1"] for item in found)
            y0, y1 = min(item["y0"] for item in found), max(item["y1"] for item in found)
            width, height = (x1 - x0) * PT_TO_MM, (y1 - y0) * PT_TO_MM
            sx = width / marker["width_mm"] if marker["width_mm"] else None
            sy = height / marker["height_mm"] if marker["height_mm"] else None
            metrics.append({"marker": name, "status": "extracted-vector-extents", "matched_objects": len(found), "width_mm": width, "height_mm": height, "scale_x": sx, "scale_y": sy, "error_x_percent": None if sx is None else (sx - 1) * 100, "error_y_percent": None if sy is None else (sy - 1) * 100, "bbox_pdf_points": [x0, y0, x1, y1]})
    return {"file_sha256": sha(path), "page_count": 1, "mediabox_mm": [float(page.mediabox.width) * PT_TO_MM, float(page.mediabox.height) * PT_TO_MM], "cropbox_mm": [float(page.cropbox.width) * PT_TO_MM, float(page.cropbox.height) * PT_TO_MM], "rotation_degrees": int(page.get("/Rotate", 0)), "producer": str(reader.metadata.get("/Producer", "")) if reader.metadata else "", "measurement_definition": "PDF vector path extents, excluding line thickness; displayed visible clipping is not inferred from raw path extents.", "metrics": metrics}

def all_generated(manifest):
    outputs = []
    tolerance = manifest["geometry_extraction_tolerance_mm"]
    for entry in manifest["files"]:
        path = ROOT / entry["path"]
        if sha(path) != entry["sha256"]:
            raise ValueError(f"Generated source hash changed: {entry['path']}")
        result = extract(path, manifest)
        for metric in result["metrics"]:
            marker = manifest["markers"][metric["marker"]]
            if metric["status"] != "extracted-vector-extents":
                raise ValueError(f"Detector failed generated control {entry['case_id']}: {metric['marker']}")
            expected_w = marker["width_mm"] * entry["expected_sx"]
            expected_h = marker["height_mm"] * entry["expected_sy"]
            if abs(metric["width_mm"] - expected_w) > tolerance or abs(metric["height_mm"] - expected_h) > tolerance:
                raise ValueError(f"Geometry exceeds .005 mm numerical tolerance: {entry['case_id']}, {metric['marker']}")
        expected_paper = manifest["paper_mm"][entry["output_paper"]]
        if any(abs(a - b) > tolerance for a, b in zip(result["mediabox_mm"], expected_paper)):
            raise ValueError(f"Output paper size mismatch: {entry['case_id']}")
        outputs.append({"case_id": entry["case_id"], "origin": entry["origin"], "path": entry["path"], "validation": "passed-known-geometry-control", **result})
    output = {"schema_version": 1, "scope": "Generated digital references and detector controls; no browser or printer experiment results.", "native_cases_completed": 0, "results": outputs}
    (ROOT / "results" / "generated-controls-measured.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    write_csv(outputs, ROOT / "results" / "generated-controls-measured.csv")
    print(json.dumps({"passed_generated_files": len(outputs), "native_cases_completed": 0}))

def write_csv(outputs, path):
    fields = ["case_id", "origin", "marker", "status", "width_mm", "height_mm", "scale_x", "scale_y", "error_x_percent", "error_y_percent", "file_sha256"]
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for output in outputs:
            for metric in output["metrics"]:
                row = {field: metric.get(field) for field in fields}
                row.update({"case_id": output["case_id"], "origin": output["origin"], "file_sha256": output["file_sha256"]})
                for field in ("width_mm", "height_mm", "scale_x", "scale_y", "error_x_percent", "error_y_percent"):
                    if row[field] is not None:
                        row[field] = round(row[field], 8)
                writer.writerow(row)

def native(receipt_path: Path, manifest):
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    required = ["case_id", "output_pdf", "source_fixture", "source_sha256", "native_ui_observed", "captured_on", "application_name", "application_version_observed", "destination_label_observed", "source_document_type", "paper_label_observed", "scale_label_observed", "orientation_label_observed", "settings_screenshot", "settings_screenshot_sha256", "saved_output_observed", "save_workflow_observed", "output_class", "notes"]
    if any(key not in receipt for key in required):
        raise ValueError(f"Receipt missing required fields: {[key for key in required if key not in receipt]}")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,79}", receipt["case_id"]):
        raise ValueError("Case ID must be a safe lowercase filename identifier.")
    if any(isinstance(receipt[key], str) and receipt[key].startswith("REPLACE_") for key in required):
        raise ValueError("Receipt still contains preparation placeholders; supply actual observations.")
    if receipt["native_ui_observed"] is not True or receipt["saved_output_observed"] is not True:
        raise ValueError("Native receipt requires actual observed UI and a saved output.")
    if receipt["source_document_type"] != "pdf" or receipt["output_class"] not in ("native-browser-save-as-pdf", "native-pdf-printer-output"):
        raise ValueError("Output origin must explicitly distinguish browser Save as PDF from a PDF printer destination.")
    source = (ROOT / receipt["source_fixture"]).resolve()
    source_entry = next((entry for entry in manifest["files"] if entry["origin"] == "programmatic-reference" and (ROOT / entry["path"]).resolve() == source), None)
    if not source_entry or sha(source) != receipt["source_sha256"] or source_entry["sha256"] != receipt["source_sha256"]:
        raise ValueError("Native input must refer to an unchanged reference fixture.")
    output_path = (ROOT / receipt["output_pdf"]).resolve()
    if not output_path.is_relative_to((ROOT / "incoming").resolve()):
        raise ValueError("Native output must be saved under incoming/; generated controls are not native results.")
    if sha(output_path) in {entry["sha256"] for entry in manifest["files"]}:
        raise ValueError("Output is byte-identical to a generated reference/control. A copied input is not a measured native output; document any byte-preserving save separately.")
    screenshot = (ROOT / receipt["settings_screenshot"]).resolve()
    if not screenshot.is_relative_to((ROOT / "incoming").resolve()):
        raise ValueError("A native settings screenshot must be saved under incoming/.")
    if sha(screenshot) != receipt["settings_screenshot_sha256"]:
        raise ValueError("Settings screenshot hash differs from its receipt.")
    output = {"schema_version": 1, "case_id": receipt["case_id"], "origin": receipt["output_class"], "receipt": receipt, "receipt_sha256": sha(receipt_path), **extract(output_path, manifest)}
    (ROOT / "results" / f"{receipt['case_id']}.measured.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    write_csv([output], ROOT / "results" / f"{receipt['case_id']}.measured.csv")
    print(json.dumps({"case_id": receipt["case_id"], "origin": output["origin"], "measured": [metric["marker"] for metric in output["metrics"] if metric["status"] == "extracted-vector-extents"], "native_output_sha256": output["file_sha256"]}))

def browser_engine(receipt_path: Path, manifest):
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    required = ["case_id","output_pdf","output_sha256","source_fixture","source_sha256","source_document_type","source_url_observed","controlled_source_document_observed","captured_on","application_name","browser_version_observed","command","command_parameters_observed","documented_cua_cdp_capability_used","response_pdf_saved","output_class","source_screenshot","source_screenshot_sha256","notes"]
    if any(key not in receipt for key in required):
        raise ValueError(f"Browser engine receipt missing fields: {[key for key in required if key not in receipt]}")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,79}",receipt["case_id"]):
        raise ValueError("Case ID must be a safe lowercase filename identifier.")
    if any(isinstance(receipt[key],str) and receipt[key].startswith("REPLACE_") for key in required):
        raise ValueError("Browser engine receipt contains preparation placeholders.")
    if receipt["controlled_source_document_observed"] is not True or receipt["documented_cua_cdp_capability_used"] is not True or receipt["response_pdf_saved"] is not True:
        raise ValueError("Browser engine output requires observed controlled source, documented CUA capability and actual saved response.")
    if receipt["command"] != "Page.printToPDF" or receipt["source_document_type"] != "html" or receipt["output_class"] != "browser-engine-html-to-pdf":
        raise ValueError("Browser engine origin must explicitly identify HTML Page.printToPDF, distinct from PDF-viewer/physical printing.")
    html_manifest = json.loads((ROOT / "html-fixtures-manifest.json").read_text(encoding="utf-8"))
    source = (ROOT / receipt["source_fixture"]).resolve()
    source_entry = next((entry for entry in html_manifest["fixtures"] if (ROOT/entry["path"]).resolve()==source),None)
    if not source_entry or sha(source)!=receipt["source_sha256"] or source_entry["sha256"]!=receipt["source_sha256"]:
        raise ValueError("Browser source must be an unchanged original HTML fixture.")
    params = receipt["command_parameters_observed"]
    parameter_fields = ["landscape","displayHeaderFooter","printBackground","scale","paperWidth","paperHeight","marginTop","marginBottom","marginLeft","marginRight","preferCSSPageSize","pageRanges"]
    if not isinstance(params,dict) or any(field not in params for field in parameter_fields):
        raise ValueError("Capture exact orientation, scale, paper, margins, CSS priority and page range parameters.")
    if params["pageRanges"] != "":
        raise ValueError("Use the whole generated document, rather than hiding extra pages through a page range.")
    output_path = (ROOT/receipt["output_pdf"]).resolve()
    screenshot = (ROOT/receipt["source_screenshot"]).resolve()
    if not output_path.is_relative_to((ROOT/"incoming").resolve()) or not screenshot.is_relative_to((ROOT/"incoming").resolve()):
        raise ValueError("Browser engine output and source screenshot must remain under incoming/.")
    if sha(output_path)!=receipt["output_sha256"] or sha(screenshot)!=receipt["source_screenshot_sha256"]:
        raise ValueError("Observed output or screenshot hash differs from receipt.")
    if sha(output_path) in {entry["sha256"] for entry in manifest["files"]}:
        raise ValueError("Generated programmatic controls cannot masquerade as browser engine output.")
    output = {"schema_version":1,"case_id":receipt["case_id"],"origin":"browser-engine-html-to-pdf","receipt":receipt,"receipt_sha256":sha(receipt_path),**extract(output_path,manifest)}
    (ROOT/"results"/f"{receipt['case_id']}.measured.json").write_text(json.dumps(output,indent=2)+"\n",encoding="utf-8")
    write_csv([output],ROOT/"results"/f"{receipt['case_id']}.measured.csv")
    print(json.dumps({"case_id":receipt["case_id"],"origin":output["origin"],"measured":[metric["marker"] for metric in output["metrics"] if metric["status"]=="extracted-vector-extents"],"output_sha256":output["file_sha256"]}))

def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all-generated", action="store_true")
    group.add_argument("--native-receipt", type=Path)
    group.add_argument("--browser-engine-receipt", type=Path)
    args = parser.parse_args()
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    if args.all_generated:
        all_generated(manifest)
    elif args.native_receipt:
        native(args.native_receipt.resolve(), manifest)
    else:
        browser_engine(args.browser_engine_receipt.resolve(),manifest)

if __name__ == "__main__":
    main()
