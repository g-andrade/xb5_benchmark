defmodule Xb5Benchmark.CollectionWrappers.ErlangBag do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    coll_mod = opts[:coll_mod]

    quote do
      @behaviour Xb5Benchmark.CollectionWrapper

      @impl true
      defdelegate coll_add(element, bag), to: unquote(coll_mod), as: :add

      @impl true
      defdelegate coll_delete(element, bag), to: unquote(coll_mod), as: :delete

      @impl true
      defdelegate coll_delete_any(element, bag), to: unquote(coll_mod), as: :delete_any

      @impl true
      @compile {:inline, coll_filter_all: 1}
      def coll_filter_all(bag) do
        unquote(coll_mod).filter(&coll_fun_filter_all/1, bag)
      end

      @impl true
      @compile {:inline, coll_filter_none: 1}
      def coll_filter_none(bag) do
        unquote(coll_mod).filter(&coll_fun_filter_none/1, bag)
      end

      @impl true
      @compile {:inline, coll_filtermap_all: 1}
      def coll_filtermap_all(bag) do
        unquote(coll_mod).filtermap(&coll_fun_filter_all/1, bag)
      end

      @impl true
      @compile {:inline, coll_filtermap_all_mapped: 1}
      def coll_filtermap_all_mapped(bag) do
        unquote(coll_mod).filtermap(&coll_fun_filtermap_all_mapped/1, bag)
      end

      @impl true
      @compile {:inline, coll_filtermap_none: 1}
      def coll_filtermap_none(bag) do
        unquote(coll_mod).filtermap(&coll_fun_filter_none/1, bag)
      end

      @impl true
      @compile {:inline, coll_foldl: 1}
      def coll_foldl(bag) do
        unquote(coll_mod).fold(&coll_fun_fold_return_acc/2, :ok, bag)
      end

      @impl true
      defdelegate coll_from_list(bag), to: unquote(coll_mod), as: :from_list

      @impl true
      defdelegate coll_from_ordset_or_orddict(bag), to: unquote(coll_mod), as: :from_ordset

      @impl true
      defdelegate coll_insert(element, bag), to: unquote(coll_mod), as: :insert

      @impl true
      defdelegate coll_is_member(element, bag), to: unquote(coll_mod), as: :is_member

      @impl true
      defdelegate coll_iterator(bag), to: unquote(coll_mod), as: :iterator

      @impl true
      defdelegate coll_larger(element, bag), to: unquote(coll_mod), as: :larger

      @impl true
      defdelegate coll_largest(bag), to: unquote(coll_mod), as: :largest

      @impl true
      @compile {:inline, coll_map: 1}
      def coll_map(bag) do
        unquote(coll_mod).map(&coll_fun_map_identity/1, bag)
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
      defdelegate coll_nth(rank, bag), to: unquote(coll_mod), as: :nth

      @impl true
      @compile {:inline, coll_rank_and_discard: 2}
      def coll_rank_and_discard(key, bag) do
        case unquote(coll_mod).rank(key, bag) do
          {:rank, _rank} ->
            bag

          :none ->
            bag
        end
      end

      @impl true
      defdelegate coll_smaller(element, bag), to: unquote(coll_mod), as: :smaller

      @impl true
      defdelegate coll_smallest(bag), to: unquote(coll_mod), as: :smallest

      @impl true
      @compile {:inline, coll_take_largest_and_discard: 1}
      def coll_take_largest_and_discard(bag) do
        {_element, bag} = unquote(coll_mod).take_largest(bag)
        bag
      end

      @impl true
      @compile {:inline, coll_take_smallest_and_discard: 1}
      def coll_take_smallest_and_discard(bag) do
        {_element, bag} = unquote(coll_mod).take_smallest(bag)
        bag
      end

      @impl true
      defdelegate coll_to_list(bag), to: unquote(coll_mod), as: :to_list

      ################

      @impl true
      def coll_api_name(:add), do: ":#{unquote(coll_mod)}.add/2"
      def coll_api_name(:delete), do: ":#{unquote(coll_mod)}.delete/2"
      def coll_api_name(:delete_any), do: ":#{unquote(coll_mod)}.delete_any/2"
      def coll_api_name(:filter), do: ":#{unquote(coll_mod)}.filter/2"
      def coll_api_name(:filtermap), do: ":#{unquote(coll_mod)}.filtermap/2"
      def coll_api_name(:foldl), do: ":#{unquote(coll_mod)}.fold/3"
      def coll_api_name(:from_list), do: ":#{unquote(coll_mod)}.from_list/1"
      def coll_api_name(:from_ordset_or_orddict), do: ":#{unquote(coll_mod)}.from_ordset/1"
      def coll_api_name(:insert), do: ":#{unquote(coll_mod)}.insert/2"
      def coll_api_name(:is_member), do: ":#{unquote(coll_mod)}.is_member/2"
      def coll_api_name(:larger), do: ":#{unquote(coll_mod)}.larger/2"
      def coll_api_name(:largest), do: ":#{unquote(coll_mod)}.largest/1"
      def coll_api_name(:map), do: ":#{unquote(coll_mod)}.map/2"
      def coll_api_name(:next), do: "iterate :#{unquote(coll_mod)}"
      def coll_api_name(:nth), do: "#{unquote(coll_mod)}.nth/2"
      def coll_api_name(:rank), do: "#{unquote(coll_mod)}.rank/2"
      def coll_api_name(:smaller), do: ":#{unquote(coll_mod)}.smaller/2"
      def coll_api_name(:smallest), do: ":#{unquote(coll_mod)}.smallest/1"
      def coll_api_name(:take_largest), do: ":#{unquote(coll_mod)}.take_largest/1"
      def coll_api_name(:take_smallest), do: ":#{unquote(coll_mod)}.take_smallest/1"
      def coll_api_name(:to_list), do: ":#{unquote(coll_mod)}.to_list/1"

      #######

      defp coll_fun_filter_all(_element), do: true

      defp coll_fun_filter_none(_element), do: false

      defp coll_fun_filtermap_all_mapped(element), do: {true, element}

      defp coll_fun_fold_return_acc(_element, acc), do: acc

      defp coll_fun_map_identity(element), do: element
    end
  end
end
