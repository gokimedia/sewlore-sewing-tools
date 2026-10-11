# frozen_string_literal: true
require "bigdecimal"
require_relative "measurement_records/version"

module Sewlore
  # Validate unit-explicit digital measurement records without guessing units.
  # Comparisons are numerical consistency checks, not a fabric/fit certification.
  module MeasurementRecords
    FACTORS = { "mm" => BigDecimal("1"), "cm" => BigDecimal("10"), "in" => BigDecimal("25.4") }.freeze
    class InvalidRecord < ArgumentError; end

    module_function

    def decimal(value, name)
      unless value.is_a?(Integer) || value.is_a?(Float) || value.is_a?(BigDecimal)
        raise InvalidRecord, "#{name} must be a finite numeric value"
      end
      parsed = BigDecimal(value.to_s)
      raise InvalidRecord, "#{name} must be finite" unless parsed.finite?
      raise InvalidRecord, "#{name} must be nonnegative" if parsed.negative?
      parsed
    end

    def to_mm(value, unit)
      raise InvalidRecord, "unit must be exactly mm, cm, or in" unless FACTORS.key?(unit)
      decimal(value, "value") * FACTORS.fetch(unit)
    end

    def validate(record)
      raise InvalidRecord, "record must be a Hash with string keys" unless record.is_a?(Hash) && record.keys.all? { |key| key.is_a?(String) }
      %w[id context].each do |key|
        raise InvalidRecord, "#{key} must be a nonempty String" unless record[key].is_a?(String) && !record[key].strip.empty?
      end
      value = to_mm(record.fetch("value") { raise InvalidRecord, "value is required" }, record["unit"])
      output = { "id" => record["id"], "context" => record["context"], "value_mm" => value.to_s("F"), "comparison" => "not_requested" }
      keys = %w[target target_unit tolerance tolerance_unit]
      if keys.any? { |key| record.key?(key) }
        raise InvalidRecord, "comparison requires target, target_unit, tolerance, tolerance_unit" unless keys.all? { |key| record.key?(key) }
        target = to_mm(record["target"], record["target_unit"])
        tolerance = to_mm(record["tolerance"], record["tolerance_unit"])
        deviation = value - target
        output.merge!("target_mm" => target.to_s("F"), "tolerance_mm" => tolerance.to_s("F"), "deviation_mm" => deviation.to_s("F"), "comparison" => deviation.abs <= tolerance ? "within_tolerance" : "outside_tolerance")
      end
      output
    end

    def validate_batch(records)
      raise InvalidRecord, "batch must be an Array" unless records.is_a?(Array)
      seen = {}
      results = records.each_with_index.map do |record, index|
        begin
          normalized = validate(record)
          id = normalized.fetch("id")
          raise InvalidRecord, "duplicate id: #{id}" if seen.key?(id)
          seen[id] = true
          { "index" => index, "valid" => true, "record" => normalized }
        rescue InvalidRecord => error
          { "index" => index, "valid" => false, "error" => error.message }
        end
      end
      { "valid_count" => results.count { |result| result["valid"] }, "invalid_count" => results.count { |result| !result["valid"] }, "results" => results }
    end
  end
end
