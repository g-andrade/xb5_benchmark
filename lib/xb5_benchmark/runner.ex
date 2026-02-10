defmodule Xb5Benchmark.Runner do
  @moduledoc false
  use TypedStruct

  require Logger

  alias Xb5Benchmark.Cases

  # import ExUnit.Assertions

  ## Constants

  @min_measurement_interval_multiplier 20

  @rand_algo :exsp

  ## Types

  ## API

  def run(opts \\ []) do
    cache = get_or_init_cache()

    Logger.notice("Preparing cases...")

    %{
      cases: cases,
      recommended_execution_seconds: recommended_execution_seconds,
      cache: cache
    } = Cases.prepare(cache, opts)

    save_cache(cache)

    run_time =
      case opts[:execution_seconds] do
        nil ->
          recommended_execution_seconds

        override ->
          override
      end

    ####

    Logger.notice("Running for #{pretty_time_left(run_time)}")

    run(cases, run_time)
  end

  def run(cases, seconds) do
    duration = ceil(seconds * System.convert_time_unit(1, :second, :native))

    samples_acc = %{}
    finish_ts = System.monotonic_time() + duration
    min_measurement_interval = min_measurement_interval()

    {%{uniform_n: rand_uniform}, rand_s_details} = :rand.seed_s(@rand_algo)
    rand_s = {@rand_algo, rand_s_details}

    samples_acc = run_recur(cases, rand_uniform, rand_s, min_measurement_interval, finish_ts, samples_acc)

    process_samples(samples_acc)
  end

  ## Internal

  defp get_or_init_cache() do
    case Process.get(__MODULE__.Cache) do
      nil ->
        cache = Cases.init_cache()
        Process.put(__MODULE__.Cache, cache)
        cache

      cache ->
        cache
    end
  end

  defp save_cache(cache) do
    Process.put(__MODULE__.Cache, cache)
  end

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

  defp process_samples(samples_acc) do
    samples_acc
    |> workerpool_map(fn {id, samples} ->
      {id, process_sample_group(samples)}
    end)
    |> Map.new()
  end

  defp process_sample_group(samples) do
    native_units_in_1sec = System.convert_time_unit(10, :second, :native)

    # Enum.take_random(samples, 10_000)
    downsampled = samples

    adjusted =
      Enum.map(
        downsampled,
        fn {count, duration, _measurement_ended_ts} ->
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

  defp min_measurement_interval do
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

  defp run_recur(cases, rand_uniform, rand_s, min_measurement_interval, finish_ts, samples_acc) do
    nr_of_cases = tuple_size(cases)
    {test_case_pos, rand_s} = rand_uniform.(nr_of_cases, rand_s)

    test_case = :erlang.element(test_case_pos, cases)
    {case_id, fun, arg} = test_case

    measurement_end_ts = System.monotonic_time() + min_measurement_interval

    [measurement_ended_ts | sample] = run_measurement(fun, arg, measurement_end_ts)

    samples_acc = accumulate_sample(samples_acc, case_id, sample)

    if measurement_ended_ts < finish_ts do
      run_recur(cases, rand_uniform, rand_s, min_measurement_interval, finish_ts, samples_acc)
    else
      samples_acc
    end
  end

  defp run_measurement(fun, arg, measurement_end_ts) do
    counter = 1
    measurement_start_ts = System.monotonic_time()

    [count | measurement_ended_ts] = run_measurement_recur(fun, arg, measurement_end_ts, counter)
    measurement_duration = measurement_ended_ts - measurement_start_ts

    sample = {count, measurement_duration, measurement_ended_ts}
    [measurement_ended_ts | sample]
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

  @compile {:inline, accumulate_sample: 3}
  defp accumulate_sample(samples_acc, case_id, sample) do
    Map.fetch!(samples_acc, case_id)
  catch
    :error, {:badkey, k} when k === case_id ->
      Map.put(samples_acc, case_id, [sample])
  else
    prev_id_samples ->
      %{samples_acc | case_id => [sample | prev_id_samples]}
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
