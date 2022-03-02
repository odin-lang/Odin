package sdl2

import "core:c"

when ODIN_OS == .Windows { foreign import lib "SDL2.lib"    }
when ODIN_OS == .Linux   { foreign import lib "system:SDL2" }
when ODIN_OS == .Darwin  { foreign import lib "system:SDL2" }
when ODIN_OS == .FreeBSD { foreign import lib "system:SDL2" }
when ODIN_OS == .OpenBSD { foreign import lib "system:SDL2" }

MetalView :: distinct rawptr

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Metal_CreateView      :: proc(window: ^Window) -> MetalView ---
	Metal_DestroyView     :: proc(view: MetalView) ---
	Metal_GetLayer        :: proc(view: MetalView) -> rawptr ---
	Metal_GetDrawableSize :: proc(window: ^Window, w, h: ^c.int) ---
}
