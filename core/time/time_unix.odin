//+private
//+build linux, darwin, freebsd, openbsd, netbsd, haiku
package time

import "core:sys/unix"

_IS_SUPPORTED :: true // NOTE: Times on Darwin are UTC.

_now :: proc "contextless" () -> Time {
	time_spec_now: unix.timespec
	unix.clock_gettime(unix.CLOCK_REALTIME, &time_spec_now)
	ns := time_spec_now.tv_sec * 1e9 + time_spec_now.tv_nsec
	return Time{_nsec=ns}
}

_sleep :: proc "contextless" (d: Duration) {
	ds := duration_seconds(d)
	seconds := u32(ds)
	nanoseconds := i64((ds - f64(seconds)) * 1e9)

	if seconds > 0     { unix.sleep(seconds)   }
	if nanoseconds > 0 { unix.inline_nanosleep(nanoseconds) }
}

_tick_now :: proc "contextless" () -> Tick {
	t: unix.timespec
	unix.clock_gettime(unix.CLOCK_MONOTONIC_RAW, &t)
	return Tick{_nsec = t.tv_sec*1e9 + t.tv_nsec}
}

_yield :: proc "contextless" () {
	unix.sched_yield()
}

