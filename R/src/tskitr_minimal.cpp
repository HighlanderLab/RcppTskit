#include <Rcpp.h>
#include <tskit.h>

// using namespace Rcpp; // to omit Rcpp:: prefix for whole Rcpp API
// using Rcpp::IntegerVector; // to omit Rcpp:: prefix for IntegerVector

//' Report the version of kastore C API
//'
//' @details The version is defined by kastore in the header \code{kastore.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'     \code{patch}.
//' @examples
//' kastore_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector kastore_version() {
    return Rcpp::IntegerVector::create(Rcpp::_["major"] = KAS_VERSION_MAJOR,
                                       Rcpp::_["minor"] = KAS_VERSION_MINOR,
                                       Rcpp::_["patch"] = KAS_VERSION_PATCH);
}

//' Report the version of tskit C API
//'
//' @details The version is defined by tskit in the header \code{tskit/core.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'     \code{patch}.
//' @examples
//' tskit_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector tskit_version() {
    return Rcpp::IntegerVector::create(Rcpp::_["major"] = TSK_VERSION_MAJOR,
                                       Rcpp::_["minor"] = TSK_VERSION_MINOR,
                                       Rcpp::_["patch"] = TSK_VERSION_PATCH);
}

// Baby steps development/exploration to see how this could work

// TODO: Just testing for now, remove later
// rcpp_hello_world()
Rcpp::List rcpp_hello_world() {
    Rcpp::CharacterVector x = Rcpp::CharacterVector::create("foo", "bar");
    Rcpp::NumericVector y   = Rcpp::NumericVector::create(0.0, 1.0);
    Rcpp::List z            = Rcpp::List::create(x, y);
    return z ;
}

// TODO: Just testing for now, remove later
// table_collection_init_check()
int table_collection_init_check() {
    int ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    tsk_table_collection_free(&tables);
    return ret;
}

// TODO: Just testing for now, remove later
// table_collection_num_nodes_zero_check()
int table_collection_num_nodes_zero_check() {
    int n, ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    if (ret != 0) {
        tsk_table_collection_free(&tables);
        Rcpp::stop(tsk_strerror(ret));
    }
    n = (int) tables.nodes.num_rows;
    tsk_table_collection_free(&tables);
    return n;
}

// TODO: Just testing for now, remove later
// treeseq_num_nodes_from_file("nonexistent.trees")
// treeseq_num_nodes_from_file("test.trees")
int treeseq_num_nodes_from_file(std::string file) {
    int n, ret;
    tsk_treeseq_t ts;
    ret = tsk_treeseq_load(&ts, file.c_str(), 0);
    if (ret != 0) {
        tsk_treeseq_free(&ts);
        Rcpp::stop(tsk_strerror(ret));
    }
    n = (int) tsk_treeseq_get_num_nodes(&ts);
    tsk_treeseq_free(&ts);
    return n;
}

// Finalizer function to free tsk_treeseq_t when it is garbage collected
//
// @details Frees memory allocated to a \code{tsk_treeseq_t} object and deletes
//   its pointer.
// @param xptr_sexp an external pointer to a \code{tsk_treeseq_t} object.
static void treeseq_xptr_finalize(SEXP xptr_sexp) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(xptr_sexp);
    if (xptr.get() != NULL) {
        tsk_treeseq_free(xptr.get());
        delete xptr.get();
    }
}

//' Load tree sequence from a file
//'
//' @param file a string specifying the full path of the tree sequence file.
//' @return An external pointer to a \code{tsk_treeseq_t} object.
//' @examples
//' ts_file <- system.file("examples", "test.trees", package = "tskitr")
//' ts <- treeseq_load(ts_file)
//' ts
//' is(ts)
//' treeseq_num_nodes(ts)
//' try(treeseq_load())
//' try(treeseq_load("nonexistent.trees"))
//' @export
// [[Rcpp::export]]
SEXP treeseq_load(std::string file) {
    int ret;
    tsk_treeseq_t *ts_ptr = new tsk_treeseq_t();
    ret = tsk_treeseq_load(ts_ptr, file.c_str(), 0);
    if (ret != 0) {
        tsk_treeseq_free(ts_ptr);
        delete ts_ptr;
        Rcpp::stop(tsk_strerror(ret));
    }
    // Rcpp::XPtr<tsk_treeseq_t> xptr(ts_ptr, true);
    // true => delete ts_ptr on garbage collection, but this will not call tsk_treeseq_free()
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts_ptr, false);
    R_RegisterCFinalizerEx(xptr, treeseq_xptr_finalize, TRUE);
    return xptr;
}

//' Get number of nodes in a tree sequence
//'
//' @param ts an external pointer to a \code{tsk_treeseq_t} object.
//' @return An integer specifying the number of nodes in the tree sequence.
//' @examples
//' ts_file <- system.file("examples", "test.trees", package = "tskitr")
//' ts <- treeseq_load(ts_file)
//' treeseq_num_nodes(ts)
//' n <- treeseq_num_nodes(ts)
//' n
//' is(n)
//' try(treeseq_num_nodes())
//' try(treeseq_num_nodes(nonexistent_ts))
//' @export
// [[Rcpp::export]]
int treeseq_num_nodes(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_nodes(xptr);
    return n;
}
