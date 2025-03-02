package sdl3

when ODIN_OS == .Windows {
	@(export) foreign import lib { "SDL3.lib" }
} else {
	@(export) foreign import lib { "system:SDL3" }
}