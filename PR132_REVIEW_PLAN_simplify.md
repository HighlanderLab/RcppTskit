# PR #132 Review:  c

## Status

Reviewed and implemented for both:

- `rtsk_table_collection_simplify()` and `TableCollection$simplify()`;
- `TreeSequence$simplify()`.

The review checks the C++ wrapper against the tskit C API and the two R methods
against their tskit Python counterparts. The implementation follows upstream
names, defaults, and semantics where practical, with R-specific return values
documented below.

## Low-level C++ wrapper

`rtsk_table_collection_simplify()` is the only new C++ simplify wrapper needed.
It calls `tsk_table_collection_simplify()` directly and:

- distinguishes `samples = NULL` from an explicit `integer()`; `NULL` uses the
  nodes currently marked as samples, whereas `integer()` requests no samples;
- converts R integer sample IDs to `tsk_id_t` values;
- allocates the node map to the node-table length before simplification;
- accepts only the nine supported table-simplify option flags;
- propagates tskit errors, including invalid and duplicate sample IDs;
- returns an R integer node map, using `-1` (`TSK_NULL`) for removed nodes.

Tests cover option validation, invalid and duplicate samples, explicit empty
samples, equivalence of `NULL` to the currently flagged samples, node-map
contents, and index invalidation.

## `TableCollection$simplify()`

The method mutates its table collection in place and returns the node map. Its
public argument names and defaults follow Python
`TableCollection.simplify()`. Integer-valued numeric sample IDs are also
accepted as an intentional R convenience and safely converted to R integers.

Python's `None` defaults are represented by `NULL`. They resolve as follows:

- `filter_populations`, `filter_individuals`, `filter_sites`, `filter_nodes`,
  and `update_sample_flags` resolve to `TRUE`;
- `keep_unary_in_individuals` resolves to `FALSE`.

The R arguments map to C flags as follows:

| R argument | C option when active |
| --- | --- |
| `filter_sites = TRUE` | `TSK_SIMPLIFY_FILTER_SITES` |
| `filter_populations = TRUE` | `TSK_SIMPLIFY_FILTER_POPULATIONS` |
| `filter_individuals = TRUE` | `TSK_SIMPLIFY_FILTER_INDIVIDUALS` |
| `reduce_to_site_topology = TRUE` | `TSK_SIMPLIFY_REDUCE_TO_SITE_TOPOLOGY` |
| `keep_unary = TRUE` | `TSK_SIMPLIFY_KEEP_UNARY` |
| `keep_input_roots = TRUE` | `TSK_SIMPLIFY_KEEP_INPUT_ROOTS` |
| `keep_unary_in_individuals = TRUE` | `TSK_SIMPLIFY_KEEP_UNARY_IN_INDIVIDUALS` |
| `filter_nodes = FALSE` | `TSK_SIMPLIFY_NO_FILTER_NODES` |
| `update_sample_flags = FALSE` | `TSK_SIMPLIFY_NO_UPDATE_SAMPLE_FLAGS` |

`keep_unary` and `keep_unary_in_individuals` are rejected when both are true,
matching their incompatible upstream semantics. The obsolete
`filter_zero_mutation_sites` compatibility argument is intentionally absent.

When requested, the method appends a provenance-schema 1.0.0 record containing
the RcppTskit version and normalised simplify arguments. No row is appended
when `record_provenance = FALSE`.

Content tests use a fresh table collection for every mutating case and verify:

- node-map contents and a smaller simplified topology;
- site-topology reduction;
- `keep_unary`, `keep_input_roots`, and `keep_unary_in_individuals`;
- population, individual, site, and node filtering;
- identity mapping when node filtering is disabled;
- unchanged flags when sample-flag updates are disabled;
- provenance enabled and disabled behavior.

## `TreeSequence$simplify()`

No separate `tsk_treeseq_simplify()` wrapper is required. Following the Python
method's high-level behavior, the R method copies the input tables, delegates
to the reviewed `TableCollection$simplify()`, and constructs a new tree
sequence. The input tree sequence is therefore unchanged, and option mapping
and provenance behavior remain centralised in one implementation.

The arguments and defaults match the table-collection method, with the
addition of `map_nodes`. With `map_nodes = FALSE`, the method returns the new
`TreeSequence`. With `map_nodes = TRUE`, it returns a named list containing
`tree_sequence` and `node_map`, the natural R equivalent of Python's tuple.
Deprecated compatibility arguments never supported by RcppTskit are omitted.

Tree-sequence tests verify:

- the result is a new, smaller tree sequence and the input is unchanged;
- sample IDs and provenance behavior in the result;
- the conditional node-map return and map contents;
- invalid `map_nodes`, duplicate samples, and incompatible unary options;
- representative forwarding for `keep_unary` and `filter_nodes`.

The detailed option semantics are tested once at table-collection level; the
tree-sequence tests intentionally focus on delegation and return behavior.

## Audit conclusion

The implementation, documentation, examples, NEWS entry, and tests agree on
the public contract. No simplify code changes are outstanding from this
review.

## Upstream references

- C API: <https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_simplify>
- Python `TableCollection.simplify()`:
  <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.simplify>
- Python `TreeSequence.simplify()`:
  <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.simplify>
- Provenance schema:
  <https://tskit.dev/tskit/docs/stable/provenance.html>
