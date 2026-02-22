defmodule Xb5Benchmark.Experimental do
  import ExUnit.Assertions

  # alias Xb5Benchmark.RandomKeyTaker

  use TypedStruct

  require Logger

  ##

  @min_int_key -Bitwise.<<<(1, 24)
  @max_int_key Bitwise.<<<(1, 24) - 1

  ##

  defmodule Variant do
    typedstruct do
      field(:starting_keys, MapSet.t(term), enforce: true)
      field(:keys_to_insert, [term], enforce: true)
      field(:keys_to_delete, :inapplicable | [term], enforce: true)
      field(:keys_after_insert, MapSet.t(term), enforce: true)
    end
  end

  ##

  def test_sequence(target_max_n) do
    n_step = 100
    total_steps = ceil(target_max_n / n_step)
    max_n = n_step * total_steps

    0..max_n//n_step
    |> Enum.reduce([], &step_sequence(&1, n_step, &2))
    |> Enum.reverse()
  end

  ##

  defp step_sequence(n, n_step, acc) do
    nr_of_variants = nr_of_variants(n, n_step)
    Logger.notice("[n #{n}] Generating #{nr_of_variants} variants")

    if n === 0 do
      assert acc === []
      variants = Enum.map(1..nr_of_variants//1, &initial_variant(&1, n_step))
      [{n, variants}]
    else
      [{prev_n, prev_variants} | _] = acc
      assert prev_n === n - n_step
      variants = prev_variants |> Enum.slice(0, nr_of_variants) |> Enum.map(&evolved_variant(&1, n_step))
      [{n, variants} | acc]
    end
  end

  defp nr_of_variants(n, n_step) do
    #min_variants = 50
    #min_total_keys_after = 1000000
    min_variants = 1
    min_total_keys_after = 100
    max(min_variants, ceil(min_total_keys_after / (n + n_step)))
  end

  defp initial_variant(_variant_n, n_step) do
    starting_keys = MapSet.new()

    {keys_after_insert, keys_to_insert} = new_keys_to_insert(starting_keys, [], n_step)

    %Variant{
      starting_keys: starting_keys,
      keys_to_insert: keys_to_insert,
      keys_to_delete: :inapplicable,
      keys_after_insert: keys_after_insert
    }
  end

  defp evolved_variant(%Variant{} = prev_variant, n_step) do
    {keys_after_insert, keys_to_insert} = new_keys_to_insert(prev_variant.keys_after_insert, [], n_step)
    keys_to_delete = prev_variant.keys_after_insert |> MapSet.to_list() |> List.to_tuple() |> new_keys_to_delete(100)

    %Variant{
      starting_keys: prev_variant.keys_after_insert,
      keys_to_insert: keys_to_insert,
      keys_to_delete: keys_to_delete,
      keys_after_insert: keys_after_insert
    }
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

  defp new_keys_to_insert(existing_keys, acc, 0) do
    {existing_keys, acc}
  end

  defp new_key() do
    @min_int_key + :rand.uniform(@max_int_key - @min_int_key + 1) - 1
  end

  ##

  defp new_keys_to_delete(existing_keys_tuple, amount) when amount > 0 do
    random_index = :rand.uniform(tuple_size(existing_keys_tuple)) - 1
    key = elem(existing_keys_tuple, random_index) 
    [key | new_keys_to_delete(existing_keys_tuple, amount - 1)]
  end

  defp new_keys_to_delete(_existing_keys_tuple, 0) do
    []
  end
end
