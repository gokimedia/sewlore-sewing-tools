defmodule SewloreMeasurementBatchTest do
  use ExUnit.Case, async: true
  alias SewloreMeasurementBatch, as: Batch

  defp record,
    do: %{
      "id" => "synthetic-a",
      "context" => "digital seamline example",
      "value" => 2.54,
      "unit" => "cm",
      "target" => 1,
      "target_unit" => "in",
      "tolerance" => 0,
      "tolerance_unit" => "mm"
    }

  test "exact cross-unit equality" do
    assert {:ok, %{"comparison" => "within_tolerance", "value_mm" => "25.40"}} =
             Batch.validate(record())
  end

  test "inclusive tolerance boundary and outside" do
    assert {:ok, %{"comparison" => "within_tolerance"}} =
             Batch.validate(Map.merge(record(), %{"value" => 2.55, "tolerance" => 0.1}))

    assert {:ok, %{"comparison" => "outside_tolerance"}} =
             Batch.validate(Map.merge(record(), %{"value" => 2.551, "tolerance" => 0.1}))
  end

  test "explicit conversions" do
    assert {:ok, "25.4"} = Batch.to_mm(1, "in")
    assert {:ok, "1.0"} = Batch.to_mm(0.1, "cm")
    assert {:ok, "0"} = Batch.to_mm(0, "mm")
  end

  test "missing or unknown units are never inferred" do
    for unit <- [nil, "CM", "inch", "", :mm], do: assert({:error, _} = Batch.to_mm(2, unit))
    assert {:error, _} = Batch.validate(Map.delete(record(), "unit"))
  end

  test "reject strings booleans negative and nonscalar values" do
    for value <- ["2", nil, true, -1, [], %{}], do: assert({:error, _} = Batch.to_mm(value, "mm"))
  end

  test "comparison metadata must be complete" do
    for key <- ~w(target target_unit tolerance tolerance_unit),
        do: assert({:error, _} = Batch.validate(Map.delete(record(), key)))
  end

  test "negative tolerance rejected" do
    assert {:error, _} = Batch.validate(Map.put(record(), "tolerance", -1))
  end

  test "context and identity required" do
    assert {:error, _} = Batch.validate(Map.put(record(), "context", " "))
    assert {:error, _} = Batch.validate(Map.put(record(), "id", nil))
    assert {:error, _} = Batch.validate(%{id: "x", context: "x", value: 2, unit: "mm"})
  end

  test "standalone record preserves no-comparison state" do
    assert {:ok, %{"comparison" => "not_requested"}} =
             Batch.validate(Map.drop(record(), ~w(target target_unit tolerance tolerance_unit)))
  end

  test "partial batch and duplicate IDs" do
    assert {:ok, result} =
             Batch.validate_batch([
               record(),
               record(),
               Map.put(record(), "id", "second"),
               Map.put(record(), "unit", "bad")
             ])

    assert result["valid_count"] == 2 and result["invalid_count"] == 2
    assert Enum.at(result["results"], 1)["error"] == "duplicate id: synthetic-a"
  end

  test "empty and wrong batch" do
    assert {:ok, %{"valid_count" => 0, "results" => []}} = Batch.validate_batch([])
    assert {:error, _} = Batch.validate_batch(%{})
    assert {:error, _} = Batch.validate(nil)
  end
end
