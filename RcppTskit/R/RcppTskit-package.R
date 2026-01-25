# Contains the package description and .onLoad() function

#' @description
#' Tskit enables performant storage, manipulation, and analysis of
#' ancestral recombination graphs (ARGs) using succinct tree sequence encoding.
#' See https://tskit.dev for project news, documentation, and tutorials.
#' Tskit provides Python, C, and Rust APIs. The Python API can be called from R
#' via the `reticulate` R package to seamlessly load and analyse a tree sequence
#' as described at https://tskit.dev/tutorials/tskitr.html.
#' `RcppTskit` provides R access to the `tskit` C API for use cases where the
#' `reticulate` approach is not optimal. For example, for high-performance
#' and low-level work with tree sequences. Currently, `RcppTskit` provides a very
#' limited number of R functions due to the availability of extensive Python API
#' and the `reticulate` approach.
#' @keywords internal
#'
#' @useDynLib RcppTskit, .registration = TRUE
#' @importFrom methods is
#' @importFrom R6 R6Class
#' @importFrom Rcpp registerPlugin cppFunction
#' @importFrom reticulate is_py_object import py_module_available py_require
#'
#' @examples
#' \dontshow{# Providing the examples here so we test them via R CMD check}
#' # Here are examples showcasing what you can do with RcppTskit
#'
#' # 1) Load a tree sequence into R and summarise it
#' # Load a tree sequence
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # Print summary of the tree sequence
#' ts$num_individuals()
#' ts
#'
#' # 2) Pass tree sequence between R and reticulate or standard Python
#'
#' # Tree sequence in R
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # If you have a tree sequence in R and want to use tskit Python API, use
#' ts_py <- ts$r_to_py()
#' # ... continue in reticulate Python ...
#' ts_py$num_individuals # 80
#' ts2_py = ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#' ts2_py$num_individuals # 2
#' # ... and to bring it back to R use ...
#' ts2 <- ts_py_to_r(ts2_py)
#' ts2$num_individuals() # 2
#'
#' # If you prefer standard (non-reticulate) Python, use
#' ts_file <- tempfile()
#' print(ts_file)
#' ts$dump(file = ts_file)
#' # ... continue in standard Python ...
#' # import tskit
#' # ts = tskit.load("insert_ts_file_path_here")
#' # ts.num_individuals # 80
#' # ts2 = ts.simplify(samples = [0, 1, 2, 3])
#' # ts2.num_individuals # 2
#' # ts2.dump("insert_ts_file_path_here")
#' # ... and to bring it back to R use ...
#' ts2 <- ts_load(ts_file)
#' ts$num_individuals() # 2 (if you have ran the above Python code)
#'
#' # 3) Call tskit C API in C++ code in R session or script
#' library(Rcpp)
#' # Write and compile a C++ function
#' codeString <- '
#'   #include <tskit.h>
#'   int ts_num_individuals(SEXP ts) {
#'     Rcpp::XPtr<tsk_treeseq_t> ts_xptr(ts);
#'     return (int) tsk_treeseq_get_num_individuals(ts_xptr);
#'   }'
#' ts_num_individuals2 <- Rcpp::cppFunction(code=codeString,
#'                                          depends="RcppTskit",
#'                                          plugins="RcppTskit")
#' # We must specify both the `depends` and `plugins` arguments!
#'
#' # Load a tree sequence
#' ts_file <- system.file("examples/test.trees", package="RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # Apply the compiled function
#' ts_num_individuals2(ts$pointer)
#'
#' # An identical RcppTskit implementation
#' ts$num_individuals()
#'
#' # 4) Call `tskit` C API in C++ code in another R package
#' # TODO: Show vignette here
#' #       https://github.com/HighlanderLab/RcppTskit/issues/10
"_PACKAGE"

#' Providing an inline plugin so we can call tskit C API with functions like
#' cppFunction() or sourceCpp(). See package files on how this is used (search
#' for cppFunction).
#
#' Studying RcppArmadillo, I don't see it uses Rcpp::registerPlugin() anywhere,
#' but an LLM suggested that this is because Armadillo is header-only library
#' so `depends = "RcppArmadillo"` adds include paths to headers, while there is
#' no library that we should link to. RcppTskit is different because we must link
#' against the compiled RcppTskit library file. The `plugins` (or `PKG_LIBS`)
#' is required for linking flags in addition to `depends` for include headers.
#' @noRd
.onLoad <- function(libname, pkgname) {
  # nocov start
  Rcpp::registerPlugin(name = "RcppTskit", plugin = function() {
    # See ?Rcpp::registerPlugin and ?inline::registerPlugin on what the plugin
    # function should return (a list with additional includes, environment
    # variables, such as PKG_LIBS, and other compilation context).
    libdir <- system.file("libs", package = "RcppTskit")
    if (!nzchar(libdir)) {
      stop("Unable to locate the RcppTskit libs directory!")
    }
    libdirs <- libdir
    if (.Platform$OS.type == "windows") {
      libdirs <- c(libdirs, file.path(libdir, .Platform$r_arch))
    }
    candidates <- c(
      "RcppTskit.so", # Unix/Linux and macOS
      "RcppTskit.dylib", # macOS (backup to RcppTskit.so)
      "RcppTskit.dll.a", # Windows (MinGW/Rtools)
      "RcppTskit.lib", # Windows (MSVC, backup)
      "RcppTskit.dll" # Windows (DLL, backup)
    )
    libpaths <- sapply(
      libdirs,
      function(dir) file.path(dir, candidates),
      USE.NAMES = FALSE
    )
    libfile <- libpaths[file.exists(libpaths)][1]
    if (is.na(libfile) || !nzchar(libfile)) {
      stop(
        "Unable to locate the RcppTskit library file in: ",
        paste(libdirs, collapse = ", ")
      )
    }
    list(env = list(PKG_LIBS = shQuote(libfile)))
  })
} # nocov end
