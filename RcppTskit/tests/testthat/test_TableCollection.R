test_that("TableCollection$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(
    TableCollection$new(),
    regexp = "Provide a file or an external pointer \\(xptr\\)!"
  )
  expect_error(
    TableCollection$new(file = "xyz", xptr = "y"),
    regexp = "Provide either a file or an external pointer \\(xptr\\), but not both!"
  )
  expect_error(
    TableCollection$new(file = 1L),
    regexp = "file must be a character string!"
  )
  expect_error(
    TableCollection$new(file = "bla", skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_error(
    TableCollection$new(file = "bla", skip_reference_sequence = 1),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(
    TableCollection$new(
      file = ts_file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE
    )
  )
  expect_no_error(
    TableCollection$new(
      file = ts_file,
      skip_tables = TRUE,
      skip_reference_sequence = TRUE
    )
  )
  expect_no_error(TableCollection$new(ts_file))
  expect_error(
    TableCollection$new(xptr = 1L),
    regexp = "external pointer \\(xptr\\) must be an object of externalptr class!"
  )
})

test_that("TableCollection and TreeSequence round-trip works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  test_trees_file_uuid <- "79ec383f-a57d-b44f-2a5c-f0feecbbcb32"
  ts_xptr <- rtsk_treeseq_load(ts_file)

  # ---- Integer bitmask of tskit flags ----

  # See rtsk_treeseq_copy_tables() and rtsk_treeseq_init() documentation
  unsupported_options <- bitwShiftL(1L, 27)
  supported_copy_option <- bitwShiftL(1L, 0)
  supported_init_options <- bitwOr(bitwShiftL(1L, 0), bitwShiftL(1L, 1))
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = -1),
    regexp = "rtsk_treeseq_copy_tables does not support negative options"
  )
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = bitwShiftL(1L, 30)),
    regexp = "does not support TSK_NO_INIT"
  )
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = unsupported_options),
    regexp = "only supports copy option TSK_COPY_FILE_UUID"
  )
  expect_true(is(
    rtsk_treeseq_copy_tables(ts_xptr, options = supported_copy_option),
    "externalptr"
  ))

  # ---- ts_xptr --> tc_xptr --> ts_xptr ----

  tc_xptr <- rtsk_treeseq_copy_tables(ts_xptr)
  expect_true(is(tc_xptr, "externalptr"))
  p <- rtsk_table_collection_print(tc_xptr)
  expect_equal(
    p,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "has_reference_sequence",
          "time_units",
          "has_metadata",
          "file_uuid",
          "has_index"
        ),
        value = as.character(c(
          100,
          FALSE,
          "generations",
          FALSE,
          NA_character_,
          TRUE
        ))
      ),
      tables = data.frame(
        table = c(
          "provenances",
          "populations",
          "migrations",
          "individuals",
          "nodes",
          "edges",
          "sites",
          "mutations"
        ),
        number = as.character(c(2, 1, 0, 8, 39, 59, 25, 30)),
        has_metadata = as.character(c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        ))
      )
    )
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = -1),
    regexp = "rtsk_treeseq_init does not support negative options"
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = bitwShiftL(1L, 28)),
    regexp = "does not support TSK_TAKE_OWNERSHIP"
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = unsupported_options),
    regexp = "only supports init options"
  )
  expect_true(is(
    rtsk_treeseq_init(tc_xptr, options = supported_init_options),
    "externalptr"
  ))
  ts_xptr2 <- rtsk_treeseq_init(tc_xptr)
  p_ts_xptr <- rtsk_treeseq_print(ts_xptr)
  p_ts_xptr2 <- rtsk_treeseq_print(ts_xptr2)
  i_file_uuid <- p_ts_xptr$ts$property == "file_uuid"
  p_ts_xptr$ts$value[i_file_uuid] <- NA_character_
  p_ts_xptr2$ts$value[p_ts_xptr2$ts$property == "file_uuid"] <- NA_character_
  expect_equal(p_ts_xptr, p_ts_xptr2)

  # ---- ts --> tc --> ts ----

  ts <- ts_load(ts_file)
  expect_error(
    ts$dump_tables(options = "bla"),
    regexp = "unused argument"
  )
  expect_no_error(ts$dump_tables())

  tc <- ts$dump_tables()
  expect_true(is(tc, "TableCollection"))
  # jarl-ignore implicit_assignment:  it's just a test
  tmp <- capture.output(p <- tc$print())
  expect_equal(
    p,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "has_reference_sequence",
          "time_units",
          "has_metadata",
          "file_uuid",
          "has_index"
        ),
        value = as.character(c(
          100,
          FALSE,
          "generations",
          FALSE,
          NA_character_,
          TRUE
        ))
      ),
      tables = data.frame(
        table = c(
          "provenances",
          "populations",
          "migrations",
          "individuals",
          "nodes",
          "edges",
          "sites",
          "mutations"
        ),
        number = as.character(c(2, 1, 0, 8, 39, 59, 25, 30)),
        has_metadata = as.character(c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        ))
      )
    )
  )

  expect_error(
    tc$tree_sequence(options = "bla"),
    regexp = "unused argument"
  )
  expect_no_error(tc$tree_sequence())

  ts2 <- tc$tree_sequence()
  expect_true(is(ts2, "TreeSequence"))
  # jarl-ignore implicit_assignment: it's just a test
  tmp <- capture.output(ts_print <- ts$print())
  # jarl-ignore implicit_assignment: it's just a test
  tmp <- capture.output(ts2_print <- ts2$print())
  i_file_uuid <- ts_print$ts$property == "file_uuid"
  ts_print$ts$value[i_file_uuid] <- NA_character_
  ts2_print$ts$value[ts2_print$ts$property == "file_uuid"] <- NA_character_
  expect_equal(ts_print, ts2_print)

  # Edge cases
  expect_error(
    test_rtsk_treeseq_copy_tables_forced_error(ts_xptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(rtsk_treeseq_copy_tables(ts_xptr), "externalptr"))

  expect_error(
    test_rtsk_treeseq_init_forced_error(tc_xptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(rtsk_treeseq_init(tc_xptr), "externalptr"))

  expect_error(
    test_rtsk_table_collection_build_index_forced_error(tc_xptr),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
})

test_that("TableCollection index lifecycle and tree_sequence index handling works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  tc <- ts$dump_tables()
  tc_xptr <- tc$xptr
  build_index_option <- bitwShiftL(1L, 0)

  expect_error(rtsk_table_collection_build_index())
  expect_error(rtsk_table_collection_build_index(tc))
  expect_error(rtsk_table_collection_drop_index())
  expect_error(rtsk_table_collection_drop_index(tc))

  expect_true(tc$has_index())
  expect_no_error(tc$drop_index())
  expect_false(tc$has_index())

  expect_error(
    rtsk_treeseq_init(tc_xptr, options = 0L),
    regexp = "TSK_ERR_TABLES_NOT_INDEXED"
  )
  expect_true(is(
    rtsk_treeseq_init(tc_xptr, options = build_index_option),
    "externalptr"
  ))
  # rtsk_treeseq_init() builds indexes in an internal ts, not in tc itself,
  # so the tc in this environment will not have indexes here
  expect_false(tc$has_index())
  ts2 <- tc$tree_sequence()
  expect_true(is(ts2, "TreeSequence"))
  expect_true(tc$has_index())

  expect_no_error(tc$drop_index())
  expect_false(tc$has_index())
  expect_no_error(tc$build_index())
  expect_true(tc$has_index())
})

test_that("TableCollection$sort validates inputs and sorts a non-sorted example", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  expect_error(
    rtsk_table_collection_sort(tc_xptr, start_edges = -1L),
    regexp = "start offsets must be non-negative"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, start_sites = -1L),
    regexp = "start offsets must be non-negative"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, start_mutations = -1L),
    regexp = "start offsets must be non-negative"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, options = -1L),
    regexp = "does not support negative options"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, options = 1L),
    regexp = "only supports options"
  )

  expect_error(
    tc$sort(edge_start = NA_integer_),
    regexp = "edge_start must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$sort(edge_start = -1L),
    regexp = "edge_start must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$sort(site_start = NA_integer_),
    regexp = "site_start must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$sort(mutation_start = NA_integer_),
    regexp = "mutation_start must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$sort(edge_start = 0.5),
    regexp = "edge_start must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$sort(site_start = 1L),
    regexp = "Sort offset not supported|site_start and mutation_start must be 0|TSK_ERR_SORT_OFFSET_NOT_SUPPORTED"
  )
  expect_error(
    tc$sort(edge_start = as.integer(tc$num_edges()) + 1L),
    regexp = "Edge out of bounds|TSK_ERR_EDGE_OUT_OF_BOUNDS"
  )
  expect_invisible(tc$sort())
  expect_no_error(tc$sort(
    edge_start = 0,
    site_start = 0,
    mutation_start = 0
  ))
  expect_no_error(tc$sort(
    edge_start = as.integer(tc$num_edges()),
    site_start = as.integer(tc$num_sites()),
    mutation_start = as.integer(tc$num_mutations())
  ))

  tc$build_index()
  expect_true(tc$has_index())
  tc$sort()
  expect_false(tc$has_index())
  expect_no_error(tc$sort(
    edge_start = 0L,
    site_start = 0L,
    mutation_start = 0L
  ))

  unsorted_file <- system.file(
    "examples/test_unsorted.trees",
    package = "RcppTskit"
  )
  tc_unsorted <- tc_load(unsorted_file)
  n_sites <- as.integer(tc_unsorted$num_sites())
  expect_true(n_sites >= 2L)

  last_pos <- tc_unsorted$site_table_get_row(n_sites - 1L)$position
  prev_pos <- tc_unsorted$site_table_get_row(n_sites - 2L)$position
  expect_lt(last_pos, prev_pos)

  expect_error(
    tc_unsorted$tree_sequence(),
    regexp = "TSK_ERR_UNSORTED_SITES|strictly increasing"
  )

  expect_no_error(tc_unsorted$sort())

  site_positions <- vapply(
    seq.int(0L, n_sites - 1L),
    function(i) {
      tc_unsorted$site_table_get_row(i)$position
    },
    numeric(1)
  )
  expect_true(all(diff(site_positions) > 0))

  expect_no_error(tc_unsorted$tree_sequence())
  ts_sorted <- tc_unsorted$tree_sequence()
  expect_true(is(ts_sorted, "TreeSequence"))
})

