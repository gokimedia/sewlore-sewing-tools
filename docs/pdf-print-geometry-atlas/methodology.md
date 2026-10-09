# Sewlore PDF Geometry Test Kit, version 1.0.0

Prepared: 2026-10-10. Scope: digital PDF geometry. Native print experiments completed: **0** at preparation time.

## Why this exists

A print check should distinguish horizontal scale, vertical scale, paper size and clipping. A single on-screen ruler cannot establish physical printed dimensions. This kit supplies deterministic vector references, independent known-transform controls, and an analyzer that reports what is actually extractable from a PDF.

The A4 fixture has a 210 x 297 mm page. The Letter fixture has a 215.9 x 279.4 mm page. Both contain the same three uniquely colored measurement paths:

| Path | Reference width | Reference height | Purpose |
| --- | ---: | ---: | --- |
| Green square | 100 mm | 100 mm | Independent horizontal and vertical scale checks |
| Blue rectangle | 50.8 mm | 25.4 mm | Check the 2 in x 1 in conversion on a separate path |
| Orange horizontal line | 180 mm | 0 mm | Confirm width scale across a longer reference |

The muted border is 5 mm from each source page edge. It is a visual clipping aid, not one of the automatic measurements. Calibration refers to the path centre line, not the outside of its stroke. One PDF point is 1/72 inch and one inch is 25.4 mm.

## Evidence classes

1. **Programmatic reference.** A deterministic ReportLab PDF defining the expected geometry. This is an input, not a browser output.
2. **Programmatic detector control.** A pypdf transformation with an explicitly specified scale. These controls test that extraction detects known changes. They do not characterize Chrome, Acrobat or a physical printer.
3. **Browser-engine HTML-to-PDF output.** An actual PDF response produced by Chrome's developer `Page.printToPDF` command on an original, controlled HTML/SVG fixture. Record the exact browser version and all command parameters. This is a browser rendering experiment, not a test of the PDF viewer's print controls or an OS print driver.
4. **Native browser Save as PDF output.** A file actually saved from the visible browser print UI. Record the exact destination and controls exposed by the UI. This path may preserve the source PDF size rather than emulate a printer.
5. **Native PDF printer output.** A file actually saved through a destination such as Microsoft Print to PDF. Record that destination's exact label. Results apply only to the captured software/settings combination.
6. **Physical print.** Not included in this release. No measurement of a physical printer, paper feed, ruler uncertainty or hardware margin is claimed.

## Reproduction

Use Python 3.11 or later with ReportLab, pypdf and pdfplumber. The preparation environment used Python 3.12.14, ReportLab 4.4.9, pypdf 6.10.0 and pdfplumber 0.11.9. The exact preparation versions are recorded in `environment.json`.

```text
python build_atlas.py
python inspect_pdf_geometry.py --all-generated
```

The generator uses deterministic PDF metadata and writes `manifest.json` containing SHA-256 hashes. The analyzer checks every hash before measuring. It checks that all three paths and the paper dimensions agree with their declared control dimensions within 0.005 mm. This is a numerical extraction tolerance, not a printer accuracy allowance.

## Controlled Chrome HTML-to-PDF experiments

`build_html_fixtures.py` prepares two original HTML inputs with full-page SVG geometry in millimetres, no external scripts/fonts and exact `@page` sizes. Their input hashes are in `html-fixtures-manifest.json`. They are distinct inputs from the ReportLab PDF references, and their rendered dimensions must be measured rather than assumed.

The operator loads a controlled fixture in Chrome using the documented browser-control capability, records a source screenshot and its hash, then calls the documented `Page.printToPDF` command. Save the actual returned PDF bytes under `incoming/`; do not rebuild the returned file with another PDF library. The planned comparisons use scale 1 on matching CSS A4/Letter sizes, an A4 HTML input with explicit Letter paper and `preferCSSPageSize=false`, and scale 0.95 with the A4 CSS page size.

All comparisons explicitly record `landscape`, `displayHeaderFooter`, `printBackground`, `scale`, `paperWidth`, `paperHeight`, four margins, `preferCSSPageSize` and `pageRanges`. Margins are zero, headers/footers are disabled and the complete document is printed. A selected page range must not hide unintended extra pages. Paper/margin parameters use inches, unlike the fixtures' millimetre units. Record the actual command parameters returned by the operation transcript rather than attributing human UI setting names to them.

```text
python build_html_fixtures.py
python inspect_pdf_geometry.py --browser-engine-receipt incoming/your-browser-case.receipt.json
```

The receipt must identify `browser-engine-html-to-pdf`, the observed command, exact parameters, date/time, browser version, source hash, actual output hash and source screenshot hash. A template or generated programmatic control is refused as an observed result. The analyzer reports extracted geometry without substituting a theoretically expected fit percentage. The public page includes a browser measurement only after all three paths are extractable and the saved output/source hashes still match.

