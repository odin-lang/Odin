# Vendor Collection

The `vendor:` prefix for Odin imports is a package collection that comes with this implementation of the Odin programming language.

Its use is similar to that of `core:` packages, which would be available in any Odin implementation.

Presently, the `vendor:` collection comprises the following packages:

## microui

A tiny, portable, immediate-mode UI library written in Odin. (Ported from [rxi/microui](https://github.com/rxi/microui).)

This package is available under the MIT license. See `LICENSE` for more details.

## OpenGL

Bindings for the OpenGL graphics API and helpers in idiomatic Odin to, for example, reload shaders when they're changed on disk.

This package is available under the MIT license. See `LICENSE` and `LICENSE_glad` for more details.

## raylib

Bindings for the raylib, a simple and easy-to-use library to enjoy videogames programming, in idiomatic Odin.

This package is available under the Zlib license. See `LICENSE` for more details.

## STB

Bindings/ports for many of the [STB libraries](https://github.com/nothings/stb), single-file public domain (or MIT licensed) libraries for C/C++.

### vendor:stb/easy_font 

quick-and-dirty easy-to-deploy bitmap font for printing frame rate, etc

Source port of `stb_easy_font.h`

### vendor:stb/image 
Image _loader_, _writer_, and _resizer_.

image loading/decoding from file/memory: JPG, PNG, TGA, BMP, PSD, GIF, HDR, PIC

image writing to disk: PNG, TGA, BMP

resize images larger/smaller with good quality

Bindings of `stb_image.h`, `stb_image_rewrite.h`, `stb_image_resize.h`

### vendor:stb/rect_pack
simple 2D rectangle packer with decent quality

Bindings of `stb_rect_pack.h`

### vendor:stb/truetype
parse, decode, and rasterize characters from truetype fonts

Bindings of `stb_truetype.h`

### vendor:stb/vorbis
decode ogg vorbis files from file/memory to float/16-bit signed output

Bindings of `stb_vorbis.c`

## SDL2

Bindings for the cross platform multimedia API [SDL2](https://github.com/libsdl-org/SDL) and its sub-projects.

`SDL2.dll` and `SDL2.lib` are available under SDL's [zlib](https://github.com/libsdl-org/SDL/blob/main/LICENSE.txt) license.

See also LICENSE.txt in the `sdl2` directory itself.

### SDL2 Image

Bindings for SDL's image decoding library, subject to SDL's [zlib](https://github.com/libsdl-org/SDL_image/blob/main/LICENSE.txt) license.

SDL2 Image relies on 3rd party libraries to support various image formats. You can find the licenses for these in the `image` directory, alongside SDL\_image's own license.

### SDL2 Mixer

Bindings for SDL's sound decoding library and mixer, subject to SDL's [zlib](https://github.com/libsdl-org/SDL_mixer/blob/master/LICENSE.txt) license.

SDL2 Mixer relies on 3rd party libraries to support various audio formats. You can find the licenses for these in the `mixer` directory, alongside SDL\_mixer's own license.

### SDL2 Net

Bindings for SDL's networking library, subject to SDL's [zlib](https://github.com/libsdl-org/SDL_net/blob/main/COPYING.txt) license.

### SDL2 TTF

Bindings for SDL's font rendering library, subject to SDL's [zlib](https://github.com/libsdl-org/SDL_ttf/blob/main/COPYING.txt) license.

SDL2 TTF relies on 3rd party libraries `zlib`, available under the ZLIB license, and `FreeType`, available under its own license. Both can be found in the `ttf` directory.

## Vulkan

The Vulkan 3D graphics API are automatically generated from headers provided by Khronos, and are made available under the [Apache License, Version 2.0](https://github.com/KhronosGroup/Vulkan-Headers/blob/master/LICENSE.txt).

## GLFW

Bindings for the multi-platform library for OpenGL, OpenGL ES, Vulkan, window and input API [GLFW](https://github.com/glfw/glfw).

`GLFW.dll` and `GLFW.lib` are available under GLFW's [zlib/libpng](https://www.glfw.org/license.html) license.

See also LICENSE.txt in the `glfw` directory itself.

## PortMidi

[PortMidi](https://sourceforge.net/projects/portmedia/) Portable Real-Time MIDI Library.

`portmidi_s.lib` is available under PortMidi's [MIT](https://sourceforge.net/projects/portmedia/) license.

See also LICENSE.txt in the `portmidi` directory itself.


## ENet

[ENet](http://enet.bespin.org/) Reliable UDP networking library.

`enet.lib` and `enet64.lib` are available under ENet's [MIT](http://enet.bespin.org/License.html) license.

See also LICENSE in the `ENet` directory itself.

## GGPO

[GGPO](https://www.ggpo.net/) GGPO Rollback Networking SDK.

Zero-input latency networking library for peer-to-peer games.

See also LICENSE in the `GGPO` directory itself.

## Botan

[Botan](https://botan.randombit.net/) Crypto and TLS library.

`botan.lib` is available under Botan's [BSD](https://botan.randombit.net/license.txt) license.

See also LICENSE in the `botan` directory itself.
Includes full bindings as well as wrappers to match the `core:crypto` API.

## CommonMark

[CMark](https://github.com/commonmark/cmark) CommonMark parsing library.

See also LICENSE in the `commonmark` directory itself.
Includes full bindings and Windows `.lib` and `.dll`.