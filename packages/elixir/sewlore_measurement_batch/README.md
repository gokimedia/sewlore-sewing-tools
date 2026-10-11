# Sewlore Measurement Batch

An Elixir utility that retains every batch row while validating explicit units, context and duplicate identities. Decimal arithmetic makes inclusive cross-unit tolerance comparisons without a hidden epsilon. It does not guess missing units or certify a physical material, pattern or garment.

## Usage

Once published, add `{:sewlore_measurement_batch, "~> 0.1.0"}` to your Mix dependencies. Elixir 1.14+ is required; Decimal is the sole runtime dependency.

```elixir
records = [%{
  "id" => "synthetic-seam-a", "context" => "digital seamline, not cut edge",
  "value" => 2.54, "unit" => "cm", "target" => 1, "target_unit" => "in",
  "tolerance" => 0.1, "tolerance_unit" => "mm"
}]
{:ok, report} = SewloreMeasurementBatch.validate_batch(records)
report["results"] |> hd() |> get_in(["record", "comparison"])
# "within_tolerance"
```

Each map uses string keys. Units must be exactly `mm`, `cm`, or `in`. Values are nonnegative finite integers/floats; strings and booleans are rejected. A comparison requires all four fields `target`, `target_unit`, `tolerance`, `tolerance_unit`. Outputs are millimetre decimal strings; a Float is converted from its supplied decimal representation. Duplicate IDs are invalid after their first valid occurrence; invalid rows remain in order and do not cancel the batch. `to_mm/2` and `validate/1` return `{:ok, result}` or `{:error, reason}`.

## Interpretation

Carry the question and specimen state with the result. Distinguish a cut edge from a seamline and a body measure from finished garment ease. [Sewlore's measurement guide](https://sewlore.com/pages/fabric-measurement-methods-guide) explains the practical context; [Sewlore](https://sewlore.com/) provides further sewing methods.

## Development

Run `mix deps.get`, `mix test`, `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix docs`, and `mix hex.build`. ExDoc is development-only and is not a runtime dependency. The library makes no network requests and has no telemetry. Examples are synthetic digital records, not observed fabric test data.

## Authorship and licence

Original AI-assisted source/documentation with native Elixir tests and generated ExDoc HTML. MIT. Registry publication and HexDocs availability are separate actions; local docs are not a live backlink.
