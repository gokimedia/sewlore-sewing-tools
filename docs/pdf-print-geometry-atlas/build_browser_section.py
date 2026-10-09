"""Build public rows only from hash-verified actual browser-engine measurements."""
from __future__ import annotations
import hashlib
import html
import json
import shutil
import csv
from pathlib import Path

def browser_section(root: Path):
    rows, results, files = [], [], []
    case_labels = {
        "browser-html-a4-css-size-scale-100":"A4 CSS size, scale 1",
        "browser-html-letter-css-size-scale-100":"Letter CSS size, scale 1",
        "browser-html-a4-to-letter-prefercss-false":"A4 source, Letter paper, CSS priority off",
        "browser-html-a4-css-size-scale-95":"A4 CSS size, scale 0.95",
    }
    for path in sorted((root/"results").glob("*.measured.json")):
        measured = json.loads(path.read_text(encoding="utf-8"))
        if measured.get("origin") != "browser-engine-html-to-pdf": continue
        receipt = measured["receipt"]
        output = (root/receipt["output_pdf"]).resolve()
        source = (root/receipt["source_fixture"]).resolve()
        if not output.is_relative_to((root/"incoming").resolve()) or hashlib.sha256(output.read_bytes()).hexdigest()!=measured["file_sha256"] or hashlib.sha256(source.read_bytes()).hexdigest()!=receipt["source_sha256"]:
            raise ValueError("Actual browser output/source changed after analysis; refuse stale results.")
        if any(metric["status"]!="extracted-vector-extents" for metric in measured["metrics"]):
            raise ValueError("Browser output has unextractable markers; resolve before adding a results row.")
        target = root/"browser-output"/f"{measured['case_id']}.pdf"
        target.parent.mkdir(exist_ok=True)
        shutil.copyfile(output,target)
        files.append(target.relative_to(root).as_posix())
        square = next(item for item in measured["metrics"] if item["marker"]=="metric-square")
        params = receipt["command_parameters_observed"]
        params_label = f"scale={params['scale']}; preferCSSPageSize={str(params['preferCSSPageSize']).lower()}; paper={params['paperWidth']:.5f} x {params['paperHeight']:.5f} in"
        rows.append(f'<tr><th scope="row"><a href="{html.escape(target.relative_to(root).as_posix(),quote=True)}">{html.escape(case_labels.get(measured["case_id"],measured["case_id"]))}</a></th><td>{html.escape(params_label)}</td><td>{measured["mediabox_mm"][0]:.5f} x {measured["mediabox_mm"][1]:.5f} mm</td><td>{square["width_mm"]:.5f} / {square["height_mm"]:.5f} mm</td><td>{square["error_x_percent"]:+.5f}% / {square["error_y_percent"]:+.5f}%</td></tr>')
        results.append({"case_id":measured["case_id"],"origin":"browser-engine-html-to-pdf","captured_on":receipt["captured_on"],"application_name":receipt["application_name"],"browser_version_observed":receipt["browser_version_observed"],"command":"Page.printToPDF","command_parameters_observed":params,"source_fixture":receipt["source_fixture"],"source_sha256":receipt["source_sha256"],"output_pdf":target.relative_to(root).as_posix(),"output_sha256":measured["file_sha256"],"page_count":measured["page_count"],"mediabox_mm":measured["mediabox_mm"],"producer":measured["producer"],"metrics":measured["metrics"],"scope":"Actual controlled Chrome HTML-to-PDF developer output. Not PDF-viewer Actual size/Fit, OS print driver or physical printer results."})
    count = len(results)
    if count:
        (root/"browser-output-measured.json").write_text(json.dumps({"schema_version":1,"browser_engine_cases_completed":count,"native_pdf_viewer_cases_completed":0,"physical_print_cases_completed":0,"results":results},indent=2)+"\n",encoding="utf-8")
        files.append("browser-output-measured.json")
        fields = ["case_id","origin","captured_on","browser_version","command_scale","prefer_css_page_size","requested_paper_width_in","requested_paper_height_in","output_page_width_mm","output_page_height_mm","marker","width_mm","height_mm","scale_x","scale_y","error_x_percent","error_y_percent","source_sha256","output_sha256"]
        with (root/"browser-output-measured.csv").open("w",encoding="utf-8",newline="") as stream:
            writer = csv.DictWriter(stream,fieldnames=fields)
            writer.writeheader()
            for result in results:
                params = result["command_parameters_observed"]
                for metric in result["metrics"]:
                    row = {key:metric.get(key) for key in fields}
                    row.update({"case_id":result["case_id"],"origin":result["origin"],"captured_on":result["captured_on"],"browser_version":result["browser_version_observed"],"command_scale":params["scale"],"prefer_css_page_size":params["preferCSSPageSize"],"requested_paper_width_in":params["paperWidth"],"requested_paper_height_in":params["paperHeight"],"output_page_width_mm":result["mediabox_mm"][0],"output_page_height_mm":result["mediabox_mm"][1],"source_sha256":result["source_sha256"],"output_sha256":result["output_sha256"]})
                    writer.writerow(row)
        files.append("browser-output-measured.csv")
        section = '<section aria-labelledby="browser"><h2 id="browser">Actual Chrome HTML-to-PDF measurements</h2><p>These are saved browser-engine outputs from original HTML/SVG fixtures. Each case retains its exact developer print parameters, browser version, source hash and output hash. They do not test the PDF viewer\'s Actual size/Fit controls or a physical printer.</p><div class="table-wrap"><table><caption>Observed Page.printToPDF output geometry; all three calibration paths extracted</caption><thead><tr><th scope="col">Actual output</th><th scope="col">Recorded parameters</th><th scope="col">PDF page size</th><th scope="col">Square width / height</th><th scope="col">Width / height error</th></tr></thead><tbody>'+"\n".join(rows)+'</tbody></table></div><p><a href="browser-output-measured.csv">Download browser measurement CSV</a> · <a href="browser-output-measured.json">Exact parameters, hashes and full measured geometry JSON</a></p><p>Inputs: <a href="fixtures/print-geometry-a4.html">A4 HTML/SVG</a> and <a href="fixtures/print-geometry-letter.html">Letter HTML/SVG</a>. Downloaded output PDFs preserve the actual returned bytes. Small numerical differences belong to this rendering path and should not be interpreted as physical printer tolerance.</p></section>'
        producers = sorted({result["producer"] for result in results})
        environment_note = '<p class="small">Returned PDF producer metadata: '+html.escape(", ".join(producers))+'. The full browser version was not exposed by the tab-scoped capture capability; the producer label is not a complete Chrome build identifier.</p>'
        selected = {result["case_id"]:result for result in results}
        findings = []
        for case_id in ["browser-html-a4-css-size-scale-100","browser-html-letter-css-size-scale-100","browser-html-a4-css-size-scale-95","browser-html-a4-to-letter-prefercss-false"]:
            if case_id in selected:
                result = selected[case_id]
                square = next(metric for metric in result["metrics"] if metric["marker"]=="metric-square")
                findings.append(f'<li><strong>{html.escape(case_labels[case_id])}:</strong> {square["width_mm"]:.5f} mm wide and {square["height_mm"]:.5f} mm high, from a 100 mm x 100 mm source path.</li>')
        findings_text = '<h3>What this captured run shows</h3><ul>'+"".join(findings)+'</ul><p>Output page dimensions are reported from the actual MediaBox, not rounded to the requested paper name. For example, the A4 CSS-size output can have small numeric differences from 210 x 297 mm. These observations characterize this controlled rendering path only.</p>'
        section = section.replace('<div class="table-wrap">',environment_note+findings_text+'<div class="table-wrap" tabindex="0" role="region" aria-label="Browser geometry comparison">',1)
        status = f'<strong>This release includes {count} actual Chrome HTML-to-PDF measurements and six generated reference/control files.</strong> Native PDF-viewer print-setting experiments: 0. Physical printer measurements: 0. Generated controls remain separate from browser output.'
    else:
        section = '<section aria-labelledby="browser"><h2 id="browser">Chrome HTML-to-PDF experiment inputs</h2><p>The original <a href="fixtures/print-geometry-a4.html">A4 HTML/SVG</a> and <a href="fixtures/print-geometry-letter.html">Letter HTML/SVG</a> inputs have exact CSS page sizes and the same known vector paths. Browser-engine results are not listed until actual saved outputs and parameter receipts have been measured.</p></section>'
        status = '<strong>This release measures digital reference files and known software transforms.</strong> Chrome HTML-to-PDF outputs measured: 0. Native PDF-viewer print-setting experiments: 0. Physical printer measurements: 0. Generated controls are not browser or printer observations.'
    (root/"browser-public-package-files.private.json").write_text(json.dumps({"schema_version":1,"browser_engine_cases_completed":count,"files":files},indent=2)+"\n",encoding="utf-8")
    return {"count":count,"section":section,"status":status}
