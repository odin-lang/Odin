@echo off
set OUT_FILE=test_binary.exe
set COMMON=-show-timings -no-bounds-check -vet -strict-style -collection:tests=.. -out:%OUT_FILE%
set PATH_TO_ODIN==..\..\odin

python3 download_assets.py
echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% run image    %COMMON%

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% run compress %COMMON%

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% run strings %COMMON%

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% run hash %COMMON% -o:size

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% run odin %COMMON% -o:size

echo ---
echo Running core:crypto hash tests
echo ---
%PATH_TO_ODIN% run crypto %COMMON%

echo ---
echo Running core:encoding tests
echo ---
%PATH_TO_ODIN% run encoding/hxa    %COMMON%
%PATH_TO_ODIN% run encoding/json   %COMMON%
%PATH_TO_ODIN% run encoding/varint %COMMON%

echo ---
echo Running core:math/noise tests
echo ---
%PATH_TO_ODIN% run math/noise      %COMMON%

echo ---
echo Running core:math tests
echo ---
%PATH_TO_ODIN% run math %COMMON%

echo ---
echo Running core:math/linalg/glsl tests
echo ---
%PATH_TO_ODIN% run math/linalg/glsl %COMMON%

echo ---
echo Running core:path/filepath tests
echo ---
%PATH_TO_ODIN% run path/filepath %COMMON%

echo ---
echo Running core:reflect tests
echo ---
%PATH_TO_ODIN% run reflect %COMMON%
