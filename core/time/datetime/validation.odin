package datetime
// Validation helpers

/*
Check if a year is a leap year.
*/
is_leap_year :: proc "contextless" (#any_int year: i64) -> (leap: bool) {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

/*
Check for errors in date formation.

This procedure validates all fields of a date, and if any of the fields is
outside of allowed range, an error is returned.
*/
validate_date :: proc "contextless" (date: Date) -> (err: Error) {
	return validate(date.year, date.month, date.day)
}

/*
Check for errors in date formation given date components.

This procedure checks whether a date formed by the specified year month and a
day is a valid date. If not, an error is returned.
*/
validate_year_month_day :: proc "contextless" (#any_int year, #any_int month, #any_int day: i64) -> (err: Error) {
	if year < MIN_DATE.year || year > MAX_DATE.year {
		return .Invalid_Year
	}
	if month < 1 || month > 12 {
		return .Invalid_Month
	}

	month_days := MONTH_DAYS
	days_this_month := month_days[month]
	if month == 2 && is_leap_year(year) {
		days_this_month = 29
	}

	if day < 1 || day > i64(days_this_month) {
		return .Invalid_Day
	}
	return .None
}

/*
Check for errors in Ordinal

This procedure checks if the ordinal is in a valid range for roundtrip
conversions with the dates. If not, an error is returned.
*/
validate_ordinal :: proc "contextless" (ordinal: Ordinal) -> (err: Error) {
	if ordinal < MIN_ORD || ordinal > MAX_ORD {
		return .Invalid_Ordinal
	}
	return
}

/*
Check for errors in time formation

This procedure checks whether time has all fields in valid ranges, and if not
an error is returned.
*/
validate_time :: proc "contextless" (time: Time) -> (err: Error) {
	return validate(time.hour, time.minute, time.second, time.nano)
}

/*
Check for errors in time formed by its components.

This procedure checks whether the time formed by its components is valid, and
if not an error is returned.
*/
validate_hour_minute_second :: proc "contextless" (#any_int hour, #any_int minute, #any_int second, #any_int nano: i64) -> (err: Error) {
	if hour < 0 || hour > 23 {
		return .Invalid_Hour
	}
	if minute < 0 || minute > 59 {
		return .Invalid_Minute
	}
	if second < 0 || second > 59 {
		return .Invalid_Second
	}
	if nano < 0 || nano > 1e9 {
		return .Invalid_Nano
	}
	return .None
}

/*
Check for errors in datetime formation.

This procedure checks whether all fields of date and time in the specified
datetime are valid, and if not, an error is returned.
*/
validate_datetime :: proc "contextless" (datetime: DateTime) -> (err: Error) {
	validate(datetime.date) or_return
	validate(datetime.time) or_return
	return .None
}

/*
Check for errors in date, time or datetime.
*/
validate :: proc{
	validate_date,
	validate_year_month_day,
	validate_ordinal,
	validate_hour_minute_second,
	validate_time,
	validate_datetime,
}
