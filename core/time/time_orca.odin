//+private
//+build orca
package time

import "base:intrinsics"

import "core:sys/orca"

_IS_SUPPORTED :: true

_now :: proc "contextless" () -> Time {
	CLK_JAN_1970 :: 2208988800
	secs := orca.clock_time(.DATE)
	return Time{i64((secs - CLK_JAN_1970) * 1e9)}
}

_sleep :: proc "contextless" (d: Duration) {
	// NOTE: no way to sleep afaict.
	if d > 0 {
		orca.log_warning("core:time 'sleep' is unimplemented for orca")
	}
}

_tick_now :: proc "contextless" () -> Tick {
	secs := orca.clock_time(.MONOTONIC)
	return Tick{i64(secs * 1e9)}
}

_yield :: proc "contextless" () {}
