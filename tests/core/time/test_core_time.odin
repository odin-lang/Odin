package test_core_time

import "core:fmt"
import "core:mem"
import "core:os"
import "core:testing"
import "core:time"
import dt "core:time/datetime"

is_leap_year :: time.is_leap_year

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect       :: testing.expect
	expect_value :: testing.expect_value
	log          :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	test_ordinal_date_roundtrip(&t)
	test_component_to_time_roundtrip(&t)
	test_parse_rfc3339_string(&t)
	test_parse_iso8601_string(&t)

	for _, leak in track.allocation_map {
		expect(&t, false, fmt.tprintf("%v leaked %m\n", leak.location, leak.size))
	}
	for bad_free in track.bad_free_array {
		expect(&t, false, fmt.tprintf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory))
	}

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@test
test_ordinal_date_roundtrip :: proc(t: ^testing.T) {
	expect(t, dt.unsafe_ordinal_to_date(dt.unsafe_date_to_ordinal(dt.MIN_DATE)) == dt.MIN_DATE, "Roundtripping MIN_DATE failed.")
	expect(t, dt.unsafe_date_to_ordinal(dt.unsafe_ordinal_to_date(dt.MIN_ORD))  == dt.MIN_ORD,  "Roundtripping MIN_ORD failed.")
	expect(t, dt.unsafe_ordinal_to_date(dt.unsafe_date_to_ordinal(dt.MAX_DATE)) == dt.MAX_DATE, "Roundtripping MAX_DATE failed.")
	expect(t, dt.unsafe_date_to_ordinal(dt.unsafe_ordinal_to_date(dt.MAX_ORD))  == dt.MAX_ORD,  "Roundtripping MAX_ORD failed.")
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
			msg := fmt.tprintf("[apply offet] Parsing failed: %v -> %v (nsec: %v). Expected %v consumed, got %v", test.rfc_3339, res, res._nsec, test.consumed, consumed)
			expect(t, test.consumed == consumed, msg)

			if test.consumed == consumed {
				expect(t, test.datetime == res,     fmt.tprintf("Time didn't match. Expected %v (%v), got %v (%v)", test.datetime, test.datetime._nsec, res, res._nsec))
				expect(t, test.is_leap  == is_leap, "Expected a leap second, got none.")
			}
		} else {
			res, offset, consumed := time.rfc3339_to_time_and_offset(test.rfc_3339)
			msg := fmt.tprintf("Parsing failed: %v -> %v (nsec: %v), offset: %v. Expected %v consumed, got %v", test.rfc_3339, res, res._nsec, offset, test.consumed, consumed)
			expect(t, test.consumed == consumed, msg)

			if test.consumed == consumed {
				expect(t, test.datetime   == res,     fmt.tprintf("Time didn't match. Expected %v (%v), got %v (%v)", test.datetime, test.datetime._nsec, res, res._nsec))
				expect(t, test.utc_offset == offset,  fmt.tprintf("UTC offset didn't match. Expected %v, got %v", test.utc_offset, offset))
				expect(t, test.is_leap    == is_leap, "Expected a leap second, got none.")
			}
		}
	}
}

@test
test_parse_iso8601_string :: proc(t: ^testing.T) {
	for test in iso8601_tests {
		is_leap := false
		if test.apply_offset {
			res, consumed := time.iso8601_to_time_utc(test.iso_8601, &is_leap)
			msg := fmt.tprintf("[apply offet] Parsing failed: %v -> %v (nsec: %v). Expected %v consumed, got %v", test.iso_8601, res, res._nsec, test.consumed, consumed)
			expect(t, test.consumed == consumed, msg)

			if test.consumed == consumed {
				expect(t, test.datetime == res,     fmt.tprintf("Time didn't match. Expected %v (%v), got %v (%v)", test.datetime, test.datetime._nsec, res, res._nsec))
				expect(t, test.is_leap  == is_leap, "Expected a leap second, got none.")
			}
		} else {
			res, offset, consumed := time.iso8601_to_time_and_offset(test.iso_8601)
			msg := fmt.tprintf("Parsing failed: %v -> %v (nsec: %v), offset: %v. Expected %v consumed, got %v", test.iso_8601, res, res._nsec, offset, test.consumed, consumed)
			expect(t, test.consumed == consumed, msg)

			if test.consumed == consumed {
				expect(t, test.datetime   == res,     fmt.tprintf("Time didn't match. Expected %v (%v), got %v (%v)", test.datetime, test.datetime._nsec, res, res._nsec))
				expect(t, test.utc_offset == offset,  fmt.tprintf("UTC offset didn't match. Expected %v, got %v", test.utc_offset, offset))
				expect(t, test.is_leap    == is_leap, "Expected a leap second, got none.")
			}
		}
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
	expect(t, ok, "Couldn't convert date components into date")

	YYYY, MM, DD := time.date(res)
	hh,   mm, ss := time.clock(res)

	expected := fmt.tprintf("Expected %4d-%2d-%2d %2d:%2d:%2d, got %4d-%2d-%2d %2d:%2d:%2d",
	                        moment.year, moment.month, moment.day, moment.hour, moment.minute, moment.second, YYYY, MM, DD, hh, mm, ss)

	ok =  moment.year == i64(YYYY) && moment.month == i8(MM) && moment.day    == i8(DD)
	ok &= moment.hour == i8(hh)   && moment.minute == i8(mm) && moment.second == i8(ss)
	expect(t, ok, expected)
}