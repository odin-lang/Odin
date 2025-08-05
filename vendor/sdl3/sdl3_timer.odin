package sdl3

MS_PER_SECOND   :: 1000
US_PER_SECOND   :: 1000000
NS_PER_SECOND   :: 1000000000
NS_PER_MS       :: 1000000
NS_PER_US       :: 1000

@(require_results) SECONDS_TO_NS :: #force_inline proc "c" (S: Uint64)  -> Uint64 { return S * NS_PER_SECOND  }
@(require_results) NS_TO_SECONDS :: #force_inline proc "c" (NS: Uint64) -> Uint64 { return NS / NS_PER_SECOND }
@(require_results) MS_TO_NS      :: #force_inline proc "c" (MS: Uint64) -> Uint64 { return MS * NS_PER_MS     }
@(require_results) NS_TO_MS      :: #force_inline proc "c" (NS: Uint64) -> Uint64 { return NS / NS_PER_MS     }
@(require_results) US_TO_NS      :: #force_inline proc "c" (US: Uint64) -> Uint64 { return US * NS_PER_US     }
@(require_results) NS_TO_US      :: #force_inline proc "c" (NS: Uint64) -> Uint64 { return NS / NS_PER_US     }

TimerID :: distinct Uint32

TimerCallback   :: #type proc "c" (userdata: rawptr, timerID: TimerID, interval: Uint32) -> Uint32
NSTimerCallback :: #type proc "c" (userdata: rawptr, timerID: TimerID, interval: Uint64) -> Uint64

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetTicks                :: proc() -> Uint64 ---
	GetTicksNS              :: proc() -> Uint64 ---
	GetPerformanceCounter   :: proc() -> Uint64 ---
	GetPerformanceFrequency :: proc() -> Uint64 ---
	Delay                   :: proc(ms: Uint32) ---
	DelayNS                 :: proc(ns: Uint64) ---
	DelayPrecise            :: proc(ns: Uint64) ---
	AddTimer                :: proc(interval: Uint32, callback: TimerCallback, userdata: rawptr) -> TimerID ---
	AddTimerNS              :: proc(interval: Uint64, callback: NSTimerCallback, userdata: rawptr) -> TimerID ---
	RemoveTimer             :: proc(id: TimerID) -> bool ---
}