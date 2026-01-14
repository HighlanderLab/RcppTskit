#include <tskit/core.h>

void tskitr_bug_assert_c(void) { tsk_bug_assert(0); }

void tskitr_trace_error_c(void) { (void)tsk_trace_error(-1); }
