package test_core_time

import "core:testing"
import "core:time"
import dt "core:time/datetime"
import tz "core:time/timezone"

is_leap_year :: time.is_leap_year

@test
test_time_and_date_formatting :: proc(t: ^testing.T) {
	buf: [64]u8
	{
		now := time.Time{_nsec=min(i64)} // 1677-09-21 00:12:44.145224192 +0000 UTC
		d := time.Duration(now._nsec)

		testing.expect_value(t, time.to_string_hms       (now, buf[:]),               "00:12:44")
		testing.expect_value(t, time.to_string_hms_12    (now, buf[:]),               "00:12:44 am")
		testing.expect_value(t, time.to_string_hms_12    (now, buf[:],  {"㏂", "㏘"}), "00:12:44㏂")
		testing.expect_value(t, time.to_string_hms       (d,   buf[:]),               "00:12:44")

		testing.expect_value(t, time.to_string_yyyy_mm_dd(now, buf[:]),               "1677-09-21")
		testing.expect_value(t, time.to_string_yy_mm_dd  (now, buf[:]),               "77-09-21")
		testing.expect_value(t, time.to_string_dd_mm_yyyy(now, buf[:]),               "21-09-1677")
		testing.expect_value(t, time.to_string_dd_mm_yy  (now, buf[:]),               "21-09-77")
		testing.expect_value(t, time.to_string_mm_dd_yyyy(now, buf[:]),               "09-21-1677")
		testing.expect_value(t, time.to_string_mm_dd_yy  (now, buf[:]),               "09-21-77")
	}
	{
		now := time.Time{_nsec=max(i64)} // 2262-04-11 23:47:16.854775807 +0000 UTC
		d := time.Duration(now._nsec)

		testing.expect_value(t, time.to_string_hms       (now, buf[:]),               "23:47:16")
		testing.expect_value(t, time.to_string_hms_12    (now, buf[:]),               "11:47:16 pm")
		testing.expect_value(t, time.to_string_hms_12    (now, buf[:],  {"㏂", "㏘"}), "11:47:16㏘")
		testing.expect_value(t, time.to_string_hms       (d,   buf[:]),               "23:47:16")

		testing.expect_value(t, time.to_string_yyyy_mm_dd(now, buf[:]),               "2262-04-11")
		testing.expect_value(t, time.to_string_yy_mm_dd  (now, buf[:]),               "62-04-11")
		testing.expect_value(t, time.to_string_dd_mm_yyyy(now, buf[:]),               "11-04-2262")
		testing.expect_value(t, time.to_string_dd_mm_yy  (now, buf[:]),               "11-04-62")
		testing.expect_value(t, time.to_string_mm_dd_yyyy(now, buf[:]),               "04-11-2262")
		testing.expect_value(t, time.to_string_mm_dd_yy  (now, buf[:]),               "04-11-62")
	}
}

@test
test_ordinal_date_roundtrip :: proc(t: ^testing.T) {
	testing.expect(t, dt.unsafe_ordinal_to_date(dt.unsafe_date_to_ordinal(dt.MIN_DATE)) == dt.MIN_DATE, "Roundtripping MIN_DATE failed.")
	testing.expect(t, dt.unsafe_date_to_ordinal(dt.unsafe_ordinal_to_date(dt.MIN_ORD))  == dt.MIN_ORD,  "Roundtripping MIN_ORD failed.")
	testing.expect(t, dt.unsafe_ordinal_to_date(dt.unsafe_date_to_ordinal(dt.MAX_DATE)) == dt.MAX_DATE, "Roundtripping MAX_DATE failed.")
	testing.expect(t, dt.unsafe_date_to_ordinal(dt.unsafe_ordinal_to_date(dt.MAX_ORD))  == dt.MAX_ORD,  "Roundtripping MAX_ORD failed.")
}

/*
	1990-12-31T23:59:60Z

This represents the leap second inserted at the end of 1990.

	1990-12-31T15:59:60-08:00

This represents the same leap second in Pacific Standard Time, 8 hours behind UTC.

	1937-01-01T12:00:27.87+00:20

This represents the same instant of time as noon, January 1, 1937, Netherlands time.
Standard time in the Netherlands was exactly 19 minutes and 32.13 seconds ahead of UTC by law from 1909-05-01 through 1937-06-30.
This time zone cannot be represented exactly using the HH:MM format, and this timestamp uses the closest representable UTC offset.
*/
RFC3339_Test :: struct{
	rfc_3339:     string,
	datetime:     time.Time,
	apply_offset: bool,
	utc_offset:   int,
	consumed:     int,
	is_leap:      bool,
}

