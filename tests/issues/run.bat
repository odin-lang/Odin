@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-collection:tests=..\..

@echo on

..\..\..\odin test ..\test_issue_829.odin %COMMON% -file
..\..\..\odin test ..\test_issue_1592.odin %COMMON% -file
..\..\..\odin test ..\test_issue_2087.odin %COMMON% -file
..\..\..\odin run ..\test_issue_2113.odin %COMMON% -file -debug

@echo off

popd
rmdir /S /Q build
