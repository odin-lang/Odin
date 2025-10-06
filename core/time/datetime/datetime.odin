/*
Calendrical conversions using a proleptic Gregorian calendar.

Implemented using formulas from: Calendrical Calculations Ultimate Edition,
Reingold & Dershowitz
*/
package datetime

import "base:intrinsics"

/*
Obtain an ordinal from a date.

This procedure converts the specified date into an ordinal. If the specified
date is not a valid date, an error is returned.
*/
date_to_ordinal :: proc "contextless" (date: Date) -> (ordinal: Ordinal, err: Error) {
	validate(date) or_return
	return unsafe_date_to_ordinal(date), .None
}

/*
Obtain an ordinal from date components.

This procedure converts the specified date, provided by its individual
components, into an ordinal. If the specified date is not a valid date, an error
is returned.
*/
components_to_ordinal :: proc "contextless" (#any_int year, #any_int month, #any_int day: i64) -> (ordinal: Ordinal, err: Error) {
	validate(year, month, day) or_return
	return unsafe_date_to_ordinal({year, i8(month), i8(day)}), .None
}

/*
Obtain date using an Ordinal.

This provedure converts the specified ordinal into a date. If the ordinal is not
a valid ordinal, an error is returned.
*/
ordinal_to_date :: proc "contextless" (ordinal: Ordinal) -> (date: Date, err: Error) {
	validate(ordinal) or_return
	return unsafe_ordinal_to_date(ordinal), .None
}

/*
Obtain a date from date components.

This procedure converts date components, specified by a year, a month and a day,
into a date object. If the provided date components don't represent a valid
date, an error is returned.
*/
components_to_date :: proc "contextless" (#any_int year, #any_int month, #any_int day: i64) -> (date: Date, err: Error) {
	validate(year, month, day) or_return
	return Date{i64(year), i8(month), i8(day)}, .None
}

/*
Obtain time from time components.

This procedure converts time components, specified by an hour, a minute, a second
and nanoseconds, into a time object. If the provided time components don't
represent a valid time, an error is returned.
*/
components_to_time :: proc "contextless" (#any_int hour, #any_int minute, #any_int second: i64, #any_int nanos := i64(0)) -> (time: Time, err: Error) {
	validate(hour, minute, second, nanos) or_return
	return Time{i8(hour), i8(minute), i8(second), i32(nanos)}, .None
}

/*
Obtain datetime from components.

This procedure converts date components and time components into a datetime object.
If the provided date components or time components don't represent a valid
datetime, an error is returned.
*/
components_to_datetime :: proc "contextless" (#any_int year, #any_int month, #any_int day, #any_int hour, #any_int minute, #any_int second: i64, #any_int nanos := i64(0)) -> (datetime: DateTime, err: Error) {
	date := components_to_date(year, month, day)            or_return
	time := components_to_time(hour, minute, second, nanos) or_return
	return {date, time, nil}, .None
}

/*
Obtain an datetime from an ordinal.

This procedure converts the value of an ordinal into a datetime. Since the
ordinal only has the amount of days, the resulting time in the datetime
object will always have the time equal to `00:00:00.000`.
*/
ordinal_to_datetime :: proc "contextless" (ordinal: Ordinal) -> (datetime: DateTime, err: Error) {
	d := ordinal_to_date(ordinal) or_return
	return {Date(d), {}, nil}, .None
}

/*
Calculate the weekday from an ordinal.

This procedure takes the value of an ordinal and returns the day of week for
that ordinal.
*/
day_of_week :: proc "contextless" (ordinal: Ordinal) -> (day: Weekday) {
	return Weekday(ordinal %% 7)
}

/*
Calculate the difference between two dates.

This procedure calculates the difference between two dates `a - b`, and returns
a delta between the two dates in `days`. If either `a` or `b` is not a valid
date, an error is returned.
*/
subtract_dates :: proc "contextless" (a, b: Date) -> (delta: Delta, err: Error) {
	ord_a := date_to_ordinal(a) or_return
	ord_b := date_to_ordinal(b) or_return

	delta  = Delta{days=ord_a - ord_b}
	return
}

/*
Calculate the difference between two datetimes.

This procedure calculates the difference between two datetimes, `a - b`, and
returns a delta between the two dates. The difference is returned in all three
fields of the `Delta` struct: the difference in days, the difference in seconds
and the difference in nanoseconds.

If either `a` or `b` is not a valid datetime, an error is returned.
*/
subtract_datetimes :: proc "contextless" (a, b: DateTime) -> (delta: Delta, err: Error) {
	ord_a := date_to_ordinal(a) or_return
	ord_b := date_to_ordinal(b) or_return

	validate(a.time) or_return
	validate(b.time) or_return

	seconds_a := i64(a.hour) * 3600 + i64(a.minute) * 60 + i64(a.second)
	seconds_b := i64(b.hour) * 3600 + i64(b.minute) * 60 + i64(b.second)

	delta = Delta{ord_a - ord_b, seconds_a - seconds_b, i64(a.nano) - i64(b.nano)}
	return
}

