defmodule Xb5Benchmark.ErlangTree do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    tree_mod = opts[:tree_mod]

    quote do
      @compile {:inline, tree_delete: 2}
      def tree_delete(tree, key) do
        unquote(tree_mod).delete_any(key, tree)
      end

      @compile {:inline, tree_delete!: 2}
      def tree_delete!(tree, key) do
        unquote(tree_mod).delete(key, tree)
      end

      @compile {:inline, tree_fetch!: 2}
      def tree_fetch!(tree, key) do
        unquote(tree_mod).get(key, tree)
      end

      defdelegate tree_iterator(tree), to: unquote(tree_mod), as: :iterator
      defdelegate tree_keys(tree), to: unquote(tree_mod), as: :keys
      defdelegate tree_largest!(tree), to: unquote(tree_mod), as: :largest

      @compile {:inline, tree_map: 2}
      def tree_map(tree, fun) do
        unquote(tree_mod).map(fun, tree)
      end

      @compile {:inline, tree_has_key?: 2}
      def tree_has_key?(tree, key) do
        unquote(tree_mod).is_defined(key, tree)
      end

      defdelegate tree_next(tree), to: unquote(tree_mod), as: :next

      @compile {:inline, tree_pop!: 2}
      def tree_pop!(tree, key) do
        unquote(tree_mod).take(key, tree)
      end

      defdelegate tree_pop_largest!(tree), to: unquote(tree_mod), as: :take_largest
      defdelegate tree_pop_smallest!(tree), to: unquote(tree_mod), as: :take_smallest

      @compile {:inline, tree_put_new!: 3}
      def tree_put_new!(tree, key, value) do
        unquote(tree_mod).insert(key, value, tree)
      end

      @compile {:inline, tree_replace!: 3}
      def tree_replace!(tree, key, value) do
        unquote(tree_mod).update(key, value, tree)
      end

      defdelegate tree_size(tree), to: unquote(tree_mod), as: :size

      defdelegate tree_smallest!(tree), to: unquote(tree_mod), as: :smallest
      defdelegate tree_to_list(tree), to: unquote(tree_mod), as: :to_list
      defdelegate tree_values(tree), to: unquote(tree_mod), as: :values
    end
  end
end
