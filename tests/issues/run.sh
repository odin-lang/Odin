#!/bin/bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-collection:tests=../.."

set -x

$ODIN test ../test_issue_829.odin  $COMMON -file
$ODIN test ../test_issue_1592.odin $COMMON -file
$ODIN test ../test_issue_2056.odin $COMMON -file
$ODIN test ../test_issue_2087.odin $COMMON -file
$ODIN build ../test_issue_2113.odin $COMMON -file -debug
$ODIN test ../test_issue_2466.odin $COMMON -file

set +x

popd
rm -rf build
