defmodule Xb5Benchmark.Groups do
  @moduledoc false
  use TypedStruct

  defmodule Group do
    @moduledoc false
    typedstruct do
      field(:id, atom, enforce: true)
      field(:input_type, atom, enforce: true)
      field(:input_amount, pos_integer | {:max, pos_integer}, enforce: true)
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

  def delete do
    %Group{
      id: elem(__ENV__.function, 0),
      input_type: :existing_keys_to_delete_cumulatively,
      input_amount: {:max, 500}
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
      input_type: :new_keys_to_insert,
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
