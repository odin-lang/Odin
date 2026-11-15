package test_vendor_sdl2

import "core:log"
import "core:testing"
import NET "vendor:sdl2/net"

// Links `vendor:sdl2/net` and prints its version as a line `VERSION SDL2_net <version>`. On Windows it must be the version the
// bindings were written for.

@(test)
test_sdl_net :: proc(t: ^testing.T) {
	linked := NET.Linked_Version()
	log.infof("VERSION SDL2_net %v.%v.%v", linked.major, linked.minor, linked.patch)
	when ODIN_OS == .Windows {
		got      := [3]int{int(linked.major), int(linked.minor), int(linked.patch)}
		bindings := [3]int{NET.MAJOR_VERSION, NET.MINOR_VERSION, NET.PATCHLEVEL}
		testing.expectf(t, got == bindings, "the SDL2_net DLL is %v but the bindings are for %v", got, bindings)
	}

	testing.expect_value(t, NET.Init(), 0)
	NET.Quit()
}
