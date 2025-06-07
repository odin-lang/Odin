@echo off

set ODIN==..\..\odin

%ODIN% build shared -build-mode:dll                                                                      || exit /b

%ODIN% run .               -define:TEST_TAG="main:default/default"                                       || exit /b
%ODIN% run . -o:none       -define:TEST_TAG="main:none/default"                                          || exit /b
%ODIN% run . -o:size       -define:TEST_TAG="main:size/default"                                          || exit /b
%ODIN% run . -o:speed      -define:TEST_TAG="main:speed/default"                                         || exit /b
%ODIN% run . -o:aggressive -define:TEST_TAG="main:aggressive/default"                                    || exit /b

%ODIN% run .               -define:TEST_TAG="shared:default/default"    -define:USE_SHARED_CONTEXT=true  || exit /b
%ODIN% run . -o:none       -define:TEST_TAG="shared:none/default"       -define:USE_SHARED_CONTEXT=true  || exit /b
%ODIN% run . -o:size       -define:TEST_TAG="shared:size/default"       -define:USE_SHARED_CONTEXT=true  || exit /b
%ODIN% run . -o:speed      -define:TEST_TAG="shared:speed/default"      -define:USE_SHARED_CONTEXT=true  || exit /b
%ODIN% run . -o:aggressive -define:TEST_TAG="shared:aggressive/default" -define:USE_SHARED_CONTEXT=true  || exit /b

%ODIN% build shared -build-mode:dll -o:speed                                                             || exit /b

%ODIN% run .               -define:TEST_TAG="main:default/speed"                                         || exit /b
%ODIN% run . -o:none       -define:TEST_TAG="main:none/speed"                                            || exit /b
%ODIN% run . -o:size       -define:TEST_TAG="main:size/speed"                                            || exit /b
%ODIN% run . -o:speed      -define:TEST_TAG="main:speed/speed"                                           || exit /b
%ODIN% run . -o:aggressive -define:TEST_TAG="main:aggressive/speed"                                      || exit /b

%ODIN% run .               -define:TEST_TAG="shared:default/speed"    -define:USE_SHARED_CONTEXT=true    || exit /b
%ODIN% run . -o:none       -define:TEST_TAG="shared:none/speed"       -define:USE_SHARED_CONTEXT=true    || exit /b
%ODIN% run . -o:size       -define:TEST_TAG="shared:size/speed"       -define:USE_SHARED_CONTEXT=true    || exit /b
%ODIN% run . -o:speed      -define:TEST_TAG="shared:speed/speed"      -define:USE_SHARED_CONTEXT=true    || exit /b
%ODIN% run . -o:aggressive -define:TEST_TAG="shared:aggressive/speed" -define:USE_SHARED_CONTEXT=true    || exit /b



%ODIN% build shared -build-mode:dll -use-separate-modules                                                || exit /b

%ODIN% run .               -define:TEST_TAG="main:default/separate"                                      || exit /b
%ODIN% run .               -define:TEST_TAG="main:separate/separate" -use-separate-modules               || exit /b

%ODIN% build shared -build-mode:dll -use-single-module                                                   || exit /b

%ODIN% run .               -define:TEST_TAG="main:default/single"                                        || exit /b
%ODIN% run .               -define:TEST_TAG="main:single/single" -use-single-module                      || exit /b

del shared.lib
