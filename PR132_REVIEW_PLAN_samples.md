# PR #132 Review: Tree-Sequence Sample Access

## Status

Review complete for the agreed scope. The low-level wrapper, single-call helper,
and user-facing filtering method have been reviewed and tested.

This file records the review of:

- `rtsk_treeseq_get_samples()` against `tsk_treeseq_get_samples()`;
- `TreeSequence$samples()` against Python `TreeSequence.samples()`.

The direct low-level wrapper now guards the copy for a zero-sample tree
sequence. Focused tests cover empty and nonconsecutive sample sets and confirm
that the returned R vector is an independent copy.

The review distinguishes correctness and API-parity fixes from optional
optimisation. The current per-sample filtering path is sufficiently expensive
to treat its replacement as part of this review rather than as a later
optimisation.

## Low-level C++ wrapper

Current implementation:

```cpp
Rcpp::IntegerVector rtsk_treeseq_get_samples(SEXP ts) {
  rtsk_treeseq_t ts_xptr(ts);
  const tsk_id_t *samples = tsk_treeseq_get_samples(ts_xptr);
  const tsk_size_t num_samples = tsk_treeseq_get_num_samples(ts_xptr);
  Rcpp::IntegerVector out(num_samples);
  if (num_samples > 0) {
    std::copy_n(samples, num_samples, out.begin());
  }
  return out;
}
```

The upstream C function returns a borrowed pointer owned by the tree sequence.
The wrapper correctly copies those IDs into R-owned memory.

### Suggested changes

- [x] Explicitly guard the copy when there are no samples:

  ```cpp
  Rcpp::IntegerVector out(num_samples);
  if (num_samples > 0) {
    std::copy_n(samples, num_samples, out.begin());
  }
  ```

- [x] Change the C API documentation link from `latest` to `stable`.
- [x] State that the returned vector is an R-owned copy of the borrowed C
      array, and that IDs are returned in numerical order.

### Suggested low-level tests

- [x] A tree sequence with no samples returns `integer()`.
- [x] Nonconsecutive sample IDs are returned exactly and in order.
- [x] The returned R vector is an independent copy of tskit-owned memory.

For copy independence:

```r
samples1 <- rtsk_treeseq_get_samples(ts$xptr)
samples1[1] <- 999L
samples2 <- rtsk_treeseq_get_samples(ts$xptr)
expect_false(samples2[1] == 999L)
```

## User-facing R method

Current signature:

```r
samples = function(population = NULL, time = NULL)
```

Upstream Python signature:

```python
samples(population=None, *, population_id=None, time=None)
```

## Finding 1: population validation

The R method calls:

```r
validate_row_index(population, "population", allow_null = TRUE)
```

This intentionally rejects `-1L`. Although Python filters by direct equality
and therefore permits `population=-1`, RcppTskit consistently treats public R
population IDs as non-negative, 0-based IDs. The value `-1`/`TSK_NULL` is
accepted only by methods that store an unknown population reference, not by a
method requesting an actual population ID. `NULL` means that no population
filter is applied.

### Decision

- [x] Retain non-negative row-index validation for `population`.
- [x] Document the intentional RcppTskit convention that negative population
      IDs are unsupported.

## Finding 2: infinite scalar time

The former comparison was:

```r
tol <- 1e-08 + 1e-05 * abs(time_num)
keep <- keep & (abs(sample_time - time_num) <= tol)
```

For `time = Inf`, both sides can become `Inf`, incorrectly selecting finite
sample times. Python `numpy.isclose(finite_value, Inf)` returns `FALSE`.

### Implemented change

- [x] Implement an internal vectorised comparison using NumPy's default
      `isclose()` tolerances and explicit infinity handling.

  The method now calls
  `numeric_values_are_close(sample_time, time)`, which implements the default
  NumPy tolerances and handles equal infinities without matching finite values.

- [x] Reject R `NA` and `NaN` through the shared argument validator so missing
      values cannot produce missing IDs in the result. This is an intentional R
      safety convention; Python accepts `NaN` and returns no matches.
