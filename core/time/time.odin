package time

import    "base:intrinsics"
import dt "core:time/datetime"

/*
Type representing duration, with nanosecond precision.
This is the regular Unix timestamp, scaled to nanosecond precision.
*/
Duration :: distinct i64

/*
The duration equal to one nanosecond (1e-9 seconds).
*/
Nanosecond  :: Duration(1)

/*
The duration equal to one microsecond (1e-6 seconds).
*/
Microsecond :: 1000 * Nanosecond

/*
The duration equal to one millisecond (1e-3 seconds).
*/
Millisecond :: 1000 * Microsecond

/*
The duration equal to one second.
*/
Second      :: 1000 * Millisecond

/*
The duration equal to one minute (60 seconds).
*/
Minute      :: 60 * Second

/*
The duration equal to one hour (3600 seconds).
*/
Hour        :: 60 * Minute

/*
Minimum representable duration.
*/
MIN_DURATION :: Duration(-1 << 63)

/*
Maximum representable duration.
*/
MAX_DURATION :: Duration(1<<63 - 1)

/*
Value specifying whether the time procedures are supported by the current
platform.
*/
IS_SUPPORTED :: _IS_SUPPORTED

/*
Specifies time since the UNIX epoch, with nanosecond precision.

Capable of representing any time within the following range:

- `min: 1677-09-21 00:12:44.145224192 +0000 UTC`
- `max: 2262-04-11 23:47:16.854775807 +0000 UTC`
*/
Time :: struct {
	_nsec: i64, // Measured in UNIX nanonseconds
}

/*
Type representing a month.
*/
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

/*
Type representing a weekday.
*/
Weekday :: enum int {
	Sunday = 0,
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday,
}

/*
Type representing a stopwatch.

The stopwatch is used for measuring the total time in multiple "runs". When the
stopwatch is started, it starts counting time. When the stopwatch is stopped,
the difference in time between the last start and the stop is added to the
total. When the stopwatch resets, the total is reset.
*/
Stopwatch :: struct {
	running: bool,
	_start_time: Tick,
	_accumulation: Duration,
}

/*
Obtain the current time.
*/
now :: proc "contextless" () -> Time {
	return _now()
}

/*
Sleep for the specified duration.
*/
sleep :: proc "contextless" (d: Duration) {
	_sleep(d)
}

/*
Start the stopwatch.
*/
stopwatch_start :: proc "contextless" (stopwatch: ^Stopwatch) {
	if !stopwatch.running {
		stopwatch._start_time = tick_now()
		stopwatch.running = true
	}
}

/*
Stop the stopwatch.
*/
stopwatch_stop :: proc "contextless" (stopwatch: ^Stopwatch) {
	if stopwatch.running {
		stopwatch._accumulation += tick_diff(stopwatch._start_time, tick_now())
		stopwatch.running = false
	}
}

/*
Reset the stopwatch.
*/
stopwatch_reset :: proc "contextless" (stopwatch: ^Stopwatch) {
	stopwatch._accumulation = {}
	stopwatch.running = false
}

/*
Obtain the total time, counted by the stopwatch.

This procedure obtains the total time, counted by the stopwatch. If the stopwatch
isn't stopped at the time of calling this procedure, the time between the last
start and the current time is also accounted for.
*/
stopwatch_duration :: proc "contextless" (stopwatch: Stopwatch) -> Duration {
	if !stopwatch.running {
		return stopwatch._accumulation
	}
	return stopwatch._accumulation + tick_diff(stopwatch._start_time, tick_now())
}

/*
Calculate the duration elapsed between two times.
*/
diff :: proc "contextless" (start, end: Time) -> Duration {
	d := end._nsec - start._nsec
	return Duration(d)
}

/*
Calculate the duration elapsed since a specific time.
*/
since :: proc "contextless" (start: Time) -> Duration {
	return diff(start, now())
}

/*
Obtain the number of nanoseconds in a duration.
*/
duration_nanoseconds :: proc "contextless" (d: Duration) -> i64 {
	return i64(d)
}

/*
Obtain the number of microseconds in a duration.
*/
duration_microseconds :: proc "contextless" (d: Duration) -> f64 {
	return duration_seconds(d) * 1e6
}

/*
Obtain the number of milliseconds in a duration.
*/
duration_milliseconds :: proc "contextless" (d: Duration) -> f64 {
	return duration_seconds(d) * 1e3
}

/*
Obtain the number of seconds in a duration.
*/
duration_seconds :: proc "contextless" (d: Duration) -> f64 {
	sec := d / Second
	nsec := d % Second
	return f64(sec) + f64(nsec)/1e9
}

