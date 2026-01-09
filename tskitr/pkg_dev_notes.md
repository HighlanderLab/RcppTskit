# Notes on R package development

## Next TODOs

* TODO: Rename ts_load() to ts_load_ptr() and create ts_load() returning S3/S4/R6 object #22
       https://github.com/HighlanderLab/tskitr/issues/22

TreeSequence <- R6::R6Class(
  "TreeSequence",
  public = list(
    ptr = NULL,
    initialize = function(file, options = 0L) {
      self$ptr <- ts_load_ptr(file, options)
    },
    show = function(...) ts_print(self$ptr, ...),
    dump = function(...) ts_dump(self$ptr, ...),
    # summary = function(...) ts_summary(self$ptr, ...),
  )
)

ts_load <- function(file, options = 0L) {
  TreeSequence$new(file, options)
}

* TODO: Explore use of RcppModule
https://github.com/cran/lm.br/blob/2c7bf2708f90143d455a6476b43c83d9a002cb01/src/Rcpp_module.cpp#L7
https://github.com/cran/GiRaF/blob/3c448999ec2003d3624306014ce53bc117d110f4/src/rcpp_module.cpp#L5
https://github.com/cran/multinet/blob/776cf9d64035d517df76f2cf67da039eab5950ab/src/rcpp_module_definition.cpp#L28
https://github.com/cran/raster/blob/3f64977b51a3b7c565f1309a462cb35f66daeafe/src/RasterModule.cpp#L14
https://github.com/cran/vcfppR/blob/c6efbbe51902d41e01ba8c566ab26cba74c5f948/src/vcf-writer.cpp#L77
https://github.com/cran/dfpk/blob/8137c06f6df08e717bb41eaa4edd2e16115cd0e2/src/Modules.cpp#L5

## Setup

```
install.packages(c("usethis", "devtools"))
```

## Code testing coverage with covr

```
install.packages("covr")

# https://usethis.r-lib.org/reference/use_coverage.html
usethis::use_coverage(type = "codecov")

TODO: ! If test coverage uploads do not succeed, you probably need
  to configure CODECOV_TOKEN as a repository or organization
  secret:
  <https://docs.codecov.com/docs/adding-the-codecov-token>

# Build the report
cov <- covr::package_coverage(clean = TRUE)

# Interactive HTML report with uncovered lines highlighted
covr::report(cov)

# List lines with zero coverage per file
covr::zero_coverage(cov)

# Show coverage for a specific file
covr::report(cov, file = "R/tskitr-package.R")
covr::report(cov, file = "src/tskitr_minimal.cpp")

# If you want a quick text view of uncovered lines:
covr::file_coverage("R/tskitr-package.R", "tests/testthat")
covr::file_coverage("src/tskitr_minimal.cpp", "tests/testthat")
```

To ignore specific lines, use `# nocov`

To ignore multiple lines use `# nocov start/stop`.

In `Rcpp` code use `// # nocov ...`.

## Air formatter

https://usethis.r-lib.org/reference/use_air.html
```
usethis::use_air()
```

## Jarl linter and fixer (buil on Air)

https://jarl.etiennebacher.com

* Add jarl.toml to ~/.config/jarl and to the package folder
* TODO

## GitHub actions

```
install.packages("usethis")

# R CMD check
usethis::use_github_action("check-standard")

# Code testing coverage with covr
usethis::use_github_action("test-coverage")

# Air formatting
usethis::use_github_action(url = "https://github.com/posit-dev/setup-air/blob/main/examples/format-suggest.yaml")
usethis::use_github_action(url = "https://github.com/posit-dev/setup-air/blob/main/examples/format-check.yaml")
```
