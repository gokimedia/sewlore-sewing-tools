# Sewlore Measurement Interchange 0.1.0

A small local Python tool for exchanging **numeric individual measurements** between CSV, SeamlyME `.smis` and legacy `.vit` files. It provides explicit per-row units when importing a CSV, preserves measurement identifiers, and lets you choose whether to carry personal metadata into a new file.

This is an independent Sewlore helper, not an official Seamly product. It does not replace SeamlyME's built-in CSV export or evaluate pattern formulas. All examples are synthetic; no person's body measurements or fitting results were collected.

## Supported formats

| File | Root | Schema version | Output unit spelling |
| --- | --- | --- | --- |
| Current SeamlyME `.smis` | `smis` | `0.3.4` | `mm`, `cm`, `inch` |
| Legacy `.vit` | `vit` | `0.3.3` | `mm`, `cm`, `inch` |

CSV uses `mm`, `cm` or `in` (`inch` is accepted when importing). Later Valentina/Tape formats and multisize `.vst`/`.smms` files are outside this release. Names are limited to ASCII letters, digits and underscores, beginning with a letter or underscore; this covers the sample identifiers but does not claim to cover every identifier allowed by Seamly's broader XML schema.

## Run locally

Python 3.10 or newer is sufficient. The tool uses only Python's standard library and makes no network requests.

```sh
python sewlore_measurements.py to-csv examples/synthetic.smis measurements-mm.csv --unit mm
python sewlore_measurements.py from-csv examples/mixed-units.csv measurements.smis --unit cm
python sewlore_measurements.py from-csv measurements-mm.csv legacy-copy.vit --format vit --unit cm
```

Outputs must be new filenames. Input files and existing output files are never overwritten.

## CSV layout

The required columns are `name,value,unit`; optional columns are `full_name,description`. Column order may change, but duplicate or unknown column names fail validation.

```csv
name,value,unit,full_name,description
bust_circ,840,mm,Bust circumference,Synthetic example only
waist_circ,26,in,Waist circumference,Synthetic example only
hip_circ,96,cm,Hip circumference,Synthetic example only
```

The resulting centimetre values are **84, 66.04 and 96**. Conversion uses decimal factors: 1 cm = 10 mm and 1 in = 25.4 mm. Up to 15 significant digits are written; a decimal centimetre-to-inch-to-centimetre roundtrip can therefore differ at insignificant trailing digits. Do not infer measurement accuracy from the number of printed digits.

Do not rename identifiers merely to make their labels prettier. A pattern refers to identifiers such as `bust_circ`; `full_name` is only a human-readable label. Each identifier must occur once. Review the list in SeamlyME before linking it to a pattern, and ensure every measurement actually required by that pattern is present.

## Formula values are rejected

Seamly files can contain formulas. A value such as `bust_circ / 2` is **not** a numeric literal. The tool stops with a named error rather than guessing a value or multiplying a formula by a unit factor. Calculate and export values through SeamlyME when you need its formula engine. Do not replace a formula with a numeric value unless that is your deliberate editing choice.

Zero and negative numeric offsets are supported. This does not mean a negative circumference is physically meaningful. The tool validates representation and conversion, not the suitability of body measurements for drafting or fit.

## Metadata and privacy

An ordinary CSV export includes names, values, units and labels; it omits the original `personal` section, notes and pattern-system metadata. Re-importing without a template creates an empty personal section, `gender=unknown`, a schema-required placeholder birth date (`1800-01-01`) and `pm_system=998`.

To preserve **your own original** personal information, notes and system code in a local roundtrip, use an editable original as a template:

```sh
python sewlore_measurements.py from-csv edited.csv edited-copy.smis --unit cm --template original.smis
```

That option deliberately copies the original personal metadata. Keep the result private if it contains identifying data. A template marked read-only is rejected. The measurement list is replaced by the complete CSV list, so partial CSVs remove measurements absent from the CSV; keep an original backup.

The parser rejects XML DTD/entity declarations, unexpected sections, duplicate measurement names and unsupported formats. Spreadsheet-active labels beginning with `=`, `+`, `-`, `@` or a tab are rejected during export rather than silently changing the label. CSV and XML inputs have a 4 MiB limit and a 10,000-measurement limit.

## Verification and limits

The development checks cover unit pairs, mixed units, CLI roundtrips, XML escaping, metadata choices, existing-file protection, read-only templates, malformed CSV, duplicates and formula rejection. Generated `.vit` and `.smis` examples validate against the official upstream 0.3.3 and 0.3.4 XSDs. The public package contains independent code and synthetic examples, not copied upstream schema files.

Native interactive SeamlyME opening/saving has not been tested in this environment. Schema validation and CLI tests do not establish that a particular pattern will draft or fit successfully. Open a copy in your installed SeamlyME, check the measurements, and save it before attaching it to a pattern.

## Sources and licence

- [Official Seamly2D project](https://github.com/FashionFreedom/Seamly2D)
- [Official individual-measurement schemas](https://github.com/FashionFreedom/Seamly2D/tree/develop/src/libs/ifc/schema/individual_size_measurements)
- [Seamly's explanation of VIT and SMIS versions](https://forum.seamly.io/t/couldnt-get-version-information-when-importing-a-converted-3dlook-file/11183/9)
- [Sewlore sewing resources](https://sewlore.com/)

Copyright (c) 2026 Sewlore. Independent helper code, documentation and synthetic examples: MIT. AI assisted in drafting and implementation; functionality was checked with automated tests. No Seamly endorsement is implied.