/*
Obtain the number of minutes in a duration.
*/
duration_minutes :: proc "contextless" (d: Duration) -> f64 {
	min := d / Minute
	nsec := d % Minute
	return f64(min) + f64(nsec)/(60*1e9)
}

/*
Obtain the number of hours in a duration.
*/
duration_hours :: proc "contextless" (d: Duration) -> f64 {
	hour := d / Hour
	nsec := d % Hour
	return f64(hour) + f64(nsec)/(60*60*1e9)
}

/*
Round a duration to a specific unit

This procedure rounds the duration to a specific unit

**Note**: Any duration can be supplied as a unit.

Inputs:
- d: The duration to round
- m: The unit to round to

Returns:
- The duration `d`, rounded to the unit specified by `m`

Example:
	time.duration_round(my_duration, time.Second)
*/
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

/*
Truncate the duration to the specified unit.

This procedure truncates the duration `d` to the unit specified by `m`.

**Note**: Any duration can be supplied as a unit.

Inputs:
- d: The duration to truncate.
- m: The unit to truncate to.

Returns:
- The duration `d`, truncated to the unit specified by `m`.

Example:
	time.duration_round(my_duration, time.Second)
*/
duration_truncate :: proc "contextless" (d, m: Duration) -> Duration {
	return d if m <= 0 else d - d%m
}

/*
Parse time into date components.
*/
date :: proc "contextless" (t: Time) -> (year: int, month: Month, day: int) {
	year, month, day, _ = _abs_date(_time_abs(t), true)
	return
}

/*
Obtain the year of the date specified by time.
*/
year :: proc "contextless" (t: Time) -> (year: int) {
	year, _, _, _ = _date(t, true)
	return
}

/*
Obtain the month of the date specified by time.
*/
month :: proc "contextless" (t: Time) -> (month: Month) {
	_, month, _, _ = _date(t, true)
	return
}

/*
Obtain the day of the date specified by time.
*/
day :: proc "contextless" (t: Time) -> (day: int) {
	_, _, day, _ = _date(t, true)
	return
}

/*
Obtain the week day of the date specified by time.
*/
weekday :: proc "contextless" (t: Time) -> (weekday: Weekday) {
	abs := _time_abs(t)
	sec := (abs + u64(Weekday.Monday) * SECONDS_PER_DAY) % SECONDS_PER_WEEK
	return Weekday(int(sec) / SECONDS_PER_DAY)
}

/*
Obtain the time components from a time, a duration or a stopwatch's total.
*/
clock :: proc { clock_from_time, clock_from_duration, clock_from_stopwatch }

/*
Obtain the time components from a time, a duration or a stopwatch's total, including nanoseconds.
*/
precise_clock :: proc { precise_clock_from_time, precise_clock_from_duration, precise_clock_from_stopwatch }

/*
Obtain the time components from a time.
*/
clock_from_time :: proc "contextless" (t: Time) -> (hour, min, sec: int) {
	hour, min, sec, _ = precise_clock_from_time(t)
	return
}

/*
Obtain the time components from a time, including nanoseconds.
*/
precise_clock_from_time :: proc "contextless" (t: Time) -> (hour, min, sec, nanos: int) {
	// Time in nanoseconds since 1-1-1970 00:00
	_sec, _nanos := t._nsec / 1e9, t._nsec % 1e9
	_sec += INTERNAL_TO_ABSOLUTE
	nanos = int(_nanos)
	sec   = int(_sec  % SECONDS_PER_DAY)
	hour  = sec  / SECONDS_PER_HOUR
	sec  -= hour * SECONDS_PER_HOUR
	min   = sec  / SECONDS_PER_MINUTE
	sec  -= min  * SECONDS_PER_MINUTE
	return
}

/*
Obtain the time components from a duration.
*/
clock_from_duration :: proc "contextless" (d: Duration) -> (hour, min, sec: int) {
	return clock_from_seconds(u64(d/1e9))
}

/*
Obtain the time components from a duration, including nanoseconds.
*/
precise_clock_from_duration :: proc "contextless" (d: Duration) -> (hour, min, sec, nanos: int) {
	return precise_clock_from_time({_nsec=i64(d)})
}

/*
Obtain the time components from a stopwatch's total.
*/
clock_from_stopwatch :: proc "contextless" (s: Stopwatch) -> (hour, min, sec: int) {
	return clock_from_duration(stopwatch_duration(s))
}

