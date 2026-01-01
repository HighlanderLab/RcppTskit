# tskitr: R access to the `tskit` C API

`tskit` enables performant storage, manipulation and analysis of ancestral
recombination graphs using succinct tree sequence encoding; see https://tskit.dev.
`tskit` provides Python, C, and Rust APIs. The Python API can be called from R
via the `reticulate` package to seamlessly load and analyse tree sequences,
see https://tskit.dev/tutorials/tskitr.html.
`tskitr` provides R access to the `tskit` C API for use cases where the
`reticulate` approach is not suitable. For example, where high-performance and
low-level work with tree sequences is required. R access to the parts of C API
is added as the need arises.

See more details on the state of the tree sequence ecosystem and aims for
`tskitr` in `R/inst/STATE_and_AIMS.md`, including examples on how to use it independently or to develop new R packages.

## TODO: What would be a good subsection title here?

TODO: Add R package badges (build status, CRAN version, etc.) to README.md #1
      https://github.com/HighlanderLab/tskitr/issues/1

## Contents

  * `extern` - Git submodule for `tskit` and instructions on obtaining the latest version and copying the `tskit` C code into `R` directory. `extern` is saved outside of the `R` directory because `R CMD CHECK` complains otherwise.

  * `R` - R package `tskitr`.

## License

  * See `extern/LICENSE` for `tskit`.

  * See `R/DESCRIPTION` and `R/LICENSE` for `tskitr`.

## Installation

To install the published release from CRAN use:

```
# tskitr is not, yet, published on CRAN (TODO)
# install.packages("tskitr")
```

To install the published release or specific branches from Github use the
following code. Note that you will have to compile the C/C++ code and will
hence require complete R build toolchain, including compilers. See
https://r-pkgs.org/setup.html#setup-tools for introduction to this topic,
https://cran.r-project.org/bin/windows/Rtools for Windows tools, and
https://mac.r-project.org/tools for macOS tools.

```
# install.packages("remotes") # If you don't have it already

# Release (TODO)
# remotes::install_github("HighlanderLab/tskitr/R")

# Main branch
remotes::install_github("HighlanderLab/tskitr/R")

# Development branch (TODO)
# remotes::install_github("HighlanderLab/tskitr/R@devel")
```

## Development

First clone the repository:

```
git clone https://github.com/HighlanderLab/tskitr.git
```

If you plan to update `tskit`, follow instructions in `extern/README.md`.

Then open R package directory in your favourite R IDE (RStudio, Positron, ...), implement your changes and run:

```
# Note that the tskitr package is in the R directory
setwd("path/to/tskitr/R")

# Run checks of your changes, documentation, etc.
devtools::check()

# Install the package
devtools::install()
```

Alternatively you can check and install from command line:

```
# Note that the tskitr package is in the R directory
cd path/to/tskitr

# Run checks of your changes, documentation, etc.
R CMD build tskitr
R CMD check tskitr_*.tar.gz

# Install the package
R CMD INSTALL tskitr_*.tar.gz # or .zip
```

On Windows, replace `tar.gz` with `zip`.