// These are based on RFC 3339's examples, see https://www.rfc-editor.org/rfc/rfc3339#page-10
rfc3339_tests :: []RFC3339_Test{
	// This represents 20 minutes and 50.52 seconds after the 23rd hour of April 12th, 1985 in UTC.
	{"1985-04-12 23:20:50.52Z",      {482196050520000000},  true,  0,    23, false},
	// Same, but lowercase z
	{"1985-04-12 23:20:50.52z",      {482196050520000000},  true,  0,    23, false},

	// This represents 39 minutes and 57 seconds after the 16th hour of December 19th, 1996 with an offset of -08:00 from UTC (Pacific Standard Time).
	// Note that this is equivalent to 1996-12-20T00:39:57Z in UTC.
	{"1996-12-19 16:39:57-08:00",    {851013597000000000},  false, -480, 25, false},
	{"1996-12-19 16:39:57-08:00",    {851042397000000000},  true,  0,    25, false},
	{"1996-12-20 00:39:57Z",         {851042397000000000},  false, 0,    20, false},

	// This represents the leap second inserted at the end of 1990.
	// It'll be represented as 1990-12-31 23:59:59 UTC after parsing, and `is_leap` will be set to `true`.
	{"1990-12-31 23:59:60Z",         {662687999000000000},  true,  0,    20, true},

	// This represents the same leap second in Pacific Standard Time, 8 hours behind UTC.
	{"1990-12-31 15:59:60-08:00",    {662687999000000000},  true,  0,    25, true},

	// This represents the same instant of time as noon, January 1, 1937, Netherlands time.
	// Standard time in the Netherlands was exactly 19 minutes and 32.13 seconds ahead of UTC by law
	// from 1909-05-01 through 1937-06-30.  This time zone cannot be represented exactly using the
	// HH:MM format, and this timestamp uses the closest representable UTC offset.
	{"1937-01-01 12:00:27.87+00:20", {-1041335972130000000}, false, 20,  28, false},
	{"1937-01-01 12:00:27.87+00:20", {-1041337172130000000}, true,  0,   28, false},
}

ISO8601_Test :: struct{
	iso_8601:     string,
	datetime:     time.Time,
	apply_offset: bool,
	utc_offset:   int,
	consumed:     int,
	is_leap:      bool,
}

// These are based on RFC 3339's examples, see https://www.rfc-editor.org/rfc/rfc3339#page-10
iso8601_tests :: []ISO8601_Test{
	// This represents 20 minutes and .003362 seconds after the 23rd hour of April 12th, 1985 in UTC.
	{"1985-04-12T23:20:50.003362",   {482196050003362000},  true,  0,    26, false},
	{"1985-04-12t23:20:50.003362",   {482196050003362000},  true,  0,    26, false},
	{"1985-04-12 23:20:50.003362",   {482196050003362000},  true,  0,    26, false},

	// This represents 39 minutes and 57 seconds after the 16th hour of December 19th, 1996 with an offset of -08:00 from UTC (Pacific Standard Time).
	// Note that this is equivalent to 1996-12-20T00:39:57Z in UTC.
	{"1996-12-19T16:39:57-08:00",    {851013597000000000},  false, -480, 25, false},
	{"1996-12-19T16:39:57-08:00",    {851042397000000000},  true,  0,    25, false},
	{"1996-12-20T00:39:57Z",         {851042397000000000},  false, 0,    20, false},

	// This represents the leap second inserted at the end of 1990.
	// It'll be represented as 1990-12-31 23:59:59 UTC after parsing, and `is_leap` will be set to `true`.
	{"1990-12-31T23:59:60Z",         {662687999000000000},  true,  0,    20, true},

	// This represents the same leap second in Pacific Standard Time, 8 hours behind UTC.
	{"1990-12-31T15:59:60-08:00",    {662687999000000000},  true,  0,    25, true},

	// This represents the same instant of time as noon, January 1, 1937, Netherlands time.
	// Standard time in the Netherlands was exactly 19 minutes and 32.13 seconds ahead of UTC by law
	// from 1909-05-01 through 1937-06-30.  This time zone cannot be represented exactly using the
	// HH:MM format, and this timestamp uses the closest representable UTC offset.
	{"1937-01-01 12:00:27.87+00:20", {-1041335972130000000}, false, 20,  28, false},
	{"1937-01-01 12:00:27.87+00:20", {-1041337172130000000}, true,  0,   28, false},
}

