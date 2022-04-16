package time

import "core:intrinsics"

Duration :: distinct i64

Nanosecond  :: Duration(1)
Microsecond :: 1000 * Nanosecond
Millisecond :: 1000 * Microsecond
Second      :: 1000 * Millisecond
Minute      :: 60 * Second
Hour        :: 60 * Minute

MIN_DURATION :: Duration(-1 << 63)
MAX_DURATION :: Duration(1<<63 - 1)

Time :: struct {
	_nsec: i64, // zero is 1970-01-01 00:00:00
}

Month :: enum int {
	January = 1,
	February,
	March,
	April,
	May,
	June,
	July,
	August,
	September,
	October,
	November,
	December,
}

Weekday :: enum int {
	Sunday = 0,
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday,
}

Stopwatch :: struct {
	running: bool,
	_start_time: Tick,
	_accumulation: Duration,
}

stopwatch_start :: proc(using stopwatch: ^Stopwatch) {
	if !running {
		_start_time = tick_now()
		running = true
	}
}

stopwatch_stop :: proc(using stopwatch: ^Stopwatch) {
	if running {
		_accumulation += tick_diff(_start_time, tick_now())
		running = false
	}
}

stopwatch_reset :: proc(using stopwatch: ^Stopwatch) {
	_accumulation = {}
	running = false
}

stopwatch_duration :: proc(using stopwatch: Stopwatch) -> Duration {
	if !running { return _accumulation }
	return _accumulation + tick_diff(_start_time, tick_now())
}

diff :: proc(start, end: Time) -> Duration {
	d := end._nsec - start._nsec
	return Duration(d)
}

since :: proc(start: Time) -> Duration {
	return diff(start, now())
}

duration_nanoseconds :: proc(d: Duration) -> i64 {
	return i64(d)
}
duration_microseconds :: proc(d: Duration) -> f64 {
	return duration_seconds(d) * 1e6
}
duration_milliseconds :: proc(d: Duration) -> f64 {
	return duration_seconds(d) * 1e3
}
duration_seconds :: proc(d: Duration) -> f64 {
	sec := d / Second
	nsec := d % Second
	return f64(sec) + f64(nsec)/1e9
}
duration_minutes :: proc(d: Duration) -> f64 {
	min := d / Minute
	nsec := d % Minute
	return f64(min) + f64(nsec)/(60*1e9)
}
duration_hours :: proc(d: Duration) -> f64 {
	hour := d / Hour
	nsec := d % Hour
	return f64(hour) + f64(nsec)/(60*60*1e9)
}

_less_than_half :: #force_inline proc(x, y: Duration) -> bool {
	return u64(x)+u64(x) < u64(y)
}

duration_round :: proc(d, m: Duration) -> Duration {
	if m <= 0 {
		return d
	}

	r := d % m
	if d < 0 {
		r = -r
		if _less_than_half(r, m) {
			return d + r
		}
		if d1 := d-m+r; d1 < d {
			return d1
		}
		return MIN_DURATION
	}
	if _less_than_half(r, m) {
		return d - r
	}
	if d1 := d+m-r; d1 > d {
		return d1
	}
	return MAX_DURATION
}

duration_truncate :: proc(d, m: Duration) -> Duration {
	return d if m <= 0 else d - d%m
}

date :: proc(t: Time) -> (year: int, month: Month, day: int) {
	year, month, day, _ = _abs_date(_time_abs(t), true)
	return
}

year :: proc(t: Time) -> (year: int) {
	year, _, _, _ = _date(t, true)
	return
}

month :: proc(t: Time) -> (month: Month) {
	_, month, _, _ = _date(t, true)
	return
}

day :: proc(t: Time) -> (day: int) {
	_, _, day, _ = _date(t, true)
	return
}

clock :: proc { clock_from_time, clock_from_duration, clock_from_stopwatch }

