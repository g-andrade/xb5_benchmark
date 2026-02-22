defmodule Xb5Benchmark.ErlangSet do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    set_mod = opts[:set_mod]

    quote do
      @compile {:inline, set_delete: 2}
      def set_delete(set, key) do
        unquote(set_mod).delete_any(key, set)
      end

      @compile {:inline, set_delete!: 2}
      def set_delete!(set, key) do
        unquote(set_mod).delete(key, set)
      end

      @compile {:inline, set_filter: 2}
      def set_filter(set, fun) do
        unquote(set_mod).filter(fun, set)
      end

      defdelegate set_iterator(set), to: unquote(set_mod), as: :iterator
      defdelegate set_largest!(set), to: unquote(set_mod), as: :largest

      @compile {:inline, set_map: 2}
      def set_map(set, fun) do
        unquote(set_mod).map(fun, set)
      end

      @compile {:inline, set_member?: 2}
      def set_member?(set, key) do
        unquote(set_mod).is_member(key, set)
      end

      defdelegate set_next(set), to: unquote(set_mod), as: :next

      defdelegate set_pop_largest!(set), to: unquote(set_mod), as: :take_largest
      defdelegate set_pop_smallest!(set), to: unquote(set_mod), as: :take_smallest

      @compile {:inline, set_put_new!: 2}
      def set_put_new!(set, key) do
        unquote(set_mod).insert(key, set)
      end

      defdelegate set_size(set), to: unquote(set_mod), as: :size

      defdelegate set_smallest!(set), to: unquote(set_mod), as: :smallest
      defdelegate set_to_list(set), to: unquote(set_mod), as: :to_list
    end
  end
end
