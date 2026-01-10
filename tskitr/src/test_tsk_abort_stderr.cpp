#include <Rcpp.h>
#include <tskit/core.h>

extern "C" void tskitr_bug_assert_c(void);

// [[Rcpp::export]]
void test_tsk_bug_assert_c() { tskitr_bug_assert_c(); }

// [[Rcpp::export]]
void test_tsk_bug_assert_cpp() { tsk_bug_assert(0); }

extern "C" void tskitr_trace_error_c(void);

// [[Rcpp::export]]
void test_tsk_trace_error_c() { tskitr_trace_error_c(); }

// [[Rcpp::export]]
void test_tsk_trace_error_cpp() { tsk_trace_error(-1); }
