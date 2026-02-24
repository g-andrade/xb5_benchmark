defmodule Xb5Benchmark.Suite do
  ############## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    wrapper_mod = opts[:wrapper_mod]
    coll_mod = opts[:coll_mod]

    quote do
      use unquote(wrapper_mod), coll_mod: unquote(coll_mod)

      alias Xb5Benchmark.Groups

      def impl_mod(), do: unquote(coll_mod)

      ####################################################

      def run_each_add([coll, key | next]) do
        _ = coll_add(key, coll)
        run_each_add(next)
      end

      def run_each_add([]) do
        :ok
      end

      ####################################################

      def run_each_add_many([coll, keys | next]) do
        _ = add_many_recur(coll, keys)
        run_each_add_many(next)
      end

      def run_each_add_many([]) do
        :ok
      end

      ##

      defp add_many_recur(coll, [key | next]) do
        coll = coll_add(key, coll)
        add_many_recur(coll, next)
      end

      defp add_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      def run_each_delete([coll, key | next]) do
        _ = coll_delete(key, coll)
        run_each_delete(next)
      end

      def run_each_delete([]) do
        :ok
      end

      ####################################################

      def run_each_delete_many([coll, keys | next]) do
        _ = delete_many_recur(coll, keys)
        run_each_delete_many(next)
      end

      def run_each_delete_many([]) do
        :ok
      end

      ##

      defp delete_many_recur(coll, [key | next]) do
        coll = coll_delete(key, coll)
        delete_many_recur(coll, next)
      end

      defp delete_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      def run_each_delete_any([coll, key | next]) do
        _ = coll_delete_any(key, coll)
        run_each_delete_any(next)
      end

      def run_each_delete_any([]) do
        :ok
      end

      ####################################################

      def run_each_delete_any_many([coll, keys | next]) do
        _ = delete_any_many_recur(coll, keys)
        run_each_delete_any_many(next)
      end

      def run_each_delete_any_many([]) do
        :ok
      end

      ##

      defp delete_any_many_recur(coll, [key | next]) do
        coll = coll_delete_any(key, coll)
        delete_any_many_recur(coll, next)
      end

      defp delete_any_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_filter_all, 1}) do
        def run_each_filter_all([coll | next]) do
          _ = coll_filter_all(coll)
          run_each_filter_all(next)
        end

        def run_each_filter_all([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_filter_none, 1}) do
        def run_each_filter_none([coll | next]) do
          _ = coll_filter_none(coll)
          run_each_filter_none(next)
        end

        def run_each_filter_none([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_foldl, 1}) do
        def run_each_foldl([coll | next]) do
          _ = coll_foldl(coll)
          run_each_foldl(next)
        end

        def run_each_foldl([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_get, 2}) do
        def run_each_get([coll, key | next]) do
          _ = coll_get(key, coll)
          run_each_get(next)
        end

        def run_each_get([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_get, 2}) do
        def run_each_get_many([coll, keys | next]) do
          get_many_recur(coll, keys)
          run_each_get_many(next)
        end

        def run_each_get_many([]) do
          :ok
        end

        ###

        defp get_many_recur(coll, [key | next]) do
          _ = coll_get(key, coll)
          get_many_recur(coll, next)
        end

        defp get_many_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      def run_each_insert([coll, key | next]) do
        _ = coll_insert(key, coll)
        run_each_insert(next)
      end

      def run_each_insert([]) do
        :ok
      end

      ####################################################

      def run_each_insert_many([coll, keys | next]) do
        _ = insert_many_recur(coll, keys)
        run_each_insert_many(next)
      end

      def run_each_insert_many([]) do
        :ok
      end

      ##

      defp insert_many_recur(coll, [key | next]) do
        coll = coll_insert(key, coll)
        insert_many_recur(coll, next)
      end

      defp insert_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      def run_each_iterate([coll | next]) do
        iterator = coll_iterator(coll)
        _ = iterate_recur(iterator)
        run_each_iterate(next)
      end

      def run_each_iterate([]) do
        :ok
      end

      ##

      defp iterate_recur(iterator) do
        case coll_next_and_discard(iterator) do
          :done ->
            :ok

          iterator ->
            iterate_recur(iterator)
        end
      end

      ####################################################

      def run_each_is_member([coll, key | next]) do
        _ = coll_is_member(key, coll)
        run_each_is_member(next)
      end

      def run_each_is_member([]) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_keys, 1}) do
        def run_each_keys([coll | next]) do
          _ = coll_keys(coll)
          run_each_keys(next)
        end

        def run_each_keys([]) do
          :ok
        end
      end

      ####################################################

      def run_each_largest([coll | next]) do
        _ = coll_largest(coll)
        run_each_largest(next)
      end

      def run_each_largest([]) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_lookup, 2}) do
        def run_each_lookup([coll, key | next]) do
          _ = coll_lookup(key, coll)
          run_each_lookup(next)
        end

        def run_each_lookup([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_lookup, 2}) do
        def run_each_lookup_many([coll, keys | next]) do
          _ = lookup_many_recur(coll, keys)
          run_each_lookup_many(next)
        end

        def run_each_lookup_many([]) do
          :ok
        end

        ##

        defp lookup_many_recur(coll, [key | next]) do
          _ = coll_lookup(key, coll)
          lookup_many_recur(coll, next)
        end

        defp lookup_many_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      def run_each_map([coll | next]) do
        _ = coll_map(coll)
        run_each_map(next)
      end

      def run_each_map([]) do
        :ok
      end

      ####################################################

      def run_each_smallest([coll | next]) do
        _ = coll_smallest(coll)
        run_each_smallest(next)
      end

      def run_each_smallest([]) do
        :ok
      end

      ####################################################

      def run_each_take_largest([coll | next]) do
        _ = coll_take_largest_and_discard(coll)
        run_each_take_largest(next)
      end

      def run_each_take_largest([]) do
        :ok
      end

      ####################################################

      def run_each_take_largest_many([coll, amount | next]) do
        _ = take_largest_recur(coll, amount)
        run_each_take_largest_many(next)
      end

      def run_each_take_largest_many([]) do
        :ok
      end

      ##

      defp take_largest_recur(coll, amount) when amount > 0 do
        coll = coll_take_largest_and_discard(coll)
        take_largest_recur(coll, amount - 1)
      end

      defp take_largest_recur(_coll, 0) do
        :ok
      end

      ####################################################

      def run_each_take_smallest([coll | next]) do
        _ = coll_take_smallest_and_discard(coll)
        run_each_take_smallest(next)
      end

      def run_each_take_smallest([]) do
        :ok
      end

      ####################################################

      def run_each_take_smallest_many([coll, amount | next]) do
        _ = take_smallest_recur(coll, amount)
        run_each_take_smallest_many(next)
      end

      def run_each_take_smallest_many([]) do
        :ok
      end

      ##

      defp take_smallest_recur(coll, amount) when amount > 0 do
        coll = coll_take_smallest_and_discard(coll)
        take_smallest_recur(coll, amount - 1)
      end

      defp take_smallest_recur(_coll, 0) do
        :ok
      end

      ####################################################

      def run_each_to_list([coll | next]) do
        _ = coll_to_list(coll)
        run_each_to_list(next)
      end

      def run_each_to_list([]) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_update, 2}) do
        def run_each_update([coll, key | next]) do
          _ = coll_update(key, coll)
            run_each_update(next)
        end

        def run_each_update([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_update, 2}) do
        def run_each_update_many([coll, keys | next]) do
          _ = update_many_recur(coll, keys)
            run_each_update_many(next)
        end

        def run_each_update_many([]) do
          :ok
        end

        ##

        defp update_many_recur(coll, [key | next]) do
          coll = coll_update(key, coll)
          update_many_recur(coll, next)
        end

        defp update_many_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_values, 1}) do
        def run_each_values([coll | next]) do
          _ = coll_values(coll)
          run_each_values(next)
        end

        def run_each_values([]) do
          :ok
        end
      end

      ####################################################
      ####################################################
      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filter_all, 1}) do
        def group_filter_all, do: Groups.filter_all(&__MODULE__.run_each_filter_all/1, impl_mod(), coll_api_name(:filter))
      else
        def group_filter_all, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filter_none, 1}) do
        def group_filter_none, do: Groups.filter_none(&__MODULE__.run_each_filter_none/1, impl_mod(), coll_api_name(:filter))
      else
        def group_filter_none, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_foldl, 1}) do
        def group_foldl, do: Groups.foldl(&__MODULE__.run_each_foldl/1, impl_mod(), coll_api_name(:foldl))
      else
        def group_foldl, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_from_list, 1}) do
        def group_from_list, do: Groups.filter_none(&__MODULE__.run_each_from_list/1, impl_mod(), coll_api_name(:from_list))
      else
        def group_from_list, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_get, 1}) do
        def group_get, do: Groups.get(&__MODULE__.run_each_get/1, impl_mod(), coll_api_name(:get))
      else
        def group_get, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_get_many, 1}) do
        def group_get_x100, do: Groups.get_x100(&__MODULE__.run_each_get_many/1, impl_mod(), coll_api_name(:get))
      else
        def group_get_x100, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_keys, 1}) do
        def group_keys, do: Groups.keys(&__MODULE__.run_each_keys/1, impl_mod(), coll_api_name(:keys))
      else
        def group_keys, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_lookup, 1}) do
        def groups_lookup do
          [
            Groups.lookup_existing(&__MODULE__.run_each_lookup/1, impl_mod(), coll_api_name(:lookup)),
            Groups.lookup_missing(&__MODULE__.run_each_lookup/1, impl_mod(), coll_api_name(:lookup))
          ]
        end
      else
        def groups_lookup do
          []
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_lookup_many, 1}) do
        def groups_lookup_many do
          [
            Groups.lookup_existing_x100(&__MODULE__.run_each_lookup_many/1, impl_mod(), coll_api_name(:lookup)),
            Groups.lookup_missing_x100(&__MODULE__.run_each_lookup_many/1, impl_mod(), coll_api_name(:lookup))
          ]
        end
      else
        def groups_lookup_many do
          []
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_update, 1}) do
        def group_update, do: Groups.update(&__MODULE__.run_each_update/1, impl_mod(), coll_api_name(:update))
      else
        def group_update, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_update_many, 1}) do
        def group_update_x100, do: Groups.update_x100(&__MODULE__.run_each_update_many/1, impl_mod(), coll_api_name(:update))
      else
        def group_update_x100, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_values, 1}) do
        def group_values, do: Groups.values(&__MODULE__.run_each_values/1, impl_mod(), coll_api_name(:values))
      else
        def group_values, do: nil
      end

      ####################################################

      def groups() do
        [
          Groups.add_new(&__MODULE__.run_each_add/1, impl_mod(), coll_api_name(:add)),
          Groups.add_new_x100(&__MODULE__.run_each_add_many/1, impl_mod(), coll_api_name(:add)),
          Groups.add_existing(&__MODULE__.run_each_add/1, impl_mod(), coll_api_name(:add)),
          Groups.add_existing_x100(&__MODULE__.run_each_add_many/1, impl_mod(), coll_api_name(:add)),
          Groups.delete(&__MODULE__.run_each_delete/1, impl_mod(), coll_api_name(:delete)),
          Groups.delete_x100(&__MODULE__.run_each_delete_many/1, impl_mod(), coll_api_name(:delete)),
          Groups.delete_any_missing(&__MODULE__.run_each_delete_any/1, impl_mod(), coll_api_name(:delete_any)),
          Groups.delete_any_missing_x100(&__MODULE__.run_each_delete_any_many/1, impl_mod(), coll_api_name(:delete_any)),
          group_filter_all(),
          group_filter_none(),
          group_foldl(),
          group_from_list(),
          group_get(),
          group_get_x100(),
          Groups.insert(&__MODULE__.run_each_insert/1, impl_mod(), coll_api_name(:insert)),
          Groups.insert_x100(&__MODULE__.run_each_insert_many/1, impl_mod(), coll_api_name(:insert)),
          Groups.iterate(&__MODULE__.run_each_iterate/1, impl_mod(), coll_api_name(:next)),
          Groups.is_member_existing(&__MODULE__.run_each_is_member/1, impl_mod(), coll_api_name(:is_member)),
          Groups.is_member_missing(&__MODULE__.run_each_is_member/1, impl_mod(), coll_api_name(:is_member)),
          group_keys(),
          Groups.largest(&__MODULE__.run_each_largest/1, impl_mod(), coll_api_name(:largest)),
          groups_lookup(),
          groups_lookup_many(),
          Groups.map(&__MODULE__.run_each_map/1, impl_mod(), coll_api_name(:map)),
          Groups.smallest(&__MODULE__.run_each_smallest/1, impl_mod(), coll_api_name(:smallest)),
          Groups.take_largest(&__MODULE__.run_each_take_largest/1, impl_mod(), coll_api_name(:take_largest)),
          Groups.take_largest_x100(&__MODULE__.run_each_take_largest_many/1, impl_mod(), coll_api_name(:take_largest)),
          Groups.take_smallest(&__MODULE__.run_each_take_smallest/1, impl_mod(), coll_api_name(:take_smallest)),
          Groups.take_smallest_x100(&__MODULE__.run_each_take_smallest_many/1, impl_mod(), coll_api_name(:take_smallest)),
          Groups.to_list(&__MODULE__.run_each_to_list/1, impl_mod(), coll_api_name(:to_list)),
          group_update(),
          group_update_x100(),
          group_values()
        ]
        |> List.flatten()
        |> Enum.filter(&(&1 !== nil))
      end

    end
  end
end