- [x] Test scalar `Inf` and `-Inf` matching, and rejection of `NA_real_` and
      `NaN`.

The former `is.numeric()` check also accepted complex values and numeric arrays
or matrices. `TreeSequence$samples()` now uses the shared optional
numeric-vector validator with permitted lengths one and two. The validator
accepts ordinary integer or double vectors and rejects missing values and
shaped objects before the C++ helper is called.

## Finding 3: filtering performance

For either filter, the current implementation:

1. copies the entire table collection using `dump_tables()`;
2. crosses the R/C++ boundary once for every sample;
3. allocates one row list for every sample;
4. retrieves metadata and node fields that filtering does not use.

This is likely to scale poorly for large tree sequences.

Python instead indexes directly into the node population and time columns.

### Implemented design

- [x] Add a separate internal C++ helper that retrieves sample node IDs,
      populations, and times in a single call.
- [x] Keep `rtsk_treeseq_get_samples()` as a faithful wrapper of the C API;
      do not overload it with Python-level filtering semantics.
- [x] Use the helper in `TreeSequence$samples()` to filter vectors without
      copying all tables or constructing row lists.

The internal interface is:

```cpp
Rcpp::List rtsk_treeseq_get_sample_node_data(SEXP ts);
```

returning:

```r
list(
  samples = integer_vector,
  population = integer_vector,
  time = numeric_vector
)
```

The helper reads directly from the tree sequence's read-only node table in one
C++ call. It does not copy the full table collection or construct per-node row
lists. The public `rtsk_treeseq_get_samples()` remains the direct C API wrapper
and has not acquired filtering arguments. The helper is Rcpp-exported for
internal package use but intentionally omitted from `RcppTskit_public.hpp`
because it has no direct tskit C API counterpart.

## Finding 4: deprecated `population_id` alias

Python retains `population_id` as a deprecated alias for `population`.

Because `TreeSequence$samples()` is new in RcppTskit, the current
recommendation is not to introduce an already-deprecated argument. This should
be recorded as an intentional omission. Deprecated aliases copied elsewhere in
PR #132 should be reconsidered during their respective reviews.

- [x] Omit `population_id` because this is a new R API and the Python alias is
      already deprecated.
- [x] Record this intentional omission in the main review plan.

## Suggested R-method tests

- [ ] Combined `population` and `time` filters.
- [ ] A population with no matching samples.
- [x] A negative population ID is rejected.
- [x] Scalar-time matching and tolerance behavior.
- [x] `Inf`, `-Inf`, `NA`, and `NaN` time inputs.
- [x] Time-interval filtering with an included lower bound.
- [ ] Time-interval upper bound is excluded.
- [ ] Empty filtered results remain `integer()`.
- [x] Filtered IDs remain in numerical order.
- [x] Complex, matrix, and array `time` inputs are rejected rather than
      flattened or coerced with loss.
- [ ] A tree sequence containing no samples.
- [ ] On a tree sequence containing no samples, exercise population filtering
      and confirm that the internal empty population vector branch returns
      `integer(0)` and the public result remains `integer(0)`.
- [ ] On a tree sequence containing no samples, exercise time filtering and
      confirm that the internal empty time vector branch returns `numeric(0)`
      and the public result remains `integer(0)`.

## Recommended implementation order

1. [x] Harden and test the direct low-level `rtsk_treeseq_get_samples()` wrapper.
2. [x] Implement the single-call internal C++ sample-node-data helper.
3. [x] Switch `TreeSequence$samples()` to that helper for filtered calls.
4. [x] Correct population and time validation and filtering semantics.
5. [x] Complete the agreed content tests and concise documentation. Additional
   boundary combinations are intentionally deferred because the current test
   fixture does not expose them clearly.

## Upstream references

- C API: <https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_samples>
- Python API: <https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.samples>
- Python implementation:
  <https://tskit.dev/tskit/docs/stable/_modules/tskit/trees.html>
