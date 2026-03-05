defmodule Xb5Benchmark.Runner do
  @moduledoc false
  use TypedStruct

  require Logger

  alias Xb5Benchmark.Cases.Case
  alias Xb5Benchmark.Groups.Group
  alias Xb5Benchmark.Utils

  # import ExUnit.Assertions

  ## Constants

  @min_measurement_interval_multiplier 20

  @min_stable_count_per_stats 4

  @batch_interval_seconds 60

  ## Types

  defmodule State do
    typedstruct do
      field(:batch_nr, pos_integer(), enforce: true)
      field(:nr_of_cases, pos_integer(), enforce: true)
      field(:min_measurement_interval, pos_integer(), enforce: true)
      field(:cases, [Case.t(), ...], enforce: true)
      field(:sampling_numbers_map, %{pos_integer => tuple()}, enforce: true)
      field(:collectors, %{term() => Xb5Benchmark.Runner.Collector.t()}, enforce: true)
      field(:run_list_amount_of_reshuffles, pos_integer, enforce: true)
      field(:run_list, [Case.t(), ...], enforce: true)
      field(:convergence_count, non_neg_integer, enforce: true)
      field(:convergence_limit, pos_integer, enforce: true)
    end
  end

  defmodule Collector do
    typedstruct do
      field(:build_type, atom, enforce: true)
      field(:group, Group.t(), enforce: true)

      field(
        :results_per_n,
        %{non_neg_integer => Xb5Benchmark.Runner.ResultsForSize.t(), enforce: true},
        enforce: true
      )
    end
  end

  defmodule ResultsForSize do
    typedstruct do
      field(:stats_history, [map], enforce: true)
      field(:processed_samples, [Xb5Benchmark.Runner.processed_sample()], enforce: true)
      field(:memory_stats, Statistex.t(), enforce: true)
      field(:ops_multiplier, number, enforce: true)
    end
  end

  @type sample ::
          nonempty_improper_list(
            count :: pos_integer(),
            measurement_duration :: pos_integer()
          )

  @type processed_sample :: float()

  ## API

  def run(cases) do
    Enum.each(:erlang.processes(), &:erlang.garbage_collect/1)

    Logger.notice("Collecting memory stats...")
    cases = Enum.map(cases, &collect_memory_stats/1)
    Enum.each(:erlang.processes(), &:erlang.garbage_collect/1)

    Logger.notice("Instantiating collectors...")
    collectors = new_collectors(cases)

    {cases, sampling_numbers_map} = assign_sampling_group_numbers(1, cases, collectors, [], %{})

    min_measurement_interval = min_measurement_interval()

    Logger.notice("Measuring time to run cases...")

    {time_to_run_cases, _} =
      :timer.tc(
        fn ->
          stop_ts = :after_one_run
          run_recur(cases, cases, min_measurement_interval, stop_ts, [])
        end,
        :native
      )

    run_list_amount_of_reshuffles = run_list_amount_of_reshuffles(cases, time_to_run_cases)
    Logger.notice("Doing #{run_list_amount_of_reshuffles} reshuffles on every batch")

    state = %State{
      batch_nr: 1,
      nr_of_cases: length(cases),
      min_measurement_interval: min_measurement_interval(),
      cases: cases,
      sampling_numbers_map: sampling_numbers_map,
      collectors: collectors,
      run_list_amount_of_reshuffles: run_list_amount_of_reshuffles,
      run_list: run_list(cases, run_list_amount_of_reshuffles),
      convergence_count: 0,
      convergence_limit: convergence_limit(collectors)
    }

    :erlang.garbage_collect()
    final_state = run_batches(state)

    Map.values(final_state.collectors)
  end

  ## Internal

  defp collect_memory_stats(%Case{} = c) do
    iteration_fun = c.group.iteration_fun
    {:single, iterations} = c.fun_arg

    samples =
      cond do
        is_function(iteration_fun, 1) ->
          collect_memory_stats_samples_fun1(iteration_fun, iterations)

        is_function(iteration_fun, 2) ->
          collect_memory_stats_samples_fun2(iteration_fun, iterations)
      end

    stats = stats(samples)
    %{c | memory_stats: stats}
  end

  defp collect_memory_stats_samples_fun1(iteration_fun, [arg | next]) do
    {bytes_used, _} = Benchee.Benchmark.Collect.Memory.collect(fn -> iteration_fun.(arg) end)
    [bytes_used | collect_memory_stats_samples_fun1(iteration_fun, next)]
  end

  defp collect_memory_stats_samples_fun1(_iteration_fun, []) do
    []
  end

  defp collect_memory_stats_samples_fun2(iteration_fun, [arg1, arg2 | next]) do
    {bytes_used, _} =
      Benchee.Benchmark.Collect.Memory.collect(fn -> iteration_fun.(arg1, arg2) end)

    [bytes_used | collect_memory_stats_samples_fun2(iteration_fun, next)]
  end

  defp collect_memory_stats_samples_fun2(_iteration_fun, []) do
    []
  end

  ############

  defp new_collectors(cases) do
    cases
    |> Enum.group_by(&collector_key/1)
    |> Map.new(fn {collector_key, [%Case{} = example_case | _] = cases} ->
      results_per_n =
        Map.new(
          cases,
          fn %Case{} = c ->
            {c.n,
             %ResultsForSize{
               stats_history: [],
               processed_samples: [],
               memory_stats: c.memory_stats,
               ops_multiplier: c.ops_multiplier
             }}
          end
        )

      collector = %Collector{
        build_type: example_case.build_type,
        group: example_case.group,
        results_per_n: results_per_n
      }

      {collector_key, collector}
    end)
  end

  defp assign_sampling_group_numbers(
         number,
         [c = %Case{} | next],
         collectors,
         mapped_cases,
         sampling_numbers_map
       ) do
    collector_key = collector_key(c)
    mapped_c = %{c | sampling_group_number: number}
    mapped_cases = [mapped_c | mapped_cases]
    sampling_numbers_map = Map.put(sampling_numbers_map, number, {collector_key, c.n})

    assign_sampling_group_numbers(
      number + 1,
      next,
      collectors,
      mapped_cases,
      sampling_numbers_map
    )
  end

  defp assign_sampling_group_numbers(_, [], _, mapped_cases, sampling_numbers_map) do
    {mapped_cases, sampling_numbers_map}
  end

  defp convergence_limit(collectors) do
    Enum.reduce(
      collectors,
      0,
      fn {_collector_key, %Collector{} = collector}, acc ->
        acc + @min_stable_count_per_stats * map_size(collector.results_per_n)
      end
    )
  end

  defp run_list_amount_of_reshuffles(cases, time_to_run_cases) do
    max_reshuffles_that_can_run =
      div(System.convert_time_unit(@batch_interval_seconds, :second, :native), time_to_run_cases)

    max_reshuffles_size_limit = div(100_000, length(cases))
    max(1, min(max_reshuffles_that_can_run, min(max_reshuffles_size_limit, 50)))
  end

  defp run_list(cases, amount_of_reshuffles) do
    Enum.flat_map(1..amount_of_reshuffles//1, fn _ -> Enum.shuffle(cases) end)
  end

  defp run_batches(%State{} = state) do
    batch_interval_seconds = @batch_interval_seconds
    batch_interval = System.convert_time_unit(batch_interval_seconds, :second, :native)
    stop_ts = System.monotonic_time() + batch_interval

    convergence_progress = floor(100 * state.convergence_count / state.convergence_limit)

    progress_str =
      "#{convergence_progress}% [#{state.convergence_count}/#{state.convergence_limit}]"

    Logger.notice(
      "Running batch ##{state.batch_nr} for #{batch_interval_seconds}s (#{progress_str})"
    )

    batch_samples =
      run_recur(state.run_list, state.run_list, state.min_measurement_interval, stop_ts, [])

    Logger.notice("Collecting batch samples...")
    grouped_batch_samples = group_batch_samples(batch_samples, state.sampling_numbers_map, %{})
    collectors = collect_batch_samples(state.collectors, grouped_batch_samples)
    state = %{state | collectors: collectors}

    convergence_count = convergence_count(state.collectors)
    state = %{state | convergence_count: convergence_count}

    cond do
      convergence_count === state.convergence_limit ->
        state

      convergence_count < state.convergence_limit ->
        run_list = run_list(state.cases, state.run_list_amount_of_reshuffles)
        state = %{state | batch_nr: state.batch_nr + 1, run_list: run_list}
        :erlang.garbage_collect()
        run_batches(state)
    end
  end

  defp group_batch_samples([case_nr, sample | next], sampling_numbers_map, acc) do
    {collector_key, n} = Map.fetch!(sampling_numbers_map, case_nr)

    case Map.get(acc, collector_key) do
      nil ->
        acc = Map.put(acc, collector_key, %{n => [sample]})
        group_batch_samples(next, sampling_numbers_map, acc)

      collector_samples ->
        acc =
          case Map.get(collector_samples, n) do
            nil ->
              %{acc | collector_key => Map.put(collector_samples, n, [sample])}

            prev_samples_for_n ->
              %{acc | collector_key => %{collector_samples | n => [sample | prev_samples_for_n]}}
          end

        group_batch_samples(next, sampling_numbers_map, acc)
    end
  end

  defp group_batch_samples([], _sampling_numbers_map, acc) do
    acc
  end

  defp collector_key(the_case) do
    {the_case.build_type, the_case.group.impl_mod, the_case.group.id}
  end

  defp collect_batch_samples(collectors, grouped_batch_samples) do
    Enum.reduce(grouped_batch_samples, collectors, &collect_samples/2)
  end

  defp collect_samples({collector_key, collector_samples}, collectors) do
    collector = %Collector{} = Map.fetch!(collectors, collector_key)

    merged_results_per_n =
      Enum.reduce(collector_samples, collector.results_per_n, &merge_results_for_size/2)

    collector = %{collector | results_per_n: merged_results_per_n}
    %{collectors | collector_key => collector}
  end

  defp merge_results_for_size({n, samples}, results_per_n) do
    results = %ResultsForSize{} = Map.get(results_per_n, n)

    processed_samples =
      processed_samples(results.ops_multiplier, samples, results.processed_samples)

    results = %{
      results
      | stats_history: [stats(processed_samples) | results.stats_history],
        processed_samples: processed_samples
    }

    %{results_per_n | n => results}
  end

  defp processed_samples(ops_multiplier, [sample | next], acc) do
    [count | measurement_duration] = sample

    processed_sample =
      ops_multiplier * count * System.convert_time_unit(1, :second, :native) /
        measurement_duration

    acc = [processed_sample | acc]
    processed_samples(ops_multiplier, next, acc)
  end

  defp processed_samples(_ops_multiplier, [], acc) do
    acc
  end

  defp stats(processed_samples) do
    stats = Statistex.statistics(processed_samples, exclude_outliers: true)
    %{stats | frequency_distribution: :removed, outliers: :removed}
  end

  defp convergence_count(collectors) do
    Enum.reduce(collectors, 0, &(&2 + collector_convergence_count(&1)))
  end

  defp collector_convergence_count({_collector_key, %Collector{} = collector}) do
    Enum.reduce(collector.results_per_n, 0, &(&2 + results_for_size_convergence_count(&1)))
  end

  defp results_for_size_convergence_count({_n, %ResultsForSize{} = results}) do
    plateaus = stats_plateaus(results.stats_history)
    stable_count = plateaus |> Enum.take_while(&(&1 <= 0.05)) |> length()
    min(stable_count, @min_stable_count_per_stats)
  end

  defp stats_plateaus([%Statistex{}]) do
    []
  end

  defp stats_plateaus([%Statistex{} = stats2, %Statistex{} = stats1]) do
    [stats_plateau_measurement(stats1, stats2)]
  end

  defp stats_plateaus([%Statistex{} = stats2 | [%Statistex{} = stats1 | _] = next]) do
    [stats_plateau_measurement(stats1, stats2) | stats_plateaus(next)]
  end

  defp stats_plateau_measurement(%Statistex{} = stats1, %Statistex{} = stats2) do
    abs(stats2.median - stats1.median) / stats1.median
  end

  #  def run(opts \\ []) do
  #    {cases, sampling_group_assignments} = assign_sampling_group_numbers(Cases.get(opts))
  #    cases = Enum.shuffle(cases)
  #
  #    total_cases = length(cases)
  #    seconds = opts[:seconds] || (total_cases * @recommended_seconds_per_case)
  #    Logger.notice("Running #{total_cases} case(s) for #{pretty_time_left(seconds)}...")
  #
  #    duration = ceil(seconds * System.convert_time_unit(1, :second, :native))
  #
  #    samples_acc = []
  #    finish_ts = System.monotonic_time() + duration
  #    min_measurement_interval = min_measurement_interval()
  #
  #    samples_acc = run_recur(cases, cases, min_measurement_interval, finish_ts, samples_acc)
  #
  #    process_samples(samples_acc, sampling_group_assignments)
  #  end

  ## Internal

  ##  defp pretty_time_left(seconds) when seconds >= 86400 do
  ##    "#{floor(seconds / 86400)}d #{pretty_time_left(:math.fmod(seconds, 86400))}"
  ##  end
  ##
  ##  defp pretty_time_left(seconds) when seconds >= 3600 do
  ##    "#{floor(seconds / 3600)}h#{pretty_time_left(:math.fmod(seconds, 3600))}"
  ##  end
  ##
  ##  defp pretty_time_left(seconds) when seconds >= 60 do
  ##    "#{floor(seconds / 60)}m#{pretty_time_left(:math.fmod(seconds, 60))}"
  ##  end
  ##
  ##  defp pretty_time_left(seconds) when seconds > 0 do
  ##    "#{floor(seconds)}s"
  ##  end
  ##
  ##  defp pretty_time_left(seconds) when seconds == 0 do
  ##    ""
  ##  end
  ##
  ##  defp process_samples(samples_acc, sampling_group_assignments) do
  ##    rev_sampling_group_assigmments = 
  ##      Map.new(sampling_group_assignments, fn {number, group_key} -> {group_key, number} end)
  ##
  ##    samples_acc
  ##    |> group_samples(%{})
  ##    |> workerpool_map(fn {group_number, samples} ->
  ##      {group_number, process_sample_group(samples)}
  ##    end)
  ##    |> Map.new(
  ##      fn {group_number, processed_group} ->
  ##        group_key = %{} = Map.fetch!(rev_sampling_group_assigmments, group_number)
  ##        {group_key, processed_group}
  ##      end)
  ##  end
  ##
  ##  defp group_samples([sampling_group_number, sample | next], acc) do
  ##    case Map.get(acc, sampling_group_number) do
  ##      nil ->
  ##        acc = Map.put(acc, sampling_group_number, [sample])
  ##        group_samples(next, acc)
  ##
  ##      prev ->
  ##        acc = %{acc | sampling_group_number => [sample | prev]}
  ##        group_samples(next, acc)
  ##    end
  ##  end
  ##
  ##  defp group_samples([], acc) do
  ##    acc
  ##  end
  ##
  ##  defp process_sample_group(samples) do
  ##    native_units_in_1sec = System.convert_time_unit(10, :second, :native)
  ##
  ##    # Enum.take_random(samples, 10_000)
  ##    downsampled = samples
  ##
  ##    adjusted =
  ##      Enum.map(
  ##        downsampled,
  ##        fn [count | duration] ->
  ##          count * native_units_in_1sec / duration
  ##        end
  ##      )
  ##
  ##    stats = Statistex.statistics(adjusted, exclude_outliers: true)
  ##
  ##    %{
  ##      overall: %{stats | frequency_distribution: :removed, outliers: :removed}
  ##      # history: process_stats_history(samples)
  ##    }
  ##  end

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

  #  defp assign_sampling_group_numbers(cases) do
  #    assign_sampling_group_numbers_recur(cases, [], %{})
  #  end
  #
  #  defp assign_sampling_group_numbers_recur([%Case{} = c | next], acc, mapped_groups) do
  #    group_key = sampling_group_key(c)
  #
  #    case Map.get(mapped_groups, group_key) do
  #      nil ->
  #        new_assignment = map_size(mapped_groups)
  #        mapped_groups = Map.put(mapped_groups, group_key, new_assignment)
  #        acc = [%{c | sampling_group_number: new_assignment} | acc]
  #        assign_sampling_group_numbers_recur(next, acc, mapped_groups)
  #
  #      assignment ->
  #        acc = [%{c | sampling_group_number: assignment} | acc]
  #        assign_sampling_group_numbers_recur(next, acc, mapped_groups)
  #    end
  #  end
  #
  #  defp assign_sampling_group_numbers_recur([], acc, mapped_groups) do
  #    {acc, mapped_groups}
  #  end
  #
  #  defp sampling_group_key(%Case{} = c) do
  #    %{
  #      build_type: c.build_type, 
  #      n: c.n, 
  #      impl_mod: c.group.impl_mod, 
  #      group_id: c.group.id,
  #      impl_description: c.group.impl_description,
  #      group_type: c.group.type,
  #      group_tweaks: c.group.tweaks
  #      }
  #  end

  ##

  defp run_recur(run_list, [current_case | next], min_measurement_interval, stop_ts, samples_acc) do
    current_case = %Case{} = current_case
    fun_arg = resolve_case_fun_arg(current_case.fun_arg)

    measurement_end_ts = System.monotonic_time() + min_measurement_interval

    [measurement_ended_ts | samples_acc] =
      run_measurement(
        current_case.sampling_group_number,
        current_case.fun,
        fun_arg,
        measurement_end_ts,
        samples_acc
      )

    if measurement_ended_ts >= stop_ts do
      samples_acc
    else
      run_recur(run_list, next, min_measurement_interval, stop_ts, samples_acc)
    end
  end

  defp run_recur(run_list, [], min_measurement_interval, stop_ts, samples_acc) do
    if stop_ts === :after_one_run do
      samples_acc
    else
      run_recur(run_list, run_list, min_measurement_interval, stop_ts, samples_acc)
    end
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

  #  defp workerpool_map(enum, fun) do
  #    import ExUnit.Assertions
  #
  #    {:ok, _} = Application.ensure_all_started(:taskforce)
  #
  #    tasks =
  #      enum
  #      |> Enum.with_index()
  #      |> Map.new(fn {value, index} ->
  #        {index, :taskforce.task(fun, [value], %{timeout: 300_000})}
  #      end)
  #
  #    %{
  #      completed: completed_tasks,
  #      individual_timeouts: individual_timeouts,
  #      global_timeouts: global_timeouts
  #    } = :taskforce.execute(tasks)
  #
  #    assert individual_timeouts === []
  #    assert global_timeouts === []
  #
  #    completed_tasks
  #    |> Enum.sort_by(fn {index, _} -> index end)
  #    |> Enum.map(fn {_, mapped_value} -> mapped_value end)
  #  end
end
