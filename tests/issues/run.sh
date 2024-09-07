#!/usr/bin/env bash
set -eu

mkdir -p build
pushd build
ODIN=../../../odin
COMMON="-define:ODIN_TEST_FANCY=false -file -vet -strict-style"

set -x

$ODIN test ../test_issue_829.odin  $COMMON
$ODIN test ../test_issue_1592.odin $COMMON
$ODIN test ../test_issue_2056.odin $COMMON
$ODIN build ../test_issue_2113.odin $COMMON -debug
$ODIN test ../test_issue_2466.odin $COMMON
$ODIN test ../test_issue_2615.odin $COMMON
$ODIN test ../test_issue_2637.odin $COMMON
$ODIN test ../test_issue_2666.odin $COMMON
$ODIN test ../test_issue_4210.odin $COMMON
if [[ $($ODIN build ../test_issue_2395.odin $COMMON 2>&1 >/dev/null | grep -c "Error:") -eq 2 ]] ; then
	echo "SUCCESSFUL 1/1"
else
	echo "SUCCESSFUL 0/1"
	exit 1
fi

set +x

popd
rm -rf build
