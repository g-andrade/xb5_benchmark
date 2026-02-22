defmodule Xb5Benchmark.Groups do
  @moduledoc false
  use TypedStruct

  defmodule Group do
    @moduledoc false
    typedstruct do
      field(:id, atom, enforce: true)
      field(:input_type, atom | tuple(), enforce: true)
      field(:input_amount, pos_integer | {:max, pos_integer} | float, enforce: true)
    end
  end

  #####

  def alternate_insert_and_delete do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :keys_to_alternate_insert_and_delete,
      input_amount: 500
    }
  end

  def alternate_insert_largest_and_take_smallest do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: {:new_keys_to_insert, :asc},
      input_amount: 250
    }
  end

  def alternate_insert_smallest_and_take_largest do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: {:new_keys_to_insert, :desc},
      input_amount: 250
    }
  end

  def delete do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_delete_cumulatively,
      input_amount: {:max, 500}
    }
  end

  def filter_all do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :amount,
      input_amount: :all
    }
  end

  def filter_none do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :amount,
      input_amount: :none
    }
  end

  def get do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def insert do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: {:new_keys_to_insert, :random},
      input_amount: 500
    }
  end

  def is_defined do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def nth do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_ranks_to_lookup,
      input_amount: 1000
    }
  end

  def percentile_inclusive do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: {:existing_percentiles_to_lookup, :inclusive},
      input_amount: 1000
    }
  end

  def percentile_nearest_rank do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: {:existing_percentiles_to_lookup, :nearest_rank},
      input_amount: 1000
    }
  end

  def percentile_rank do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def rank do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def rank_larger do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def rank_smaller do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 1000
    }
  end

  def take_largest do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :amount,
      input_amount: {:max, 500}
    }
  end

  def take_smallest do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :amount,
      input_amount: {:max, 500}
    }
  end

  def update do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_lookup,
      input_amount: 500
    }
  end
end