test_that("TableCollection$sort forwards edge_start and sorts the edge suffix", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc <- tc_load(ts_file)
  edge_start <- as.integer(tc$num_edges())
  prefix_before <- lapply(
    seq.int(0L, edge_start - 1L),
    tc$edge_table_get_row
  )

  child_a <- tc$node_table_add_row(time = 0)
  child_b <- tc$node_table_add_row(time = 0)
  parent <- tc$node_table_add_row(time = 100)
  tc$edge_table_add_row(
    left = 0,
    right = tc$sequence_length(),
    parent = parent,
    child = child_b
  )
  tc$edge_table_add_row(
    left = 0,
    right = tc$sequence_length(),
    parent = parent,
    child = child_a
  )

  expect_equal(
    vapply(
      edge_start:(edge_start + 1L),
      function(i) {
        tc$edge_table_get_row(i)$child
      },
      integer(1)
    ),
    c(child_b, child_a)
  )

  tc$sort(edge_start = edge_start)

  prefix_after <- lapply(
    seq.int(0L, edge_start - 1L),
    tc$edge_table_get_row
  )
  expect_equal(prefix_after, prefix_before)
  expect_equal(
    vapply(
      edge_start:(edge_start + 1L),
      function(i) {
        tc$edge_table_get_row(i)$child
      },
      integer(1)
    ),
    c(child_a, child_b)
  )
})

test_that("TableCollection$sort can skip site and mutation sorting together", {
  unsorted_file <- system.file(
    "examples/test_unsorted.trees",
    package = "RcppTskit"
  )
  tc <- tc_load(unsorted_file)
  num_sites <- as.integer(tc$num_sites())
  num_mutations <- as.integer(tc$num_mutations())
  sites_before <- lapply(
    seq.int(0L, num_sites - 1L),
    tc$site_table_get_row
  )
  mutations_before <- lapply(
    seq.int(0L, num_mutations - 1L),
    tc$mutation_table_get_row
  )

  expect_gt(
    sites_before[[num_sites - 1L]]$position,
    sites_before[[num_sites]]$position
  )

  tc$sort(
    edge_start = as.integer(tc$num_edges()),
    site_start = num_sites,
    mutation_start = num_mutations
  )

  sites_after <- lapply(
    seq.int(0L, num_sites - 1L),
    tc$site_table_get_row
  )
  mutations_after <- lapply(
    seq.int(0L, num_mutations - 1L),
    tc$mutation_table_get_row
  )
  expect_equal(sites_after, sites_before)
  expect_equal(mutations_after, mutations_before)
})

test_that("rtsk_table_collection_simplify validates options and returns node map", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  n_nodes_before <- as.integer(rtsk_table_collection_get_num_nodes(tc_xptr))

  expect_error(
    rtsk_table_collection_simplify(tc_xptr, options = -1L),
    regexp = "rtsk_table_collection_simplify does not support negative options"
  )
  expect_error(
    rtsk_table_collection_simplify(tc_xptr, options = bitwShiftL(1L, 30)),
    regexp = "rtsk_table_collection_simplify only supports options"
  )
  expect_error(
    rtsk_table_collection_simplify(
      rtsk_table_collection_load(ts_file),
      samples = -1L
    ),
    regexp = "Node out of bounds|TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_table_collection_simplify(
      rtsk_table_collection_load(ts_file),
      samples = c(0L, 0L)
    ),
    regexp = "Duplicate sample|TSK_ERR_DUPLICATE_SAMPLE"
  )

  node_map <- rtsk_table_collection_simplify(
    tc = tc_xptr,
    samples = c(0L, 1L, 2L, 3L),
    options = 0L
  )
  expect_type(node_map, "integer")
  expect_length(node_map, n_nodes_before)
  expect_equal(node_map[c(1L, 2L, 3L, 4L)], 0:3)
  expect_false(rtsk_table_collection_has_index(tc_xptr))

  tc_xptr_empty <- rtsk_table_collection_load(ts_file)
  n_nodes_before_empty <- as.integer(rtsk_table_collection_get_num_nodes(
    tc_xptr_empty
  ))
  node_map_empty <- rtsk_table_collection_simplify(
    tc = tc_xptr_empty,
    samples = integer(),
    options = 0L
  )
  expect_length(node_map_empty, n_nodes_before_empty)
  expect_true(all(node_map_empty == -1L))
  expect_equal(
    as.integer(rtsk_table_collection_get_num_nodes(tc_xptr_empty)),
    0L
  )

  tc_null <- rtsk_table_collection_load(ts_file)
  tc_explicit <- rtsk_table_collection_load(ts_file)
  sample_ids <- which(vapply(
    seq.int(0L, n_nodes_before - 1L),
    function(i) {
      bitwAnd(rtsk_node_table_get_row(tc_explicit, i)$flags, 1L) != 0L
    },
    logical(1)
  )) -
    1L
  expect_equal(
    rtsk_table_collection_simplify(tc_null),
    rtsk_table_collection_simplify(tc_explicit, samples = sample_ids)
  )
})

test_that("TableCollection$simplify follows Python-style argument semantics", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc <- tc_load(ts_file)
  n_nodes_before <- as.integer(tc$num_nodes())
  n_provenances_before <- as.integer(tc$num_provenances())

  expect_error(
    tc$simplify(samples = c(0L, NA_integer_)),
    regexp = "samples must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  expect_error(
    tc$simplify(filter_nodes = "yes"),
    regexp = "filter_nodes must be TRUE/FALSE!"
  )
  tc_keep_sites <- tc_load(ts_file)
  expect_no_error(tc_keep_sites$simplify(
    samples = c(0L, 1L, 2L, 3L),
    filter_sites = FALSE,
    record_provenance = FALSE
  ))
  expect_equal(as.integer(tc_keep_sites$num_sites()), 25L)
  expect_error(
    tc$simplify(keep_unary = TRUE, keep_unary_in_individuals = TRUE),
    regexp = "keep_unary and keep_unary_in_individuals cannot both be TRUE!"
  )

  node_map <- tc$simplify(samples = c(0L, 1L, 2L, 3L))
  expect_type(node_map, "integer")
  expect_length(node_map, n_nodes_before)
  expect_equal(node_map[c(1L, 2L, 3L, 4L)], 0:3)
  expect_true(as.integer(tc$num_nodes()) < n_nodes_before)
  expect_false(tc$has_index())
  expect_equal(as.integer(tc$num_provenances()), n_provenances_before + 1L)
  provenance <- tc$provenance_table_get_row(
    as.integer(tc$num_provenances()) - 1L
  )$record
  expect_match(provenance, '^\\{"schema_version":"1.0.0"')
  expect_match(provenance, '"command":"simplify"', fixed = TRUE)
  expect_match(provenance, '"samples":[0,1,2,3]', fixed = TRUE)
  expect_match(provenance, '"filter_sites":true', fixed = TRUE)
  expect_match(provenance, '"environment":{}', fixed = TRUE)

  tc_null_samples <- tc_load(ts_file)
  tc_null_samples$simplify()
  null_samples_provenance <- tc_null_samples$provenance_table_get_row(
    as.integer(tc_null_samples$num_provenances()) - 1L
  )$record
  expect_match(null_samples_provenance, '"samples":null', fixed = TRUE)

  tc_no_provenance <- tc_load(ts_file)
  n_provenances_before_no_prov <- as.integer(tc_no_provenance$num_provenances())
  expect_no_error(tc_no_provenance$simplify(
    samples = c(0L, 1L, 2L, 3L),
    record_provenance = FALSE
  ))
  expect_equal(
    as.integer(tc_no_provenance$num_provenances()),
    n_provenances_before_no_prov
  )
})

