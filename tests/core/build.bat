@echo off
set COMMON=-no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% test image    %COMMON%

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% test compress %COMMON%

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% test strings %COMMON%

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% test hash %COMMON% -o:size

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% test odin %COMMON% -o:size

echo ---
echo Running core:encoding tests
echo ---
%PATH_TO_ODIN% test encoding/hxa    %COMMON%
%PATH_TO_ODIN% test encoding/json   %COMMON%
%PATH_TO_ODIN% test encoding/varint %COMMON%
%PATH_TO_ODIN% test encoding/xml    %COMMON%

echo ---
echo Running core:math/noise tests
echo ---
%PATH_TO_ODIN% test math/noise %COMMON%

echo ---
echo Running core:math tests
echo ---
%PATH_TO_ODIN% test math %COMMON%

echo ---
echo Running core:math/linalg/glsl tests
echo ---
%PATH_TO_ODIN% test math/linalg/glsl %COMMON%

echo ---
echo Running core:path/filepath tests
echo ---
%PATH_TO_ODIN% test path/filepath %COMMON%

echo ---
echo Running core:reflect tests
echo ---
%PATH_TO_ODIN% test reflect %COMMON%

echo ---
echo Running core:text/i18n tests
echo ---
%PATH_TO_ODIN% test text/i18n %COMMON%

echo ---
echo Running core:slice tests
echo ---
%PATH_TO_ODIN% test slice %COMMON%

rem Run as the last tests in case the CI gets stuck on them
echo ---
echo Running core:crypto hash tests
echo ---
%PATH_TO_ODIN% run crypto %COMMON% -o:speed