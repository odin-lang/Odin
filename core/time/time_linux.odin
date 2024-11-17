package time

import "core:sys/linux"

_IS_SUPPORTED :: true

_now :: proc "contextless" () -> Time {
	time_spec_now, _ := linux.clock_gettime(.REALTIME)
	ns := i64(time_spec_now.time_sec) * 1e9 + i64(time_spec_now.time_nsec)
	return Time{_nsec=ns}
}

_sleep :: proc "contextless" (d: Duration) {
	ds := duration_seconds(d)
	seconds := uint(ds)
	nanoseconds := uint((ds - f64(seconds)) * 1e9)

	ts := linux.Time_Spec{
		time_sec  = seconds,
		time_nsec = nanoseconds,
	}

	for {
		if linux.nanosleep(&ts, &ts) != .EINTR {
			break
		}
	}
}

_tick_now :: proc "contextless" () -> Tick {
	t, _ := linux.clock_gettime(.MONOTONIC_RAW)
	return Tick{_nsec = i64(t.time_sec)*1e9 + i64(t.time_nsec)}
}

_yield :: proc "contextless" () {
	linux.sched_yield()
}

