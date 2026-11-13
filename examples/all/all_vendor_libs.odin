#+build !js
#+build !windows, !arm64
package all

// NOTE: These packages link libraries that are only bundled as x64 builds for Windows, so they panic on Windows arm64.

@(require) import "vendor:curl"
@(require) import "vendor:ENet"
@(require) import "vendor:OpenEXRCore"
@(require) import "vendor:ggpo"
@(require) import "vendor:glfw"
@(require) import "vendor:portmidi"
@(require) import "vendor:raylib"
@(require) import "vendor:raylib/rlgl"
@(require) import "vendor:zlib"

@(require) import "vendor:sdl2"
@(require) import "vendor:sdl2/net"
@(require) import "vendor:sdl2/image"
@(require) import "vendor:sdl2/mixer"
@(require) import "vendor:sdl2/ttf"

// NOTE(bill): only one can be checked at a time
@(require) import lua54 "vendor:lua/5.4"

@(require) import "vendor:commonmark"
