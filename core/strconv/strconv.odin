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

// Parses an integer value from a string, in the given base, without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found.
//
// ```
// n, ok := strconv.parse_i64_of_base("-1234eeee", 10);
// assert(n == -1234 && ok);
// ```
parse_i64_of_base :: proc(str: string, base: int) -> (value: i64, ok: bool) {
	assert(base <= 16, "base must be 1-16");
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

	i := 0;
	for r in s {
		if r == '_' {
			i += 1;
			continue;
		}
		v := i64(_digit_value(r));
		if v >= i64(base) do break;
		value *= i64(base);
		value += v;
		i += 1;
	}

	if neg do value = -value;
	ok = i > 0;
	return;
}

// Parses a integer value from a string, in base 10, unless there's a prefix.
//
// Returns ok=false if a base 10 integer could not be found.
//
// ```
// n, ok := strconv.parse_i64_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_i64_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_i64_maybe_prefixed :: proc(str: string) -> (value: i64, ok: bool) {
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

	i := 0;
	for r in s {
		if r == '_' {
			i += 1;
			continue;
		}
		v := i64(_digit_value(r));
		if v >= base do break;
		value *= base;
		value += v;
		i += 1;
	}

	if neg do value = -value;
	ok = i > 0;
	return;
}

parse_i64 :: proc{parse_i64_maybe_prefixed, parse_i64_of_base};

// Parses an unsigned integer value from a string, in the given base, and
// without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found.
//
// ```
// n, ok := strconv.parse_u64_of_base("1234eeee", 10);
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u64_of_base("5678eeee", 16);
// assert(n == 0x5678eeee && ok);
// ```
parse_u64_of_base :: proc(str: string, base: int) -> (value: u64, ok: bool) {
	assert(base <= 16, "base must be 1-16");
	s := str;
	if len(s) > 1 && s[0] == '+' {
		s = s[1:];
	}

	i := 0;
	for r in s {
		if r == '_' {
			i += 1;
			continue;
		}
		v := u64(_digit_value(r));
		if v >= u64(base) do break;
		value *= u64(base);
		value += v;
		i += 1;
	}

	ok = i > 0;
	return;
}

// Parses an unsigned integer value from a string in base 10, unless there's a prefix.
//
// Returns ok=false if a base 10 integer could not be found, or
// if the value was negative.
//
// ```
// n, ok := strconv.parse_u64_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u64_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_u64_maybe_prefixed :: proc(str: string) -> (value: u64, ok: bool) {
	s := str;
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

	i := 0;
	for r in s {
		if r == '_' {
			i += 1;
			continue;
		}
		v := u64(_digit_value(r));
		if v >= base do break;
		value *= base;
		value += u64(v);
		i += 1;
	}

	ok = i > 0;
	return;
}

parse_u64 :: proc{parse_u64_maybe_prefixed, parse_u64_of_base};

// Parses an integer value from a string in the given base, or
// - if the string has a prefix (e.g: '0x') then that will determine the base;
// - otherwise, assumes base 10.
//
// Returns ok=false if no appropriate value could be found.
//
// ```
// n, ok := strconv.parse_int("1234"); // without prefix, inferred base 10
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_int("ffff", 16); // without prefix, explicit base
// assert(n == 0xffff && ok);
//
// n, ok = strconv.parse_int("0xffff"); // with prefix and inferred base
// assert(n == 0xffff && ok);
// ```
parse_int :: proc(s: string, base := 0) -> (value: int, ok: bool) {
	v: i64 = ---;
	switch base {
	case 0:  v, ok = parse_i64_maybe_prefixed(s);
	case:    v, ok = parse_i64_of_base(s, base);
	}
	value = int(v);
	return;
}


// Parses an unsigned integer value from a string in the given base, or
// - if the string has a prefix (e.g: '0x') then that will determine the base;
// - otherwise, assumes base 10.
//
// Returns ok=false if:
// - no appropriate value could be found; or
// - the value was negative.
//
// ```
// n, ok := strconv.parse_uint("1234"); // without prefix, inferred base 10
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_uint("ffff", 16); // without prefix, explicit base
// assert(n == 0xffff && ok);
//
// n, ok = strconv.parse_uint("0xffff"); // with prefix and inferred base
// assert(n == 0xffff && ok);
// ```
parse_uint :: proc(s: string, base := 0) -> (value: uint, ok: bool) {
	v: u64 = ---;
	switch base {
	case 0:  v, ok = parse_u64_maybe_prefixed(s);
	case:    v, ok = parse_u64_of_base(s, base);
	}
	value = uint(v);
	return;
}


// Parses a 32-bit floating point number from a string.
//
// Returns ok=false if a base 10 float could not be found.
//
// ```
// n, ok := strconv.parse_f32("12.34eee");
// assert(n == 12.34 && ok);
//
// n, ok = strconv.parse_f32("12.34");
// assert(n == 12.34 && ok);
// ```
parse_f32 :: proc(s: string) -> (value: f32, ok: bool) {
	v: f64 = ---;
	v, ok = parse_f64(s);
	return f32(v), ok;
}

// Parses a 64-bit floating point number from a string.
//
// Returns ok=false if a base 10 float could not be found.
//
// ```
// n, ok := strconv.parse_f32("12.34eee");
// assert(n == 12.34 && ok);
//
// n, ok = strconv.parse_f32("12.34");
// assert(n == 12.34 && ok);
// ```
parse_f64 :: proc(s: string) -> (value: f64, ok: bool) {
	if s == "" {
		return;
	}
	i := 0;

	sign: f64 = 1;
	switch s[i] {
	case '-': i += 1; sign = -1;
	case '+': i += 1;
	}

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

	if frac {
		value = sign * (value/scale);
	} else {
		value = sign * (value*scale);
	}

	ok = i > 0;
	return;
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
	v, _ := parse_int(s);
	return v;
}
atof :: proc(s: string) -> f64 {
	v, _  := parse_f64(s);
	return v;
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
