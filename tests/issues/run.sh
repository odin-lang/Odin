#!/bin/bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-collection:tests=../.."

set -x

$ODIN test test_issue_829.odin  $COMMON -file
$ODIN test test_issue_1592.odin $COMMON -file
$ODIN test test_issue_2087.odin $COMMON -file
$ODIN test test_issue_2113.odin $COMMON -file -debug

set +x

popd build
rm -rf build
