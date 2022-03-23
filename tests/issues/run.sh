#!/bin/bash
set -eu

mkdir -p tests/issues/build

COMMON="-collection:tests=tests -out:tests/issues/build/test_issue"

set -x

./odin build tests/issues/test_issue_829.odin $COMMON
tests/issues/build/test_issue

./odin build tests/issues/test_issue_1592.odin $COMMON
tests/issues/build/test_issue

set +x

rm -rf tests/issues/build