clock_from_time :: proc(t: Time) -> (hour, min, sec: int) {
	return clock_from_seconds(_time_abs(t))
}

clock_from_duration :: proc(d: Duration) -> (hour, min, sec: int) {
	return clock_from_seconds(u64(d/1e9))
}

clock_from_stopwatch :: proc(s: Stopwatch) -> (hour, min, sec: int) {
	return clock_from_duration(stopwatch_duration(s))
}

clock_from_seconds :: proc(nsec: u64) -> (hour, min, sec: int) {
	sec = int(nsec % SECONDS_PER_DAY)
	hour = sec / SECONDS_PER_HOUR
	sec -= hour * SECONDS_PER_HOUR
	min = sec / SECONDS_PER_MINUTE
	sec -= min * SECONDS_PER_MINUTE
	return
}

read_cycle_counter :: proc() -> u64 {
	return u64(intrinsics.read_cycle_counter())
}

unix :: proc(sec: i64, nsec: i64) -> Time {
	sec, nsec := sec, nsec
	if nsec < 0 || nsec >= 1e9 {
		n := nsec / 1e9
		sec += n
		nsec -= n * 1e9
		if nsec < 0 {
			nsec += 1e9
			sec -= 1
		}
	}
	return Time{(sec*1e9 + nsec) + UNIX_TO_INTERNAL}
}

time_to_unix :: proc(t: Time) -> i64 {
	return t._nsec/1e9
}

time_to_unix_nano :: proc(t: Time) -> i64 {
	return t._nsec
}

time_add :: proc(t: Time, d: Duration) -> Time {
	return Time{t._nsec + i64(d)}
}

// Accurate sleep borrowed from: https://blat-blatnik.github.io/computerBear/making-accurate-sleep-function/
//
// Accuracy seems to be pretty good out of the box on Linux, to within around 4µs worst case.
// On Windows it depends but is comparable with regular sleep in the worst case.
// To get the same kind of accuracy as on Linux, have your program call `win32.time_begin_period(1)` to
// tell Windows to use a more accurate timer for your process.
accurate_sleep :: proc(d: Duration) {
	to_sleep, estimate, mean, m2, count: Duration

	to_sleep = d
	estimate = 5 * Millisecond
	mean     = 5 * Millisecond
	count = 1

	for to_sleep > estimate {
		start := tick_now()
		sleep(1 * Millisecond)

		observed := tick_since(start)
		to_sleep -= observed

		count += 1

		delta := observed - mean
		mean += delta / count
		m2 += delta * (observed - mean)
		stddev := intrinsics.sqrt(f64(m2) / f64(count - 1))
		estimate = mean + Duration(stddev)
	}

	start := tick_now()
	for to_sleep > tick_since(start) {
		// prevent the spinlock from taking the thread hostage, still accurate enough
		_yield()
		// NOTE: it might be possible that it yields for too long, in that case it should spinlock freely for a while
		// TODO: needs actual testing done to check if that's the case
	}
}

ABSOLUTE_ZERO_YEAR :: i64(-292277022399) // Day is chosen so that 2001-01-01 is Monday in the calculations
ABSOLUTE_TO_INTERNAL :: i64(-9223371966579724800) // i64((ABSOLUTE_ZERO_YEAR - 1) * 365.2425 * SECONDS_PER_DAY);
INTERNAL_TO_ABSOLUTE :: -ABSOLUTE_TO_INTERNAL

UNIX_TO_INTERNAL :: i64((1969*365 + 1969/4 - 1969/100 + 1969/400) * SECONDS_PER_DAY)
INTERNAL_TO_UNIX :: -UNIX_TO_INTERNAL

WALL_TO_INTERNAL :: i64((1884*365 + 1884/4 - 1884/100 + 1884/400) * SECONDS_PER_DAY)
INTERNAL_TO_WALL :: -WALL_TO_INTERNAL

