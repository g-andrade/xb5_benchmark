defmodule Xb5Benchmark.ErlangBag do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    bag_mod = opts[:bag_mod]

    quote do
      @compile {:inline, bag_delete: 2}
      def bag_delete(bag, key) do
        unquote(bag_mod).delete_any(key, bag)
      end

      @compile {:inline, bag_delete!: 2}
      def bag_delete!(bag, key) do
        unquote(bag_mod).delete(key, bag)
      end

      @compile {:inline, bag_filter: 2}
      def bag_filter(bag, fun) do
        unquote(bag_mod).filter(fun, bag)
      end

      defdelegate bag_iterator(bag), to: unquote(bag_mod), as: :iterator
      defdelegate bag_largest!(bag), to: unquote(bag_mod), as: :largest

      @compile {:inline, bag_map: 2}
      def bag_map(bag, fun) do
        unquote(bag_mod).map(fun, bag)
      end

      @compile {:inline, bag_member?: 2}
      def bag_member?(bag, key) do
        unquote(bag_mod).is_member(key, bag)
      end

      defdelegate bag_next(bag), to: unquote(bag_mod), as: :next

      defdelegate bag_pop_largest!(bag), to: unquote(bag_mod), as: :take_largest
      defdelegate bag_pop_smallest!(bag), to: unquote(bag_mod), as: :take_smallest

      @compile {:inline, bag_put_new!: 2}
      def bag_put_new!(bag, key) do
        unquote(bag_mod).insert(key, bag)
      end

      defdelegate bag_size(bag), to: unquote(bag_mod), as: :size

      defdelegate bag_smallest!(bag), to: unquote(bag_mod), as: :smallest
      defdelegate bag_to_list(bag), to: unquote(bag_mod), as: :to_list

      ################
      ################

      def bag_function_description(:delete!), do: ":#{unquote(bag_mod)}.delete/2"
      def bag_function_description(:delete), do: ":#{unquote(bag_mod)}.delete_any/2"
    end
  end
end
