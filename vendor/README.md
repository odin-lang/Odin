# Vendor Collection

The `vendor:` prefix for Odin imports is a package collection that comes with this implementation of the Odin programming language.

Its use is similar to that of `core:` packages, which would be available in any Odin implementation.

These packages and their associated binary files are curated and maintained by the Odin team. Please don't open pull requests for `vendor:` without first consulting them, whether it be to propose a new package or update bindings to a newer version. In the best of cases this often results in a duplication of effort. Localized fixes where type or procedure definitions diverge between the Odin binding and upstream are welcome.

Presently, the `vendor:` collection comprises the following packages. Each name links to its documentation. The version is the upstream version that the bindings and the binaries we ship are for. Where a package has a `LICENSE` file in its directory, it applies in addition to what is listed here.

| Package | Description | Version | License[^licenses] | Upstream URL |
|---|---|---|---|---|
| [box2d](https://pkg.odin-lang.org/vendor/box2d/) | 2D physics engine | 3.2.0 | MIT | https://github.com/erincatto/box2d |
| [box3d](https://pkg.odin-lang.org/vendor/box3d/) | 3D physics engine | master snapshot | MIT | https://github.com/erincatto/box3d |
| [cgltf](https://pkg.odin-lang.org/vendor/cgltf/) | glTF 2.0 loader and writer | 1.15 | MIT | https://github.com/jkuhlmann/cgltf |
| [commonmark](https://pkg.odin-lang.org/vendor/commonmark/) | CommonMark (Markdown) parser and renderer | 0.31.2 | BSD-2-Clause | https://github.com/commonmark/cmark |
| [compress/lz4](https://pkg.odin-lang.org/vendor/compress/lz4/) | Fast lossless compression | 1.10.0 | BSD-2-Clause | https://github.com/lz4/lz4 |
| [curl](https://pkg.odin-lang.org/vendor/curl/) | URL transfers over HTTP(S) and more, with libcurl | 8.23.0 | curl[^curl] | https://curl.se |
| [darwin](https://pkg.odin-lang.org/vendor/darwin/) | macOS and iOS frameworks, such as AppKit and Metal | macOS 26.2 and iOS 26.2 SDKs | [Odin's](../LICENSE), platform bindings only | https://developer.apple.com/documentation/ |
| [directx/dxc](https://pkg.odin-lang.org/vendor/directx/dxc/) | DirectX shader compiler | 1.9.2609 | LLVM Release License (UIUC/NCSA)[^dxc] | https://github.com/microsoft/DirectXShaderCompiler |
| directx: [d3d11](https://pkg.odin-lang.org/vendor/directx/d3d11/), [d3d12](https://pkg.odin-lang.org/vendor/directx/d3d12/), [dxgi](https://pkg.odin-lang.org/vendor/directx/dxgi/), [d3d_compiler](https://pkg.odin-lang.org/vendor/directx/d3d_compiler/) | Direct3D 11 and 12, DXGI and the D3D shader compiler | Windows API | [Odin's](../LICENSE), platform bindings only | https://learn.microsoft.com/en-us/windows/win32/direct3d12/direct3d-12-graphics |
| [egl](https://pkg.odin-lang.org/vendor/egl/) | EGL, the Khronos platform graphics interface | EGL 1.5 | [Odin's](../LICENSE), platform bindings only | https://registry.khronos.org/EGL/ |
| [ENet](https://pkg.odin-lang.org/vendor/ENet/) | Reliable UDP networking | 1.3.18 | MIT | https://github.com/lsalzman/enet |
| [fontstash](https://pkg.odin-lang.org/vendor/fontstash/) | Font texture atlas builder | Port | zlib | https://github.com/memononen/fontstash |
| [ggpo](https://pkg.odin-lang.org/vendor/ggpo/) | Rollback networking for peer-to-peer games | 7ddadef (no releases) | MIT | https://github.com/pond3r/ggpo |
| [glfw](https://pkg.odin-lang.org/vendor/glfw/) | Windows, input, and OpenGL and Vulkan contexts | 3.5.1 | zlib | https://github.com/glfw/glfw |
| [kb_text_shape](https://pkg.odin-lang.org/vendor/kb_text_shape/) | Unicode text segmentation and OpenType shaping | 2.28g | zlib | https://github.com/JimmyLefevre/kb |
| [libc](https://pkg.odin-lang.org/vendor/libc/) | C standard library |  | [Odin's](../LICENSE), platform bindings only | https://en.cppreference.com/w/c/header |
| [libc-shim](https://pkg.odin-lang.org/vendor/libc-shim/) | Minimal libc for building C libraries to WASM |  | [Odin's](../LICENSE), platform bindings only |  |
| [lua/5.1](https://pkg.odin-lang.org/vendor/lua/5.1/) | Lua 5.1 scripting language | 5.1.5 | MIT | https://www.lua.org |
| [lua/5.2](https://pkg.odin-lang.org/vendor/lua/5.2/) | Lua 5.2 scripting language | 5.2.4 | MIT | https://www.lua.org |
| [lua/5.3](https://pkg.odin-lang.org/vendor/lua/5.3/) | Lua 5.3 scripting language | 5.3.6 | MIT | https://www.lua.org |
| [lua/5.4](https://pkg.odin-lang.org/vendor/lua/5.4/) | Lua 5.4 scripting language | 5.4.9 | MIT | https://www.lua.org |
| [lua/5.5](https://pkg.odin-lang.org/vendor/lua/5.5/) | Lua 5.5 scripting language | 5.5.1 | MIT | https://www.lua.org |
| [microui](https://pkg.odin-lang.org/vendor/microui/) | Tiny immediate-mode UI library | Port | MIT | https://github.com/rxi/microui |
| [miniaudio](https://pkg.odin-lang.org/vendor/miniaudio/) | Audio playback and capture | 0.11.26 | Public domain or MIT-0 | https://github.com/mackron/miniaudio |
| [nanovg](https://pkg.odin-lang.org/vendor/nanovg/) | Antialiased 2D vector graphics | Port | zlib | https://github.com/memononen/nanovg |
| [OpenEXRCore](https://pkg.odin-lang.org/vendor/OpenEXRCore/) | Reading and writing EXR images | 3.5.3 | BSD-3-Clause[^exr] | https://github.com/AcademySoftwareFoundation/openexr |
| [OpenGL](https://pkg.odin-lang.org/vendor/OpenGL/) | OpenGL bindings with a loader and helpers | Generated with glad | MIT | https://github.com/Dav1dde/glad |
| [portmidi](https://pkg.odin-lang.org/vendor/portmidi/) | Real-time MIDI input and output | 2.0.8 | MIT | https://github.com/PortMidi/portmidi |
| [raylib](https://pkg.odin-lang.org/vendor/raylib/) (with raygui) | Simple library for making games, with raygui | 6.2 (raygui 5.0) | zlib | https://github.com/raysan5/raylib |
| [sdl2](https://pkg.odin-lang.org/vendor/sdl2/) | Windows, input, audio and graphics | 2.32.10 | zlib | https://github.com/libsdl-org/SDL |
| [sdl2/image](https://pkg.odin-lang.org/vendor/sdl2/image/) | SDL2 image loading | 2.8.12 | zlib[^sdl2-image] | https://github.com/libsdl-org/SDL_image |
| [sdl2/mixer](https://pkg.odin-lang.org/vendor/sdl2/mixer/) | SDL2 audio mixing and music | 2.8.2 | zlib[^sdl2-mixer] | https://github.com/libsdl-org/SDL_mixer |
| [sdl2/net](https://pkg.odin-lang.org/vendor/sdl2/net/) | SDL2 networking | 2.4.0 | zlib | https://github.com/libsdl-org/SDL_net |
| [sdl2/ttf](https://pkg.odin-lang.org/vendor/sdl2/ttf/) | SDL2 TrueType font rendering | 2.24.0 | zlib[^sdl2-ttf] | https://github.com/libsdl-org/SDL_ttf |
| [sdl3](https://pkg.odin-lang.org/vendor/sdl3/) | Windows, input, audio and graphics | 3.4.18 | zlib | https://github.com/libsdl-org/SDL |
| [sdl3/image](https://pkg.odin-lang.org/vendor/sdl3/image/) | SDL3 image loading | 3.4.8 | zlib[^sdl3-image] | https://github.com/libsdl-org/SDL_image |
| [sdl3/mixer](https://pkg.odin-lang.org/vendor/sdl3/mixer/) | SDL3 audio mixing and music | 3.2.4 | zlib[^sdl3-mixer] | https://github.com/libsdl-org/SDL_mixer |
| [sdl3/net](https://pkg.odin-lang.org/vendor/sdl3/net/) | SDL3 networking | 3.2.0 | zlib | https://github.com/libsdl-org/SDL_net |
| [sdl3/ttf](https://pkg.odin-lang.org/vendor/sdl3/ttf/) | SDL3 TrueType font rendering | 3.2.2 | zlib[^sdl3-ttf] | https://github.com/libsdl-org/SDL_ttf |
| [stb/easy_font](https://pkg.odin-lang.org/vendor/stb/easy_font/) | Quick bitmap font for debug text | Port | Public domain or MIT | https://github.com/nothings/stb |
| [stb/image](https://pkg.odin-lang.org/vendor/stb/image/) | Image loading, writing and resizing | stb_image 2.30, stb_image_write 1.16, stb_image_resize2 2.50 | Public domain or MIT | https://github.com/nothings/stb |
| [stb/rect_pack](https://pkg.odin-lang.org/vendor/stb/rect_pack/) | 2D rectangle packing | 1.01 | Public domain or MIT | https://github.com/nothings/stb |
| [stb/sprintf](https://pkg.odin-lang.org/vendor/stb/sprintf/) | Fast snprintf replacement | 1.10 | Public domain or MIT | https://github.com/nothings/stb |
| [stb/truetype](https://pkg.odin-lang.org/vendor/stb/truetype/) | TrueType font parsing and rasterizing | 1.26 | Public domain or MIT | https://github.com/nothings/stb |
| [stb/vorbis](https://pkg.odin-lang.org/vendor/stb/vorbis/) | Ogg Vorbis decoder | 1.22 | Public domain or MIT | https://github.com/nothings/stb |
| [vulkan](https://pkg.odin-lang.org/vendor/vulkan/) | Vulkan graphics and compute API | Headers 1.4.354 | Apache-2.0 | https://github.com/KhronosGroup/Vulkan-Headers |
| [wasm/WebGL](https://pkg.odin-lang.org/vendor/wasm/WebGL/) | Browser graphics API for js_wasm32 | WebGL 1 and 2 | [Odin's](../LICENSE), platform bindings only | https://registry.khronos.org/webgl/specs/latest/ |
| [wgpu](https://pkg.odin-lang.org/vendor/wgpu/) | WebGPU graphics API | 29.0.1.1 | Apache-2.0 or MIT | https://github.com/gfx-rs/wgpu-native |
| windows: [GameInput](https://pkg.odin-lang.org/vendor/windows/GameInput/), [XAudio2](https://pkg.odin-lang.org/vendor/windows/XAudio2/), [wasapi](https://pkg.odin-lang.org/vendor/windows/wasapi/) | Windows audio (WASAPI, XAudio2) and game input | Windows SDK 10.0.26100.0 | [Odin's](../LICENSE), platform bindings only | https://learn.microsoft.com/en-us/windows/win32/ |
| [x11/xlib](https://pkg.odin-lang.org/vendor/x11/xlib/) | X11 window system client library |  | [Odin's](../LICENSE), platform bindings only | https://www.x.org/releases/current/doc/ |
| [zlib](https://pkg.odin-lang.org/vendor/zlib/) | Deflate compression | 1.3.2 | zlib | https://github.com/madler/zlib |

[^licenses]: This column is indicative only. Always consult the license files present in the package, and at its upstream.
[^sdl2-image]: `SDL2_image.dll` loads `libavif-16.dll`, `libtiff-5.dll`, `libwebp-7.dll` and `libwebpdemux-2.dll` from the same directory, for AVIF, TIFF and WebP. Their licenses are the `LICENSE.*.txt` files there.
[^sdl2-mixer]: `SDL2_mixer.dll` loads `libgme.dll`, `libogg-0.dll`, `libopus-0.dll`, `libopusfile-0.dll`, `libwavpack-1.dll` and `libxmp.dll` from the same directory, for game music, Ogg Vorbis, Opus, WavPack and tracker modules. Their licenses are the `LICENSE.*.txt` files there.
[^sdl2-ttf]: `SDL2_ttf.dll` is built with zlib and FreeType, which have their own licenses: `LICENSE.zlib.txt` and `LICENSE.freetype.txt` in the same directory.
[^sdl3-image]: `SDL3_image.dll` loads `libavif-16.dll`, `libpng16-16.dll`, `libtiff-6.dll`, `libwebp-7.dll`, `libwebpdemux-2.dll` and `libwebpmux-3.dll` from the same directory, for AVIF, PNG, TIFF and WebP. Their licenses, and those of the AVIF codecs aom and dav1d, are the `LICENSE.*.txt` files there.
[^sdl3-mixer]: `SDL3_mixer.dll` loads `libgme.dll`, `libogg-0.dll`, `libopus-0.dll`, `libopusfile-0.dll`, `libwavpack-1.dll` and `libxmp.dll` from the same directory, for game music, Ogg Vorbis, Opus, WavPack and tracker modules. Their licenses are the `LICENSE.*.txt` files there.
[^sdl3-ttf]: `SDL3_ttf.dll` is built with FreeType, HarfBuzz, PlutoSVG and PlutoVG, which have their own licenses: the `LICENSE.*.txt` files in the same directory.
[^dxc]: `dxcompiler.dll` and `dxil.dll` include third party components. Their licenses are in `directx/ThirdPartyNotices.txt`.
[^curl]: `curl.lib` is built with zlib, zstd, brotli and nghttp2, which are linked in as the other `.lib` files in `lib`. Their licenses are `LICENSE.zlib.txt`, `LICENSE.zstd.txt`, `LICENSE.brotli.txt` and `LICENSE.nghttp2.txt` in the `curl` directory.
[^exr]: `OpenEXRCore-3_5.lib` includes OpenJPH, zstd, libdeflate and Imath's headers. Their licenses are `LICENSE.openjph.txt`, `LICENSE.zstd.txt`, `LICENSE.libdeflate.txt` and `LICENSE.imath.txt` in the `OpenEXRCore` directory.
