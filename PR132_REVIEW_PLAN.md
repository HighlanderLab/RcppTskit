# PR #132 API Review Plan

## Pause handoff (2026-08-21)

The review is deliberately paused at the start of variant iteration while
Gregor is away and until the intended user-facing design has been discussed
with Jinyang. This is a clean review boundary, not an indication that the
variant implementation has been approved.

Completed review slices are node and remaining table-row access, table-row
appenders, tree-sequence sample access, table-collection sorting, and table-
collection/tree-sequence simplification. Their detailed notes are retained in
the companion review-plan files.

The next work is **section 7, low-level variant iteration**. Resume with
iterator state, initialization, ownership, and cleanup in
`PR132_REVIEW_PLAN_variants.md`; then review decoding and exhaustion; only then
review the user-facing `TreeSequence$variants()` API. Do not restart the review
from the beginning of the PR.

Before continuing, ask Jinyang for:

- concise user-facing documentation for the intended variants workflow;
- one or two executable examples, including expected returned content and the
  AlphaSimR use case;
- the intended public API and compatibility requirements, particularly which
  iterator methods and arguments downstream code needs.

The local review branch was clean at commit `ac89284` before this handoff note
was added. At that point it contained ten review commits beyond PR #132's head
commit `24509d1`, and the latest commit had not yet been pushed to Gregor's
`origin/lynx-clean-work`. PR #132 is open from
`LynxJinyangii:add-multiple-functions-on-pr-131` into
`HighlanderLab:main`; pushing this review branch to Gregor's fork does not by
itself update the PR.

After variants are agreed and reviewed, complete section 9 cross-cutting
cleanup and all final quality gates. No final full-package quality-gate result
is claimed by this pause handoff.

## Goal

Review and polish PR #132 function by function before it is merged into
`HighlanderLab/RcppTskit`.

For every API slice:

- align the RcppTskit R API with the upstream tskit Python API;
- align the RcppTskit C++ API with the upstream tskit C API;
- document any intentional deviation;
- add or update examples and focused regression tests;
- update `RcppTskit/NEWS.md` for user-visible changes;
- regenerate exports and documentation rather than editing generated files;
- keep focused and full quality gates green.

## Review method for each function

### 1. Review the low-level C++ wrapper

- Compare its name, arguments, defaults, return value, ownership rules, and
  error handling with the corresponding tskit C function.
- Check conversions between `tsk_id_t`, `tsk_size_t`, flags, pointers, strings,
  raw metadata, and R values.
- Check special values such as `TSK_NULL`, empty arrays, missing values, and
  invalid indices.
- Use `const` for local values that are not modified, including converted row
  indices and tskit return codes.
- Where the upstream row struct exposes an `id` field, return `row.id` rather
  than reconstructing the ID from the input index.
- Confirm that the wrapper does not add unsupported semantics silently.

### 2. Review the user-facing R method

- Compare its name, arguments, defaults, return value, and error behaviour with
  the corresponding tskit Python method.
- Prefer Python naming and semantics unless an R-specific deviation is clearly
  justified.
- Document and test every intentional deviation.
- Check input validation and conversions before calling the C++ wrapper.

### 3. Review tests and documentation

- Test normal results and content, not only object types or lengths.
- Test boundary cases, empty inputs, special values, and invalid inputs.
- Add a concise user-facing example.
- Verify roxygen documentation and `NEWS.md` wording.

## Function-by-function order

### 1. Node table row access

- [x] `rtsk_node_table_get_row()` against `tsk_node_table_get_row()`
- [x] `TableCollection$node_table_get_row()` against Python node-table row
      access
- [x] Focused tests and documentation

This is the first review target. It is small, establishes the table-row return
conventions used throughout the PR, and is used by `TreeSequence$samples()`.

Review specifically:

- all node fields and their R types;
- 0-based row IDs;
- `TSK_NULL` population and individual values;
- empty and nonempty metadata;
- first, last, negative, out-of-range, missing, and invalid indices;
- C error propagation;
- parity of the returned R object with the Python row object.

### 2. Tree-sequence sample access

- [x] `rtsk_treeseq_get_samples()` against `tsk_treeseq_get_samples()`
- [x] `TreeSequence$samples()` against `TreeSequence.samples()`
- [x] Omit Python's already-deprecated `population_id` alias from the new R API
- [x] Focused tests and documentation

The completed review is recorded in `PR132_REVIEW_PLAN_samples.md`.

### 3. Remaining table row accessors

- [x] `individual_table_get_row()`
- [x] `edge_table_get_row()`
- [x] `site_table_get_row()`
- [x] `mutation_table_get_row()`
- [x] `population_table_get_row()`
- [x] `migration_table_get_row()`
- [x] `provenance_table_get_row()`

For each entry, review the low-level `rtsk_*` wrapper first and then the
corresponding `TableCollection$*` method. As part of each C++ review, make
unmodified index and return-code locals `const`, and return the upstream row
struct's `id` field where that struct provides one.

### 4. Table row appenders

- [x] `individual_table_add_row()`
- [x] `node_table_add_row()`
- [x] `edge_table_add_row()`
- [x] `site_table_add_row()`
- [x] `mutation_table_add_row()`
- [x] `population_table_add_row()`
- [x] `migration_table_add_row()`
- [x] `provenance_table_add_row()`

