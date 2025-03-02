package sdl3

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	OpenURL :: proc(url: cstring) -> bool ---
}