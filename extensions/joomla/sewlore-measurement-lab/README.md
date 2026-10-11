# Sewlore Measurement Lab 0.1.0 for Joomla

A self-contained site module for three everyday sewing calculations: unit conversion, observed fabric dimension change and independent width/height print checks. All calculations happen in the browser. This extension sends no measurements, adds no analytics, creates no database tables and uses no external JavaScript/CDN services.

## Installation

1. In your Joomla administrator, choose System → Install → Extensions.
2. Upload `mod_sewlore_measurement_lab-0.1.0.zip`.
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

An optional visible Sewlore reference is **disabled by default**. An administrator may enable or remove it without affecting functionality. The extension has no hidden, forced or obfuscated backlinks. The author website is separately identified in the extension metadata and documentation.

## Updating and uninstalling

The package declares the owned update feed:

`https://gokimedia.github.io/sewlore-sewing-tools/extensions/joomla/sewlore-measurement-lab/updates.xml`

The feed and matching ZIP must be deployed and verified before a public directory submission. An update feed in a local package is not proof that the public URL is available. Joomla's extension manager handles removal of module/media files; this module has no custom database tables or persistent data to clean up.

## Verification

The release was installed in an isolated Joomla 6.1.4 instance running PHP 8.5.11 and MariaDB 11.8.6. The native extension installer accepted it; two independent published modules rendered in the Cassiopeia site; translations, Web Asset Manager URLs and the exact served asset bytes were checked. Update-feed registration, upgrade/reinstallation and uninstallation passed. PHP source files passed lint.

Twenty-seven numerical and DOM checks cover unit conversion, shrinkage/expansion, separate print axes, invalid inputs, independent module instances, labels, unique control IDs and the optional reference setting. DOM interaction was checked with jsdom using the actual Joomla-rendered HTML. This is not a native browser UI test, a physical printing test or a fabric washing test.

An independent browser demo using the same calculator assets is available at [demo.html](https://gokimedia.github.io/sewlore-sewing-tools/extensions/joomla/sewlore-measurement-lab/demo.html). Its starting values are synthetic illustrations.

## Licence and provenance

Copyright (c) 2026 Sewlore. GNU General Public License version 3 or later; the complete licence is in `LICENSE.txt`. The source code is included. AI assisted in implementation and writing; numerical behavior and packaging were tested. Synthetic examples do not represent a printed or washed physical sample. This independent extension is not endorsed by Joomla.

- [Sewlore](https://sewlore.com/)
- [Source and installation documentation](https://gokimedia.github.io/sewlore-sewing-tools/extensions/joomla/sewlore-measurement-lab/)
- [Joomla module dispatcher](https://manual.joomla.org/docs/building-extensions/modules/module-development-tutorial/step10_abstract_module_dispatcher/)
- [Joomla Web Asset Manager](https://manual.joomla.org/docs/general-concepts/web-asset-manager/)