/*
Calculate a difference between two deltas.
*/
subtract_deltas :: proc "contextless" (a, b: Delta) -> (delta: Delta, err: Error) {
	delta = Delta{a.days - b.days, a.seconds - b.seconds, a.nanos - b.nanos}
	delta = normalize_delta(delta) or_return
	return
}

/*
Calculate a difference between two datetimes, dates or deltas.
*/
sub :: proc{subtract_datetimes, subtract_dates, subtract_deltas}

/*
Add certain amount of days to a date.

This procedure adds the specified amount of days to a date and returns a new
date. The new date would have happened the specified amount of days after the
specified date.
*/
add_days_to_date :: proc "contextless" (a: Date, days: i64) -> (date: Date, err: Error) {
	ord := date_to_ordinal(a) or_return
	ord += days
	return ordinal_to_date(ord)
}

/*
Add delta to a date.

This procedure adds a delta to a date, and returns a new date. The new date
would have happened the time specified by `delta` after the specified date.

**Note**: The delta is assumed to be normalized. That is, if it contains seconds
or milliseconds, regardless of the amount only the days will be added.
*/
add_delta_to_date :: proc "contextless" (a: Date, delta: Delta) -> (date: Date, err: Error) {
	ord := date_to_ordinal(a) or_return
	// Because the input is a Date, we add only the days from the Delta.
	ord += delta.days
	return ordinal_to_date(ord)
}

/*
Add delta to datetime.

This procedure adds a delta to a datetime, and returns a new datetime. The new
datetime would have happened the time specified by `delta` after the specified
datetime. 
*/
add_delta_to_datetime :: proc "contextless" (a: DateTime, delta: Delta) -> (datetime: DateTime, err: Error) {
	days   := date_to_ordinal(a) or_return

	a_seconds := i64(a.hour) * 3600 + i64(a.minute) * 60 + i64(a.second)
	a_delta   := Delta{days=days, seconds=a_seconds, nanos=i64(a.nano)}

	sum_delta := Delta{days=a_delta.days + delta.days, seconds=a_delta.seconds + delta.seconds, nanos=a_delta.nanos + delta.nanos}
	sum_delta  = normalize_delta(sum_delta) or_return

	datetime.date = ordinal_to_date(sum_delta.days) or_return

	hour,   rem    := divmod(sum_delta.seconds, 3600)
	minute, second := divmod(rem, 60)

	datetime.time = components_to_time(hour, minute, second, sum_delta.nanos) or_return
	return
}

/*
Add days to a date, delta to a date or delta to datetime.
*/
add :: proc{add_days_to_date, add_delta_to_date, add_delta_to_datetime}

/*
Obtain the day number in a year

This procedure returns the number of the day in a year, starting from 1. If
the date is not a valid date, an error is returned.
*/
day_number :: proc "contextless" (date: Date) -> (day_number: i64, err: Error) {
	validate(date) or_return

	ord := unsafe_date_to_ordinal(date)
	_, day_number = unsafe_ordinal_to_year(ord)
	return
}

/*
Obtain the remaining number of days in a year.

This procedure returns the number of days between the specified date and
December 31 of the same year. If the date is not a valid date, an error is
returned.
*/
days_remaining :: proc "contextless" (date: Date) -> (days_remaining: i64, err: Error) {
	// Alternative formulation `day_number` subtracted from 365 or 366 depending on leap year
	validate(date) or_return
	delta := sub(date, Date{date.year, 12, 31}) or_return
	return delta.days, .None
}

/*
Obtain the last day of a given month on a given year.

This procedure returns the amount of days in a specified month on a specified
date. If the specified year or month is not valid, an error is returned.
*/
last_day_of_month :: proc "contextless" (#any_int year: i64, #any_int month: i8) -> (day: i8, err: Error) {
	// Not using formula 2.27 from the book. This is far simpler and gives the same answer.

	validate(Date{year, month, 1}) or_return
	month_days := MONTH_DAYS

	day = month_days[month]
	if month == 2 && is_leap_year(year) {
		day += 1
	}
	return
}

/*
Obtain the new year date of a given year.

This procedure returns the January 1st date of the specified year. If the year
is not valid, an error is returned.
*/
new_year :: proc "contextless" (#any_int year: i64) -> (new_year: Date, err: Error) {
	validate(year, 1, 1) or_return
	return {year, 1, 1}, .None
}

