defmodule Xb5Benchmark.RandomKeyTaker do
  @moduledoc false
  use TypedStruct

  ## Types

  typedstruct do
    field(:len, non_neg_integer, enforce: true)
    field(:left, [term], enforce: true)
    field(:left_len, [term], enforce: true)
    field(:right, [term], enforce: true)
  end

  ## API

  def add(%__MODULE__{} = taker, item) do
    %{taker | len: taker.len + 1, right: [item | taker.right]}
  end

  def new(list) do
    left_len = len = length(list)

    %__MODULE__{
      len: len,
      left: list,
      left_len: left_len,
      right: []
    }
  end

  def pop(%__MODULE__{len: 0}) do
    :none
  end

  def pop(%__MODULE__{len: len, left: left, left_len: left_len, right: right} = taker) do
    # assert length(left) === left_len
    # assert left_len + length(right) === len

    n = :rand.uniform(len)

    if n > left_len do
      m = n - left_len
      {popped_key, left, right} = pop_right!(m, left, right)
      len = len - 1
      left_len = left_len + m - 1
      taker = %{taker | len: len, left: left, left_len: left_len, right: right}
      {popped_key, taker}
    else
      {popped_key, left, right} = pop_left!(n, left, right)
      len = len - 1
      left_len = left_len - n
      taker = %{taker | len: len, left: left, left_len: left_len, right: right}
      {popped_key, taker}
    end
  end

  ## Internal

  defp pop_left!(n, [h | t], right) when n > 1 do
    pop_left!(n - 1, t, [h | right])
  end

  defp pop_left!(1, [h | t], right) do
    {h, t, right}
  end

  ##

  defp pop_right!(m, left, [h | t]) when m > 1 do
    pop_right!(m - 1, [h | left], t)
  end

  defp pop_right!(1, left, [h | t]) do
    {h, left, t}
  end
end
