@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style -define:ODIN_TEST_FANCY=false
set PATH_TO_ODIN==..\..\odin

echo ---
echo Running vendor:glfw tests
echo ---
%PATH_TO_ODIN% test glfw %COMMON% -out:vendor_glfw.exe || exit /b