@test
test_parse_rfc3339_string :: proc(t: ^testing.T) {
	for test in rfc3339_tests {
		is_leap := false
		if test.apply_offset {
			res, consumed := time.rfc3339_to_time_utc(test.rfc_3339, &is_leap)
			testing.expectf(
				t,
				test.consumed == consumed,
				"[apply offet] Parsing failed: %v -> %v (nsec: %v). Expected %v consumed, got %v",
				test.rfc_3339, res, res._nsec, test.consumed, consumed,
			)

			if test.consumed == consumed {
				testing.expectf(
					t,
					test.datetime == res,
					"Time didn't match. Expected %v (%v), got %v (%v)",
					test.datetime, test.datetime._nsec, res, res._nsec,
				)
				testing.expect(
					t,
					test.is_leap == is_leap,
					"Expected a leap second, got none",
				)
			}
		} else {
			res, offset, consumed := time.rfc3339_to_time_and_offset(test.rfc_3339)
			testing.expectf(
				t,
				test.consumed == consumed,
				"Parsing failed: %v -> %v (nsec: %v), offset: %v. Expected %v consumed, got %v",
				test.rfc_3339, res, res._nsec, offset, test.consumed, consumed,
			)

			if test.consumed == consumed {
				testing.expectf(
					t, test.datetime == res,
					"Time didn't match. Expected %v (%v), got %v (%v)",
					test.datetime, test.datetime._nsec, res, res._nsec,
				)
				testing.expectf(
					t,
					test.utc_offset == offset,
					"UTC offset didn't match. Expected %v, got %v",
					test.utc_offset, offset,
				)
				testing.expect(
					t, test.is_leap == is_leap,
					"Expected a leap second, got none",
				)
			}
		}
	}
}

@test
test_print_rfc3339 :: proc(t: ^testing.T) {
	TestCase :: struct {
		printed: string,
		time: i64,
		utc_offset: int,
	}

	tests :: [?]TestCase {
		{"1985-04-12T23:20:50.52Z",      	482196050520000000,  	0},
		{"1985-04-12T23:20:50.52001905Z",	482196050520019050,  	0},
		{"1996-12-19T16:39:57-08:00",    	851013597000000000,  	-480},
		{"1996-12-20T00:39:57Z",         	851042397000000000,  	0},
		{"1937-01-01T12:00:27.87+00:20", 	-1041335972130000000,	+20},
	}

	for test in tests {
		timestamp := time.Time { _nsec = test.time }
		printed_timestamp, ok := time.time_to_rfc3339(time=timestamp, utc_offset=test.utc_offset)
		defer delete_string(printed_timestamp)

		testing.expect(t, ok, "expected printing to work fine")

		testing.expectf(
			t, printed_timestamp == test.printed,
			"expected is %w, printed is %w", test.printed, printed_timestamp,
		)
	}
}

@test
test_parse_iso8601_string :: proc(t: ^testing.T) {
	for test in iso8601_tests {
		is_leap := false
		if test.apply_offset {
			res, consumed := time.iso8601_to_time_utc(test.iso_8601, &is_leap)
			testing.expectf(
				t,
				test.consumed == consumed,
				"[apply offet] Parsing failed: %v -> %v (nsec: %v). Expected %v consumed, got %v",
				test.iso_8601, res, res._nsec, test.consumed, consumed,
			)

			if test.consumed == consumed {
				testing.expectf(
					t,
					test.datetime == res,
					"Time didn't match. Expected %v (%v), got %v (%v)",
					test.datetime, test.datetime._nsec, res, res._nsec,
				)
				testing.expect(
					t,
					test.is_leap == is_leap,
					"Expected a leap second, got none",
				)
			}
		} else {
			res, offset, consumed := time.iso8601_to_time_and_offset(test.iso_8601)
			testing.expectf(
				t,
				test.consumed == consumed,
				"Parsing failed: %v -> %v (nsec: %v), offset: %v. Expected %v consumed, got %v",
				test.iso_8601, res, res._nsec, offset, test.consumed, consumed,
			)

			if test.consumed == consumed {
				testing.expectf(
					t, test.datetime == res,
					"Time didn't match. Expected %v (%v), got %v (%v)",
					test.datetime, test.datetime._nsec, res, res._nsec,
				)
				testing.expectf(
					t,
					test.utc_offset == offset,
					"UTC offset didn't match. Expected %v, got %v",
					test.utc_offset, offset,
				)
				testing.expect(
					t,
					test.is_leap == is_leap,
					"Expected a leap second, got none",
				)
			}
		}
	}
}

