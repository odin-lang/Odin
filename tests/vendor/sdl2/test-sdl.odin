package test_vendor_sdl2

import "core:log"
import "core:testing"
import SDL "vendor:sdl2"

// Links `vendor:sdl2` and prints its version as a line `VERSION SDL2 <version>`. On Windows the library is the DLL of
// `vendor:sdl2`, which `test.bat` copies next to the test, and its version must be the one the bindings were written for. Elsewhere
// it is the system's library, which can be any version, so it is only printed. Run `test.bat` or `test.sh`: each library has its own
// test file, so that one that isn't installed doesn't stop the others from being tested.

@(test)
test_sdl :: proc(t: ^testing.T) {
	linked: SDL.version
	SDL.GetVersion(&linked)
	log.infof("VERSION SDL2 %v.%v.%v", linked.major, linked.minor, linked.patch)
	when ODIN_OS == .Windows {
		got      := [3]int{int(linked.major), int(linked.minor), int(linked.patch)}
		bindings := [3]int{SDL.MAJOR_VERSION, SDL.MINOR_VERSION, SDL.PATCHLEVEL}
		testing.expectf(t, got == bindings, "the SDL2 DLL is %v but the bindings are for %v", got, bindings)
	}

	// the version from SDL's header the bindings were made from
	compiled: SDL.version
	SDL.VERSION(&compiled)
	testing.expect_value(t, int(compiled.major), SDL.MAJOR_VERSION)

	revision := SDL.GetRevision()
	testing.expect(t, revision != nil)
	log.infof("REVISION SDL2 %v", revision)
}
