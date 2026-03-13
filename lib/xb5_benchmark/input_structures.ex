defmodule Xb5Benchmark.InputStructures do
  use TypedStruct

  require Logger

  alias Xb5Benchmark.Suites
  alias Xb5Benchmark.Utils

  import ExUnit.Assertions

  ## Constants

  # @min_int_key -Bitwise.<<<(1, 24)
  # @max_int_key Bitwise.<<<(1, 24) - 1

  @min_int_key -Bitwise.<<<(1, 59)
  @max_int_key Bitwise.<<<(1, 59) - 1

  assert :erts_debug.size(@min_int_key) === 0
  assert :erts_debug.size(@max_int_key) === 0

  @maximal_input_structure_candidates 50

  @random_candidates_seed_part1 1_855_106_302

  ## Types

  defmodule Wrapper do
    typedstruct do
      field(:n, non_neg_integer, enforce: true)
      field(:build_type, atom, enforce: true)
      field(:suite, module, enforce: true)
      field(:impl_mod, module, enforce: true)
      field(:existing_keys_tuple, tuple(), enforce: true)
      field(:existing_keys_set, MapSet.t(term()), enforce: true)
      field(:existing_keys_list, [term()], enforce: true)
      field(:variants, [term, ...], enforce: true)
    end
  end

  ## API

  def all_build_types() do
    [
      :sequential,
      :random,
      :from_ordset_or_orddict,
      :xb5_adversarial
    ]
  end

  def generate(build_type, target_max_n) do
    wrappers =
      target_max_n
      |> n_sequence()
      |> Enum.reduce([], &accumulate_new_n(&1, build_type, &2))

    :erlang.garbage_collect()
    wrappers
  end

  def new_key() do
    @min_int_key + :rand.uniform(@max_int_key - @min_int_key + 1) - 1
  end

  def new_key_with_seed(seed, constraint \\ :none)

  def new_key_with_seed(seed, :none) do
    @min_int_key + Utils.rand_uniform_with_seed(@max_int_key - @min_int_key + 1, seed) - 1
  end

  def new_key_with_seed(seed, {:larger_than, ceil}) do
    ceil + Utils.rand_uniform_with_seed(@max_int_key - ceil, seed)
  end

  def new_key_with_seed(seed, {:smaller_than, ceil}) do
    @min_int_key + Utils.rand_uniform_with_seed(ceil - @min_int_key, seed) - 1
  end

  def maximal_input_structure_candidates(), do: @maximal_input_structure_candidates

  def new_second_collection(
        build_type,
        size,
        impl_mod,
        existing_keys,
        new_keys_constraint,
        keys_in_common,
        common_rand_seed,
        cache
      ) do
    [seed_part1 | seed_part2] = common_rand_seed

    build_type_adjusted_size =
      if build_type === :xb5_adversarial do
        size + div(size, 4)
      else
        size
      end

    new_amount = build_type_adjusted_size - length(keys_in_common)
    assert new_amount >= 0

    {new_keys, cache} =
      Utils.memoized(
        cache,
        {
          __MODULE__,
          :new_second_collection,
          :new_keys,
          :erlang.phash2(existing_keys),
          :erlang.phash2(keys_in_common),
          common_rand_seed
        },
        fn ->
          seeded_new_keys_to_insert(
            existing_keys,
            new_keys_constraint,
            new_amount,
            seed_part1,
            seed_part2
          )
        end
      )

    initial_keys = Enum.sort(keys_in_common ++ new_keys)
    # assert length(initial_keys) === size

    _ =
      case new_keys_constraint do
        :none ->
          :ok

        {:larger_than, ceil} ->
          assert Enum.filter(new_keys, &(&1 <= ceil)) === []

        {:smaller_than, floor} ->
          assert Enum.filter(new_keys, &(&1 >= floor)) === []
      end

    # This will make any `random` builds have initial keys in the same way for
    # all iterations sharing `common_rand_seed`. This should be fine.
    pseudo_candidate_id = -1

    collection =
      new_input_structure_candidate(build_type, size, initial_keys, impl_mod, pseudo_candidate_id)

    assert impl_mod.size(collection) === size

    {collection, cache}
  end

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

  defp accumulate_new_n(n, build_type, acc) do
    Logger.notice("[n #{n}]")

    initial_keys_amount = initial_keys_amount(n, build_type)
    initial_keys = new_keys_to_insert(MapSet.new(), [], initial_keys_amount) |> Enum.sort()

    for suite <- all_suites(), reduce: acc do
      acc ->
        accumulate_new_input_structure(n, build_type, initial_keys, suite, acc)
    end
  end

  ##

  defp initial_keys_amount(n, build_type)
       when build_type in [:sequential, :random, :from_ordset_or_orddict] do
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

  defp seeded_new_keys_to_insert(existing_keys, constraint, amount, seed_part1, seed_part2) do
    acc = []

    seeded_new_keys_to_insert_recur(
      existing_keys,
      constraint,
      acc,
      seed_part1,
      seed_part2,
      0,
      amount
    )
  end

  defp seeded_new_keys_to_insert_recur(
         existing_keys,
         constraint,
         acc,
         seed_part1,
         seed_part2,
         seed_part3,
         amount
       )
       when amount > 0 do
    new_key = new_key_with_seed({seed_part1, seed_part2, seed_part3}, constraint)

    if MapSet.member?(existing_keys, new_key) do
      # Logger.notice("CONFLICT")
      seeded_new_keys_to_insert_recur(
        existing_keys,
        constraint,
        acc,
        seed_part1,
        seed_part2,
        seed_part3 + 1,
        amount
      )
    else
      existing_keys = MapSet.put(existing_keys, new_key)
      acc = [new_key | acc]

      seeded_new_keys_to_insert_recur(
        existing_keys,
        constraint,
        acc,
        seed_part1,
        seed_part2,
        seed_part3 + 1,
        amount - 1
      )
    end
  end

  defp seeded_new_keys_to_insert_recur(_, _, acc, _, _, _, 0) do
    acc
  end

  ##

  defp all_suites do
    [
      Suites.ErlGbSet,
      Suites.ErlGbTree,
      Suites.ErlXb5Bag,
      Suites.ErlXb5Set,
      Suites.ErlXb5Tree
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

    new_candidates =
      Utils.workerpool_map(
        new_candidate_ids,
        &new_input_structure_candidate(build_type, n, initial_keys, impl_mod, &1)
      )

    candidates = Enum.slice(cached_candidates ++ new_candidates, 0, amount_of_candidates)

    if new_candidates !== [] do
      save_cache(cache_path, candidates)
    end

    variants =
      case amount_of_candidates do
        1 ->
          [single_candidate] = candidates

          copies =
            Utils.deep_copy_term_n_times(
              single_candidate,
              @maximal_input_structure_candidates - 1
            )

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
      existing_keys_list: existing_keys,
      variants: variants
    }

    [wrapper | acc]
  end

  defp amount_of_input_structure_candidates(build_type)
       when build_type in [:sequential, :from_ordset_or_orddict, :xb5_adversarial] do
    1
  end

  defp amount_of_input_structure_candidates(:random) do
    @maximal_input_structure_candidates
  end

  ##

  defp cache_path(n, build_type, impl_mod) do
    n_str = n |> Integer.to_string() |> String.pad_leading(5, "0")

    impl_mod_suffix = impl_mod.module_info(:md5) |> Base.encode16(case: :lower)

    Path.join([
      "_cache",
      "input_structures",
      n_str,
      "#{build_type}",
      "#{impl_mod}_#{impl_mod_suffix}"
    ])
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
            Logger.error(
              "Failed to read cached candidates: #{inspect({class, reason, __STACKTRACE__})}"
            )

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
        Logger.error("Failed to cache candidates: #{inspect({class, reason, __STACKTRACE__})}")
    end
  end

  ##

  defp new_input_structure_candidate(:sequential, n, initial_keys, impl_mod, _candidate_id) do
    candidate =
      Enum.reduce(initial_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))

    assert impl_mod.size(candidate) === n
    candidate
  end

  defp new_input_structure_candidate(:random, n, initial_keys, impl_mod, candidate_id) do
    shuffle_seed = {@random_candidates_seed_part1, n, candidate_id}
    shuffled_keys = Utils.shuffle_with_seed(initial_keys, shuffle_seed)

    # Logger.notice("[#{n}] [#{impl_mod}] Shuffled keys: #{inspect shuffled_keys}")

    candidate =
      Enum.reduce(shuffled_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))

    assert impl_mod.size(candidate) === n
    candidate
  end

  defp new_input_structure_candidate(
         :from_ordset_or_orddict,
         n,
         initial_keys,
         impl_mod,
         _candidate_id
       ) do
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

    candidate =
      Enum.reduce(initial_keys, impl_mod_new(impl_mod), &impl_mod_insert(impl_mod, &1, &2))

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

  defp impl_mod_insert(impl_mod, key, acc) when impl_mod in [:xb5_trees, :xb5_trees_v2, :gb_trees] do
    impl_mod.insert(key, :value, acc)
  end

  defp impl_mod_insert(impl_mod, key, acc) do
    impl_mod.insert(key, acc)
  end

  ##

  defp impl_mod_from_ordset_or_orddict(impl_mod, initial_keys)
       when impl_mod in [:xb5_trees, :xb5_trees_v2, :gb_trees] do
    initial_keys
    |> Enum.map(&{&1, :value})
    |> impl_mod.from_orddict()
  end

  defp impl_mod_from_ordset_or_orddict(impl_mod, initial_keys) do
    impl_mod.from_ordset(initial_keys)
  end

  ###############

  defp impl_mod_keys(impl_mod, tree) when impl_mod in [:xb5_trees, :xb5_trees_v2, :gb_trees] do
    impl_mod.keys(tree)
  end

  defp impl_mod_keys(impl_mod, collection) do
    impl_mod.to_list(collection)
  end
end
