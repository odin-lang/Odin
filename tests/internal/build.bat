@echo off
set PATH_TO_ODIN==..\..\odin
rem %PATH_TO_ODIN% run test_rtti.odin -file -vet -strict-style -o:minimal || exit /b
%PATH_TO_ODIN% run test_map.odin -file -vet -strict-style -o:minimal || exit /b
rem -define:SEED=42
%PATH_TO_ODIN% run test_pow.odin -file -vet -strict-style -o:minimal || exit /b

%PATH_TO_ODIN% run test_128.odin -file -vet -strict-style -o:minimal || exit /b

%PATH_TO_ODIN% run test_string_compare.odin -file -vet -strict-style -o:minimal || exit /b