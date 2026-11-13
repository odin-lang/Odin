#+build !windows, !arm64
/*
Imports all packages using SDL3, can't go in the parent directory
because SDL2 and SDL3 will have naming conflicts.

Not on Windows arm64, where `vendor:sdl3` panics as only x64 builds of SDL3 are bundled for Windows.
*/
package all_sdl3

import SDL "vendor:sdl3"
import IMG "vendor:sdl3/image"
import MIX "vendor:sdl3/mixer"
import NET "vendor:sdl3/net"
import TTF "vendor:sdl3/ttf"

_ :: SDL
_ :: IMG
_ :: MIX
_ :: NET
_ :: TTF
