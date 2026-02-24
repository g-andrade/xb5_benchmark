defmodule Xb5Benchmark.CollectionWrappers.ErlangTree do
  ## Code generation
  @moduledoc false
  defmacro __using__(opts) do
    coll_mod = opts[:coll_mod]

    quote do
      @behaviour Xb5Benchmark.CollectionWrapper

      @impl true
      @compile {:inline, coll_add: 2}
      def coll_add(key, tree) do
        unquote(coll_mod).enter(key, :new_value, tree)
      end

      @impl true
      defdelegate coll_delete(key, tree), to: unquote(coll_mod), as: :delete

      @impl true
      defdelegate coll_delete_any(key, tree), to: unquote(coll_mod), as: :delete_any

      @impl true
      defdelegate coll_from_ordset_or_orddict(list), to: unquote(coll_mod), as: :from_orddict

      @impl true
      defdelegate coll_get(key, tree), to: unquote(coll_mod), as: :get

      @impl true
      @compile {:inline, coll_insert: 2}
      def coll_insert(key, tree) do
        unquote(coll_mod).insert(key, :new_value, tree)
      end

      @impl true
      defdelegate coll_is_member(key, tree), to: unquote(coll_mod), as: :is_defined

      @impl true
      defdelegate coll_iterator(tree), to: unquote(coll_mod), as: :iterator

      @impl true
      defdelegate coll_keys(tree), to: unquote(coll_mod), as: :keys

      @impl true
      defdelegate coll_larger(key, tree), to: unquote(coll_mod), as: :larger

      @impl true
      defdelegate coll_largest(tree), to: unquote(coll_mod), as: :largest

      @impl true
      defdelegate coll_lookup(key, tree), to: unquote(coll_mod), as: :lookup

      @impl true
      @compile {:inline, coll_map: 1}
      def coll_map(bag) do
        unquote(coll_mod).map(&coll_fun_map_identity/2, bag)
      end

      @impl true
      @compile {:inline, coll_next_and_discard: 1}
      def coll_next_and_discard(iterator) do
        case unquote(coll_mod).next(iterator) do
          {_, _, iterator} ->
            iterator

          :none ->
            :done
        end
      end

      @impl true
      defdelegate coll_smaller(key, tree), to: unquote(coll_mod), as: :smaller

      @impl true
      defdelegate coll_smallest(tree), to: unquote(coll_mod), as: :smallest

      @impl true
      @compile {:inline, coll_take_and_discard: 2}
      def coll_take_and_discard(key, tree) do
        {_value, tree} = unquote(coll_mod).take(key, tree)
        tree
      end

      @impl true
      @compile {:inline, coll_take_any_and_discard: 2}
      def coll_take_any_and_discard(key, tree) do
        case unquote(coll_mod).take(key, tree) do
          {_value, tree} ->
            tree

          :error ->
            tree
        end
      end

      @impl true
      @compile {:inline, coll_take_largest_and_discard: 1}
      def coll_take_largest_and_discard(tree) do
        {_key, _value, tree} = unquote(coll_mod).take_largest(tree)
        tree
      end

      @impl true
      @compile {:inline, coll_take_smallest_and_discard: 1}
      def coll_take_smallest_and_discard(tree) do
        {_key, _value, tree} = unquote(coll_mod).take_smallest(tree)
        tree
      end

      @impl true
      defdelegate coll_to_list(tree), to: unquote(coll_mod), as: :to_list

      @impl true
      @compile {:inline, coll_update: 2}
      def coll_update(key, tree) do
        unquote(coll_mod).update(key, :updated_value, tree)
      end

      @impl true
      defdelegate coll_values(tree), to: unquote(coll_mod), as: :values

      ################

      @impl true
      def coll_api_name(:add), do: ":#{unquote(coll_mod)}.enter/3"
      def coll_api_name(:delete), do: ":#{unquote(coll_mod)}.delete/2"
      def coll_api_name(:delete_any), do: ":#{unquote(coll_mod)}.delete_any/2"
      def coll_api_name(:from_ordset_or_orddict), do: ":#{unquote(coll_mod)}.from_orddict/1"
      def coll_api_name(:get), do: ":#{unquote(coll_mod)}.get/2"
      def coll_api_name(:insert), do: ":#{unquote(coll_mod)}.insert/3"
      def coll_api_name(:is_member), do: ":#{unquote(coll_mod)}.is_defined/2"
      def coll_api_name(:keys), do: ":#{unquote(coll_mod)}.keys/1"
      def coll_api_name(:larger), do: ":#{unquote(coll_mod)}.larger/2"
      def coll_api_name(:largest), do: ":#{unquote(coll_mod)}.largest/1"
      def coll_api_name(:lookup), do: ":#{unquote(coll_mod)}.lookup/2"
      def coll_api_name(:map), do: ":#{unquote(coll_mod)}.map/2"
      def coll_api_name(:next), do: "iterate :#{unquote(coll_mod)}"
      def coll_api_name(:smaller), do: ":#{unquote(coll_mod)}.smaller/2"
      def coll_api_name(:smallest), do: ":#{unquote(coll_mod)}.smallest/1"
      def coll_api_name(:take), do: ":#{unquote(coll_mod)}.take/2"
      def coll_api_name(:take_any), do: ":#{unquote(coll_mod)}.take_any/2"
      def coll_api_name(:take_largest), do: ":#{unquote(coll_mod)}.take_largest/1"
      def coll_api_name(:take_smallest), do: ":#{unquote(coll_mod)}.take_smallest/1"
      def coll_api_name(:to_list), do: ":#{unquote(coll_mod)}.to_list/1"
      def coll_api_name(:update), do: ":#{unquote(coll_mod)}.update/3"
      def coll_api_name(:values), do: ":#{unquote(coll_mod)}.values/1"

      #######

      defp coll_fun_map_identity(_key, value), do: value
    end
  end
end
