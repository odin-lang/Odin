//+private
//+build wasi
package time

import wasi "core:sys/wasm/wasi"

_IS_SUPPORTED :: false

_now :: proc "contextless" () -> Time {
	return {}
}

_sleep :: proc "contextless" (d: Duration) {
}

_tick_now :: proc "contextless" () -> Tick {
	// mul_div_u64 :: proc "contextless" (val, num, den: i64) -> i64 {
	// 	q := val / den
	// 	r := val % den
	// 	return q * num + r * num / den
	// }
	return {}
}

_yield :: proc "contextless" () {
}
