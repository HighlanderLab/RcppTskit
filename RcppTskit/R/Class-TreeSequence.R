#' @title Succinct tree sequence R6 class (TreeSequence)
#' @description An \code{R6} class holding an external pointer to
#' a tree sequence object. As an \code{R6} class, method-calling looks Pythonic
#' and hence resembles the \code{tskit Python} API. Since the class only
#' holds the pointer, it is lightweight. Currently there is a limited set of
#' \code{R} methods for working with the tree sequence.
#' @export
TreeSequence <- R6Class(
  classname = "TreeSequence",
  public = list(
    #' @field xptr external pointer to the tree sequence
    xptr = "externalptr",

    #' @description Create a \code{\link{TreeSequence}} from a file or an external pointer.
    #'   See \code{\link{ts_load}} for details and examples.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param skip_tables logical; if \code{TRUE}, load only non-table information.
    #' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
    #'   reference genome sequence information.
    #' @param xptr an external pointer (\code{externalptr}) to a tree sequence.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.load}.
    #' @return A \code{\link{TreeSequence}} object.
    #' @seealso \code{\link{ts_load}}
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- TreeSequence$new(file = ts_file)
    #' is(ts)
    #' ts
    #' ts$num_nodes()
    #' # Also
    #' ts <- ts_load(ts_file)
    #' is(ts)
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
        self$xptr <- rtsk_treeseq_load(filename = file, options = options)
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

    #' @description Write a tree sequence to a file.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.dump}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' dump_file <- tempfile()
    #' ts$dump(dump_file)
    #' ts$write(dump_file) # alias
    #' \dontshow{file.remove(dump_file)}
    dump = function(file) {
      rtsk_treeseq_dump(self$xptr, filename = file, options = 0L)
    },

    #' @description Alias for \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @param file see \code{\link[=TreeSequence]{TreeSequence$dump}}.
    write = function(file) {
      self$dump(file = file)
    },

    #' @description Copy the tables into a \code{\link{TableCollection}}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.dump_tables}.
    #' @return A \code{\link{TableCollection}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' tc <- ts$dump_tables()
    #' is(tc)
    dump_tables = function() {
      tc_xptr <- rtsk_treeseq_copy_tables(self$xptr)
      TableCollection$new(xptr = tc_xptr)
    },

    #' @description Return a simplified copy of this tree sequence.
    #' @param samples optional integer vector of distinct node IDs to retain as
    #'   samples. If \code{NULL}, use the nodes currently marked as samples.
    #' @param map_nodes logical; if \code{TRUE}, also return the mapping from
    #'   input node IDs to output node IDs (see also return section).
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
    #' @param keep_input_roots logical; retain topology back to the roots in the
    #'   input tree sequence rather than stopping at samples' MRCAs.
    #' @param record_provenance logical; record this simplify call in the
    #'   returned tree sequence.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.simplify}.
    #'   The input tree sequence is unchanged.
    #' @return A simplified \code{\link{TreeSequence}}. If
    #'   \code{map_nodes = TRUE}, return a named list containing
    #'   \code{tree_sequence} and the integer \code{node_map};
    #'   removed nodes map to \code{-1}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts_simplified <- ts$simplify(samples = c(0L, 1L, 2L, 3L))
    #' c(before = ts$num_nodes(),
    #'   after = ts_simplified$num_nodes())
    simplify = function(
      samples = NULL,
      map_nodes = FALSE,
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
      validate_logical_arg(map_nodes, "map_nodes")
      tables <- self$dump_tables()
      node_map <- tables$simplify(
        samples = samples,
        reduce_to_site_topology = reduce_to_site_topology,
        filter_populations = filter_populations,
        filter_individuals = filter_individuals,
        filter_sites = filter_sites,
        filter_nodes = filter_nodes,
        update_sample_flags = update_sample_flags,
        keep_unary = keep_unary,
        keep_unary_in_individuals = keep_unary_in_individuals,
        keep_input_roots = keep_input_roots,
        record_provenance = record_provenance
      )
      new_ts <- tables$tree_sequence()
      if (map_nodes) {
        return(list(tree_sequence = new_ts, node_map = node_map))
      }
      return(new_ts)
    },

    #' @description Print a summary of a tree sequence and its contents.
    #' @return A list with two data.frames; the first contains tree sequence
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata. All columns are characters
    #'   since output types differ across the entries. Use individual getters
    #'   to obtain raw values before they are converted to character.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$print()
    #' ts
    print = function() {
      ret <- rtsk_treeseq_print(self$xptr)
      # These are not hit since testing is not interactive
      # nocov start
      if (interactive()) {
        cat("Object of class 'TreeSequence'\n")
        print(ret)
      }
      # nocov end
      invisible(ret)
    },

    #' @description This function saves a tree sequence from \code{R} to disk
    #'   and loads it into reticulate \code{Python} for use with the
    #'   \code{tskit Python} API.
    #' @param tskit_module reticulate \code{Python} module of \code{tskit}.
    #'   By default, it calls \code{\link{get_tskit_py}} to obtain the module.
    #' @param cleanup logical; delete the temporary file at the end of the function?
    #' @return \code{TreeSequence} object in reticulate \code{Python}.
    #' @seealso \code{\link{ts_py_to_r}}, \code{\link{ts_load}}, and
    #'   \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @examples
    #' \dontrun{
    #'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #'   ts_r <- ts_load(ts_file)
    #'   is(ts_r)
    #'   ts_r$num_individuals() # 8
    #'
    #'   # Transfer the tree sequence to reticulate Python and use tskit Python API
    #'   tskit <- get_tskit_py()
    #'   if (check_tskit_py(tskit)) {
    #'     ts_py <- ts_r$r_to_py()
    #'     is(ts_py)
    #'     ts_py$num_individuals # 8
    #'     ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'     ts_py$num_individuals # 8
    #'     ts2_py$num_individuals # 2
    #'     ts2_py$num_nodes # 8
    #'     ts2_py$tables$nodes$time # 0.0 ... 5.0093910
    #'   }
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      rtsk_treeseq_r_to_py(
        self$xptr,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    },

    #' @description Iterate over sites as decoded variants.
    #' @param samples Optional integer vector of sample node IDs to decode.
    #' @param isolated_as_missing Logical; decode isolated samples as missing
    #'   data (\code{TRUE}, default) or as ancestral state (\code{FALSE}).
    #' @param alleles Optional character vector of allele states; when set,
    #'   genotypes are indexed to this allele order.
    #' @param impute_missing_data Deprecated alias for
    #'   \code{!isolated_as_missing}.
    #' @param copy Logical; currently only \code{TRUE} is supported.
    #' @param left Left genomic coordinate (inclusive).
    #' @param right Right genomic coordinate (exclusive). \code{NULL} means
    #'   sequence length.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.variants}.
    #' @return A simple iterator object with methods \code{next()} and
    #'   \code{next_variant()} that each return either a variant list or
    #'   \code{NULL} at end.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' it <- ts$variants()
    #' v1 <- it$next_variant()
    #' v2 <- it$next_variant()
    #' is.list(v1)
    #' is.list(v2)
    variants = function(
      samples = NULL,
      isolated_as_missing = TRUE,
      alleles = NULL,
      impute_missing_data = NULL,
      copy = TRUE,
      left = 0,
      right = NULL
    ) {
      if (!is.logical(copy) || length(copy) != 1 || is.na(copy)) {
        stop("copy must be TRUE/FALSE!")
      }
      if (!copy) {
        stop("copy = FALSE is not supported yet!")
      }
      if (!is.null(impute_missing_data)) {
        if (
          !is.logical(impute_missing_data) ||
            length(impute_missing_data) != 1 ||
            is.na(impute_missing_data)
        ) {
          stop("impute_missing_data must be TRUE/FALSE or NULL!")
        }
        mapped <- !impute_missing_data
        if (
          !missing(isolated_as_missing) &&
            !identical(isolated_as_missing, mapped)
        ) {
          stop(
            "isolated_as_missing and impute_missing_data are inconsistent!"
          )
        }
        warning(
          "impute_missing_data is deprecated; use isolated_as_missing",
          call. = FALSE
        )
        isolated_as_missing <- mapped
      }

      iter_xptr <- rtsk_treeseq_init_variants_iterator(
        ts = self$xptr,
        samples = samples,
        isolated_as_missing = isolated_as_missing,
        alleles = alleles,
        left = left,
        right = if (is.null(right)) NA_real_ else right
      )

      env <- new.env(parent = emptyenv())
      env$iter_xptr <- iter_xptr
      next_fun <- function() {
        rtsk_treeseq_next_variant(env$iter_xptr)
      }
      structure(
        list(`next` = next_fun, next_variant = next_fun),
        class = "rtsk_variant_iterator"
      )
    },

    #' @description Get the number of provenances in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_provenances}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_provenances()
    num_provenances = function() {
      rtsk_treeseq_get_num_provenances(self$xptr)
    },

    #' @description Get the number of populations in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_populations}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_populations()
    num_populations = function() {
      rtsk_treeseq_get_num_populations(self$xptr)
    },

    #' @description Get the number of migrations in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_migrations}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_migrations()
    num_migrations = function() {
      rtsk_treeseq_get_num_migrations(self$xptr)
    },

    #' @description Get the number of individuals in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_individuals}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_individuals()
    num_individuals = function() {
      rtsk_treeseq_get_num_individuals(self$xptr)
    },

    #' @description Get the number of samples (of nodes) in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_samples}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_samples()
    num_samples = function() {
      rtsk_treeseq_get_num_samples(self$xptr)
    },

    #' @description Get sample node IDs in this tree sequence.
    #' @param population integer or integer-valued numeric scalar population ID
    #'   (0-based) used to filter samples. If \code{NULL}, do not filter by
    #'   population.
    #' @param time numeric scalar or numeric vector of length 2 used to filter
    #'   samples by node time. A scalar selects samples with approximately equal
    #'   node time. A pair \code{c(min_time, max_time)} selects samples in the
    #'   half-open interval \code{min_time <= time < max_time}. If \code{NULL},
    #'   do not filter by time.
    #' @return An integer vector containing the sample node IDs (0-based) in
    #'   numerical order.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.samples}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$samples()
    samples = function(population = NULL, time = NULL) {
      validate_row_index(population, "population", allow_null = TRUE)
      validate_optional_numeric_vector_arg(
        time,
        "time",
        lengths = c(1L, 2L),
        error_message = paste0(
          "time must be either a single value or a pair of values ",
          "(min_time, max_time)."
        )
      )
      needs_node_data <- !is.null(population) || !is.null(time)
      sample_data <- if (needs_node_data) {
        rtsk_treeseq_get_sample_node_data(self$xptr)
      } else {
        NULL
      }
      samples <- if (needs_node_data) {
        sample_data$samples
      } else {
        rtsk_treeseq_get_samples(self$xptr)
      }
      keep <- rep(TRUE, length(samples))

      if (!is.null(population)) {
        sample_population <- sample_data$population
        keep <- keep & (sample_population == as.integer(population))
      }

      if (!is.null(time)) {
        sample_time <- sample_data$time
        if (length(time) == 1L) {
          keep <- keep & numeric_values_are_close(sample_time, time)
        } else {
          if (time[2] <= time[1]) {
            stop("time_interval max is less than or equal to min.")
          }
          keep <- keep &
            (sample_time >= time[1]) &
            (sample_time < time[2])
        }
      }

      samples[keep]
    },

    #' @description Get the number of nodes in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_nodes}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_nodes()
    num_nodes = function() {
      rtsk_treeseq_get_num_nodes(self$xptr)
    },

    #' @description Get the number of edges in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_nodes}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_edges()
    num_edges = function() {
      rtsk_treeseq_get_num_edges(self$xptr)
    },

    #' @description Get the number of trees in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_trees}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_trees()
    num_trees = function() {
      rtsk_treeseq_get_num_trees(self$xptr)
    },

    #' @description Get the number of sites in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_sites}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_sites()
    num_sites = function() {
      rtsk_treeseq_get_num_sites(self$xptr)
    },

    #' @description Get the number of mutations in a tree sequence.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.num_mutations}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_mutations()
    num_mutations = function() {
      rtsk_treeseq_get_num_mutations(self$xptr)
    },

    #' @description Get the sequence length.
    #' @return A numeric.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.sequence_length}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$sequence_length()
    sequence_length = function() {
      rtsk_treeseq_get_sequence_length(self$xptr)
    },

    #' @description Get the discrete genome status.
    #' @details Returns \code{TRUE} if all genomic coordinates in the tree
    #'   sequence are discrete integer values.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.discrete_genome}.
    #' @return A logical.
    #' @examples
    #' ts_file1 <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts_file2 <- system.file("examples/test_non_discrete_genome.trees", package = "RcppTskit")
    #' ts1 <- ts_load(ts_file1)
    #' ts1$discrete_genome()
    #' ts2 <- ts_load(ts_file2)
    #' ts2$discrete_genome()
    discrete_genome = function() {
      rtsk_treeseq_get_discrete_genome(self$xptr)
    },

    #' @description Get whether the tree sequence has a reference genome sequence.
    #' @return A logical.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.has_reference_sequence}.
    #' @examples
    #' ts_file1 <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts_file2 <- system.file("examples/test_with_ref_seq.trees", package = "RcppTskit")
    #' ts1 <- ts_load(ts_file1)
    #' ts1$has_reference_sequence()
    #' ts2 <- ts_load(ts_file2)
    #' ts2$has_reference_sequence()
    has_reference_sequence = function() {
      rtsk_treeseq_has_reference_sequence(self$xptr)
    },

    #' @description Get the time units string.
    #' @return A character.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.time_units}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$time_units()
    time_units = function() {
      rtsk_treeseq_get_time_units(self$xptr)
    },

    #' @description Get the discrete time status.
    #' @details Returns \code{TRUE} if all time values in the tree sequence are
    #'   discrete integer values.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.discrete_time}.
    #' @return A logical.
    #' @examples
    #' ts_file1 <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts_file2 <- system.file("examples/test_discrete_time.trees", package = "RcppTskit")
    #' ts1 <- ts_load(ts_file1)
    #' ts1$discrete_time()
    #' ts2 <- ts_load(ts_file2)
    #' ts2$discrete_time()
    discrete_time = function() {
      rtsk_treeseq_get_discrete_time(self$xptr)
    },

    #' @description Get the min time in node table and mutation table.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.min_time}.
    #' @return A numeric.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$min_time()
    min_time = function() {
      rtsk_treeseq_get_min_time(self$xptr)
    },

    #' @description Get the max time in node table and mutation table.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.max_time}.
    #' @return A numeric.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$max_time()
    max_time = function() {
      rtsk_treeseq_get_max_time(self$xptr)
    },

    # No Python equivalent in the docs as of 2026-03-03
    #' @description Get the length of metadata in a tree sequence and its tables.
    #' @return A named list with the length of metadata, each as a signed 64 bit
    #'   integer \code{bit64::integer64}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$metadata_length()
    metadata_length = function() {
      rtsk_treeseq_metadata_length(self$xptr)
    },

    # No Python equivalent in the docs as of 2026-03-03
    #' @description Get the UUID string of the file the tree sequence was
    #'   loaded from.
    #' @return A character; \code{NA_character_} when file is information is
    #'   unavailable.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$file_uuid()
    file_uuid = function() {
      rtsk_treeseq_get_file_uuid(self$xptr)
    }
  )
)
