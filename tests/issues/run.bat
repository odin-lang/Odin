@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-collection:tests=..\..

set ERROR_DID_OCCUR=0

@echo on

..\..\..\odin test ..\test_issue_829.odin %COMMON% -file
..\..\..\odin test ..\test_issue_1592.odin %COMMON% -file
..\..\..\odin test ..\test_issue_2087.odin %COMMON% -file
..\..\..\odin build ..\test_issue_2113.odin %COMMON% -file -debug

@echo off

if %ERRORLEVEL% NEQ 0 set ERROR_DID_OCCUR=1

popd
rmdir /S /Q build
if %ERROR_DID_OCCUR% NEQ 0 EXIT /B 1
