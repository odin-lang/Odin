package time

import    "base:intrinsics"
import dt "core:time/datetime"

Duration :: distinct i64

Nanosecond  :: Duration(1)
Microsecond :: 1000 * Nanosecond
Millisecond :: 1000 * Microsecond
Second      :: 1000 * Millisecond
Minute      :: 60 * Second
Hour        :: 60 * Minute

MIN_DURATION :: Duration(-1 << 63)
MAX_DURATION :: Duration(1<<63 - 1)

IS_SUPPORTED :: _IS_SUPPORTED

Time :: struct {
	_nsec: i64, // Measured in UNIX nanonseconds
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

now :: proc "contextless" () -> Time {
	return _now()
}

sleep :: proc "contextless" (d: Duration) {
	_sleep(d)
}

stopwatch_start :: proc "contextless" (stopwatch: ^Stopwatch) {
	if !stopwatch.running {
		stopwatch._start_time = tick_now()
		stopwatch.running = true
	}
}

stopwatch_stop :: proc "contextless" (stopwatch: ^Stopwatch) {
	if stopwatch.running {
		stopwatch._accumulation += tick_diff(stopwatch._start_time, tick_now())
		stopwatch.running = false
	}
}

stopwatch_reset :: proc "contextless" (stopwatch: ^Stopwatch) {
	stopwatch._accumulation = {}
	stopwatch.running = false
}

stopwatch_duration :: proc "contextless" (stopwatch: Stopwatch) -> Duration {
	if !stopwatch.running {
		return stopwatch._accumulation
	}
	return stopwatch._accumulation + tick_diff(stopwatch._start_time, tick_now())
}

diff :: proc "contextless" (start, end: Time) -> Duration {
	d := end._nsec - start._nsec
	return Duration(d)
}

since :: proc "contextless" (start: Time) -> Duration {
	return diff(start, now())
}

duration_nanoseconds :: proc "contextless" (d: Duration) -> i64 {
	return i64(d)
}
duration_microseconds :: proc "contextless" (d: Duration) -> f64 {
	return duration_seconds(d) * 1e6
}
duration_milliseconds :: proc "contextless" (d: Duration) -> f64 {
	return duration_seconds(d) * 1e3
}
duration_seconds :: proc "contextless" (d: Duration) -> f64 {
	sec := d / Second
	nsec := d % Second
	return f64(sec) + f64(nsec)/1e9
}
duration_minutes :: proc "contextless" (d: Duration) -> f64 {
	min := d / Minute
	nsec := d % Minute
	return f64(min) + f64(nsec)/(60*1e9)
}
duration_hours :: proc "contextless" (d: Duration) -> f64 {
	hour := d / Hour
	nsec := d % Hour
	return f64(hour) + f64(nsec)/(60*60*1e9)
}

duration_round :: proc "contextless" (d, m: Duration) -> Duration {
	_less_than_half :: #force_inline proc "contextless" (x, y: Duration) -> bool {
		return u64(x)+u64(x) < u64(y)
	}

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

duration_truncate :: proc "contextless" (d, m: Duration) -> Duration {
	return d if m <= 0 else d - d%m
}

date :: proc "contextless" (t: Time) -> (year: int, month: Month, day: int) {
	year, month, day, _ = _abs_date(_time_abs(t), true)
	return
}

year :: proc "contextless" (t: Time) -> (year: int) {
	year, _, _, _ = _date(t, true)
	return
}

month :: proc "contextless" (t: Time) -> (month: Month) {
	_, month, _, _ = _date(t, true)
	return
}

day :: proc "contextless" (t: Time) -> (day: int) {
	_, _, day, _ = _date(t, true)
	return
}

weekday :: proc "contextless" (t: Time) -> (weekday: Weekday) {
	abs := _time_abs(t)
	sec := (abs + u64(Weekday.Monday) * SECONDS_PER_DAY) % SECONDS_PER_WEEK
	return Weekday(int(sec) / SECONDS_PER_DAY)
}

clock :: proc { clock_from_time, clock_from_duration, clock_from_stopwatch }

clock_from_time :: proc "contextless" (t: Time) -> (hour, min, sec: int) {
	return clock_from_seconds(_time_abs(t))
}

clock_from_duration :: proc "contextless" (d: Duration) -> (hour, min, sec: int) {
	return clock_from_seconds(u64(d/1e9))
}

clock_from_stopwatch :: proc "contextless" (s: Stopwatch) -> (hour, min, sec: int) {
	return clock_from_duration(stopwatch_duration(s))
}

clock_from_seconds :: proc "contextless" (nsec: u64) -> (hour, min, sec: int) {
	sec = int(nsec % SECONDS_PER_DAY)
	hour = sec / SECONDS_PER_HOUR
	sec -= hour * SECONDS_PER_HOUR
	min = sec / SECONDS_PER_MINUTE
	sec -= min * SECONDS_PER_MINUTE
	return
}

read_cycle_counter :: proc "contextless" () -> u64 {
	return u64(intrinsics.read_cycle_counter())
}

unix :: proc "contextless" (sec: i64, nsec: i64) -> Time {
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
	return Time{(sec*1e9 + nsec)}
}

to_unix_seconds :: time_to_unix
time_to_unix :: proc "contextless" (t: Time) -> i64 {
	return t._nsec/1e9
}

to_unix_nanoseconds :: time_to_unix_nano
time_to_unix_nano :: proc "contextless" (t: Time) -> i64 {
	return t._nsec
}

time_add :: proc "contextless" (t: Time, d: Duration) -> Time {
	return Time{t._nsec + i64(d)}
}

// Accurate sleep borrowed from: https://blat-blatnik.github.io/computerBear/making-accurate-sleep-function/
//
// Accuracy seems to be pretty good out of the box on Linux, to within around 4µs worst case.
// On Windows it depends but is comparable with regular sleep in the worst case.
// To get the same kind of accuracy as on Linux, have your program call `windows.timeBeginPeriod(1)` to
// tell Windows to use a more accurate timer for your process.
// Additionally your program should call `windows.timeEndPeriod(1)` once you're done with `accurate_sleep`. 
accurate_sleep :: proc "contextless" (d: Duration) {
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


@(private)
_date :: proc "contextless" (t: Time, full: bool) -> (year: int, month: Month, day: int, yday: int) {
	year, month, day, yday = _abs_date(_time_abs(t), full)
	return
}

@(private)
_time_abs :: proc "contextless" (t: Time) -> u64 {
	return u64(t._nsec/1e9 + UNIX_TO_ABSOLUTE)
}

@(private)
_abs_date :: proc "contextless" (abs: u64, full: bool) -> (year: int, month: Month, day: int, yday: int) {
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

	if is_leap_year(year) {
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

components_to_time :: proc "contextless" (#any_int year, #any_int month, #any_int day, #any_int hour, #any_int minute, #any_int second: i64, #any_int nsec := i64(0)) -> (t: Time, ok: bool) {
	this_date, err := dt.components_to_datetime(year, month, day, hour, minute, second, nsec)
	if err != .None {
		return
	}
	return compound_to_time(this_date)
}

compound_to_time :: proc "contextless" (datetime: dt.DateTime) -> (t: Time, ok: bool) {
	unix_epoch := dt.DateTime{{1970, 1, 1}, {0, 0, 0, 0}}
	delta, err := dt.sub(datetime, unix_epoch)
	ok = err == .None

	seconds     := delta.days    * 86_400 + delta.seconds
	nanoseconds := i128(seconds) * 1e9    + i128(delta.nanos)

	// Can this moment be represented in i64 worth of nanoseconds?
	// min(Time): 1677-09-21 00:12:44.145224192 +0000 UTC
	// max(Time): 2262-04-11 23:47:16.854775807 +0000 UTC
	if nanoseconds < i128(min(i64)) || nanoseconds > i128(max(i64)) {
		return {}, false
	}
	return Time{_nsec=i64(nanoseconds)}, true
}

datetime_to_time :: proc{components_to_time, compound_to_time}

is_leap_year :: proc "contextless" (year: int) -> (leap: bool) {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

@(rodata)
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
