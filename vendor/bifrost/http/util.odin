package bifrost_http

import "core:strconv"
import "core:strings"
import "core:time"

parse_int_safe :: proc(s: string, base: int = 10) -> (n: int, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	return strconv.parse_int(s, base)
}

parse_content_length :: proc(s: string) -> (n: int, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	for i in 0..<len(s) {
		ch := s[i]
		if ch < '0' || ch > '9' {
			return 0, false
		}
	}
	return strconv.parse_int(s, 10)
}

parse_content_length_values :: proc(values: []string) -> (n: int, ok: bool, present: bool, canonical: string) {
	if values == nil || len(values) == 0 {
		return 0, false, false, ""
	}
	first := ""
	for v in values {
		val := strings.trim_space(v)
		if len(val) == 0 {
			return 0, false, true, ""
		}
		if first == "" {
			first = val
		} else if val != first {
			return 0, false, true, ""
		}
	}
	if first == "" {
		return 0, false, true, ""
	}
	n, ok = parse_content_length(first)
	if ok {
		canonical = first
	}
	return n, ok, true, canonical
}

parse_transfer_encoding :: proc(values: []string) -> (chunked: bool, ok: bool, present: bool) {
	if values == nil || len(values) == 0 {
		return false, true, false
	}
	token := ""
	count := 0
	for v in values {
		parts, _ := strings.split(v, ",", context.temp_allocator)
		for p in parts {
			t := strings.trim_space(p)
			if len(t) == 0 {
				continue
			}
			count += 1
			if count == 1 {
				token = t
			} else {
				return false, false, true
			}
		}
	}
	if count == 0 {
		return false, false, true
	}
	if strings.equal_fold(token, "chunked") {
		return true, true, true
	}
	return false, false, true
}

valid_host_header :: proc(host: string) -> bool {
	if len(host) == 0 {
		return true
	}
	for i in 0..<len(host) {
		ch := host[i]
		if ch >= 'a' && ch <= 'z' {
			continue
		}
		if ch >= 'A' && ch <= 'Z' {
			continue
		}
		if ch >= '0' && ch <= '9' {
			continue
		}
		switch ch {
		case '.', '-', '_', ':', '[', ']', '%':
			continue
		}
		return false
	}
	return true
}

parse_request_target :: proc(method, target: string) -> (new_target: string, ok: bool) {
	if method == "CONNECT" {
		return target, true
	}
	if len(target) > 0 && target[0] == '/' {
		return target, true
	}
	if target == "*" {
		return target, true
	}
	if strings.has_prefix(target, "http://") {
		start := len("http://")
		path_idx := strings.index_byte(target[start:], '/')
		if path_idx < 0 {
			return "/", true
		}
		return target[start+path_idx:], true
	}
	if strings.has_prefix(target, "https://") {
		start := len("https://")
		path_idx := strings.index_byte(target[start:], '/')
		if path_idx < 0 {
			return "/", true
		}
		return target[start+path_idx:], true
	}
	return target, false
}

parse_http_month :: proc(s: string) -> (month: i64, ok: bool) {
	if len(s) != 3 {
		return 0, false
	}
	switch s {
	case "Jan": return 1, true
	case "Feb": return 2, true
	case "Mar": return 3, true
	case "Apr": return 4, true
	case "May": return 5, true
	case "Jun": return 6, true
	case "Jul": return 7, true
	case "Aug": return 8, true
	case "Sep": return 9, true
	case "Oct": return 10, true
	case "Nov": return 11, true
	case "Dec": return 12, true
	}
	return 0, false
}

parse_two_digit_year :: proc(y: int) -> int {
	if y >= 69 {
		return 1900 + y
	}
	return 2000 + y
}

parse_int_fixed :: proc(s: string, digits: int) -> (n: int, ok: bool) {
	if len(s) != digits {
		return 0, false
	}
	for i in 0..<len(s) {
		ch := s[i]
		if ch < '0' || ch > '9' {
			return 0, false
		}
	}
	return strconv.parse_int(s, 10)
}

parse_time :: proc(text: string) -> (t: time.Time, ok: bool) {
	s := strings.trim_space(text)
	if len(s) == 0 {
		return {}, false
	}

	// RFC1123: "Mon, 02 Jan 2006 15:04:05 GMT"
	if len(s) == 29 && s[3] == ',' && s[4] == ' ' && s[25] == ' ' && s[26:] == "GMT" {
		day, ok_day := parse_int_fixed(s[5:7], 2)
		month, ok_mon := parse_http_month(s[8:11])
		year, ok_year := parse_int_fixed(s[12:16], 4)
		if ok_day && ok_mon && ok_year &&
			s[16] == ' ' && s[19] == ':' && s[22] == ':' {
			hour, ok_h := parse_int_fixed(s[17:19], 2)
			min, ok_m := parse_int_fixed(s[20:22], 2)
			sec, ok_s := parse_int_fixed(s[23:25], 2)
			if ok_h && ok_m && ok_s {
				t, ok = time.components_to_time(i64(year), i64(month), i64(day), i64(hour), i64(min), i64(sec))
				return
			}
		}
	}

	// RFC850: "Monday, 02-Jan-06 15:04:05 GMT"
	if strings.has_suffix(s, " GMT") {
		base := s[:len(s)-4]
		comma := strings.index_byte(base, ',')
		if comma >= 0 {
			rest := strings.trim_space(base[comma+1:])
			space := strings.index_byte(rest, ' ')
			if space > 0 {
				date_part := rest[:space]
				time_part := rest[space+1:]
				if len(date_part) == 9 && len(time_part) == 8 &&
					date_part[2] == '-' && date_part[6] == '-' &&
					time_part[2] == ':' && time_part[5] == ':' {
					day, ok_day := parse_int_fixed(date_part[0:2], 2)
					month, ok_mon := parse_http_month(date_part[3:6])
					yy, ok_yy := parse_int_fixed(date_part[7:9], 2)
					hour, ok_h := parse_int_fixed(time_part[0:2], 2)
					min, ok_m := parse_int_fixed(time_part[3:5], 2)
					sec, ok_s := parse_int_fixed(time_part[6:8], 2)
					if ok_day && ok_mon && ok_yy && ok_h && ok_m && ok_s {
						year := parse_two_digit_year(yy)
						t, ok = time.components_to_time(i64(year), i64(month), i64(day), i64(hour), i64(min), i64(sec))
						return
					}
				}
			}
		}
	}

	// ANSI C asctime(): "Mon Jan _2 15:04:05 2006"
	if len(s) == 24 && s[3] == ' ' && s[7] == ' ' && s[10] == ' ' && s[19] == ' ' {
		month, ok_mon := parse_http_month(s[4:7])
		day_str := s[8:10]
		day := 0
		ok_day := false
		if day_str[0] == ' ' && day_str[1] >= '0' && day_str[1] <= '9' {
			day = int(day_str[1] - '0')
			ok_day = true
		} else {
			day, ok_day = parse_int_fixed(day_str, 2)
		}
		if ok_mon && ok_day && s[13] == ':' && s[16] == ':' {
			hour, ok_h := parse_int_fixed(s[11:13], 2)
			min, ok_m := parse_int_fixed(s[14:16], 2)
			sec, ok_s := parse_int_fixed(s[17:19], 2)
			year, ok_y := parse_int_fixed(s[20:24], 4)
			if ok_h && ok_m && ok_s && ok_y {
				t, ok = time.components_to_time(i64(year), i64(month), i64(day), i64(hour), i64(min), i64(sec))
				return
			}
		}
	}

	return {}, false
}
