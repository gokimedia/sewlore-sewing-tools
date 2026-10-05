---
title: Sewlore Sewing Tools
emoji: 🧵
colorFrom: gray
colorTo: blue
sdk: static
app_file: index.html
pinned: false
license: mit
short_description: Fabric stretch and PDF print scale tools for sewing
---

# Sewlore Sewing Tools

Two small, transparent measurement tools for people who sew. Enter measurements from your own fabric sample or printed test square. No sign-up is required.

[Open the demo](https://huggingface.co/spaces/sewlore/sewlore-sewing-tools) · [Source code](https://github.com/gokimedia/sewlore-sewing-tools) · [Sewlore](https://sewlore.com/)

## Fabric Stretch Lab

Mark a span on your relaxed sample. Measure the same span at a gentle, comfortable extension and again after release and a recorded rest time. Keep your method consistent and test width, length and bias separately when relevant. This is a practical sample check, not a standardized textile laboratory test.

- Stretch (%) = `(stretched − original) / original × 100`
- Residual growth (%) = `(released − original) / original × 100`
- Recovered extension (%) = `(stretched − released) / (stretched − original) × 100`

For the **illustrative** measurements 10 cm → 14 cm → 10.5 cm, the results are 40% stretch, 5% residual growth and 87.5% recovered extension. When no extension occurs, recovered extension is undefined. An unusual released length is flagged for checking rather than silently clamped.

Results describe the entered measurements; they do not prove garment fit or tell you how much negative ease to use. Follow your pattern's fabric requirements and make an appropriate fitting sample.

[Fabric and elastic guide](https://sewlore.com/blogs/sewing-journal/choose-fabric-and-elastic-for-sewing)

## PDF Print Scale Checker

Measure a printed test square in both directions and enter the intended side length using one unit throughout.

- Width error (%) = `(measured width − target) / target × 100`
- Height error (%) = `(measured height − target) / target × 100`

For an **illustrative** 100 mm target measured as 98 × 101 mm, width error is −2% and height error is +1%. Different axis errors can indicate uneven output; a single scaling change may not resolve both. The interface's comparison threshold is a stated convenience, not a printer accuracy certification. The checker does not identify the cause of print errors or resize/grade a sewing pattern.

Use the PDF's own test square. Print at the settings specified in the pattern, usually Actual Size/100%, and check before printing every sheet.

[Printing and assembly guide](https://sewlore.com/pages/printing-assembly)

## Privacy and source attribution

Calculations run locally in your browser. The application does not upload entered measurements or add analytics. You may download your current measurement record as CSV. The hosting platform still receives normal web requests; following an external link uses that site's own privacy policy. An optional `?source=github`, `?source=huggingface`, or `?source=pinterest` parameter adds channel attribution only to outbound Sewlore links.

The initial example values are illustrative and are labelled as such. This repository contains no invented textile dataset, sewn product photos, user counts or paid pattern files. After the first successful load, the local application files may be cached for offline reuse; external guides still need a connection.

## Run and test

The app uses static HTML, CSS and native JavaScript modules. No package install or server API is needed.

```sh
python -m http.server 8000
# Open http://localhost:8000
node --test tests/calculations.test.mjs
```

Deep links: `#stretch` and `#print-scale`. Native labels, keyboard tab selection, live validation and unit conversion support the measurement workflow.

## Reuse

The original application code and educational templates are available under the MIT licence. Sewlore names and branding remain trademarks of their respective owner; the licence does not imply endorsement. Contributions should improve measurement transparency or usability. Please do not add fabricated results, advertising repositories or unrelated link placements.