test_that("TableCollection$simplify options have their upstream semantics", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  samples <- 0:3

  simplify_fresh <- function(...) {
    tc <- tc_load(ts_file)
    node_map <- tc$simplify(
      samples = samples,
      record_provenance = FALSE,
      ...
    )
    list(tc = tc, node_map = node_map)
  }

  default <- simplify_fresh()
  keep_unary <- simplify_fresh(keep_unary = TRUE)
  expect_gt(
    as.integer(keep_unary$tc$num_nodes()),
    as.integer(default$tc$num_nodes())
  )
  expect_gt(
    as.integer(keep_unary$tc$num_edges()),
    as.integer(default$tc$num_edges())
  )

  keep_roots <- simplify_fresh(keep_input_roots = TRUE)
  expect_gt(
    as.integer(keep_roots$tc$num_nodes()),
    as.integer(default$tc$num_nodes())
  )

  keep_individuals <- simplify_fresh(filter_individuals = FALSE)
  expect_equal(as.integer(keep_individuals$tc$num_individuals()), 8L)
  expect_gt(
    as.integer(keep_individuals$tc$num_individuals()),
    as.integer(default$tc$num_individuals())
  )

  filtered_populations <- tc_load(ts_file)
  filtered_populations$population_table_add_row(metadata = "unreferenced")
  filtered_populations$simplify(
    samples = samples,
    record_provenance = FALSE
  )
  kept_populations <- tc_load(ts_file)
  kept_populations$population_table_add_row(metadata = "unreferenced")
  kept_populations$simplify(
    samples = samples,
    filter_populations = FALSE,
    record_provenance = FALSE
  )
  expect_equal(as.integer(filtered_populations$num_populations()), 1L)
  expect_equal(as.integer(kept_populations$num_populations()), 2L)

  all_samples <- tc_load(ts_file)
  all_sample_ids <- which(vapply(
    seq.int(0L, as.integer(all_samples$num_nodes()) - 1L),
    function(i) {
      bitwAnd(all_samples$node_table_get_row(i)$flags, 1L) != 0L
    },
    logical(1)
  )) -
    1L
  all_samples$simplify(
    samples = all_sample_ids,
    record_provenance = FALSE
  )
  reduced <- tc_load(ts_file)
  reduced$simplify(
    samples = all_sample_ids,
    reduce_to_site_topology = TRUE,
    record_provenance = FALSE
  )
  expect_lt(
    as.integer(reduced$num_edges()),
    as.integer(all_samples$num_edges())
  )

  no_node_filter <- simplify_fresh(filter_nodes = FALSE)
  expect_equal(as.integer(no_node_filter$tc$num_nodes()), 39L)
  expect_equal(no_node_filter$node_map, seq.int(0L, 38L))

  unchanged_flags <- tc_load(ts_file)
  flags_before <- vapply(
    seq.int(0L, as.integer(unchanged_flags$num_nodes()) - 1L),
    function(i) unchanged_flags$node_table_get_row(i)$flags,
    integer(1)
  )
  unchanged_flags$simplify(
    samples = 16L,
    filter_nodes = FALSE,
    update_sample_flags = FALSE,
    record_provenance = FALSE
  )
  flags_after <- vapply(
    seq.int(0L, as.integer(unchanged_flags$num_nodes()) - 1L),
    function(i) unchanged_flags$node_table_get_row(i)$flags,
    integer(1)
  )
  expect_equal(flags_after, flags_before)

  make_individual_unary_path <- function() {
    tc <- tc_load(ts_file)
    individual <- tc$individual_table_add_row()
    child <- tc$node_table_add_row(time = 0)
    unary <- tc$node_table_add_row(time = 100, individual = individual)
    root <- tc$node_table_add_row(time = 101)
    tc$edge_table_add_row(
      left = 0,
      right = tc$sequence_length(),
      parent = unary,
      child = child
    )
    tc$edge_table_add_row(
      left = 0,
      right = tc$sequence_length(),
      parent = root,
      child = unary
    )
    tc$sort()
    list(tc = tc, child = child)
  }
  collapsed_path <- make_individual_unary_path()
  collapsed_path$tc$simplify(
    samples = collapsed_path$child,
    keep_input_roots = TRUE,
    record_provenance = FALSE
  )
  retained_path <- make_individual_unary_path()
  retained_path$tc$simplify(
    samples = retained_path$child,
    keep_input_roots = TRUE,
    keep_unary_in_individuals = TRUE,
    record_provenance = FALSE
  )
  expect_equal(as.integer(collapsed_path$tc$num_nodes()), 2L)
  expect_equal(as.integer(retained_path$tc$num_nodes()), 3L)
})

