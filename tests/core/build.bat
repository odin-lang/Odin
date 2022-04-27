@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style -collection:tests=..
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% run image    %COMMON% -out:test_core_image.exe

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% run compress %COMMON% -out:test_core_compress.exe

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% run strings %COMMON% -out:test_core_strings.exe

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% run hash %COMMON% -o:size -out:test_core_hash.exe

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% run odin %COMMON% -o:size -out:test_core_odin.exe

echo ---
echo Running core:crypto hash tests
echo ---
%PATH_TO_ODIN% run crypto %COMMON% -out:test_crypto_hash.exe

echo ---
echo Running core:encoding tests
echo ---
%PATH_TO_ODIN% run encoding/hxa %COMMON% -out:test_hxa.exe
%PATH_TO_ODIN% run encoding/json %COMMON% -out:test_json.exe
%PATH_TO_ODIN% run encoding/varint %COMMON% -out:test_varint.exe

echo ---
echo Running core:math/noise tests
echo ---
%PATH_TO_ODIN% run math/noise %COMMON% -out:test_noise.exe

echo ---
echo Running core:math tests
echo ---
%PATH_TO_ODIN% run math %COMMON% -out:test_core_math.exe

echo ---
echo Running core:math/linalg/glsl tests
echo ---
%PATH_TO_ODIN% run math/linalg/glsl %COMMON% -out:test_linalg_glsl.exe

echo ---
echo Running core:path/filepath tests
echo ---
%PATH_TO_ODIN% run path/filepath %COMMON% -out:test_core_filepath.exe

echo ---
echo Running core:reflect tests
echo ---
%PATH_TO_ODIN% run reflect %COMMON% -out:test_core_reflect.exe