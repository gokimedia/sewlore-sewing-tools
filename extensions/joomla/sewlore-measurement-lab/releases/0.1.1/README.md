# Sewlore Measurement Lab 0.1.1 for Joomla

A self-contained site module for three everyday sewing calculations: unit conversion, observed fabric dimension change and independent width/height print checks. All calculations happen in the browser. This extension sends no measurements, adds no analytics, creates no database tables and uses no external JavaScript/CDN services.

## Installation

1. In your Joomla administrator, choose System → Install → Extensions.
2. Upload `mod_sewlore_measurement_lab-0.1.1.zip`.
3. Open Content → Site Modules and configure the new Sewlore Measurement Lab module.
4. Choose a position supported by your template, assign the required menu pages and publish the module.
5. Verify it on a site page. The example inputs are illustrations, not measured physical test results.

Target platform: Joomla 6.1.x, PHP 8.3 or newer, with JavaScript enabled for interactive results. Native compatibility evidence is recorded separately; do not infer Joomla 5 compatibility from similar APIs. The implementation uses a namespaced module dispatcher, a service provider, a layout override and the Web Asset Manager.

Multiple copies on a page have independent inputs and IDs. Module layouts can be overridden through Joomla's template override system. Assets and styles are scoped to this module.

## Formulas

- Units: 1 inch = 25.4 millimetres; 1 centimetre = 10 millimetres.
- Observed dimension change: `(before − after) / before × 100`. A positive percentage represents shrinkage of the measured axis; a negative percentage represents expansion. This is not a predicted fabric shrinkage rate.
- Retained dimension: `after / before × 100`.
- Print width ratio: `measured width / expected width × 100`.
- Print height ratio: `measured height / expected height × 100`.
- Difference between axes: the absolute difference between the two ratios, in **percentage points**.

For a 100 × 50 expected rectangle measured as 96 × 52, the module returns 96% width, 104% height and an 8-percentage-point difference. It does not average those axes or choose a printer correction. All four dimensions must use the same unit. There is no universal pass/fail threshold; follow your pattern provider's requirements and your measurement method.

For a synthetic fabric example changing from 100 to 95 in one dimension, the observed change is 5% and the retained dimension is 95%. Measure both directions separately, and record washing/drying conditions when interpreting a real fabric sample.

## Data, accessibility and links

Every control has a label. Results use live output regions and display invalid-input messages when measurements are missing, non-finite or non-positive where a baseline is required. Results are written as text, not interpreted HTML. No input is submitted or stored by the extension.

The rendered module contains no author-credit link or credit setting. Legacy `show_credit` parameters are ignored. The author website remains in normal extension metadata and documentation; those links are not injected into site content.

## Updating and uninstalling

The package declares the owned update feed:

`https://gokimedia.github.io/sewlore-sewing-tools/extensions/joomla/sewlore-measurement-lab/updates.xml`

The feed and matching ZIP must be deployed and verified before a public directory submission. An update feed in a local package is not proof that the public URL is available. Joomla's extension manager handles removal of module/media files; this module has no custom database tables or persistent data to clean up.

## Verification

Release-specific evidence is recorded in `verification.json` and bound to the exact 0.1.1 ZIP hash. The local checks cover native Joomla installation, the literal extension name and version, source identity, two published module instances, translations, Web Asset Manager assets, upgrade/reinstallation and removal. Calculator checks use jsdom against the actual Joomla-rendered HTML, including legacy credit parameters and independent inputs. Native browser UI, physical printing and fabric washing are not claimed as tested.

`demo.html` is a **standalone calculator preview** using the same local assets and synthetic starting values. It is not a hosted native Joomla demonstration. Publication URLs and directory acceptance must be verified separately.

## Changes in 0.1.1

- The literal install manifest name is Sewlore Measurement Lab, matching the intended directory listing.
- Frontend author-credit output, its configuration field, language strings and unused style were removed.
- Unit conversion, observed fabric dimension change and independent print-axis calculations remain unchanged.

## Licence and provenance

Copyright (c) 2026 Sewlore. GNU General Public License version 3 or later; the complete licence is in `LICENSE.txt`. The source code is included. AI assisted in implementation and writing; numerical behavior and packaging were tested. Synthetic examples do not represent a printed or washed physical sample. This independent extension is not endorsed by Joomla.

- [Sewlore](https://sewlore.com/)
- [Source and installation documentation](https://gokimedia.github.io/sewlore-sewing-tools/extensions/joomla/sewlore-measurement-lab/releases/0.1.1/)
- [Joomla module dispatcher](https://manual.joomla.org/docs/building-extensions/modules/module-development-tutorial/step10_abstract_module_dispatcher/)
- [Joomla Web Asset Manager](https://manual.joomla.org/docs/general-concepts/web-asset-manager/)
