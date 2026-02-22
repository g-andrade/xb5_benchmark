defmodule Xb5Benchmark do
  ####

  require Logger

  import ExUnit.Assertions

  alias Xb5Benchmark.Runner

  ####

  def run(output_dir, opts \\ []) do
    File.mkdir_p!(output_dir)

    final_stats = Runner.run(opts)
    save_raw_stats!(output_dir, :runtime, final_stats)

    Logger.notice("Merging output into CSV...")
    merge(output_dir, :runtime)
  end

  def merge(output_dir, name) do
    json_paths = Path.wildcard(Path.join([output_dir, "*", "*", "#{name}", "*.json"]))

    merged_rows = 
      json_paths
      |> Enum.map(&File.read!/1)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.flat_map(&merged_stats_rows/1)
      |> Enum.sort_by(&merged_stats_row_order/1)

    csv_headers = collect_csv_headers(merged_rows)

    csv_rows = 
      merged_rows
      |> Enum.map(&build_csv_row(&1, csv_headers))

    csv_path = Path.join(output_dir, "stats_#{name}.csv")
    csv = csv_output([csv_headers | csv_rows])
    File.write!(csv_path, csv)
  end


  #####

  defp save_raw_stats!(output_dir, name, final_stats) do
    final_stats
    |> Enum.group_by(&raw_stats_group_key/1)
    |> Enum.each(&save_raw_stats_group!(output_dir, name, &1))
  end

  defp raw_stats_group_key({sampling_group_key, _samples}) do
    Map.delete(sampling_group_key, :n)
  end

  defp save_raw_stats_group!(output_dir, name, {_regrouped_key, grouped}) do 
    json_measurements =
      grouped
      |> Enum.map(
        fn {sampling_group_key, stats} -> 
          %{n: n} = sampling_group_key
          {n, stats}
        end)
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(&json_raw_stats/1)

    #####

    {sampling_group_key, _} = Enum.at(grouped, 0)

    %{
      build_type: build_type,
      impl_mod: impl_mod,
      group_id: group_id,
      impl_description: impl_description,
      group_tweaks: group_tweaks
    } = sampling_group_key

    #####

    json_output = %{
      name: name,
      build_type: build_type,
      impl_mod: impl_mod,
      group_id: group_id,
      impl_description: impl_description,
      tweaks: raw_stats_case_group_tweaks(group_tweaks),
      measurements: json_measurements
    }

    #####

    group_output_dir = Path.join([output_dir, "build_#{build_type}", "#{impl_mod}", "#{name}"])
    File.mkdir_p!(group_output_dir)

    group_output_path = Path.join(group_output_dir, "#{group_id}.json")
    File.write!(group_output_path, Jason.encode!(json_output, pretty: true))
  end

  defp json_raw_stats({n, %{overall: %Statistex{} = stats}}) do
    map = Map.from_struct(stats)
    assert Map.get(map, :n) === nil
    Map.put(map, :n, n)
  end

  defp raw_stats_case_group_tweaks({tag, value}) when is_atom(tag) and (is_atom(value) or is_number(value)) do
    [tag, value]
  end

  defp raw_stats_case_group_tweaks(:none) do
    :none
  end

  #####

  defp merged_stats_rows(%{
    "build_type" => build_type_str, 
    "group_id" => group_id_str,
    "impl_description" => impl_description,
    "measurements" => measurements
  }) do
    rev_measurements = Enum.reverse(measurements)

    [
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "average", "average"),
      # Five-number summary
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "minimum", "minimum"),
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "25th_percentile", ["percentiles", "25"]),
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "median", "median"),
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "75th_percentile", ["percentiles", "75"]),
      merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, "maximum", "maximum")
    ]
  end

  defp merged_stats_row(build_type_str, group_id_str, impl_description, rev_measurements, measurement_id, json_path) do
    [
      {"build_type", build_type_str},
      {"group_id", group_id_str},
      {"measurement_name", measurement_id},
      {"impl_description", impl_description}
      | Enum.reduce(rev_measurements, [], &merge_measurement(&2, &1, json_path))
    ]
  end

  #defp merged_stats_case_group_id(case_group_id_str, input_amount) do
  #  prettier_case_id = prettier_case_id(case_group_id_str)

  #  case input_amount do
  #    integer when is_integer(integer) ->
  #      "#{prettier_case_id} x #{integer}"

  #    ["max", ceiling] when is_integer(ceiling) ->
  #      "#{prettier_case_id} x min(N, #{ceiling})"

  #    _ when input_amount in ["all", "none"] ->
  #      "#{prettier_case_id}"
  #  end
  #end

  #defp prettier_case_id("alternate_insert_and_delete") do
  #  "alternate [insert,delete]"
  #end

  #defp prettier_case_id("alternate_insert_largest_and_take_smallest") do
  #  "alternate [insert largest, take smallest]"
  #end

  #defp prettier_case_id("alternate_insert_smallest_and_take_largest") do
  #  "alternate [insert smallest, take largest]"
  #end

  #defp prettier_case_id(<<"percentile_", suffix::bytes>>) when suffix !== "rank" do
  #  "percentile (#{suffix})"
  #end

  #defp prettier_case_id(<<"filter_", suffix::bytes>>) when suffix !== "rank" do
  #  "filter (#{suffix})"
  #end

  #defp prettier_case_id(<<"is_", _::bytes>> = case_group_id) do
  #  "#{case_group_id}?"
  #end

  #defp prettier_case_id(case_group_id_str) do
  #  case_group_id_str
  #end

  defp merge_measurement(acc, %{"n" => n} = json, path) do
    [{"#{n}", json_measurement_fetch!(json, path)} | acc]
  end

  defp json_measurement_fetch!(json, <<key::bytes>>) do
    Map.fetch!(json, key)
  end

  defp json_measurement_fetch!(json, [key | next]) do
    json |> Map.fetch!(key) |> json_measurement_fetch!(next)
  end

  defp json_measurement_fetch!(json, []) do
    json
  end

  ###

  defp merged_stats_row_order(merged_row) do
    {_, build_type_str} = List.keyfind(merged_row, "build_type", 0)
    {_, impl_description} = List.keyfind(merged_row, "impl_description", 0)
    {_, group_id_str} = List.keyfind(merged_row, "group_id", 0)
    {_, measurement_name} = List.keyfind(merged_row, "measurement_name", 0)

    [
      build_type_str_order(build_type_str),
      group_id_str,
      measurement_name_order(measurement_name),
      impl_description
    ]
  end

  defp build_type_str_order("sequential"), do: 1
  defp build_type_str_order("random"), do: 2
  defp build_type_str_order("from_ordset_or_orddict"), do: 3
  defp build_type_str_order("xb5_adversarial"), do: 4

  defp measurement_name_order("average"), do: 1
  defp measurement_name_order("minimum"), do: 2
  defp measurement_name_order("25th_percentile"), do: 3
  defp measurement_name_order("median"), do: 4
  defp measurement_name_order("75th_percentile"), do: 5
  defp measurement_name_order("maximum"), do: 6

  ###

  defp collect_csv_headers(merged_rows) do
    merged_rows
    |> Enum.sort_by(&(List.keymember?(&1, "0", 0)), :desc)
    |> Enum.reduce(%{}, &collect_row_csv_keys/2)
    |> Enum.sort_by(fn {_key, order} -> order end)
    |> Enum.map(fn {key, _order} -> key end)
  end

  defp collect_row_csv_keys(row, acc) do
    Enum.reduce(row, acc, &collect_row_csv_key/2)
  end

  defp collect_row_csv_key({key, _value}, acc) do
    if is_map_key(acc, key) do
      acc
    else
      order = map_size(acc) + 1
      Map.put(acc, key, order)
    end
  end

  defp build_csv_row(merged_row, csv_headers) do
    Enum.map(
      csv_headers,
      fn key ->
        case List.keyfind(merged_row, key, 0) do
          {_, value} ->
            "#{value}"

          _ ->
            ""
        end
      end)
  end

  defp csv_output(rows) do
    Enum.map(rows, &csv_row_output/1)
  end

  defp csv_row_output([last_column]) do
    [csv_escape(last_column), "\n"]
  end

  defp csv_row_output([column | next]) do
    [csv_escape(column), "," | csv_row_output(next)]
  end

  defp csv_escape(column) do
    cond do
      String.contains?(column, "\"") ->
        ["\"", String.replace(column, "\"", "\"\""), "\""]

      String.contains?(column, ",") ->
        ["\"", column, "\""]

      true ->
        column
    end
  end
end
