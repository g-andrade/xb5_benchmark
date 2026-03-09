defmodule Xb5Benchmark.Suites do
  alias Xb5Benchmark.CollectionWrappers.ErlangBag
  alias Xb5Benchmark.CollectionWrappers.ErlangSet
  alias Xb5Benchmark.CollectionWrappers.ErlangTree
  alias Xb5Benchmark.Suite

  ##

  defmodule ErlGbSet do
    use Suite, wrapper_mod: ErlangSet, coll_mod: :gb_sets
  end

  defmodule ErlGbTree do
    use Suite, wrapper_mod: ErlangTree, coll_mod: :gb_trees
  end

  ##

  defmodule ErlXb5Bag do
    use Suite, wrapper_mod: ErlangBag, coll_mod: :xb5_bag
  end

  defmodule ErlXb5Set do
    use Suite, wrapper_mod: ErlangSet, coll_mod: :xb5_sets
  end

  defmodule ErlXb5Tree do
    use Suite, wrapper_mod: ErlangTree, coll_mod: :xb5_trees
  end

  defmodule ErlXb5TreeV2 do
    use Suite, wrapper_mod: ErlangTree, coll_mod: :xb5_trees_v2
  end
end
