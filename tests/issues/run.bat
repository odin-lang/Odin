@echo off

if not exist "tests\issues\build\" mkdir tests\issues\build

set COMMON=-collection:tests=tests -out:tests\issues\build\test_issue

@echo on

.\odin build tests\issues\test_issue_829.odin %COMMON% -file
tests\issues\build\test_issue

.\odin build tests\issues\test_issue_1592.odin %COMMON% -file
tests\issues\build\test_issue

@echo off

rmdir /S /Q tests\issues\build
