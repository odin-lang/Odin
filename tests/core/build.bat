@echo off
set COMMON=-no-bounds-check -vet -strict-style
set COLLECTION=-collection:tests=..
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% run compress %COMMON% -out:test_core_compress.exe || exit /b

echo ---
echo Running core:container tests
echo ---
%PATH_TO_ODIN% run container %COMMON% %COLLECTION% -out:test_core_container.exe || exit /b

echo ---
echo Running core:crypto tests
echo ---
%PATH_TO_ODIN% run crypto %COMMON% %COLLECTION% -out:test_crypto.exe || exit /b

echo ---
echo Running core:encoding tests
echo ---
rem %PATH_TO_ODIN% run encoding/hxa    %COMMON% %COLLECTION% -out:test_hxa.exe || exit /b
%PATH_TO_ODIN% run encoding/json   %COMMON% -out:test_json.exe || exit /b
%PATH_TO_ODIN% run encoding/varint %COMMON% -out:test_varint.exe || exit /b
%PATH_TO_ODIN% run encoding/xml    %COMMON% -out:test_xml.exe || exit /b
%PATH_TO_ODIN% test encoding/cbor  %COMMON% -out:test_cbor.exe || exit /b
%PATH_TO_ODIN% run encoding/hex    %COMMON% -out:test_hex.exe || exit /b
%PATH_TO_ODIN% run encoding/base64 %COMMON% -out:test_base64.exe || exit /b

echo ---
echo Running core:fmt tests
echo ---
%PATH_TO_ODIN% run fmt %COMMON% %COLLECTION% -out:test_core_fmt.exe || exit /b

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% run hash %COMMON% -o:size -out:test_core_hash.exe || exit /b

echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% run image    %COMMON% -out:test_core_image.exe || exit /b

echo ---
echo Running core:math tests
echo ---
%PATH_TO_ODIN% run math %COMMON% %COLLECTION% -out:test_core_math.exe || exit /b

echo ---
echo Running core:math/linalg/glsl tests
echo ---
%PATH_TO_ODIN% run math/linalg/glsl %COMMON% %COLLECTION% -out:test_linalg_glsl.exe || exit /b

echo ---
echo Running core:math/noise tests
echo ---
%PATH_TO_ODIN% run math/noise %COMMON% -out:test_noise.exe || exit /b

echo ---
echo Running core:net
echo ---
%PATH_TO_ODIN% run net %COMMON% -out:test_core_net.exe || exit /b

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% run odin %COMMON% -o:size -out:test_core_odin.exe || exit /b

echo ---
echo Running core:path/filepath tests
echo ---
%PATH_TO_ODIN% run path/filepath %COMMON% %COLLECTION% -out:test_core_filepath.exe || exit /b

echo ---
echo Running core:reflect tests
echo ---
%PATH_TO_ODIN% run reflect %COMMON% %COLLECTION% -out:test_core_reflect.exe || exit /b

echo ---
echo Running core:runtime tests
echo ---
%PATH_TO_ODIN% run runtime %COMMON% %COLLECTION% -out:test_core_runtime.exe || exit /b

echo ---
echo Running core:slice tests
echo ---
%PATH_TO_ODIN% run slice %COMMON% -out:test_core_slice.exe || exit /b

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% run strings %COMMON% -out:test_core_strings.exe || exit /b

echo ---
echo Running core:text/i18n tests
echo ---
%PATH_TO_ODIN% run text\i18n %COMMON% -out:test_core_i18n.exe || exit /b

echo ---
echo Running core:thread tests
echo ---
%PATH_TO_ODIN% run thread %COMMON% %COLLECTION% -out:test_core_thread.exe || exit /b

echo ---
echo Running core:time tests
echo ---
%PATH_TO_ODIN% run time %COMMON% %COLLECTION% -out:test_core_time.exe || exit /b