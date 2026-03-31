# xb5_benchmark

Elixir benchmarking suite for the [`xb5`](https://github.com/g-andrade/xb5) Erlang library.
Compares `xb5_sets`, `xb5_trees`, and `xb5_bag` against OTP's `gb_sets` and `gb_trees` across
50+ operations, 4 build scenarios, and collection sizes from 0 to 15,000 elements.

## Published reports

Two pre-run HTML reports are available online:

- [AMD Ryzen 7 5700G — OTP 28.1.1, JIT enabled](https://www.gandrade.net/xb5_benchmark/report_amd_ryzen7_5700g.html)
- [Intel i5-3550 — OTP 28.3.1, JIT enabled](https://www.gandrade.net/xb5_benchmark/report_intel_i5_3550.html)

Each report is interactive: you can select build type, metric (runtime / heap allocation),
and drill into individual operations with per-size line charts and p25–p75 bands.

## What is benchmarked

Three comparisons are made:

| xb5 module | Baseline | Description |
|---|---|---|
| `xb5_sets` | `gb_sets` | Ordered set; drop-in replacement |
| `xb5_trees` | `gb_trees` | Ordered key-value store; drop-in replacement |
| `xb5_bag` | `gb_sets` | Ordered multiset with rank/percentile operations |

## Methodology

### Collection sizes

Each operation is measured at `n = 0, 100, 200, 300, …, 1000, 2000, …, 10000, 15000` elements
(21 sizes).

### Build types

| Build type | Description |
|---|---|
| `sequential` | Keys inserted one at a time in sorted order |
| `random` | Random insertion order (50 independent variants per size, averaged) |
| `from_ordset_or_orddict` | Bulk construction from a pre-sorted list (tests optimised paths) |
| `xb5_adversarial` | Insert 25% extra keys, then delete every 4th (lowers key density, putting xb5 at a potential disadvantage) |

### Metrics

- **Runtime** — median iterations per second over a 60-second measurement window, reported as
  a ratio relative to the baseline (higher = faster than the baseline)
- **Heap allocation** — median bytes allocated per operation call, also reported as a ratio

### Convergence

Measurements run in 60-second batches. A size is considered stable once 4 consecutive batches
show a median variance of ≤5%. If the total elapsed time for a group exceeds 600 seconds, any
size that is currently stable is force-marked as done to prevent indefinite stalls on
high-variance operations.

### Environment

Tests ran on OTP 28 with JIT enabled on two machines:

| Machine | CPU | OTP | RAM |
|---|---|---|---|
| AMD Ryzen 7 5700G | 16-thread desktop APU | 28.1.1 | 30.7 GB |
| Intel i5-3550 | 4-core 2012 desktop | 28.3.1 | 19.2 GB |

## Benchmark design

### Uniform code paths via collection wrappers and the Suite macro

A key design goal is that every collection implementation runs through *identical* benchmark
code. This is achieved in two layers:

1. **`CollectionWrappers`** — one module per collection (`ErlGbSet`, `ErlXb5Set`,
   `ErlGbTree`, `ErlXb5Tree`, `ErlXb5Bag`). Each adapter maps a normalised API
   (`coll_add/2`, `coll_delete/2`, `coll_lookup/2`, …) onto the collection's native calls.
   For example, inserting a key into a tree requires a dummy value
   (`:gb_trees.enter(key, :value, tree)`) — that translation lives in the wrapper, not in
   the benchmark loop. Simple pass-throughs use `defdelegate` (compiled to a direct call
   with no extra frame); wrappers with any body are marked `@compile {:inline, …}` so they
   disappear into the call site.

2. **`Suite` macro** — `use Xb5Benchmark.Suite` is called by each suite module and
   generates all `run_each_*` benchmark functions and `groups_*` group descriptors at
   compile time from the suite's `@wrapper_mod` and `@coll_mod` attributes. Operations not
   supported by a collection are conditionally excluded using `Module.defines?/2`. The
   result is that the same generated code handles all five collections; there is no
   hand-written per-collection benchmark logic.

   Overhead is further minimised in the hot path in two ways. First, multi-key operations
   (e.g. "add 300 keys") are implemented as direct tail-recursive functions that
   pattern-match on `[key | rest]` lists, avoiding any higher-order dispatch through
   `:lists.foreach/2` or `:lists.foldl/3`. Second, collection variants are consumed the
   same way — the `run_each_*` functions iterate through the pre-built variant list with
   head-tail pattern matching rather than `Enum` calls.

### Pre-built and cached input structures

Before any timing begins, `InputStructures` builds all collections at every `(n, build_type,
impl_mod)` combination and serialises them to disk under `_cache/input_structures/`. The
cache key incorporates an MD5 hash of the implementation module, so it is invalidated
automatically if the module changes.

For the `random` build type, 50 independent variants are constructed per `n` using seeded
randomness (different seeds per variant, same seeds across runs). This averages out
insertion-order effects. For the other build types a single canonical collection is built
and deep-copied to produce 50 structurally identical but heap-independent variants, ensuring
that cache pressure from one measurement does not carry over to the next.

### Pre-computed keys and operation inputs

Operations that require specific keys (e.g. "add 300 missing keys", "look up 100 existing
keys") pre-generate those keys before the measurement loop starts, using seeded randomness
for reproducibility. Binary operations (union, difference, intersection, `is_subset`,
`is_equal`) are benchmarked across all combinations of a second-collection size (50, 100,
500, 1000 elements) and overlap percentage (0%, 50%, 100% keys in common). None of this
input preparation happens inside the timed loop.

### Memory measurement

Heap allocation per call is measured by recording process heap size before and after a
single operation invocation (after forcing a garbage collection). This is collected once
per case at initialisation time and stored alongside the runtime samples.

## Results

Results below are drawn from the published runs. Ratios are at the largest measured size
(`n = 15,000`) unless otherwise noted. "As fast" means iterations per second relative to
the baseline; heap differences are percentages relative to the baseline.

### `xb5_sets` vs `gb_sets`

* Mutations (`add`, `del_element`, `delete`), membership tests (`is_member`), and
  set-algebraic operations (`difference`, `union`, `intersection`, `is_disjoint`,
  `is_subset`): **1.2–2.2× as fast**, with similar heap use
* `filter`, `filtermap`, `map`: **~1.5–2.5× as fast**, with up to ~40% less heap
* Bulk construction (`from_list`, `from_ordset`): similar or faster speed,
  **~15–65% less heap**
* Alternating `take_smallest`/`insert` (queue-like workload): **~2–4× as fast**
  depending on build scenario
* `is_equal` with no key overlap: **40–126× as fast** — `gb_sets` converts both sets to
  lists for comparison; with identical keys the results are roughly equal
* Iteration (`iterator`, `next`): **~25% slower** on the AMD machine; near-equal on the i5

### `xb5_trees` vs `gb_trees`

* Lookups (`get`, `lookup`, `is_defined`): **1.6–1.9× as fast**, with equal heap
* Mutations (`enter`, `insert`, `update`, `delete`, `take`): **1.2–1.7× as fast**
* `map`, `keys`, `values`: **1.9–2.5× as fast**; `map` uses ~47% less heap
* Alternating `take_smallest`/`insert_largest` (queue-like workload):
  **1.7–3.3× as fast**
* `take_smallest` and `take_largest`: **14–27% slower** in most build scenarios

### `xb5_bag` vs `gb_sets`

Runtime profile broadly matches `xb5_sets`. Heap use is up to ~40% lower for `filter`/`map`
operations and ~15–62% lower for bulk construction, but ~20–25% higher for mutations.

## Running the benchmarks yourself

Requirements: Erlang/OTP 27+ and Elixir 1.17+.

```bash
git clone https://github.com/g-andrade/xb5_benchmark
cd xb5_benchmark
mix deps.get
iex -S mix
```

```elixir
# Run the full suite and write results to output/my_run/
Xb5Benchmark.run("output/my_run")

# Run specific build types only
Xb5Benchmark.run("output/my_run", build_types: [:sequential, :random])

# Target specific operations by keyword
Xb5Benchmark.run("output/my_run", keywords: [:union, :intersection])

# Merge per-operation JSON files into a single file for the report generator
Xb5Benchmark.merge_into_single_json("output/my_run")
```

A full run takes several hours. Results land in `output/my_run/` as JSON files and two
pivoted CSV files (`stats_runtime.csv`, `stats_memory.csv`).

### Generating the HTML report

```bash
python3 generate_report.py output/my_run
# writes output/my_run/report.html (~3 MB; requires internet for Plotly CDN)
```

`generate_report.py` is a self-contained Python 3 script with no dependencies beyond the
standard library. It reads `output/my_run/merged_data.json` (produced by
`merge_into_single_json/1`) and writes a single interactive HTML file.
