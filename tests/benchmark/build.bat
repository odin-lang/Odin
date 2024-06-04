@echo off
set COMMON=-no-bounds-check -vet -strict-style -define:ODIN_TEST_FANCY=false
set PATH_TO_ODIN==..\..\odin

echo ---
echo Running core:crypto benchmarks
echo ---
%PATH_TO_ODIN% test crypto %COMMON% -o:speed -out:bench_crypto.exe || exit /b

echo ---
echo Running core:hash benchmarks
echo ---
%PATH_TO_ODIN% test hash %COMMON% -o:speed -out:bench_hash.exe || exit /b
