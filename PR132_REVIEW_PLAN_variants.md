# PR #132 Review: Variant Iteration

## Status

Paused on 2026-08-21 pending discussion with Jinyang. The low-level iterator-
state documentation and ownership model have been mapped, but the variant
implementation and user-facing API have not been approved. There are not yet
sufficient user-facing docs or examples to resolve the API by review alone.

When work resumes, continue with the finalizer and initializer, then review
decoding and exhaustion, and only then review `TreeSequence$variants()`. Do not
restart from earlier PR slices, which are recorded as complete in
`PR132_REVIEW_PLAN.md`.

### Questions for Jinyang before resuming

- What concrete workflow should `TreeSequence$variants()` support, especially
  in AlphaSimR?
- Can he provide one or two small executable examples with expected site,
  allele, genotype, sample-order, and missing-data results?
- What returned R object and iteration protocol does he intend? Are both
  `next()` and `next_variant()` required?
- Are the `copy` and deprecated `impute_missing_data` compatibility arguments
  required by downstream code, or should this new R API omit unsupported or
  deprecated compatibility surface?
- Are the low-level iterator functions intended to be public installed C++ API
  or internal implementation details?
- What behavior is intended for `NULL` versus empty `samples` and `alleles`,
  interval bounds, fixed allele mappings, and isolated/missing samples?

### Exact restart point

1. Resolve the questions above and record intentional deviations from Python.
2. Resume at **C++ iterator state and initialization** below.
3. Confirm finalizer and partial-initialization cleanup semantics from the
   upstream C API before changing ownership code.
4. Remove the redundant `ts_sexp` preservation only together with regression
   tests covering garbage collection, iterator lifetime, early abandonment,
   and absence of double-free behavior.
5. Complete decoding/exhaustion and exact-content tests before reviewing the R
   iterator API, documentation, and examples.
6. Run the focused and full completion gates in section 5.

This review covers:

- `rtsk_treeseq_init_variants_iterator()` against `tsk_variant_init()`;
- `rtsk_treeseq_next_variant()` against `tsk_variant_decode()` and
  `tsk_variant_t`;
- `TreeSequence$variants()` against Python `TreeSequence.variants()`.

The goal is C++/C and R/Python parity where practical, safe ownership across
the R/C++ boundary, clear documentation and examples, and focused tests of
returned variant content rather than only iterator shape.

## Review order

1. Low-level C++ iterator state and initialization.
2. Low-level decoding, result conversion, and exhaustion.
3. User-facing R iterator and Python parity.
4. Documentation, examples, NEWS, and quality gates.

## Architecture and usage map

These components are used inside RcppTskit. The user-facing
`TreeSequence$variants()` method calls the low-level initializer and its
returned closures call the low-level next function:

```text
TreeSequence$variants()
        |
        v
rtsk_treeseq_init_variants_iterator()
        |
        |-- creates rtsk_variant_iterator_state_t
        |-- compute_variant_iteration_bounds()
        |       `-- validate_variant_site_index_range()
        |-- calls tsk_variant_init()
        `-- wraps the state in rtsk_variant_iterator_t
                    |
                    v
              R iterator object
                    |
             next_variant()/next()
                    |
                    v
       rtsk_treeseq_next_variant()
                    |
                    |-- checks next_site_id against stop_site_id
                    |-- calls tsk_variant_decode()
                    |-- converts the result to an R-owned list
                    `-- advances next_site_id

When the iterator is garbage-collected:

rtsk_variant_iterator_free()
        |-- calls tsk_variant_free()
        |-- releases tree-sequence lifetime protection
        `-- deletes the iterator state
```

The central connector, omitted easily when reading individual functions, is:

```cpp
using rtsk_variant_iterator_t =
    Rcpp::XPtr<rtsk_variant_iterator_state_t, Rcpp::PreserveStorage,
               rtsk_variant_iterator_free, true>;
```

Component roles:

