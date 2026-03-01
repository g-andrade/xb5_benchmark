defmodule Xb5Benchmark.InputStructures do
  use TypedStruct

  require Logger

  alias Xb5Benchmark.Suites
  alias Xb5Benchmark.Utils

  import ExUnit.Assertions

  ## Constants

  @min_int_key -Bitwise.<<<(1, 24)
  @max_int_key Bitwise.<<<(1, 24) - 1

  @maximal_input_structure_candidates 50

  @random_candidates_seed_part1 1855106302

  ## Types

  defmodule Wrapper do
    typedstruct do
      field(:n, non_neg_integer, enforce: true)
      field(:build_type, atom, enforce: true)
      field(:suite, module, enforce: true)
      field(:impl_mod, module, enforce: true)
      field(:existing_keys_tuple, tuple(), enforce: true)
      field(:existing_keys_set, MapSet.t(term()), enforce: true)
      field(:variants, [term, ...], enforce: true)
    end
  end

  ## API

  def generate(target_max_n) do
    wrappers =
      target_max_n
      |> n_sequence()
      |> Enum.reduce([], &accumulate_new_n/2)

    :erlang.garbage_collect()
    wrappers
  end

  def new_key() do
    @min_int_key + :rand.uniform(@max_int_key - @min_int_key + 1) - 1
  end

  def new_key_with_seed(seed) do
    @min_int_key + Utils.rand_uniform_with_seed(@max_int_key - @min_int_key + 1, seed) - 1
  end

  def maximal_input_structure_candidates(), do: @maximal_input_structure_candidates

  ## Internal

  defp n_sequence(target_max_n) do
    n_sequence_recur(0, target_max_n)
  end

  defp n_sequence_recur(n, target_max_n) when n <= target_max_n do
    [n | n_sequence_recur(n + n_step(n), target_max_n)]
  end

  defp n_sequence_recur(_, _) do
    []
  end

  defp n_step(n) do
    cond do
      n < 1000 ->
        100

      n < 10_000 ->
        1000

      true ->
        5000
    end
  end

  defp accumulate_new_n(n, acc) do
    Logger.notice("[n #{n}]")

    for build_type <- all_build_types(), reduce: acc do
      acc ->
        initial_keys_amount = initial_keys_amount(n, build_type)
        initial_keys = new_keys_to_insert(MapSet.new(), [], initial_keys_amount) |> Enum.sort()

        for suite <- all_suites(), reduce: acc do
          acc ->
            accumulate_new_input_structure(n, build_type, initial_keys, suite, acc)
        end
    end
  end

  ##

  defp initial_keys_amount(n, build_type) when build_type in [:sequential, :random, :from_ordset_or_orddict] do
    n
  end

  defp initial_keys_amount(n, :xb5_adversarial) do
    delete_amount = div(n, 4)
    n + delete_amount
  end

  ##

  defp new_keys_to_insert(existing_keys, acc, amount) when amount > 0 do
    new_key = new_key()

    if MapSet.member?(existing_keys, new_key) do
      new_keys_to_insert(existing_keys, acc, amount)
    else
      existing_keys = MapSet.put(existing_keys, new_key)
      acc = [new_key | acc]
      new_keys_to_insert(existing_keys, acc, amount - 1)
    end
  end

  defp new_keys_to_insert(_existing_keys, acc, 0) do
    acc
  end

  ##

  defp all_build_types() do
    [
      # FIXME
      :sequential,
      #:random,
      #:from_ordset_or_orddict,
      #:xb5_adversarial
    ]
  end

  defp all_suites do
    [
      Suites.ErlGbSet,
      Suites.ErlGbTree,
      Suites.ErlXb5Bag,
      Suites.ErlXb5Set,
      Suites.ErlXb5Tree,
    ]
  end

  defp accumulate_new_input_structure(n, build_type, initial_keys, suite, acc) do
    impl_mod = suite.impl_mod()
    amount_of_candidates = amount_of_input_structure_candidates(build_type)

    cache_path = cache_path(n, build_type, impl_mod)

    cached_candidates = read_cached_candidates(cache_path, impl_mod)
    amount_cached = length(cached_candidates)
    amount_missing = max(0, amount_of_candidates - amount_cached)

    new_candidate_ids = Enum.map(1..amount_missing//1, &(amount_cached + &1))

    new_candidates = workerpool_map(new_candidate_ids, &new_input_structure_candidate(build_type, n, initial_keys, impl_mod, &1))

    candidates = Enum.slice(cached_candidates ++ new_candidates, 0, amount_of_candidates)

    if new_candidates !== [] do
      save_cache(cache_path, candidates)
    end

    variants = 
      case amount_of_candidates do
        1 ->
          [single_candidate] = candidates
          copies = Utils.deep_copy_term_n_times(single_candidate, @maximal_input_structure_candidates - 1)
          [single_candidate | copies]

        @maximal_input_structure_candidates ->
          candidates
      end

    ##

    existing_keys = impl_mod_keys(impl_mod, List.first(variants))
    existing_keys_tuple = List.to_tuple(existing_keys)
    existing_keys_set = MapSet.new(existing_keys)

    wrapper = %Wrapper{
      n: n,
      build_type: build_type,
      suite: suite,
      impl_mod: impl_mod,
      existing_keys_tuple: existing_keys_tuple,
      existing_keys_set: existing_keys_set,
      variants: variants
    }

    [wrapper | acc]
  end

  defp amount_of_input_structure_candidates(build_type) when build_type in [:sequential, :from_ordset_or_orddict, :xb5_adversarial] do
    1
  end

  defp amount_of_input_structure_candidates(:random) do
    @maximal_input_structure_candidates
  end

  ##

  defp cache_path(n, build_type, impl_mod) do
    n_str = n |> Integer.to_string() |> String.pad_leading(5, "0")

    impl_mod_suffix = impl_mod.module_info(:md5) |> Base.encode16(case: :lower)

    Path.join(["_cache", "input_structures", n_str, "#{build_type}", "#{impl_mod}_#{impl_mod_suffix}"])
  end

  defp read_cached_candidates(path, impl_mod) do
    case File.read(path) do
      {:ok, encoded} ->
        try do
          %{candidates: cached_candidates} = :erlang.binary_to_term(encoded)
          true = is_list(cached_candidates)

          Enum.each(cached_candidates, &cached_candidate_valid!(impl_mod, &1))

          cached_candidates
        catch
          class, reason ->
            Logger.error("Failed to read cached candidates: #{inspect {class, reason, __STACKTRACE__}}")
            []
        end

      {:error, :enoent} ->
        []
    end
  end

  #

  defp cached_candidate_valid!(:gb_sets, set) do
    {_h, size} = Utils.gb_sets_count(set)
    assert size === :gb_sets.size(set)
  end

  defp cached_candidate_valid!(:gb_trees, tree) do
    {_h, size} = Utils.gb_trees_count(tree)
    assert size === :gb_trees.size(tree)
  end

  defp cached_candidate_valid!(impl_mod, collection) do
    stats = impl_mod.structural_stats(collection)
    {_, total_keys} = List.keyfind(stats, :total_keys, 0)
    assert total_keys === impl_mod.size(collection)
  end

  #

  defp save_cache(path, candidates) do
    try do
      File.mkdir_p!(Path.dirname(path))
      encoded = :erlang.term_to_binary(%{candidates: candidates}, compressed: 9)
      File.write!(path, encoded)
    catch
      class, reason ->
        Logger.error("Failed to cache candidates: #{inspect {class, reason, __STACKTRACE__}}")
    end
  end

  ##

  defp new_input_structure_candidate(:sequential, n, initial_keys, impl_mod, _candidate_id) do
    candidate = Enum.reduce(initial_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))
    assert impl_mod.size(candidate) === n
    candidate
  end

  defp new_input_structure_candidate(:random, n, initial_keys, impl_mod, candidate_id) do
    shuffle_seed = {@random_candidates_seed_part1, n, candidate_id}
    shuffled_keys = Utils.shuffle_with_seed(initial_keys, shuffle_seed)

    # Logger.notice("[#{n}] [#{impl_mod}] Shuffled keys: #{inspect shuffled_keys}")

    candidate = Enum.reduce(shuffled_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))

    assert impl_mod.size(candidate) === n
    candidate
  end

  defp new_input_structure_candidate(:from_ordset_or_orddict, n, initial_keys, impl_mod, _candidate_id) do
    candidate = impl_mod_from_ordset_or_orddict(impl_mod, initial_keys)
    assert impl_mod.size(candidate) === n
    candidate
  end

  defp new_input_structure_candidate(:xb5_adversarial, n, initial_keys, impl_mod, _candidate_id) do
    delete_amount = div(n, 4)

    # delete every 4th key
    delete_keys =
      initial_keys
      |> Enum.with_index()
      |> Enum.filter(fn {_key, index} ->
        rem(index + 1, 4) === 0
      end)
      |> Enum.take(delete_amount)
      |> Enum.map(&elem(&1, 0))

    candidate = Enum.reduce(initial_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))
    candidate = Enum.reduce(delete_keys, candidate, &impl_mod.delete/2)

    assert impl_mod.size(candidate) === n
    candidate
  end

  ##

  defp impl_mod_new(:xb5_bag) do
    :xb5_bag.new()
  end

  defp impl_mod_new(impl_mod) do
    impl_mod.empty()
  end

  ##

  defp impl_mod_insert(impl_mod, key, acc) when impl_mod in [:xb5_trees, :gb_trees] do
    impl_mod.insert(key, :value, acc)
  end

  defp impl_mod_insert(impl_mod, key, acc) do
    impl_mod.insert(key, acc)
  end

  ##

  defp impl_mod_from_ordset_or_orddict(impl_mod, initial_keys) when impl_mod in [:xb5_trees, :gb_trees] do
    initial_keys
    |> Enum.map(&{&1, :value})
    |> impl_mod.from_orddict()
  end

  defp impl_mod_from_ordset_or_orddict(impl_mod, initial_keys) do
    impl_mod.from_ordset(initial_keys)
  end

  ###############

  defp impl_mod_keys(impl_mod, tree) when impl_mod in [:xb5_trees, :gb_trees] do
    impl_mod.keys(tree)
  end

  defp impl_mod_keys(impl_mod, collection) do
    impl_mod.to_list(collection)
  end

  ###############

  defp workerpool_map(enum, fun) do
    {:ok, _} = Application.ensure_all_started(:taskforce)
  
    tasks =
      enum
      |> Enum.with_index()
      |> Map.new(
        fn {value, index} ->
          {index, :taskforce.task(fun, [value], %{timeout: 300_000})}
        end)
  
    %{
      completed: completed_tasks,
      individual_timeouts: individual_timeouts,
      global_timeouts: global_timeouts
    } = :taskforce.execute(tasks, %{max_workers: min(System.schedulers_online(), 8)})
  
    assert individual_timeouts === []
    assert global_timeouts === []
  
    completed_tasks
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.map(fn {_, mapped_value} -> mapped_value end)
  end
end