@test
test_time_to_datetime_roundtrip :: proc(t: ^testing.T) {
	// Roundtrip a time through `time_to_datetime` to `DateTime` and back.
	// Select `N` evenly-distributed points throughout the positive signed 64-bit number line.
	N :: 1024
	for i in 0..=i64(N) {
		n := i * (max(i64) / N)
		x := time.unix(0, n)

		y, ttd_err := time.time_to_datetime(x)
		testing.expectf(t, ttd_err,
			"Time<%i> failed to convert to DateTime",
			n) or_continue

		z, dtt_err := time.datetime_to_time(y)
		testing.expectf(t, dtt_err,
			"DateTime<%v> failed to convert to Time",
			y) or_continue

		testing.expectf(t, x == z,
			"Roundtrip conversion of Time to DateTime and back failed: got %v, expected %v",
			z, x)
	}
}

MONTH_DAYS := []int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
YEAR_START :: 1900
YEAR_END   :: 2024

@test
test_component_to_time_roundtrip :: proc(t: ^testing.T) {
	// Roundtrip a datetime through `datetime_to_time` to `Time` and back to its components.
	for year in YEAR_START..=YEAR_END {
		for month in 1..=12 {
			days := MONTH_DAYS[month - 1]
			if month == 2 && is_leap_year(year) {
				days += 1
			}
			for day in 1..=days {
				d, _ := dt.components_to_datetime(year, month, day, 0, 0, 0, 0)
				date_component_roundtrip_test(t, d)
			}
		}
	}
}

date_component_roundtrip_test :: proc(t: ^testing.T, moment: dt.DateTime) {
	res, ok := time.datetime_to_time(moment.year, moment.month, moment.day, moment.hour, moment.minute, moment.second)
	testing.expect(
		t,
		ok,
		"Couldn't convert date components into date",
	)

	YYYY, MM, DD := time.date(res)
	hh,   mm, ss := time.clock(res)

	ok =  moment.year == i64(YYYY) && moment.month == i8(MM) && moment.day    == i8(DD)
	ok &= moment.hour == i8(hh)   && moment.minute == i8(mm) && moment.second == i8(ss)
	testing.expectf(
		t,
		ok,
		"Expected %4d-%2d-%2d %2d:%2d:%2d, got %4d-%2d-%2d %2d:%2d:%2d",
		moment.year, moment.month, moment.day, moment.hour, moment.minute, moment.second, YYYY, MM, DD, hh, mm, ss,
	)
}

datetime_eq :: proc(dt1: dt.DateTime, dt2: dt.DateTime) -> bool {
	return (
		dt1.year == dt2.year && dt1.month == dt2.month   && dt1.day == dt2.day &&
		dt1.hour == dt2.hour && dt1.minute == dt2.minute && dt1.second == dt2.second
	)
}

@test
test_convert_timezone_roundtrip :: proc(t: ^testing.T) {
	dst_dt, _ := dt.components_to_datetime(2024, 10, 4, 23, 47, 0)
	std_dt, _ := dt.components_to_datetime(2024, 11, 4, 23, 47, 0)

	local_tz, local_load_ok := tz.region_load("local")
	testing.expectf(t, local_load_ok, "Failed to load local timezone")
	defer tz.region_destroy(local_tz)

	edm_tz, edm_load_ok := tz.region_load("America/Edmonton")
	testing.expectf(t, edm_load_ok, "Failed to load America/Edmonton timezone")
	defer tz.region_destroy(edm_tz)

	shuffle_tz :: proc(start_dt: dt.DateTime, test_tz: ^dt.TZ_Region) -> dt.DateTime {
		tz_dt := tz.datetime_to_tz(start_dt, test_tz)
		utc_dt := tz.datetime_to_utc(tz_dt)
		return utc_dt
	}

	testing.expectf(t, datetime_eq(dst_dt, shuffle_tz(dst_dt, local_tz)), "Failed to convert to/from local dst timezone")
	testing.expectf(t, datetime_eq(std_dt, shuffle_tz(std_dt, local_tz)), "Failed to convert to/from local std timezone")
	testing.expectf(t, datetime_eq(dst_dt, shuffle_tz(dst_dt, edm_tz)), "Failed to convert to/from Edmonton dst timezone")
	testing.expectf(t, datetime_eq(std_dt, shuffle_tz(std_dt, edm_tz)), "Failed to convert to/from Edmonton std timezone")
}

