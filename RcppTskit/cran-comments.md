## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

* I have tested on my local MacOS laptop using:
  `devtools::check()` and
  `devtools::check(remote = TRUE, manual = TRUE)`. Both pass.

* I have also used R CMD check GitHub action on MacOS, Windows, and
  Ubunutu (olderelease, release, and devel, and ); all pass as you can
  see at https://github.com/HighlanderLab/RcppTskit/actions/runs/21542139159.

* `urlchecker::url_check()` also passes.

* On https://win-builder.r-project.org/UmBp28nqBAkU/00check.log
  I get this warning:

  ```
  * checking whether package 'RcppTskit' can be installed ... WARNING
  Found the following significant warnings:
    ../inst/include/tskit/tskit/core.h:171:21: warning: C++ designated initializers only available with '-std=c++20' or '-std=gnu++20' [-Wc++20-extensions]
  ```

  Discussion with upstream devs of tskit indicates that this is due
  to how the build tools have been built for this platform since
  we could not replicate the warning on any of our platforms even when
  tweaking the flags - see https://github.com/tskit-dev/tskit/issues/3375.
