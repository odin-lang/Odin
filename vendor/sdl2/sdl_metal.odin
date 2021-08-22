package sdl2

import "core:c"

when ODIN_OS == "windows" do foreign import lib "SDL2.lib"
when ODIN_OS == "linux"   do foreign import lib "system:SDL2"
when ODIN_OS == "darwin"  do foreign import lib "system:SDL2"
when ODIN_OS == "freebsd" do foreign import lib "system:SDL2"

MetalView :: distinct rawptr;

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Metal_CreateView      :: proc(window: ^Window) -> MetalView ---
	Metal_DestroyView     :: proc(view: MetalView) ---
	Metal_GetLayer        :: proc(view: MetalView) -> rawptr ---
	Metal_GetDrawableSize :: proc(window: ^Window, w, h: ^c.int) ---
}