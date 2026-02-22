defmodule Xb5Benchmark.Utils do
  # import ExUnit.Assertions

  ## API

##  def gb_sets_balance_score({_size, root}) do
##    {height, _} = gb_sets_count(root)
##    height
##  end
##
##  def gb_trees_balance_score({_size, root}) do
##    {height, _} = gb_trees_count(root)
##    height
##  end

  def gb_sets_count({_size, root}) do
    gb_sets_count_recur(root)
  end

  def gb_trees_count({_size, root}) do
    gb_trees_count_recur(root)
  end

  def deep_copy_term_n_times(term, n) do
    pid = self()
    ref = make_ref()
    _helper_pid = spawn_link(fn -> send(pid, {ref, List.duplicate(term, n)}) end)

    receive do
      {^ref, copies} ->
        copies
    after
      10_000 ->
        raise "Timeout"
    end
  end

  ## Internal

  defp gb_sets_count_recur(node) do
    # Internal implementation from :gb_sets

    case node do
      {_key, nil, nil} ->
        {1, 1}

      {_key, left, right} ->
        {h1, s1} = gb_sets_count_recur(left)
        {h2, s2} = gb_sets_count_recur(right)
        {2 * max(h1, h2), s1 + s2 + 1}

      nil ->
        {1, 0}
    end
  end

  defp gb_trees_count_recur(node) do
    # Internal implementation from :gb_trees

    case node do
      {_key, _value, nil, nil} ->
        {1, 1}

      {_key, _value, left, right} ->
        {h1, s1} = gb_trees_count_recur(left)
        {h2, s2} = gb_trees_count_recur(right)
        {2 * max(h1, h2), s1 + s2 + 1}

      nil ->
        {1, 0}
    end
  end

end
