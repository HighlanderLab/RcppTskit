# RcppTskit: R access to the `tskit` C API

## Overview

Tskit enables performant storage, manipulation, and analysis of ancestral
recombination graphs (ARGs) using succinct tree sequence encoding.
See https://tskit.dev for project news, documentation, and tutorials.
Tskit provides Python, C, and Rust APIs. The Python API can be called from R
via the `reticulate` R package to seamlessly load and analyse a tree sequence,
as described at https://tskit.dev/tutorials/RcppTskit.html.
`RcppTskit` provides R access to the `tskit` C API for use cases where the
`reticulate` approach is not optimal. For example, for high-performance and
low-level work with tree sequences. Currently, `RcppTskit` provides a very limited
number of R functions due to the availability of extensive Python API and
the `reticulate` approach.

See more details on the state of the tree sequence ecosystem and aims for
`RcppTskit` in [RcppTskit/inst/STATE_and_AIMS.md](RcppTskit/inst/STATE_and_AIMS.md),
including examples on how to use it on its own or to develop new R packages.

TODO: Think how to best point to use cases. Probably best to point to vignette!?
      TODO: add vignette issue link here

## Status

<!-- badges: start -->
  [![R-CMD-check](https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml)

  [![Codecov test coverage](https://codecov.io/gh/HighlanderLab/RcppTskit/graph/badge.svg)](https://app.codecov.io/gh/HighlanderLab/RcppTskit)
<!-- badges: end -->

TODO: Add R package badges (build status, CRAN version, etc.) to README.md #1
      https://github.com/HighlanderLab/RcppTskit/issues/1

## Contents

  * `extern` - Git submodule for `tskit` and instructions on obtaining the latest version and copying the `tskit` C code into `RcppTskit` directory. `extern` is saved outside of the `RcppTskit` directory because `R CMD CHECK` complains otherwise.

  * `RcppTskit` - R package `RcppTskit`.

## License

  * See `extern/LICENSE` for `tskit`.

  * See `RcppTskit/DESCRIPTION` and `RcppTskit/LICENSE` for `RcppTskit`.

## Installation

To install the published release from CRAN use:

```
# TODO: Publish on CRAN #14
#       https://github.com/HighlanderLab/RcppTskit/issues/14
# install.packages("RcppTskit")
```

To install a published release or specific branches from Github use the
following code. Note that you will have to compile the C/C++ code and will
hence require the complete R build toolchain, including compilers. See
https://r-pkgs.org/setup.html#setup-tools for introduction to this topic,
https://cran.r-project.org/bin/windows/Rtools for Windows tools, and
https://mac.r-project.org/tools for macOS tools.

```
# install.packages("remotes") # If you don't have it already

# Release (TODO)
# TODO: Tag a release #15
#       https://github.com/HighlanderLab/RcppTskit/issues/15
# remotes::install_github("HighlanderLab/RcppTskit/RcppTskit")

# Main branch
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit")

# Development branch
# TODO: Create a devel branch #16
#       https://github.com/HighlanderLab/RcppTskit/issues/16
# remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@devel")
```

## Development

First clone the repository:

```
git clone https://github.com/HighlanderLab/RcppTskit.git
```

If you plan to update `tskit`, follow instructions in `extern/README.md`.

Then open `RcppTskit` package directory in your favourite R IDE (Positron, RStudio, text-editor-of-your-choice, etc.), implement your changes and run (in R):

```
# Note that the RcppTskit R package is in the RcppTskit sub-directory
setwd("path/to/RcppTskit/RcppTskit")

# Run checks of your changes, documentation, etc.
devtools::check()

# Install the package
devtools::install()
```

Alternatively you can check and install from command line:

```
# Note that the RcppTskit package is in the RcppTskit sub-directory
cd path/to/RcppTskit

# Run checks of your changes, documentation, etc.
R CMD build RcppTskit
R CMD check RcppTskit_*.tar.gz

# Install the package
R CMD INSTALL RcppTskit_*.tar.gz
```

On Windows, replace `tar.gz` with `zip`.
