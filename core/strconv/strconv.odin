package strconv

import "core:unicode/utf8"

parse_bool :: proc(s: string) -> (result: bool = false, ok: bool) {
	switch s {
	case "1", "t", "T", "true", "TRUE", "True":
		return true, true;
	case "0", "f", "F", "false", "FALSE", "False":
		return false, true;
	}
	return;
}

_digit_value :: proc(r: rune) -> int {
	ri := int(r);
	v: int = 16;
	switch r {
	case '0'..'9': v = ri-'0';
	case 'a'..'z': v = ri-'a'+10;
	case 'A'..'Z': v = ri-'A'+10;
	}
	return v;
}

parse_i64 :: proc(str: string) -> i64 {
	s := str;
	neg := false;
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true;
			s = s[1:];
		case '+':
			s = s[1:];
		}
	}


	base: i64 = 10;
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:];
		case 'o': base =  8;  s = s[2:];
		case 'd': base = 10;  s = s[2:];
		case 'z': base = 12;  s = s[2:];
		case 'x': base = 16;  s = s[2:];
		}
	}


	value: i64;
	for r in s {
		if r == '_' {
			continue;
		}

		v := i64(_digit_value(r));
		if v >= base {
			break;
		}
		value *= base;
		value += v;
	}

	if neg do return -value;
	return value;
}

parse_u64 :: proc(str: string) -> u64 {
	s := str;
	neg := false;
	if len(s) > 1 && s[0] == '+' {
		s = s[1:];
	}


	base := u64(10);
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:];
		case 'o': base =  8;  s = s[2:];
		case 'd': base = 10;  s = s[2:];
		case 'z': base = 12;  s = s[2:];
		case 'x': base = 16;  s = s[2:];
		}
	}


	value: u64;
	for r in s {
		if r == '_' do continue;
		v := u64(_digit_value(r));
		if v >= base do break;
		value *= base;
		value += u64(v);
	}

	if neg do return -value;
	return value;
}


parse_int :: proc(s: string) -> int {
	return int(parse_i64(s));
}
parse_uint :: proc(s: string) -> uint {
	return uint(parse_u64(s));
}

parse_f32 :: proc(s: string) -> f32 {
	return f32(parse_f64(s));
}


parse_f64 :: proc(s: string) -> f64 {
	if s == "" {
		return 0;
	}
	i := 0;

	sign: f64 = 1;
	switch s[i] {
	case '-': i += 1; sign = -1;
	case '+': i += 1;
	}

	value: f64 = 0;
	for ; i < len(s); i += 1 {
		r := rune(s[i]);
		if r == '_' do continue;

		v := _digit_value(r);
		if v >= 10 do break;
		value *= 10;
		value += f64(v);
	}

	if i < len(s) && s[i] == '.' {
		pow10: f64 = 10;
		i += 1;

		for ; i < len(s); i += 1 {
			r := rune(s[i]);
			if r == '_' do continue;

			v := _digit_value(r);
			if v >= 10 do break;
			value += f64(v)/pow10;
			pow10 *= 10;
		}
	}

	frac := false;
	scale: f64 = 1;

	if i < len(s) && (s[i] == 'e' || s[i] == 'E') {
		i += 1;

		if i < len(s) {
			switch s[i] {
			case '-': i += 1; frac = true;
			case '+': i += 1;
			}

			exp: u32 = 0;
			for ; i < len(s); i += 1 {
				r := rune(s[i]);
				if r == '_' do continue;

				d := u32(_digit_value(r));
				if d >= 10 do break;
				exp = exp * 10 + d;
			}
			if exp > 308 { exp = 308; }

			for exp >= 50 { scale *= 1e50; exp -= 50; }
			for exp >=  8 { scale *=  1e8; exp -=  8; }
			for exp >   0 { scale *=   10; exp -=  1; }
		}
	}

	if frac do return sign * (value/scale);
	return sign * (value*scale);
}


append_bool :: proc(buf: []byte, b: bool) -> string {
	n := 0;
	if b do n = copy(buf, "true");
	else do n = copy(buf, "false");
	return string(buf[:n]);
}

append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	return append_bits(buf, u64(u), base, false, 8*size_of(uint), digits, nil);
}
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return append_bits(buf, u64(i), base, true, 8*size_of(int), digits, nil);
}

itoa :: proc(buf: []byte, i: int) -> string {
	return append_int(buf, i64(i), 10);
}
atoi :: proc(s: string) -> int {
	return parse_int(s);
}
atof :: proc(s: string) -> f64 {
	return parse_f64(s);
}

ftoa :: append_float;
append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size));
}


quote :: proc(buf: []byte, str: string) -> string {
	write_byte :: inline proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ >= len(buf) do return;
		n := copy(buf[i^:], bytes[:]);
		i^ += n;
	}

	if buf == nil {
		return "";
	}

	c :: '"';
	i := 0;
	s := str;

	write_byte(buf, &i, c);
	for width := 0; len(s) > 0; s = s[width:] {
		r := rune(s[0]);
		width = 1;
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s);
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			write_byte(buf, &i, '\\', 'x');
			write_byte(buf, &i, digits[s[0]>>4]);
			write_byte(buf, &i, digits[s[0]&0xf]);
		}
		if i < len(buf) {
			x := quote_rune(buf[i:], r);
			i += len(x);
		}
	}
	write_byte(buf, &i, c);
	return string(buf[:i]);
}

quote_rune :: proc(buf: []byte, r: rune) -> string {
	write_byte :: inline proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ < len(buf) {
			n := copy(buf[i^:], bytes[:]);
			i^ += n;
		}
	}
	write_string :: inline proc(buf: []byte, i: ^int, s: string) {
		if i^ < len(buf) {
			n := copy(buf[i^:], s);
			i^ += n;
		}
	}
	write_rune :: inline proc(buf: []byte, i: ^int, r: rune) {
		if i^ < len(buf) {
			b, w := utf8.encode_rune(r);
			n := copy(buf[i^:], b[:w]);
			i^ += n;
		}
	}

	if buf == nil {
		return "";
	}

	i := 0;
	write_byte(buf, &i, '\'');

	switch r {
	case '\a': write_string(buf, &i, "\\a");
	case '\b': write_string(buf, &i, "\\b");
	case '\e': write_string(buf, &i, "\\e");
	case '\f': write_string(buf, &i, "\\f");
	case '\n': write_string(buf, &i, "\\n");
	case '\r': write_string(buf, &i, "\\r");
	case '\t': write_string(buf, &i, "\\t");
	case '\v': write_string(buf, &i, "\\v");
	case:
		if r < 32 {
			write_string(buf, &i, "\\x");
			b: [2]byte;
			s := append_bits(b[:], u64(r), 16, true, 64, digits, nil);
			switch len(s) {
			case 0: write_string(buf, &i, "00");
			case 1: write_rune(buf, &i, '0');
			case 2: write_string(buf, &i, s);
			}
		} else {
			write_rune(buf, &i, r);
		}
	}
	write_byte(buf, &i, '\'');

	return string(buf[:i]);
}