@test
test_check_timezone_metadata :: proc(t: ^testing.T) {
	dst_dt, _ := dt.components_to_datetime(2024, 10, 4, 23, 47, 0)
	std_dt, _ := dt.components_to_datetime(2024, 11, 4, 23, 47, 0)

	pac_tz, pac_load_ok := tz.region_load("America/Los_Angeles")
	testing.expectf(t, pac_load_ok, "Failed to load America/Los_Angeles timezone")
	defer tz.region_destroy(pac_tz)

	pac_dst_dt := tz.datetime_to_tz(dst_dt, pac_tz)
	pac_std_dt := tz.datetime_to_tz(std_dt, pac_tz)
	testing.expectf(t, tz.shortname_unsafe(pac_dst_dt) == "PDT", "Invalid timezone shortname")
	testing.expectf(t, tz.shortname_unsafe(pac_std_dt) == "PST", "Invalid timezone shortname")
	testing.expectf(t, tz.dst_unsafe(pac_std_dt) == false, "Expected daylight savings == false, got true")
	testing.expectf(t, tz.dst_unsafe(pac_dst_dt) == true, "Expected daylight savings == true, got false")

	pac_dst_name, ok := tz.shortname(pac_dst_dt)
	testing.expectf(t, ok == true, "Invalid datetime")
	testing.expectf(t, pac_dst_name == "PDT", "Invalid timezone shortname")

	pac_std_name, ok2 := tz.shortname(pac_std_dt)
	testing.expectf(t, ok2 == true, "Invalid datetime")
	testing.expectf(t, pac_std_name == "PST", "Invalid timezone shortname")

	pac_is_dst, ok3 := tz.dst(pac_dst_dt)
	testing.expectf(t, ok3 == true, "Invalid datetime")
	testing.expectf(t, pac_is_dst == true, "Expected daylight savings == false, got true")

	pac_is_dst, ok3 = tz.dst(pac_std_dt)
	testing.expectf(t, ok3 == true, "Invalid datetime")
	testing.expectf(t, pac_is_dst == false, "Expected daylight savings == false, got true")
}

rrule_eq :: proc(r1, r2: dt.TZ_RRule) -> (eq: bool) {
	if r1.has_dst    != r2.has_dst { return }

	if r1.std_name   != r2.std_name { return }
	if r1.std_offset != r2.std_offset { return }
	if r1.std_date   != r2.std_date { return }

	if r1.dst_name   != r2.dst_name { return }
	if r1.dst_offset != r2.dst_offset { return }
	if r1.dst_date   != r2.dst_date { return }

	return true
}