This route makes actual browser geometry measurable while native Windows print dialogs are unavailable. It does not remove that limitation or establish PDF-viewer Actual size/Fit behavior. Refer to the [official Chrome DevTools Page.printToPDF protocol](https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF) for command semantics. In particular, `preferCSSPageSize=false` allows content to be scaled to fit the explicitly supplied paper size; it is not the same evidence as clicking a viewer's Fit to paper option.

For a native output, copy the receipt template, replace each placeholder with observations, save the PDF in `incoming/`, then run:

```text
python inspect_pdf_geometry.py --native-receipt incoming/a4-to-letter-fit-paper.receipt.json
```

The analyzer refuses a generated fixture/control as a native output, requires the source hash and screenshot hash, and preserves the output PDF's hash and producer metadata. An unextractable marker is reported as such; its dimension is not guessed.

## Minimal native cases

Use one page, portrait orientation and the same observed destination for each comparable case. Record application/version, destination label, paper label, exact scale label, any visible margins and the saved filename. Take a screenshot after settings are settled and before saving. Retain both the screenshot and output PDF.

| Case | Source | Output paper requested | Scale requested | Purpose |
| --- | --- | --- | --- | --- |
| a4-to-a4-actual | A4 PDF | A4 | Actual size | Matched-paper baseline |
| letter-to-letter-actual | Letter PDF | Letter | Actual size | Second matched-paper baseline |
| a4-to-letter-fit-paper | A4 PDF | Letter | Fit to paper | Tall-page mismatch |
| letter-to-a4-fit-paper | Letter PDF | A4 | Fit to paper | Wide-page mismatch |

Optional follow-ups: A4 to Letter at Actual size for visible clipping; A4 to Letter at Fit to printable area if that exact option exists; Custom 95% for an explicitly user-set scale. Do not substitute similarly named settings without recording the changed label.

If the chosen destination hides paper/scale controls, record them as "not exposed by this destination". A control not exposed by the UI is not an applied setting. Do not fabricate a mismatched-paper result. In particular, Chromium source documents a source-size path for Save as PDF; use an actual PDF printer destination if the goal is a printer scaling comparison and the UI supports it.

## Calculations and interpretation

For reference length R and extracted output length O:

- Scale ratio = O / R.
- Signed dimensional error (%) = 100 x (O - R) / R.
- Calculate the two square axes independently. Agreement between the square, inch rectangle and long line provides a consistency check.

Negative error means a shorter extracted path; positive error means a longer path. Two axes do not become interchangeable because they happen to agree in one case. This kit makes no garment fit or fabric shrinkage inference.

The A4-to-Letter whole-paper-fit control uses a mathematical model with the smaller of the width and height ratios: min(215.9 / 210, 279.4 / 297) = 0.9407407407. It intentionally assumes no margins and no printer restrictions. It is **not an observed Chrome fit result**. A real printable-area fit can differ.

PDF path bounding boxes do not establish what survived a clipping path or physical printing. Inspect the rendered output visually for clipping. If a conversion rasterizes, recolors, duplicates or rotates the calibration paths, review that output separately. The analyzer does not silently compensate for rotations or repair missing content.

## Sources and provenance

- [Google Chrome Help: Print from Chrome](https://support.google.com/chrome/answer/1069693?hl=en): visible print workflow and Save as PDF.
- [Adobe Acrobat: Adjust page size for printing](https://helpx.adobe.com/acrobat/desktop/print-documents/set-up-and-print-pdfs/page-size.html): meanings of Fit, Actual size and Shrink oversized pages. These are Acrobat definitions; do not attribute them to an unobserved Chrome UI.
- [Chromium printing implementation, immutable commit](https://chromium.googlesource.com/chromium/src/+/f6529c7990744370869e4ab2794caae6c46ba044/components/printing/renderer/print_render_frame_helper.cc): source-size handling for Save as PDF, plus printer scaling distinctions. The installed Chrome version may differ; actual output takes precedence.
- [Chromium print preview labels](https://chromium.googlesource.com/chromium/src/+/767f1d9d92d527ae92d45d29d79b6af5589c54d9/chrome/app/printing_strings.grdp): distinct labels for Fit to printable area, Fit to paper and Actual size.
- [Chrome DevTools Protocol: Page.printToPDF](https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF): developer print parameters, including scale, paper dimensions, margins and CSS page-size priority.
- [Sewlore printing and assembly guide](https://sewlore.com/pages/printing-assembly): practical reference for checking one test page before printing a pattern.

This is an original Sewlore technical resource prepared with AI assistance and programmatically verified. It is not a peer-reviewed study, and no DOI, affiliation or independent laboratory validation is claimed. Cite the version, preparation date and actual public URL when available.
