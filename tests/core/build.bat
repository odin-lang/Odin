@echo off
set COMMON=-no-bounds-check -vet -strict-style -define:ODIN_TEST_FANCY=false
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:c/libc tests
echo ---
%PATH_TO_ODIN% test c\libc %COMMON% -out:test_libc.exe || exit /b

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% test compress %COMMON% -out:test_core_compress.exe || exit /b

echo ---
echo Running core:container tests
echo ---
%PATH_TO_ODIN% test container %COMMON% -out:test_core_container.exe || exit /b

echo ---
echo Running core:crypto tests
echo ---
%PATH_TO_ODIN% test crypto %COMMON% -o:speed -out:test_crypto.exe || exit /b

echo ---
echo Running core:encoding tests
echo ---
%PATH_TO_ODIN% test encoding/base64 %COMMON% -out:test_base64.exe || exit /b
%PATH_TO_ODIN% test encoding/cbor   %COMMON% -out:test_cbor.exe   || exit /b
%PATH_TO_ODIN% test encoding/hex    %COMMON% -out:test_hex.exe    || exit /b
%PATH_TO_ODIN% test encoding/hxa    %COMMON% -out:test_hxa.exe    || exit /b
%PATH_TO_ODIN% test encoding/json   %COMMON% -out:test_json.exe   || exit /b
%PATH_TO_ODIN% test encoding/varint %COMMON% -out:test_varint.exe || exit /b
%PATH_TO_ODIN% test encoding/xml    %COMMON% -out:test_xml.exe    || exit /b

echo ---
echo Running core:path/filepath tests
echo ---
%PATH_TO_ODIN% test path/filepath %COMMON% -out:test_core_filepath.exe || exit /b

echo ---
echo Running core:fmt tests
echo ---
%PATH_TO_ODIN% test fmt %COMMON% -out:test_core_fmt.exe || exit /b

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% test hash %COMMON% -o:speed -out:test_core_hash.exe || exit /b

echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% test image %COMMON% -out:test_core_image.exe || exit /b

echo ---
echo Running core:text/i18n tests
echo ---
%PATH_TO_ODIN% test text\i18n %COMMON% -out:test_core_i18n.exe || exit /b

echo ---
echo Running text:match tests
echo ---
%PATH_TO_ODIN% test text/match %COMMON% -out:test_core_match.exe || exit /b

echo ---
echo Running core:math tests
echo ---
%PATH_TO_ODIN% test math %COMMON% -out:test_core_math.exe || exit /b

echo ---
echo Running core:math/linalg/glsl tests
echo ---
%PATH_TO_ODIN% test math/linalg/glsl %COMMON% -out:test_linalg_glsl.exe || exit /b

echo ---
echo Running core:math/noise tests
echo ---
%PATH_TO_ODIN% test math/noise %COMMON% -out:test_noise.exe || exit /b

echo ---
echo Running core:net
echo ---
%PATH_TO_ODIN% test net %COMMON% -out:test_core_net.exe || exit /b

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% test odin %COMMON% -o:size -out:test_core_odin.exe || exit /b

echo ---
echo Running core:reflect tests
echo ---
%PATH_TO_ODIN% test reflect %COMMON% -out:test_core_reflect.exe || exit /b

echo ---
echo Running core:runtime tests
echo ---
%PATH_TO_ODIN% test runtime %COMMON% -out:test_core_runtime.exe || exit /b

echo ---
echo Running core:slice tests
echo ---
%PATH_TO_ODIN% test slice %COMMON% -out:test_core_slice.exe || exit /b

echo ---
echo Running core:strconv tests
echo ---
%PATH_TO_ODIN% test strconv %COMMON% -out:test_core_strconv.exe || exit /b

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% test strings %COMMON% -out:test_core_strings.exe || exit /b

echo ---
echo Running core:thread tests
echo ---
%PATH_TO_ODIN% test thread %COMMON% -out:test_core_thread.exe || exit /b

echo ---
echo Running core:time tests
echo ---
%PATH_TO_ODIN% test time %COMMON% -out:test_core_time.exe || exit /b