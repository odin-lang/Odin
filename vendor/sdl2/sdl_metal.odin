package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib { "amd64/SDL2.lib" when ODIN_ARCH == .amd64 else "arm64/SDL2.lib" }
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

MetalView :: distinct rawptr

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Metal_CreateView      :: proc(window: ^Window) -> MetalView ---
	Metal_DestroyView     :: proc(view: MetalView) ---
	Metal_GetLayer        :: proc(view: MetalView) -> rawptr ---
	Metal_GetDrawableSize :: proc(window: ^Window, w, h: ^c.int) ---
}
