@echo off

if not exist "build\" mkdir build

set COMMON=-collection:tests=.. -out:build\test_issue.exe

@echo on

..\..\odin build test_issue_829.odin %COMMON% -file
build\test_issue

..\..\odin build test_issue_1592.odin %COMMON% -file
build\test_issue

..\..\odin build test_issue_1840.odin %COMMON% -file
build\test_issue

@echo off

rmdir /S /Q build
