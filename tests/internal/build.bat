@echo off
set PATH_TO_ODIN==..\..\odin
set COMMON=-file -vet -strict-style -o:minimal
%PATH_TO_ODIN% test test_rtti.odin %COMMON% || exit /b
%PATH_TO_ODIN% test test_map.odin  %COMMON% || exit /b
%PATH_TO_ODIN% test test_pow.odin  %COMMON% || exit /b
%PATH_TO_ODIN% test test_asan.odin %COMMON% || exit /b
%PATH_TO_ODIN% test test_128.odin  %COMMON% || exit /b
%PATH_TO_ODIN% test test_string_compare.odin %COMMON% || exit /b