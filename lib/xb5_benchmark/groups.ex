defmodule Xb5Benchmark.Groups do
  @moduledoc false
  use TypedStruct

  import ExUnit.Assertions

  defmodule Group do
    @moduledoc false
    typedstruct do
      field(:id, atom, enforce: true)
      field(:keywords, [atom], default: [])
      field(:type, term, enforce: true)
      field(:includes_empty?, boolean, enforce: true)
      field(:impl_mod, module, enforce: true)
      field(:suite_fun, fun(), enforce: true)
      field(:iteration_fun, fun(), enforce: true)
      field(:tweaks, term, enforce: true)
      field(:impl_description, String.t(), enforce: true)
    end
  end

  @type run_structure :: :alternate_one_variant_one_key

  #####

  @set_op_max_percentages_in_common [0.0, 0.5, 1.0]
  @set_op_sizes [50, 100, 500, 1000]

  @set_op_params for max_percentage_in_common <- @set_op_max_percentages_in_common,
                     size2 <- @set_op_sizes,
                     do: {max_percentage_in_common, size2}

  #####

  def add_new_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:add_new],
      type: {:each_iteration_many_keys, :missing_and_unique, amount},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def add_existing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      keywords: [:add_existing],
      type: {:each_iteration_many_keys, :existing_and_unique, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def alternatively_take_smallest_and_insert_largest(
        amount,
        suite_fun,
        iteration_fun,
        impl_mod,
        impl_description
      ) do
    %Group{
      id: :"take_smallest + insert largest x#{amount}",
      keywords: [:alternatively_take_smallest_and_insert_largest],
      type: {:each_iteration_many_keys, :to_append, amount},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def delete_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:delete],
      type: {:each_iteration_many_keys, :existing_and_unique, amount},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def delete_any_missing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      keywords: [:delete_any_missing],
      type: {:each_iteration_many_keys, :missing, 300},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def difference(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      @set_op_params,
      fn {max_percentage_in_common, size2} ->
        %Group{
          id: set_op_group_name(:difference, max_percentage_in_common, size2),
          keywords: [:difference],
          type: {:each_iteration_a_second_collection, max_percentage_in_common, size2},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def filter_all(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def filter_none(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def filtermap_all(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def filtermap_all_mapped(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def filtermap_none(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def foldl(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def from_list(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:bulk_constructor, [:sequential, :random]},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def from_ordset_or_orddict(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: :"from_ordset / from_orddict",
      type: {:bulk_constructor, [:sequential]},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def get_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def insert_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:insert],
      type: {:each_iteration_many_keys, :missing_and_unique, amount},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def intersection(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      @set_op_params,
      fn {max_percentage_in_common, size2} ->
        %Group{
          id: set_op_group_name(:intersection, max_percentage_in_common, size2),
          keywords: [:intersection],
          type: {:each_iteration_a_second_collection, max_percentage_in_common, size2},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def iterate(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def is_disjoint(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      @set_op_params,
      fn {max_percentage_in_common, size2} ->
        %Group{
          id: set_op_group_name(:is_disjoint, max_percentage_in_common, size2),
          keywords: [:is_disjoint],
          type: {:each_iteration_a_second_collection, max_percentage_in_common, size2},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def is_equal(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      [0.0, 0.5, 1.0],
      fn percentage_in_common ->
        id =
          case percentage_in_common do
            +0.0 ->
              :"is_equal [no shared keys]"

            0.5 ->
              :"is_equal [50% smallest keys are equal]"

            1.0 ->
              :"is_equal [same keys]"
          end

        %Group{
          id: id,
          keywords: [:is_equal],
          type:
            {:each_iteration_a_second_collection, {percentage_in_common, :smallest_keys},
             :same_size},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def is_member_existing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def is_member_missing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :missing, 300},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def is_subset(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      [0.0, 0.5, 1.0],
      fn percentage_in_common ->
        id =
          case percentage_in_common do
            +0.0 ->
              :"is_subset [no shared keys]"

            0.5 ->
              :"is_subset [50% largest keys are equal]"

            1.0 ->
              :"is_subset [same keys]"
          end

        %Group{
          id: id,
          keywords: [:is_subset],
          type:
            {:each_iteration_a_second_collection, {percentage_in_common, :largest_keys},
             :same_size},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def keys(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def larger_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def largest(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  def lookup_existing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def lookup_missing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :missing, 300},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def map(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def nth_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_ranks, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def rank_existing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def smaller_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def smallest(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  def take_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:take],
      type: {:each_iteration_many_keys, :existing_and_unique, amount},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def take_any_missing_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      keywords: [:take_any],
      type: {:each_iteration_many_keys, :missing, 300},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def take_largest_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:take_largest],
      type: {:each_iteration_no_keys, amount},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def take_smallest_many(amount, suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: many_group_id(elem(__ENV__.function, 0), amount),
      keywords: [:take_smallest],
      type: {:each_iteration_no_keys, amount},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def to_list(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def union(suite_fun, iteration_fun, impl_mod, impl_description) do
    Enum.map(
      @set_op_params,
      fn {max_percentage_in_common, size2} ->
        %Group{
          id: set_op_group_name(:union, max_percentage_in_common, size2),
          keywords: [:union],
          type: {:each_iteration_a_second_collection, max_percentage_in_common, size2},
          includes_empty?: true,
          impl_mod: impl_mod,
          suite_fun: suite_fun,
          iteration_fun: iteration_fun,
          tweaks: :none,
          impl_description: impl_description
        }
      end
    )
  end

  def update_x300(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 300},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def values(suite_fun, iteration_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      iteration_fun: iteration_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  ##########

  defp many_group_id(function_name, amount) do
    assert is_integer(amount) or amount === :N

    string_function_name = Atom.to_string(function_name)
    base_string_function_name = String.replace_suffix(string_function_name, "_many", "")
    assert base_string_function_name !== string_function_name

    String.to_atom(base_string_function_name <> "_x#{amount}")
  end

  #  defp set_op_group_name(base_name, percentage_in_common) do
  #    percentage_str = String.pad_leading("#{trunc(percentage_in_common * 100)}", 3, "0")
  #    String.to_atom("#{base_name}_#{percentage_str}")
  #  end

  defp set_op_group_name(base_name, max_percentage_in_common, size2) do
    percentage_str = String.pad_leading("#{trunc(max_percentage_in_common * 100)}", 3, "0")
    size_str = String.pad_leading("#{size2}", 4, "0")
    String.to_atom("#{base_name}_#{percentage_str}_#{size_str}")
  end
end
