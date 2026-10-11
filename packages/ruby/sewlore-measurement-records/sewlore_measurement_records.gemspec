# frozen_string_literal: true
require_relative "lib/sewlore/measurement_records/version"
Gem::Specification.new do |spec|
  spec.name = "sewlore_measurement_records"
  spec.version = Sewlore::MeasurementRecords::VERSION
  spec.authors = ["Sewlore"]
  spec.summary = "Unit-explicit measurement record validation with decimal tolerances"
  spec.description = "Normalizes mm, cm, and inch observations, validates required context and batch IDs, and performs inclusive decimal tolerance comparisons. It never guesses missing units or certifies physical fabric or fit."
  spec.homepage = "https://sewlore.com/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE CHANGELOG.md examples/records.json]
  spec.require_paths = ["lib"]
  spec.metadata = {
    "homepage_uri" => "https://sewlore.com/",
    "documentation_uri" => "https://sewlore.com/pages/fabric-measurement-methods-guide",
    "bug_tracker_uri" => "https://github.com/gokimedia/sewlore-sewing-tools/issues",
    "rubygems_mfa_required" => "true"
  }
  spec.add_dependency "bigdecimal", ">= 3.1", "< 5"
end
