package time

Tick :: struct {
	_nsec: i64, // relative amount
}

tick_now :: proc() -> Tick {
	return _tick_now();
}

tick_diff :: proc(start, end: Tick) -> Duration {
	d := end._nsec - start._nsec;
	return Duration(d);
}

tick_lap_time :: proc(prev: ^Tick) -> Duration {
	d: Duration;
	t := tick_now();
	if prev._nsec != 0 {
		d = tick_diff(prev^, t);
	}
	prev^ = t;
	return d;
}

tick_since :: proc(start: Tick) -> Duration {
	return tick_diff(start, tick_now());
}


@(deferred_in_out=_tick_duration_end)
SCOPED_TICK_DURATION :: proc(d: ^Duration) -> Tick {
	return tick_now();
}


_tick_duration_end :: proc(d: ^Duration, t: Tick) {
	d^ = tick_since(t);
}
