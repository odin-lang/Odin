// Bindings for [[ Box2D ; https://box2d.org ]].
package vendor_box2d

import "base:intrinsics"

_ :: intrinsics

// Box2D 3.2 selects AVX2 or SSE2 at run time, so there is one library per platform. Only the WASM build comes in two
// flavors, one with SIMD and one without.
when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	@(private) VECTOR_EXT :: "_simd" when #config(VENDOR_BOX2D_ENABLE_SIMD128, intrinsics.has_target_feature("simd128")) else ""
}

when ODIN_OS == .Windows {
	@(private) LIB_PATH :: "lib/box2d_windows_amd64.lib"
} else when ODIN_OS == .Darwin {
	@(private) LIB_PATH :: "lib/box2d_darwin.a"
} else when ODIN_ARCH == .amd64 {
	@(private) LIB_PATH :: "lib/box2d_other_amd64.a"
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	@(private) LIB_PATH :: "lib/box2d_wasm" + VECTOR_EXT + ".o"
} else {
	@(private) LIB_PATH :: "lib/box2d_other.a"
}

when !#exists(LIB_PATH) {
	#panic("Could not find the compiled box2d libraries at \"" + LIB_PATH + "\", they can be compiled by running `\"" + ODIN_ROOT + "vendor/box2d/build_box2d.sh\"`")
}
