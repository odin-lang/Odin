#!/usr/bin/env bash

set -ex

$(llvm-config --bindir)/clang++ $(llvm-config --cxxflags --ldflags --libs) featuregen.cpp -o featuregen
