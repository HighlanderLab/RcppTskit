# PR #132 Review: Table-Collection Sorting

## Status

Reviewed and implemented.

This file records the review of:

- `rtsk_table_collection_sort()` against `tsk_table_collection_sort()`;
- `TableCollection$sort()` against Python `TableCollection.sort()`.

The project-wide parity goal is to align the RcppTskit C++ API with the tskit
C API and the R API with the tskit Python API. Intentional R-specific
conveniences or deviations must be documented and tested.

## Low-level C++ wrapper

The wrapper constructs a `tsk_bookmark_t`, forwards its edge, site, and
mutation offsets and the supported `TSK_NO_CHECK_INTEGRITY` flag, mutates the
table collection in place, and translates tskit error codes to R errors.

Changes made during review:

- reject negative signed offsets before converting them to unsigned
  `tsk_size_t` values;
- retain strict option validation so only `TSK_NO_CHECK_INTEGRITY` is accepted;
- make the unmodified tskit return code `const`;
- retain the explanatory error for unsupported site/mutation offset pairs;
- use stable upstream documentation links.

Focused tests cover negative offsets, negative and unsupported options, the
edge upper-bound error, and supported boundary offsets.

## User-facing R method

The R signature mirrors Python's argument names and defaults:

```r
sort = function(edge_start = 0L, site_start = 0L, mutation_start = 0L)
```

R cannot enforce Python's keyword-only marker for `site_start` and
`mutation_start`. As an intentional R convenience consistent with the rest of
RcppTskit, integer-valued numeric scalars are accepted and safely converted to
32-bit integers after validation.

The documentation now states that:

- `edge_start` may range from zero through the edge-table length;
- site and mutation sorting can only be skipped together, by setting both
  offsets to their respective table lengths;
- rows before `edge_start` must already be sorted;
- sorting is in place and invalidates existing indexes;
- node, individual, population, and provenance tables are unaffected.

The example demonstrates converting an unsorted table collection into a valid
tree sequence. Focused tests check the invisible return value, integer-valued
numeric inputs, successful full sorting, site ordering, creation of a valid
tree sequence, boundary offsets, and index invalidation. Binding-specific
tests also verify that `edge_start` preserves the prefix and sorts actual rows
in the suffix, and that passing both site and mutation table lengths leaves
those tables unchanged.

## Upstream references

- C API: <https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_sort>
- Python API: <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.sort>
- Python implementation: <https://tskit.dev/tskit/docs/stable/_modules/tskit/tables.html>
