package time
// Parsing ISO 8601 date/time strings into time.Time.

import dt "core:time/datetime"

/*
Parse an ISO 8601 string into a time with UTC offset applied to it.

This procedure parses an ISO 8601 string of roughly the following format:

```text
YYYY-MM-DD[Tt]HH:mm:ss[.nn][Zz][+-]HH:mm
```

And returns time, in UTC represented by that string. In case the timezone offset
is specified in the string, that timezone is applied to time.

Inputs:
- `iso_datetime`: The string to be parsed.
- `is_leap`: Optional output parameter, specifying if the moment was a leap second.

Returns:
- `res`: The time represented by `iso_datetime`, with UTC offset applied.
- `consumed`: Number of bytes consumed by parsing the string.

**Notes**:
- Only 4-digit years are accepted.
- Leap seconds are smeared into 23:59:59.
*/
iso8601_to_time_utc :: proc(iso_datetime: string, is_leap: ^bool = nil) -> (res: Time, consumed: int) {
	offset: int
	res, offset, consumed = iso8601_to_time_and_offset(iso_datetime, is_leap)
	res._nsec += (i64(-offset) * i64(Minute))
	return res, consumed
}

/*
Parse an ISO 8601 string into a time and a UTC offset in minutes.

This procedure parses an ISO 8601 string of roughly the following format:

```text
YYYY-MM-DD[Tt]HH:mm:ss[.nn][Zz][+-]HH:mm
```

And returns time, in UTC represented by that string, and the UTC offset, in
minutes.

Inputs:
- `iso_datetime`: The string to be parsed.
- `is_leap`: Optional output parameter, specifying if the moment was a leap second.

Returns:
- `res`: The time in UTC.
- `utc_offset`: The UTC offset of the time, in minutes.
- `consumed`: Number of bytes consumed by parsing the string.

**Notes**:
- Only 4-digit years are accepted.
- Leap seconds are smeared into 23:59:59.
*/
iso8601_to_time_and_offset :: proc(iso_datetime: string, is_leap: ^bool = nil) -> (res: Time, utc_offset: int, consumed: int) {
	moment, offset, leap_second, count := iso8601_to_components(iso_datetime)
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

/*
Parse an ISO 8601 string into a datetime and a UTC offset in minutes.

This procedure parses an ISO 8601 string of roughly the following format:

```text
YYYY-MM-DD[Tt]HH:mm:ss[.nn][Zz][+-]HH:mm
```

And returns datetime, in UTC represented by that string, and the UTC offset, in
minutes.

Inputs:
- `iso_datetime`: The string to be parsed

Returns:
- `res`: The parsed datetime, in UTC.
- `utc_offset`: The UTC offset, in minutes.
- `is_leap`: Specifies whether the moment was a leap second.
- `consumed`: The number of bytes consumed by parsing the string.

**Notes**:
- This procedure performs no validation on whether components are valid,
  e.g. it'll return hour = 25 if that's what it's given in the specified
  string.
*/
iso8601_to_components :: proc(iso_datetime: string) -> (res: dt.DateTime, utc_offset: int, is_leap: bool, consumed: int) {
	moment, offset, count, leap_second, ok := _iso8601_to_components(iso_datetime)
	if !ok {
		return
	}
	return moment, offset, leap_second, count
}

// Parses an ISO 8601 string and returns datetime.DateTime.
// Performs no validation on whether components are valid, e.g. it'll return hour = 25 if that's what it's given
@(private)
_iso8601_to_components :: proc(iso_datetime: string) -> (res: dt.DateTime, utc_offset: int, consumed: int, is_leap: bool, ok: bool) {
	// A compliant date is at minimum 20 characters long, e.g. YYYY-MM-DDThh:mm:ssZ
	(len(iso_datetime) >= 20) or_return

	// Scan and eat YYYY-MM-DD[Tt], then scan and eat HH:MM:SS, leave separator
	year   := scan_digits(iso_datetime[0:], "-",   4) or_return
	month  := scan_digits(iso_datetime[5:], "-",   2) or_return
	day    := scan_digits(iso_datetime[8:], "Tt ", 2) or_return
	hour   := scan_digits(iso_datetime[11:], ":",  2) or_return
	minute := scan_digits(iso_datetime[14:], ":",  2) or_return
	second := scan_digits(iso_datetime[17:], "",   2) or_return
	nanos  := 0
	count  := 19

	// Scan fractional seconds
	if iso_datetime[count] == '.' {
		count += 1 // consume '.'
		multiplier := 100_000_000
		for digit in iso_datetime[count:] {
			if multiplier >= 1 && int(digit) >= '0' && int(digit) <= '9' {
				nanos += int(digit - '0') * multiplier
				multiplier /= 10
				count += 1
			} else {
				break
			}
		}
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

	if len(iso_datetime[count:]) == 0 {
		return res, utc_offset, count, is_leap, true
	}

	// Scan UTC offset
	switch iso_datetime[count] {
	case 'Z', 'z':
		utc_offset = 0
		count += 1
	case '+', '-':
		(len(iso_datetime[count:]) >= 6) or_return
		offset_hour   := scan_digits(iso_datetime[count+1:], ":", 2) or_return
		offset_minute := scan_digits(iso_datetime[count+4:], "",  2) or_return

		utc_offset = 60 * offset_hour + offset_minute
		utc_offset *= -1 if iso_datetime[count] == '-' else 1
		count += 6
	}
	return res, utc_offset, count, is_leap, true
}