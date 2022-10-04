@echo off

if not exist "build\" mkdir build

set COMMON=-collection:tests=..

@echo on

..\..\odin test test_issue_829.odin %COMMON% -file
..\..\odin test test_issue_1592.odin %COMMON% -file
..\..\odin test test_issue_2087.odin %COMMON% -file

@echo off

rmdir /S /Q build
