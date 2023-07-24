#!/bin/bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-collection:tests=../.."

NO_NIL_ERR="Error: "

set -x

$ODIN test ../test_issue_829.odin  $COMMON -file
$ODIN test ../test_issue_1592.odin $COMMON -file
$ODIN test ../test_issue_2056.odin $COMMON -file
$ODIN test ../test_issue_2087.odin $COMMON -file
$ODIN build ../test_issue_2113.odin $COMMON -file -debug
$ODIN test ../test_issue_2466.odin $COMMON -file
$ODIN test ../test_issue_2615.odin $COMMON -file
$ODIN test ../test_issue_2637.odin $COMMON -file
if [[ $($ODIN build ../test_issue_2395.odin $COMMON -file 2>&1 >/dev/null | grep -c "$NO_NIL_ERR") -eq 2 ]] ; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
fi

set +x

popd
rm -rf build