| Component | Role |
| --- | --- |
| `rtsk_variant_iterator_state_t` | Persistent tree-sequence reference, reusable `tsk_variant_t`, and remaining site-ID interval. |
| `rtsk_variant_iterator_free()` | Finalizer called when the iterator external pointer is garbage-collected. |
| `rtsk_variant_iterator_t` | External-pointer type connecting the state to its finalizer. |
| `compute_variant_iteration_bounds()` | Converts genomic coordinates `[left, right)` to site-ID bounds `[start, stop)`. |
| `validate_variant_site_index_range()` | Checks that `tsk_size_t` site offsets can be represented as `tsk_id_t`. |
| `rtsk_treeseq_init_variants_iterator()` | Creates and initializes persistent state and transfers its ownership to an R external pointer. |
| `rtsk_treeseq_next_variant()` | Decodes one site into an R-owned list, or returns `NULL` at exhaustion. |

### AlphaSimR downstream usage

Jinyang's AlphaSimR `ts` branch uses the R API:

```r
it <- ts$variants()
v <- it$next_variant()
```

See
[`R/makeFoundersFromTs.R`](https://github.com/LynxJinyangii/AlphaSimR/blob/ts/R/makeFoundersFromTs.R#L37).
A search of the branch found no direct calls to
`rtsk_treeseq_init_variants_iterator()`,
`rtsk_treeseq_next_variant()`, the state/bounds helpers, or the test helpers.
AlphaSimR is therefore a downstream consumer of the RcppTskit R API, rather
than the only location where the implementation is used.

This evidence does not establish a downstream need to expose the two
low-level iterator functions in the installed public C++ header. Revisit
whether they should be PUBLIC RcppTskit extensions or INTERNAL implementation
functions before finalising the PR.

### Test-only scaffolding to challenge

The following functions do not participate in normal iteration:

- `test_rtsk_variant_iterator_force_null_first_allele()` uses global mutable
  state and mutates a live tskit variant. Prefer a naturally occurring missing
  allele test if practical.
- `test_rtsk_variant_iterator_set_site_bounds()` deliberately creates invalid
  iterator state to force a decode error that valid public inputs cannot
  normally reach. Decide whether this coverage is valuable enough to retain.
- `test_variant_site_index_range()` exposes an otherwise impractical range
  branch for testing. It is more defensible, but still adds production
  test-only surface solely for coverage.

Review the essential iterator implementation separately from these coverage
devices. If retained, test-only helpers should not be mistaken for part of the
public RcppTskit API.

## 1. C++ iterator state and initialization

### Iterator lifetime and ownership

- [ ] Document `rtsk_variant_iterator_state_t`, its fields, and the invariant
      represented by `variant_initialized`.
- [ ] Confirm the external-pointer finalizer calls `tsk_variant_free()` exactly
      once for every successfully initialized variant.
- [ ] Confirm partial `tsk_variant_init()` failure is cleaned up according to
      the C API contract; do not assume that a failed initialization allocated
      nothing.
- [ ] Confirm `std::unique_ptr` protects every pre-external-pointer error path.
- [x] Determine whether the separate `ts_sexp` preservation is necessary.
      It is redundant: `rtsk_treeseq_t` is an `Rcpp::XPtr` using
      `Rcpp::PreserveStorage`, so the `ts_xptr` member already preserves the
      originating R external pointer and releases it when the state is
      destroyed. `ts_sexp` is otherwise only assigned, manually preserved,
      checked, and manually released; it is never used to access the tree
      sequence or passed to tskit.
- [ ] Remove `ts_sexp`, `R_PreserveObject(ts)`, and the matching
      `R_ReleaseObject()` together. Retain the cleanup order in which
      `tsk_variant_free()` runs before deleting the state and thereby
      destroying `ts_xptr`.
- [ ] Test that iteration remains valid after the original R `TreeSequence`
      reference is removed and garbage collection runs. Add this regression
      test with the `ts_sexp` removal to verify that `ts_xptr` alone provides
      the required lifetime protection.
- [ ] Test abandoning an iterator before exhaustion and exercising garbage
      collection without a crash or double free.

### Samples

- [ ] Verify the distinction between `samples = NULL` and explicit
      `integer()`: `NULL` requests all tree-sequence samples, while
      `integer()` requests zero decoded nodes.
- [ ] Verify sample IDs are copied into tskit-owned iterator storage and do not
      depend on the temporary C++ vector after initialization.
- [ ] Validate R sample input before C++ conversion: ordinary integer IDs,
      missing values, negative IDs, out-of-range IDs, duplicates, ordering,
      non-sample nodes, and empty input.
- [ ] Confirm genotype order follows the requested sample order, including a
      deliberately non-numerical order.
- [ ] Confirm non-sample nodes are accepted, matching Python.

### Alleles

- [ ] Verify whether `tsk_variant_init()` copies fixed allele strings and its
      pointer array; confirm temporary `std::string` storage is safe.
- [ ] Review `NULL` versus `character()` semantics. Python requires at least one
      allele when a fixed mapping is supplied; decide whether empty character
      input should error rather than behave like `NULL`.
- [ ] Validate type, `NA`, duplicate alleles, empty strings, embedded NUL bytes,
      and allele-count limits.
- [ ] Test fixed allele ordering and genotype indices against known content.

### Options and genomic bounds

- [ ] Confirm `isolated_as_missing = TRUE` maps to options `0`, while `FALSE`
      maps to `TSK_ISOLATED_NOT_MISSING`.
- [ ] Validate `isolated_as_missing` as a non-missing logical scalar at the R
      boundary.
- [ ] Compare R defaults with Python's effective defaults, including Python's
      `None` compatibility behavior.
- [ ] Review `left` and `right` validation for type, scalar length, `NA`, `NaN`,
      infinities, negatives, reversed bounds, and values beyond sequence
      length.
- [ ] Confirm half-open interval semantics: first site at or after `left`, last
      site strictly before `right`.
- [ ] Test `left == right`, boundaries with no sites, exact site positions,
      sequence endpoints, and a tree sequence with zero sites.
- [ ] Confirm `lower_bound()` is valid because site positions are sorted, or
      ensure an appropriate error is propagated for invalid input tables.
- [ ] Review the `tsk_size_t` to `tsk_id_t` range check and retain only test
      helpers that exercise otherwise unreachable safety branches.

## 2. C++ decoding and iterator exhaustion

### Decode progression

- [ ] Confirm each site ID is decoded once and in increasing site-table order.
- [ ] Decide whether `next_site_id` should advance before or only after a
      successful `tsk_variant_decode()` call.
- [ ] Confirm exhaustion returns `NULL` repeatedly without decoding or mutating
      state.
- [ ] Test an empty interval, zero-site tree sequence, normal exhaustion, and
      repeated calls after exhaustion.
- [ ] Verify C errors are propagated with useful messages and leave the
      iterator in a documented state.

### Returned variant content

- [ ] Compare the returned R representation with Python `Variant`: site ID,
      position, alleles, genotypes, and missing-data status.
- [ ] Test exact site IDs and positions against site-table rows.
- [ ] Test exact genotype content and confirm genotype values index the returned
      allele vector.
- [ ] Confirm genotype `-1` represents missing data.
- [ ] Confirm `has_missing_data` is exposed as an R logical scalar rather than
      an accidental integer.
- [ ] Confirm allele strings use `allele_lengths`, preserving valid binary-safe
      lengths where R character semantics permit them.
- [ ] Confirm a null C allele pointer is represented as `NA_character_` and is
      covered without relying unnecessarily on global mutable test state.
- [ ] Confirm every returned vector/list owns its R memory and remains unchanged
      after subsequent iterator calls.

## 3. `TreeSequence$variants()`

Current R signature:

```r
variants = function(
  samples = NULL,
  isolated_as_missing = TRUE,
  alleles = NULL,
  impute_missing_data = NULL,
  copy = TRUE,
  left = 0,
  right = NULL
)
```

Upstream Python signature:

```python
variants(
    *, samples=None, isolated_as_missing=None, alleles=None,
    impute_missing_data=None, copy=None, left=None, right=None
)
```

### API and validation

- [ ] Compare argument names, keyword-only behavior, defaults, accepted types,
      and error behavior with Python.
- [ ] Decide whether to retain the already-deprecated
      `impute_missing_data` compatibility argument in this new R API. If
      retained, document and test precedence and warnings precisely.
- [ ] Review `copy`: the R implementation always returns fresh R objects and
      currently rejects `FALSE`; document this intentional deviation or remove
      the unsupported argument before release.
- [ ] Reuse shared validators where appropriate instead of maintaining inline
      validation.
- [ ] Confirm `right = NULL` maps to the sequence length and document `left = 0`
      as the R equivalent of Python's `left = None` default.

### Iterator protocol

- [ ] Decide whether both `next()` and `next_variant()` are useful, and document
      the chosen R iteration convention.
- [ ] Confirm both methods share exactly one iterator state.
- [ ] Confirm retaining either closure keeps the external pointer alive.
- [ ] Consider whether the iterator needs a print method or standard R iterator
      integration; avoid expanding scope unless it materially helps users.
- [ ] Test interleaved calls to `next()` and `next_variant()` and repeated calls
      after exhaustion.

### Documentation and examples

- [ ] Expand the return documentation to describe every variant-list field and
      the genotype-to-allele relationship.
- [ ] Add a concise content example that decodes one variant and uses
      `variant$alleles[variant$genotypes + 1L]`, handling genotype `-1` safely.
- [ ] Document sample order, interval bounds, missing genotypes, fixed alleles,
      and all intentional Python deviations without reproducing the full Python
      manual.
- [ ] Ensure low-level C++ functions have stable C API links, ownership notes,
      executable examples, and documented exhaustion behavior.
- [ ] Update `RcppTskit/NEWS.md` for any user-visible changes.

## 4. Focused test matrix

- [ ] Default iteration returns all sites in order with exact content checks on
      at least one or two known sites.
- [ ] Custom samples preserve requested genotype order, accept a non-sample
      node, and distinguish `NULL` from `integer()`.
- [ ] Fixed alleles produce the expected allele vector and genotype encoding.
- [ ] Missing-data behavior differs correctly between
      `isolated_as_missing = TRUE` and `FALSE`.
- [ ] Intervals are half-open and cover empty and endpoint cases.
- [ ] Returned variants are independent R copies across iterator advancement.
- [ ] Iterator lifetime is safe across garbage collection and early disposal.
- [ ] Exhaustion is stable and repeatedly returns `NULL`.
- [ ] Invalid samples, alleles, logicals, bounds, and compatibility-argument
      combinations produce focused errors.
- [ ] Low-level error and range-check branches are covered where practical.

## 5. Completion gates

- [ ] Regenerate Rcpp exports and roxygen documentation.
- [ ] Review generated diffs rather than editing generated files manually.
- [ ] Run focused variant tests.
- [ ] Run `pre-commit run --all-files`.
- [ ] Run `Rscript -e "setwd('RcppTskit'); devtools::test()"`.
- [ ] Run `Rscript -e "setwd('RcppTskit'); devtools::check()"`.
- [ ] Review the complete variant diff against upstream C and Python APIs.

## Upstream references

- C variant API:
  <https://tskit.dev/tskit/docs/stable/c-api.html#variant-decoding>
- `tsk_variant_init()`:
  <https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_variant_init>
- `tsk_variant_decode()`:
  <https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_variant_decode>
- Python `TreeSequence.variants()`:
  <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.variants>
- Python `Variant`:
  <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.Variant>
