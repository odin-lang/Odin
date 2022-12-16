//+private
//+build freestanding
package time

_IS_SUPPORTED :: false

_now :: proc "contextless" () -> Time {
	return {}
}

_sleep :: proc "contextless" (d: Duration) {
}

_tick_now :: proc "contextless" () -> Tick {
	return {}
}

_yield :: proc "contextless" () {
}