/*
Obtain the time components from a stopwatch's total, including nanoseconds
*/
precise_clock_from_stopwatch :: proc "contextless" (s: Stopwatch) -> (hour, min, sec, nanos: int) {
	return precise_clock_from_duration(stopwatch_duration(s))
}

/*
Obtain the time components from the number of seconds.
*/
clock_from_seconds :: proc "contextless" (in_sec: u64) -> (hour, min, sec: int) {
	sec = int(in_sec % SECONDS_PER_DAY)
	hour = sec / SECONDS_PER_HOUR
	sec -= hour * SECONDS_PER_HOUR
	min = sec / SECONDS_PER_MINUTE
	sec -= min * SECONDS_PER_MINUTE
	return
}

MIN_HMS_LEN       :: 8
MIN_HMS_12_LEN    :: 11
MIN_YYYY_DATE_LEN :: 10
MIN_YY_DATE_LEN   :: 8

/*
Formats a `Time` as a 24-hour `hh:mm:ss` string.

**Does not allocate**

Inputs:
- t:   The Time to format.
- buf: The backing buffer to use.

Returns:
- res: The formatted string, backed by buf

Example:
	buf: [MIN_HMS_LEN]u8
	now := time.now()
	fmt.println(time.to_string_hms(now, buf[:]))
*/
time_to_string_hms :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_HMS_LEN)
	h, m, s := clock(t)

	buf[7] = '0' + u8(s % 10); s /= 10
	buf[6] = '0' + u8(s)
	buf[5] = ':'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m)
	buf[2] = ':'
	buf[1] = '0' + u8(h % 10); h /= 10
	buf[0] = '0' + u8(h)

	return string(buf[:MIN_HMS_LEN])
}

/*
Formats a `Duration` as a 24-hour `hh:mm:ss` string.

**Does not allocate**

Inputs:
- d:   The Duration to format.
- buf: The backing buffer to use.

Returns:
- res: The formatted string, backed by buf

Example:
	buf: [MIN_HMS_LEN]u8
	d   := time.since(earlier)
	fmt.println(time.to_string_hms(now, buf[:]))
*/
duration_to_string_hms :: proc(d: Duration, buf: []u8) -> (res: string) #no_bounds_check {
	return time_to_string_hms(Time{_nsec=i64(d)}, buf)
}

to_string_hms :: proc{time_to_string_hms, duration_to_string_hms}

/*
Formats a `Time` as a 12-hour `hh:mm:ss pm` string

**Does not allocate**

Inputs:
- t:    The Time to format
- buf:  The backing buffer to use
- ampm: An optional pair of am/pm strings to use in place of the default

Returns:
- res: The formatted string, backed by buf

Example:
	buf: [64]u8
	now := time.now()
	fmt.println(time.to_string_hms_12(now, buf[:]))
	fmt.println(time.to_string_hms_12(now, buf[:], {"㏂", "㏘"}))
*/
to_string_hms_12 :: proc(t: Time, buf: []u8, ampm: [2]string = {" am", " pm"}) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_HMS_LEN + max(len(ampm[0]), len(ampm[1])))
	h, m, s := clock(t)

	_h := h % 12
	buf[7] = '0' + u8(s % 10); s /= 10
	buf[6] = '0' + u8(s)
	buf[5] = ':'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m)
	buf[2] = ':'
	buf[1] = '0' + u8(_h% 10); _h /= 10
	buf[0] = '0' + u8(_h)

	if h < 13 {
		copy(buf[8:], ampm[0])
		return string(buf[:MIN_HMS_LEN+len(ampm[0])])
	} else {
		copy(buf[8:], ampm[1])
		return string(buf[:MIN_HMS_LEN+len(ampm[1])])
	}
}

/*
Formats a Time as a yyyy-mm-dd date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YYYY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_yyyy_mm_dd(now, buf[:]))
*/
to_string_yyyy_mm_dd :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YYYY_DATE_LEN)
	y, _m, d := date(t)
	m := u8(_m)

	buf[9] = '0' + u8(d % 10); d /= 10
	buf[8] = '0' + u8(d % 10)
	buf[7] = '-'
	buf[6] = '0' + u8(m % 10); m /= 10
	buf[5] = '0' + u8(m % 10)
	buf[4] = '-'
	buf[3] = '0' + u8(y % 10); y /= 10
	buf[2] = '0' + u8(y % 10); y /= 10
	buf[1] = '0' + u8(y % 10); y /= 10
	buf[0] = '0' + u8(y)

	return string(buf[:MIN_YYYY_DATE_LEN])
}

