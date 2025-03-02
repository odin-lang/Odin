#+private
#+build darwin, freebsd, openbsd, netbsd, haiku
package time

import "core:sys/posix"

_IS_SUPPORTED :: true

_now :: proc "contextless" () -> Time {
	time_spec_now: posix.timespec
	posix.clock_gettime(.REALTIME, &time_spec_now)
	ns := i64(time_spec_now.tv_sec) * 1e9 + time_spec_now.tv_nsec
	return Time{_nsec=ns}
}

_sleep :: proc "contextless" (d: Duration) {
	ds := duration_seconds(d)
	seconds := posix.time_t(ds)
	nanoseconds := i64((ds - f64(seconds)) * 1e9)

	ts := posix.timespec{
		tv_sec  = seconds,
		tv_nsec = nanoseconds,
	}

	for {
		res := posix.nanosleep(&ts, &ts)
		if res == .OK || posix.errno() != .EINTR {
			break
		}
	}
}

when ODIN_OS == .Darwin {
	TICK_CLOCK :: posix.Clock(4) // CLOCK_MONOTONIC_RAW
} else {
	// It looks like the BSDs don't have a CLOCK_MONOTONIC_RAW equivalent.
	TICK_CLOCK :: posix.Clock.MONOTONIC
}

_tick_now :: proc "contextless" () -> Tick {
	t: posix.timespec
	posix.clock_gettime(TICK_CLOCK, &t)
	return Tick{_nsec = i64(t.tv_sec)*1e9 + t.tv_nsec}
}

_yield :: proc "contextless" () {
	posix.sched_yield()
}

