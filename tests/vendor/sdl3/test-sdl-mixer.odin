package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import MIX "vendor:sdl3/mixer"

// Links `vendor:sdl3/mixer` and prints its version as a line `VERSION SDL3_mixer <version>`. On Windows it must be the version the
// bindings were written for, and initializing it loads the libraries that SDL3_mixer needs for its audio formats, which are the
// DLLs that `test.bat` copies next to the test.

@(test)
test_sdl_mixer :: proc(t: ^testing.T) {
	linked := MIX.Version()
	major, minor, micro := SDL.VERSIONNUM_MAJOR(linked), SDL.VERSIONNUM_MINOR(linked), SDL.VERSIONNUM_MICRO(linked)
	log.infof("VERSION SDL3_mixer %v.%v.%v", major, minor, micro)
	when ODIN_OS == .Windows {
		got      := [3]int{int(major), int(minor), int(micro)}
		bindings := [3]int{MIX.MAJOR_VERSION, MIX.MINOR_VERSION, MIX.MICRO_VERSION}
		testing.expectf(t, got == bindings, "the SDL3_mixer DLL is %v but the bindings are for %v", got, bindings)
	}

	if !testing.expect(t, bool(MIX.Init()), "SDL3_mixer failed to initialize, its DLLs are missing or the wrong version") { return }
	defer MIX.Quit()

	// the audio decoders SDL3_mixer has, which depend on the DLLs next to the test on Windows
	decoders: [dynamic]string
	defer delete(decoders)
	for i in 0 ..< MIX.GetNumAudioDecoders() { append(&decoders, string(MIX.GetAudioDecoder(i))) }
	log.infof("SDL3_mixer decoders %v", decoders[:])
	testing.expect(t, len(decoders) > 0, "SDL3_mixer has no audio decoders")

	// Some are built in, and OPUS, WAVPACK, GME and XMP need DLLs that `test.bat` copies next to the test.
	for name in ([?]string{"WAV", "STBVORBIS", "DRFLAC", "DRMP3", "OPUS", "WAVPACK", "GME", "XMP"}) {
		found := false
		for d in decoders { if d == name { found = true } }
		when ODIN_OS == .Windows {
			testing.expectf(t, found, "SDL3_mixer has no %v decoder, its DLLs are missing or the wrong version", name)
		} else {
			if !found { log.infof("SDL3_mixer has no %v decoder", name) }
		}
	}
}
