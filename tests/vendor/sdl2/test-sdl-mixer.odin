package test_vendor_sdl2

import "core:log"
import "core:os"
import "core:strings"
import "core:testing"
import SDL "vendor:sdl2"
import MIX "vendor:sdl2/mixer"

// Links `vendor:sdl2/mixer` and prints its version as a line `VERSION SDL2_mixer <version>`. On Windows it must be the version
// the bindings were written for, and initializing the audio formats loads the libraries that SDL2_mixer needs for them, which are
// the DLLs that `test.bat` copies next to the test. It also loads a sound through a silent audio driver, and lists the decoders.

@(test)
test_sdl_mixer :: proc(t: ^testing.T) {
	linked := MIX.Linked_Version()
	log.infof("VERSION SDL2_mixer %v.%v.%v", linked.major, linked.minor, linked.patch)
	when ODIN_OS == .Windows {
		dll      := [3]int{int(linked.major), int(linked.minor), int(linked.patch)}
		bindings := [3]int{MIX.MAJOR_VERSION, MIX.MINOR_VERSION, MIX.PATCHLEVEL}
		testing.expectf(t, dll == bindings, "the SDL2_mixer DLL is %v but the bindings are for %v", dll, bindings)
	}

	wanted := MIX.InitFlags{.FLAC, .MOD, .MP3, .OGG, .OPUS}
	got := transmute(MIX.InitFlags)MIX.Init(wanted)
	defer MIX.Quit()
	log.infof("SDL2_mixer formats %v", got)
	when ODIN_OS == .Windows {
		testing.expectf(t, got >= wanted, "SDL2_mixer could only initialize %v of %v, its DLLs are missing or the wrong version", got, wanted)
	}

	// A driver that plays nothing, so this works on a machine without sound.
	_ = os.set_env("SDL_AUDIODRIVER", "dummy")
	if !testing.expectf(t, SDL.InitSubSystem({.AUDIO}) == 0, "SDL could not initialize audio: %v", SDL.GetError()) { return }
	defer SDL.QuitSubSystem({.AUDIO})
	if !testing.expectf(t, MIX.OpenAudio(44100, SDL.AUDIO_S16SYS, 2, 1024) == 0, "could not open audio: %v", SDL.GetError()) { return }
	defer MIX.CloseAudio()

	// the decoders that are built in, for sounds and for music
	decoders: [dynamic]string
	defer delete(decoders)
	for i in 0 ..< MIX.GetNumChunkDecoders() { append(&decoders, string(MIX.GetChunkDecoder(i))) }
	for i in 0 ..< MIX.GetNumMusicDecoders() { append(&decoders, string(MIX.GetMusicDecoder(i))) }
	log.infof("SDL2_mixer decoders %v", decoders)
	for name in ([?]string{"WAVE", "FLAC", "MP3", "OGG"}) {
		found := false
		for d in decoders { if strings.equal_fold(d, name) { found = true } }
		// the system's library can lack some, but SDL2_mixer has these built in
		when ODIN_OS == .Windows {
			testing.expectf(t, found, "SDL2_mixer has no %v decoder", name)
		} else {
			if !found { log.infof("SDL2_mixer has no %v decoder", name) }
		}
	}

	// a tenth of a second of silence as a WAV file in memory
	SAMPLES :: 4410
	wav: [44 + SAMPLES * 2]u8
	put32 :: proc(wav: []u8, at: int, value: u32) { for i in 0 ..< 4 { wav[at + i] = u8(value >> u32(8 * i)) } }
	put16 :: proc(wav: []u8, at: int, value: u16) { for i in 0 ..< 2 { wav[at + i] = u8(value >> u32(8 * i)) } }
	copy(wav[0:], "RIFF")
	put32(wav[:], 4, u32(len(wav) - 8))
	copy(wav[8:], "WAVEfmt ")
	put32(wav[:], 16, 16)
	put16(wav[:], 20, 1)         // PCM
	put16(wav[:], 22, 1)         // mono
	put32(wav[:], 24, 44100)
	put32(wav[:], 28, 44100 * 2)
	put16(wav[:], 32, 2)
	put16(wav[:], 34, 16)
	copy(wav[36:], "data")
	put32(wav[:], 40, SAMPLES * 2)
	chunk := MIX.LoadWAV_RW(SDL.RWFromConstMem(&wav[0], i32(len(wav))), true)
	if testing.expectf(t, chunk != nil, "could not load the WAV: %v", SDL.GetError()) {
		testing.expect(t, chunk.alen > 0)
		MIX.FreeChunk(chunk)
	}
}
