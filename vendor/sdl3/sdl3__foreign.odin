package sdl3

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		@(export) foreign import lib { "amd64/SDL3.lib" }
	} else when ODIN_ARCH == .arm64 {
		@(export) foreign import lib { "arm64/SDL3.lib" }
	} else {
		@(export) foreign import lib { "i386/SDL3.lib" }
	}
} else {
	@(export) foreign import lib { "system:SDL3" }
}
