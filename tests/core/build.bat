@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
echo ---
echo Running core:image tests
echo ---
%PATH_TO_ODIN% run image    %COMMON% -out:test_image.exe

echo ---
echo Running core:compress tests
echo ---
%PATH_TO_ODIN% run compress %COMMON% -out:test_compress.exe

echo ---
echo Running core:strings tests
echo ---
%PATH_TO_ODIN% run strings %COMMON% -out:test_strings.exe

echo ---
echo Running core:hash tests
echo ---
%PATH_TO_ODIN% run hash %COMMON% -o:size -out:test_hash.exe

echo ---
echo Running core:odin tests
echo ---
%PATH_TO_ODIN% run odin %COMMON% -o:size -out:test_odin.exe

echo ---
echo Running core:crypto hash tests
echo ---
%PATH_TO_ODIN% run crypto %COMMON% -o:speed -out:test_crypto.exe

echo ---
echo Running core:encoding tests
echo ---
%PATH_TO_ODIN% run encoding\json %COMMON% -out:test_json.exe
%PATH_TO_ODIN% run encoding\xml %COMMON% -out:test_xml.exe