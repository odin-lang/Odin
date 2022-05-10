//+build js
package time

IS_SUPPORTED :: false

now :: proc() -> Time {
	return {}
}

sleep :: proc(d: Duration) {
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
