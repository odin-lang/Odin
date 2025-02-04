package sdl3

SharedObject :: struct {}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	LoadObject   :: proc(sofile: cstring) -> ^SharedObject ---
	LoadFunction :: proc(handle: ^SharedObject, name: cstring) -> FunctionPointer ---
	UnloadObject :: proc(handle: ^SharedObject) ---
}