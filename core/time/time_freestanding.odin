//+build freestanding
package time

IS_SUPPORTED :: false

now :: proc() -> Time {
	return {}
}

sleep :: proc(d: Duration) {
}

_tick_now :: proc "contextless" () -> Tick {
	return {}
}