UNIX_TO_ABSOLUTE :: UNIX_TO_INTERNAL + INTERNAL_TO_ABSOLUTE
ABSOLUTE_TO_UNIX :: -UNIX_TO_ABSOLUTE

_is_leap_year :: proc(year: int) -> bool {
	return year%4 == 0 && (year%100 != 0 || year%400 == 0)
}

_date :: proc(t: Time, full: bool) -> (year: int, month: Month, day: int, yday: int) {
	year, month, day, yday = _abs_date(_time_abs(t), full)
	return
}

_time_abs :: proc(t: Time) -> u64 {
	return u64(t._nsec/1e9 + UNIX_TO_ABSOLUTE)
}

_abs_date :: proc(abs: u64, full: bool) -> (year: int, month: Month, day: int, yday: int) {
	d := abs / SECONDS_PER_DAY

	// 400 year cycles
	n := d / DAYS_PER_400_YEARS
	y := 400 * n
	d -= DAYS_PER_400_YEARS * n

	// Cut-off 100 year cycles
	n = d / DAYS_PER_100_YEARS
	n -= n >> 2
	y += 100 * n
	d -= DAYS_PER_100_YEARS * n

	// Cut-off 4 year cycles
	n = d / DAYS_PER_4_YEARS
	y += 4 * n
	d -= DAYS_PER_4_YEARS * n

	n = d / 365
	n -= n >> 2
	y += n
	d -= 365 * n

	year = int(i64(y) + ABSOLUTE_ZERO_YEAR)
	yday = int(d)

	if !full {
		return
	}

	day = yday

	if _is_leap_year(year) {
		switch {
		case day > 31+29-1:
			day -= 1
		case day == 31+29-1:
			month = .February
			day = 29
			return
		}
	}

	month = Month(day / 31)
	end := int(days_before[int(month)+1])
	begin: int
	if day >= end {
		(^int)(&month)^ += 1
		begin = end
	} else {
		begin = int(days_before[month])
	}
	(^int)(&month)^ += 1 // January is 1
	day = day - begin + 1
	return
}

datetime_to_time :: proc(year, month, day, hour, minute, second: int, nsec := int(0)) -> (t: Time, ok: bool) {
	divmod :: proc(year: int, divisor: int) -> (div: int, mod: int) {
		assert(divisor > 0)
		div = int(year / divisor)
		mod = year % divisor
		return
	}

	ok = true

	_y := year  - 1970
	_m := month - 1
	_d := day   - 1

	if month < 1 || month > 12 {
		_m %= 12; ok = false
	}
	if day   < 1 || day   > 31 {
		_d %= 31; ok = false
	}

	s := i64(0)
	div, mod := divmod(_y, 400)
	days := div * DAYS_PER_400_YEARS

	div, mod = divmod(mod, 100)
	days += div * DAYS_PER_100_YEARS

	div, mod = divmod(mod, 4)
	days += (div * DAYS_PER_4_YEARS) + (mod * 365)

	days += int(days_before[_m]) + _d

	s += i64(days)   * SECONDS_PER_DAY
	s += i64(hour)   * SECONDS_PER_HOUR
	s += i64(minute) * SECONDS_PER_MINUTE
	s += i64(second)

	t._nsec = (s * 1e9) + i64(nsec)

	return
}

days_before := [?]i32{
	0,
	31,
	31 + 28,
	31 + 28 + 31,
	31 + 28 + 31 + 30,
	31 + 28 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
	31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + 31,
}


SECONDS_PER_MINUTE :: 60
SECONDS_PER_HOUR   :: 60 * SECONDS_PER_MINUTE
SECONDS_PER_DAY    :: 24 * SECONDS_PER_HOUR
SECONDS_PER_WEEK   ::  7 * SECONDS_PER_DAY
DAYS_PER_400_YEARS :: 365*400 + 97
DAYS_PER_100_YEARS :: 365*100 + 24
DAYS_PER_4_YEARS   :: 365*4   + 1
