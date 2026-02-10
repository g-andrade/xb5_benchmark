defmodule Xb5Benchmark.ElixirTree do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    tree_mod = opts[:tree_mod]

    quote do
      defdelegate tree_delete!(tree, key), to: unquote(tree_mod), as: :delete!
      defdelegate tree_fetch!(tree, key), to: unquote(tree_mod), as: :fetch!
      defdelegate tree_from_list(tree), to: unquote(tree_mod), as: :new
      defdelegate tree_iterator(tree), to: unquote(tree_mod), as: :iterator
      defdelegate tree_keys(tree), to: unquote(tree_mod), as: :keys
      defdelegate tree_largest!(tree), to: unquote(tree_mod), as: :largest!

      @compile {:inline, tree_map: 2}
      def tree_map(tree, fun) do
        # This is not a fair comparison, there's some overhead to the
        # intermediate fun with arity 1
        unquote(tree_mod).new(tree, fn {k, v} -> fun.(k, v) end)
      end

      defdelegate tree_next(tree), to: unquote(tree_mod), as: :next
      defdelegate tree_pop!(tree, key), to: unquote(tree_mod), as: :pop!
      defdelegate tree_pop_largest!(tree), to: unquote(tree_mod), as: :pop_largest!
      defdelegate tree_pop_smallest!(tree), to: unquote(tree_mod), as: :pop_smallest!
      defdelegate tree_put_new!(tree, key, value), to: unquote(tree_mod), as: :put_new!
      defdelegate tree_replace!(tree, key, value), to: unquote(tree_mod), as: :replace!
      defdelegate tree_smallest!(tree), to: unquote(tree_mod), as: :smallest!
      defdelegate tree_to_list(tree), to: unquote(tree_mod), as: :to_list
      defdelegate tree_values(tree), to: unquote(tree_mod), as: :values
    end
  end
end
