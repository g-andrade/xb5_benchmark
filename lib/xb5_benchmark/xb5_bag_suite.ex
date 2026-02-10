defmodule Xb5Benchmark.Xb5BagSuite do
  alias Xb5Benchmark.Groups

  ############

  def impl_mod, do: :xb5_bag

  def tests do
    [
      {Groups.alternate_insert_and_delete(), &alternate_put_new_and_delete!/1},
      {Groups.delete(), &delete!/1},
      {Groups.insert(), &put_new!/1},
      {Groups.is_defined(), &member?/1},
      {Groups.take_largest(), &pop_largest!/1},
      {Groups.take_smallest(), &pop_smallest!/1}
    ]
  end

  ## TODO nth, percentile, etc?

  #############

  def alternate_put_new_and_delete!([bag | keys]) do
    alternate_put_new_and_delete!(bag, keys)
  end

  defp alternate_put_new_and_delete!(bag, [key_to_put, key_to_delete | next]) do
    bag = :xb5_bag.insert(key_to_put, bag)
    bag = :xb5_bag.delete(key_to_delete, bag)
    alternate_put_new_and_delete!(bag, next)
  end

  defp alternate_put_new_and_delete!(_, []) do
    :ok
  end

  #############

  def delete!([bag | keys]) do
    delete_recur!(bag, keys)
  end

  defp delete_recur!(bag, [key | next]) do
    bag = :xb5_bag.delete(key, bag)
    delete_recur!(bag, next)
  end

  defp delete_recur!(_, []) do
    :ok
  end

  #############

  def member?([bag | keys]) do
    member?(bag, keys)
  end

  defp member?(bag, [key | next]) do
    _ = :xb5_bag.is_member(key, bag)
    member?(bag, next)
  end

  defp member?(_, []) do
    :ok
  end

  #############

  def pop_largest!([bag | amount]) do
    # assert amount <= :xb5_bag.size(bag)
    pop_largest_recur!(bag, amount)
  end

  defp pop_largest_recur!(bag, amount) when amount > 0 do
    {_, bag} = :xb5_bag.take_largest(bag)
    pop_largest_recur!(bag, amount - 1)
  end

  defp pop_largest_recur!(_, 0) do
    :ok
  end

  #############

  def pop_smallest!([bag | amount]) do
    # assert amount <= :xb5_bag.size(bag)
    pop_smallest_recur!(bag, amount)
  end

  defp pop_smallest_recur!(bag, amount) when amount > 0 do
    {_, bag} = :xb5_bag.take_smallest(bag)
    pop_smallest_recur!(bag, amount - 1)
  end

  defp pop_smallest_recur!(_, 0) do
    :ok
  end

  #############

  def put_new!([bag | keys]) do
    put_new!(bag, keys)
  end

  defp put_new!(bag, [key | next]) do
    bag = :xb5_bag.insert(key, bag)
    put_new!(bag, next)
  end

  defp put_new!(_, []) do
    :ok
  end
end
