//+private
//+build js
package time

foreign import "odin_env"

_IS_SUPPORTED :: true

_now :: proc "contextless" () -> Time {
	foreign odin_env {
		time_now :: proc "contextless" () -> i64 ---
	}
	return Time{time_now()}
}

_sleep :: proc "contextless" (d: Duration) {
	foreign odin_env {
		time_sleep :: proc "contextless" (ms: u32) ---
	}
	if d > 0 {
		time_sleep(u32(d/1e6))
	}
}

_tick_now :: proc "contextless" () -> Tick {
	foreign odin_env {
		tick_now :: proc "contextless" () -> i64 ---
	}
	return Tick{tick_now()}
}

_yield :: proc "contextless" () {
}
