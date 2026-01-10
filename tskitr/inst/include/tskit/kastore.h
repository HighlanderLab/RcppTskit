// Shim header to use tskit C API in Rcpp code in an R session or an R package
#include <tskit/tskit/kastore.h>

// Redefinition of kas_bug_assert to avoid aborting R sessions with tskit C API
// (following R extensions manual recommendations).
// Since kastore is only used by tskit C API we provide only C macros.
#ifndef __cplusplus
// Override kas_bug_assert to use R-style error handling in C code.
#undef kas_bug_assert
#include <R_ext/Error.h>
#define kas_bug_assert(condition)                                              \
  do {                                                                         \
    if (!(condition)) {                                                        \
      Rf_error("Bug detected in %s at line %d. %s", __FILE__, __LINE__,        \
               KAS_BUG_ASSERT_MESSAGE);                                        \
    }                                                                          \
  } while (0)
#endif
