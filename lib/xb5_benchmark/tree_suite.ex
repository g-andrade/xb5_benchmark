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

      # Cases yet to benchmark:
      # - alternate insert and take
      # - delete_any [non-existent keys]
      # - enter [existing keys]
      # - enter [non-existing keys]
      # - from_list
      # - from_orddict
      # - iterate
      # - iterate from middle key
      # - keys
      # - larger [existing keys]
      # - larger [non-existing keys]
      # - largest?
      # - map
      # - smaller [existing keys]
      # - smaller [non-existing keys]
      # - take_largest (x N)
      # - take_smallest (x N)
      # - to_list
      # - update [existing keys]
      # - values

      def groups do
        [
          #Groups.delete_any_non_existing(&run_each_delete/1, impl_mod(), tree_function_description(:delete)),
          #Groups.delete_existing(&run_each_delete!/1, impl_mod(), tree_function_description(:delete!)),
          #Groups.delete_all(&run_delete_all!/1, impl_mod(), tree_function_description(:delete!))
          #
          #{Groups.alternate_insert_and_delete(), &alternate_put_new_and_delete!/1},
          #{Groups.alternate_insert_largest_and_take_smallest(), &alternate_put_new_and_pop_smallest!/1},
          #{Groups.alternate_insert_smallest_and_take_largest(), &alternate_put_new_and_pop_largest!/1},
          #{Groups.delete(), &delete!/1},
          #{Groups.get(), &fetch!/1},
          #{Groups.insert(), &put_new!/1},
          #{Groups.is_defined(), &has_key?/1},
          #{Groups.take_largest(), &pop_largest!/1},
          #{Groups.take_smallest(), &pop_smallest!/1},
          #{Groups.update(), &replace!/1}
        ]
      end

      ###

      def run_each_delete([tree, key | next]) do
        _tree = tree_delete(tree, key)
        run_each_delete(next)
      end

      def run_each_delete([]) do
        :ok
      end

      ###

      def run_each_delete!([tree, key | next]) do
        _tree = tree_delete!(tree, key)
        run_each_delete!(next)
      end

      def run_each_delete!([]) do
        :ok
      end
    end
  end
end
