# README for extern/tskit

This directory holds git submodule for tskit and instructions on copying its
C code into R package.

All commands are run from the root of the tskitr repository:

```
ls -l
# extern # Git submodules for tskit and instructions on copying its C code
# tskitr # R package
```

Below instructions show how to add, update, and inspect the tskit code changes.

## tskit

Set up git submodule for the first time:

```
git submodule add https://github.com/tskit-dev/tskit extern/tskit
```

Update the git submodule to the latest version:

```
# Ensure submodule is initialized
git submodule update --init --recursive extern/tskit

# Fetch latest changes from remote
git submodule update --remote extern/tskit

# Check what has changed
git status extern/tskit
git diff extern/tskit
# <old SHA>
# <new SHA>
cd extern/tskit

# Inspect changes
git diff <old SHA> <new SHA>

cd ../..
```

Inspect the contents:

```
ls -l extern/tskit
cat extern/tskit/LICENSE
# MIT License
ls -l extern/tskit/c
cat extern/tskit/c/VERSION.txt
# 1.3.0
less extern/tskit/c/CHANGELOG.rst
# [1.3.0] - 2025-11-27
```

Commit git submodule change:

```
git status
git add extern/tskit
git commit -m "Update tskit submodule to C API version 1.3.0"
git push
```

Copy files to R package for the first time:

```
# Create folders
mkdir -p tskitr/inst/include/tskit
mkdir -p tskitr/inst/include/tskit/tskit
mkdir -p tskitr/src/tskit

# Header files
cp extern/tskit/LICENSE tskitr/inst/include/tskit/.
cp extern/tskit/c/VERSION.txt tskitr/inst/include/tskit/.
cp extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/inst/include/tskit/tskit/VERSION_kastore.txt
cp extern/tskit/c/tskit.h tskitr/inst/include/tskit/.
cp extern/tskit/c/tskit/convert.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/core.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/genotypes.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/haplotype_matching.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/stats.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/tables.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/tskit/trees.h tskitr/inst/include/tskit/tskit/.
cp extern/tskit/c/subprojects/kastore/kastore.h tskitr/inst/include/tskit/tskit/.

# Code files
cp extern/tskit/LICENSE tskitr/src/tskit/.
cp extern/tskit/c/VERSION.txt tskitr/src/tskit/.
cp extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/src/tskit/VERSION_kastore.txt
cp extern/tskit/c/tskit/convert.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/core.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/genotypes.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/haplotype_matching.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/stats.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/tables.c tskitr/src/tskit/.
cp extern/tskit/c/tskit/trees.c tskitr/src/tskit/.
cp extern/tskit/c/subprojects/kastore/kastore.c tskitr/src/tskit/.

Check differences between old copy and new version:

```
# Header files
diff extern/tskit/LICENSE tskitr/inst/include/tskit/LICENSE
diff extern/tskit/c/VERSION.txt tskitr/inst/include/tskit/VERSION.txt
diff extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/inst/include/tskit/tskit/VERSION_kastore.txt
diff extern/tskit/c/tskit.h tskitr/inst/include/tskit/tskit.h
diff extern/tskit/c/tskit/convert.h tskitr/inst/include/tskit/tskit/convert.h
diff extern/tskit/c/tskit/core.h tskitr/inst/include/tskit/tskit/core.h
diff extern/tskit/c/tskit/genotypes.h tskitr/inst/include/tskit/tskit/genotypes.h
diff extern/tskit/c/tskit/haplotype_matching.h tskitr/inst/include/tskit/tskit/haplotype_matching.h
diff extern/tskit/c/tskit/stats.h tskitr/inst/include/tskit/tskit/stats.h
diff extern/tskit/c/tskit/tables.h tskitr/inst/include/tskit/tskit/tables.h
diff extern/tskit/c/tskit/trees.h tskitr/inst/include/tskit/tskit/trees.h
diff extern/tskit/c/subprojects/kastore/kastore.h tskitr/inst/include/tskit/tskit/kastore.h

# Code files
diff extern/tskit/LICENSE tskitr/src/tskit/LICENSE
diff extern/tskit/c/VERSION.txt tskitr/src/tskit/VERSION.txt
diff extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/src/tskit/VERSION_kastore.txt
diff extern/tskit/c/tskit/convert.c tskitr/src/tskit/convert.c
diff extern/tskit/c/tskit/core.c tskitr/src/tskit/core.c
diff extern/tskit/c/tskit/genotypes.c tskitr/src/tskit/genotypes.c
diff extern/tskit/c/tskit/haplotype_matching.c tskitr/src/tskit/haplotype_matching.c
diff extern/tskit/c/tskit/stats.c tskitr/src/tskit/stats.c
diff extern/tskit/c/tskit/tables.c tskitr/src/tskit/tables.c
diff extern/tskit/c/tskit/trees.c tskitr/src/tskit/trees.c
diff extern/tskit/c/subprojects/kastore/kastore.c tskitr/src/tskit/kastore.c

Update the files in R package:

```
# Header files
cp -i extern/tskit/LICENSE tskitr/inst/include/tskit/.
cp -i extern/tskit/c/VERSION.txt tskitr/inst/include/tskit/.
cp -i extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/inst/include/tskit/tskit/VERSION_kastore.txt
cp -i extern/tskit/c/tskit.h  tskitr/inst/include/tskit/.
cp -i extern/tskit/c/tskit/convert.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/core.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/genotypes.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/haplotype_matching.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/stats.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/tables.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/tskit/trees.h tskitr/inst/include/tskit/tskit/.
cp -i extern/tskit/c/subprojects/kastore/kastore.h tskitr/inst/include/tskit/tskit/.

# Code files
cp -i extern/tskit/LICENSE tskitr/src/tskit/.
cp -i extern/tskit/c/VERSION.txt tskitr/src/tskit/.
cp -i extern/tskit/c/subprojects/kastore/VERSION.txt tskitr/src/tskit/VERSION_kastore.txt
cp -i extern/tskit/c/tskit/convert.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/core.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/genotypes.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/haplotype_matching.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/stats.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/tables.c tskitr/src/tskit/.
cp -i extern/tskit/c/tskit/trees.c tskitr/src/tskit/.
cp -i extern/tskit/c/subprojects/kastore/kastore.c tskitr/src/tskit/.

Commit changes:

```
git status
git add tskitr/inst/include/tskit
git add tskitr/src
git commit -m "Update tskit C API to version 1.3.0"
git push
```
