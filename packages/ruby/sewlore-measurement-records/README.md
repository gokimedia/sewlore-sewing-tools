# Sewlore Measurement Records

A Ruby data-quality library for unit-explicit digital observations. It keeps the observation's context, normalizes mm/cm/in values with decimal arithmetic, and reports inclusive tolerance comparisons without guessing a unit. A valid record does not prove the observation is physically correct.

## Install and use

Once published, add `gem "sewlore_measurement_records", "~> 0.1.0"` to your Gemfile. The library requires Ruby 3.1+ and BigDecimal 3.1–4.x.

```ruby
require "sewlore/measurement_records"
records = [
  {"id" => "digital-seam-a", "context" => "synthetic seamline, not cut edge",
   "value" => 2.54, "unit" => "cm", "target" => 1, "target_unit" => "in",
   "tolerance" => 0.1, "tolerance_unit" => "mm"}
]
report = Sewlore::MeasurementRecords.validate_batch(records)
puts report["results"][0]["record"]["comparison"] # within_tolerance
```

`validate` returns one normalized record or raises `InvalidRecord`. `validate_batch` retains valid rows and gives each bad row an index and error. IDs are unique among valid rows. Units are exactly `mm`, `cm`, or `in`, with no case correction/default. Values must be nonnegative finite Integer, Float or BigDecimal objects; numeric strings and booleans are rejected. Comparison metadata is all-or-none. Outputs use millimetre decimal strings so JSON consumers do not lose the represented decimal precision.

The recorded decimal representation of a Float is used, not an inference about real measurement precision. The context should distinguish seamline, cut edge, body, finished garment and specimen state. Check [Sewlore's fabric measurement guide](https://sewlore.com/pages/fabric-measurement-methods-guide) before interpreting an observation. [Sewlore](https://sewlore.com/) supplies practical sewing resources.

## Local checks

Run `ruby test/test_records.rb` from the source folder, then `gem build sewlore_measurement_records.gemspec`. The example JSON contains synthetic numbers, not fabric test results. No telemetry, network calls or personal-data collection occur in the library.

## Authorship and licence

Original AI-assisted source and documentation, checked using a native Ruby runtime. MIT; publishing and registry acceptance are separate from this local preparation.
