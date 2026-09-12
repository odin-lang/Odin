#!/bin/bash

# build the .a files if they don't already exist

if ! ls vendor/stb/lib/*.a >/dev/null 2>&1; then
    pushd vendor/stb/src >/dev/null
    ./build_stb.sh
    popd >/dev/null
fi

if ! ls vendor/miniaudio/lib/*.a >/dev/null 2>&1; then
    pushd vendor/miniaudio/src >/dev/null
    ./build_miniaudio.sh
    popd >/dev/null
fi

if ! ls vendor/cgltf/lib/*.a >/dev/null 2>&1; then
    pushd vendor/cgltf/src >/dev/null
    ./build_cgltf.sh
    popd >/dev/null
fi

if ! ls vendor/box2d/*.a >/dev/null 2>&1; then
    pushd vendor/box2d >/dev/null
    ./build_box2d.sh
    popd >/dev/null
fi

if ! ls vendor/box3d/lib/*.a >/dev/null 2>&1; then
    pushd vendor/box3d/src >/dev/null
    ./build.sh
    popd >/dev/null
fi

if ! ls vendor/kb_text_shape/lib/*.a >/dev/null 2>&1; then
    pushd vendor/kb_text_shape/src >/dev/null
    ./build_unix.sh
    popd >/dev/null
fi
