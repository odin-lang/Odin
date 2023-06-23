@echo off

if not exist "build\" mkdir build
pushd build

set COMMON=-collection:tests=..\..

@echo on

..\..\..\odin test ..\test_issue_829.odin %COMMON% -file || exit /b
..\..\..\odin test ..\test_issue_1592.odin %COMMON% -file || exit /b
..\..\..\odin test ..\test_issue_2056.odin %COMMON% -file || exit /b
..\..\..\odin test ..\test_issue_2087.odin %COMMON% -file || exit /b
..\..\..\odin build ..\test_issue_2113.odin %COMMON% -file -debug || exit /b
..\..\..\odin test ..\test_issue_2466.odin %COMMON% -file || exit /b

@echo off

popd
rmdir /S /Q build
