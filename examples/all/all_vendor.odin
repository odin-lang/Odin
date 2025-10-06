#+build !js
package all

@(require) import "vendor:cgltf"
@(require) import "vendor:ENet"
@(require) import "vendor:OpenEXRCore"
@(require) import "vendor:ggpo"
@(require) import "vendor:OpenGL"
@(require) import "vendor:glfw"
@(require) import "vendor:microui"
@(require) import "vendor:miniaudio"
@(require) import "vendor:portmidi"
@(require) import "vendor:raylib"
@(require) import "vendor:zlib"

@(require) import "vendor:sdl2"
@(require) import "vendor:sdl2/net"
@(require) import "vendor:sdl2/image"
@(require) import "vendor:sdl2/mixer"
@(require) import "vendor:sdl2/ttf"

@(require) import "vendor:vulkan"

// NOTE(bill): only one can be checked at a time
@(require) import lua54 "vendor:lua/5.4"
@(require) import "vendor:nanovg"
@(require) import "vendor:nanovg/gl"
@(require) import "vendor:fontstash"

// NOTE: needed for doc generator
@(require) import "core:sys/darwin/Foundation"
@(require) import "core:sys/darwin/CoreFoundation"
@(require) import "core:sys/darwin/Security"
@(require) import "vendor:darwin/Metal"
@(require) import "vendor:darwin/MetalKit"
@(require) import "vendor:darwin/QuartzCore"

@(require) import "vendor:directx/dxc"
@(require) import "vendor:directx/d3d11"
@(require) import "vendor:directx/d3d12"
@(require) import "vendor:directx/dxgi"
@(require) import "vendor:commonmark"

@(require) import "vendor:stb/easy_font"
@(require) import stbi "vendor:stb/image"
@(require) import "vendor:stb/rect_pack"
@(require) import "vendor:stb/truetype"
@(require) import "vendor:stb/vorbis"


@(require) import "vendor:kb_text_shape"