test_that("individual_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_individuals(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$individuals

  expect_error(
    rtsk_individual_table_add_row(tc_xptr, flags = -1L),
    regexp = "rtsk_individual_table_add_row does not support negative flags"
  )

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = .Machine$integer.max,
    location = c(1.25, -2.5),
    parents = c(0L, 1L),
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_individual_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      flags = .Machine$integer.max,
      location = c(1.25, -2.5),
      parents = c(0L, 1L),
      metadata = binary_metadata,
      nodes = integer()
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_individuals(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_individuals()
  new_id_method <- tc$individual_table_add_row(
    flags = as.numeric(.Machine$integer.max)
  )
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_identical(
    tc$individual_table_get_row(new_id_method)$flags,
    .Machine$integer.max
  )
  expect_equal(
    as.integer(tc$num_individuals()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_individuals(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals)

  # Defaults map to NULL in the generated R wrapper and should be accepted.
  id0 <- rtsk_individual_table_add_row(tc_xptr)
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_individuals(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals),
    m0
  )

  # Explicit NULL should also be accepted and behave like empty vectors.
  id1 <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    location = NULL,
    parents = NULL,
    metadata = NULL
  )
  expect_equal(id1, n0 + 1L)

  # Parent IDs are provided as integer vectors and should be accepted.
  id2 <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    parents = c(id0, id1),
    location = numeric(),
    metadata = raw()
  )
  expect_equal(id2, n0 + 2L)

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_individuals())
  expect_no_error(
    tc$individual_table_add_row(
      flags = 0L,
      location = NULL,
      parents = c(id1, id2),
      metadata = NULL
    )
  )
  expect_no_error(
    tc$individual_table_add_row(
      flags = 0,
      location = NULL,
      parents = as.numeric(c(id1, id2)),
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_individuals()), n_before_method + 2L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$individuals
  )
  expect_no_warning(tc$individual_table_add_row(metadata = "abc"))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$individuals),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$individuals
  )
  expect_no_error(tc$individual_table_add_row(metadata = charToRaw("xyz")))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$individuals),
    m_before_raw + 3L
  )
  expect_error(
    tc$individual_table_add_row(flags = NULL),
    regexp = "flags cannot be NULL"
  )
  invalid_flags <- list(
    NA_integer_,
    -1L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (flags in invalid_flags) {
    expect_error(
      tc$individual_table_add_row(flags = flags),
      regexp = "flags must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$individual_table_add_row(location = c(1, NA_real_)),
    regexp = "location must be NULL or a numeric vector with no NA values!"
  )
  expect_error(
    tc$individual_table_add_row(parents = c(NA_integer_)),
    regexp = "parents must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  expect_error(
    tc$individual_table_add_row(parents = c(0.5, 1)),
    regexp = "parents must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  expect_error(
    test_rtsk_individual_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )

  expect_error(
    tc$individual_table_add_row(metadata = c("a", "b")),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$individual_table_add_row(metadata = NA_character_),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$individual_table_add_row(metadata = 1L),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
})

test_that("node_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_nodes(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$nodes

  expect_error(
    rtsk_node_table_add_row(tc_xptr, flags = -1L),
    regexp = "rtsk_node_table_add_row does not support negative flags"
  )

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_node_table_add_row(
    tc = tc_xptr,
    flags = .Machine$integer.max,
    time = -1.25,
    population = 0L,
    individual = 0L,
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_node_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      flags = .Machine$integer.max,
      time = -1.25,
      population = 0L,
      individual = 0L,
      metadata = binary_metadata
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_nodes()
  new_id_method <- tc$node_table_add_row(
    flags = as.numeric(.Machine$integer.max),
    population = 0,
    individual = 0
  )
  expect_identical(new_id_method, as.integer(n_before_method))
  expect_identical(
    tc$node_table_get_row(new_id_method),
    list(
      id = new_id_method,
      flags = .Machine$integer.max,
      time = 0,
      population = 0L,
      individual = 0L,
      metadata = raw()
    )
  )
  expect_equal(
    as.integer(tc$num_nodes()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_nodes(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes)

  # Testing defaults
  id0 <- rtsk_node_table_add_row(tc_xptr)
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes),
    m0
  )

  # Explicit NULL metadata should also be accepted.
  id1 <- rtsk_node_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    time = 2.5,
    population = -1L,
    individual = -1L,
    metadata = NULL
  )
  expect_equal(id1, n0 + 1L)

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_nodes())
  expect_no_error(
    tc$node_table_add_row(
      flags = 1L,
      time = 3.5,
      population = 0L,
      individual = -1L,
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_nodes()), n_before_method + 1L)
  expect_no_error(
    tc$node_table_add_row(
      flags = 1,
      time = 4.5,
      population = 0,
      individual = -1,
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_nodes()), n_before_method + 2L)
  expect_no_error(tc$node_table_add_row(population = NULL, individual = NULL))
  expect_equal(as.integer(tc$num_nodes()), n_before_method + 3L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$nodes
  )
  expect_no_warning(tc$node_table_add_row(metadata = "abc"))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$nodes),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$nodes
  )
  expect_no_error(tc$node_table_add_row(metadata = charToRaw("xyz")))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$nodes),
    m_before_raw + 3L
  )

  expect_error(tc$node_table_add_row(flags = NULL), "flags cannot be NULL")
  invalid_flags <- list(
    NA_integer_,
    -1L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (flags in invalid_flags) {
    expect_error(
      tc$node_table_add_row(flags = flags),
      regexp = "flags must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }

  invalid_times <- list(NULL, NA_real_, NaN, c(0, 1), "0")
  for (time in invalid_times) {
    expect_error(
      tc$node_table_add_row(time = time),
      regexp = "time must be a non-NA numeric scalar!"
    )
  }

  invalid_ids <- list(
    NA_integer_,
    -2L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (name in c("population", "individual")) {
    for (value in invalid_ids) {
      args <- list()
      args[[name]] <- value
      expect_error(
        do.call(tc$node_table_add_row, args),
        regexp = paste0(
          name,
          " must be NULL or a non-NA integer scalar within 32-bit range \\(>= -1\\)!"
        )
      )
    }
  }
  expect_error(
    tc$node_table_add_row(metadata = c("a", "b")),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$node_table_add_row(metadata = NA_character_),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$node_table_add_row(metadata = 1L),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_node_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("individual_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  empty_id <- tc$individual_table_add_row()
  empty_low <- rtsk_individual_table_get_row(tc_xptr, empty_id)
  empty_method <- tc$individual_table_get_row(empty_id)
  expect_identical(
    empty_low,
    list(
      id = empty_id,
      flags = 0L,
      location = numeric(),
      parents = integer(),
      metadata = raw(),
      nodes = integer()
    )
  )
  expect_identical(
    empty_method,
    empty_low[c("id", "flags", "location", "parents", "metadata")]
  )
  expect_false("nodes" %in% names(empty_method))

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  populated_id <- tc$individual_table_add_row(
    flags = 3L,
    location = c(1.25, -2.5),
    parents = c(0L, 1L),
    metadata = binary_metadata
  )
  populated_low <- rtsk_individual_table_get_row(tc_xptr, populated_id)
  populated_method <- tc$individual_table_get_row(populated_id)
  expect_identical(populated_low$id, populated_id)
  expect_identical(populated_low$flags, 3L)
  expect_identical(populated_low$location, c(1.25, -2.5))
  expect_identical(populated_low$parents, c(0L, 1L))
  expect_identical(populated_low$metadata, binary_metadata)
  expect_identical(populated_low$nodes, integer())
  expect_identical(
    populated_method,
    populated_low[c("id", "flags", "location", "parents", "metadata")]
  )

  expect_error(
    rtsk_individual_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_INDIVIDUAL_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_individual_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_INDIVIDUAL_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_individual_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_INDIVIDUAL_OUT_OF_BOUNDS"
  )

  expect_error(
    tc$individual_table_get_row(NULL),
    regexp = "index cannot be NULL"
  )
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$individual_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
})

test_that("node_table_get_row wrapper returns node row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  last_node <- as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)) - 1L

  first_row_low <- rtsk_node_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$node_table_get_row(0L)
  last_row_low <- rtsk_node_table_get_row(tc_xptr, last_node)
  last_row_method <- tc$node_table_get_row(last_node)

  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    first_row_low,
    list(
      id = 0L,
      flags = 1L,
      time = 0,
      population = 0L,
      individual = 0L,
      metadata = raw(0)
    )
  )
  expect_equal(first_row_method, first_row_low)
  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    last_row_low,
    list(
      id = 38L,
      flags = 0L,
      time = 6.96199333719081,
      population = 0L,
      individual = -1L,
      metadata = raw(0)
    )
  )
  expect_equal(last_row_method, last_row_low)

  expect_error(
    rtsk_node_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_node_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
  expect_error(
    tc$node_table_get_row(NA_integer_),
    regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    tc$node_table_get_row(-1L),
    regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(tc$node_table_get_row(NULL), regexp = "index cannot be NULL")
  invalid_indices <- list(0.5, Inf, c(0L, 1L))
  for (index in invalid_indices) {
    expect_error(
      tc$node_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_equal(tc$node_table_get_row(0), first_row_low)
  expect_error(
    rtsk_node_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )

  new_id <- tc$node_table_add_row(
    flags = 1L,
    time = 12.5,
    population = 0L,
    individual = -1L,
    metadata = charToRaw("abc")
  )
  row_low <- rtsk_node_table_get_row(tc_xptr, new_id)
  row_method <- tc$node_table_get_row(new_id)

  expect_equal(
    sort(names(row_low)),
    c("flags", "id", "individual", "metadata", "population", "time")
  )
  expect_equal(row_low$id, new_id)
  expect_equal(row_low$flags, 1L)
  expect_equal(row_low$time, 12.5)
  expect_equal(row_low$population, 0L)
  expect_equal(row_low$individual, -1L)
  expect_equal(row_low$metadata, charToRaw("abc"))
  expect_equal(row_method, row_low)

  null_id <- tc$node_table_add_row(
    time = 13.5,
    population = NULL,
    individual = NULL
  )
  null_row <- tc$node_table_get_row(null_id)
  expect_equal(null_row$id, null_id)
  expect_equal(null_row$population, -1L)
  expect_equal(null_row$individual, -1L)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  binary_id <- tc$node_table_add_row(metadata = binary_metadata)
  binary_row_low <- rtsk_node_table_get_row(tc_xptr, binary_id)
  binary_row_method <- tc$node_table_get_row(binary_id)
  expect_identical(binary_row_low$metadata, binary_metadata)
  expect_identical(binary_row_method$metadata, binary_metadata)
})

test_that("edge_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  last_edge <- as.integer(rtsk_table_collection_get_num_edges(tc_xptr)) - 1L

  first_row_low <- rtsk_edge_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$edge_table_get_row(0)
  last_row_low <- rtsk_edge_table_get_row(tc_xptr, last_edge)
  last_row_method <- tc$edge_table_get_row(last_edge)

  # we got these values from inst/examples/create_test.trees.py
  expect_identical(
    first_row_low,
    list(
      id = 0L,
      left = 0,
      right = 100,
      parent = 16L,
      child = 13L,
      metadata = raw()
    )
  )
  expect_identical(first_row_method, first_row_low)
  # we got these values from inst/examples/create_test.trees.py
  expect_identical(
    last_row_low,
    list(
      id = 58L,
      left = 0,
      right = 29,
      parent = 38L,
      child = 34L,
      metadata = raw()
    )
  )
  expect_identical(last_row_method, last_row_low)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- tc$edge_table_add_row(
    left = 12.5,
    right = 25.75,
    parent = 16L,
    child = 13L,
    metadata = binary_metadata
  )
  new_row_low <- rtsk_edge_table_get_row(tc_xptr, new_id)
  new_row_method <- tc$edge_table_get_row(new_id)
  expect_identical(
    new_row_low,
    list(
      id = new_id,
      left = 12.5,
      right = 25.75,
      parent = 16L,
      child = 13L,
      metadata = binary_metadata
    )
  )
  expect_identical(new_row_method, new_row_low)

  expect_error(
    rtsk_edge_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_EDGE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_edge_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_EDGE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_edge_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_EDGE_OUT_OF_BOUNDS"
  )

  expect_error(tc$edge_table_get_row(NULL), regexp = "index cannot be NULL")
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$edge_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$edge_table_get_row(999999L),
    regexp = "TSK_ERR_EDGE_OUT_OF_BOUNDS"
  )
})

test_that("site_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  last_site <- as.integer(rtsk_table_collection_get_num_sites(tc_xptr)) - 1L

  first_row_low <- rtsk_site_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$site_table_get_row(0)
  last_row_low <- rtsk_site_table_get_row(tc_xptr, last_site)
  last_row_method <- tc$site_table_get_row(last_site)

  # we got these values from inst/examples/create_test.trees.py
  expect_identical(
    first_row_low,
    list(
      id = 0L,
      position = 0,
      ancestral_state = "G",
      metadata = raw(),
      mutations = NULL
    )
  )
  expect_identical(
    first_row_method,
    first_row_low[c("id", "position", "ancestral_state", "metadata")]
  )
  expect_false("mutations" %in% names(first_row_method))
  # we got these values from inst/examples/create_test.trees.py
  expect_identical(
    last_row_low,
    list(
      id = 24L,
      position = 99,
      ancestral_state = "G",
      metadata = raw(),
      mutations = NULL
    )
  )
  expect_identical(
    last_row_method,
    last_row_low[c("id", "position", "ancestral_state", "metadata")]
  )

  empty_state_id <- tc$site_table_add_row(
    position = 100.5,
    ancestral_state = ""
  )
  empty_state_low <- rtsk_site_table_get_row(tc_xptr, empty_state_id)
  expect_identical(empty_state_low$ancestral_state, "")
  expect_identical(empty_state_low$metadata, raw())
  expect_null(empty_state_low$mutations)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- tc$site_table_add_row(
    position = 101.25,
    ancestral_state = "AC",
    metadata = binary_metadata
  )
  new_row_low <- rtsk_site_table_get_row(tc_xptr, new_id)
  new_row_method <- tc$site_table_get_row(new_id)
  expect_identical(
    new_row_low,
    list(
      id = new_id,
      position = 101.25,
      ancestral_state = "AC",
      metadata = binary_metadata,
      mutations = NULL
    )
  )
  expect_identical(
    new_row_method,
    new_row_low[c("id", "position", "ancestral_state", "metadata")]
  )

  expect_error(
    rtsk_site_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_SITE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_site_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_SITE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_site_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_SITE_OUT_OF_BOUNDS"
  )

  expect_error(tc$site_table_get_row(NULL), regexp = "index cannot be NULL")
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$site_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$site_table_get_row(999999L),
    regexp = "TSK_ERR_SITE_OUT_OF_BOUNDS"
  )
})

test_that("mutation_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  last_mutation <-
    as.integer(rtsk_table_collection_get_num_mutations(tc_xptr)) - 1L

  first_row_low <- rtsk_mutation_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$mutation_table_get_row(0)
  last_row_low <- rtsk_mutation_table_get_row(tc_xptr, last_mutation)
  last_row_method <- tc$mutation_table_get_row(last_mutation)

  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    first_row_low,
    list(
      id = 0L,
      site = 0L,
      node = 34L,
      parent = -1L,
      time = 5.96733256969776,
      derived_state = "T",
      metadata = raw(),
      edge = -1L,
      inherited_state = NULL
    )
  )
  expect_identical(
    first_row_method,
    first_row_low[c(
      "id",
      "site",
      "node",
      "derived_state",
      "parent",
      "metadata",
      "time"
    )]
  )
  expect_false(any(c("edge", "inherited_state") %in% names(first_row_method)))
  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    last_row_low,
    list(
      id = 29L,
      site = 24L,
      node = 33L,
      parent = -1L,
      time = 2.44107265855989,
      derived_state = "C",
      metadata = raw(),
      edge = -1L,
      inherited_state = NULL
    )
  )
  expect_identical(
    last_row_method,
    last_row_low[c(
      "id",
      "site",
      "node",
      "derived_state",
      "parent",
      "metadata",
      "time"
    )]
  )

  empty_state_id <- tc$mutation_table_add_row(
    site = 0L,
    node = 0L,
    derived_state = ""
  )
  empty_state_low <- rtsk_mutation_table_get_row(tc_xptr, empty_state_id)
  expect_identical(empty_state_low$derived_state, "")
  expect_identical(empty_state_low$parent, -1L)
  expect_true(is.nan(empty_state_low$time))
  expect_identical(empty_state_low$metadata, raw())
  expect_identical(empty_state_low$edge, -1L)
  expect_null(empty_state_low$inherited_state)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- tc$mutation_table_add_row(
    site = 0L,
    node = 1L,
    derived_state = "AC",
    parent = empty_state_id,
    metadata = binary_metadata,
    time = 0.125
  )
  new_row_low <- rtsk_mutation_table_get_row(tc_xptr, new_id)
  new_row_method <- tc$mutation_table_get_row(new_id)
  expect_identical(
    new_row_low,
    list(
      id = new_id,
      site = 0L,
      node = 1L,
      parent = empty_state_id,
      time = 0.125,
      derived_state = "AC",
      metadata = binary_metadata,
      edge = -1L,
      inherited_state = NULL
    )
  )
  expect_identical(
    new_row_method,
    new_row_low[c(
      "id",
      "site",
      "node",
      "derived_state",
      "parent",
      "metadata",
      "time"
    )]
  )

  expect_error(
    rtsk_mutation_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_MUTATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_mutation_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_MUTATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_mutation_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_MUTATION_OUT_OF_BOUNDS"
  )

  expect_error(tc$mutation_table_get_row(NULL), regexp = "index cannot be NULL")
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$mutation_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$mutation_table_get_row(999999L),
    regexp = "TSK_ERR_MUTATION_OUT_OF_BOUNDS"
  )
})