/*
Obtain the end year of a given date.

This procedure returns the December 31st date of the specified year. If the year
is not valid, an error is returned.
*/
year_end :: proc "contextless" (#any_int year: i64) -> (year_end: Date, err: Error) {
	validate(year, 12, 31) or_return
	return {year, 12, 31}, .None
}

/*
Obtain the range of dates for a given year.

This procedure returns dates, for every day of a given year in a slice.
*/
year_range :: proc (#any_int year: i64, allocator := context.allocator) -> (range: []Date) {
	is_leap := is_leap_year(year)

	days := 366 if is_leap else 365
	range = make([]Date, days, allocator)

	month_days := MONTH_DAYS
	if is_leap {
		month_days[2] = 29
	}

	i := 0
	for month in 1..=len(month_days) {
		for day in 1..=month_days[month] {
			range[i], _ = components_to_date(year, month, day)
			i += 1
		}
	}
	return
}

/*
Normalize the delta.

This procedure normalizes the delta in such a way that the number of seconds
is between 0 and the number of seconds in the day and nanoseconds is between
0 and 10^9.

If the value for `days` overflows during this operation, an error is returned.
*/
normalize_delta :: proc "contextless" (delta: Delta) -> (normalized: Delta, err: Error) {
	// Distribute nanos into seconds and remainder
	seconds, nanos := divmod(delta.nanos, 1e9)

	// Add original seconds to rolled over seconds.
	seconds += delta.seconds
	days: i64

	// Distribute seconds into number of days and remaining seconds.
	days, seconds = divmod(seconds, 24 * 3600)

	// Add original days
	days += delta.days

	if days <= MIN_ORD || days >= MAX_ORD {
		return {}, .Invalid_Delta
	}
	return Delta{days, seconds, nanos}, .None
}

// The following procedures don't check whether their inputs are in a valid range.
// They're still exported for those who know their inputs have been validated.

/*
Obtain an ordinal from a date.

This procedure converts a date into an ordinal. If the date is not a valid date,
the result is unspecified.
*/
unsafe_date_to_ordinal :: proc "contextless" (date: Date) -> (ordinal: Ordinal) {
	year_minus_one := date.year - 1

	ordinal = 0

	// Add non-leap days
	ordinal += 365 * year_minus_one

	// Add leap days
	ordinal += floor_div(year_minus_one, 4)          // Julian-rule leap days
	ordinal -= floor_div(year_minus_one, 100)        // Prior century years
	ordinal += floor_div(year_minus_one, 400)        // Prior 400-multiple years
	ordinal += floor_div(367 * i64(date.month) - 362, 12) // Prior days this year

	// Apply correction
	if date.month <= 2 {
		ordinal += 0
	} else if is_leap_year(date.year) {
		ordinal -= 1
	} else {
		ordinal -= 2
	}

	// Add days
	ordinal += i64(date.day)
	return
}

/*
Obtain a year and a day of the year from an ordinal.

This procedure returns the year and the day of the year of a given ordinal.
Of the ordinal is outside of its valid range, the result is unspecified.
*/
unsafe_ordinal_to_year :: proc "contextless" (ordinal: Ordinal) -> (year: i64, day_ordinal: i64) {
	// Correct for leap year cycle starting at day 1.
	d0   := ordinal - 1

	// Number of 400-year cycles and remainder
	n400, d1 := divmod(d0, 365*400 + 100 - 3)

	// Number of 100-year cycles and remainder
	n100, d2 := divmod(d1, 365*100 + 25 - 1)

	// Number of 4-year cycles and remainder
	n4,   d3 := divmod(d2, 365*4 + 1)

	// Number of remaining days
	n1,   d4 := divmod(d3, 365)

	year  = 400 * n400 + 100 * n100 + 4 * n4 + n1

	if n1 != 4 && n100 != 4 {
		day_ordinal = d4 + 1
	} else {
		day_ordinal = 366
	}

	if n100 == 4 || n1 == 4 {
		return year, day_ordinal
	}
	return year + 1, day_ordinal
}

/*
Obtain a date from an ordinal.

This procedure converts an ordinal into a date. If the ordinal is outside of
its valid range, the result is unspecified.
*/
unsafe_ordinal_to_date :: proc "contextless" (ordinal: Ordinal) -> (date: Date) {
	year, _ := unsafe_ordinal_to_year(ordinal)

	prior_days := ordinal - unsafe_date_to_ordinal(Date{year, 1, 1})
	correction := Ordinal(2)

	if ordinal < unsafe_date_to_ordinal(Date{year, 3, 1}) {
		correction = 0
	} else if is_leap_year(year) {
		correction = 1
	}

	month := i8(floor_div((12 * (prior_days + correction) + 373), 367))
	day   := i8(ordinal - unsafe_date_to_ordinal(Date{year, month, 1}) + 1)

	return {year, month, day}
}
