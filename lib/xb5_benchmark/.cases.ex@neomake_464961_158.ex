defmodule Xb5Benchmark.Cases do
  use TypedStruct

  import ExUnit.Assertions

  require Logger

  alias Xb5Benchmark.InputStructures
  alias Xb5Benchmark.Suites
  alias Xb5Benchmark.Groups.Group

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
      field(:sampling_group_number, nil | pos_integer) # Set by runner
    end

    @type fun_arg() :: (
      {:single, term}
      | {:random_pick, tuple()}
    )
  end

  ## API

  def get() do
    Logger.notice("Preparing cases...")
    input_structures = get_input_structures()
    grouped_structures = Enum.group_by(input_structures, &(&1.impl_mod))
    cases = get_cases(grouped_structures)
    :erlang.garbage_collect(self())
    cases
  end

  ## Internal

  defp get_input_structures() do
    cache_key = {__MODULE__, :input_structures}

    case Process.get(cache_key) do
      nil ->
        input_structures = InputStructures.generate(@target_max_n)
        Process.put(cache_key, input_structures)
        input_structures

      input_structures ->
        input_structures
    end
  end

  defp get_cases(grouped_structures) do
    groups = get_groups()

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
      :each_iteration_no_keys ->
        Enum.map(structures, &new_alternate_case(group, &1, :no_keys, 0))

      {:each_iteration_no_keys, arg} ->
        Enum.map(structures, &new_alternate_case(group, &1, {:no_keys, arg}, 0))

      {:each_iteration_one_key, key_status} ->
        Enum.map(structures, &new_alternate_case(group, &1, key_status, 1))

      {:each_iteration_many_keys, key_status, batch_amount} ->
        Enum.map(structures, &new_alternate_case(group, &1, key_status, batch_amount))

      {:each_iteration_building_from_list, key_order} ->
        Enum.map(structures, &new_alternate_case_building_from_list(group, &1, key_order))

    end
  end

  ###

  defp new_alternate_case_building_from_list(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper, key_order) do
    assert group.tweaks === :none

    fun = group.suite_fun

    existing_keys = Tuple.to_list(input_wrapper.existing_keys_tuple) |> Enum.sort()
    amount_of_variants = length(input_wrapper.variants_)
    is_impl_kv = group.impl_mod in [:gb_trees, :xb5_trees]

    fun_arg =
      case {key_order, is_impl_kv} do
        {:ordered, false} ->
          copies = Xb5Benchmark.Utils.deep_copy_term_n_times(existing_keys, amount_of_variants - 1)
          [existing_keys | copies]

        {:ordered, true} ->
          kvs = Enum.map(existing_keys, &{&1, :initial_value})
          copies = Xb5Benchmark.Utils.deep_copy_term_n_times(existing_keys, amount_of_variants - 1)
          [kvs | copies]

        {:shuffled, false} ->
          Enum.map(1..amount_of_variants//1, fn _ -> Enum.shuffle(existing_keys) end)

        {:shuffled, true} ->
          kvs = Enum.map(existing_keys, &{&1, :initial_value})
          Enum.map(1..amount_of_variants//1, fn _ -> Enum.shuffle(existing_keys) end)




    # TODO
    todo
  end


  ###

  defp new_alternate_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper, key_status, batch_amount) do
    fun = group.suite_fun

    fun_arg =
      case group.tweaks do
        {:duplicate_variants, multiplier} ->
          expanded_variants = Enum.flat_map(1..multiplier//1, fn _ -> input_wrapper.variants end)
          {:single, Enum.flat_map(expanded_variants, &alternate_case_iteration(&1, input_wrapper, key_status, batch_amount))}

        :none ->
          {:single, Enum.flat_map(input_wrapper.variants, &alternate_case_iteration(&1, input_wrapper, key_status, batch_amount))}
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

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{}, :no_keys, _) do
    [input_variant]
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{}, {:no_keys, arg}, _) do
    [input_variant, arg]
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status, 1) do
    case key_status do
      :existing ->
        assert input_wrapper.n !== 0
        [input_variant, existing_key(input_wrapper.existing_keys_tuple)]

      :missing ->
        [input_variant, missing_key(input_wrapper.existing_keys_set)]
    end
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status, batch_amount) do
    case key_status do
      :existing ->
        assert input_wrapper.n !== 0
        [input_variant, existing_keys_independent(input_wrapper.existing_keys_tuple, batch_amount)]

      :missing ->
        [input_variant, missing_keys(input_wrapper.existing_keys_set, batch_amount)]

      :missing_and_unique ->
        [input_variant, missing_keys_unique(input_wrapper.existing_keys_set, batch_amount)]
    end
  end

  ##

  defp existing_key(existing_keys_tuple) do
    index = :rand.uniform(tuple_size(existing_keys_tuple)) - 1
    elem(existing_keys_tuple, index)
  end

  ##

  defp missing_key(existing_keys_set) do
    key = InputStructures.new_key()

    if MapSet.member?(existing_keys_set, key) do
      missing_key(existing_keys_set)
    else
      key
    end
  end

  ##

  defp existing_keys_independent(existing_keys_tuple, amount) do
    Enum.map(1..amount//1, fn _ -> existing_key(existing_keys_tuple) end)
  end

  ##

  defp missing_keys(initial_keys_set, amount) when amount > 0 do
    key = missing_key(initial_keys_set)
    [key | missing_keys(initial_keys_set, amount - 1)]
  end

  defp missing_keys(_initial_keys_set, 0) do
    []
  end

  ##

  defp missing_keys_unique(_existing_keys_set, 0) do
    []
  end

  defp missing_keys_unique(existing_keys_set, amount) when amount > 0 do
    key = missing_key(existing_keys_set)
    existing_keys_set = MapSet.put(existing_keys_set, key)
    [key | missing_keys_unique(existing_keys_set, amount - 1)]
  end

  defp missing_keys_unique(_existing_keys_set, 0) do
    []
  end
end
