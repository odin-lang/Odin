@echo off
set PATH_TO_ODIN==..\..\odin
set COMMON=-collection:tests=.. -out:build\test_issue
if not exist "build" mkdir build

%PATH_TO_ODIN% build test_issue_829.odin %COMMON% -file
build\test_issue

%PATH_TO_ODIN% build test_issue_1592.odin %COMMON% -file
build\test_issue

rmdir /S /Q build
