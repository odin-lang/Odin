package timezone

import "base:intrinsics"

import "core:slice"
import "core:strings"
import "core:os"
import "core:strconv"
import "core:time/datetime"

// Implementing RFC8536 [https://datatracker.ietf.org/doc/html/rfc8536]

TZIF_MAGIC :: u32be(0x545A6966) // 'TZif'
TZif_Version :: enum u8 {
	V1 =  0,
	V2 = '2',
	V3 = '3',
	V4 = '4',
}
BIG_BANG_ISH :: -0x800000000000000

TZif_Header :: struct #packed {
	magic:    u32be,
	version:  TZif_Version,
	reserved: [15]u8,
	isutcnt:  u32be,
	isstdcnt: u32be,
	leapcnt:  u32be,
	timecnt:  u32be,
	typecnt:  u32be,
	charcnt:  u32be,
}

Sun_Shift :: enum u8 {
	Standard = 0,
	DST      = 1,
}

Local_Time_Type :: struct #packed {
	utoff: i32be,
	dst:   Sun_Shift,
	idx:   u8,
}

Leapsecond_Record :: struct #packed {
	occur: i64be,
	corr:  i32be,
}

@private
tzif_data_block_size :: proc(hdr: ^TZif_Header, version: TZif_Version) -> (block_size: int, ok: bool) {
	time_size : int

	if version == .V1 {
		time_size = 4
	} else if version == .V2 || version == .V3 || version == .V4 {
		time_size = 8
	} else {
		return
	}

	return (int(hdr.timecnt) * time_size)              +
		   int(hdr.timecnt)                            +
		   int(hdr.typecnt * size_of(Local_Time_Type)) +
		   int(hdr.charcnt)                            +
		   (int(hdr.leapcnt) * (time_size + 4))        +
		   int(hdr.isstdcnt)                           +
		   int(hdr.isutcnt), true
}


load_tzif_file :: proc(filename: string, region_name: string, allocator := context.allocator) -> (out: ^datetime.TZ_Region, ok: bool) {
	tzif_data := os.read_entire_file_from_filename(filename, allocator) or_return
	defer delete(tzif_data, allocator)
	return parse_tzif(tzif_data, region_name, allocator)
}

@private
is_alphabetic :: proc(ch: u8) -> bool {
	//     ('A' -> 'Z')             || ('a' -> 'z')
	return (ch > 0x40 && ch < 0x5B) || (ch > 0x60 && ch < 0x7B)
}

@private
is_numeric :: proc(ch: u8) -> bool {
	//     ('0' -> '9')
	return (ch > 0x2F && ch < 0x3A)
}

@private
is_alphanumeric :: proc(ch: u8) -> bool {
	return is_alphabetic(ch) || is_numeric(ch)
}

@private
is_valid_quoted_char :: proc(ch: u8) -> bool {
	return is_alphabetic(ch) || is_numeric(ch) || ch == '+' || ch == '-'
}

@private
parse_posix_tz_shortname :: proc(str: string) -> (out: string, idx: int, ok: bool) {
	was_quoted := false
	quoted := false
	i := 0

	for ; i < len(str); i += 1 {
		ch := str[i]

		if !quoted && ch == '<' {
			quoted = true
			was_quoted = true
			continue
		}

		if quoted && ch == '>' {
			quoted = false
			break
		}

		if !is_valid_quoted_char(ch) && ch != ',' {
			return
		}

		if !quoted && !is_alphabetic(ch) {
			break
		}
	}

	// If we didn't see the trailing quote
	if was_quoted && quoted {
		return
	}

	out_str: string
	end_idx := i
	if was_quoted {
		end_idx += 1
		out_str = str[1:i]
	} else {
		out_str = str[:i]
	}

	return out_str, end_idx, true
}

