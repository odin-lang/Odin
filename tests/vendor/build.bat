@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin

echo ---
echo Running vendor:botan tests
echo ---
%PATH_TO_ODIN% run botan %COMMON% -out:vendor_botan.exe

echo ---
echo Running vendor:glfw tests
echo ---
%PATH_TO_ODIN% run glfw %COMMON% -out:vendor_glfw.exe