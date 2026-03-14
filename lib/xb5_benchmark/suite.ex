defmodule Xb5Benchmark.Suite do
  ############## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    wrapper_mod = opts[:wrapper_mod]
    coll_mod = opts[:coll_mod]

    quote do
      use unquote(wrapper_mod), coll_mod: unquote(coll_mod)

      alias Xb5Benchmark.Groups

      @size_expanding_key_ops_amounts [300]
      @size_diminishing_key_ops_amounts [300]

      ####################################################

      def impl_mod(), do: unquote(coll_mod)

      ####################################################

      def run_each_add_many([coll, keys | next]) do
        _ = add_many_recur(coll, keys)
        run_each_add_many(next)
      end

      def run_each_add_many([]) do
        :ok
      end

      ##

      def add_many_recur(coll, [key | next]) do
        coll = coll_add(key, coll)
        add_many_recur(coll, next)
      end

      def add_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      def run_each_alt_takesmall_inslargest([coll, keys | next]) do
        _ = alt_takesmall_inslargest_recur(coll, keys)
        run_each_alt_takesmall_inslargest(next)
      end

      def run_each_alt_takesmall_inslargest([]) do
        :ok
      end

      ##

      def alt_takesmall_inslargest_recur(coll, [key | next]) do
        coll = coll_take_smallest_and_discard(coll)
        coll = coll_insert(key, coll)
        alt_takesmall_inslargest_recur(coll, next)
      end

      def alt_takesmall_inslargest_recur(_coll, []) do
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

      def delete_many_recur(coll, [key | next]) do
        coll = coll_delete(key, coll)
        delete_many_recur(coll, next)
      end

      def delete_many_recur(_coll, []) do
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

      def delete_any_many_recur(coll, [key | next]) do
        coll = coll_delete_any(key, coll)
        delete_any_many_recur(coll, next)
      end

      def delete_any_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_difference, 2}) do
        def run_each_difference([coll1, coll2 | next]) do
          _ = coll_difference(coll1, coll2)
          run_each_difference(next)
        end

        def run_each_difference([]) do
          :ok
        end
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

      if Module.defines?(__MODULE__, {:coll_filtermap_all, 1}) do
        def run_each_filtermap_all([coll | next]) do
          _ = coll_filtermap_all(coll)
          run_each_filtermap_all(next)
        end

        def run_each_filtermap_all([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_filtermap_all_mapped, 1}) do
        def run_each_filtermap_all_mapped([coll | next]) do
          _ = coll_filtermap_all_mapped(coll)
          run_each_filtermap_all_mapped(next)
        end

        def run_each_filtermap_all_mapped([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_filtermap_none, 1}) do
        def run_each_filtermap_none([coll | next]) do
          _ = coll_filtermap_none(coll)
          run_each_filtermap_none(next)
        end

        def run_each_filtermap_none([]) do
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

      if Module.defines?(__MODULE__, {:coll_from_list, 1}) do
        def run_each_from_list([list | next]) do
          _ = coll_from_list(list)
          run_each_from_list(next)
        end

        def run_each_from_list([]) do
          :ok
        end
      end

      ####################################################

      def run_each_from_ordsect_or_orddict([list | next]) do
        _ = coll_from_ordset_or_orddict(list)
        run_each_from_ordsect_or_orddict(next)
      end

      def run_each_from_ordsect_or_orddict([]) do
        :ok
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

        def get_many_recur(coll, [key | next]) do
          _ = coll_get(key, coll)
          get_many_recur(coll, next)
        end

        def get_many_recur(_coll, []) do
          :ok
        end
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

      def insert_many_recur(coll, [key | next]) do
        coll = coll_insert(key, coll)
        insert_many_recur(coll, next)
      end

      def insert_many_recur(_coll, []) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_intersection, 2}) do
        def run_each_intersection([coll1, coll2 | next]) do
          _ = coll_intersection(coll1, coll2)
          run_each_intersection(next)
        end

        def run_each_intersection([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_is_disjoint, 2}) do
        def run_each_is_disjoint([coll1, coll2 | next]) do
          _ = coll_is_disjoint(coll1, coll2)
          run_each_is_disjoint(next)
        end

        def run_each_is_disjoint([]) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_is_equal, 2}) do
        def run_each_is_equal([coll1, coll2 | next]) do
          _ = coll_is_equal(coll1, coll2)
          run_each_is_equal(next)
        end

        def run_each_is_equal([]) do
          :ok
        end
      end

      ####################################################

      def run_each_is_member_many([coll, keys | next]) do
        _ = is_member_recur(coll, keys)
        run_each_is_member_many(next)
      end

      def run_each_is_member_many([]) do
        :ok
      end

      ##

      def is_member_recur(coll, [key | next]) do
        _ = coll_is_member(key, coll)
        is_member_recur(coll, next)
      end

      def is_member_recur(_coll, []) do
        :ok
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_is_subset, 2}) do
        def run_each_is_subset([coll1, coll2 | next]) do
          _ = coll_is_subset(coll1, coll2)
          run_each_is_subset(next)
        end

        def run_each_is_subset([]) do
          :ok
        end
      end

      ####################################################

      def run_each_iterate([coll | next]) do
        iterate = iterate(coll)
        run_each_iterate(next)
      end

      def run_each_iterate([]) do
        :ok
      end

      ##

      def iterate(coll) do
        iterator = coll_iterator(coll)
        iterate_recur(iterator)
      end

      def iterate_recur(iterator) do
        case coll_next_and_discard(iterator) do
          :done ->
            :ok

          iterator ->
            iterate_recur(iterator)
        end
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

      def run_each_larger_many([coll, keys | next]) do
        larger_many_recur(coll, keys)
        run_each_larger_many(next)
      end

      def run_each_larger_many([]) do
        :ok
      end

      ##

      def larger_many_recur(coll, [key | next]) do
        _ = coll_larger(key, coll)
        larger_many_recur(coll, next)
      end

      def larger_many_recur(_coll, []) do
        :ok
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
        def run_each_lookup_many([coll, keys | next]) do
          _ = lookup_many_recur(coll, keys)
          run_each_lookup_many(next)
        end

        def run_each_lookup_many([]) do
          :ok
        end

        ##

        def lookup_many_recur(coll, [key | next]) do
          _ = coll_lookup(key, coll)
          lookup_many_recur(coll, next)
        end

        def lookup_many_recur(_coll, []) do
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

      if Module.defines?(__MODULE__, {:coll_nth, 2}) do
        def run_each_nth_many([coll, ranks | next]) do
          _ = nth_many_recur(coll, ranks)
          run_each_nth_many(next)
        end

        def run_each_nth_many([]) do
          :ok
        end

        ##

        def nth_many_recur(coll, [rank | next]) do
          _ = coll_nth(rank, coll)
          nth_many_recur(coll, next)
        end

        def nth_many_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_rank_and_discard, 2}) do
        def run_each_rank_many([coll, keys | next]) do
          _ = rank_many_recur(coll, keys)
          run_each_rank_many(next)
        end

        def run_each_rank_many([]) do
          :ok
        end

        ##

        def rank_many_recur(coll, [key | next]) do
          _ = coll_rank_and_discard(key, coll)
          rank_many_recur(coll, next)
        end

        def rank_many_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      def run_each_smaller_many([coll, keys | next]) do
        smaller_many_recur(coll, keys)
        run_each_smaller_many(next)
      end

      def run_each_smaller_many([]) do
        :ok
      end

      ##

      def smaller_many_recur(coll, [key | next]) do
        _ = coll_smaller(key, coll)
        smaller_many_recur(coll, next)
      end

      def smaller_many_recur(_coll, []) do
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

      if Module.defines?(__MODULE__, {:coll_take_and_discard, 2}) do
        def run_each_take_many([coll, keys | next]) do
          _ = take_recur(coll, keys)
          run_each_take_many(next)
        end

        def run_each_take_many([]) do
          :ok
        end

        ##

        def take_recur(coll, [key | keys]) do
          coll = coll_take_and_discard(key, coll)
          take_recur(coll, keys)
        end

        def take_recur(_coll, []) do
          :ok
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:coll_take_any_and_discard, 2}) do
        def run_each_take_any_many([coll, keys | next]) do
          _ = take_any_recur(coll, keys)
          run_each_take_any_many(next)
        end

        def run_each_take_any_many([]) do
          :ok
        end

        ##

        def take_any_recur(coll, [key | keys]) do
          coll = coll_take_any_and_discard(key, coll)
          take_any_recur(coll, keys)
        end

        def take_any_recur(_coll, []) do
          :ok
        end
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

      def take_largest_recur(coll, amount) when amount > 0 do
        coll = coll_take_largest_and_discard(coll)
        take_largest_recur(coll, amount - 1)
      end

      def take_largest_recur(_coll, 0) do
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

      def take_smallest_recur(coll, amount) when amount > 0 do
        coll = coll_take_smallest_and_discard(coll)
        take_smallest_recur(coll, amount - 1)
      end

      def take_smallest_recur(_coll, 0) do
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

      if Module.defines?(__MODULE__, {:coll_union, 2}) do
        def run_each_union([coll1, coll2 | next]) do
          _ = coll_union(coll1, coll2)
          run_each_union(next)
        end

        def run_each_union([]) do
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

        def update_many_recur(coll, [key | next]) do
          coll = coll_update(key, coll)
          update_many_recur(coll, next)
        end

        def update_many_recur(_coll, []) do
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

      if Module.defines?(__MODULE__, {:run_each_difference, 1}) do
        def groups_difference do
          Groups.difference(
            &run_each_difference/1,
            &coll_difference/2,
            impl_mod(),
            coll_api_name(:difference)
          )
        end
      else
        def groups_difference, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filter_all, 1}) do
        def group_filter_all,
          do:
            Groups.filter_all(
              &run_each_filter_all/1,
              &coll_filter_all/1,
              impl_mod(),
              coll_api_name(:filter)
            )
      else
        def group_filter_all, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filter_none, 1}) do
        def group_filter_none,
          do:
            Groups.filter_none(
              &run_each_filter_none/1,
              &coll_filter_none/1,
              impl_mod(),
              coll_api_name(:filter)
            )
      else
        def group_filter_none, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filtermap_all, 1}) do
        def group_filtermap_all,
          do:
            Groups.filtermap_all(
              &run_each_filtermap_all/1,
              &coll_filtermap_all/1,
              impl_mod(),
              coll_api_name(:filtermap)
            )
      else
        def group_filtermap_all, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filtermap_all_mapped, 1}) do
        def group_filtermap_all_mapped,
          do:
            Groups.filtermap_all_mapped(
              &run_each_filtermap_all_mapped/1,
              &coll_filtermap_all_mapped/1,
              impl_mod(),
              coll_api_name(:filtermap)
            )
      else
        def group_filtermap_all_mapped, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_filtermap_none, 1}) do
        def group_filtermap_none,
          do:
            Groups.filtermap_none(
              &run_each_filtermap_none/1,
              &coll_filtermap_none/1,
              impl_mod(),
              coll_api_name(:filtermap)
            )
      else
        def group_filtermap_none, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_foldl, 1}) do
        def group_foldl do
          Groups.foldl(
            &run_each_foldl/1,
            &coll_foldl/1,
            impl_mod(),
            coll_api_name(:foldl)
          )
        end
      else
        def group_foldl, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_from_list, 1}) do
        def group_from_list,
          do:
            Groups.from_list(
              &run_each_from_list/1,
              &coll_from_list/1,
              impl_mod(),
              coll_api_name(:from_list)
            )
      else
        def group_from_list, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_get_many, 1}) do
        def group_get_x100,
          do:
            Groups.get_x100(
              &run_each_get_many/1,
              &get_many_recur/2,
              impl_mod(),
              coll_api_name(:get)
            )
      else
        def group_get_x100, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_intersection, 1}) do
        def groups_intersection do
          Groups.intersection(
            &run_each_intersection/1,
            &coll_intersection/2,
            impl_mod(),
            coll_api_name(:intersection)
          )
        end
      else
        def groups_intersection, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_is_disjoint, 1}) do
        def groups_is_disjoint do
          Groups.is_disjoint(
            &run_each_is_disjoint/1,
            &coll_is_disjoint/2,
            impl_mod(),
            coll_api_name(:is_disjoint)
          )
        end
      else
        def groups_is_disjoint, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_is_equal, 1}) do
        def groups_is_equal do
          Groups.is_equal(
            &run_each_is_equal/1,
            &coll_is_equal/2,
            impl_mod(),
            coll_api_name(:is_equal)
          )
        end
      else
        def groups_is_equal, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_is_subset, 1}) do
        def groups_is_subset do
          Groups.is_subset(
            &run_each_is_subset/1,
            &coll_is_subset/2,
            impl_mod(),
            coll_api_name(:is_subset)
          )
        end
      else
        def groups_is_subset, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_keys, 1}) do
        def group_keys,
          do: Groups.keys(&run_each_keys/1, &coll_keys/1, impl_mod(), coll_api_name(:keys))
      else
        def group_keys, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_lookup_many, 1}) do
        def groups_lookup_many do
          [
            Groups.lookup_existing_x100(
              &run_each_lookup_many/1,
              &lookup_many_recur/2,
              impl_mod(),
              coll_api_name(:lookup)
            ),
            Groups.lookup_missing_x100(
              &run_each_lookup_many/1,
              &lookup_many_recur/2,
              impl_mod(),
              coll_api_name(:lookup)
            )
          ]
        end
      else
        def groups_lookup_many do
          []
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_nth_many, 1}) do
        def groups_nth do
          [
            Groups.nth_x100(
              &run_each_nth_many/1,
              &nth_many_recur/2,
              impl_mod(),
              coll_api_name(:nth)
            )
          ]
        end
      else
        def groups_nth do
          []
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_rank_many, 1}) do
        def groups_rank do
          [
            Groups.rank_existing_x100(
              &run_each_rank_many/1,
              &rank_many_recur/2,
              impl_mod(),
              coll_api_name(:rank)
            )
          ]
        end
      else
        def groups_rank do
          []
        end
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_take_many, 1}) do
        def groups_take_many do
          size_changing_key_ops_groups(
            &Groups.take_many/5,
            &run_each_take_many/1,
            &take_recur/2,
            impl_mod(),
            coll_api_name(:take)
          )
        end
      else
        def groups_take_many, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_take_any_many, 1}) do
        def group_take_any_missing_x100,
          do:
            Groups.take_any_missing_x100(
              &run_each_take_any_many/1,
              &take_any_recur/2,
              impl_mod(),
              coll_api_name(:take_any)
            )
      else
        def group_take_any_missing_x100, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_union, 1}) do
        def groups_union do
          Groups.union(&run_each_union/1, &coll_union/2, impl_mod(), coll_api_name(:union))
        end
      else
        def groups_union, do: []
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_update_many, 1}) do
        def group_update_x100,
          do:
            Groups.update_x100(
              &run_each_update_many/1,
              &update_many_recur/2,
              impl_mod(),
              coll_api_name(:update)
            )
      else
        def group_update_x100, do: nil
      end

      ####################################################

      if Module.defines?(__MODULE__, {:run_each_values, 1}) do
        def group_values,
          do:
            Groups.values(&run_each_values/1, &coll_values/1, impl_mod(), coll_api_name(:values))
      else
        def group_values, do: nil
      end

      ####################################################

      def groups() do
        [
          size_changing_key_ops_groups(
            &Groups.add_new_many/5,
            &run_each_add_many/1,
            &add_many_recur/2,
            impl_mod(),
            coll_api_name(:add),
            size_expanding: true
          ),
          ##
          Groups.add_existing_x100(
            &run_each_add_many/1,
            &add_many_recur/2,
            impl_mod(),
            coll_api_name(:add)
          ),
          ##
          size_changing_key_ops_groups(
            &Groups.alternatively_take_smallest_and_insert_largest/5,
            &run_each_alt_takesmall_inslargest/1,
            &alt_takesmall_inslargest_recur/2,
            impl_mod(),
            "#{coll_api_name(:take_smallest)} + #{coll_api_name(:insert)}"
          ),
          ##
          size_changing_key_ops_groups(
            &Groups.delete_many/5,
            &run_each_delete_many/1,
            &delete_many_recur/2,
            impl_mod(),
            coll_api_name(:delete)
          ),
          ##
          Groups.delete_any_missing_x100(
            &run_each_delete_any_many/1,
            &delete_any_many_recur/2,
            impl_mod(),
            coll_api_name(:delete_any)
          ),
          ##
          groups_difference(),
          group_filter_all(),
          group_filter_none(),
          group_filtermap_all(),
          group_filtermap_all_mapped(),
          group_filtermap_none(),
          group_foldl(),
          group_from_list(),
          ##
          Groups.from_ordset_or_orddict(
            &run_each_from_ordsect_or_orddict/1,
            &coll_from_ordset_or_orddict/1,
            impl_mod(),
            coll_api_name(:from_ordset_or_orddict)
          ),
          ##
          group_get_x100(),
          ##
          size_changing_key_ops_groups(
            &Groups.insert_many/5,
            &run_each_insert_many/1,
            &insert_many_recur/2,
            impl_mod(),
            coll_api_name(:insert),
            size_expanding: true
          ),
          ##
          groups_intersection(),
          ##
          Groups.iterate(
            &run_each_iterate/1,
            &iterate/1,
            impl_mod(),
            coll_api_name(:next)
          ),
          ##
          groups_is_disjoint(),
          ##
          groups_is_equal(),
          ##
          Groups.is_member_existing_x100(
            &run_each_is_member_many/1,
            &is_member_recur/2,
            impl_mod(),
            coll_api_name(:is_member)
          ),
          ##
          Groups.is_member_missing_x100(
            &run_each_is_member_many/1,
            &is_member_recur/2,
            impl_mod(),
            coll_api_name(:is_member)
          ),
          ##
          groups_is_subset(),
          ##
          group_keys(),
          ##
          Groups.larger_x100(
            &run_each_larger_many/1,
            &larger_many_recur/2,
            impl_mod(),
            coll_api_name(:larger)
          ),
          ##
          Groups.largest(
            &run_each_largest/1,
            &coll_largest/1,
            impl_mod(),
            coll_api_name(:largest)
          ),
          ##
          groups_lookup_many(),
          ##
          Groups.map(
            &run_each_map/1,
            &coll_map/1,
            impl_mod(),
            coll_api_name(:map)
          ),
          ##
          groups_nth(),
          groups_rank(),
          ##
          Groups.smaller_x100(
            &run_each_smaller_many/1,
            &smaller_many_recur/2,
            impl_mod(),
            coll_api_name(:smaller)
          ),
          ##
          Groups.smallest(
            &run_each_smallest/1,
            &coll_smallest/1,
            impl_mod(),
            coll_api_name(:smallest)
          ),
          ##
          groups_take_many(),
          group_take_any_missing_x100(),
          ##
          size_changing_key_ops_groups(
            &Groups.take_largest_many/5,
            &run_each_take_largest_many/1,
            &take_largest_recur/2,
            impl_mod(),
            coll_api_name(:take_largest)
          ),
          ##
          size_changing_key_ops_groups(
            &Groups.take_smallest_many/5,
            &run_each_take_smallest_many/1,
            &take_smallest_recur/2,
            impl_mod(),
            coll_api_name(:take_smallest)
          ),
          ##
          Groups.to_list(
            &run_each_to_list/1,
            &coll_to_list/1,
            impl_mod(),
            coll_api_name(:to_list)
          ),
          ##
          groups_union(),
          group_update_x100(),
          group_values()
        ]
        |> List.flatten()
        |> Enum.filter(&(&1 !== nil))
      end

      ###############

      def size_changing_key_ops_groups(
            group_fun,
            suite_fun,
            iteration_fun,
            impl_mod,
            impl_description,
            opts \\ []
          ) do
        amounts =
          if opts[:size_expanding] do
            @size_expanding_key_ops_amounts
          else
            @size_diminishing_key_ops_amounts
          end

        ##
        Enum.map(amounts, &group_fun.(&1, suite_fun, iteration_fun, impl_mod, impl_description))
      end
    end
  end
end
