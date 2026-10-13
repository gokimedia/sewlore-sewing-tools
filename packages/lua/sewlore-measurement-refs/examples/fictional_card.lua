-- Run from the source package directory: lua examples/fictional_card.lua
local script = (arg and arg[0] or ""):gsub("\\", "/")
local example_root = script:match("^(.*)/[^/]+$") or "examples"
package.path = example_root .. "/../src/?.lua;" .. example_root .. "/../src/?/init.lua;" .. package.path
local refs = require("sewlore.measurement_refs")

-- Fictional coordinates; no physical fabric test was performed.
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
print(string.format("baseline=%.1f mm later=%.1f mm change=%.1f mm change=%.1f%%",
    report.baseline.length_mm, report.later.length_mm,
    report.change_mm, report.percent_change))
-- baseline=200.0 mm later=194.0 mm change=-6.0 mm change=-3.0%
-- This arithmetic cannot establish the shrinkage of an actual material.
