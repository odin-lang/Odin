#!/bin/bash
ODIN=../../odin
COMMON="-collection:tests=.. -out:build/test_issue.bin"

set -eu
mkdir -p build
set -x

$ODIN build test_issue_829.odin $COMMON -file
build/test_issue.bin

$ODIN build test_issue_1592.odin $COMMON -file
build/test_issue.bin

set +x

rm -rf build
