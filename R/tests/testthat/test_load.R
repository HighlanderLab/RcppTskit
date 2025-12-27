context("test_load")

test_that("treeseq_load works and numbers are correct", {
  expect_error(treeseq_load())
  expect_error(treeseq_load("nonexistent_ts"))
  ts_file <- system.file("examples", "test.trees", package = "tskitr")
  ts <- treeseq_load(ts_file)

  if (FALSE) {
    expect_error(treeseq_num_individuals())
    n <- treeseq_num_individuals(ts)
    expect_equal(n, 80)

    expect_error(treeseq_num_samples())
    n <- treeseq_num_sampled(ts)
    expect_equal(n, 160)
  }

  expect_error(treeseq_num_nodes())
  n <- treeseq_num_nodes(ts)
  expect_equal(n, 344)

  if (FALSE) {
    expect_error(treeseq_num_edges())
    n <- treeseq_num_edges(ts)
    expect_equal(n, 414)

    expect_error(treeseq_num_trees())
    n <- treeseq_num_trees(ts)
    expect_equal(n, 26)

    expect_error(treeseq_num_sites())
    n <- treeseq_num_sites(ts)
    expect_equal(n, 2376)

    expect_error(treeseq_num_mutations())
    n <- treeseq_num_mutations(ts)
    expect_equal(n, 2700)
  }
})