/*
Formats a Time as a yy-mm-dd date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_yy_mm_dd(now, buf[:]))
*/
to_string_yy_mm_dd :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YY_DATE_LEN)
	y, _m, d := date(t)
	y %= 100; m := u8(_m)

	buf[7] = '0' + u8(d % 10); d /= 10
	buf[6] = '0' + u8(d % 10)
	buf[5] = '-'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m % 10)
	buf[2] = '-'
	buf[1] = '0' + u8(y % 10); y /= 10
	buf[0] = '0' + u8(y)

	return string(buf[:MIN_YY_DATE_LEN])
}

/*
Formats a Time as a dd-mm-yyyy date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YYYY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_dd_mm_yyyy(now, buf[:]))
*/
to_string_dd_mm_yyyy :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YYYY_DATE_LEN)
	y, _m, d := date(t)
	m := u8(_m)

	buf[9] = '0' + u8(y % 10); y /= 10
	buf[8] = '0' + u8(y % 10); y /= 10
	buf[7] = '0' + u8(y % 10); y /= 10
	buf[6] = '0' + u8(y)
	buf[5] = '-'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m % 10)
	buf[2] = '-'
	buf[1] = '0' + u8(d % 10); d /= 10
	buf[0] = '0' + u8(d % 10)

	return string(buf[:MIN_YYYY_DATE_LEN])
}

/*
Formats a Time as a dd-mm-yy date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_dd_mm_yy(now, buf[:]))
*/
to_string_dd_mm_yy :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YY_DATE_LEN)
	y, _m, d := date(t)
	y %= 100; m := u8(_m)

	buf[7] = '0' + u8(y % 10); y /= 10
	buf[6] = '0' + u8(y)
	buf[5] = '-'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m % 10)
	buf[2] = '-'
	buf[1] = '0' + u8(d % 10); d /= 10
	buf[0] = '0' + u8(d % 10)

	return string(buf[:MIN_YY_DATE_LEN])
}

/*
Formats a Time as a mm-dd-yyyy date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YYYY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_mm_dd_yyyy(now, buf[:]))
*/
to_string_mm_dd_yyyy :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YYYY_DATE_LEN)
	y, _m, d := date(t)
	m := u8(_m)

	buf[9] = '0' + u8(y % 10); y /= 10
	buf[8] = '0' + u8(y % 10); y /= 10
	buf[7] = '0' + u8(y % 10); y /= 10
	buf[6] = '0' + u8(y)
	buf[5] = '-'
	buf[4] = '0' + u8(d % 10); d /= 10
	buf[3] = '0' + u8(d % 10)
	buf[2] = '-'
	buf[1] = '0' + u8(m % 10); m /= 10
	buf[0] = '0' + u8(m % 10)

	return string(buf[:MIN_YYYY_DATE_LEN])
}

/*
Formats a Time as a mm-dd-yy date string.

Inputs:
- t:    The Time to format.
- buf:  The backing buffer to use.

Returns:
- res: The formatted string, backed by `buf`.

Example:
	buf: [MIN_YY_DATE_LEN]u8
	now := time.now()
	fmt.println(time.to_string_mm_dd_yy(now, buf[:]))
*/
to_string_mm_dd_yy :: proc(t: Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= MIN_YY_DATE_LEN)
	y, _m, d := date(t)
	y %= 100; m := u8(_m)

	buf[7] = '0' + u8(y % 10); y /= 10
	buf[6] = '0' + u8(y)
	buf[5] = '-'
	buf[4] = '0' + u8(d % 10); d /= 10
	buf[3] = '0' + u8(d % 10)
	buf[2] = '-'
	buf[1] = '0' + u8(m % 10); m /= 10
	buf[0] = '0' + u8(m % 10)

	return string(buf[:MIN_YY_DATE_LEN])
}

/*
Read the timestamp counter of the CPU.
*/
read_cycle_counter :: proc "contextless" () -> u64 {
	return u64(intrinsics.read_cycle_counter())
}

/*
Obtain time from unix seconds and unix nanoseconds.
*/
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

/*
Obtain time from unix nanoseconds.
*/
from_nanoseconds :: #force_inline proc "contextless" (nsec: i64) -> Time {
	return Time{nsec}
}

/*
Alias for `time_to_unix`.
*/
to_unix_seconds :: time_to_unix

/*
Obtain the Unix timestamp in seconds from a Time.
*/
time_to_unix :: proc "contextless" (t: Time) -> i64 {
	return t._nsec/1e9
}

