defmodule SewloreMeasurementBatch do
  @moduledoc """
  Validates batches of digital measurements with explicit units and context.

  Each record uses **string keys** `id`, `context`, `value` and `unit`.
  Units are exactly `mm`, `cm`, or `in`; no inference or default is applied.
  A comparison additionally requires `target`, `target_unit`, `tolerance`
  and `tolerance_unit`. Tolerances are inclusive and nonnegative.

  Returned values are decimal strings in millimetres. Decimal arithmetic
  compares the supplied decimal representation, avoiding binary epsilon
  rules. This is a data-quality utility; a valid record or a within-tolerance
  number does not certify physical measurement, material suitability or fit.

  See [Sewlore's measurement methods](https://sewlore.com/pages/fabric-measurement-methods-guide)
  for the practical questions that should accompany an observation.
  """
  alias Decimal, as: D
  @factors %{"mm" => "1", "cm" => "10", "in" => "25.4"}
  @comparison_keys ~w(target target_unit tolerance tolerance_unit)

  @doc "Converts a nonnegative finite number to a millimetre decimal string."
  @spec to_mm(number(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def to_mm(value, unit) do
    with {:ok, decimal} <- decimal(value, "value"),
         {:ok, factor} <- factor(unit) do
      {:ok, decimal |> D.mult(factor) |> D.to_string(:normal)}
    end
  end

  @doc "Normalizes one unit-explicit record, or returns a descriptive error."
  @spec validate(map()) :: {:ok, map()} | {:error, String.t()}
  def validate(record) when is_map(record) do
    with true <- Enum.all?(Map.keys(record), &is_binary/1),
         :ok <- text(record["id"], "id"),
         :ok <- text(record["context"], "context"),
         {:ok, value} <- normalize(record["value"], record["unit"]),
         {:ok, comparison} <- compare(record, value) do
      {:ok,
       Map.merge(
         %{
           "id" => record["id"],
           "context" => record["context"],
           "value_mm" => D.to_string(value, :normal)
         },
         comparison
       )}
    else
      false -> {:error, "record keys must be strings"}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(_record), do: {:error, "record must be a map"}

  @doc "Retains each row's result, rejects duplicate valid IDs, and counts outcomes."
  @spec validate_batch(list()) :: {:ok, map()} | {:error, String.t()}
  def validate_batch(records) when is_list(records) do
    {results, _seen} =
      records
      |> Enum.with_index()
      |> Enum.map_reduce(MapSet.new(), fn {record, index}, seen ->
        case validate(record) do
          {:ok, normalized} ->
            id = normalized["id"]

            if MapSet.member?(seen, id) do
              {%{"index" => index, "valid" => false, "error" => "duplicate id: #{id}"}, seen}
            else
              {%{"index" => index, "valid" => true, "record" => normalized}, MapSet.put(seen, id)}
            end

          {:error, reason} ->
            {%{"index" => index, "valid" => false, "error" => reason}, seen}
        end
      end)

    valid = Enum.count(results, & &1["valid"])

    {:ok,
     %{"valid_count" => valid, "invalid_count" => length(results) - valid, "results" => results}}
  end

  def validate_batch(_records), do: {:error, "batch must be a list"}

  defp normalize(value, unit) do
    with {:ok, decimal} <- decimal(value, "value"),
         {:ok, multiplier} <- factor(unit),
         do: {:ok, D.mult(decimal, multiplier)}
  end

  defp factor(unit) do
    case Map.fetch(@factors, unit) do
      {:ok, value} -> {:ok, D.new(value)}
      :error -> {:error, "unit must be exactly mm, cm, or in"}
    end
  end

  defp decimal(value, label) when is_integer(value) or is_float(value) do
    number = if is_integer(value), do: D.new(value), else: D.from_float(value)

    if D.compare(number, D.new(0)) == :lt,
      do: {:error, "#{label} must be nonnegative"},
      else: {:ok, number}
  rescue
    _ -> {:error, "#{label} must be finite"}
  end

  defp decimal(_value, label), do: {:error, "#{label} must be a finite numeric value"}

  defp text(value, label) when is_binary(value) do
    if String.trim(value) == "", do: {:error, "#{label} must be nonempty"}, else: :ok
  end

  defp text(_value, label), do: {:error, "#{label} must be a nonempty string"}

  defp compare(record, value) do
    present = Enum.count(@comparison_keys, &Map.has_key?(record, &1))

    cond do
      present == 0 ->
        {:ok, %{"comparison" => "not_requested"}}

      present != 4 ->
        {:error, "comparison requires target, target_unit, tolerance, tolerance_unit"}

      true ->
        with {:ok, target} <- normalize(record["target"], record["target_unit"]),
             {:ok, tolerance} <- normalize(record["tolerance"], record["tolerance_unit"]) do
          deviation = D.sub(value, target)

          verdict =
            if D.compare(D.abs(deviation), tolerance) in [:lt, :eq],
              do: "within_tolerance",
              else: "outside_tolerance"

          {:ok,
           %{
             "target_mm" => D.to_string(target, :normal),
             "tolerance_mm" => D.to_string(tolerance, :normal),
             "deviation_mm" => D.to_string(deviation, :normal),
             "comparison" => verdict
           }}
        end
    end
  end
end
