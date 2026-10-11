# frozen_string_literal: true
require_relative "../lib/sewlore/measurement_records"
R = Sewlore::MeasurementRecords
checks = 0
check = ->(condition, name) { checks += 1; raise "FAIL: #{name}" unless condition }
bad = ->(name, &block) { checks += 1; begin; block.call; raise "FAIL: accepted #{name}"; rescue R::InvalidRecord; end }
base = { "id" => "digital-a", "context" => "synthetic seamline length", "value" => 2.54, "unit" => "cm", "target" => 1, "target_unit" => "in", "tolerance" => 0, "tolerance_unit" => "mm" }
check.call(R.validate(base)["comparison"] == "within_tolerance", "cross-unit exact inch")
check.call(R.to_mm(0.1, "cm") == BigDecimal("1"), "decimal tenth")
check.call(R.validate(base.merge("value" => 2.55, "tolerance" => 0.1))["comparison"] == "within_tolerance", "inclusive boundary")
check.call(R.validate(base.merge("value" => 2.551, "tolerance" => 0.1))["comparison"] == "outside_tolerance", "outside boundary")
check.call(R.validate(base.reject { |k, _v| %w[target target_unit tolerance tolerance_unit].include?(k) })["comparison"] == "not_requested", "standalone observation")
bad.call("missing unit") { R.validate(base.reject { |k, _v| k == "unit" }) }
bad.call("unknown unit") { R.to_mm(1, "CM") }
bad.call("negative measurement") { R.to_mm(-1, "mm") }
bad.call("infinity") { R.to_mm(Float::INFINITY, "mm") }
bad.call("nan") { R.to_mm(Float::NAN, "mm") }
bad.call("numeric string") { R.to_mm("12", "mm") }
bad.call("nil") { R.to_mm(nil, "mm") }
bad.call("negative tolerance") { R.validate(base.merge("tolerance" => -1)) }
bad.call("partial comparison") { R.validate(base.reject { |k, _v| k == "target_unit" }) }
bad.call("empty context") { R.validate(base.merge("context" => " ")) }
bad.call("symbol keys") { R.validate(id: "x", unit: "mm", value: 2) }
bad.call("wrong batch") { R.validate_batch({}) }
batch = R.validate_batch([base, base, base.merge("id" => "digital-b", "unit" => "bad"), base.merge("id" => "digital-c")])
check.call(batch["valid_count"] == 2 && batch["invalid_count"] == 2, "partial batch retained")
check.call(batch["results"][1]["error"].include?("duplicate"), "duplicate id")
check.call(R.to_mm(BigDecimal("0.05"), "in") == BigDecimal("1.27"), "BigDecimal direct")
check.call(R.validate_batch([])["valid_count"] == 0, "empty batch")
puts({checks: checks, passed: true}.inspect)
