@echo off
set OUT_FILE=test_binary.exe
set COMMON=-show-timings -no-bounds-check -vet -strict-style -out:%OUT_FILE%
set PATH_TO_ODIN==..\..\odin

echo ---
echo Running vendor:botan tests
echo ---
%PATH_TO_ODIN% run botan %COMMON%

echo ---
echo Running vendor:glfw tests
echo ---
%PATH_TO_ODIN% run glfw %COMMON%