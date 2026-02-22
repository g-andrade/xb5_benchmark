defmodule Xb5Benchmark.Cases do
  use TypedStruct

  import ExUnit.Assertions

  require Logger

  alias Xb5Benchmark.InputStructures
  alias Xb5Benchmark.NewSuites
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
      NewSuites.ErlGbSet,
      NewSuites.ErlGbTree,
      NewSuites.ErlXb5Bag,
      NewSuites.ErlXb5Set,
      NewSuites.ErlXb5Tree,
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
      :delete_all ->
        Enum.map(structures, &new_whole_case(group, &1))

      :delete_any_non_existing ->
        Enum.map(structures, &new_alternate_case(group, &1, :non_existing))

      :delete_existing ->
        Enum.map(structures, &new_alternate_case(group, &1, :existing))

      :get_existing ->
        Enum.map(structures, &new_alternate_case(group, &1, :existing))
    end
  end

  ###

  defp new_whole_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper) do
    fun = group.suite_fun

    # FIXME
    {:multiplier, multiplier} = group.tweaks
    expanded_variants = Enum.flat_map(1..multiplier//1, fn _ -> input_wrapper.variants end)

    random_pick_candidates = Enum.map(expanded_variants, &whole_case_candidate(&1, input_wrapper))

    fun_arg = {:random_pick, List.to_tuple(random_pick_candidates)}

    %Case{
      n: input_wrapper.n,
      build_type: input_wrapper.build_type,
      suite: input_wrapper.suite,
      group: group,
      fun: fun,
      fun_arg: fun_arg
    }
  end

  defp whole_case_candidate(input_variant, %InputStructures.Wrapper{} = input_wrapper) do
    keys = input_wrapper.existing_keys_tuple |> Tuple.to_list() |> Enum.shuffle()
    _arg = [input_variant | keys]
  end

  ###

  defp new_alternate_case(%Group{} = group, %InputStructures.Wrapper{} = input_wrapper, key_status) do
    fun = group.suite_fun

    # FIXME
    {:multiplier, multiplier} = group.tweaks
    expanded_variants = Enum.flat_map(1..multiplier//1, fn _ -> input_wrapper.variants end)

    fun_arg = {:single, Enum.flat_map(expanded_variants, &alternate_case_iteration(&1, input_wrapper, key_status))}

    %Case{
      n: input_wrapper.n,
      build_type: input_wrapper.build_type,
      suite: input_wrapper.suite,
      group: group,
      fun: fun,
      fun_arg: fun_arg
    }
  end

  defp alternate_case_iteration(input_variant, %InputStructures.Wrapper{} = input_wrapper, key_status) do
    case key_status do
      :existing ->
        assert input_wrapper.n !== 0
        [input_variant, existing_key(input_wrapper.existing_keys_tuple)]

      :non_existing ->
        [input_variant, non_existing_key(input_wrapper.existing_keys_set)]
    end
  end

  defp existing_key(existing_keys_tuple) do
    index = :rand.uniform(tuple_size(existing_keys_tuple)) - 1
    elem(existing_keys_tuple, index)
  end

  defp non_existing_key(existing_keys_set) do
    key = InputStructures.new_key()

    if MapSet.member?(existing_keys_set, key) do
      non_existing_key(existing_keys_set)
    else
      key
    end
  end
end
