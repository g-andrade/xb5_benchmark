defmodule Xb5Benchmark.Suites do
  alias Xb5Benchmark.ErlangBag
  alias Xb5Benchmark.ErlangSet
  alias Xb5Benchmark.ErlangTree
  alias Xb5Benchmark.BagSuite
  alias Xb5Benchmark.SetSuite
  alias Xb5Benchmark.TreeSuite

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

  ##########

  defmodule ErlXb5Bag do
    @moduledoc false
    use BagSuite, bag_mod: :xb5_bag, wrapper_mod: ErlangBag
  end
end
