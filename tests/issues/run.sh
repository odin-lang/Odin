#!/bin/bash
set -eu

mkdir -p build
ODIN=../../odin
COMMON="-collection:tests=.. -out:build/test_issue"

set -x

$ODIN build test_issue_829.odin $COMMON -file
./build/test_issue

$ODIN build test_issue_1592.odin $COMMON -file
./build/test_issue

set +x

rm -rf build