For each entry, review the low-level `rtsk_*` wrapper against the C API and the
corresponding `TableCollection$*` method against Python `add_row()`.

### 5. Table collection sorting

- [x] `rtsk_table_collection_sort()` against `tsk_table_collection_sort()`
- [x] `TableCollection$sort()` against `TableCollection.sort()`
- [x] Focused tests and documentation

The completed review is recorded in `PR132_REVIEW_PLAN_sort.md`. It confirms
the intended C++/C and R/Python API parity, documents partial-sort constraints
and index invalidation, and adds focused safety and semantic tests.

### 6. Table collection simplification

- [x] `rtsk_table_collection_simplify()` against
      `tsk_table_collection_simplify()`
- [x] `TableCollection$simplify()` against `TableCollection.simplify()`
- [x] Review every option bit and default
- [x] Replace or resolve the placeholder provenance record
- [x] Add focused tests for the currently uncovered option-building branches:
      `reduce_to_site_topology = TRUE`, `keep_unary = TRUE`,
      `keep_input_roots = TRUE`, `keep_unary_in_individuals = TRUE`,
      `filter_nodes = FALSE`, and `update_sample_flags = FALSE`. Use a fresh
      table collection for each case because `simplify()` mutates it, and test
      the resulting semantics rather than only executing each branch.
- [x] Focused tests and documentation

The completed review is recorded in `PR132_REVIEW_PLAN_simplify.md`. It
confirms all C option mappings and Python defaults, replaces the bare
placeholder provenance with a valid provenance-schema document, and tests the
semantic effect of every public option.

### 6a. Tree-sequence simplification

- [x] `TreeSequence$simplify()` against Python `TreeSequence.simplify()`
- [x] Preserve the input tree sequence and support `map_nodes`
- [x] Reuse the reviewed table-collection implementation rather than
      duplicating option construction or adding an unnecessary C++ wrapper
- [x] Focused tests and documentation

The completed review of both table-collection and tree-sequence simplification
is recorded in `PR132_REVIEW_PLAN_simplify.md`.

### 7. Low-level variant iteration

The detailed review and workstation handoff plan is recorded in
`PR132_REVIEW_PLAN_variants.md`. Start with iterator state, initialization,
ownership, and cleanup before reviewing decoding.

- [ ] `rtsk_treeseq_init_variants_iterator()` against `tsk_variant_init()`
- [ ] `rtsk_treeseq_next_variant()` against `tsk_variant_decode()` and
      `tsk_variant_t`
- [ ] Review memory ownership, preservation, cleanup, and iterator exhaustion
- [ ] Review samples, alleles, missing-data semantics, and genomic bounds
- [ ] Focused tests and documentation

### 8. User-facing variant iteration

- [ ] `TreeSequence$variants()` against `TreeSequence.variants()`
- [ ] Review arguments, defaults, return shape, copying, and iteration protocol
- [ ] Decide how closely the R iterator should mirror Python iteration
- [ ] Focused tests and documentation

### 9. Cross-cutting cleanup

- [ ] Review shared validators introduced or changed by the PR
- [ ] Confirm all reviewed C++ row getters consistently use `const` locals and
      return `row.id` where the upstream row struct provides it
- [ ] Add a shared binary-metadata round-trip test using bytes such as
      `as.raw(c(0x00, 0x7f, 0x80, 0xff))` for metadata-bearing row appenders
      and getters
- [ ] Confirm consistent terminology, argument names, and error messages
- [ ] We have some C functions names rtsk_x while for some we have just x,
      particulalry the internal functions - I guess internals are fine, but are there any non-internal functions that don't start as rtsk_x?
- [ ] Confirm examples are concise and executable
- [ ] Investigate and resolve the existing
      `vignette 'RcppTskit_intro' not found` warning emitted by
      `devtools::run_examples()`.
- [ ] Update `RcppTskit/NEWS.md`
- [ ] Regenerate Rcpp exports and roxygen documentation
- [ ] Review generated diffs for consistency only

## Final quality gates

- [ ] Run focused tests after each API slice
- [ ] Run `pre-commit run --all-files`
- [ ] Run `Rscript -e "setwd('RcppTskit'); devtools::test()"`
- [ ] Run `Rscript -e "setwd('RcppTskit'); devtools::check()"`
- [ ] Review the complete PR diff against `upstream/main`

## Useful diff commands

Review the PR without the additional local integration commit:

```sh
git diff upstream/main...LynxJinyangii/add-multiple-functions-on-pr-131
```

Review the combined local branch:

```sh
git diff upstream/main...HEAD
```

Review the hand-written implementation and tests while initially excluding
generated exports and manuals:

```sh
git diff upstream/main...HEAD -- \
  RcppTskit/R/Class-TableCollection.R \
  RcppTskit/R/Class-TreeSequence.R \
  RcppTskit/R/RcppTskit.R \
  RcppTskit/src/RcppTskit.cpp \
  RcppTskit/inst/include/RcppTskit_public.hpp \
  RcppTskit/tests/testthat/
```
