@echo off
set COMMON=-show-timings -no-bounds-check -vet -strict-style
set PATH_TO_ODIN==..\..\odin
python3 download_assets.py
%PATH_TO_ODIN% test image    %COMMON%
%PATH_TO_ODIN% test compress %COMMON%