/*
Alias for `time_to_unix_nano`.
*/
to_unix_nanoseconds :: time_to_unix_nano

/*
Obtain the Unix timestamp in nanoseconds from a Time.
*/
time_to_unix_nano :: proc "contextless" (t: Time) -> i64 {
	return t._nsec
}

/*
Add duration to a time.
*/
time_add :: proc "contextless" (t: Time, d: Duration) -> Time {
	return Time{t._nsec + i64(d)}
}

/*
Accurate sleep

This procedure sleeps for the duration specified by `d`, very accurately.

**Note**: Implementation borrowed from: [this source](https://blat-blatnik.github.io/computerBear/making-accurate-sleep-function/)

**Note(linux)**: The accuracy is within around 4µs (microseconds), in the worst case.

**Note(windows)**: The accuracy depends but is comparable with regular sleep in
the worst case. To get the same kind of accuracy as on Linux, have your program
call `windows.timeBeginPeriod(1)` to tell Windows to use a more accurate timer
for your process. Additionally your program should call `windows.timeEndPeriod(1)`
once you're done with `accurate_sleep`. 
*/
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

/*
Convert datetime components into time.

This procedure calculates the time from datetime components supplied in the
arguments to this procedure. If the datetime components don't represent a valid
datetime, the function returns `false` in the second argument.
*/
components_to_time :: proc "contextless" (#any_int year, #any_int month, #any_int day, #any_int hour, #any_int minute, #any_int second: i64, #any_int nsec := i64(0)) -> (t: Time, ok: bool) {
	this_date, err := dt.components_to_datetime(year, month, day, hour, minute, second, nsec)
	if err != .None {
		return
	}
	return compound_to_time(this_date)
}

/*
Convert datetime into time.

If the datetime represents a time outside of a valid range, `false` is returned
as the second return value. See `Time` for the representable range.
*/
compound_to_time :: proc "contextless" (datetime: dt.DateTime) -> (t: Time, ok: bool) {
	unix_epoch := dt.DateTime{{1970, 1, 1}, {0, 0, 0, 0}, nil}
	delta, err := dt.sub(datetime, unix_epoch)
	if err != .None {
		return
	}

	seconds := delta.days * 86_400 + delta.seconds
	// Can this moment be represented in i64 worth of nanoseconds?
	// min(Time): 1677-09-21 00:12:44.145224192 +0000 UTC
	// max(Time): 2262-04-11 23:47:16.854775807 +0000 UTC
	if seconds < -9223372036 || (seconds == -9223372036 && delta.nanos < -854775808) {
		return {}, false
	}
	if seconds > 9223372036 || (seconds == 9223372036 && delta.nanos > 854775807) {
		return {}, false
	}
	return Time{_nsec=seconds * 1e9 + delta.nanos}, true
}

/*
Convert datetime components into time.
*/
datetime_to_time :: proc{components_to_time, compound_to_time}

/*
Convert time into datetime.
*/
time_to_datetime :: proc "contextless" (t: Time) -> (dt.DateTime, bool) {
	unix_epoch := dt.DateTime{{1970, 1, 1}, {0, 0, 0, 0}, nil}

	datetime, err := dt.add(unix_epoch, dt.Delta{ nanos = t._nsec })
	if err != .None {
		return {}, false
	}
	return datetime, true
}

/*
Alias for `time_to_datetime`.
*/
time_to_compound :: time_to_datetime

/*
Check if a year is a leap year.
*/
is_leap_year :: proc "contextless" (year: int) -> (leap: bool) {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

/*
Days before each month in a year, not counting the leap day on february 29th.
*/
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

/*
Number of seconds in a minute (without leap seconds).
*/
SECONDS_PER_MINUTE :: 60

/*
Number of seconds in an hour (without leap seconds).
*/
SECONDS_PER_HOUR   :: 60 * SECONDS_PER_MINUTE

/*
Number of seconds in a day (without leap seconds).
*/
SECONDS_PER_DAY    :: 24 * SECONDS_PER_HOUR

/*
Number of seconds in a week (without leap seconds).
*/
SECONDS_PER_WEEK   ::  7 * SECONDS_PER_DAY

/*
Days in 400 years, with leap days.
*/
DAYS_PER_400_YEARS :: 365*400 + 97

/*
Days in 100 years, with leap days.
*/
DAYS_PER_100_YEARS :: 365*100 + 24

/*
Days in 4 years, with leap days.
*/
DAYS_PER_4_YEARS   :: 365*4   + 1