@private
parse_posix_tz_offset :: proc(str: string) -> (out_sec: i64, idx: int, ok: bool) {
	str := str

	sign : i64 = 1
	start_idx := 0
	i := 0
	if str[i] == '+' {
		i += 1
		sign = 1
		start_idx = 1
	} else if str[i] == '-' {
		i += 1
		sign = -1
		start_idx = 1
	}

	got_more_time := false
	for ; i < len(str); i += 1 {
		if is_numeric(str[i]) {
			continue
		}

		if str[i] == ':' {
			got_more_time = true
			break
		}
		
		break
	}

	ret_sec : i64 = 0
	hours := strconv.parse_int(str[start_idx:i], 10) or_return
	if hours > 167 || hours < -167 {
		return
	}
	ret_sec += i64(hours) * (60 * 60)
	if !got_more_time {
		return ret_sec * sign, i, true
	}

	i += 1
	start_idx = i

	got_more_time = false
	for ; i < len(str); i += 1 {
		if is_numeric(str[i]) {
			continue
		}

		if str[i] == ':' {
			got_more_time = true
			break
		}
		
		break
	}

	mins_str := str[start_idx:i]
	if len(mins_str) != 2 {
		return
	}

	mins := strconv.parse_int(mins_str, 10) or_return
	if mins > 59 || mins < 0 {
		return
	}
	ret_sec += i64(mins) * 60
	if !got_more_time {
		return ret_sec * sign, i, true
	}

	i += 1
	start_idx = i

	for ; i < len(str); i += 1 {
		if !is_numeric(str[i]) {
			break
		}
	}
	secs_str := str[start_idx:i]
	if len(secs_str) != 2 {
		return
	}

	secs := strconv.parse_int(secs_str, 10) or_return
	if secs > 59 || secs < 0 {
		return
	}
	ret_sec += i64(secs)
	return ret_sec * sign, i, true
}

@private
skim_digits :: proc(str: string) -> (out: string, idx: int, ok: bool) {
	i := 0
	for ; i < len(str); i += 1 {
		ch := str[i]
		if ch == '.' || ch == '/' || ch == ',' {
			break
		}

		if !is_numeric(ch) {
			return
		}
	}

	return str[:i], i, true
}

TWO_AM :: 2 * 60 * 60
parse_posix_rrule :: proc(str: string) -> (out: datetime.TZ_Transition_Date, idx: int, ok: bool) {
	str := str
	if len(str) < 2 { return }

	i := 0
	// No leap
	if str[i] == 'J' {
		i += 1

		day_str, off := skim_digits(str[i:]) or_return
		i += off

		day := strconv.parse_int(day_str, 10) or_return
		if day < 1 || day > 365 { return }

		offset : i64 = TWO_AM
		if len(str) != i && str[i] == '/' {
			i += 1

			offset, off = parse_posix_tz_offset(str[i:]) or_return
			i += off
		}

		if len(str) != i && str[i] == ',' {
			i += 1
		}

		return datetime.TZ_Transition_Date{
			type   = .No_Leap,
			day    = u16(day),
			time   = offset,
		}, i, true

	// Leap
	} else if is_numeric(str[i]) {
		day_str, off := skim_digits(str[i:]) or_return
		i += off

		day := strconv.parse_int(day_str, 10) or_return
		if day < 0 || day > 365 { return }

		offset : i64 = TWO_AM
		if len(str) != i && str[i] == '/' {
			i += 1

			offset, off = parse_posix_tz_offset(str[i:]) or_return
			i += off
		}

		if len(str) != i && str[i] == ',' {
			i += 1
		}

		return datetime.TZ_Transition_Date{
			type   = .Leap,
			day    = u16(day),
			time   = offset,
		}, i, true

	} else if str[i] == 'M' {
		i += 1

		month_str, week_str, day_str: string
		off := 0

		month_str, off = skim_digits(str[i:]) or_return
		i += off + 1

		week_str, off = skim_digits(str[i:]) or_return
		i += off + 1

		day_str, off = skim_digits(str[i:]) or_return
		i += off

		month := strconv.parse_int(month_str, 10) or_return
		if month < 1 || month > 12 { return }

		week := strconv.parse_int(week_str, 10) or_return
		if week < 1 || week > 5 { return }

		day := strconv.parse_int(day_str, 10) or_return
		if day < 0 || day > 6 { return }

		offset : i64 = TWO_AM
		if len(str) != i && str[i] == '/' {
			i += 1

			offset, off = parse_posix_tz_offset(str[i:]) or_return
			i += off
		}

		if len(str) != i && str[i] == ',' {
			i += 1
		}

		return datetime.TZ_Transition_Date{
			type   = .Month_Week_Day,
			month  = u8(month),
			week   = u8(week),
			day    = u16(day),
			time = offset,
		}, i, true
	}

	return
}

