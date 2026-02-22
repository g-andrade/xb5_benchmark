defmodule Xb5Benchmark.Groups do
  @moduledoc false
  use TypedStruct

  defmodule Group do
    @moduledoc false
    typedstruct do
      field(:id, atom, enforce: true)
      field(:type, term, enforce: true)
      field(:includes_empty?, boolean, enforce: true)
      field(:impl_mod, module, enforce: true)
      field(:suite_fun, fun(), enforce: true)
      field(:tweaks, term, enforce: true)
      field(:impl_description, String.t, enforce: true)
    end
  end

  @type run_structure :: :alternate_one_variant_one_key

  #####

  def delete_any_missing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :missing},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 4},
      impl_description: impl_description
    }
  end

  def delete(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :existing},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 4},
      impl_description: impl_description
    }
  end
  
  #  def delete_batch(suite_fun, impl_mod, impl_description) do
  #    %Group{
  #      id: elem(__ENV__.function, 0),
  #      type: :delete,
  #      includes_empty?: false,
  #      impl_mod: impl_mod,
  #      suite_fun: suite_fun,
  #      tweaks: {:batch_amount, 100},
  #      impl_description: impl_description
  #    }
  #  end

  def filter_all(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def filter_none(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def from_list(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_building_from_list, :shuffled},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def get(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :existing},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 4},
      impl_description: impl_description
    }
  end

  def get_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 100},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def insert(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :missing},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def insert_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :missing_and_unique, 100},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  # TODO is_disjoint

  # TODO is_equal

  def is_member_existing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :existing},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def is_member_missing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :missing},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def keys(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  ## TODO larger

  def largest(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  def lookup_existing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :existing},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def lookup_existing_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 100},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def lookup_missing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :missing},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def lookup_missing_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :missing, 100},
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  # TODO map

  # TODO iterations

  # TODO smaller

  def smallest(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  # TODO take_and_discard
  # TODO take_any_and_discard

  def take_largest(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  def take_largest_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_no_keys, 100},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def take_smallest(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 10},
      impl_description: impl_description
    }
  end

  def take_smallest_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_no_keys, 100},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def to_list(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  # TODO union

  def update(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_one_key, :existing},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:duplicate_variants, 5},
      impl_description: impl_description
    }
  end

  def update_x100(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: {:each_iteration_many_keys, :existing, 100},
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end

  def values(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :each_iteration_no_keys,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: :none,
      impl_description: impl_description
    }
  end
end
