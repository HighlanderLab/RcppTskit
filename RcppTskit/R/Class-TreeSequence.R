# ---- S4 class ----

#' @description TODO and add a title
#'
#' @slot/field pointer TODO
#'
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- new("TreeSequenceS4", pointer = ts_pointer)
#' is(ts)
#' ts
# TODO: Create ts_load(file, options) that calls
#       stopifnot(is.character(file))
#       stopifnot(is.numeric(options))
#       if (!is.integer(options)) options <- as.integer(options)
#       ts_pointer <- ts_load_ptr(file, options)
#       new("TreeSequenceS4", pointer = ts_pointer)
#
#       Create ts_init() that calls
#       ts_pointer <- ts_init_ptr() # this does not exist yet!
#       new("TreeSequenceS4", pointer = ts_pointer)
setClass("TreeSequenceS4", slots = c(pointer = "externalptr"))

setMethod("show", signature(object = "TreeSequenceS4"), function(object) {
  cat("An object of class", classLabel(class(object)), "\n")
  print(ts_print(object@pointer))
  invisible()
})

# ---- R6 class ----

TreeSequenceR6 <- R6::R6Class(
  "TreeSequenceR6",
  public = list(
    #' @field pointer TODO
    pointer = "externalptr",

    #' @description TODO and add a title
    #'
    #' @param file TODO
    #' @param options TODO
    #'
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- TreeSequenceR6$new(ts_file)
    #' is(ts)
    # TODO: Create ts_load(file, options) that calls
    #       TreeSequenceR6$new(file = ts_file, options = options)
    #
    #       Create ts_init() that calls
    #       TreeSequenceR6$new(file = NULL)
    initialize = function(file, options = 0L) {
      if (is.null(file)) {
        # TODO: Implement ts_init_ptr()
        # self$pointer <- ts_init_ptr()
      } else {
        stopifnot(is.character(file))
        stopifnot(is.numeric(options))
        if (!is.integer(options)) {
          options <- as.integer(options)
        }
        # TODO: switch to ts_load_ptr()
        self$pointer <- ts_load(file, options = options)
      }
      invisible(self)
    },

    #' @description TODO
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- TreeSequenceR6$new(ts_file)
    #' ts
    print = function() {
      print(ts_print(self$pointer))
    }
  )
)

# ---- Examples ----

#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # TODO: implement ts_load() that calls ts_load() and returns ts_s4
#' ts_pointer <- ts_load(ts_file)
#' ts_s4 <- new("TreeSequenceS4", pointer = ts_pointer)
#' ts_s4
#' ts_s4@pointer
#'
#' ts_r6 <- TreeSequenceR6$new(ts_file)
#' ts_r6
#' ts_r6$pointer

# TODO: Develop C++ code to grow tree sequence using S4 class
#       ts_grow(ts_s4@pointer)

# TODO: Develop C++ code to grow tree sequence using R6 class
#       ts_grow(ts_r6$pointer)

# TODO: Time the above approaches

# Hmm, the above timing exercise will not be informative
# because C++ code will operate with pointer, which will be part of
# the classes and the C++ code will hence run as fast as it can.
# So, we should really only be timing how fast/slow would be operations
# with the S4 or R6 class on R side!?
#
# What will we be really doing in AlphaSimR?
# Everytime we will call cross() functions, which does meiosis,
# we will grow the SP$ts object. This will be done on C++ side.
# This might look something like this:
#
# progeny <- randCross(parents, ..., simParam = SP)
# - this calls meiosis and already stores SP$pedigree and SP$trackRec
# - so we would call C++ code on SP$ts as we do with SP$pedigree and SP$trackRec
#
# R6 class is pass by reference (change in the object is global),
# but since we would be updating SP$ts$pointer I don't think this advantage matters at all,
# namely the object SP$ts$pointer only points to real ts object in the session.
#
# S4 class is pass by value (change in the object is local and becomes global only if we reassign),
# but since we would be updating SP$ts@pointer I don't think this advantage matters at all,
# namely the object SP$ts@pointer only points to real ts object in the session.
#
# I hope I am getting the above right!?
#
# ts_s4@pointer <- ts_pointer
# ts_s4@pointer
# ts_r6$pointer <- ts_pointer
# ts_r6$pointer

# TODO: Do we want to expose tree sequence building C functions as R functions
#       so that R users could easy record tree sequence!?
#       This could easily become a missing creep!
#       I think we can just relly on either tskit C API or Python API for this.
#       I could be persuaded, but let's punt this down the road.
#       An argument for this could be that some R users don't have C/C++ skills so they
#       can be stuck on not being able to generate tree sequence in their packages/scripts,
#       where calling Python many times might not be optimal.
