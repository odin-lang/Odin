package timezone

import "core:fmt"
import "core:slice"
import "core:time"
import "core:time/datetime"

region_load :: proc(reg: string, allocator := context.allocator) ->  (out_reg: ^datetime.TZ_Region, ok: bool) {
	return _region_load(reg, allocator)
}

region_load_from_file :: proc(file_path, reg: string, allocator := context.allocator) ->  (out_reg: ^datetime.TZ_Region, ok: bool) {
	return load_tzif_file(file_path, reg, allocator)
}

region_load_from_buffer :: proc(buffer: []u8, reg: string, allocator := context.allocator) ->  (out_reg: ^datetime.TZ_Region, ok: bool) {
	return parse_tzif(buffer, reg, allocator)
}

rrule_destroy :: proc(rrule: datetime.TZ_RRule, allocator := context.allocator) {
	delete(rrule.std_name, allocator)
	delete(rrule.dst_name, allocator)
}

region_destroy :: proc(region: ^datetime.TZ_Region, allocator := context.allocator) {
	if region == nil {
		return
	}

	for name in region.shortnames {
		delete(name, allocator)
	}
	delete(region.shortnames, allocator)
	delete(region.records, allocator)
	delete(region.name, allocator)
	rrule_destroy(region.rrule, allocator)
	free(region, allocator)
}


@private
region_get_nearest :: proc(region: ^datetime.TZ_Region, tm: time.Time) -> (out: datetime.TZ_Record, success: bool) {
	if len(region.records) == 0 {
		return process_rrule(region.rrule, tm)
	}

	n := len(region.records)
	left, right := 0, n

	tm_sec := time.to_unix_seconds(tm)
	last_time := region.records[len(region.records)-1].time
	if tm_sec > last_time {
		return process_rrule(region.rrule, tm)
	}

	for left < right {
		mid := int(uint(left+right) >> 1)
		if region.records[mid].time < tm_sec {
			left = mid + 1
		} else {
			right = mid
		}
	}

	idx := max(0, left-1)
	return region.records[idx], true
}

@private
month_to_seconds :: proc(month: int, is_leap: bool) -> i64 {
	month_seconds := []i64{
		0,             31 * 86_400,  59 * 86_400,  90 * 86_400,
		120 * 86_400, 151 * 86_400, 181 * 86_400, 212 * 86_400,
		243 * 86_400, 273 * 86_400, 304 * 86_400, 334 * 86_400,
	}

	t := month_seconds[month]
	if is_leap && month >= 2 {
		t += 86_400
	}
	return t
}

@private
trans_date_to_seconds :: proc(year: i64, td: datetime.TZ_Transition_Date) -> (secs: i64, ok: bool) {
	is_leap := datetime.is_leap_year(year)
	DAY_SEC :: 86_400

	year_start := datetime.DateTime{{year, 1, 1}, {0, 0, 0, 0}, nil}
	year_start_time := time.datetime_to_time(year_start) or_return

	t := i64(time.to_unix_seconds(year_start_time))

	switch td.type {
	case .Month_Week_Day:
		if td.month < 1 { return }

		t += month_to_seconds(int(td.month) - 1, is_leap)

		weekday := ((t + (4 * DAY_SEC)) %% (7 * DAY_SEC)) / DAY_SEC
		days := i64(td.day) - weekday
		if days < 0 { days += 7 }

		month_daycount, err := datetime.last_day_of_month(year, td.month)
		if err != nil { return }

		week := td.week
		if week == 5 && days + 28 >= i64(month_daycount) {
			week = 4
		}

		t += DAY_SEC * (days + (7 * i64(week - 1)))
		t += td.time

		return t, true

	// Both of these should result in 0 -> 365 days (in seconds)
	case .No_Leap:
		day := i64(td.day)

		// if before Feb 29th || not a leap year
		if day < 60 || !is_leap {
			day -= 1
		}
		t += DAY_SEC * day

		return t, true

	case .Leap:
		t += DAY_SEC * i64(td.day)

		return t, true

	case:
		return
	}

	return
}
 
@private
process_rrule :: proc(rrule: datetime.TZ_RRule, tm: time.Time) -> (out: datetime.TZ_Record, success: bool) {
	if !rrule.has_dst {
		return datetime.TZ_Record{
			time       = time.to_unix_seconds(tm),
			utc_offset = rrule.std_offset,
			shortname  = rrule.std_name,
			dst        = false,
		}, true
	}

	y, _, _ := time.date(tm)
	std_secs := trans_date_to_seconds(i64(y), rrule.std_date) or_return
	dst_secs := trans_date_to_seconds(i64(y), rrule.dst_date) or_return

	records := []datetime.TZ_Record{
		{
			time = std_secs,
			utc_offset = rrule.std_offset,
			shortname  = rrule.std_name,
			dst        = false,
		},
		{
			time = dst_secs,
			utc_offset = rrule.dst_offset,
			shortname  = rrule.dst_name,
			dst        = true,
		},
	}
	record_sort_proc :: proc(i, j: datetime.TZ_Record) -> bool {
		return i.time < j.time
	}
	slice.sort_by(records, record_sort_proc)

	tm_sec := time.to_unix_seconds(tm)
	for record in records {
		if tm_sec < record.time {
			return record, true
		}
	}

	return records[0], true
}

