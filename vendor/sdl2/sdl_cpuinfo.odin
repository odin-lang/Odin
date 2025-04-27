package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

/* This is a guess for the cacheline size used for padding.
 * Most x86 processors have a 64 byte cache line.
 * The 64-bit PowerPC processors have a 128 byte cache line.
 * We'll use the larger value to be generally safe.
 */
CACHELINE_SIZE :: 128


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetCPUCount         :: proc() -> c.int ---
	GetCPUCacheLineSize :: proc() -> c.int ---

	HasRDTSC            :: proc() -> bool  ---
	HasAltiVec          :: proc() -> bool  ---
	HasMMX              :: proc() -> bool  ---
	Has3DNow            :: proc() -> bool  ---
	HasSSE              :: proc() -> bool  ---
	HasSSE2             :: proc() -> bool  ---
	HasSSE3             :: proc() -> bool  ---
	HasSSE41            :: proc() -> bool  ---
	HasSSE42            :: proc() -> bool  ---
	HasAVX              :: proc() -> bool  ---
	HasAVX2             :: proc() -> bool  ---
	HasAVX512F          :: proc() -> bool  ---
	HasARMSIMD          :: proc() -> bool  ---
	HasNEON             :: proc() -> bool  ---

	GetSystemRAM        :: proc() -> c.int ---

	SIMDGetAlignment    :: proc() -> c.size_t ---
	SIMDAlloc           :: proc(len: c.size_t) -> rawptr ---
	SIMDRealloc         :: proc(mem: rawptr, len: c.size_t) -> rawptr ---
	SIMDFree            :: proc(ptr: rawptr) ---
}
