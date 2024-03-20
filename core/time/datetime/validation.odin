package datetime

// Validation helpers
is_leap_year :: proc "contextless" (#any_int year: i64) -> (leap: bool) {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

validate_date :: proc "contextless" (date: Date) -> (err: Error) {
	return validate(date.year, date.month, date.day)
}

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

validate_ordinal :: proc "contextless" (ordinal: Ordinal) -> (err: Error) {
	if ordinal < MIN_ORD || ordinal > MAX_ORD {
		return .Invalid_Ordinal
	}
	return
}

validate_time :: proc "contextless" (time: Time) -> (err: Error) {
	return validate(time.hour, time.minute, time.second, time.nano)
}

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

validate_datetime :: proc "contextless" (using datetime: DateTime) -> (err: Error) {
	validate(date) or_return
	validate(time) or_return
	return .None
}

validate :: proc{
	validate_date,
	validate_year_month_day,
	validate_ordinal,
	validate_hour_minute_second,
	validate_time,
	validate_datetime,
}