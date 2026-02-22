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
      @compile {:inline, coll_filter_all: 1}
      def coll_filter_all(set) do
        unquote(coll_mod).filter(fn _element -> true end, set)
      end

      @impl true
      @compile {:inline, coll_filter_none: 1}
      def coll_filter_none(set) do
        unquote(coll_mod).filter(fn _element -> false end, set)
      end

      @impl true
      defdelegate coll_insert(element, set), to: unquote(coll_mod), as: :insert

      @impl true
      defdelegate coll_is_disjoint(set1, set2), to: unquote(coll_mod), as: :is_disjoint

      @impl true
      defdelegate coll_is_equal(set1, set2), to: unquote(coll_mod), as: :is_equal

      @impl true
      defdelegate coll_is_member(element, set), to: unquote(coll_mod), as: :is_member

      @impl true
      defdelegate coll_larger(element, set), to: unquote(coll_mod), as: :larger

      @impl true
      defdelegate coll_largest(set), to: unquote(coll_mod), as: :largest

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
      def coll_api_name(:filter), do: ":#{unquote(coll_mod)}.filter/2"
      def coll_api_name(:insert), do: ":#{unquote(coll_mod)}.insert/2"
      def coll_api_name(:is_disjoint), do: ":#{unquote(coll_mod)}.is_disjoint/2"
      def coll_api_name(:is_equal), do: ":#{unquote(coll_mod)}.is_equal/2"
      def coll_api_name(:is_member), do: ":#{unquote(coll_mod)}.is_member/2"
      def coll_api_name(:larger), do: ":#{unquote(coll_mod)}.larger/2"
      def coll_api_name(:largest), do: ":#{unquote(coll_mod)}.largest/1"
      def coll_api_name(:smaller), do: ":#{unquote(coll_mod)}.smaller/2"
      def coll_api_name(:smallest), do: ":#{unquote(coll_mod)}.smallest/1"
      def coll_api_name(:take_largest_and_discard), do: ":#{unquote(coll_mod)}.take_largest/1"
      def coll_api_name(:take_smallest_and_discard), do: ":#{unquote(coll_mod)}.take_smallest/1"
      def coll_api_name(:to_list), do: ":#{unquote(coll_mod)}.to_list/1"
    end
  end
end
