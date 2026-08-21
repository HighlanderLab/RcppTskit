test_that("TreeSequence$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(
    TreeSequence$new(),
    regexp = "Provide a file or an external pointer \\(xptr\\)!"
  )
  expect_error(
    TreeSequence$new(file = "xyz", xptr = "y"),
    regexp = "Provide either a file or an external pointer \\(xptr\\), but not both!"
  )
  expect_error(
    TreeSequence$new(file = 1L),
    regexp = "file must be a character string!"
  )
  expect_error(
    TreeSequence$new(file = "bla", skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_error(
    TreeSequence$new(file = "bla", skip_reference_sequence = 1),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(
    TreeSequence$new(
      file = ts_file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE
    )
  )
  expect_no_error(
    TreeSequence$new(
      file = ts_file,
      skip_tables = TRUE,
      skip_reference_sequence = TRUE
    )
  )
  expect_no_error(TreeSequence$new(ts_file))
  expect_error(
    TreeSequence$new(xptr = 1L),
    regexp = "external pointer \\(xptr\\) must be an object of externalptr class!"
  )
})

test_that("TreeSequence$simplify returns a new tree sequence and optional map", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  nodes_before <- as.integer(ts$num_nodes())
  samples_before <- ts$samples()
  provenances_before <- as.integer(ts$num_provenances())

  simplified <- ts$simplify(samples = 0:3)
  expect_true(is(simplified, "TreeSequence"))
  expect_lt(as.integer(simplified$num_nodes()), nodes_before)
  expect_equal(simplified$samples(), 0:3)
  expect_equal(
    as.integer(simplified$num_provenances()),
    provenances_before + 1L
  )

  expect_equal(as.integer(ts$num_nodes()), nodes_before)
  expect_equal(ts$samples(), samples_before)
  expect_equal(as.integer(ts$num_provenances()), provenances_before)

  mapped <- ts$simplify(samples = 0:3, map_nodes = TRUE)
  expect_named(mapped, c("tree_sequence", "node_map"))
  expect_true(is(mapped$tree_sequence, "TreeSequence"))
  expect_type(mapped$node_map, "integer")
  expect_length(mapped$node_map, nodes_before)
  expect_equal(mapped$node_map[1:4], 0:3)
  expect_true(all(mapped$node_map[-(1:4)] >= -1L))
  expect_true(any(mapped$node_map == -1L))

  without_provenance <- ts$simplify(
    samples = 0:3,
    record_provenance = FALSE
  )
  expect_equal(
    as.integer(without_provenance$num_provenances()),
    provenances_before
  )
})

test_that("TreeSequence$simplify validates and forwards options", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  expect_error(ts$simplify(map_nodes = NA), "map_nodes must be TRUE/FALSE!")
  expect_error(
    ts$simplify(samples = c(0L, 0L)),
    "Duplicate sample|TSK_ERR_DUPLICATE_SAMPLE"
  )
  expect_error(
    ts$simplify(keep_unary = TRUE, keep_unary_in_individuals = TRUE),
    "keep_unary and keep_unary_in_individuals cannot both be TRUE!"
  )

  default <- ts$simplify(samples = 0:3, record_provenance = FALSE)
  keep_unary <- ts$simplify(
    samples = 0:3,
    keep_unary = TRUE,
    record_provenance = FALSE
  )
  expect_gt(as.integer(keep_unary$num_nodes()), as.integer(default$num_nodes()))

  unfiltered_nodes <- ts$simplify(
    samples = 0:3,
    filter_nodes = FALSE,
    map_nodes = TRUE,
    record_provenance = FALSE
  )
  expect_equal(as.integer(unfiltered_nodes$tree_sequence$num_nodes()), 39L)
  expect_equal(unfiltered_nodes$node_map, seq.int(0L, 38L))
})

test_that("TreeSequence$variants() iterates over sites", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  n_sites <- as.integer(ts$num_sites())

  it <- ts$variants()
  seen <- 0L
  repeat {
    v <- it$next_variant()
    if (is.null(v)) {
      break
    }
    seen <- seen + 1L
    expect_equal(
      sort(names(v)),
      c("alleles", "genotypes", "has_missing_data", "position", "site_id")
    )
  }
  expect_equal(seen, n_sites)
})

test_that("TreeSequence$variants() supports interval and samples", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  full_it <- ts$variants()
  first <- full_it$next_variant()
  second <- full_it$next_variant()
  expect_false(is.null(first))
  expect_false(is.null(second))

  it_interval <- ts$variants(
    left = first$position,
    right = second$position + 1e-12
  )
  v1 <- it_interval$next_variant()
  v2 <- it_interval$next_variant()
  v3 <- it_interval$next_variant()
  expect_equal(v1$site_id, first$site_id)
  expect_equal(v2$site_id, second$site_id)
  expect_null(v3)

  it_samples <- ts$variants(samples = c(0L, 1L, 2L))
  v_samples <- it_samples$next_variant()
  expect_length(v_samples$genotypes, 3L)
})

test_that("TreeSequence$variants() validates compatibility args", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  expect_error(ts$variants(copy = NA), "copy must be TRUE/FALSE")
  expect_error(ts$variants(copy = "yes"), "copy must be TRUE/FALSE")
  expect_error(ts$variants(copy = FALSE), "copy = FALSE is not supported yet")
  expect_error(
    ts$variants(impute_missing_data = NA),
    "impute_missing_data must be TRUE/FALSE or NULL"
  )
  expect_error(
    ts$variants(impute_missing_data = "yes"),
    "impute_missing_data must be TRUE/FALSE or NULL"
  )
  expect_warning(
    ts$variants(impute_missing_data = TRUE),
    "impute_missing_data is deprecated"
  )
  expect_error(
    ts$variants(isolated_as_missing = TRUE, impute_missing_data = TRUE),
    "inconsistent"
  )
})

