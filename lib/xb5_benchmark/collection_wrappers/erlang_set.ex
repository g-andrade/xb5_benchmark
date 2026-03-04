defmodule Xb5Benchmark.CollectionWrappers.ErlangSet do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    coll_mod = opts[:coll_mod]

    quote do
      @behaviour Xb5Benchmark.CollectionWrapper

      @impl true
      defdelegate coll_add(element, set), to: unquote(coll_mod), as: :add

      @impl true
      defdelegate coll_delete(element, set), to: unquote(coll_mod), as: :delete

      @impl true
      defdelegate coll_delete_any(element, set), to: unquote(coll_mod), as: :delete_any

      @impl true
      defdelegate coll_difference(set1, set2), to: unquote(coll_mod), as: :difference

      @impl true
      @compile {:inline, coll_filter_all: 1}
      def coll_filter_all(set) do
        unquote(coll_mod).filter(&coll_fun_filter_all/1, set)
      end

      @impl true
      @compile {:inline, coll_filter_none: 1}
      def coll_filter_none(set) do
        unquote(coll_mod).filter(&coll_fun_filter_none/1, set)
      end

      @impl true
      @compile {:inline, coll_filtermap_all: 1}
      def coll_filtermap_all(set) do
        unquote(coll_mod).filtermap(&coll_fun_filter_all/1, set)
      end

      @impl true
      @compile {:inline, coll_filtermap_all_mapped: 1}
      def coll_filtermap_all_mapped(bag) do
        unquote(coll_mod).filtermap(&coll_fun_filtermap_all_mapped/1, bag)
      end

      @impl true
      @compile {:inline, coll_filtermap_none: 1}
      def coll_filtermap_none(set) do
        unquote(coll_mod).filtermap(&coll_fun_filter_none/1, set)
      end

      @impl true
      @compile {:inline, coll_foldl: 1}
      def coll_foldl(set) do
        unquote(coll_mod).fold(&coll_fun_fold_return_acc/2, :ok, set)
      end

      @impl true
      defdelegate coll_from_list(set), to: unquote(coll_mod), as: :from_list

      @impl true
      defdelegate coll_from_ordset_or_orddict(set), to: unquote(coll_mod), as: :from_ordset

      @impl true
      defdelegate coll_insert(element, set), to: unquote(coll_mod), as: :insert

      @impl true
      defdelegate coll_intersection(set1, set2), to: unquote(coll_mod), as: :intersection

      @impl true
      defdelegate coll_is_disjoint(set1, set2), to: unquote(coll_mod), as: :is_disjoint

      @impl true
      defdelegate coll_is_equal(set1, set2), to: unquote(coll_mod), as: :is_equal

      @impl true
      defdelegate coll_is_member(element, set), to: unquote(coll_mod), as: :is_member

      @impl true
      defdelegate coll_is_subset(element, set), to: unquote(coll_mod), as: :is_subset

      @impl true
      defdelegate coll_iterator(set), to: unquote(coll_mod), as: :iterator

      @impl true
      defdelegate coll_larger(element, set), to: unquote(coll_mod), as: :larger

      @impl true
      defdelegate coll_largest(set), to: unquote(coll_mod), as: :largest

      @impl true
      @compile {:inline, coll_map: 1}
      def coll_map(set) do
        unquote(coll_mod).map(&coll_fun_map_identity/1, set)
      end

      @impl true
      @compile {:inline, coll_next_and_discard: 1}
      def coll_next_and_discard(iterator) do
        case unquote(coll_mod).next(iterator) do
          {_, iterator} ->
            iterator

          :none ->
            :done
        end
      end

      @impl true
      defdelegate coll_smaller(element, set), to: unquote(coll_mod), as: :smaller

      @impl true
      defdelegate coll_smallest(set), to: unquote(coll_mod), as: :smallest

      @impl true
      @compile {:inline, coll_take_largest_and_discard: 1}
      def coll_take_largest_and_discard(set) do
        {_element, set} = unquote(coll_mod).take_largest(set)
        set
      end

      @impl true
      @compile {:inline, coll_take_smallest_and_discard: 1}
      def coll_take_smallest_and_discard(set) do
        {_element, set} = unquote(coll_mod).take_smallest(set)
        set
      end

      @impl true
      defdelegate coll_to_list(set), to: unquote(coll_mod), as: :to_list

      @impl true
      defdelegate coll_union(set1, set2), to: unquote(coll_mod), as: :union

      ################

      @impl true
      def coll_api_name(:add), do: ":#{unquote(coll_mod)}.add/2"
      def coll_api_name(:delete), do: ":#{unquote(coll_mod)}.delete/2"
      def coll_api_name(:delete_any), do: ":#{unquote(coll_mod)}.delete_any/2"
      def coll_api_name(:difference), do: ":#{unquote(coll_mod)}.difference/2"
      def coll_api_name(:filter), do: ":#{unquote(coll_mod)}.filter/2"
      def coll_api_name(:filtermap), do: ":#{unquote(coll_mod)}.filtermap/2"
      def coll_api_name(:foldl), do: ":#{unquote(coll_mod)}.fold/3"
      def coll_api_name(:from_list), do: ":#{unquote(coll_mod)}.from_list/1"
      def coll_api_name(:from_ordset_or_orddict), do: ":#{unquote(coll_mod)}.from_ordset/1"
      def coll_api_name(:insert), do: ":#{unquote(coll_mod)}.insert/2"
      def coll_api_name(:intersection), do: ":#{unquote(coll_mod)}.intersection/2"
      def coll_api_name(:is_disjoint), do: ":#{unquote(coll_mod)}.is_disjoint/2"
      def coll_api_name(:is_equal), do: ":#{unquote(coll_mod)}.is_equal/2"
      def coll_api_name(:is_member), do: ":#{unquote(coll_mod)}.is_member/2"
      def coll_api_name(:is_subset), do: ":#{unquote(coll_mod)}.is_subset/2"
      def coll_api_name(:iterator), do: ":#{unquote(coll_mod)}.iterator/1"
      def coll_api_name(:larger), do: ":#{unquote(coll_mod)}.larger/2"
      def coll_api_name(:largest), do: ":#{unquote(coll_mod)}.largest/1"
      def coll_api_name(:map), do: ":#{unquote(coll_mod)}.map/2"
      def coll_api_name(:next), do: "iterate :#{unquote(coll_mod)}"
      def coll_api_name(:smaller), do: ":#{unquote(coll_mod)}.smaller/2"
      def coll_api_name(:smallest), do: ":#{unquote(coll_mod)}.smallest/1"
      def coll_api_name(:take_largest), do: ":#{unquote(coll_mod)}.take_largest/1"
      def coll_api_name(:take_smallest), do: ":#{unquote(coll_mod)}.take_smallest/1"
      def coll_api_name(:to_list), do: ":#{unquote(coll_mod)}.to_list/1"
      def coll_api_name(:union), do: ":#{unquote(coll_mod)}.union/2"

      #######

      defp coll_fun_filter_all(_element), do: true

      defp coll_fun_filter_none(_element), do: false

      defp coll_fun_filtermap_all_mapped(element), do: {true, element}

      defp coll_fun_fold_return_acc(_element, acc), do: acc

      defp coll_fun_map_identity(element), do: element
    end
  end
end
