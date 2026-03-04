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
      field(:group, Group.t, enforce: true)
      field(:fun, fun(), enforce: true)
      field(:fun_arg, fun_arg(), enforce: true)
      field(:sampling_group_number, nil | pos_integer) # Set by Runner
    end

    @type fun_arg() :: (
      {:single, term}
      | {:random_pick, tuple()}
    )
  end

  ## API

  def get(build_type, opts \\ []) do
    Logger.notice("Preparing cases for build_type #{inspect build_type}...")
    input_structures = get_input_structures(build_type, opts)
    grouped_structures = Enum.group_by(input_structures, &(&1.impl_mod))
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
            (
              group.id in keywords_to_filter
              or Enum.any?(group.keywords, &(&1 in keywords_to_filter))
            )
          end)
      else
        groups
      end

    Enum.flat_map(groups, &group_to_cases(&1, grouped_structures))
  end

  defp get_groups() do
    [
      Suites.ErlGbSet,
      Suites.ErlGbTree,
      Suites.ErlXb5Bag,
      Suites.ErlXb5Set,
      Suites.ErlXb5Tree,
    ]
    |> Enum.flat_map(&(&1.groups()))
  end

  defp group_to_cases(%Group{} = group, grouped_structures) do
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
        |> Enum.map(&new_bulk_constructor_case(group, &1))

      :each_iteration_no_keys ->
        Enum.map(structures, &new_alternate_case(group, &1, :no_keys, 0))

      {:each_iteration_no_keys, arg} ->
        Enum.map(structures, &new_alternate_case(group, &1, {:no_keys, arg}, 0))

      {:each_iteration_many_keys, key_status, batch_amount} ->
        Enum.map(structures, &new_alternate_case(group, &1, key_status, batch_amount))

      {:each_iteration_a_second_collection, max_perc_in_common, size2} ->
        Enum.map(structures, &new_second_collection_case(group, &1, max_perc_in_common, size2))
    end
  end

  ###

  defp new_bulk_constructor_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper) do
    assert group.tweaks === :none

    rand_seed_part1 = :erlang.phash2(group.id)

    existing_keys_list = input_wrapper.existing_keys_list
    amount_of_variants = length(input_wrapper.variants)

    sorted_input_list =
      if String.contains?(group.impl_description, "from_orddict") do
        Enum.map(existing_keys_list, &({&1, :value}))
      else
        existing_keys_list
      end

    iterations =
      case input_wrapper.build_type do
        :sequential ->
          copies = Utils.deep_copy_term_n_times(sorted_input_list, amount_of_variants - 1)
          [sorted_input_list | copies]

        :random ->
          Enum.map(
            0..(amount_of_variants - 1)//1,
            fn iteration_index ->
              Utils.shuffle_with_seed(sorted_input_list, {rand_seed_part1, iteration_index, 637})
            end)
      end

    fun = group.suite_fun
    fun_arg = {:single, iterations}

    %Case{
      n: input_wrapper.n,
      build_type: input_wrapper.build_type,
      suite: input_wrapper.suite,
      group: group,
      fun: fun,
      fun_arg: fun_arg
    }
  end

  ###

  defp new_alternate_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper, key_status, batch_amount) do
    fun = group.suite_fun

    rand_seed_part1 = :erlang.phash2(group.id)

    fun_arg =
      case group.tweaks do
        {:duplicate_variants, multiplier} ->
          expanded_variants = Enum.flat_map(1..multiplier//1, fn _ -> input_wrapper.variants end)

          iterations = 
            Enum.with_index(
              expanded_variants,
              fn variant, iteration_index ->
                common_rand_seed = [rand_seed_part1 | iteration_index]
                alternate_case_iteration(variant, input_wrapper, key_status, batch_amount, common_rand_seed)
              end
            )
            |> Enum.flat_map(&(&1))

          {:single, iterations}

        :none ->
          iterations = 
            Enum.with_index(
              input_wrapper.variants,
              fn variant, iteration_index ->
                common_rand_seed = [rand_seed_part1 | iteration_index]
                alternate_case_iteration(variant, input_wrapper, key_status, batch_amount, common_rand_seed)
              end
            )
            |> Enum.flat_map(&(&1))

          {:single, iterations}
      end

    ###

    %Case{
      n: input_wrapper.n,
      build_type: input_wrapper.build_type,
      suite: input_wrapper.suite,
      group: group,
      fun: fun,
      fun_arg: fun_arg
    }
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{}, :no_keys, _, _) do
    [input_variant]
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{}, {:no_keys, arg}, _, _) do
    [input_variant, arg]
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
    input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status,
    batch_amount, common_rand_seed
  ) do
    case key_status do
      :existing ->
        assert input_wrapper.n !== 0
        [input_variant, existing_keys(
          input_wrapper.existing_keys_tuple, common_rand_seed, batch_amount
        )]

      :existing_and_unique ->
        assert input_wrapper.n !== 0
        [input_variant, existing_keys_unique(
          input_wrapper.existing_keys_tuple, common_rand_seed, batch_amount
        )]

      :missing ->
        [input_variant, missing_keys(
          input_wrapper.existing_keys_set, common_rand_seed, batch_amount
        )]

      :missing_and_unique ->
        [input_variant, missing_keys_unique(
          input_wrapper.existing_keys_set, common_rand_seed, batch_amount
        )]
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

  ##

  defp existing_keys(existing_keys_tuple, common_rand_seed, amount) do
    key_indices = 0..(amount - 1)//1
    Enum.map(key_indices, &existing_key(existing_keys_tuple, common_rand_seed, &1))
  end

  defp existing_keys_unique(existing_keys_tuple, common_rand_seed, amount) when amount <= tuple_size(existing_keys_tuple) do
    [seed_part1 | seed_part2] = common_rand_seed
    rand_seed = {seed_part1, seed_part2, 0}
    existing_keys_tuple |> Tuple.to_list() |> Utils.take_random_with_seed(amount, rand_seed)
  end

  ##

  defp missing_keys(initial_keys_set, common_rand_seed, amount) do
    missing_keys_recur(initial_keys_set, common_rand_seed, 0, amount)
  end

  defp missing_keys_recur(initial_keys_set, common_rand_seed, key_index, amount) when amount > 0 do
    key = missing_key(initial_keys_set, common_rand_seed, key_index)
    [key | missing_keys_recur(initial_keys_set, common_rand_seed, key_index + 1, amount - 1)]
  end

  defp missing_keys_recur(_initial_keys_set, _, _, 0) do
    []
  end

  ##

  defp missing_keys_unique(existing_keys_set, common_rand_seed, amount) do
    missing_keys_unique_recur(existing_keys_set, common_rand_seed, 0, amount)
  end

  defp missing_keys_unique_recur(existing_keys_set, common_rand_seed, key_index, amount) when amount > 0 do
    key = missing_key(existing_keys_set, common_rand_seed, key_index)
    existing_keys_set = MapSet.put(existing_keys_set, key)
    [key | missing_keys_unique_recur(existing_keys_set, common_rand_seed, key_index + 1, amount - 1)]
  end

  defp missing_keys_unique_recur(_existing_keys_set, _, _, 0) do
    []
  end

  #########

  defp new_second_collection_case(
    %Group{} = group, %InputStructures.Wrapper{} = input_wrapper, max_perc_in_common, size2
  ) do
    assert group.tweaks === :none

    fun = group.suite_fun

    rand_seed_part1 = :erlang.phash2(group.id)

    iterations =
      Enum.with_index(
        input_wrapper.variants,
        fn variant, iteration_index ->
          common_rand_seed = [rand_seed_part1 | iteration_index]
          second_collection_iteration(variant, input_wrapper, max_perc_in_common, size2, common_rand_seed)
        end)
        |> Enum.flat_map(&(&1))

    fun_arg = {:single, iterations}

    %Case{
      n: input_wrapper.n,
      build_type: input_wrapper.build_type,
      suite: input_wrapper.suite,
      group: group,
      fun: fun,
      fun_arg: fun_arg
    }
  end

  defp second_collection_iteration(
    variant, %InputStructures.Wrapper{} = input_wrapper, max_perc_in_common, size2, common_rand_seed
  ) do
    impl_mod = input_wrapper.impl_mod

    {resolved_max_perc_in_common, common_keys_direction} = second_collection_resolve_max_perc_in_common(max_perc_in_common)
    resolved_size2 = second_collection_resolve_size2(input_wrapper.n, size2)

    amount_in_common = floor(resolved_max_perc_in_common * min(resolved_size2, input_wrapper.n))
    {new_keys_constraint, keys_in_common} = second_collection_keys_in_common(
      input_wrapper, common_keys_direction, amount_in_common, common_rand_seed
    )

    coll2 = InputStructures.new_second_collection(
      input_wrapper.build_type, resolved_size2, impl_mod, input_wrapper.existing_keys_set, 
      new_keys_constraint, keys_in_common, common_rand_seed
    )
    assert impl_mod.size(coll2) === resolved_size2
    [variant, coll2]
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
    %InputStructures.Wrapper{} = input_wrapper, common_keys_direction, amount_in_common, [seed_part1 | seed_part2]
  ) do
    case common_keys_direction do
      :random_keys ->
        new_keys_constraint = :none
        {
          new_keys_constraint,
          Utils.take_random_with_seed(input_wrapper.existing_keys_list, amount_in_common, {seed_part1, seed_part2, 42})
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
