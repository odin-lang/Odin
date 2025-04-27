package sdl3

import "core:c"

CACHELINE_SIZE :: 128

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetNumLogicalCPUCores :: proc() -> c.int ---
	GetCPUCacheLineSize   :: proc() -> c.int ---
	HasAltiVec            :: proc() -> bool ---
	HasMMX                :: proc() -> bool ---
	HasSSE                :: proc() -> bool ---
	HasSSE2               :: proc() -> bool ---
	HasSSE3               :: proc() -> bool ---
	HasSSE41              :: proc() -> bool ---
	HasSSE42              :: proc() -> bool ---
	HasAVX                :: proc() -> bool ---
	HasAVX2               :: proc() -> bool ---
	HasAVX512F            :: proc() -> bool ---
	HasARMSIMD            :: proc() -> bool ---
	HasNEON               :: proc() -> bool ---
	HasLSX                :: proc() -> bool ---
	HasLASX               :: proc() -> bool ---
	GetSystemRAM          :: proc() -> c.int ---
	GetSIMDAlignment      :: proc() -> uint ---
}