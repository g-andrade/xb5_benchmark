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

      def groups do
        [
          #Groups.delete_any_missing(&run_each_delete/1, impl_mod(), set_function_description(:delete)),
          #Groups.delete_existing(&run_each_delete!/1, impl_mod(), set_function_description(:delete!)),
          #Groups.delete_existing_batch(&run_batch_delete!/1, impl_mod(), set_function_description(:delete!)),
          #
          #{Groups.alternate_insert_and_delete(), &alternate_put_new_and_delete!/1},
          #{Groups.alternate_insert_smallest_and_take_largest(), &alternate_put_new_and_pop_largest!/1},
          #{Groups.alternate_insert_largest_and_take_smallest(), &alternate_put_new_and_pop_smallest!/1},
          #{Groups.delete(), &delete!/1},
          #{Groups.filter_all(), &filter/1},
          #{Groups.filter_none(), &filter/1},
          #{Groups.insert(), &put_new!/1},
          #{Groups.is_defined(), &member?/1},
          #{Groups.take_largest(), &pop_largest!/1},
          #{Groups.take_smallest(), &pop_smallest!/1}
        ]
      end

      #########################

#      def run_batch_delete!([set, keys | next]) do
#        _ = delete_all_recur!(set, keys)
#        run_batch_delete!(set, next)
#      end
#
#      def run_batch_delete!([]) do
#        :ok
#      end

      #

      defp delete_all_recur!(set, [key | next]) do
        set = set_delete!(set, key)
        delete_all_recur!(set, next)
      end

      defp delete_all_recur!(_set, []) do
        :ok
      end

      ###########################

      def run_each_delete([set, key | next]) do
        _set = set_delete(set, key)
        run_each_delete(next)
      end

      def run_each_delete([]) do
        :ok
      end

      #######################

      def run_each_delete!([set, key | next]) do
        _set = set_delete!(set, key)
        run_each_delete!(next)
      end

      def run_each_delete!([]) do
        :ok
      end
    end
  end
end
