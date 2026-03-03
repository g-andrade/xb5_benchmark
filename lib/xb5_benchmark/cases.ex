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

  def get(opts \\ []) do
    Logger.notice("Preparing cases...")
    input_structures = get_input_structures(opts)
    grouped_structures = Enum.group_by(input_structures, &(&1.impl_mod))
    cases = get_cases(grouped_structures, opts)
    :erlang.garbage_collect(self())
    cases
  end

  ## Internal

  defp get_input_structures(opts) do
    cache_key = {__MODULE__, :input_structures}

    case Process.get(cache_key) do
      nil ->
        max_n = opts[:max_n] || @target_max_n
        input_structures = InputStructures.generate(max_n)
        Process.put(cache_key, input_structures)
        input_structures

      input_structures ->
        input_structures
    end
  end

  defp get_cases(grouped_structures, opts) do
    group_ids_to_filter = opts[:groups]

    groups = get_groups()

    groups =
      if group_ids_to_filter !== nil do
        Enum.filter(groups, &(&1.id in group_ids_to_filter))
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

      {:each_iteration_one_key, key_status} ->
        Enum.map(structures, &new_alternate_case(group, &1, key_status, 1))

      {:each_iteration_many_keys, key_status, batch_amount} ->
        Enum.map(structures, &new_alternate_case(group, &1, key_status, batch_amount))
    end
  end

  ###

  defp new_bulk_constructor_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper) do
    impl_mod = input_wrapper.impl_mod

    # FIXME missing tweaks
    # FIXME we need to shuffle the input variants when build type is random

    fun = group.suite_fun
    fun_arg = {:single, Enum.map(input_wrapper.variants, &impl_mod.to_list/1)}

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
          # FIXME copy duplicate variants?
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

  defp alternate_case_iteration(
    input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status,
    batch_amount, common_rand_seed
  ) when batch_amount === 1
  do
    case key_status do
      :existing ->
        assert input_wrapper.n !== 0
        key_index = 0
        [input_variant, existing_key(input_wrapper.existing_keys_tuple, common_rand_seed, key_index)]

      :missing ->
        key_index = 0
        [input_variant, missing_key(input_wrapper.existing_keys_set, common_rand_seed, key_index)]
    end
  end

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
end
