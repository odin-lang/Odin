package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

TimerCallback :: proc "c" (interval: u32, param: rawptr) -> u32
TimerID :: distinct c.int

TICKS_PASSED :: #force_inline proc "c" (A, B: u32) -> bool {
	return bool(i32(B) - i32(A) <= 0)
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetTicks                :: proc() -> u32 ---
	GetPerformanceCounter   :: proc() -> u64 ---
	GetPerformanceFrequency :: proc() -> u64 ---
	Delay                   :: proc(ms: u32) ---
	AddTimer                :: proc(interval: u32, callback: TimerCallback, param: rawptr) -> TimerID ---
	RemoveTimer             :: proc(id: TimerID) -> bool ---
}
