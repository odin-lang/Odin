package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"

// Links `vendor:sdl3` and prints its version as a line `VERSION SDL3 <version>`. On Windows the library is the DLL of
// `vendor:sdl3`, which `test.bat` copies next to the test, and its version must be the one the bindings were written for. Elsewhere
// it is the system's library, which can be any version, so it is only printed. Run `test.bat` or `test.sh`: each library has its own
// test file, so that one that isn't installed doesn't stop the others from being tested.

@(test)
test_sdl :: proc(t: ^testing.T) {
	linked := SDL.GetVersion()
	major, minor, micro := SDL.VERSIONNUM_MAJOR(linked), SDL.VERSIONNUM_MINOR(linked), SDL.VERSIONNUM_MICRO(linked)
	log.infof("VERSION SDL3 %v.%v.%v", major, minor, micro)
	when ODIN_OS == .Windows {
		got      := [3]int{int(major), int(minor), int(micro)}
		bindings := [3]int{SDL.MAJOR_VERSION, SDL.MINOR_VERSION, SDL.MICRO_VERSION}
		testing.expectf(t, got == bindings, "the SDL3 DLL is %v but the bindings are for %v", got, bindings)
	}

	revision := SDL.GetRevision()
	testing.expect(t, revision != nil)
	log.infof("REVISION SDL3 %v", revision)
}
