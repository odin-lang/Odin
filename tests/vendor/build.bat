@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin

echo ---
echo Running vendor:botan tests
echo ---
%PATH_TO_ODIN% run botan %COMMON%

echo ---
echo Running vendor:glfw tests
echo ---
%PATH_TO_ODIN% run glfw %COMMON%