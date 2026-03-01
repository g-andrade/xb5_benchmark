defmodule Xb5Benchmark.Runner do
  @moduledoc false
  use TypedStruct

  require Logger

  alias Xb5Benchmark.Cases
  alias Xb5Benchmark.Cases.Case

  # import ExUnit.Assertions

  ## Constants

  @min_measurement_interval_multiplier 20

  # FIXME
  @recommended_seconds_per_case 3

  ## Types

  ## API

  def run(opts \\ []) do
    {cases, sampling_group_assignments} = assign_sampling_group_numbers(Cases.get(opts))
    cases = Enum.shuffle(cases)

    total_cases = length(cases)
    seconds = opts[:seconds] || (total_cases * @recommended_seconds_per_case)
    Logger.notice("Running #{total_cases} case(s) for #{pretty_time_left(seconds)}...")

    duration = ceil(seconds * System.convert_time_unit(1, :second, :native))

    samples_acc = []
    finish_ts = System.monotonic_time() + duration
    min_measurement_interval = min_measurement_interval()

    samples_acc = run_recur(cases, cases, min_measurement_interval, finish_ts, samples_acc)

    process_samples(samples_acc, sampling_group_assignments)
  end

  ## Internal

  defp pretty_time_left(seconds) when seconds >= 86400 do
    "#{floor(seconds / 86400)}d #{pretty_time_left(:math.fmod(seconds, 86400))}"
  end

  defp pretty_time_left(seconds) when seconds >= 3600 do
    "#{floor(seconds / 3600)}h#{pretty_time_left(:math.fmod(seconds, 3600))}"
  end

  defp pretty_time_left(seconds) when seconds >= 60 do
    "#{floor(seconds / 60)}m#{pretty_time_left(:math.fmod(seconds, 60))}"
  end

  defp pretty_time_left(seconds) when seconds > 0 do
    "#{floor(seconds)}s"
  end

  defp pretty_time_left(seconds) when seconds == 0 do
    ""
  end

  defp process_samples(samples_acc, sampling_group_assignments) do
    rev_sampling_group_assigmments = 
      Map.new(sampling_group_assignments, fn {number, group_key} -> {group_key, number} end)

    samples_acc
    |> group_samples(%{})
    |> workerpool_map(fn {group_number, samples} ->
      {group_number, process_sample_group(samples)}
    end)
    |> Map.new(
      fn {group_number, processed_group} ->
        group_key = %{} = Map.fetch!(rev_sampling_group_assigmments, group_number)
        {group_key, processed_group}
      end)
  end

  defp group_samples([sampling_group_number, sample | next], acc) do
    case Map.get(acc, sampling_group_number) do
      nil ->
        acc = Map.put(acc, sampling_group_number, [sample])
        group_samples(next, acc)

      prev ->
        acc = %{acc | sampling_group_number => [sample | prev]}
        group_samples(next, acc)
    end
  end

  defp group_samples([], acc) do
    acc
  end

  defp process_sample_group(samples) do
    native_units_in_1sec = System.convert_time_unit(10, :second, :native)

    # Enum.take_random(samples, 10_000)
    downsampled = samples

    adjusted =
      Enum.map(
        downsampled,
        fn [count | duration] ->
          count * native_units_in_1sec / duration
        end
      )

    stats = Statistex.statistics(adjusted, exclude_outliers: true)

    %{
      overall: %{stats | frequency_distribution: :removed, outliers: :removed}
      # history: process_stats_history(samples)
    }
  end

