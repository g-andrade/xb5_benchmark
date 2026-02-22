defmodule Xb5Benchmark.Xb5BagSuite do
  alias Xb5Benchmark.Groups

  ############

  def impl_mod, do: :xb5_bag

  def tests do
    [
      {Groups.alternate_insert_and_delete(), &alternate_put_new_and_delete!/1},
      {Groups.alternate_insert_smallest_and_take_largest(), &alternate_put_new_and_pop_largest!/1},
      {Groups.alternate_insert_largest_and_take_smallest(), &alternate_put_new_and_pop_smallest!/1},
      {Groups.delete(), &delete!/1},
      {Groups.filter_all(), &filter/1},
      {Groups.filter_none(), &filter/1},
      {Groups.insert(), &put_new!/1},
      {Groups.is_defined(), &member?/1},
      {Groups.nth(), &nth/1},
      {Groups.percentile_inclusive(), &percentile_inclusive/1},
      {Groups.percentile_nearest_rank(), &percentile_nearest_rank/1},
      {Groups.percentile_rank(), &percentile_rank/1},
      {Groups.rank(), &rank/1},
      {Groups.rank_larger(), &rank_larger/1},
      {Groups.rank_smaller(), &rank_smaller/1},
      {Groups.take_largest(), &pop_largest!/1},
      {Groups.take_smallest(), &pop_smallest!/1}
    ]
  end

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

  def alternate_put_new_and_pop_largest!([bag | keys]) do
    alternate_put_new_and_pop_largest!(bag, keys)
  end

  defp alternate_put_new_and_pop_largest!(bag, [key_to_put | next]) do
    bag = :xb5_bag.insert(key_to_put, bag)
    {_, bag} = :xb5_bag.take_largest(bag)
    alternate_put_new_and_pop_largest!(bag, next)
  end

  defp alternate_put_new_and_pop_largest!(_bag, []) do
    :ok
  end

  #############

  def alternate_put_new_and_pop_smallest!([bag | keys]) do
    alternate_put_new_and_pop_smallest!(bag, keys)
  end

  defp alternate_put_new_and_pop_smallest!(bag, [key_to_put | next]) do
    bag = :xb5_bag.insert(key_to_put, bag)
    {_, bag} = :xb5_bag.take_smallest(bag)
    alternate_put_new_and_pop_smallest!(bag, next)
  end

  defp alternate_put_new_and_pop_smallest!(_bag, []) do
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

  def filter([bag | amount]) do
    case amount do
      :all ->
        _ = :xb5_bag.filter(fn _ -> true end, bag)

      :none ->
        _ = :xb5_bag.filter(fn _ -> false end, bag)
    end
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

  def nth([bag | ranks]) do
    nth(bag, ranks)
  end

  defp nth(bag, [rank | next]) do
    _ = :xb5_bag.nth(rank, bag)
    nth(bag, next)
  end

  defp nth(_, []) do
    :ok
  end

  #############

  def percentile_inclusive([bag | percentiles]) do
    percentile_inclusive(bag, percentiles)
  end

  defp percentile_inclusive(bag, [percentile | next]) do
    {:value, _} = :xb5_bag.percentile(percentile, bag)
    percentile_inclusive(bag, next)
  end

  defp percentile_inclusive(_, []) do
    :ok
  end

  #############

  def percentile_nearest_rank([bag | percentiles]) do
    percentile_nearest_rank(bag, percentiles)
  end

  defp percentile_nearest_rank(bag, [percentile | next]) do
    {:value, _} = :xb5_bag.percentile(percentile, bag, method: :nearest_rank)
    percentile_nearest_rank(bag, next)
  end

  defp percentile_nearest_rank(_, []) do
    :ok
  end

  #############

  def percentile_rank([bag | keys]) do
    percentile_rank(bag, keys)
  end

  defp percentile_rank(bag, [key | next]) do
    _ = :xb5_bag.percentile_rank(key, bag)
    percentile_rank(bag, next)
  end

  defp percentile_rank(_, []) do
    :ok
  end

  #############

  def rank([bag | keys]) do
    rank(bag, keys)
  end

  defp rank(bag, [key | next]) do
    {:rank, _} = :xb5_bag.rank(key, bag)
    rank(bag, next)
  end

  defp rank(_, []) do
    :ok
  end

  #############

  def rank_larger([bag | keys]) do
    rank_larger(bag, keys)
  end

  defp rank_larger(bag, [key | next]) do
    _ = :xb5_bag.rank_larger(key, bag)
    rank_larger(bag, next)
  end

  defp rank_larger(_, []) do
    :ok
  end

  #############

  def rank_smaller([bag | keys]) do
    rank_smaller(bag, keys)
  end

  defp rank_smaller(bag, [key | next]) do
    _ = :xb5_bag.rank_smaller(key, bag)
    rank_smaller(bag, next)
  end

  defp rank_smaller(_, []) do
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
