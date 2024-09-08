@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-define:ODIN_TEST_FANCY=false -file -vet -strict-style

@echo on

..\..\..\odin test ..\test_issue_829.odin  %COMMON%   || exit /b
..\..\..\odin test ..\test_issue_1592.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2056.odin %COMMON%  || exit /b
..\..\..\odin build ..\test_issue_2113.odin %COMMON% -debug || exit /b
..\..\..\odin test ..\test_issue_2466.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2615.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2637.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_2666.odin %COMMON%  || exit /b
..\..\..\odin test ..\test_issue_4210.odin %COMMON%  || exit /b

@echo off

popd
rmdir /S /Q build
