#' @title Table collection R6 class (TableCollection)
#' @description An \code{R6} class holding an external pointer to
#' a table collection object. As an \code{R6} class, method-calling looks Pythonic
#' and hence resembles the \code{tskit Python} API. Since the class only
#' holds the pointer, it is lightweight. Currently there is a limited set of
#' \code{R} methods for working with the table collection object.
#' @export
TableCollection <- R6Class(
  classname = "TableCollection",
  public = list(
    #' @field xptr external pointer to the table collection
    xptr = "externalptr",

    #' @description Create a \code{\link{TableCollection}} from a file or an external pointer.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param skip_tables logical; if \code{TRUE}, load only non-table information.
    #' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
    #'   reference genome sequence information.
    #' @param xptr an external pointer (\code{externalptr}) to a table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.load}.
    #' @return A \code{\link{TableCollection}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' is(tc)
    #' tc
    initialize = function(
      file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE,
      xptr = NULL
    ) {
      if (missing(file) && is.null(xptr)) {
        stop("Provide a file or an external pointer (xptr)!")
      }
      if (!missing(file) && !is.null(xptr)) {
        stop(
          "Provide either a file or an external pointer (xptr), but not both!"
        )
      }
      if (!missing(file)) {
        if (!is.character(file)) {
          stop("file must be a character string!")
        }
        options <- load_args_to_options(
          skip_tables = skip_tables,
          skip_reference_sequence = skip_reference_sequence
        )
        self$xptr <- rtsk_table_collection_load(
          filename = file,
          options = options
        )
      } else {
        if (!is.null(xptr) && !is(xptr, "externalptr")) {
          stop(
            "external pointer (xptr) must be an object of externalptr class!"
          )
        }
        self$xptr <- xptr
      }
      invisible(self)
    },

    #' @description Write a table collection to a file.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.dump}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' dump_file <- tempfile()
    #' tc$dump(dump_file)
    #' tc$write(dump_file) # alias
    #' \dontshow{file.remove(dump_file)}
    dump = function(file) {
      rtsk_table_collection_dump(self$xptr, filename = file, options = 0L)
    },

    #' @description Alias for \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @param file see \code{\link[=TableCollection]{TableCollection$dump}}.
    write = function(file) {
      self$dump(file = file)
    },

    #' @description Create a \code{\link{TreeSequence}} from this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.tree_sequence}.
    #' @return A \code{\link{TreeSequence}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' ts <- tc$tree_sequence()
    #' is(ts)
    tree_sequence = function() {
      if (!self$has_index()) {
        self$build_index()
      }
      ts_xptr <- rtsk_treeseq_init(self$xptr)
      TreeSequence$new(xptr = ts_xptr)
    },

    #' @description Sort this table collection in place.
    #' @param edge_start integer or integer-valued numeric scalar edge-table
    #'   start row index (0-based).
    #' @param site_start integer or integer-valued numeric scalar site-table
    #'   start row index (0-based).
    #' @param mutation_start integer or integer-valued numeric scalar
    #'   mutation-table start row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.sort}.
    #' @return No return value; called for side effects.
    #' @examples
    #' unsorted_file <- system.file("examples/test_unsorted.trees", package = "RcppTskit")
    #' tc <- tc_load(unsorted_file)
    #' inherits(try(tc$tree_sequence(), silent = TRUE), "try-error")
    #' tc$sort()
    #' ts <- tc$tree_sequence()
    #' is(ts)
    sort = function(edge_start = 0L, site_start = 0L, mutation_start = 0L) {
      validate_row_index(edge_start, "edge_start")
      validate_row_index(site_start, "site_start")
      validate_row_index(mutation_start, "mutation_start")
      rtsk_table_collection_sort(
        tc = self$xptr,
        start_edges = as.integer(edge_start),
        start_sites = as.integer(site_start),
        start_mutations = as.integer(mutation_start),
        options = 0L
      )
    },

    #' @description Simplify this table collection in place.
    #' @param samples optional integer vector of distinct node IDs to retain as
    #'   samples. If \code{NULL}, use the nodes currently marked as samples.
    #' @param reduce_to_site_topology logical; if \code{TRUE}, retain only
    #'   topology needed to represent trees containing sites.
    #' @param filter_populations optional logical; if \code{TRUE}, remove
    #'   populations no longer referenced by nodes. If \code{NULL}, treated as
    #'   \code{TRUE}.
    #' @param filter_individuals optional logical; if \code{TRUE}, remove
    #'   individuals no longer referenced by nodes. If \code{NULL}, treated as
    #'   \code{TRUE}.
    #' @param filter_sites optional logical; if \code{TRUE}, remove sites no
    #'   longer referenced by mutations. If \code{NULL}, treated as
    #'   \code{TRUE}.
    #' @param filter_nodes optional logical; if \code{TRUE}, remove nodes no
    #'   longer referenced by edges. If \code{NULL}, treated as
    #'   \code{TRUE}.
    #' @param update_sample_flags optional logical; if \code{TRUE}, update node
    #'   flags so exactly the requested samples carry the sample flag. If
    #'   \code{NULL}, treated as \code{TRUE}.
    #' @param keep_unary logical; if \code{TRUE}, retain unary nodes on paths
    #'   from samples to roots.
    #' @param keep_unary_in_individuals optional logical; if \code{TRUE}, retain
    #'   unary nodes that are associated with an individual, while other unary
    #'   nodes may still be removed. Cannot be used with
    #'   \code{keep_unary = TRUE}. If \code{NULL}, treated as \code{FALSE}.
    #' @param keep_input_roots logical; if \code{TRUE}, retain topology back to
    #'   the roots in the input tables rather than stopping at samples' MRCAs.
    #' @param record_provenance logical; if \code{TRUE}, append a
    #'   provenance row describing this simplify call.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.simplify}.
    #' @return Integer vector mapping input node IDs to simplified node IDs.
    #'   Removed nodes map to \code{-1}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' nodes_before <- as.integer(tc$num_nodes())
    #' node_map <- tc$simplify(samples = c(0L, 1L, 2L, 3L))
    #' c(before = nodes_before, after = as.integer(tc$num_nodes()))
    simplify = function(
      samples = NULL,
      reduce_to_site_topology = FALSE,
      filter_populations = NULL,
      filter_individuals = NULL,
      filter_sites = NULL,
      filter_nodes = NULL,
      update_sample_flags = NULL,
      keep_unary = FALSE,
      keep_unary_in_individuals = NULL,
      keep_input_roots = FALSE,
      record_provenance = TRUE
    ) {
      if (!is.null(samples)) {
        validate_optional_integer_vector_arg(samples, "samples")
        samples <- as.integer(samples)
      }
      validate_logical_arg(reduce_to_site_topology, "reduce_to_site_topology")
      validate_logical_arg(keep_unary, "keep_unary")
      validate_logical_arg(keep_input_roots, "keep_input_roots")
      validate_logical_arg(record_provenance, "record_provenance")

      resolve_optional_logical <- function(value, name, default) {
        if (is.null(value)) {
          return(default)
        }
        validate_logical_arg(value, name)
        return(value)
      }

      filter_populations <- resolve_optional_logical(
        filter_populations,
        "filter_populations",
        TRUE
      )
      filter_individuals <- resolve_optional_logical(
        filter_individuals,
        "filter_individuals",
        TRUE
      )
      filter_sites <- resolve_optional_logical(
        filter_sites,
        "filter_sites",
        TRUE
      )
      filter_nodes <- resolve_optional_logical(
        filter_nodes,
        "filter_nodes",
        TRUE
      )
      update_sample_flags <- resolve_optional_logical(
        update_sample_flags,
        "update_sample_flags",
        TRUE
      )
      keep_unary_in_individuals <- resolve_optional_logical(
        keep_unary_in_individuals,
        "keep_unary_in_individuals",
        FALSE
      )

      if (keep_unary && keep_unary_in_individuals) {
        stop("keep_unary and keep_unary_in_individuals cannot both be TRUE!")
      }

      # See https://tskit.dev/tskit/docs/stable/c-api.html#tsk-treeseq-simplify-tsk-table-collection-simplify
      options <- 0L
      if (filter_sites) {
        options <- bitwOr(options, bitwShiftL(1L, 0))
      }
      if (filter_populations) {
        options <- bitwOr(options, bitwShiftL(1L, 1))
      }
      if (filter_individuals) {
        options <- bitwOr(options, bitwShiftL(1L, 2))
      }
      if (reduce_to_site_topology) {
        options <- bitwOr(options, bitwShiftL(1L, 3))
      }
      if (keep_unary) {
        options <- bitwOr(options, bitwShiftL(1L, 4))
      }
      if (keep_input_roots) {
        options <- bitwOr(options, bitwShiftL(1L, 5))
      }
      if (keep_unary_in_individuals) {
        options <- bitwOr(options, bitwShiftL(1L, 6))
      }
      if (!filter_nodes) {
        options <- bitwOr(options, bitwShiftL(1L, 7))
      }
      if (!update_sample_flags) {
        options <- bitwOr(options, bitwShiftL(1L, 8))
      }

      node_map <- rtsk_table_collection_simplify(
        tc = self$xptr,
        samples = samples,
        options = options
      )

      if (record_provenance) {
        json_bool <- function(value) {
          if (value) "true" else "false"
        }
        samples_json <- if (is.null(samples)) {
          "null"
        } else {
          paste0("[", paste(samples, collapse = ","), "]")
        }
        package_version <- as.character(utils::packageVersion("RcppTskit"))
        provenance_record <- paste0(
          '{"schema_version":"1.0.0",',
          '"software":{"name":"RcppTskit","version":"',
          package_version,
          '"},"parameters":{"command":"simplify","samples":',
          samples_json,
          ',"reduce_to_site_topology":',
          json_bool(reduce_to_site_topology),
          ',"filter_populations":',
          json_bool(filter_populations),
          ',"filter_individuals":',
          json_bool(filter_individuals),
          ',"filter_sites":',
          json_bool(filter_sites),
          ',"filter_nodes":',
          json_bool(filter_nodes),
          ',"update_sample_flags":',
          json_bool(update_sample_flags),
          ',"keep_unary":',
          json_bool(keep_unary),
          ',"keep_unary_in_individuals":',
          json_bool(keep_unary_in_individuals),
          ',"keep_input_roots":',
          json_bool(keep_input_roots),
          '},"environment":{}}'
        )
        self$provenance_table_add_row(
          record = provenance_record
        )
      }
      return(node_map)
    },

    #' @description Get the number of provenances in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_provenances()
    num_provenances = function() {
      rtsk_table_collection_get_num_provenances(self$xptr)
    },

    #' @description Add a row to the provenance table.
    #' @param record character string record for the new provenance.
    #' @param timestamp optional character string timestamp for the new
    #'   provenance. If provided, it should be in ISO8601 form. If
    #'   \code{NULL}, a current UTC timestamp in ISO8601 form is generated.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.ProvenanceTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added provenance.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$provenance_table_add_row(
    #'   record = "{\"software\":\"RcppTskit\"}",
    #'   timestamp = "2025-01-01T00:00:00Z"
    #' )
    #' tc$provenance_table_get_row(new_id)
    provenance_table_add_row = function(record, timestamp = NULL) {
      validate_character_scalar_arg(record, "record")
      timestamp_value <- if (is.null(timestamp)) {
        strftime(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
      } else {
        validate_character_scalar_arg(timestamp, "timestamp")
        as.character(timestamp)
      }
      rtsk_provenance_table_add_row(
        tc = self$xptr,
        timestamp = timestamp_value,
        record = as.character(record)
      )
    },

    #' @description Get one row from the provenance table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.ProvenanceTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{timestamp},
    #'   and \code{record}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' id <- tc$provenance_table_add_row(
    #'   record = "{}", timestamp = "2025-01-01T00:00:00Z"
    #' )
    #' tc$provenance_table_get_row(id)
    provenance_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_provenance_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of populations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_populations()
    num_populations = function() {
      rtsk_table_collection_get_num_populations(self$xptr)
    },

    #' @description Add a row to the population table.
    #' @param metadata for the new population; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.PopulationTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added population.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$population_table_add_row(metadata = "abc")
    #' tc$population_table_get_row(new_id)
    population_table_add_row = function(metadata = NULL) {
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_population_table_add_row(
        tc = self$xptr,
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the population table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.PopulationTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id} and \code{metadata}
    #'   (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$population_table_get_row(0)
    population_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_population_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of migrations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_migrations()
    num_migrations = function() {
      rtsk_table_collection_get_num_migrations(self$xptr)
    },

    #' @description Add a row to the migration table.
    #' @param left numeric scalar left coordinate (inclusive) for the new
    #'   migration.
    #' @param right numeric scalar right coordinate (exclusive) for the new
    #'   migration.
    #' @param node integer or integer-valued numeric scalar node ID (0-based).
    #' @param source integer or integer-valued numeric scalar source population
    #'   ID (0-based).
    #' @param dest integer or integer-valued numeric scalar destination
    #'   population ID (0-based).
    #' @param time numeric scalar time of the migration event.
    #' @param metadata for the new migration; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MigrationTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added migration.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_population <- tc$population_table_add_row(metadata = "new-population")
    #' migrating_node <- tc$node_table_add_row(time = 0.5, population = new_population)
    #' new_id <- tc$migration_table_add_row(
    #'   left = 0,
    #'   right = 1,
    #'   node = migrating_node,
    #'   source = 0L,
    #'   dest = new_population,
    #'   time = 1.0,
    #'   metadata = "abc"
    #' )
    #' tc$migration_table_get_row(new_id)
    migration_table_add_row = function(
      left,
      right,
      node,
      source,
      dest,
      time,
      metadata = NULL
    ) {
      validate_numeric_scalar_arg(left, "left")
      validate_numeric_scalar_arg(right, "right")
      if (as.numeric(left) >= as.numeric(right)) {
        stop("left must be strictly less than right!")
      }
      validate_row_index(node, "node")
      validate_row_index(source, "source")
      validate_row_index(dest, "dest")
      validate_numeric_scalar_arg(time, "time")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_migration_table_add_row(
        tc = self$xptr,
        left = as.numeric(left),
        right = as.numeric(right),
        node = as.integer(node),
        source = as.integer(source),
        dest = as.integer(dest),
        time = as.numeric(time),
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the migration table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MigrationTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{left}, \code{right},
    #'   \code{node}, \code{source}, \code{dest}, \code{time}, and
    #'   \code{metadata} (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' if (tc$num_migrations() == 0L) {
    #'   tc$migration_table_add_row(
    #'     left = 0, right = 1, node = 0L, source = 0L, dest = 0L, time = 1
    #'   )
    #' }
    #' tc$migration_table_get_row(0)
    migration_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_migration_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of individuals in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_individuals()
    num_individuals = function() {
      rtsk_table_collection_get_num_individuals(self$xptr)
    },

    #' @description Add a row to the individual table.
    #' @param flags integer or integer-valued numeric scalar bitwise flags for
    #'   the new individual. Values from 0 through 2^31 - 1 are supported.
    #' @param location numeric vector with the location of the new individual;
    #'   \code{NULL} stores an empty location.
    #' @param parents integer or integer-valued numeric vector with parent
    #'   individual IDs (0-based); \code{NULL} stores no parents.
    #' @param metadata for the new individual; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.IndividualTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added individual.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$individual_table_add_row(
    #'   flags = 3L,
    #'   location = c(2, 11),
    #'   parents = c(1L, 3L),
    #'   metadata = "abc"
    #' )
    #' tc$individual_table_get_row(new_id)
    individual_table_add_row = function(
      flags = 0L,
      location = NULL,
      parents = NULL,
      metadata = NULL
    ) {
      validate_integer_scalar_arg(flags, "flags", minimum = 0L)
      validate_optional_numeric_vector_arg(location, "location")
      validate_optional_integer_vector_arg(parents, "parents")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_individual_table_add_row(
        tc = self$xptr,
        flags = as.integer(flags),
        location = if (is.null(location)) NULL else as.numeric(location),
        parents = if (is.null(parents)) NULL else as.integer(parents),
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the individual table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.IndividualTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{flags},
    #'   \code{location}, \code{parents}, and \code{metadata}
    #'   (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$individual_table_get_row(0)
    individual_table_get_row = function(index) {
      validate_row_index(index)
      row <- rtsk_individual_table_get_row(self$xptr, index = as.integer(index))
      row[c("id", "flags", "location", "parents", "metadata")]
    },

    #' @description Get the number of nodes in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_nodes()
    num_nodes = function() {
      rtsk_table_collection_get_num_nodes(self$xptr)
    },

    #' @description Add a row to the node table.
    #' @param flags integer or integer-valued numeric scalar bitwise flags for
    #'   the new node. Values from 0 through 2^31 - 1 are supported.
    #' @param time numeric scalar birth time for the new node.
    #' @param population integer or integer-valued numeric scalar population ID
    #'   (0-based); use \code{-1} or \code{NULL} if unknown. Both store
    #'   \code{TSK_NULL}.
    #' @param individual integer or integer-valued numeric scalar individual ID
    #'   (0-based); use \code{-1} or \code{NULL} if unknown. Both store
    #'   \code{TSK_NULL}.
    #' @param metadata for the new node; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.NodeTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added node.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$node_table_add_row(
    #'   flags = 1L, time = 3.5, individual = 0L, metadata = "abc"
    #' )
    #' tc$node_table_get_row(new_id)
    node_table_add_row = function(
      flags = 0L,
      time = 0,
      population = -1L,
      individual = -1L,
      metadata = NULL
    ) {
      validate_integer_scalar_arg(flags, "flags", minimum = 0L)
      validate_numeric_scalar_arg(time, "time")
      validate_integer_scalar_arg(
        population,
        "population",
        minimum = -1L,
        allow_null = TRUE
      )
      validate_integer_scalar_arg(
        individual,
        "individual",
        minimum = -1L,
        allow_null = TRUE
      )
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_node_table_add_row(
        tc = self$xptr,
        flags = as.integer(flags),
        time = as.numeric(time),
        population = if (is.null(population)) -1L else as.integer(population),
        individual = if (is.null(individual)) -1L else as.integer(individual),
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the node table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details In \code{tskit Python}, rows are accessed by indexing a
    #'   \code{NodeTable}, for example \code{tables.nodes[index]}; see
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.NodeTable}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{flags}, \code{time},
    #'   \code{population}, \code{individual}, and \code{metadata}
    #'   (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$node_table_get_row(0L)
    #' (last_node <- as.integer(tc$num_nodes()) - 1L)
    #' tc$node_table_get_row(last_node)
    node_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_node_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of edges in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_edges()
    num_edges = function() {
      rtsk_table_collection_get_num_edges(self$xptr)
    },

    #' @description Add a row to the edge table.
    #' @param left numeric scalar left coordinate (inclusive) for the new edge.
    #' @param right numeric scalar right coordinate (exclusive) for the new
    #'   edge.
    #' @param parent integer or integer-valued numeric scalar parent node ID
    #'   (0-based).
    #' @param child integer or integer-valued numeric scalar child node ID
    #'   (0-based).
    #' @param metadata for the new edge; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.EdgeTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added edge.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' child <- tc$node_table_add_row(time = 0.0)
    #' new_id <- tc$edge_table_add_row(
    #'   left = 0, right = 50, parent = 16L, child = child, metadata = "abc"
    #' )
    #' tc$edge_table_get_row(new_id)
    edge_table_add_row = function(
      left,
      right,
      parent,
      child,
      metadata = NULL
    ) {
      validate_numeric_scalar_arg(left, "left")
      validate_numeric_scalar_arg(right, "right")
      if (as.numeric(left) >= as.numeric(right)) {
        stop("left must be strictly less than right!")
      }
      validate_row_index(parent, "parent")
      validate_row_index(child, "child")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_edge_table_add_row(
        tc = self$xptr,
        left = as.numeric(left),
        right = as.numeric(right),
        parent = as.integer(parent),
        child = as.integer(child),
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the edge table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.EdgeTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{left}, \code{right},
    #'   \code{parent}, \code{child}, and \code{metadata}
    #'   (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$edge_table_get_row(0)
    edge_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_edge_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of sites in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_sites()
    num_sites = function() {
      rtsk_table_collection_get_num_sites(self$xptr)
    },

    #' @description Add a row to the site table.
    #' @param position numeric scalar position for the new site.
    #' @param ancestral_state character string with the ancestral state.
    #' @param metadata for the new site; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.SiteTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added site.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$site_table_add_row(
    #'   position = 2.5, ancestral_state = "T", metadata = "abc"
    #' )
    #' tc$site_table_get_row(new_id)
    site_table_add_row = function(
      position,
      ancestral_state,
      metadata = NULL
    ) {
      validate_numeric_scalar_arg(position, "position")
      validate_character_scalar_arg(ancestral_state, "ancestral_state")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_site_table_add_row(
        tc = self$xptr,
        position = as.numeric(position),
        ancestral_state = as.character(ancestral_state),
        metadata = metadata_raw
      )
    },

    #' @description Get one row from the site table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.SiteTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{position},
    #'   \code{ancestral_state}, and \code{metadata}
    #'   (as raw bytes without metadata-schema decoding).
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$site_table_get_row(0)
    site_table_get_row = function(index) {
      validate_row_index(index)
      row <- rtsk_site_table_get_row(self$xptr, index = as.integer(index))
      row[c("id", "position", "ancestral_state", "metadata")]
    },

    #' @description Get the number of mutations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_mutations()
    num_mutations = function() {
      rtsk_table_collection_get_num_mutations(self$xptr)
    },

    #' @description Add a row to the mutation table.
    #' @param site integer or integer-valued numeric scalar site ID (0-based).
    #' @param node integer or integer-valued numeric scalar node ID (0-based).
    #' @param derived_state character string with the derived state.
    #' @param parent integer or integer-valued numeric scalar parent mutation ID
    #'   (0-based); use \code{-1} or \code{NULL} if unknown. Both store
    #'   \code{TSK_NULL}.
    #' @param metadata for the new mutation; accepts \code{NULL},
    #'   a raw vector, or a character vector of length 1. Values are stored as
    #'   raw bytes without metadata-schema validation or encoding.
    #' @param time numeric scalar mutation time. Use \code{NULL} (the default)
    #'   or \code{NaN} if unknown; both store \code{TSK_UNKNOWN_TIME}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MutationTable.add_row}.
    #'   Metadata schemas are not currently applied.
    #' @return An integer row index and hence ID (0-based) of the newly added mutation.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' new_id <- tc$mutation_table_add_row(
    #'   site = 0L, node = 16L, derived_state = "T", metadata = "abc"
    #' )
    #' tc$mutation_table_get_row(new_id)
    mutation_table_add_row = function(
      site,
      node,
      derived_state,
      parent = -1L,
      metadata = NULL,
      time = NULL
    ) {
      validate_row_index(site, "site")
      validate_row_index(node, "node")
      validate_character_scalar_arg(derived_state, "derived_state")
      validate_integer_scalar_arg(
        parent,
        "parent",
        minimum = -1L,
        allow_null = TRUE
      )
      metadata_raw <- validate_metadata_arg(metadata)
      validate_numeric_scalar_arg(
        time,
        "time",
        allow_null = TRUE,
        allow_nan = TRUE
      )
      rtsk_mutation_table_add_row(
        tc = self$xptr,
        site = as.integer(site),
        node = as.integer(node),
        derived_state = as.character(derived_state),
        parent = if (is.null(parent)) -1L else as.integer(parent),
        metadata = metadata_raw,
        time = if (is.null(time)) NaN else as.numeric(time)
      )
    },

    #' @description Get one row from the mutation table.
    #' @param index integer or numeric scalar row index (0-based).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MutationTable.__getitem__}.
    #'   The function accepts numeric \code{index} for ease of use, but converts
    #'   it to integer after checking that conversion to 32-bit integer succeeds.
    #'   Unlike Python table indexing, negative indices are not supported.
    #' @return A named list with fields \code{id}, \code{site}, \code{node},
    #'   \code{derived_state}, \code{parent}, \code{metadata}
    #'   (as raw bytes without metadata-schema decoding), and \code{time}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$mutation_table_get_row(0)
    mutation_table_get_row = function(index) {
      validate_row_index(index)
      row <- rtsk_mutation_table_get_row(self$xptr, index = as.integer(index))
      row[c(
        "id",
        "site",
        "node",
        "derived_state",
        "parent",
        "metadata",
        "time"
      )]
    },

    #' @description Get the sequence length.
    #' @return A numeric.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$sequence_length()
    sequence_length = function() {
      rtsk_table_collection_get_sequence_length(self$xptr)
    },

    #' @description Get the time units string.
    #' @return A character.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$time_units()
    time_units = function() {
      rtsk_table_collection_get_time_units(self$xptr)
    },

    #' @description Get whether the table collection has edge indexes.
    #' @return A logical.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    has_index = function() {
      rtsk_table_collection_has_index(self$xptr)
    },

    #' @description Build edge indexes for this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.build_index}.
    #' @return No return value; called for side effects.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    #' tc$drop_index()
    #' tc$has_index()
    #' tc$build_index()
    #' tc$has_index()
    build_index = function() {
      rtsk_table_collection_build_index(self$xptr)
    },

    #' @description Drop edge indexes for this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TableCollection.drop_index}.
    #' @return No return value; called for side effects.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    #' tc$drop_index()
    #' tc$has_index()
    drop_index = function() {
      rtsk_table_collection_drop_index(self$xptr)
    },

    #' @description Get whether the table collection has a reference genome sequence.
    #' @return A logical.
    #' @examples
    #' tc_file1 <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc_file2 <- system.file("examples/test_with_ref_seq.trees", package = "RcppTskit")
    #' tc1 <- tc_load(tc_file1)
    #' tc1$has_reference_sequence()
    #' tc2 <- tc_load(tc_file2)
    #' tc2$has_reference_sequence()
    has_reference_sequence = function() {
      rtsk_table_collection_has_reference_sequence(self$xptr)
    },

    #' @description Get the UUID string of the file the table collection was
    #'   loaded from.
    #' @return A character; \code{NA_character_} when file is information is
    #'   unavailable.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$file_uuid()
    file_uuid = function() {
      rtsk_table_collection_get_file_uuid(self$xptr)
    },

    #' @description This function saves a table collection from \code{R} to disk
    #'   and loads it into reticulate \code{Python} for use with the
    #'   \code{tskit Python} API.
    #' @param tskit_module reticulate \code{Python} module of \code{tskit}.
    #'   By default, it calls \code{\link{get_tskit_py}} to obtain the module.
    #' @param cleanup logical; delete the temporary file at the end of the function?
    #' @details See \url{https://tskit.dev/tutorials/tables_and_editing.html#tables-and-editing}
    #'   on what you can do with the tables.
    #' @return \code{TableCollection} object in reticulate \code{Python}.
    #' @seealso \code{\link{tc_py_to_r}}, \code{\link{tc_load}}, and
    #'   \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @examples
    #' \dontrun{
    #'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #'   tc_r <- tc_load(ts_file)
    #'   is(tc_r)
    #'   tc_r$print()
    #'
    #'   # Transfer the table collection to reticulate Python and use tskit Python API
    #'   tskit <- get_tskit_py()
    #'   if (check_tskit_py(tskit)) {
    #'     tc_py <- tc_r$r_to_py()
    #'     is(tc_py)
    #'     tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'     tmp
    #'     tc_py$individuals$num_rows # 2
    #'     tc_py$nodes$num_rows # 8
    #'     tc_py$nodes$time # 0.0 ... 5.0093910
    #'   }
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      rtsk_table_collection_r_to_py(
        self$xptr,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    },

    #' @description Print a summary of a table collection and its contents.
    #' @return A list with two data.frames; the first contains table collection
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata. All columns are characters
    #'   since output types differ across the entries. Use individual getters
    #'   to obtain raw values before they are converted to character.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(file = ts_file)
    #' tc$print()
    #' tc
    print = function() {
      ret <- rtsk_table_collection_print(self$xptr)
      # These are not hit since testing is not interactive
      # nocov start
      if (interactive()) {
        cat("Object of class 'TableCollection'\n")
        print(ret)
      }
      # nocov end
      invisible(ret)
    }
  )
)