parse_posix_tz :: proc(posix_tz: string, allocator := context.allocator) -> (out: datetime.TZ_RRule, ok: bool) {
	// TZ string contain at least 3 characters for the STD name, and 1 for the offset
	if len(posix_tz) < 4 {
		return
	}

	str := posix_tz

	std_name, idx := parse_posix_tz_shortname(str) or_return
	str = str[idx:]
	
	std_offset, idx2 := parse_posix_tz_offset(str) or_return
	std_offset *= -1
	str = str[idx2:]

	std_name_str, err := strings.clone(std_name, allocator)
	if err != nil { return }
	defer if !ok { delete(std_name_str, allocator) }

	if len(str) == 0 {
		return datetime.TZ_RRule{
			has_dst  = false,
			std_name = std_name_str,
			std_offset = std_offset,
			std_date = datetime.TZ_Transition_Date{
				type   = .Leap,
				day    = 0,
				time = TWO_AM,
			},
		}, true
	}

	dst_name: string
	dst_offset := std_offset + (1 * 60 * 60)
	if str[0] != ',' {
		dst_name, idx = parse_posix_tz_shortname(str) or_return
		str = str[idx:]

		if str[0] != ',' {
			dst_offset, idx = parse_posix_tz_offset(str) or_return
			dst_offset *= -1
			str = str[idx:]
		}
	}
	if str[0] != ',' { return }
	str = str[1:]

	std_td, idx3 := parse_posix_rrule(str) or_return
	str = str[idx3:]

	dst_td, idx4 := parse_posix_rrule(str) or_return
	str = str[idx4:]

	dst_name_str: string
	dst_name_str, err = strings.clone(dst_name, allocator)
	if err != nil { return }

	return datetime.TZ_RRule{
		has_dst = true,

		std_name   = std_name_str,
		std_offset = std_offset,
		std_date   = std_td,

		dst_name   = dst_name_str,
		dst_offset = dst_offset,
		dst_date   = dst_td,
	}, true
}

