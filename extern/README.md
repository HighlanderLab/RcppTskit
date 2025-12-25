# kastore and tskit

This directory holds git submodules for kastore and tskit and instructions on
copying their C code into R package. kastore is used by tskit.

All commands are run from the root of the tskitr repository:

```
ls -l
# extern # Git submodules for kastore and tskit and instructions on copying their C code
# R # R package
```

Below instructions show how to add, update, and inspect the kastore and tskit code. 

## kastore

Set up git submodule for the first time:

```
git submodule add https://github.com/tskit-dev/kastore extern/kastore
```

Update the git submodule to the latest version:

```
# Ensure submodule is initialized
git submodule update --init --recursive extern/kastore

# Fetch latest changes from remote
git submodule update --remote extern/kastore

# Check what has changed
git status extern/kastore
git diff extern/kastore
# <old SHA>
# <new SHA>
cd extern/kastore

# Inspect changes
git diff <old SHA> <new SHA>

cd ../..
```

Inspect the contents:

```
ls -l extern/kastore
cat extern/kastore/LICENSE
# MIT License
ls -l extern/kastore/c
cat extern/kastore/c/VERSION.txt
# 2.1.1
less extern/kastore/c/CHANGELOG.rst
# [2.1.1] - 2021-03-01
```

Copy the C source files to src the first time:

```
cp extern/kastore/c/kastore.{c,h} R/inst/???
```

Check differences between old copy and new version:

```
diff extern/kastore/c/kastore.c R/inst/???
diff extern/kastore/c/kastore.h R/inst/???
```

Update the C source files to src the first time:

```
cp extern/kastore/c/kastore.{c,h} R/inst/???
```

Commit changes:

```
git status
git add extern/kastore
git add R/inst/???kastore.c kastore.h
git commit -m "Update kastore C API to version [2.1.1]"
git push
```

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

Copy the C source files to src the first time:

```
cp extern/tskit/c/??? R/inst/???
```

Check differences between old copy and new version:

```
diff extern/tskit/c/??? R/inst/???
```

Update the C source files to src the first time:

```
cp extern/tskit/c/???  R/inst/???
```

Commit changes:

```
git status
git add extern/tskit
git add R/inst/???
git commit -m "Update tskit C API to version [1.3.0]"
git push
```

