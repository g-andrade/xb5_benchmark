defmodule Xb5Benchmark.Groups do
  @moduledoc false
  use TypedStruct

  defmodule Group do
    @moduledoc false
    typedstruct do
      field(:id, atom, enforce: true)
      field(:type, atom, enforce: true)
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
      type: :delete_any_non_existing,
      includes_empty?: true,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:multiplier, 4},
      impl_description: impl_description
    }
  end

  def delete_existing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :delete_existing,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:multiplier, 4},
      impl_description: impl_description
    }
  end
  
  #  def delete_existing_batch(suite_fun, impl_mod, impl_description) do
  #    %Group{
  #      id: elem(__ENV__.function, 0),
  #      type: :delete_existing,
  #      includes_empty?: false,
  #      impl_mod: impl_mod,
  #      suite_fun: suite_fun,
  #      tweaks: {:batch_amount, 100},
  #      impl_description: impl_description
  #    }
  #  end

  def get_existing(suite_fun, impl_mod, impl_description) do
    %Group{
      id: elem(__ENV__.function, 0),
      type: :get_existing,
      includes_empty?: false,
      impl_mod: impl_mod,
      suite_fun: suite_fun,
      tweaks: {:multiplier, 4},
      impl_description: impl_description
    }
  end
end
