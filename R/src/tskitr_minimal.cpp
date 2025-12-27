#include <Rcpp.h>
#include <tskit.h>

using namespace Rcpp;

// Baby steps development/exploration to see how this could work

// [[Rcpp::export]]
List rcpp_hello_world() {
    CharacterVector x = CharacterVector::create( "foo", "bar" )  ;
    NumericVector y   = NumericVector::create( 0.0, 1.0 ) ;
    List z            = List::create( x, y ) ;
    return z ;
}

//' Report the version of tskit C API
//'
//' @details The version is defined by tstkit in the header \code{tskit/core.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'   \code{patch}.
//' @seealso tskit header file \code{tskit/core.h}.
// [[Rcpp::export]]
Rcpp::IntegerVector tskit_version() {
  using Rcpp::_;
  using Rcpp::IntegerVector;
  return IntegerVector::create(_["major"] = TSK_VERSION_MAJOR,
                               _["minor"] = TSK_VERSION_MINOR,
                               _["patch"] = TSK_VERSION_PATCH);
}

// [[Rcpp::export]]
int tskit_table_collection_init_ok() {
    int ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    tsk_table_collection_free(&tables);
    return ret;
}

// [[Rcpp::export]]
int tskit_table_collection_num_nodes_zero() {
    int n, ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    if (ret != 0) {
        Rcpp::stop(tsk_strerror(ret));
    } else {
        n = (int) tables.nodes.num_rows;
    }
    tsk_table_collection_free(&tables);
    return n;
}

/*
install.packages("reticulate")
reticulate::py_require("msprime")
msprime <- reticulate::import("msprime")
ts <- msprime$sim_ancestry(80, sequence_length=1e4, recombination_rate=1e-4, random_seed=42)
ts
ts$num_nodes
ts$dump("test.trees")
tskit <- reticulate::import("tskit")
ts2 <- tskit$load("test.trees")
ts2
ts2$num_nodes
*/

// [[Rcpp::export]]
int tskit_treeseq_num_nodes_from_file(std::string file) {
    int n, ret;
    tsk_treeseq_t ts;
    ret = tsk_treeseq_load(&ts, file.c_str(), 0);
    if (ret != 0) {
        Rcpp::stop(tsk_strerror(ret));
    } else {
        n = (int) tsk_treeseq_get_num_nodes(&ts);
    }
    tsk_treeseq_free(&ts);
    return n;
}

/*
tskit_treeseq_num_nodes_from_file("test.trees")
*/

// [[Rcpp::export]]
SEXP tskit_treeseq_load_xptr(std::string file) {
    int ret;
    tsk_treeseq_t *ts = new tsk_treeseq_t();
    ret = tsk_treeseq_load(ts, file.c_str(), 0);
    if (ret != 0) {
        delete ts;
        Rcpp::stop(tsk_strerror(ret));
    }
    Rcpp::XPtr<tsk_treeseq_t> xp(ts, true); // true => delete on GC
    return xp;
}

// [[Rcpp::export]]
int tskit_treeseq_num_nodes(SEXP xp) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> ts(xp);
    n = (int) tsk_treeseq_get_num_nodes(ts);
    return n;
}

/*
ts <- tskit_treeseq_load_xptr("nonexistent.trees")
ts <- tskit_treeseq_load_xptr("test.trees")
ts
is(ts)
tskit_treeseq_num_nodes()
tskit_treeseq_num_nodes(tserr)
tskit_treeseq_num_nodes(ts)
n <- tskit_treeseq_num_nodes(ts)
n
is(n)
*/
