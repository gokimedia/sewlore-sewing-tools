-- Dependency-free behavioral tests; run: lua test.lua
local script = (arg and arg[0] or ""):gsub("\\", "/")
local source_root = script:match("^(.*)/[^/]+$") or "."
package.path = source_root .. "/src/?.lua;" .. source_root .. "/src/?/init.lua;" .. package.path
local refs = require("sewlore.measurement_refs")
local completed = {}

local function test(name, fn)
    fn()
    completed[#completed + 1] = name
end
local function near(actual, expected)
    assert(math.abs(actual - expected) <= 1e-10 * math.max(1, math.abs(expected)),
        tostring(actual) .. " differs from " .. tostring(expected))
end
local function record(length, unit)
    return {
        sample_id = "HYP-001", span_id = "A-B", direction = "widthwise",
        state = "fictional baseline", method = "straight_span", line_role = "gauge",
        unit = unit or "mm",
        endpoints = { { id = "A", x = 0, y = 0 }, { id = "B", x = length, y = 0 } },
    }
end
local function rejects(value, expected)
    local result, err = refs.normalize(value)
    assert(result == nil and err == expected, tostring(err) .. " expected " .. expected)
end
local function compare_rejects(a, b, expected)
    local result, err = refs.compare(a, b)
    assert(result == nil and err == expected, tostring(err) .. " expected " .. expected)
end

test("mixed cm/mm fictional card keeps sign and baseline", function()
    local a, b = record(20, "cm"), record(194, "mm")
    b.state = "fictional later"
    local result = assert(refs.compare(a, b))
    near(result.baseline.length_mm, 200); near(result.later.length_mm, 194)
    near(result.change_mm, -6); near(result.percent_change, -3)
    near(result.percent_decrease, 3)
    assert(result.baseline.state == a.state and result.later.state == b.state)
end)
test("inch and mm readings describe the same span", function()
    local result = assert(refs.compare(record(1, "in"), record(25.4, "mm")))
    near(result.change_mm, 0); near(result.percent_change, 0)
end)
test("diagonal translated span uses Euclidean distance", function()
    local r = record(1)
    r.endpoints[1].x, r.endpoints[1].y = -7, 11
    r.endpoints[2].x, r.endpoints[2].y = -4, 15
    near(assert(refs.normalize(r)).length_mm, 5)
end)
test("normalization does not alter caller or share endpoint tables", function()
    local r = record(20, "cm")
    local normalized = assert(refs.normalize(r))
    assert(r.unit == "cm" and r.endpoints[2].x == 20)
    normalized.endpoints[2].x = 999
    assert(r.endpoints[2].x == 20)
    r.endpoints[1].id = "changed"
    assert(normalized.endpoints[1].id == "A")
end)
test("reversed endpoint order is the same unsigned reference pair", function()
    local a, b = record(100), record(90)
    b.endpoints[1], b.endpoints[2] = b.endpoints[2], b.endpoints[1]
    near(assert(refs.compare(a, b)).percent_change, -10)
end)
test("different physical endpoint pair rejects misleading comparison", function()
    local a, b = record(100), record(90)
    b.endpoints[2].id = "C"
    compare_rejects(a, b, "endpoint_pair_mismatch")
end)
for _, name in ipairs({ "sample_id", "span_id", "direction", "line_role" }) do
    test(name .. " mismatch rejects comparison", function()
        local a, b = record(100), record(90)
        b[name] = name == "line_role" and "cut" or "different"
        compare_rejects(a, b, name .. "_mismatch")
    end)
end
test("equal state labels permit repeat readings", function()
    near(assert(refs.compare(record(100), record(101))).percent_change, 1)
end)
test("positive growth has negative percent decrease", function()
    local result = assert(refs.compare(record(100), record(110)))
    near(result.change_mm, 10); near(result.percent_change, 10)
    near(result.percent_decrease, -10)
end)
test("zero later span is valid but zero baseline cannot be a denominator", function()
    near(assert(refs.compare(record(100), record(0))).percent_decrease, 100)
    compare_rejects(record(0), record(100), "baseline_span_zero")
end)
test("missing unit and numeric strings are not guessed", function()
    local r = record(100); r.unit = nil; rejects(r, "unit_not_supported")
    r = record("100"); rejects(r, "coordinate_not_finite_number")
    r = record(100); r.unit = "CM"; rejects(r, "unit_not_supported")
end)
test("non-finite inputs are rejected", function()
    rejects(record(0/0), "coordinate_not_finite_number")
    rejects(record(math.huge), "coordinate_not_finite_number")
    rejects(record(-math.huge), "coordinate_not_finite_number")
end)
test("missing whitespace and duplicate identities reject", function()
    rejects(nil, "record_not_table")
    local r = record(100); r.state = "  \t"; rejects(r, "state_required")
    r = record(100); r.endpoints[2].id = "A"; rejects(r, "endpoint_ids_not_distinct")
    r = record(100); r.endpoints[1].id = ""; rejects(r, "endpoint_id_required")
end)
test("extra sparse or missing endpoint slots reject", function()
    local r = record(100); r.endpoints[3] = {id="C", x=1, y=1}
    rejects(r, "exactly_two_endpoints_required")
    r = record(100); r.endpoints[2] = nil; rejects(r, "exactly_two_endpoints_required")
    r = record(100); r.endpoints.label = "A-B"; rejects(r, "exactly_two_endpoints_required")
end)
test("curved paths and unknown line roles cannot silently become straight spans", function()
    local r = record(100); r.method = "curved_path"; rejects(r, "method_not_supported")
    r = record(100); r.line_role = "unknown"; rejects(r, "line_role_not_supported")
end)
test("validation errors identify which reading failed", function()
    compare_rejects(nil, record(10), "baseline_invalid:record_not_table")
    compare_rejects(record(10), nil, "later_invalid:record_not_table")
end)
test("large diagonal avoids squared-coordinate overflow", function()
    local r = record(1e200); r.endpoints[2].y = 1e200
    near(assert(refs.normalize(r)).length_mm / 1e200, math.sqrt(2))
end)
test("coordinate conversion overflow is rejected", function()
    rejects(record(1e308, "in"), "coordinate_numeric_range")
end)
test("subtraction overflow is rejected", function()
    local r = record(1e308); r.endpoints[1].x = -1e308
    rejects(r, "span_numeric_range")
end)
test("percentage overflow is rejected", function()
    compare_rejects(record(1e-300), record(1e300), "comparison_numeric_range")
end)
test("integer-sized coordinates use floating unit multiplication", function()
    near(assert(refs.normalize(record(1000000000000, "cm"))).length_mm, 10000000000000)
end)

-- Returning this report lets the optional embedded-runtime QA capture test names.
return { passed = #completed, tests = completed, lua_version = _VERSION }
