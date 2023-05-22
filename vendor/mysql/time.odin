package mysql

import "core:c"
import "core:time"

Timestamp_Type :: enum c.int {
	None         = -2,
	Error        = -1,
	// Stores year, month and day.
	Date         = 0,
	// Stores all components, UTC for TIMESTAMP and local for DATETIME.
	Date_Time    = 1,
	// Stores hours, minute, second and microsecond.
	Time         = 2,
	// Temporary type for DATETIME or TIMESTAMP with timezone info. Converted to Date_Time after timezone info is reconciled.
	Date_Time_Tz = 3,
}

// The actual database column types.
Time_Type :: enum {
	Time,
	Date,
	Date_Time,
	Timestamp,
}

Time :: struct {
	year:                   c.uint,
	month:                  c.uint,
	day:                    c.uint,
	hour:                   c.uint,
	minute:                 c.uint,
	second:                 c.uint,
	microsecond:            c.ulong,
	neg:                    c.bool,
	time_type:              Timestamp_Type,
	time_zone_displacement: c.int, // In seconds.
}

@(private)
MICROSECONDS_PER_SECOND :: 1e+6

@(private)
time_parts :: proc(t: time.Time) -> (c.uint, c.uint, c.uint, c.ulong) {
	t := time.now()
	nsec := time.to_unix_nanoseconds(t)
	micro := c.ulong(((nsec / 1000) % MICROSECONDS_PER_SECOND))
	hour, min, sec := time.clock_from_time(t)
	return c.uint(hour), c.uint(min), c.uint(sec), micro
}

@(private)
date_parts :: proc(t: time.Time) -> (year, month, day: c.uint) {
	ayear, amonth, aday := time.date(t)
	return c.uint(ayear), c.uint(amonth), c.uint(aday)
}

time_from_time :: proc(result: ^Time, t: time.Time, type: Time_Type) {
	switch type {
	case .Date:
		result.time_type = .Date
		result.year, result.month, result.day = date_parts(t)
		return
	case .Time:
		result.time_type = .Time
		result.hour, result.minute, result.second, result.microsecond = time_parts(t)
		return
	// TODO: odin doesn't really support timezones, I think it is always UTC.
	case .Date_Time, .Timestamp:
		result.time_type = .Date_Time
		result.year, result.month, result.day = date_parts(t)
		result.hour, result.minute, result.second, result.microsecond = time_parts(t)
		return
	case:
		panic("unreachable")
	}
}
