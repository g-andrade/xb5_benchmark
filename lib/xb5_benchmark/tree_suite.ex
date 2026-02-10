defmodule Xb5Benchmark.TreeSuite do
  ############## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    tree_mod = opts[:tree_mod]
    wrapper_mod = opts[:wrapper_mod]

    quote do
      use unquote(wrapper_mod), tree_mod: unquote(tree_mod)

      alias Xb5Benchmark.Groups

      ############

      def impl_mod, do: unquote(tree_mod)

      def tests do
        [
          {Groups.alternate_insert_and_delete(), &alternate_put_new_and_delete!/1},
          {Groups.delete(), &delete!/1},
          {Groups.get(), &fetch!/1},
          {Groups.insert(), &put_new!/1},
          {Groups.is_defined(), &has_key?/1},
          {Groups.take_largest(), &pop_largest!/1},
          {Groups.take_smallest(), &pop_smallest!/1},
          {Groups.update(), &replace!/1}
        ]
      end

      #############

      def alternate_put_new_and_delete!([tree | keys]) do
        alternate_put_new_and_delete!(tree, keys)
      end

      defp alternate_put_new_and_delete!(tree, [key_to_put, key_to_delete | next]) do
        tree = tree_put_new!(tree, key_to_put, :value)
        tree = tree_delete!(tree, key_to_delete)
        alternate_put_new_and_delete!(tree, next)
      end

      defp alternate_put_new_and_delete!(_, []) do
        :ok
      end

      #############

      def delete!([tree | keys]) do
        delete_recur!(tree, keys)
      end

      defp delete_recur!(tree, [key | next]) do
        tree = tree_delete!(tree, key)
        delete_recur!(tree, next)
      end

      defp delete_recur!(_, []) do
        :ok
      end

      #############

      def fetch!([tree | keys]) do
        fetch!(tree, keys)
      end

      defp fetch!(tree, [key | next]) do
        _value = tree_fetch!(tree, key)
        fetch!(tree, next)
      end

      defp fetch!(_, []) do
        :ok
      end

      #############

      def has_key?([set | keys]) do
        has_key?(set, keys)
      end

      defp has_key?(set, [key | next]) do
        _ = tree_has_key?(set, key)
        has_key?(set, next)
      end

      defp has_key?(_, []) do
        :ok
      end

      #############

      def pop_largest!([tree | amount]) do
        # assert amount <= tree_size(tree)
        pop_largest_recur!(tree, amount)
      end

      defp pop_largest_recur!(tree, amount) when amount > 0 do
        {_, _, tree} = tree_pop_largest!(tree)
        pop_largest_recur!(tree, amount - 1)
      end

      defp pop_largest_recur!(_, 0) do
        :ok
      end

      #############

      def pop_smallest!([tree | amount]) do
        # assert amount <= tree_size(tree)
        pop_smallest_recur!(tree, amount)
      end

      defp pop_smallest_recur!(tree, amount) when amount > 0 do
        {_, _, tree} = tree_pop_smallest!(tree)
        pop_smallest_recur!(tree, amount - 1)
      end

      defp pop_smallest_recur!(_, 0) do
        :ok
      end

      #############

      def put_new!([tree | keys]) do
        put_new!(tree, keys)
      end

      defp put_new!(tree, [key | next]) do
        tree = tree_put_new!(tree, key, :new_value)
        put_new!(tree, next)
      end

      defp put_new!(_, []) do
        :ok
      end

      ############## 

      def replace!([tree | keys]) do
        replace!(tree, keys)
      end

      defp replace!(tree, [key | next]) do
        tree = tree_replace!(tree, key, :update_value)
        replace!(tree, next)
      end

      defp replace!(_, []) do
        :ok
      end
    end
  end
end
