package sdl3

MetalView :: distinct rawptr

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	Metal_CreateView  :: proc(window: ^Window) -> MetalView ---
	Metal_DestroyView :: proc(view: MetalView) ---
	Metal_GetLayer    :: proc(view: MetalView) -> rawptr ---
}