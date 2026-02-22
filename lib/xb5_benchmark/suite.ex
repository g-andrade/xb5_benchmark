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

      def run_each_delete([coll, key | next]) do
        _ = coll_delete(key, coll)
        run_each_delete(next)
      end

      def run_each_delete([]) do
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

      if Module.defines?(__MODULE__, {:run_each_get, 1}) do
        def group_get_existing, do: Groups.get_existing(&__MODULE__.run_each_get/1, impl_mod(), coll_api_name(:get))
      else
        def group_get_existing, do: nil
      end

      ####################################################

      def groups() do
        [
          Groups.delete_existing(&__MODULE__.run_each_delete/1, impl_mod(), coll_api_name(:delete_any)),
          Groups.delete_any_missing(&__MODULE__.run_each_delete_any/1, impl_mod(), coll_api_name(:delete_any)),
          group_get_existing()
        ]
        |> List.flatten()
        |> Enum.filter(&(&1 !== nil))
      end

    end
  end
end
