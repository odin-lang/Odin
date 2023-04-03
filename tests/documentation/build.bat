@echo off
set PATH_TO_ODIN==..\..\odin

echo ---
echo Building Documentation File
echo ---
%PATH_TO_ODIN% doc ..\..\examples\all -all-packages -doc-format || exit /b


echo ---
echo Running Documentation Tester
echo ---
%PATH_TO_ODIN% run documentation_tester.odin -file -vet -strict-style -- %PATH_TO_ODIN% || exit /b