@test
test_check_timezone_posix_tz :: proc(t: ^testing.T) {
	correct_simple_rrule := dt.TZ_RRule{
		has_dst    = false,

		std_name   = "UTC",
		std_offset = -(5 * 60 * 60),
		std_date   = dt.TZ_Transition_Date{
			type   = .Leap,
			day    = 0,
			time   = 2 * 60 * 60,
		},
	}

	simple_rrule, simple_rrule_ok := tz.parse_posix_tz("UTC+5")
	testing.expectf(t, simple_rrule_ok, "Failed to parse posix tz")
	defer tz.rrule_destroy(simple_rrule)
	testing.expectf(t, rrule_eq(simple_rrule, correct_simple_rrule), "POSIX TZ parsed incorrectly")

	correct_est_rrule := dt.TZ_RRule{
		has_dst    = true,

		std_name   = "EST",
		std_offset = -(5 * 60 * 60),
		std_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 3,
			week   = 2,
			day    = 0,
			time   = 2 * 60 * 60,
		},

		dst_name   = "EDT",
		dst_offset = -(4 * 60 * 60),
		dst_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 11,
			week   = 1,
			day    = 0,
			time   = 2 * 60 * 60,
		},
	}

	est_rrule, est_rrule_ok := tz.parse_posix_tz("EST+5EDT,M3.2.0/2,M11.1.0/2")
	testing.expectf(t, est_rrule_ok, "Failed to parse posix tz")
	defer tz.rrule_destroy(est_rrule)
	testing.expectf(t, rrule_eq(est_rrule, correct_est_rrule), "POSIX TZ parsed incorrectly")

	correct_ist_rrule := dt.TZ_RRule{
		has_dst    = true,

		std_name   = "IST",
		std_offset = (2 * 60 * 60),
		std_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 3,
			week   = 4,
			day    = 4,
			time   = 26 * 60 * 60,
		},

		dst_name   = "IDT",
		dst_offset = (3 * 60 * 60),
		dst_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 10,
			week   = 5,
			day    = 0,
			time   = 2 * 60 * 60,
		},
	}

	ist_rrule, ist_rrule_ok := tz.parse_posix_tz("IST-2IDT,M3.4.4/26,M10.5.0")
	testing.expectf(t, ist_rrule_ok, "Failed to parse posix tz")
	defer tz.rrule_destroy(ist_rrule)
	testing.expectf(t, rrule_eq(ist_rrule, correct_ist_rrule), "POSIX TZ parsed incorrectly")

	correct_warst_rrule := dt.TZ_RRule{
		has_dst    = true,

		std_name   = "WART",
		std_offset = -(4 * 60 * 60),
		std_date   = dt.TZ_Transition_Date{
			type   = .No_Leap,
			day    = 1,
			time   = 0 * 60 * 60,
		},

		dst_name   = "WARST",
		dst_offset = -(3 * 60 * 60),
		dst_date   = dt.TZ_Transition_Date{
			type   = .No_Leap,
			day    = 365,
			time   = 25 * 60 * 60,
		},
	}

	warst_rrule, warst_rrule_ok := tz.parse_posix_tz("WART4WARST,J1/0,J365/25")
	testing.expectf(t, warst_rrule_ok, "Failed to parse posix tz")
	defer tz.rrule_destroy(warst_rrule)
	testing.expectf(t, rrule_eq(warst_rrule, correct_warst_rrule), "POSIX TZ parsed incorrectly")

	correct_wgt_rrule := dt.TZ_RRule{
		has_dst    = true,

		std_name   = "WGT",
		std_offset = -(3 * 60 * 60),
		std_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 3,
			week   = 5,
			day    = 0,
			time   = -2 * 60 * 60,
		},

		dst_name   = "WGST",
		dst_offset = -(2 * 60 * 60),
		dst_date   = dt.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = 10,
			week   = 5,
			day    = 0,
			time   = -1 * 60 * 60,
		},
	}

	wgt_rrule, wgt_rrule_ok := tz.parse_posix_tz("WGT3WGST,M3.5.0/-2,M10.5.0/-1")
	testing.expectf(t, wgt_rrule_ok, "Failed to parse posix tz")
	defer tz.rrule_destroy(wgt_rrule)
	testing.expectf(t, rrule_eq(wgt_rrule, correct_wgt_rrule), "POSIX TZ parsed incorrectly")
}

@test
test_check_timezone_edgecases :: proc(t: ^testing.T) {
	utc_dt, _ := dt.components_to_datetime(2024, 10, 4, 0, 47, 0)

	tok_tz, tok_load_ok := tz.region_load("Asia/Tokyo")
	testing.expectf(t, tok_load_ok, "Failed to load Asia/Tokyo timezone")
	defer tz.region_destroy(tok_tz)

	ret_dt := tz.datetime_to_tz(utc_dt, tok_tz)
	expected_tok_dt, _ := dt.components_to_datetime(2024, 10, 4, 9, 47, 0)

	testing.expectf(t, datetime_eq(ret_dt, expected_tok_dt), "Failed to convert to Tokyo time")


	tog_tz, tog_load_ok := tz.region_load("Pacific/Tongatapu")
	testing.expectf(t, tog_load_ok, "Failed to load Pacific/Tongatapu timezone")
	defer tz.region_destroy(tog_tz)

	ret_dt = tz.datetime_to_tz(utc_dt, tog_tz)
	expected_tog_dt, _ := dt.components_to_datetime(2024, 10, 4, 13, 47, 0)

	testing.expectf(t, datetime_eq(ret_dt, expected_tog_dt), "Failed to convert to Togatapu time")
}
