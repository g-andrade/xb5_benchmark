defmodule Xb5Benchmark.CollectionWrapper do
  ## Types

  @type t :: term
  @type key :: term
  @type value :: term

  ## Callbacks

  @callback coll_add(key, t) :: t
  @callback coll_delete(key, t) :: t
  @callback coll_delete_any(key, t) :: t
  #@callback coll_difference(t, t) :: t
  @callback coll_filter_all(t) :: t
  @callback coll_filter_none(t) :: t
  #@callback coll_foldl(t) :: t
  #@callback coll_foldr(t) :: t
  @callback coll_get(key, t) :: value
  @callback coll_insert(key, t) :: t
  #@callback coll_intersection(t, t) :: t
  #@callback coll_iterator(t) :: term
  @callback coll_is_disjoint(t, t) :: boolean
  @callback coll_is_equal(t, t) :: boolean
  @callback coll_is_member(key, t) :: boolean
  @callback coll_keys(t) :: [key]
  @callback coll_larger(key, t) :: term
  @callback coll_largest(t) :: term
  @callback coll_lookup(key, t) :: term
  #@callback coll_map(key, t) :: term
  #@callback coll_next
  #@callback coll_size(t) :: non_neg_integer
  @callback coll_smaller(key, t) :: term
  @callback coll_smallest(t) :: term
  @callback coll_take_and_discard(key, t) :: t
  @callback coll_take_any_and_discard(key, t) :: t
  @callback coll_take_largest_and_discard(t) :: t
  @callback coll_take_smallest_and_discard(t) :: t
  @callback coll_to_list(t) :: list()
  @callback coll_union(t, t) :: t
  @callback coll_update(key, t) :: t
  @callback coll_values(t) :: [value]

  @callback coll_api_name(atom) :: String.t

  @optional_callbacks [
    # coll_difference: 2,
    coll_filter_all: 1,
    coll_filter_none: 1,
    # coll_foldl: 1,
    # coll_foldr: 1,
    coll_get: 2,
    coll_is_disjoint: 2,
    coll_is_equal: 2,
    coll_keys: 1,
    coll_lookup: 2,
    coll_take_and_discard: 2,
    coll_take_any_and_discard: 2,
    coll_union: 2,
    coll_update: 2,
    coll_values: 1
  ]
end
