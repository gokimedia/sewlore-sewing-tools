# API reference

Import the four named exports from the package root. CommonJS `require` and internal file subpath imports are not part of the documented API.

Install the published JavaScript module with:

```sh
npm install @sewingselami/sewlore-sewing-math@0.1.0
```

```js
import { calculatePrintScale } from '@sewingselami/sewlore-sewing-math';
// Hypothetical software inputs; no physical printout was measured.
const result = calculatePrintScale({ target: 10, measuredX: 9.8, measuredY: 10.1 });
```

For local paired fabric-care CSV validation and rectangular-area contraction, use the separate [Python package](https://pypi.org/project/sewlore-fabric-care/0.1.0/) and its [documentation](https://sewlore-fabric-care.readthedocs.io/en/latest/). Its positive-length `convert_length` supports `cm`/`mm`/`in`. The JavaScript conversion helper supports only `cm`/`in` and allows signed finite inputs, including zero; JavaScript stretch and print readings must still be positive. The two packages do not expose interchangeable calculation or CSV-validation APIs.

## calculateStretch({ original, stretched, released })

Use three positive finite readings in one unit. The result includes:

| Field | Meaning |
| --- | --- |
| `stretchPercent` | `(stretched − original) / original × 100` |
| `residualGrowthPercent` | `(released − original) / original × 100` |
| `recoveredExtensionPercent` | `(stretched − released) / (stretched − original) × 100`; `null` with no extension |
| `extension` | Stretched minus original, in the input unit |
| `residualExtension` | Released minus original, in the input unit |
| `unusualReleasedLength` | Released lies outside the original-to-stretched interval |

Values outside a customary percentage range are preserved. Invalid numeric input, reversed stretch readings or an overflowing result throws `RangeError`. Numeric results do not establish fabric suitability or garment fit.

## calculatePrintScale({ target, measuredX, measuredY, tolerancePercent? })

Use the intended side from the actual PDF and two measured positive finite sides in one unit. A single target is compared with both axes. The result includes scale percentages, signed axis errors, their absolute difference in percentage points, the two classification flags, and the threshold used.

`tolerancePercent` must be finite and non-negative; it defaults to 0.5. The implementation permits a small floating-point rounding slack at the exact threshold. The flags express numerical comparison only. Invalid inputs or an overflowing result throws `RangeError`; the function cannot establish why a printer changed scale.

## convertLength(value, fromUnit, toUnit)

The value must be finite. Supported unit codes are exactly `cm` and `in`, using 2.54 cm per inch. Equal units return the value unchanged. The conversion helper allows signed offsets; stretch and print functions still require positive lengths. Unsupported units or a non-finite value throws `RangeError`.

## csvCell(value)

Returns a quoted string, doubles embedded quotes and prefixes common formula-like non-numeric text. `null` and `undefined` become an empty cell. Numeric negative values keep their sign. This helper provides neither whole-file validation nor the anonymous-input policy of the separate Fabric-Care CSV Validator.

CSV imports depend on the consumer's spreadsheet settings. Review exported content in its intended destination; do not treat this helper as a complete spreadsheet-security or privacy validator.