test_that("population_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  first_row_low <- rtsk_population_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$population_table_get_row(0)
  # we got this value from inst/examples/create_test.trees.py
  expect_identical(
    first_row_low,
    list(
      id = 0L,
      metadata = charToRaw('{"description":"","name":"pop_0"}')
    )
  )
  expect_identical(first_row_method, first_row_low)

  empty_id <- tc$population_table_add_row()
  empty_row_low <- rtsk_population_table_get_row(tc_xptr, empty_id)
  empty_row_method <- tc$population_table_get_row(empty_id)
  expect_identical(empty_row_low, list(id = empty_id, metadata = raw()))
  expect_identical(empty_row_method, empty_row_low)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  binary_id <- tc$population_table_add_row(metadata = binary_metadata)
  binary_row_low <- rtsk_population_table_get_row(tc_xptr, binary_id)
  binary_row_method <- tc$population_table_get_row(binary_id)
  expect_identical(
    binary_row_low,
    list(id = binary_id, metadata = binary_metadata)
  )
  expect_identical(binary_row_method, binary_row_low)

  expect_error(
    rtsk_population_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_POPULATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_population_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_POPULATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_population_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_POPULATION_OUT_OF_BOUNDS"
  )

  expect_error(
    tc$population_table_get_row(NULL),
    regexp = "index cannot be NULL"
  )
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$population_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$population_table_get_row(999999L),
    regexp = "TSK_ERR_POPULATION_OUT_OF_BOUNDS"
  )
})

test_that("migration_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  dest <- tc$population_table_add_row()

  empty_id <- tc$migration_table_add_row(
    left = 0,
    right = 1,
    node = 0L,
    source = 0L,
    dest = dest,
    time = 1.25
  )
  empty_row_low <- rtsk_migration_table_get_row(tc_xptr, empty_id)
  empty_row_method <- tc$migration_table_get_row(0)
  expect_identical(
    empty_row_low,
    list(
      id = empty_id,
      left = 0,
      right = 1,
      node = 0L,
      source = 0L,
      dest = dest,
      time = 1.25,
      metadata = raw()
    )
  )
  expect_identical(empty_row_method, empty_row_low)

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  binary_id <- tc$migration_table_add_row(
    left = 1.5,
    right = 2.75,
    node = 1L,
    source = dest,
    dest = 0L,
    time = 3.5,
    metadata = binary_metadata
  )
  binary_row_low <- rtsk_migration_table_get_row(tc_xptr, binary_id)
  binary_row_method <- tc$migration_table_get_row(binary_id)
  expect_identical(
    binary_row_low,
    list(
      id = binary_id,
      left = 1.5,
      right = 2.75,
      node = 1L,
      source = dest,
      dest = 0L,
      time = 3.5,
      metadata = binary_metadata
    )
  )
  expect_identical(binary_row_method, binary_row_low)

  expect_error(
    rtsk_migration_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_MIGRATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_migration_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_MIGRATION_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_migration_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_MIGRATION_OUT_OF_BOUNDS"
  )

  expect_error(
    tc$migration_table_get_row(NULL),
    regexp = "index cannot be NULL"
  )
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$migration_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$migration_table_get_row(999999L),
    regexp = "TSK_ERR_MIGRATION_OUT_OF_BOUNDS"
  )
})

test_that("provenance_table_get_row returns row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  empty_id <- tc$provenance_table_add_row(record = "", timestamp = "")
  empty_row_low <- rtsk_provenance_table_get_row(tc_xptr, empty_id)
  empty_row_method <- tc$provenance_table_get_row(as.numeric(empty_id))
  expect_identical(
    empty_row_low,
    list(id = empty_id, timestamp = "", record = "")
  )
  expect_identical(empty_row_method, empty_row_low)

  timestamp <- "2026-02-03T04:05:06Z"
  record <- '{"software":"RcppTskit","action":"getter-test"}'
  row_id <- tc$provenance_table_add_row(
    record = record,
    timestamp = timestamp
  )
  row_low <- rtsk_provenance_table_get_row(tc_xptr, row_id)
  row_method <- tc$provenance_table_get_row(row_id)
  expect_identical(
    row_low,
    list(id = row_id, timestamp = timestamp, record = record)
  )
  expect_identical(row_method, row_low)

  expect_error(
    rtsk_provenance_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_PROVENANCE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_provenance_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_PROVENANCE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_provenance_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_PROVENANCE_OUT_OF_BOUNDS"
  )

  expect_error(
    tc$provenance_table_get_row(NULL),
    regexp = "index cannot be NULL"
  )
  invalid_indices <- list(NA_integer_, -1L, 0.5, Inf, c(0L, 1L), "0")
  for (index in invalid_indices) {
    expect_error(
      tc$provenance_table_get_row(index),
      regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
    )
  }
  expect_error(
    tc$provenance_table_get_row(999999L),
    regexp = "TSK_ERR_PROVENANCE_OUT_OF_BOUNDS"
  )
})

