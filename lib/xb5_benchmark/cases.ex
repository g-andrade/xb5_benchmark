defmodule Xb5Benchmark.Cases do
  use TypedStruct

  import ExUnit.Assertions

  require Logger

  alias Xb5Benchmark.InputStructures
  alias Xb5Benchmark.Suites
  alias Xb5Benchmark.Groups.Group
  alias Xb5Benchmark.Utils

  ## Constants

  @target_max_n 15_000

  ## Types

  defmodule Case do
    typedstruct do
      field(:n, non_neg_integer, enforce: true)
      field(:build_type, atom, enforce: true)
      field(:suite, module, enforce: true)
      field(:group, Group.t(), enforce: true)
      field(:fun, fun(), enforce: true)
      field(:fun_arg, fun_arg(), enforce: true)
      field(:ops_multiplier, number, enforce: true)
      # Set by Runner
      field(:memory_stats, nil | Statistex.t())
      field(:sampling_group_number, nil | pos_integer)
    end

    @type fun_arg() ::
            {:single, term}
            | {:random_pick, tuple()}
  end

  ## API

  def get(build_type, opts \\ []) do
    Logger.notice("Preparing cases for build_type #{inspect(build_type)}...")
    input_structures = get_input_structures(build_type, opts)
    grouped_structures = Enum.group_by(input_structures, & &1.impl_mod)
    cases = get_cases(grouped_structures, opts)
    :erlang.garbage_collect(self())
    cases
  end

  def clear_cache(build_type, opts) do
    max_n = opts[:max_n] || @target_max_n
    cache_key = cache_key(build_type, max_n)
    Process.delete(cache_key)
    :ok
  end

  ## Internal

  defp get_input_structures(build_type, opts) do
    max_n = opts[:max_n] || @target_max_n
    cache_key = cache_key(build_type, max_n)

    case Process.get(cache_key) do
      nil ->
        input_structures = InputStructures.generate(build_type, max_n)
        Process.put(cache_key, input_structures)
        input_structures

      input_structures ->
        input_structures
    end
  end

  defp cache_key(build_type, max_n) do
    {__MODULE__, :input_structures, build_type, max_n}
  end

  defp get_cases(grouped_structures, opts) do
    keywords_to_filter = opts[:keywords]

    groups = get_groups()

    groups =
      if keywords_to_filter !== nil do
        Enum.filter(
          groups,
          fn %Group{} = group ->
            group.id in keywords_to_filter or
              Enum.any?(group.keywords, &(&1 in keywords_to_filter))
          end
        )
      else
        groups
      end

    total_groups = length(groups)
    cache = %{}

    groups
    |> Enum.sort_by(& &1.id)
    |> Enum.with_index()
    |> Enum.flat_map_reduce(cache, &group_to_cases(&1, total_groups, grouped_structures, &2))
    |> elem(0)
    |> Enum.filter(&(&1 !== :test_case_not_possible))
  end

  defp get_groups() do
    [
      Suites.ErlGbSet,
      Suites.ErlGbTree,
      Suites.ErlXb5Bag,
      Suites.ErlXb5Set,
      Suites.ErlXb5Tree
    ]
    |> Enum.flat_map(& &1.groups())
  end

  defp group_to_cases({%Group{} = group, group_index}, total_groups, grouped_structures, cache) do
    if rem(group_index, 5) === 0 do
      Logger.notice(
        "[group_to_case] #{floor(100 * group_index / total_groups)}% [#{group_index} / #{total_groups} - #{group.id}]"
      )
    end

    structures = Map.fetch!(grouped_structures, group.impl_mod)

    structures =
      if group.includes_empty? do
        structures
      else
        Enum.filter(structures, &(&1.n !== 0))
      end

    ##

    case group.type do
      {:bulk_constructor, allowed_build_types} ->
        structures
        |> Enum.filter(&(&1.build_type in allowed_build_types))
        |> Enum.map_reduce(cache, &new_bulk_constructor_case(group, &1, &2))

      :each_iteration_no_keys ->
        Enum.map_reduce(structures, cache, &new_alternate_case(group, &1, &2, :no_keys, 0))

      {:each_iteration_no_keys, arg} ->
        Enum.map_reduce(structures, cache, &new_alternate_case(group, &1, &2, {:no_keys, arg}, 0))

      {:each_iteration_many_keys, key_status, batch_amount} ->
        Enum.map_reduce(
          structures,
          cache,
          &new_alternate_case(group, &1, &2, key_status, batch_amount)
        )

      {:each_iteration_many_ranks, amount} ->
        Enum.map_reduce(structures, cache, &new_alternate_case(group, &1, &2, :ranks, amount))

      {:each_iteration_a_second_collection, max_perc_in_common, size2} ->
        Enum.map_reduce(
          structures,
          cache,
          &new_second_collection_case(group, &1, &2, max_perc_in_common, size2)
        )
    end
  end

  ###

  defp new_bulk_constructor_case(
         %Group{} = group,
         %InputStructures.Wrapper{} = input_wrapper,
         cache
       ) do
    assert group.tweaks === :none

    rand_seed_part1 = :erlang.phash2(group.id)

    existing_keys_list = input_wrapper.existing_keys_list
    amount_of_variants = length(input_wrapper.variants)

    sorted_input_list =
      if String.contains?(group.impl_description, "from_orddict") do
        Enum.map(existing_keys_list, &{&1, :value})
      else
        existing_keys_list
      end

    {iterations, cache} =
      Utils.memoized(
        cache,
        {:iterations_from_sorted_input_list, input_wrapper.n, :erlang.phash2(sorted_input_list)},
        fn ->
          case input_wrapper.build_type do
            :sequential ->
              copies = Utils.deep_copy_term_n_times(sorted_input_list, amount_of_variants - 1)
              [sorted_input_list | copies]

            :random ->
              Enum.map(
                0..(amount_of_variants - 1)//1,
                fn iteration_index ->
                  Utils.shuffle_with_seed(
                    sorted_input_list,
                    {rand_seed_part1, iteration_index, 637}
                  )
                end
              )
          end
        end
      )

    fun = group.suite_fun
    fun_arg = {:single, iterations}

    c =
      %Case{
        n: input_wrapper.n,
        build_type: input_wrapper.build_type,
        suite: input_wrapper.suite,
        group: group,
        ops_multiplier: length(iterations),
        fun: fun,
        fun_arg: fun_arg
      }

    {c, cache}
  end

  ###

  defp new_alternate_case(
         %Group{},
         %InputStructures.Wrapper{} = input_wrapper,
         cache,
         key_status,
         batch_amount
       )
       when key_status === :existing_and_unique and batch_amount > input_wrapper.n do
    {:test_case_not_possible, cache}
  end

  defp new_alternate_case(
         %Group{},
         %InputStructures.Wrapper{} = input_wrapper,
         cache,
         {:no_keys, amount},
         _batch_amount
       )
       when is_integer(amount) and amount > input_wrapper.n do
    {:test_case_not_possible, cache}
  end

  defp new_alternate_case(
         %Group{} = group,
         %InputStructures.Wrapper{} = input_wrapper,
         cache,
         key_status,
         batch_amount
       ) do
    fun = group.suite_fun

    rand_seed_part1 = :erlang.phash2(group.id)

    {fun_arg, cache} =
      case group.tweaks do
        {:duplicate_variants, multiplier} ->
          expanded_variants = Enum.flat_map(1..multiplier//1, fn _ -> input_wrapper.variants end)

          {iterations, cache} =
            expanded_variants
            |> Enum.with_index()
            |> Enum.flat_map_reduce(
              cache,
              fn {variant, iteration_index}, cache ->
                common_rand_seed = [rand_seed_part1 | iteration_index]

                alternate_case_iteration(
                  variant,
                  input_wrapper,
                  key_status,
                  batch_amount,
                  common_rand_seed,
                  cache
                )
              end
            )

          {{:single, iterations}, cache}

        :none ->
          {iterations, cache} =
            input_wrapper.variants
            |> Enum.with_index()
            |> Enum.flat_map_reduce(
              cache,
              fn {variant, iteration_index}, cache ->
                common_rand_seed = [rand_seed_part1 | iteration_index]

                alternate_case_iteration(
                  variant,
                  input_wrapper,
                  key_status,
                  batch_amount,
                  common_rand_seed,
                  cache
                )
              end
            )

          {{:single, iterations}, cache}
      end

    ###

    {:single, iterations} = fun_arg
    ops_multiplier = length(iterations)

    c =
      %Case{
        n: input_wrapper.n,
        build_type: input_wrapper.build_type,
        suite: input_wrapper.suite,
        group: group,
        fun: fun,
        fun_arg: fun_arg,
        ops_multiplier: ops_multiplier
      }

    {c, cache}
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{}, :no_keys, _, _, cache) do
    {[input_variant], cache}
  end

  defp alternate_case_iteration(
         input_variant,
         %InputStructures.Wrapper{} = input_wrapper,
         {:no_keys, arg},
         _,
         _,
         cache
       ) do
    resolved_arg =
      if arg === :N do
        input_wrapper.n
      else
        arg
      end

    {[input_variant, resolved_arg], cache}
  end

  defp alternate_case_iteration(
         input_variant,
         %InputStructures.Wrapper{} = input_wrapper,
         :ranks,
         batch_amount,
         common_rand_seed,
         cache
       ) do
    [seed_part1 | seed_part2] = common_rand_seed

    ranks =
      Enum.map(
        0..(batch_amount - 1),
        fn key_index ->
          Utils.rand_uniform_with_seed(input_wrapper.n, {seed_part1, seed_part2, key_index})
        end
      )

    {[input_variant, ranks], cache}
  end

  #  defp alternate_case_iteration(
  #    input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status,
  #    batch_amount, common_rand_seed
  #  ) when batch_amount === 1
  #  do
  #    case key_status do
  #      :existing ->
  #        assert input_wrapper.n !== 0
  #        key_index = 0
  #        [input_variant, existing_key(input_wrapper.existing_keys_tuple, common_rand_seed, key_index)]
  #
  #      :missing ->
  #        key_index = 0
  #        [input_variant, missing_key(input_wrapper.existing_keys_set, common_rand_seed, key_index)]
  #    end
  #  end

  defp alternate_case_iteration(
         input_variant,
         %InputStructures.Wrapper{} = input_wrapper,
         key_status,
         batch_amount,
         common_rand_seed,
         cache
       ) do
    existing_keys_hash = :erlang.phash2(input_wrapper.existing_keys_list)

    case key_status do
      :existing ->
        assert input_wrapper.n !== 0

        {keys, cache} =
          Utils.memoized(
            cache,
            {:existing_keys, existing_keys_hash, batch_amount, common_rand_seed},
            fn ->
              existing_keys(
                input_wrapper.existing_keys_tuple,
                common_rand_seed,
                batch_amount
              )
            end
          )

        {[input_variant, keys], cache}

      :existing_and_unique ->
        assert input_wrapper.n !== 0

        {keys, cache} =
          Utils.memoized(
            cache,
            {:existing_keys_unique, existing_keys_hash, batch_amount, common_rand_seed},
            fn ->
              existing_keys_unique(
                input_wrapper.existing_keys_tuple,
                common_rand_seed,
                batch_amount
              )
            end
          )

        {[input_variant, keys], cache}

      :missing ->
        {keys, cache} =
          Utils.memoized(
            cache,
            {:missing_keys, existing_keys_hash, batch_amount, common_rand_seed},
            fn ->
              missing_keys(
                input_wrapper.existing_keys_set,
                common_rand_seed,
                batch_amount
              )
            end
          )

        {[input_variant, keys], cache}

      :missing_and_unique ->
        {keys, cache} =
          Utils.memoized(
            cache,
            {:missing_keys_unique, existing_keys_hash, batch_amount, common_rand_seed},
            fn ->
              missing_keys_unique(
                input_wrapper.existing_keys_set,
                common_rand_seed,
                batch_amount
              )
            end
          )

        {[input_variant, keys], cache}

      :to_append ->
        {keys, cache} =
          Utils.memoized(
            cache,
            {:keys_to_append, existing_keys_hash, batch_amount, common_rand_seed},
            fn ->
              keys_to_append(input_wrapper.existing_keys_tuple, batch_amount)
            end
          )

        {[input_variant, keys], cache}
    end
  end

  ##

  defp existing_key(existing_keys_tuple, common_rand_seed, key_index) do
    existing_keys_amount = tuple_size(existing_keys_tuple)
    [seed_part1 | seed_part2] = common_rand_seed
    rand_seed = {seed_part1, seed_part2, key_index}
    index = Utils.rand_uniform_with_seed(existing_keys_amount, rand_seed) - 1
    elem(existing_keys_tuple, index)
  end

  ##

  defp missing_key(existing_keys_set, common_rand_seed, key_index) do
    missing_key_recur(existing_keys_set, common_rand_seed, key_index, 1)
  end

  defp missing_key_recur(existing_keys_set, common_rand_seed, key_index, attempt_nr) do
    [seed_part1 | seed_part2] = common_rand_seed
    rand_seed = {seed_part1 + seed_part2, key_index, attempt_nr}
    key = InputStructures.new_key_with_seed(rand_seed)

    if MapSet.member?(existing_keys_set, key) do
      missing_key_recur(existing_keys_set, common_rand_seed, key_index, attempt_nr + 1)
    else
      key
    end
  end

  ################

  defp existing_keys(existing_keys_tuple, common_rand_seed, amount) when is_integer(amount) do
    key_indices = 0..(amount - 1)//1
    Enum.map(key_indices, &existing_key(existing_keys_tuple, common_rand_seed, &1))
  end

  ##

  defp existing_keys_unique(existing_keys_tuple, common_rand_seed, :N) do
    existing_keys_unique(existing_keys_tuple, common_rand_seed, tuple_size(existing_keys_tuple))
  end

  defp existing_keys_unique(existing_keys_tuple, common_rand_seed, amount)
       when amount <= tuple_size(existing_keys_tuple) do
    [seed_part1 | seed_part2] = common_rand_seed
    rand_seed = {seed_part1, seed_part2, 0}
    existing_keys_tuple |> Tuple.to_list() |> Utils.take_random_with_seed(amount, rand_seed)
  end

  ##

  defp missing_keys(initial_keys_set, common_rand_seed, amount) when is_integer(amount) do
    missing_keys_recur(initial_keys_set, common_rand_seed, 0, amount)
  end

  defp missing_keys_recur(initial_keys_set, common_rand_seed, key_index, amount)
       when amount > 0 do
    key = missing_key(initial_keys_set, common_rand_seed, key_index)
    [key | missing_keys_recur(initial_keys_set, common_rand_seed, key_index + 1, amount - 1)]
  end

  defp missing_keys_recur(_initial_keys_set, _, _, 0) do
    []
  end

  ##

  defp missing_keys_unique(existing_keys_set, common_rand_seed, amount) when is_integer(amount) do
    missing_keys_unique_recur(existing_keys_set, common_rand_seed, 0, amount)
  end

  defp missing_keys_unique_recur(existing_keys_set, common_rand_seed, key_index, amount)
       when amount > 0 do
    key = missing_key(existing_keys_set, common_rand_seed, key_index)
    existing_keys_set = MapSet.put(existing_keys_set, key)

    [
      key
      | missing_keys_unique_recur(existing_keys_set, common_rand_seed, key_index + 1, amount - 1)
    ]
  end

  defp missing_keys_unique_recur(_existing_keys_set, _, _, 0) do
    []
  end

  ##

  def keys_to_append(existing_keys_tuple, amount) do
    largest_key = elem(existing_keys_tuple, tuple_size(existing_keys_tuple) - 1)
    assert is_integer(largest_key)

    resolved_amount =
      if amount === :N do
        tuple_size(existing_keys_tuple)
      else
        amount
      end

    keys = Enum.to_list((largest_key + 1)..(largest_key + resolved_amount)//1)

    assert length(keys) === resolved_amount
    assert Enum.filter(keys, &(&1 <= largest_key)) === []
    assert keys |> List.last() |> :erts_debug.size() === 0

    keys
  end

  #########

  defp new_second_collection_case(
         %Group{} = group,
         %InputStructures.Wrapper{} = input_wrapper,
         cache,
         max_perc_in_common,
         size2
       ) do
    fun = group.suite_fun

    rand_seed_part1 = :erlang.phash2(group.id)

    {iterations, cache} =
      input_wrapper.variants
      |> Enum.with_index()
      |> Enum.flat_map_reduce(
        cache,
        fn {variant, iteration_index}, cache ->
          common_rand_seed = [rand_seed_part1 | iteration_index]

          second_collection_iteration(
            variant,
            input_wrapper,
            max_perc_in_common,
            size2,
            common_rand_seed,
            cache
          )
        end
      )

    assert group.tweaks === :none
    ops_multiplier = length(iterations)

    fun_arg = {:single, iterations}

    c =
      %Case{
        n: input_wrapper.n,
        build_type: input_wrapper.build_type,
        suite: input_wrapper.suite,
        group: group,
        fun: fun,
        fun_arg: fun_arg,
        ops_multiplier: ops_multiplier
      }

    {c, cache}
  end

  defp second_collection_iteration(
         variant,
         %InputStructures.Wrapper{} = input_wrapper,
         max_perc_in_common,
         size2,
         common_rand_seed,
         cache
       ) do
    impl_mod = input_wrapper.impl_mod

    {resolved_max_perc_in_common, common_keys_direction} =
      second_collection_resolve_max_perc_in_common(max_perc_in_common)

    resolved_size2 = second_collection_resolve_size2(input_wrapper.n, size2)

    amount_in_common = floor(resolved_max_perc_in_common * min(resolved_size2, input_wrapper.n))

    existing_keys_hash = :erlang.phash2(input_wrapper.existing_keys_list)

    {{new_keys_constraint, keys_in_common}, cache} =
      Utils.memoized(
        cache,
        {
          :second_collection_keys_in_common,
          existing_keys_hash,
          resolved_max_perc_in_common,
          common_keys_direction,
          amount_in_common,
          common_rand_seed
        },
        fn ->
          second_collection_keys_in_common(
            input_wrapper,
            common_keys_direction,
            amount_in_common,
            common_rand_seed
          )
        end
      )

    {coll2, cache} =
      InputStructures.new_second_collection(
        input_wrapper.build_type,
        resolved_size2,
        impl_mod,
        input_wrapper.existing_keys_set,
        new_keys_constraint,
        keys_in_common,
        common_rand_seed,
        cache
      )

    assert impl_mod.size(coll2) === resolved_size2
    {[variant, coll2], cache}
  end

  ##

  defp second_collection_resolve_max_perc_in_common({percentage, direction}) do
    {percentage, direction}
  end

  defp second_collection_resolve_max_perc_in_common(percentage) do
    {percentage, :random_keys}
  end

  ##

  defp second_collection_resolve_size2(n, :same_size), do: n
  defp second_collection_resolve_size2(_n, size2), do: size2

  defp second_collection_keys_in_common(
         %InputStructures.Wrapper{} = input_wrapper,
         common_keys_direction,
         amount_in_common,
         [seed_part1 | seed_part2]
       ) do
    case common_keys_direction do
      :random_keys ->
        new_keys_constraint = :none

        {
          new_keys_constraint,
          Utils.take_random_with_seed(
            input_wrapper.existing_keys_list,
            amount_in_common,
            {seed_part1, seed_part2, 42}
          )
        }

      #####

      :smallest_keys ->
        keys_in_common = Enum.take(input_wrapper.existing_keys_list, amount_in_common)

        new_keys_constraint =
          if keys_in_common === [] do
            :none
          else
            {:larger_than, List.last(keys_in_common)}
          end

        {new_keys_constraint, keys_in_common}

      #####

      :largest_keys ->
        keys_in_common = Enum.drop(input_wrapper.existing_keys_list, amount_in_common)

        new_keys_constraint =
          if keys_in_common === [] do
            :none
          else
            {:smaller_than, hd(keys_in_common)}
          end

        {new_keys_constraint, keys_in_common}
    end
  end
end
