package time
// Parsing RFC 3339 date/time strings into time.Time.
// See https://www.rfc-editor.org/rfc/rfc3339 for the definition

import dt "core:time/datetime"

// Parses an RFC 3339 string and returns Time in UTC, with any UTC offset applied to it.
// Only 4-digit years are accepted.
// Optional pointer to boolean `is_leap` will return `true` if the moment was a leap second.
// Leap seconds are smeared into 23:59:59.
rfc3339_to_time_utc :: proc(rfc_datetime: string, is_leap: ^bool = nil) -> (res: Time, consumed: int) {
	offset: int

	res, offset, consumed = rfc3339_to_time_and_offset(rfc_datetime, is_leap)
	res._nsec += (i64(-offset) * i64(Minute))
	return res, consumed
}

// Parses an RFC 3339 string and returns Time and a UTC offset in minutes.
// e.g. 1985-04-12T23:20:50.52Z
// Note: Only 4-digit years are accepted.
// Optional pointer to boolean `is_leap` will return `true` if the moment was a leap second.
// Leap seconds are smeared into 23:59:59.
rfc3339_to_time_and_offset :: proc(rfc_datetime: string, is_leap: ^bool = nil) -> (res: Time, utc_offset: int, consumed: int) {
	moment, offset, leap_second, count := rfc3339_to_components(rfc_datetime)
	if count == 0 {
		return
	}

	if is_leap != nil {
		is_leap^ = leap_second
	}

	if _res, ok := datetime_to_time(moment.year, moment.month, moment.day, moment.hour, moment.minute, moment.second, moment.nano); !ok {
		return {}, 0, 0
	} else {
		return _res, offset, count
	}
}

// Parses an RFC 3339 string and returns Time and a UTC offset in minutes.
// e.g. 1985-04-12T23:20:50.52Z
// Performs no validation on whether components are valid, e.g. it'll return hour = 25 if that's what it's given
rfc3339_to_components :: proc(rfc_datetime: string) -> (res: dt.DateTime, utc_offset: int, is_leap: bool, consumed: int) {
	moment, offset, count, leap_second, ok := _rfc3339_to_components(rfc_datetime)
	if !ok {
		return
	}
	return moment, offset, leap_second, count
}

// Parses an RFC 3339 string and returns datetime.DateTime.
// Performs no validation on whether components are valid, e.g. it'll return hour = 25 if that's what it's given
@(private)
_rfc3339_to_components :: proc(rfc_datetime: string) -> (res: dt.DateTime, utc_offset: int, consumed: int, is_leap: bool, ok: bool) {
	// A compliant date is at minimum 20 characters long, e.g. YYYY-MM-DDThh:mm:ssZ
	(len(rfc_datetime) >= 20) or_return

	// Scan and eat YYYY-MM-DD[Tt], then scan and eat HH:MM:SS, leave separator
	year   := scan_digits(rfc_datetime[0:], "-",  4) or_return
	month  := scan_digits(rfc_datetime[5:], "-",  2) or_return
	day    := scan_digits(rfc_datetime[8:], "Tt", 2) or_return
	hour   := scan_digits(rfc_datetime[11:], ":", 2) or_return
	minute := scan_digits(rfc_datetime[14:], ":", 2) or_return
	second := scan_digits(rfc_datetime[17:], "",  2) or_return
	nanos  := 0
	count  := 19

	if rfc_datetime[count] == '.' {
		// Scan hundredths. The string must be at least 4 bytes long (.hhZ)
		(len(rfc_datetime[count:]) >= 4) or_return
		hundredths := scan_digits(rfc_datetime[count+1:], "", 2) or_return
		count += 3
		nanos = 10_000_000 * hundredths
	}

	// Leap second handling
	if minute == 59 && second == 60 {
		second = 59
		is_leap = true
	}

	err: dt.Error
	if res, err = dt.components_to_datetime(year, month, day, hour, minute, second, nanos); err != .None {
		return {}, 0, 0, false, false
	}

	// Scan UTC offset
	switch rfc_datetime[count] {
	case 'Z':
		utc_offset = 0
		count += 1
	case '+', '-':
		(len(rfc_datetime[count:]) >= 6) or_return
		offset_hour   := scan_digits(rfc_datetime[count+1:], ":", 2) or_return
		offset_minute := scan_digits(rfc_datetime[count+4:], "",  2) or_return

		utc_offset = 60 * offset_hour + offset_minute
		utc_offset *= -1 if rfc_datetime[count] == '-' else 1
		count += 6
	}
	return res, utc_offset, count, is_leap, true
}

@(private)
scan_digits :: proc(s: string, sep: string, count: int) -> (res: int, ok: bool) {
	needed := count + min(1, len(sep))
	(len(s) >= needed) or_return

	#no_bounds_check for i in 0..<count {
		if v := s[i]; v >= '0' && v <= '9' {
			res = res * 10 + int(v - '0')
		} else {
			return 0, false
		}
	}
	found_sep := len(sep) == 0
	#no_bounds_check for v in sep {
		found_sep |= rune(s[count]) == v
	}
	return res, found_sep
}