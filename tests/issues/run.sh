#!/bin/bash
set -eu

mkdir -p build
ODIN=../../odin
COMMON="-collection:tests=.."

set -x

$ODIN test test_issue_829.odin  $COMMON -file
$ODIN test test_issue_1592.odin $COMMON -file
$ODIN test test_issue_2087.odin $COMMON -file

set +x

rm -rf build
