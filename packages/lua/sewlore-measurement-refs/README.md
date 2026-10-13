# Sewlore Measurement References for Lua

Keep the meaning of a measurement beside its number. This dependency-free Lua
module validates two named endpoints and explicit units, then compares two
straight spans only when their declared sample, span, direction and line role
agree. It is useful for a digital fabric-test card, pattern-reading exercise or
Lua sewing-tool prototype that must not silently compare a seamline with a cut
edge.

Related practical reading: [Sewlore fabric measurement methods](https://sewlore.com/pages/fabric-measurement-methods-guide).

## Source usage

The module can run directly from this source directory. Set `package.path` as
shown below; no other Lua module is required. For a repository containing several
packages, run this package's `test.lua` or example using its relative file path;
the scripts locate their own source directory.

```lua
package.path = "./src/?.lua;./src/?/init.lua;" .. package.path
local refs = require("sewlore.measurement_refs")

local baseline = {
    sample_id = "HYP-001", span_id = "width-gauge", direction = "widthwise",
    state = "hypothetical baseline: dry, flat, relaxed", method = "straight_span",
    line_role = "gauge", unit = "cm",
    endpoints = { { id = "A", x = 0, y = 0 }, { id = "B", x = 20, y = 0 } },
}
local later = {
    sample_id = "HYP-001", span_id = "width-gauge", direction = "widthwise",
    state = "hypothetical later: dry, flat, relaxed", method = "straight_span",
    line_role = "gauge", unit = "mm",
    endpoints = { { id = "A", x = 0, y = 0 }, { id = "B", x = 194, y = 0 } },
}
local report, reason = refs.compare(baseline, later)
assert(report, reason)
assert(report.baseline.length_mm == 200)
assert(report.later.length_mm == 194)
assert(report.change_mm == -6)
assert(report.percent_change == -3)
```

The example is fictional arithmetic: 20 cm is 200 mm, and the later span is 6 mm
shorter, or 3% of the baseline. No physical fabric test was performed. The module
does not identify fibre, infer warp/weft, prescribe fabric care, or recommend a
cutting allowance.

## API

`normalize(record)` returns an independent normalized record, or `nil, reason`.
Required text fields `sample_id`, `span_id`, `direction` and `state` cannot be
empty or whitespace only. Identity and direction strings are compared exactly;
they are never trimmed or guessed. `method` must be `straight_span`; `line_role`
must be `gauge`, `seam`, `cut` or `edge`. `unit` must be exactly `mm`, `cm` or
`in`. `endpoints` must be a table containing exactly positions 1 and 2. Each point
has a distinct nonempty `id` and finite numeric `x`, `y` coordinates. Negative
coordinates are allowed because the coordinate origin is arbitrary. Numeric
strings, unknown units, curved paths, NaN and infinities are rejected. Additional
fields on the outer record or point are ignored; copy separate protocol notes
yourself if needed.

Normalized coordinates and `length_mm` use millimetres; `input_unit` retains the
declared input unit. One centimetre is 10 mm; one inch is 25.4 mm. Input tables
are never modified and endpoint tables are copied.

`compare(baseline, later)` validates both records and requires identical
`sample_id`, `span_id`, `direction`, `method`, `line_role` and endpoint ID pairs.
The order of the pair may reverse because a straight unsigned span is symmetric.
Coordinates may move or rotate between states. Different state labels are
retained; equal labels also permit repeated-read comparisons. Agreement of
labels is a data check, not proof that a physical procedure was comparable.

The returned report contains both normalized records and:

| Field | Formula | Meaning |
| --- | --- | --- |
| `change_mm` | `later_length - baseline_length` | Positive is longer; negative is shorter. |
| `percent_change` | `change_mm / baseline_length * 100` | Signed change relative to the first span. |
| `percent_decrease` | `-percent_change` | Positive is shorter; negative is growth. |

A zero later span is valid; a zero baseline cannot be a denominator. Calculation
errors return stable strings such as `unit_not_supported`,
`endpoint_pair_mismatch`, `line_role_mismatch` or `baseline_span_zero`. Invalid
input includes `baseline_invalid:` or `later_invalid:` before its reason.

## Numeric limits

Ordinary Lua floating-point arithmetic is used. The Euclidean calculation scales
its operands before squaring to avoid unnecessary overflow. Non-finite
conversions, coordinate differences, lengths and percentages are rejected.
Rounding or lost low-order digits remain possible; this package does not provide
exact decimal arithmetic, uncertainty estimates or a tolerance decision. The
reported percentage is not clamped or rounded. Use appropriate measurement
precision and record the physical protocol independently.

## Development

From this source directory:

```text
lua test.lua
lua examples/fictional_card.lua
```

The dependency-free tests cover mixed units, translation and diagonal distance,
endpoint reversal, reference mismatches, immutability, missing context,
non-finite inputs, zero baselines and extreme numeric ranges.

Preparation QA ran all 24 behavioral tests and the example in native Lua 5.1,
5.2, 5.3, 5.4, 5.5 and LuaJIT 2.0/2.1 runtimes embedded by the development-only
Lupa 2.8 wheel on Windows. Lupa is not required to use or install this module.
LuaRocks 3.13.0 lint, make, test, source-rock packing and a fresh isolated
source-rock installation were also checked with Lua 5.1.5. The installed module
matched the original source byte for byte. This local packaging check is distinct
from availability of a public registry release.

## Origin and license

Original AI-assisted Lua source, example and documentation, prepared for Sewlore.
MIT; see LICENSE. The module makes no network requests and performs no file I/O.
It does not insert attribution into caller results or require a backlink from
users of the software.
