package sdl3

SDL3_WASM_LIB :: #config(SDL3_WASM_LIB, "env.o")

// NOTE: `vendor:sdl3/image`, `mixer`, `net` and `ttf` import this package, so this covers them too.
when ODIN_OS == .Windows && ODIN_ARCH == .arm64 {
	#panic("vendor:sdl3 only bundles x64 builds of SDL3 and its satellite libraries for Windows, use -target:windows_amd64 instead, which Windows on ARM runs through emulation")
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	@(export) foreign import lib { SDL3_WASM_LIB }
} else when ODIN_OS == .Windows {
	@(export) foreign import lib { "SDL3.lib" }
} else {
	@(export) foreign import lib { "system:SDL3" }
}