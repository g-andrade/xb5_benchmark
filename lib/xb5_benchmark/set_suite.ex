defmodule Xb5Benchmark.SetSuite do
  ############## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    set_mod = opts[:set_mod]
    wrapper_mod = opts[:wrapper_mod]

    quote do
      use unquote(wrapper_mod), set_mod: unquote(set_mod)

      alias Xb5Benchmark.Groups

      ############

      def impl_mod, do: unquote(set_mod)

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
          {Groups.take_largest(), &pop_largest!/1},
          {Groups.take_smallest(), &pop_smallest!/1}
        ]
      end

      #############

      def alternate_put_new_and_delete!([set | keys]) do
        alternate_put_new_and_delete!(set, keys)
      end

      defp alternate_put_new_and_delete!(set, [key_to_put, key_to_delete | next]) do
        set = set_put_new!(set, key_to_put)
        set = set_delete!(set, key_to_delete)
        alternate_put_new_and_delete!(set, next)
      end

      defp alternate_put_new_and_delete!(_, []) do
        :ok
      end

      #############

      def alternate_put_new_and_pop_largest!([set | keys]) do
        alternate_put_new_and_pop_largest!(set, keys)
      end

      defp alternate_put_new_and_pop_largest!(set, [key_to_put | next]) do
        set = set_put_new!(set, key_to_put)
        {_, set} = set_pop_largest!(set)
        alternate_put_new_and_pop_largest!(set, next)
      end

      defp alternate_put_new_and_pop_largest!(_set, []) do
        :ok
      end

      #############

      def alternate_put_new_and_pop_smallest!([set | keys]) do
        alternate_put_new_and_pop_smallest!(set, keys)
      end

      defp alternate_put_new_and_pop_smallest!(set, [key_to_put | next]) do
        set = set_put_new!(set, key_to_put)
        {_, set} = set_pop_smallest!(set)
        alternate_put_new_and_pop_smallest!(set, next)
      end

      defp alternate_put_new_and_pop_smallest!(_set, []) do
        :ok
      end

      #############

      def delete!([set | keys]) do
        delete_recur!(set, keys)
      end

      defp delete_recur!(set, [key | next]) do
        set = set_delete!(set, key)
        delete_recur!(set, next)
      end

      defp delete_recur!(_, []) do
        :ok
      end

      #############

      def filter([set | amount]) do
        case amount do
          :all ->
            _ = set_filter(set, fn _ -> true end)

          :none ->
            _ = set_filter(set, fn _ -> false end)
        end
      end

      #############

      def member?([set | keys]) do
        member?(set, keys)
      end

      defp member?(set, [key | next]) do
        _ = set_member?(set, key)
        member?(set, next)
      end

      defp member?(_, []) do
        :ok
      end

      #############

      def pop_largest!([set | amount]) do
        # assert amount <= set_size(set)
        pop_largest_recur!(set, amount)
      end

      defp pop_largest_recur!(set, amount) when amount > 0 do
        {_, set} = set_pop_largest!(set)
        pop_largest_recur!(set, amount - 1)
      end

      defp pop_largest_recur!(_, 0) do
        :ok
      end

      #############

      def pop_smallest!([set | amount]) do
        # assert amount <= set_size(set)
        pop_smallest_recur!(set, amount)
      end

      defp pop_smallest_recur!(set, amount) when amount > 0 do
        {_, set} = set_pop_smallest!(set)
        pop_smallest_recur!(set, amount - 1)
      end

      defp pop_smallest_recur!(_, 0) do
        :ok
      end

      #############

      def put_new!([set | keys]) do
        put_new!(set, keys)
      end

      defp put_new!(set, [key | next]) do
        set = set_put_new!(set, key)
        put_new!(set, next)
      end

      defp put_new!(_, []) do
        :ok
      end
    end
  end
end