test_that("TreeSequence$samples() returns sample node IDs and supports filters", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  samples <- ts$samples()
  expect_type(samples, "integer")
  expect_length(samples, as.integer(ts$num_samples()))
  expect_true(all(samples >= 0L))
  # We got the sample ID from inst/examples/create_test.trees.{R,py}
  expect_true(all(samples == 0L:15L))

  samples_low <- rtsk_treeseq_get_samples(ts$xptr)
  expect_identical(samples, samples_low)

  expect_error(
    ts$samples(population = -1L),
    regexp = "population must be NULL or a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    ts$samples(population = 0.5),
    regexp = "population must be NULL or a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )

  tc <- ts$dump_tables()
  sample_rows <- lapply(samples, function(id) {
    tc$node_table_get_row(as.integer(id))
  })
  sample_population <- vapply(
    sample_rows,
    function(row) row$population,
    integer(1)
  )
  sample_time <- vapply(sample_rows, function(row) row$time, numeric(1))

  expect_identical(
    ts$samples(population = 0L),
    samples[sample_population == 0L]
  )
  expect_false(is.unsorted(ts$samples(population = 0L)))

  time0 <- sample_time[1]
  tol0 <- 1e-08 + 1e-05 * abs(time0)
  expect_identical(
    ts$samples(time = time0),
    samples[abs(sample_time - time0) <= tol0]
  )
  expect_identical(ts$samples(time = Inf), integer())
  expect_identical(ts$samples(time = -Inf), integer())

  interval_end <- min(sample_time) + 1e-6
  expect_identical(
    ts$samples(time = c(min(sample_time), interval_end)),
    samples[sample_time >= min(sample_time) & sample_time < interval_end]
  )
  expect_false(
    is.unsorted(ts$samples(time = c(min(sample_time), interval_end)))
  )

  expect_error(
    ts$samples(time = c(0, 0)),
    regexp = "time_interval max is less than or equal to min\\."
  )
  expect_error(
    ts$samples(time = c(0, 1, 2)),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
  expect_error(
    ts$samples(time = NA_real_),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
  expect_error(
    ts$samples(time = NaN),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
  expect_error(
    ts$samples(time = 1 + 1i),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
  expect_error(
    ts$samples(time = matrix(c(0, 1), nrow = 1)),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
  expect_error(
    ts$samples(time = array(c(0, 1), dim = c(1, 1, 2))),
    regexp = "time must be either a single value or a pair of values \\(min_time, max_time\\)\\."
  )
})

test_that("rtsk_treeseq_get_samples() safely copies sample IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  zero_samples <- ts$simplify(
    samples = integer(),
    record_provenance = FALSE
  )
  expect_identical(
    rtsk_treeseq_get_samples(zero_samples$xptr),
    integer()
  )

  nonconsecutive_samples <- ts$simplify(
    samples = c(0L, 2L),
    filter_nodes = FALSE,
    record_provenance = FALSE
  )
  expect_identical(
    rtsk_treeseq_get_samples(nonconsecutive_samples$xptr),
    c(0L, 2L)
  )

  copied_samples <- rtsk_treeseq_get_samples(nonconsecutive_samples$xptr)
  copied_samples[[1L]] <- 999L
  expect_identical(
    rtsk_treeseq_get_samples(nonconsecutive_samples$xptr),
    c(0L, 2L)
  )
})

test_that("sample-node data helper returns aligned R-owned vectors", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  sample_data <- rtsk_treeseq_get_sample_node_data(ts$xptr)
  samples <- rtsk_treeseq_get_samples(ts$xptr)
  tc <- ts$dump_tables()
  sample_rows <- lapply(samples, tc$node_table_get_row)

  expect_named(sample_data, c("samples", "population", "time"))
  expect_type(sample_data$samples, "integer")
  expect_type(sample_data$population, "integer")
  expect_type(sample_data$time, "double")
  expect_length(sample_data$population, length(sample_data$samples))
  expect_length(sample_data$time, length(sample_data$samples))
  expect_identical(sample_data$samples, samples)
  expect_identical(
    sample_data$population,
    vapply(sample_rows, function(row) row$population, integer(1))
  )
  expect_identical(
    sample_data$time,
    vapply(sample_rows, function(row) row$time, numeric(1))
  )

  nonconsecutive_samples <- ts$simplify(
    samples = c(0L, 2L),
    filter_nodes = FALSE,
    record_provenance = FALSE
  )
  nonconsecutive_data <- rtsk_treeseq_get_sample_node_data(
    nonconsecutive_samples$xptr
  )
  expect_identical(nonconsecutive_data$samples, c(0L, 2L))

  zero_samples <- ts$simplify(
    samples = integer(),
    record_provenance = FALSE
  )
  expect_identical(
    rtsk_treeseq_get_sample_node_data(zero_samples$xptr),
    list(samples = integer(), population = integer(), time = numeric())
  )

  sample_data$samples[[1L]] <- 999L
  sample_data$population[[1L]] <- 999L
  sample_data$time[[1L]] <- 999
  expect_false(identical(
    rtsk_treeseq_get_sample_node_data(ts$xptr),
    sample_data
  ))
})