datetime_to_utc :: proc(dt: datetime.DateTime) -> (out: datetime.DateTime, success: bool) #optional_ok {
	if dt.tz == nil {
		return dt, true
	}

	tm := time.datetime_to_time(dt) or_return
	record := region_get_nearest(dt.tz, tm) or_return

	secs := time.time_to_unix(tm)
	adj_time := time.unix(secs - record.utc_offset, 0)
	adj_dt := time.time_to_datetime(adj_time) or_return
	return adj_dt, true
}

/*
Converts a datetime on one timezone to another timezone

Inputs:
- dt: The input datetime
- tz: The timezone to convert to

NOTE: tz will be referenced in the result datetime, so it must stay alive/allocated as long as it is used
Returns:
- out: The converted datetime
- success: `false` if the datetime was invalid
*/
datetime_to_tz :: proc(dt: datetime.DateTime, tz: ^datetime.TZ_Region) -> (out: datetime.DateTime, success: bool) #optional_ok {
	dt := dt
	if dt.tz == tz {
		return dt, true
	}
	if dt.tz != nil {
		dt = datetime_to_utc(dt)
	}
	if tz == nil {
		return dt, true
	}

	tm := time.datetime_to_time(dt) or_return
	record := region_get_nearest(tz, tm) or_return

	secs := time.time_to_unix(tm)
	adj_time := time.unix(secs + record.utc_offset, 0)
	adj_dt := time.time_to_datetime(adj_time) or_return
	adj_dt.tz = tz

	return adj_dt, true
}

/*
Gets the timezone abbreviation/shortname for a given date.
(ex: "PDT")

Inputs:
- dt: The datetime containing the date, time, and timezone pointer for the lookup

NOTE: The lifetime of name matches the timezone it was pulled from.
Returns:
- name: The timezone abbreviation
- success: returns `false` if the passed datetime is invalid
*/
shortname :: proc(dt: datetime.DateTime) -> (name: string, success: bool) #optional_ok {
	tm := time.datetime_to_time(dt) or_return
	if dt.tz == nil { return "UTC", true }

	record := region_get_nearest(dt.tz, tm) or_return
	return record.shortname, true
}

/*
Gets the timezone abbreviation/shortname for a given date.
(ex: "PDT")

WARNING: This is unsafe because it doesn't check if your datetime is valid or if your region contains a valid record.

Inputs:
- dt: The input datetime

NOTE: The lifetime of name matches the timezone it was pulled from.
Returns:
- name: The timezone abbreviation
*/
shortname_unsafe :: proc(dt: datetime.DateTime) -> string {
	if dt.tz == nil { return "UTC" }

	tm, _ := time.datetime_to_time(dt)
	record, _ := region_get_nearest(dt.tz, tm)
	return record.shortname
}

/*
Checks DST for a given date.

Inputs:
- dt: The input datetime

Returns:
- is_dst: returns `true` if dt is in daylight savings time, `false` if not
- success: returns `false` if the passed datetime is invalid
*/
dst :: proc(dt: datetime.DateTime) -> (is_dst: bool, success: bool) #optional_ok {
	tm := time.datetime_to_time(dt) or_return
	if dt.tz == nil { return false, true }

	record := region_get_nearest(dt.tz, tm) or_return
	return record.dst, true
}

/*
Checks DST for a given date.

WARNING: This is unsafe because it doesn't check if your datetime is valid or if your region contains a valid record.

Inputs:
- dt: The input datetime

Returns:
- is_dst: returns `true` if dt is in daylight savings time, `false` if not
*/
dst_unsafe :: proc(dt: datetime.DateTime) -> bool {
	if dt.tz == nil { return false }

	tm, _ := time.datetime_to_time(dt)
	record, _ := region_get_nearest(dt.tz, tm)
	return record.dst
}

datetime_to_str :: proc(dt: datetime.DateTime, allocator := context.allocator) -> string {
	if dt.tz == nil {
		_, ok := time.datetime_to_time(dt)
		if !ok {
			return ""
		}

		return fmt.aprintf("%02d-%02d-%04d @ %02d:%02d:%02d UTC", dt.month, dt.day, dt.year, dt.hour, dt.minute, dt.second, allocator = allocator)

	} else {
		tm, ok := time.datetime_to_time(dt)
		if !ok {
			return ""
		}

		record, ok2 := region_get_nearest(dt.tz, tm)
		if !ok2 {
			return ""
		}

		hour := dt.hour
		am_pm_str := "AM"
		if hour > 12 {
			am_pm_str = "PM"
			hour -= 12
		}

		return fmt.aprintf("%02d-%02d-%04d @ %02d:%02d:%02d %s %s", dt.month, dt.day, dt.year, hour, dt.minute, dt.second, am_pm_str, record.shortname, allocator = allocator)
	}
}