parse_tzif :: proc(_buffer: []u8, region_name: string, allocator := context.allocator) -> (out: ^datetime.TZ_Region, ok: bool) {
	context.allocator = allocator

	buffer := _buffer

	// TZif is crufty. Skip the initial header.

	v1_hdr := slice.to_type(buffer, TZif_Header) or_return
	if v1_hdr.magic != TZIF_MAGIC {
		return
	}
	if v1_hdr.typecnt == 0 || v1_hdr.charcnt == 0 {
		return
	}
	if v1_hdr.isutcnt != 0 && v1_hdr.isutcnt != v1_hdr.typecnt {
		return
	}
	if v1_hdr.isstdcnt != 0 && v1_hdr.isstdcnt != v1_hdr.typecnt {
		return
	}

	// We don't bother supporting v1, it uses u32 timestamps
	if v1_hdr.version == .V1 {
		return
	}
	// We only support v2 and v3
	if v1_hdr.version != .V2 && v1_hdr.version != .V3 {
		return
	}

	// Skip the initial v1 block too.
	first_block_size, _ := tzif_data_block_size(&v1_hdr, .V1)
	if len(buffer) <= size_of(v1_hdr) + first_block_size {
		return
	}
	buffer = buffer[size_of(v1_hdr)+first_block_size:]

	// Ok, time to parse real things
	real_hdr := slice.to_type(buffer, TZif_Header) or_return
	if real_hdr.magic != TZIF_MAGIC {
		return
	}
	if real_hdr.typecnt == 0 || real_hdr.charcnt == 0 {
		return
	}
	if real_hdr.isutcnt != 0 && real_hdr.isutcnt != real_hdr.typecnt {
		return
	}
	if real_hdr.isstdcnt != 0 && real_hdr.isstdcnt != real_hdr.typecnt {
		return
	}

	// Grab the real data block
	real_block_size, _ := tzif_data_block_size(&real_hdr, v1_hdr.version)
	if len(buffer) <= size_of(real_hdr) + real_block_size {
		return
	}
	buffer = buffer[size_of(real_hdr):]

	time_size := 8
	transition_times := slice.reinterpret([]i64be, buffer[:int(real_hdr.timecnt)*size_of(i64be)])
	for time in transition_times {
		if time < BIG_BANG_ISH {
			return
		}
	}
	buffer = buffer[int(real_hdr.timecnt)*time_size:]

	transition_types := buffer[:int(real_hdr.timecnt)]
	for type in transition_types {
		if int(type) > int(real_hdr.typecnt - 1) {
			return
		}
	}
	buffer = buffer[int(real_hdr.timecnt):]

	local_time_types := slice.reinterpret([]Local_Time_Type, buffer[:int(real_hdr.typecnt)*size_of(Local_Time_Type)])
	for ltt in local_time_types {
		// UT offset should be > -25 hours and < 26 hours
		if int(ltt.utoff) < -89999 || int(ltt.utoff) > 93599 {
			return
		}

		if ltt.dst != .DST && ltt.dst != .Standard {
			return
		}

		if int(ltt.idx) > int(real_hdr.charcnt - 1) {
			return
		}
	}

	buffer = buffer[int(real_hdr.typecnt) * size_of(Local_Time_Type):]
	timezone_string_table := buffer[:real_hdr.charcnt]
	buffer = buffer[real_hdr.charcnt:]

	leapsecond_records := slice.reinterpret([]Leapsecond_Record, buffer[:int(real_hdr.leapcnt)*size_of(Leapsecond_Record)])
	if len(leapsecond_records) > 0 {
		if leapsecond_records[0].occur < 0 {
			return
		}
	}
	buffer = buffer[(int(real_hdr.leapcnt) * size_of(Leapsecond_Record)):]

	standard_wall_tags := buffer[:int(real_hdr.isstdcnt)]
	buffer = buffer[int(real_hdr.isstdcnt):]

	ut_tags := buffer[:int(real_hdr.isutcnt)]

	for stdwall_tag, idx in standard_wall_tags {
		ut_tag := ut_tags[idx]

		if (stdwall_tag != 0 && stdwall_tag != 1) {
			return
		}
		if (ut_tag != 0 && ut_tag != 1) {
			return
		}

		if ut_tag == 1 && stdwall_tag != 1 {
			return
		}
	}
	buffer = buffer[int(real_hdr.isutcnt):]

	// Start of footer
	if buffer[0] != '\n' {
		return
	}
	buffer = buffer[1:]

	if buffer[0] == ':' {
		return
	}

	end_idx := 0
	for ch in buffer {
		if ch == '\n' {
			break
		}

		if ch == 0 {
			return
		}
		end_idx += 1
	}
	footer_str := string(buffer[:end_idx])

	// UTC is a special case, we don't need to alloc
	if len(local_time_types) == 1 {
		name := cstring(raw_data(timezone_string_table[local_time_types[0].idx:]))
		if name != "UTC" {
			return
		}

		return nil, true
	}

	ltt_names, err := make([dynamic]string, 0, len(local_time_types), allocator)
	if err != nil { return }
	defer if err != nil {
		for name in ltt_names {
			delete(name, allocator)
		}
		delete(ltt_names) 
	}

	for ltt in local_time_types {
		name := cstring(raw_data(timezone_string_table[ltt.idx:]))
		ltt_name: string

		ltt_name, err = strings.clone_from_cstring_bounded(name, len(timezone_string_table), allocator)
		if err != nil { return }

		append(&ltt_names, ltt_name)
	}

	records: []datetime.TZ_Record
	records, err = make([]datetime.TZ_Record, len(transition_times), allocator)
	if err != nil { return }
	defer if err != nil { delete(records, allocator) }

	for trans_time, idx in transition_times {
		trans_idx := transition_types[idx]
		ltt := local_time_types[trans_idx]

		records[idx] = datetime.TZ_Record{
			time       = i64(trans_time),
			utc_offset = i64(ltt.utoff),
			shortname  = ltt_names[trans_idx],
			dst        = bool(ltt.dst),
		}
	}

	rrule, ok2 := parse_posix_tz(footer_str, allocator)
	if !ok2 { return }
	defer if err != nil {
		delete(rrule.std_name, allocator)
		delete(rrule.dst_name, allocator)
	}

	region_name_out: string
	region_name_out, err = strings.clone(region_name, allocator)
	if err != nil { return }
	defer if err != nil { delete(region_name_out, allocator) }

	region: ^datetime.TZ_Region
	region, err = new_clone(datetime.TZ_Region{
		records    = records,
		shortnames = ltt_names[:],
		name       = region_name_out,
		rrule      = rrule,
	}, allocator)
	if err != nil {
		return
	}

	return region, true
}