test_that("edge_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_edges(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$edges

  parent <- 16L
  child <- 13L

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_edge_table_add_row(
    tc = tc_xptr,
    left = 0.25,
    right = 0.75,
    parent = parent,
    child = child,
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_edge_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      left = 0.25,
      right = 0.75,
      parent = parent,
      child = child,
      metadata = binary_metadata
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_edges(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_edges()
  new_id_method <- tc$edge_table_add_row(
    left = 1,
    right = 2,
    parent = as.numeric(parent),
    child = as.numeric(child)
  )
  expect_identical(new_id_method, as.integer(n_before_method))
  expect_identical(
    tc$edge_table_get_row(new_id_method),
    list(
      id = new_id_method,
      left = 1,
      right = 2,
      parent = parent,
      child = child,
      metadata = raw()
    )
  )
  expect_equal(
    as.integer(tc$num_edges()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_edges(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges)

  # Explicit NULL metadata should be accepted.
  id0 <- rtsk_edge_table_add_row(
    tc = tc_xptr,
    left = 0,
    right = 1,
    parent = parent,
    child = child,
    metadata = NULL
  )
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_edges(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_edges())
  expect_no_error(
    tc$edge_table_add_row(
      left = 2,
      right = 3,
      parent = parent,
      child = child,
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_edges()), n_before_method + 1L)
  expect_no_error(
    tc$edge_table_add_row(
      left = 2,
      right = 3,
      parent = as.numeric(parent),
      child = as.numeric(child),
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_edges()), n_before_method + 2L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$edges
  )
  expect_no_warning(
    tc$edge_table_add_row(
      left = 3,
      right = 4,
      parent = parent,
      child = child,
      metadata = "abc"
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$edges),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$edges
  )
  expect_no_error(
    tc$edge_table_add_row(
      left = 4,
      right = 5,
      parent = parent,
      child = child,
      metadata = charToRaw("xyz")
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$edges),
    m_before_raw + 3L
  )
  invalid_coordinates <- list(NULL, NA_real_, NaN, c(0, 1), "0")
  for (name in c("left", "right")) {
    for (value in invalid_coordinates) {
      args <- list(left = 5, right = 6, parent = parent, child = child)
      args[name] <- list(value)
      expect_error(
        do.call(tc$edge_table_add_row, args),
        regexp = paste0(name, " must be a non-NA numeric scalar!")
      )
    }
  }

  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 6,
      parent = parent,
      child = child
    ),
    regexp = "left must be strictly less than right!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 7,
      right = 6,
      parent = parent,
      child = child
    ),
    regexp = "left must be strictly less than right!"
  )

  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = NULL,
      child = child
    ),
    regexp = "parent cannot be NULL\\."
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = NULL
    ),
    regexp = "child cannot be NULL\\."
  )
  invalid_ids <- list(
    NA_integer_,
    -1L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (name in c("parent", "child")) {
    for (value in invalid_ids) {
      args <- list(left = 5, right = 6, parent = parent, child = child)
      args[[name]] <- value
      expect_error(
        do.call(tc$edge_table_add_row, args),
        regexp = paste0(
          name,
          " must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
        )
      )
    }
  }
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = c("a", "b")
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = NA_character_
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = 1L
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_edge_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("site_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_sites(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_site_table_add_row(
    tc = tc_xptr,
    position = 0.5,
    ancestral_state = "AC",
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_site_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      position = 0.5,
      ancestral_state = "AC",
      metadata = binary_metadata,
      mutations = NULL
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_sites(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_sites()
  new_id_method <- tc$site_table_add_row(position = 1.5, ancestral_state = "G")
  expect_identical(new_id_method, as.integer(n_before_method))
  expect_identical(
    tc$site_table_get_row(new_id_method),
    list(
      id = new_id_method,
      position = 1.5,
      ancestral_state = "G",
      metadata = raw()
    )
  )
  expect_identical(
    as.integer(tc$num_sites()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_sites(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]])

  id0 <- rtsk_site_table_add_row(
    tc = tc_xptr,
    position = 2.5,
    ancestral_state = "",
    metadata = NULL
  )
  expect_identical(id0, n0)
  expect_identical(
    rtsk_site_table_get_row(tc_xptr, id0),
    list(
      id = id0,
      position = 2.5,
      ancestral_state = "",
      metadata = raw(),
      mutations = NULL
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_sites(tc_xptr)),
    n0 + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  expect_error(
    tc$site_table_add_row(
      position = 3.5,
      ancestral_state = NULL,
      metadata = NULL
    ),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )

  m_before_char <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "sites"
  ]])
  character_metadata_id <- expect_no_warning(
    tc$site_table_add_row(
      position = 4.5,
      ancestral_state = "T",
      metadata = "abc"
    )
  )
  expect_identical(
    tc$site_table_get_row(character_metadata_id)$metadata,
    charToRaw("abc")
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["sites"]]),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "sites"
  ]])
  raw_metadata_id <- expect_no_error(
    tc$site_table_add_row(
      position = 5.5,
      ancestral_state = "C",
      metadata = charToRaw("xyz")
    )
  )
  expect_identical(
    tc$site_table_get_row(raw_metadata_id)$metadata,
    charToRaw("xyz")
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["sites"]]),
    m_before_raw + 3L
  )

  invalid_positions <- list(NULL, NA_real_, NaN, c(0, 1), "0")
  for (position in invalid_positions) {
    expect_error(
      tc$site_table_add_row(position = position, ancestral_state = "A"),
      regexp = "position must be a non-NA numeric scalar!"
    )
  }

  invalid_states <- list(
    NULL,
    NA_character_,
    character(),
    c("A", "B"),
    charToRaw("A"),
    1L
  )
  for (ancestral_state in invalid_states) {
    expect_error(
      tc$site_table_add_row(
        position = 6.5,
        ancestral_state = ancestral_state
      ),
      regexp = "ancestral_state must be a length-1 non-NA character string!"
    )
  }

  invalid_metadata <- list(c("a", "b"), NA_character_, 1L)
  for (metadata in invalid_metadata) {
    expect_error(
      tc$site_table_add_row(
        position = 6.5,
        ancestral_state = "A",
        metadata = metadata
      ),
      regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
    )
  }
  expect_error(
    test_rtsk_site_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("mutation_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  expect_gt(as.integer(rtsk_table_collection_get_num_sites(tc_xptr)), 0L)
  expect_gt(as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)), 0L)
  site <- 0L
  node <- 0L

  n_before <- rtsk_table_collection_get_num_mutations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_mutation_table_add_row(
    tc = tc_xptr,
    site = site,
    node = node,
    parent = -1L,
    time = 0.125,
    derived_state = "AC",
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_mutation_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      site = site,
      node = node,
      parent = -1L,
      time = 0.125,
      derived_state = "AC",
      metadata = binary_metadata,
      edge = -1L,
      inherited_state = NULL
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_mutations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_mutations()
  new_id_method <- tc$mutation_table_add_row(
    site = as.numeric(site),
    node = as.numeric(node + 1L),
    derived_state = "C",
    parent = as.numeric(new_id)
  )
  expect_identical(new_id_method, as.integer(n_before_method))
  new_row_method <- tc$mutation_table_get_row(new_id_method)
  expect_identical(
    new_row_method[names(new_row_method) != "time"],
    list(
      id = new_id_method,
      site = site,
      node = node + 1L,
      derived_state = "C",
      parent = new_id,
      metadata = raw()
    )
  )
  expect_true(is.nan(new_row_method$time))
  expect_identical(
    as.integer(tc$num_mutations()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)
  site <- 0L
  node <- 0L

  n0 <- as.integer(rtsk_table_collection_get_num_mutations(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)[[
    "mutations"
  ]])

  id0 <- rtsk_mutation_table_add_row(
    tc = tc_xptr,
    site = site,
    node = node,
    parent = -1L,
    time = NaN,
    derived_state = "",
    metadata = NULL
  )
  expect_identical(id0, n0)
  empty_row <- rtsk_mutation_table_get_row(tc_xptr, id0)
  expect_identical(
    empty_row[names(empty_row) != "time"],
    list(
      id = id0,
      site = site,
      node = node,
      parent = -1L,
      derived_state = "",
      metadata = raw(),
      edge = -1L,
      inherited_state = NULL
    )
  )
  expect_true(is.nan(empty_row$time))
  expect_identical(
    as.integer(rtsk_table_collection_get_num_mutations(tc_xptr)),
    n0 + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_mutations())
  null_id <- expect_no_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      parent = NULL,
      time = NULL,
      derived_state = "T",
      metadata = NULL
    )
  )
  null_row <- tc$mutation_table_get_row(null_id)
  expect_identical(null_row$parent, -1L)
  expect_true(is.nan(null_row$time))
  expect_identical(null_row$metadata, raw())
  expect_identical(as.integer(tc$num_mutations()), n_before_method + 1L)

  nan_id <- expect_no_error(
    tc$mutation_table_add_row(
      site = as.numeric(site),
      node = as.numeric(node),
      parent = -1,
      time = NaN,
      derived_state = "T",
      metadata = NULL
    )
  )
  expect_true(is.nan(tc$mutation_table_get_row(nan_id)$time))
  expect_identical(as.integer(tc$num_mutations()), n_before_method + 2L)

  m_before_char <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "mutations"
  ]])
  character_metadata_id <- expect_no_warning(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = "G",
      metadata = "abc"
    )
  )
  expect_identical(
    tc$mutation_table_get_row(character_metadata_id)$metadata,
    charToRaw("abc")
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["mutations"]]),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "mutations"
  ]])
  raw_metadata_id <- expect_no_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = "A",
      metadata = charToRaw("xyz")
    )
  )
  expect_identical(
    tc$mutation_table_get_row(raw_metadata_id)$metadata,
    charToRaw("xyz")
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["mutations"]]),
    m_before_raw + 3L
  )

  expect_error(
    tc$mutation_table_add_row(site = NULL, node = node, derived_state = "T"),
    regexp = "site cannot be NULL\\."
  )
  expect_error(
    tc$mutation_table_add_row(site = site, node = NULL, derived_state = "T"),
    regexp = "node cannot be NULL\\."
  )

  invalid_ids <- list(
    NA_integer_,
    -1L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (name in c("site", "node")) {
    for (value in invalid_ids) {
      args <- list(site = site, node = node, derived_state = "T")
      args[[name]] <- value
      expect_error(
        do.call(tc$mutation_table_add_row, args),
        regexp = paste0(
          name,
          " must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
        )
      )
    }
  }

  invalid_parents <- list(
    NA_integer_,
    -2L,
    0.5,
    Inf,
    c(-1L, 0L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (parent in invalid_parents) {
    expect_error(
      tc$mutation_table_add_row(
        site = site,
        node = node,
        parent = parent,
        derived_state = "T"
      ),
      regexp = "parent must be NULL or a non-NA integer scalar within 32-bit range \\(>= -1\\)!"
    )
  }

  invalid_times <- list(NA_real_, c(0, 1), "foo", TRUE)
  for (time in invalid_times) {
    expect_error(
      tc$mutation_table_add_row(
        site = site,
        node = node,
        time = time,
        derived_state = "T"
      ),
      regexp = "time must be NaN, NULL, or a non-NA numeric scalar!"
    )
  }

  invalid_states <- list(
    NULL,
    NA_character_,
    character(),
    c("a", "b"),
    charToRaw("A"),
    1L
  )
  for (derived_state in invalid_states) {
    expect_error(
      tc$mutation_table_add_row(
        site = site,
        node = node,
        derived_state = derived_state
      ),
      regexp = "derived_state must be a length-1 non-NA character string!"
    )
  }

  invalid_metadata <- list(c("a", "b"), NA_character_, 1L)
  for (metadata in invalid_metadata) {
    expect_error(
      tc$mutation_table_add_row(
        site = site,
        node = node,
        derived_state = "T",
        metadata = metadata
      ),
      regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
    )
  }
  expect_error(
    test_rtsk_mutation_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("population_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_populations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$populations

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_population_table_add_row(
    tc_xptr,
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_population_table_get_row(tc_xptr, new_id),
    list(id = new_id, metadata = binary_metadata)
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_populations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$populations),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_populations())
  empty_id <- expect_no_error(tc$population_table_add_row())
  expect_identical(empty_id, n_before_method)
  expect_identical(
    tc$population_table_get_row(empty_id),
    list(id = empty_id, metadata = raw())
  )
  expect_identical(as.integer(tc$num_populations()), n_before_method + 1L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$populations
  )
  character_metadata_id <- expect_no_warning(
    tc$population_table_add_row(metadata = "xyz")
  )
  expect_identical(
    tc$population_table_get_row(character_metadata_id)$metadata,
    charToRaw("xyz")
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$populations),
    m_before_char + 3L
  )

  raw_metadata <- charToRaw("raw")
  raw_metadata_id <- expect_no_error(
    tc$population_table_add_row(metadata = raw_metadata)
  )
  expect_identical(
    tc$population_table_get_row(raw_metadata_id)$metadata,
    raw_metadata
  )

  invalid_metadata <- list(c("a", "b"), NA_character_, 1L)
  for (metadata in invalid_metadata) {
    expect_error(
      tc$population_table_add_row(metadata = metadata),
      regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
    )
  }
  expect_error(
    test_rtsk_population_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("migration_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_migrations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$migrations

  binary_metadata <- as.raw(c(0x00, 0x7f, 0x80, 0xff))
  new_id <- rtsk_migration_table_add_row(
    tc = tc_xptr,
    left = 0.25,
    right = 1.75,
    node = 0L,
    source = 0L,
    dest = 0L,
    time = 1.25,
    metadata = binary_metadata
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_migration_table_get_row(tc_xptr, new_id),
    list(
      id = new_id,
      left = 0.25,
      right = 1.75,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = 1.25,
      metadata = binary_metadata
    )
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_migrations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_identical(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$migrations),
    as.integer(m_before) + length(binary_metadata)
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_migrations())
  empty_id <- tc$migration_table_add_row(
    left = 2,
    right = 3,
    node = 1,
    source = 0,
    dest = 0,
    time = 2.5
  )
  expect_identical(empty_id, n_before_method)
  expect_identical(
    tc$migration_table_get_row(empty_id),
    list(
      id = empty_id,
      left = 2,
      right = 3,
      node = 1L,
      source = 0L,
      dest = 0L,
      time = 2.5,
      metadata = raw()
    )
  )
  expect_identical(as.integer(tc$num_migrations()), n_before_method + 1L)

  character_metadata_id <- tc$migration_table_add_row(
    left = 3,
    right = 4,
    node = 0L,
    source = 0L,
    dest = 0L,
    time = 3,
    metadata = "abc"
  )
  expect_identical(
    tc$migration_table_get_row(character_metadata_id)$metadata,
    charToRaw("abc")
  )

  invalid_coordinates <- list(NULL, NA_real_, NaN, c(0, 1), "0", TRUE)
  for (name in c("left", "right")) {
    for (value in invalid_coordinates) {
      args <- list(
        left = 4,
        right = 5,
        node = 0L,
        source = 0L,
        dest = 0L,
        time = 1
      )
      args[name] <- list(value)
      expect_error(
        do.call(tc$migration_table_add_row, args),
        regexp = paste0(name, " must be a non-NA numeric scalar!")
      )
    }
  }

  for (right in c(4, 3)) {
    expect_error(
      tc$migration_table_add_row(
        left = 4,
        right = right,
        node = 0L,
        source = 0L,
        dest = 0L,
        time = 1
      ),
      regexp = "left must be strictly less than right!"
    )
  }

  for (name in c("node", "source", "dest")) {
    args <- list(
      left = 4,
      right = 5,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = 1
    )
    args[name] <- list(NULL)
    expect_error(
      do.call(tc$migration_table_add_row, args),
      regexp = paste0(name, " cannot be NULL\\.")
    )
  }

  invalid_ids <- list(
    NA_integer_,
    -1L,
    0.5,
    Inf,
    c(0L, 1L),
    "0",
    as.numeric(.Machine$integer.max) + 1
  )
  for (name in c("node", "source", "dest")) {
    for (value in invalid_ids) {
      args <- list(
        left = 4,
        right = 5,
        node = 0L,
        source = 0L,
        dest = 0L,
        time = 1
      )
      args[[name]] <- value
      expect_error(
        do.call(tc$migration_table_add_row, args),
        regexp = paste0(
          name,
          " must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
        )
      )
    }
  }

  invalid_times <- list(NULL, NA_real_, NaN, c(0, 1), "1", TRUE)
  for (time in invalid_times) {
    args <- list(
      left = 4,
      right = 5,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = time
    )
    expect_error(
      do.call(tc$migration_table_add_row, args),
      regexp = "time must be a non-NA numeric scalar!"
    )
  }

  invalid_metadata <- list(c("a", "b"), NA_character_, 1L)
  for (metadata in invalid_metadata) {
    expect_error(
      tc$migration_table_add_row(
        left = 4,
        right = 5,
        node = 0L,
        source = 0L,
        dest = 0L,
        time = 1,
        metadata = metadata
      ),
      regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
    )
  }

  raw_metadata <- charToRaw("raw")
  raw_metadata_id <- tc$migration_table_add_row(
    left = 4,
    right = 5,
    node = 0L,
    source = 0L,
    dest = 0L,
    time = 4,
    metadata = raw_metadata
  )
  expect_identical(
    tc$migration_table_get_row(raw_metadata_id)$metadata,
    raw_metadata
  )

  expect_error(
    test_rtsk_migration_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("provenance_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_provenances(tc_xptr)
  timestamp <- "2025-01-01T00:00:00Z"
  record <- '{"software":"RcppTskit"}'
  new_id <- rtsk_provenance_table_add_row(
    tc = tc_xptr,
    timestamp = timestamp,
    record = record
  )
  expect_identical(new_id, as.integer(n_before)) # IDs are 0-based
  expect_identical(
    rtsk_provenance_table_get_row(tc_xptr, new_id),
    list(id = new_id, timestamp = timestamp, record = record)
  )
  expect_identical(
    as.integer(rtsk_table_collection_get_num_provenances(tc_xptr)),
    as.integer(n_before) + 1L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_provenances())
  timestamp_method <- "2025-01-02T00:00:00Z"
  record_method <- '{"software":"RcppTskit","action":"test"}'
  prov_id_method <- tc$provenance_table_add_row(
    record = record_method,
    timestamp = timestamp_method
  )
  expect_identical(prov_id_method, n_before_method)
  expect_identical(
    tc$provenance_table_get_row(prov_id_method),
    list(
      id = prov_id_method,
      timestamp = timestamp_method,
      record = record_method
    )
  )
  expect_identical(as.integer(tc$num_provenances()), n_before_method + 1L)

  # Positional args follow Python API order: record, timestamp
  positional_record <- '{"software":"RcppTskit","action":"positional"}'
  positional_timestamp <- "2025-01-03T00:00:00Z"
  prov_id_positional <- tc$provenance_table_add_row(
    positional_record,
    positional_timestamp
  )
  expect_identical(
    tc$provenance_table_get_row(prov_id_positional),
    list(
      id = prov_id_positional,
      timestamp = positional_timestamp,
      record = positional_record
    )
  )

  # If timestamp is omitted, method generates current UTC ISO8601 timestamp.
  auto_record <- '{"software":"RcppTskit","action":"auto-ts"}'
  prov_id_auto_ts <- tc$provenance_table_add_row(
    record = auto_record
  )
  prov_row_auto_ts <- tc$provenance_table_get_row(prov_id_auto_ts)
  expect_identical(prov_row_auto_ts$id, prov_id_auto_ts)
  expect_identical(prov_row_auto_ts$record, auto_record)
  expect_match(
    prov_row_auto_ts$timestamp,
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{6}Z$"
  )

  invalid_records <- list(
    NULL,
    NA_character_,
    character(),
    c("{}", "{}"),
    charToRaw("{}"),
    1L
  )
  for (record in invalid_records) {
    expect_error(
      tc$provenance_table_add_row(record = record),
      regexp = "record must be a length-1 non-NA character string!"
    )
  }

  invalid_timestamps <- list(
    NA_character_,
    character(),
    c("2025-01-01", "2025-01-02"),
    charToRaw("2025-01-01"),
    1L
  )
  for (timestamp in invalid_timestamps) {
    expect_error(
      tc$provenance_table_add_row(record = "{}", timestamp = timestamp),
      regexp = "timestamp must be a length-1 non-NA character string!"
    )
  }

  expect_error(
    test_rtsk_provenance_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("get_row wrappers return expected fields and validate indices", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  indiv_low <- rtsk_individual_table_get_row(tc_xptr, 0L)
  indiv_method <- tc$individual_table_get_row(0)
  expect_equal(
    sort(names(indiv_low)),
    c("flags", "id", "location", "metadata", "nodes", "parents")
  )
  expect_equal(
    sort(names(indiv_method)),
    c("flags", "id", "location", "metadata", "parents")
  )
  expect_equal(
    indiv_method,
    indiv_low[c("id", "flags", "location", "parents", "metadata")]
  )

  edge_low <- rtsk_edge_table_get_row(tc_xptr, 0L)
  edge_method <- tc$edge_table_get_row(0)
  expect_equal(
    sort(names(edge_low)),
    c("child", "id", "left", "metadata", "parent", "right")
  )
  expect_equal(edge_method, edge_low)

  site_low <- rtsk_site_table_get_row(tc_xptr, 0L)
  site_method <- tc$site_table_get_row(0)
  expect_equal(
    sort(names(site_low)),
    c("ancestral_state", "id", "metadata", "mutations", "position")
  )
  expect_equal(
    sort(names(site_method)),
    c("ancestral_state", "id", "metadata", "position")
  )
  expect_equal(
    site_method,
    site_low[c("id", "position", "ancestral_state", "metadata")]
  )
  expect_null(site_low$mutations)

  mut_low <- rtsk_mutation_table_get_row(tc_xptr, 0L)
  mut_method <- tc$mutation_table_get_row(0)
  expect_equal(
    sort(names(mut_low)),
    c(
      "derived_state",
      "edge",
      "id",
      "inherited_state",
      "metadata",
      "node",
      "parent",
      "site",
      "time"
    )
  )
  expect_equal(
    sort(names(mut_method)),
    c("derived_state", "id", "metadata", "node", "parent", "site", "time")
  )
  expect_equal(
    mut_method,
    mut_low[c(
      "id",
      "site",
      "node",
      "derived_state",
      "parent",
      "metadata",
      "time"
    )]
  )

  pop_low <- rtsk_population_table_get_row(tc_xptr, 0L)
  pop_method <- tc$population_table_get_row(0)
  expect_equal(sort(names(pop_low)), c("id", "metadata"))
  expect_equal(pop_method, pop_low)

  if (tc$num_migrations() == 0L) {
    tc$migration_table_add_row(
      left = 0,
      right = 1,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = 1
    )
  }
  mig_low <- rtsk_migration_table_get_row(tc_xptr, 0L)
  mig_method <- tc$migration_table_get_row(0)
  expect_equal(
    sort(names(mig_low)),
    c("dest", "id", "left", "metadata", "node", "right", "source", "time")
  )
  expect_equal(mig_method, mig_low)

  if (tc$num_provenances() == 0L) {
    tc$provenance_table_add_row(
      record = "{\"software\":\"RcppTskit\"}",
      timestamp = "2025-01-01T00:00:00Z"
    )
  }
  prov_low <- rtsk_provenance_table_get_row(tc_xptr, 0L)
  prov_method <- tc$provenance_table_get_row(0)
  expect_equal(sort(names(prov_low)), c("id", "record", "timestamp"))
  expect_equal(prov_method, prov_low)

  # exercise metadata/location/parents copy paths in individual get_row
  indiv_new <- tc$individual_table_add_row(
    location = c(1.25, -2.5),
    parents = 0L,
    metadata = charToRaw("imd")
  )
  indiv_new_low <- rtsk_individual_table_get_row(tc_xptr, indiv_new)
  expect_equal(indiv_new_low$location, c(1.25, -2.5))
  expect_equal(indiv_new_low$parents, 0L)
  expect_equal(indiv_new_low$metadata, charToRaw("imd"))
  expect_length(indiv_new_low$nodes, 0L)

  # exercise metadata copy path in edge get_row
  edge_new <- tc$edge_table_add_row(
    left = 0,
    right = 0.25,
    parent = 0L,
    child = 1L,
    metadata = charToRaw("emd")
  )
  edge_new_low <- rtsk_edge_table_get_row(tc_xptr, edge_new)
  expect_equal(edge_new_low$metadata, charToRaw("emd"))

  # exercise metadata copy path in site get_row
  site_new <- tc$site_table_add_row(
    position = 123.5,
    ancestral_state = "A",
    metadata = charToRaw("smd")
  )
  site_new_low <- rtsk_site_table_get_row(tc_xptr, site_new)
  expect_equal(site_new_low$metadata, charToRaw("smd"))
  expect_null(site_new_low$mutations)

  # exercise metadata copy path in mutation get_row
  mut_new <- tc$mutation_table_add_row(
    site = site_new,
    node = 0L,
    derived_state = "T",
    metadata = charToRaw("mmd")
  )
  mut_new_low <- rtsk_mutation_table_get_row(tc_xptr, mut_new)
  expect_equal(mut_new_low$metadata, charToRaw("mmd"))
  expect_equal(mut_new_low$edge, -1L)

  # exercise metadata copy path in population get_row
  pop_new <- tc$population_table_add_row(metadata = charToRaw("pmd"))
  pop_new_low <- rtsk_population_table_get_row(tc_xptr, pop_new)
  expect_equal(pop_new_low$metadata, charToRaw("pmd"))

  # exercise metadata copy path in migration get_row
  mig_new <- tc$migration_table_add_row(
    left = 0.5,
    right = 0.75,
    node = 0L,
    source = 0L,
    dest = 0L,
    time = 2.0,
    metadata = charToRaw("gmd")
  )
  mig_new_low <- rtsk_migration_table_get_row(tc_xptr, mig_new)
  expect_equal(mig_new_low$metadata, charToRaw("gmd"))

  expect_error(
    tc$individual_table_get_row(0.5),
    regexp = "index must be a non-NA, non-negative integer scalar no greater than [.]Machine[$]integer[.]max!"
  )
  expect_error(
    rtsk_individual_table_get_row(tc_xptr, 999999L),
    regexp = "OUT_OF_BOUNDS"
  )
  expect_error(rtsk_edge_table_get_row(tc_xptr, -1L), regexp = "OUT_OF_BOUNDS")
  expect_error(
    rtsk_site_table_get_row(tc_xptr, 999999L),
    regexp = "OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_mutation_table_get_row(tc_xptr, -1L),
    regexp = "OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_population_table_get_row(tc_xptr, -1L),
    regexp = "OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_migration_table_get_row(tc_xptr, -1L),
    regexp = "OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_provenance_table_get_row(tc_xptr, -1L),
    regexp = "OUT_OF_BOUNDS"
  )
})

test_that("add_row and get_row round-trip works across tables", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc <- tc_load(ts_file)

  ind_id <- tc$individual_table_add_row(
    flags = 1L,
    location = c(9.5, -3.25),
    parents = 0L,
    metadata = "imd"
  )
  ind_row <- tc$individual_table_get_row(ind_id)
  expect_equal(ind_row$id, ind_id)
  expect_equal(ind_row$flags, 1L)
  expect_equal(ind_row$location, c(9.5, -3.25))
  expect_equal(ind_row$parents, 0L)
  expect_equal(ind_row$metadata, charToRaw("imd"))

  node_id <- tc$node_table_add_row(
    flags = 0L,
    time = 0.125,
    population = 0L,
    individual = ind_id,
    metadata = "nmd"
  )
  node_row <- tc$node_table_get_row(node_id)
  expect_equal(node_row$id, node_id)
  expect_equal(node_row$time, 0.125)
  expect_equal(node_row$population, 0L)
  expect_equal(node_row$individual, ind_id)
  expect_equal(node_row$metadata, charToRaw("nmd"))

  edge_id <- tc$edge_table_add_row(
    left = 0,
    right = 0.5,
    parent = 16L,
    child = node_id,
    metadata = "emd"
  )
  edge_row <- tc$edge_table_get_row(edge_id)
  expect_equal(edge_row$id, edge_id)
  expect_equal(edge_row$parent, 16L)
  expect_equal(edge_row$child, node_id)
  expect_equal(edge_row$metadata, charToRaw("emd"))

  site_id <- tc$site_table_add_row(
    position = 9.75,
    ancestral_state = "A",
    metadata = "smd"
  )
  site_row <- tc$site_table_get_row(site_id)
  expect_equal(site_row$id, site_id)
  expect_equal(site_row$position, 9.75)
  expect_equal(site_row$ancestral_state, "A")
  expect_equal(site_row$metadata, charToRaw("smd"))

  mut_id <- tc$mutation_table_add_row(
    site = site_id,
    node = node_id,
    derived_state = "T",
    parent = -1L,
    metadata = "mmd",
    time = 0.1
  )
  mut_row <- tc$mutation_table_get_row(mut_id)
  expect_equal(mut_row$id, mut_id)
  expect_equal(mut_row$site, site_id)
  expect_equal(mut_row$node, node_id)
  expect_equal(mut_row$derived_state, "T")
  expect_equal(mut_row$metadata, charToRaw("mmd"))

  pop_id <- tc$population_table_add_row(metadata = "pmd")
  pop_row <- tc$population_table_get_row(pop_id)
  expect_equal(pop_row$id, pop_id)
  expect_equal(pop_row$metadata, charToRaw("pmd"))

  mig_id <- tc$migration_table_add_row(
    left = 0,
    right = 0.5,
    node = node_id,
    source = 0L,
    dest = 0L,
    time = 0.2,
    metadata = "gmd"
  )
  mig_row <- tc$migration_table_get_row(mig_id)
  expect_equal(mig_row$id, mig_id)
  expect_equal(mig_row$node, node_id)
  expect_equal(mig_row$metadata, charToRaw("gmd"))

  prov_id <- tc$provenance_table_add_row(
    record = "{\"software\":\"RcppTskit\"}",
    timestamp = "2026-01-01T00:00:00Z"
  )
  prov_row <- tc$provenance_table_get_row(prov_id)
  expect_equal(prov_row$id, prov_id)
  expect_equal(prov_row$timestamp, "2026-01-01T00:00:00Z")
  expect_equal(prov_row$record, "{\"software\":\"RcppTskit\"}")
})