#  defp process_stats_history(samples) do
#    in_order = Enum.reverse(samples)
#
#    [{_, _, first_ts} | _] = in_order
#
#    process_stats_history_recur(in_order, first_ts, [])
#  end
#
#  defp process_stats_history_recur(next, prev_ts, acc) do
#    next_ts = prev_ts + System.convert_time_unit(1, :second, :native)
#
#    {next, acc} = process_stats_span(next, next_ts, acc)
#
#    stats = Statistex.statistics(acc)
#    stats = %{stats | frequency_distribution: :removed, outliers: :removed}
#
#    Logger.notice("Processed one more batch (#{length(next)} left)")
#
#    if next === [] do
#      [stats]
#    else
#      [stats | process_stats_history_recur(next, next_ts, acc)]
#    end
#  end
#
#  defp process_stats_span([{count, duration, measurement_ended_ts} | next], next_ts, acc) do
#    native_units_in_1sec = System.convert_time_unit(1, :second, :native)
#
#    if measurement_ended_ts < next_ts do
#      adjusted = count * native_units_in_1sec / duration
#      acc = [adjusted | acc]
#      process_stats_span(next, next_ts, acc)
#    else
#      {next, acc}
#    end
#  end
#
#  defp process_stats_span([], _next_ts, acc) do
#    {[], acc}
#  end

  def min_measurement_interval do
    # System.convert_time_unit(50, :millisecond, :native)
    mono_time_source = :erlang.system_info(:os_monotonic_time_source)

    used_resolution = Keyword.fetch!(mono_time_source, :used_resolution)

    native_units_in_1sec = System.convert_time_unit(1, :second, :native)

    @min_measurement_interval_multiplier *
      if native_units_in_1sec >= used_resolution do
        1
      else
        div(used_resolution, native_units_in_1sec)
      end
  end

  ##

  defp assign_sampling_group_numbers(cases) do
    assign_sampling_group_numbers_recur(cases, [], %{})
  end

  defp assign_sampling_group_numbers_recur([%Case{} = c | next], acc, mapped_groups) do
    group_key = sampling_group_key(c)

    case Map.get(mapped_groups, group_key) do
      nil ->
        new_assignment = map_size(mapped_groups)
        mapped_groups = Map.put(mapped_groups, group_key, new_assignment)
        acc = [%{c | sampling_group_number: new_assignment} | acc]
        assign_sampling_group_numbers_recur(next, acc, mapped_groups)

      assignment ->
        acc = [%{c | sampling_group_number: assignment} | acc]
        assign_sampling_group_numbers_recur(next, acc, mapped_groups)
    end
  end

  defp assign_sampling_group_numbers_recur([], acc, mapped_groups) do
    {acc, mapped_groups}
  end

  defp sampling_group_key(%Case{} = c) do
    %{
      build_type: c.build_type, 
      n: c.n, 
      impl_mod: c.group.impl_mod, 
      group_id: c.group.id,
      impl_description: c.group.impl_description,
      group_type: c.group.type,
      group_tweaks: c.group.tweaks
      }
  end

  ##

  defp run_recur(cases, [current_case | next], min_measurement_interval, finish_ts, samples_acc) do
    current_case = %Case{} = current_case
    fun_arg = resolve_case_fun_arg(current_case.fun_arg)

    measurement_end_ts = System.monotonic_time() + min_measurement_interval

    [measurement_ended_ts | samples_acc] = run_measurement(
      current_case.sampling_group_number, current_case.fun, fun_arg, measurement_end_ts, samples_acc
    )

    if measurement_ended_ts < finish_ts do
      run_recur(cases, next, min_measurement_interval, finish_ts, samples_acc)
    else
      samples_acc
    end
  end

  defp run_recur(cases, [], min_measurement_interval, finish_ts, samples_acc) do
    run_recur(cases, cases, min_measurement_interval, finish_ts, samples_acc)
  end

  ##

  defp resolve_case_fun_arg({:single, arg}) do
    arg
  end

  defp resolve_case_fun_arg({:random_pick, tuple}) do
    pick_pos = :rand.uniform(tuple_size(tuple))
    :erlang.element(pick_pos, tuple)
  end

  ##

  defp run_measurement(sampling_group_number, fun, arg, measurement_end_ts, samples_acc) do
    counter = 1
    measurement_start_ts = System.monotonic_time()

    [count | measurement_ended_ts] = run_measurement_recur(fun, arg, measurement_end_ts, counter)
    measurement_duration = measurement_ended_ts - measurement_start_ts

    sample = [count | measurement_duration]
    [measurement_ended_ts, sampling_group_number, sample | samples_acc]
  end

  defp run_measurement_recur(fun, arg, measurement_end_ts, counter) do
    fun.(arg)
    current_ts = System.monotonic_time()

    if current_ts < measurement_end_ts do
      run_measurement_recur(fun, arg, measurement_end_ts, counter + 1)
    else
      [counter | current_ts]
    end
  end

  #########

  defp workerpool_map(enum, fun) do
    import ExUnit.Assertions

    {:ok, _} = Application.ensure_all_started(:taskforce)

    tasks =
      enum
      |> Enum.with_index()
      |> Map.new(fn {value, index} ->
        {index, :taskforce.task(fun, [value], %{timeout: 300_000})}
      end)

    %{
      completed: completed_tasks,
      individual_timeouts: individual_timeouts,
      global_timeouts: global_timeouts
    } = :taskforce.execute(tasks)

    assert individual_timeouts === []
    assert global_timeouts === []

    completed_tasks
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.map(fn {_, mapped_value} -> mapped_value end)
  end
end
