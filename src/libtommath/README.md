# libtommath

This is the git repository for [LibTomMath](http://www.libtom.net/LibTomMath/), a free open source portable number theoretic multiple-precision integer (MPI) library written entirely in C.

## Build Status

### Travis CI

master: [![Build Status](https://api.travis-ci.org/libtom/libtommath.png?branch=master)](https://travis-ci.org/libtom/libtommath)

develop: [![Build Status](https://api.travis-ci.org/libtom/libtommath.png?branch=develop)](https://travis-ci.org/libtom/libtommath)

### AppVeyor

master: [![Build status](https://ci.appveyor.com/api/projects/status/b80lpolw3i8m6hsh/branch/master?svg=true)](https://ci.appveyor.com/project/libtom/libtommath/branch/master)

develop: [![Build status](https://ci.appveyor.com/api/projects/status/b80lpolw3i8m6hsh/branch/develop?svg=true)](https://ci.appveyor.com/project/libtom/libtommath/branch/develop)

### ABI Laboratory

API/ABI changes: [check here](https://abi-laboratory.pro/tracker/timeline/libtommath/)

## Summary

The `develop` branch contains the in-development version. Stable releases are tagged.

Documentation is built from the LaTeX file `bn.tex`. There is also limited documentation in `tommath.h`.
There is also a document, `tommath.pdf`, which describes the goals of the project and many of the algorithms used.

The project can be build by using `make`. Along with the usual `make`, `make clean` and `make install`,
there are several other build targets, see the makefile for details.
There are also makefiles for certain specific platforms.

## Testing

Tests are located in `demo/` and can be built in two flavors.
* `make test` creates a stand-alone test binary that executes several test routines.
* `make mtest_opponent` creates a test binary that is intended to be run against `mtest`.
  `mtest` can be built with `make mtest` and test execution is done like `./mtest/mtest | ./mtest_opponent`.
  `mtest` is creating test vectors using an alternative MPI library and `test` is consuming these vectors to verify correct behavior of ltm

## Building and Installing

Building is straightforward for GNU Linux only, the section "Building LibTomMath" in the documentation in `doc/bn.pdf` has the details.
