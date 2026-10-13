-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 Sewlore
-- Pure Lua; all inputs are supplied by the caller. No network or file access.

local M = { _VERSION = "0.1.0" }
local factors = { mm = 1.0, cm = 10.0, ["in"] = 25.4 }
local roles = { gauge = true, seam = true, cut = true, edge = true }
local fields = { "sample_id", "span_id", "direction", "state" }

local function identifier(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function to_mm(value, factor)
    if not finite(value) then return nil, "coordinate_not_finite_number" end
    local converted = value * factor
    if not finite(converted) or (value ~= 0 and converted == 0) then
        return nil, "coordinate_numeric_range"
    end
    return converted
end

local function span(x1, y1, x2, y2)
    local dx, dy = math.abs(x2 - x1), math.abs(y2 - y1)
    if not finite(dx) or not finite(dy) then return nil, "span_numeric_range" end
    local largest = math.max(dx, dy)
    if largest == 0 then return 0 end
    local length = largest * math.sqrt((dx / largest)^2 + (dy / largest)^2)
    if not finite(length) then return nil, "span_numeric_range" end
    return length
end

--- Validate a straight two-point span and return an independent mm record.
-- Success: normalized_record. Failure: nil, stable_reason_string.
function M.normalize(record)
    if type(record) ~= "table" then return nil, "record_not_table" end
    for _, name in ipairs(fields) do
        if not identifier(record[name]) then return nil, name .. "_required" end
    end
    if record.method ~= "straight_span" then return nil, "method_not_supported" end
    if not roles[record.line_role] then return nil, "line_role_not_supported" end
    local factor = factors[record.unit]
    if not factor then return nil, "unit_not_supported" end
    local points = record.endpoints
    if type(points) ~= "table" then return nil, "exactly_two_endpoints_required" end
    for key in pairs(points) do
        if key ~= 1 and key ~= 2 then return nil, "exactly_two_endpoints_required" end
    end
    if type(points[1]) ~= "table" or type(points[2]) ~= "table" then
        return nil, "exactly_two_endpoints_required"
    end
    local normalized = {
        sample_id = record.sample_id,
        span_id = record.span_id,
        direction = record.direction,
        state = record.state,
        method = record.method,
        line_role = record.line_role,
        unit = "mm",
        input_unit = record.unit,
        endpoints = {},
    }
    for i = 1, 2 do
        local point = points[i]
        if not identifier(point.id) then return nil, "endpoint_id_required" end
        local x, xerr = to_mm(point.x, factor)
        if x == nil then return nil, xerr end
        local y, yerr = to_mm(point.y, factor)
        if y == nil then return nil, yerr end
        normalized.endpoints[i] = { id = point.id, x = x, y = y }
    end
    local a, b = normalized.endpoints[1], normalized.endpoints[2]
    if a.id == b.id then return nil, "endpoint_ids_not_distinct" end
    local length, err = span(a.x, a.y, b.x, b.y)
    if length == nil then return nil, err end
    normalized.length_mm = length
    return normalized
end

--- Compare two readings only when their declared references agree.
-- Endpoint order may reverse: an unsigned straight span is symmetric.
-- State labels are retained; equal labels permit repeated-read comparisons.
function M.compare(baseline, later)
    local first, ferr = M.normalize(baseline)
    if first == nil then return nil, "baseline_invalid:" .. ferr end
    local second, serr = M.normalize(later)
    if second == nil then return nil, "later_invalid:" .. serr end
    for _, name in ipairs({ "sample_id", "span_id", "direction", "method", "line_role" }) do
        if first[name] ~= second[name] then return nil, name .. "_mismatch" end
    end
    local a, b = first.endpoints[1].id, first.endpoints[2].id
    local c, d = second.endpoints[1].id, second.endpoints[2].id
    if not ((a == c and b == d) or (a == d and b == c)) then
        return nil, "endpoint_pair_mismatch"
    end
    if first.length_mm == 0 then return nil, "baseline_span_zero" end
    local change = second.length_mm - first.length_mm
    local percent = (change / first.length_mm) * 100.0
    if not finite(percent) then return nil, "comparison_numeric_range" end
    return {
        baseline = first,
        later = second,
        change_mm = change,
        percent_change = percent,
        percent_decrease = -percent,
    }
end

return M
