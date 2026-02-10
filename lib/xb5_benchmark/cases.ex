defmodule Xb5Benchmark.Cases do
  @moduledoc false
  use TypedStruct

  import ExUnit.Assertions

  alias Xb5Benchmark.ErlangSet
  alias Xb5Benchmark.ErlangTree
  alias Xb5Benchmark.Groups
  alias Xb5Benchmark.Groups.Group
  alias Xb5Benchmark.RandomKeyTaker
  alias Xb5Benchmark.SetSuite
  alias Xb5Benchmark.TreeSuite
  alias Xb5Benchmark.Xb5BagSuite

  require Logger

  ## Constants

  @n_values :lists.usort(Enum.flat_map([[0, 50], 100..1000//100, 1000..10_000//1000, 10_000..15_000//5000], & &1))
  # @n_values :lists.usort(Enum.flat_map([[0, 50], 100..1000//100], & &1))

  @non_empty_n_values List.delete(@n_values, 0)

  @min_int_key -Bitwise.<<<(1, 24)
  @max_int_key Bitwise.<<<(1, 24) - 1

  @recommended_seconds_per_case 0.07142857142857142

  ##################

  ## Types

  defmodule Suites do
    @moduledoc false

    ###

    defmodule ErlGbTree do
      @moduledoc false
      use TreeSuite, tree_mod: :gb_trees, wrapper_mod: ErlangTree
    end

    defmodule ErlXb5Tree do
      @moduledoc false
      use TreeSuite, tree_mod: :xb5_trees, wrapper_mod: ErlangTree
    end

    #######

    defmodule ErlGbSet do
      @moduledoc false
      use SetSuite, set_mod: :gb_sets, wrapper_mod: ErlangSet
    end

    defmodule ErlXb5Set do
      @moduledoc false
      use SetSuite, set_mod: :xb5_sets, wrapper_mod: ErlangSet
    end
  end

  ############

  defmodule Cache do
    @moduledoc false
    alias Xb5Benchmark.Cases.Variant

    typedstruct do
      field(:variant_groups, %{{non_neg_integer(), atom} => Group.t()}, enforce: true)
      field(:test_input_groups, %{{non_neg_integer(), atom, test_input_key} => TestInputGroup.t()}, enforce: true)
    end

    defmodule Group do
      @moduledoc false
      typedstruct do
        field(:variants, [Variant.t()], enforce: true)
      end
    end

    @type test_input_key :: term

    defmodule TestInputGroup do
      @moduledoc false
      typedstruct do
        field(:per_variant, %{Variant.id() => term}, enforce: true)
        field(:save?, boolean, enforce: true)
      end
    end
  end

  defmodule Variant do
    @moduledoc false
    typedstruct do
      field(:id, id, enforce: true)
      field(:n, non_neg_integer, enforce: true)
      field(:build_type, atom, enforce: true)
      field(:build_instructions, [build_instruction], enforce: true)
      field(:initial_keys, [key], enforce: true)
      field(:initial_structures, %{atom => term}, enforce: true)
    end

    @type id :: binary
    @type key :: integer

    @typep build_instruction :: {:insert_all, [key]} | {:delete_all, [key]}
  end

  ## API

  def init_cache do
    combos =
      for n <- @n_values, build_type <- build_types(n) do
        {n, build_type}
          # {{n, build_type}, new_or_cached_variant_group(n, build_type)}
      end

    variant_groups =
      combos
      |> workerpool_map(fn {n, build_type} -> {{n, build_type}, new_or_cached_variant_group(n, build_type)} end)
      |> Map.new()

    %Cache{variant_groups: variant_groups, test_input_groups: %{}}
  end

  def prepare(cache, opts \\ [])

  def prepare(%Cache{} = cache, opts) do
    opt_groups = :proplists.get_value(:groups, opts, :all)

    grouped_tests =
      group_tests([
        Suites.ErlGbSet,
        Suites.ErlGbTree,
        Suites.ErlXb5Set,
        Suites.ErlXb5Tree,
        Xb5BagSuite
      ],
        opt_groups)

    {cases_deep_list, cache} = all_grouped_tests_to_cases(grouped_tests, cache)
    cases = List.to_tuple(List.flatten(cases_deep_list))

    recommended_execution_seconds = @recommended_seconds_per_case * tuple_size(cases)
    %{
      cases: cases,
      recommended_execution_seconds: recommended_execution_seconds,
      cache: cache
    }
  end

  ## Internal

  defp new_or_cached_variant_group(n, build_type) do
    nr_of_variants = nr_of_variants()

    base_cache_path = base_cache_path(n, build_type)
    cache_path = Path.join(base_cache_path, "build_instructions.bin")
    File.mkdir_p!(Path.dirname(cache_path))

    with {:ok, encoded_cache} <- File.read(cache_path),
         {:ok, decoded_cache} <- decode_serialized_cache(encoded_cache),
         {:ok, variant_group, save?} <- fill_variants(n, build_type, nr_of_variants, decoded_cache) do
      maybe_cache_variants!(cache_path, variant_group, save?)
      Logger.notice("[#{n}] [#{build_type}] Variant group ready")
      variant_group
    else
      {:error, :enoent} ->
        variants =
          Enum.map(
            1..nr_of_variants//1,
            fn _ ->
              build_instructions = new_build_instructions(n, build_type)
              initial_keys = initial_keys(build_instructions)

              %Variant{
                id: new_variant_id(),
                n: n,
                build_type: build_type,
                build_instructions: build_instructions,
                initial_keys: initial_keys,
                initial_structures: build_structures(build_instructions, build_type)
              }
            end
          )

        variant_group = %Cache.Group{variants: variants}

        cache_variants!(cache_path, variant_group)
        variant_group
    end
  end

  defp nr_of_variants() do
    50
  end

  defp base_cache_path(n, build_type) do
    n_str = n |> Integer.to_string() |> String.pad_leading(9, "0")
    Path.join(["_cache", build_type_folder(build_type), "#{n_str}"])
  end

  defp new_variant_id do
    :crypto.strong_rand_bytes(16)
  end

  defp build_type_folder(build_type) do
    # FIXME shorten very long build types that may conflict with max path sizes
    "#{build_type}"
  end

  defp expand_n_and_build_types(n_values, %Cache{} = cache, fun) do
    base_pairs =
      for n <- n_values, build_type <- build_types(n) do
        {n, build_type}
      end

    ##

    base_pairs
    |> Enum.map_reduce(
      cache,
      fn {n, build_type}, %Cache{} = cache ->

        cache.variant_groups
        |> Map.fetch!({n, build_type})
        |> then(
          fn %Cache.Group{} = group -> 
            variants = group.variants 
            variants
          end)
        |> Enum.map_reduce(
          cache,
          fn %Variant{} = variant, cache ->
            fun.(variant, cache)
          end
        )
      end
    )
    |> then(fn {cases, cache} ->
      cache = save_test_input_groups(cache)
      {cases, cache}
    end)
  end

  defp build_types(0) do
    [:sequential]
  end

  defp build_types(_n) do
    [
      :sequential,
      :random,
      # :random_ins2x_random_del1x,
      :adversarial
    ]
  end

  defp decode_serialized_cache(encoded) do
    {:ok, :erlang.binary_to_term(encoded, [:safe])}
  catch
    :error, :badarg ->
      {:error, :failed_to_decode}
  end

  defp fill_variants(n, build_type, nr_of_variants, decoded_cache) do
    Logger.notice("[#{n}] [#{build_type}] Read cache, filling variants")
    fill_variants!(n, build_type, nr_of_variants, decoded_cache)
  catch
    :error, reason ->
      {:error, {:fill_variants, reason, __STACKTRACE__}}
  else
    {variant_group, save?} ->
      {:ok, variant_group, save?}
  end

  defp fill_variants!(n, build_type, nr_of_variants, decoded_cache) do
    cached_ids = Enum.map(decoded_cache, fn {id, _build_instructions} -> id end)
    assert :lists.sort(cached_ids) === :lists.usort(cached_ids)

    {build_instructions_variants, save?} =
      fill_missing_build_instructions_variants(n, build_type, nr_of_variants, decoded_cache)

    variants =
      Enum.map(
        build_instructions_variants,
        fn {id, build_instructions} ->
          initial_keys = initial_keys(build_instructions)
          assert length(initial_keys) === n

          %Variant{
            id: id,
            n: n,
            build_type: build_type,
            build_instructions: build_instructions,
            initial_keys: initial_keys,
            initial_structures: build_structures(build_instructions, build_type)
          }
        end
      )

    {%Cache.Group{variants: variants}, save?}
  end

  defp fill_missing_build_instructions_variants(n, build_type, nr_of_variants, decoded_cache) do
    amount_missing = nr_of_variants - length(decoded_cache)

    cond do
      amount_missing > 0 ->
        Logger.notice("Missing #{amount_missing} variant(s)")
        save? = true

        new =
          Enum.map(1..amount_missing//1, fn _ ->
            id = new_variant_id()
            {id, new_build_instructions(n, build_type)}
          end)

        updated = new ++ decoded_cache
        {updated, save?}

      amount_missing === 0 ->
        save? = false
        {decoded_cache, save?}

      amount_missing < 0 ->
        save? = false
        updated = Enum.slice(decoded_cache, 0, nr_of_variants)
        {updated, save?}
    end
  end

  defp maybe_cache_variants!(_cache_path, _variants, false), do: :ok
  defp maybe_cache_variants!(cache_path, variants, true), do: cache_variants!(cache_path, variants)

  defp cache_variants!(cache_path, %Cache.Group{variants: variants}) do
    Logger.notice("Writing to cache (#{inspect(cache_path)})")
    decoded_cache = Enum.map(variants, fn %Variant{} = variant -> {variant.id, variant.build_instructions} end)
    encoded_cache = :erlang.term_to_binary(decoded_cache, compressed: 9)
    File.write!(cache_path, encoded_cache)
  end

  ##

  defp new_build_instructions(n, :sequential) do
    [
      {:insert_all, new_keys(n)}
    ]
  end

  defp new_build_instructions(n, :random) do
    [
      {:insert_all, n |> new_keys() |> Enum.shuffle()}
    ]
  end

  defp new_build_instructions(n, :random_ins2x_random_del1x) do
    insert_keys = (n * 2) |> new_keys() |> Enum.shuffle()
    delete_keys = Enum.take_random(insert_keys, n)

    [
      {:insert_all, insert_keys},
      {:delete_all, delete_keys}
    ]
  end

  defp new_build_instructions(n, :adversarial) do
    delete_amount = div(n, 4)

    # build sequentially
    insert_keys = new_keys(n + delete_amount)

    # delete every 4th key
    delete_keys =
      insert_keys
      |> Enum.with_index()
      |> Enum.filter(fn {_key, index} ->
        rem(index + 1, 4) === 0
      end)
      |> Enum.take(delete_amount)
      |> Enum.map(&elem(&1, 0))

    [
      {:insert_all, insert_keys},
      {:delete_all, delete_keys}
    ]
  end

  defp initial_keys(build_instructions) do
    Enum.reduce(
      build_instructions,
      [],
      fn
        {:insert_all, keys}, [] ->
          keys

        {:delete_all, keys}, acc ->
          acc -- keys
      end
    )
  end

  ##

  defp build_structures(build_instructions, build_type) do
    %{
      gb_sets: initial_gb_set(build_instructions),
      gb_trees: initial_gb_tree(build_instructions),
      xb5_bag: initial_xb5_bag(build_instructions),
      xb5_sets: initial_xb5_set(build_instructions),
      xb5_trees: initial_xb5_tree(build_instructions, build_type)
    }
  end

  ##

  defp initial_gb_set(build_instructions) do
    Enum.reduce(
      build_instructions,
      :gb_sets.empty(),
      fn
        {:insert_all, keys}, t ->
          Enum.reduce(keys, t, &:gb_sets.insert/2)

        {:delete_all, keys}, t ->
          Enum.reduce(keys, t, &:gb_sets.delete/2)
      end
    )
  end

  ##

  defp initial_gb_tree(build_instructions) do
    Enum.reduce(
      build_instructions,
      :gb_trees.empty(),
      fn
        {:insert_all, keys}, t ->
          keys
          |> keys_to_kvs()
          |> Enum.reduce(t, fn {k, v}, acc -> :gb_trees.insert(k, v, acc) end)

        {:delete_all, keys}, t ->
          Enum.reduce(keys, t, &:gb_trees.delete/2)
      end
    )
  end

  ##

  defp initial_xb5_bag(build_instructions) do
    Enum.reduce(
      build_instructions,
      :xb5_bag.new(),
      fn
        {:insert_all, keys}, t ->
          Enum.reduce(keys, t, &:xb5_bag.insert/2)

        {:delete_all, keys}, t ->
          Enum.reduce(keys, t, &:xb5_bag.delete/2)
      end
    )
  end

  ##

  defp initial_xb5_set(build_instructions) do
    Enum.reduce(
      build_instructions,
      :xb5_sets.empty(),
      fn
        {:insert_all, keys}, t ->
          Enum.reduce(keys, t, &:xb5_sets.insert/2)

        {:delete_all, keys}, t ->
          Enum.reduce(keys, t, &:xb5_sets.delete/2)
      end
    )
  end

  ##

  defp initial_xb5_tree(build_instructions, _build_type) do
    t =
      Enum.reduce(
        build_instructions,
        nil,
        fn
          {:insert_all, keys}, nil ->
            keys |> keys_to_kvs() |> :xb5_trees.from_list()

          {:delete_all, keys}, t ->
            Enum.reduce(keys, t, &:xb5_trees.delete/2)
        end
      )

    # assert_xb5_tree_expected_density(t, build_type)

    t
  end

  #  defp assert_xb5_tree_expected_density(t, :adversarial) do
  #    if :xb5_trees.size(t) >= 2000 do
  #      stats = :xb5_trees.structural_stats(t)
  #      avg_keys_per_internal_node = Keyword.fetch!(stats, :avg_keys_per_internal_node)
  #
  #      assert avg_keys_per_internal_node < 2.5
  #    end
  #  end
  #
  #  defp assert_xb5_tree_expected_density(_t, _build_type) do
  #    # TODO
  #    :ok
  #  end

  ##

  defp new_keys(n) do
    acc = %{}
    new_keys_recur(n, acc)
  end

  defp new_keys_recur(n, acc) when n > 0 do
    new_key = new_key()

    if is_map_key(acc, new_key) do
      new_keys_recur(n, acc)
    else
      acc = Map.put(acc, new_key, :set)
      new_keys_recur(n - 1, acc)
    end
  end

  defp new_keys_recur(0, acc) do
    acc |> Map.keys() |> :lists.sort()
  end

  defp new_key do
    @min_int_key + :rand.uniform(@max_int_key - @min_int_key + 1) - 1
  end

  defp keys_to_kvs(keys) do
    Enum.map(keys, &{&1, :value})
  end

  ############

  def group_tests(suite_modules, opt_groups) do
    Enum.reduce(
      suite_modules,
      %{},
      &group_suite_tests(&1, &2, opt_groups)
    )
  end

  defp group_suite_tests(suite_module, acc, opt_groups) do
    impl_mod = suite_module.impl_mod()
    all_suite_tests = suite_module.tests()

    tests =
      case opt_groups do
        :all ->
          all_suite_tests

        filtered ->
          Enum.filter(all_suite_tests, fn {%Group{} = group, _} -> group.id in filtered end)
      end

    Enum.reduce(
      tests,
      acc,
      &group_suite_test(impl_mod, &1, &2)
    )
  end

  defp group_suite_test(impl_mod, {%Group{} = group, test_fun}, acc) do
    assert is_function(test_fun, 1)

    case Map.fetch(acc, group.id) do
      {:ok, grouped_test_infos} ->
        grouped_test_infos = [{group.id, impl_mod, test_fun} | grouped_test_infos]
        %{acc | group.id => grouped_test_infos}

      :error ->
        grouped_test_infos = [{group.id, impl_mod, test_fun}]
        Map.put(acc, group.id, grouped_test_infos)
    end
  end

  ############

  defp all_grouped_tests_to_cases(groups, cache) do
    Enum.map_reduce(groups, cache, &group_to_cases/2)
  end

  defp group_to_cases({group_id, test_pairs}, cache) do
    group = %Group{} = apply(Groups, group_id, [])

    case group.input_type do
      :amount ->
        expand_n_and_build_types(
          @non_empty_n_values,
          cache,
          fn %Variant{} = variant, cache ->
            amount = amount_of_keys(variant, group.input_amount)
            {new_cases(variant, test_pairs, amount), cache}
          end
        )

      :existing_keys_to_delete_cumulatively ->
        expand_n_and_build_types(
          @non_empty_n_values,
          cache,
          fn %Variant{} = variant, cache ->
            expand_existing_keys_to_delete_cumulatively(
              variant,
              group.input_amount,
              &new_cases(variant, test_pairs, &1),
              cache
            )
          end
        )

      :existing_keys_to_lookup ->
        expand_n_and_build_types(
          @non_empty_n_values,
          cache,
          fn %Variant{} = variant, cache ->
            expand_existing_keys_to_lookup(
              variant,
              group.input_amount,
              &new_cases(variant, test_pairs, &1),
              cache
            )
          end
        )

      :keys_to_alternate_insert_and_delete ->
        expand_n_and_build_types(
          @non_empty_n_values,
          cache,
          fn %Variant{} = variant, cache ->
            expand_keys_to_alternate_insert_and_delete(
              variant,
              group.input_amount,
              &new_cases(variant, test_pairs, &1),
              cache
            )
          end
        )

      :new_keys_to_insert ->
        expand_n_and_build_types(
          @non_empty_n_values,
          cache,
          fn %Variant{} = variant, cache ->
            expand_new_keys_to_insert(
              variant,
              group.input_amount,
              &new_cases(variant, test_pairs, &1),
              cache
            )
          end
        )
    end
  end

  defp new_cases(%Variant{} = variant, test_pairs, test_arg2) do
    Enum.map(
      test_pairs,
      fn {group_id, impl_mod, test_fun} ->
        initial_structure = Map.fetch!(variant.initial_structures, impl_mod)
        case_id = {group_id, impl_mod, variant.build_type, variant.n}
        case_arg = [initial_structure | test_arg2]
        {case_id, test_fun, case_arg}
      end
    )
  end

  ############

  defp expand_existing_keys_to_lookup(%Variant{} = variant, input_amount, fun, cache) do
    amount = amount_of_keys(variant, input_amount)

    {keys, cache} =
      new_or_cached_input(
        variant,
        {:existing_keys_to_lookup, amount},
        fn -> new_random_existing_keys_to_lookup(variant.initial_keys, amount) end,
        cache
      )

    {fun.(keys), cache}
  end

  defp new_random_existing_keys_to_lookup(initial_keys, amount) do
    initial_keys_tuple = List.to_tuple(initial_keys)
    new_random_existing_keys_to_lookup_recur(initial_keys_tuple, amount)
  end

  defp new_random_existing_keys_to_lookup_recur(initial_keys_tuple, amount) when amount > 0 do
    index = :rand.uniform(tuple_size(initial_keys_tuple)) - 1
    key = elem(initial_keys_tuple, index)
    [key | new_random_existing_keys_to_lookup_recur(initial_keys_tuple, amount - 1)]
  end

  defp new_random_existing_keys_to_lookup_recur(_initial_keys_tuple, 0) do
    []
  end

  ############

  defp expand_new_keys_to_insert(%Variant{} = variant, input_amount, fun, cache) do
    amount = amount_of_keys(variant, input_amount)

    {keys, cache} =
      new_or_cached_input(
        variant,
        {:new_keys_to_insert, amount},
        fn -> new_random_new_keys_to_insert(variant.initial_keys, amount) end,
        cache
      )

    {fun.(keys), cache}
  end

  defp new_random_new_keys_to_insert(initial_keys, amount) do
    new_keys = new_random_new_keys_to_insert_recur(MapSet.new(initial_keys), amount)
    assert new_keys -- initial_keys === new_keys
    new_keys
  end

  defp new_random_new_keys_to_insert_recur(existing_acc, amount) when amount > 0 do
    {new_key, existing_acc} = new_key_to_insert(existing_acc)
    [new_key | new_random_new_keys_to_insert_recur(existing_acc, amount - 1)]
  end

  defp new_random_new_keys_to_insert_recur(_, 0) do
    []
  end

  ############

  defp expand_existing_keys_to_delete_cumulatively(%Variant{} = variant, input_amount, fun, cache) do
    amount = amount_of_keys(variant, input_amount)

    {keys, cache} =
      new_or_cached_input(
        variant,
        {:existing_keys_to_delete_cumulatively, amount},
        fn ->
          taker = RandomKeyTaker.new(variant.initial_keys)
          new_random_keys_to_delete_cumulatively(taker, amount)
        end,
        cache
      )

    assert length(keys) <= length(variant.initial_keys)

    {fun.(keys), cache}
  end

  defp amount_of_keys(%Variant{} = variant, input_amount) do
    case input_amount do
      _ when is_integer(input_amount) and input_amount > 0 ->
        input_amount

      {:max, max} ->
        min(max, variant.n)
    end
  end

  defp new_random_keys_to_delete_cumulatively(taker, amount) when amount > 0 do
    case RandomKeyTaker.pop(taker) do
      {key_to_delete, taker} ->
        [key_to_delete | new_random_keys_to_delete_cumulatively(taker, amount - 1)]

      :none ->
        []
    end
  end

  defp new_random_keys_to_delete_cumulatively(_taker, 0) do
    []
  end

  ############

  # defp expand_non_existent_keys(%Variant{} = variant, amount, fun, cache) do
  #   {keys, cache} =
  #     new_or_cached_input(
  #       variant,
  #       {:non_existent_keys, amount},
  #       fn ->
  #         acc = :maps.from_keys(variant.initial_keys, :set)
  #         Enum.shuffle(new_keys_recur(amount, acc) -- variant.initial_keys)
  #       end,
  #       cache
  #     )

  #   {fun.(keys), cache}
  # end

  ############

  defp expand_keys_to_alternate_insert_and_delete(%Variant{} = variant, input_amount, fun, cache) do
    amount = amount_of_keys(variant, input_amount)

    {keys, cache} =
      new_or_cached_input(
        variant,
        {:keys_to_alternate_insert_and_delete, amount},
        fn ->
          taker = RandomKeyTaker.new(variant.initial_keys)
          existing_acc = MapSet.new(variant.initial_keys)
          keys_to_alternate_insert_and_delete(taker, existing_acc, amount)
        end,
        cache
      )

    {fun.(keys), cache}
  end

  defp keys_to_alternate_insert_and_delete(taker, existing_acc, amount) when amount > 0 do
    {key_to_insert, existing_acc} = new_key_to_insert(existing_acc)
    taker = RandomKeyTaker.add(taker, key_to_insert)

    {key_to_delete, taker} = RandomKeyTaker.pop(taker)
    existing_acc = MapSet.delete(existing_acc, key_to_delete)

    [key_to_insert, key_to_delete | keys_to_alternate_insert_and_delete(taker, existing_acc, amount - 2)]
  end

  defp keys_to_alternate_insert_and_delete(_taker, _existing_acc, 0) do
    []
  end

  defp new_key_to_insert(existing_acc) do
    new_key = new_key()

    if MapSet.member?(existing_acc, new_key) do
      new_key_to_insert(existing_acc)
    else
      existing_acc = MapSet.put(existing_acc, new_key)
      {new_key, existing_acc}
    end
  end

  # defp expand_keys_to_delete(initial_keys, max_amount, fun) do
  #   fun.(keys_to_delete(initial_keys, max_amount))
  # end

  # defp keys_to_delete(existing_keys, amount) when existing_keys !== [] and amount > 0 do
  #   [key | existing_keys] = Enum.shuffle(existing_keys)
  #   [key | keys_to_delete(existing_keys, amount - 1)]
  # end

  # defp keys_to_delete(_initial_keys, _amount) do
  #   []
  # end

  ############

  defp new_or_cached_input(%Variant{} = variant, test_input_key, new_fun, %Cache{} = cache) do
    group_key = {variant.n, variant.build_type, test_input_key}

    case Map.fetch(cache.test_input_groups, group_key) do
      {:ok, %Cache.TestInputGroup{} = group} ->
        case Map.fetch(group.per_variant, variant.id) do
          {:ok, input_value} ->
            {input_value, cache}

          :error ->
            input_value = new_fun.()
            group = %{group | per_variant: Map.put(group.per_variant, variant.id, input_value), save?: true}
            test_input_groups = %{cache.test_input_groups | group_key => group}
            cache = %{cache | test_input_groups: test_input_groups}
            {input_value, cache}
        end

      :error ->
        base_cache_path = base_cache_path(variant.n, variant.build_type)
        cache_path = Path.join(base_cache_path, test_input_filename(test_input_key, variant.n))

        with {:ok, encoded_cache} <- File.read(cache_path),
             {:ok, per_variant} <- decode_serialized_cache(encoded_cache) do
          cached_group = %Cache.TestInputGroup{
            per_variant: per_variant,
            save?: false
          }

          cache = %{cache | test_input_groups: Map.put(cache.test_input_groups, group_key, cached_group)}
          new_or_cached_input(variant, test_input_key, new_fun, cache)
        else
          {:error, :enoent} ->
            input_value = new_fun.()

            new_group = %Cache.TestInputGroup{
              per_variant: %{variant.id => input_value},
              save?: true
            }

            test_input_groups = Map.put(cache.test_input_groups, group_key, new_group)
            cache = %{cache | test_input_groups: test_input_groups}
            {input_value, cache}
        end
    end
  end

  defp test_input_filename({tag, input_amount}, n) when is_atom(tag) do
    case input_amount do
      amount when is_integer(amount) and amount > 0 ->
        "#{tag}_x#{amount}"

      {:max, max} ->
        amount = min(max, n)
        "#{tag}_x#{amount}"
    end
  end

  defp save_test_input_groups(%Cache{test_input_groups: test_input_groups} = cache) do
    in_need_of_saving = Enum.filter(test_input_groups, fn {_group_id, %Cache.TestInputGroup{} = group} -> group.save? end)

    Enum.reduce(in_need_of_saving, cache, &save_test_input_group(&2, &1))
  end

  defp save_test_input_group(%Cache{} = cache, {group_id, %Cache.TestInputGroup{save?: save?} = group}) do
    assert save?

    {n, build_type, test_input_key} = group_id

    base_cache_path = base_cache_path(n, build_type)
    cache_path = Path.join(base_cache_path, test_input_filename(test_input_key, n))

    encoded_cache = :erlang.term_to_binary(group.per_variant, compressed: 9)
    File.write!(cache_path, encoded_cache)

    group = %{group | save?: false}
    %{cache | test_input_groups: %{cache.test_input_groups | group_id => group}}
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
    } = :taskforce.execute(tasks, %{max_workers: min(System.schedulers_online(), 4)})
  
    assert individual_timeouts === []
    assert global_timeouts === []
  
    completed_tasks
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.map(fn {_, mapped_value} -> mapped_value end)
  end
end
