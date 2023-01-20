package strconv

import "core:unicode/utf8"

import "core:c/libc"

parse_bool :: proc(s: string, n: ^int = nil) -> (result: bool = false, ok: bool) {
	switch s {
	case "1", "t", "T", "true", "TRUE", "True":
		if n != nil { n^ = len(s) }
		return true, true
	case "0", "f", "F", "false", "FALSE", "False":
		if n != nil { n^ = len(s) }
		return false, true
	}
	return
}

_digit_value :: proc(r: rune) -> int {
	ri := int(r)
	v: int = 16
	switch r {
	case '0'..='9': v = ri-'0'
	case 'a'..='z': v = ri-'a'+10
	case 'A'..='Z': v = ri-'A'+10
	}
	return v
}

// Parses an integer value from a string, in the given base, without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_i64_of_base("-1234eeee", 10);
// assert(n == -1234 && ok);
// ```
parse_i64_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: i64, ok: bool) {
	assert(base <= 16, "base must be 1-16")

	s := str

	defer if n != nil { n^ = len(str)-len(s) }

	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i64(_digit_value(r))
		if v >= i64(base) {
			break
		}
		value *= i64(base)
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}

// Parses a integer value from a string, in base 10, unless there's a prefix.
//
// Returns ok=false if a valid integer could not be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_i64_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_i64_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_i64_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: i64, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	base: i64 = 10
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i64(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}

parse_i64 :: proc{parse_i64_maybe_prefixed, parse_i64_of_base}

// Parses an unsigned integer value from a string, in the given base, and
// without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_u64_of_base("1234eeee", 10);
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u64_of_base("5678eeee", 16);
// assert(n == 0x5678eeee && ok);
// ```
parse_u64_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: u64, ok: bool) {
	assert(base <= 16, "base must be 1-16")
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u64(_digit_value(r))
		if v >= u64(base) {
			break
		}
		value *= u64(base)
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}

// Parses an unsigned integer value from a string in base 10, unless there's a prefix.
//
// Returns ok=false if a valid integer could not be found, if the value was negative,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_u64_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u64_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_u64_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: u64, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}


	base := u64(10)
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u64(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}

parse_u64 :: proc{parse_u64_maybe_prefixed, parse_u64_of_base}

// Parses an integer value from a string in the given base, or
// - if the string has a prefix (e.g: '0x') then that will determine the base;
// - otherwise, assumes base 10.
//
// Returns ok=false if no appropriate value could be found, or if the input string
// contained more than just the number.
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
parse_int :: proc(s: string, base := 0, n: ^int = nil) -> (value: int, ok: bool) {
	v: i64 = ---
	switch base {
	case 0:  v, ok = parse_i64_maybe_prefixed(s, n)
	case:    v, ok = parse_i64_of_base(s, base, n)
	}
	value = int(v)
	return
}


// Parses an unsigned integer value from a string in the given base, or
// - if the string has a prefix (e.g: '0x') then that will determine the base;
// - otherwise, assumes base 10.
//
// Returns ok=false if:
// - no appropriate value could be found; or
// - the value was negative.
// - the input string contained more than just the number.
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
parse_uint :: proc(s: string, base := 0, n: ^int = nil) -> (value: uint, ok: bool) {
	v: u64 = ---
	switch base {
	case 0:  v, ok = parse_u64_maybe_prefixed(s, n)
	case:    v, ok = parse_u64_of_base(s, base, n)
	}
	value = uint(v)
	return
}


// Parses an integer value from a string, in the given base, without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_i128_of_base("-1234eeee", 10);
// assert(n == -1234 && ok);
// ```
parse_i128_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: i128, ok: bool) {
	assert(base <= 16, "base must be 1-16")

	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i128(_digit_value(r))
		if v >= i128(base) {
			break
		}
		value *= i128(base)
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}

// Parses a integer value from a string, in base 10, unless there's a prefix.
//
// Returns ok=false if a valid integer could not be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_i128_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_i128_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_i128_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: i128, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	base: i128 = 10
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i128(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}

parse_i128 :: proc{parse_i128_maybe_prefixed, parse_i128_of_base}

// Parses an unsigned integer value from a string, in the given base, and
// without a prefix.
//
// Returns ok=false if no numeric value of the appropriate base could be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_u128_of_base("1234eeee", 10);
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u128_of_base("5678eeee", 16);
// assert(n == 0x5678eeee && ok);
// ```
parse_u128_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: u128, ok: bool) {
	assert(base <= 16, "base must be 1-16")
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u128(_digit_value(r))
		if v >= u128(base) {
			break
		}
		value *= u128(base)
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}

// Parses an unsigned integer value from a string in base 10, unless there's a prefix.
//
// Returns ok=false if a valid integer could not be found, if the value was negative,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_u128_maybe_prefixed("1234");
// assert(n == 1234 && ok);
//
// n, ok = strconv.parse_u128_maybe_prefixed("0xeeee");
// assert(n == 0xeeee && ok);
// ```
parse_u128_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: u128, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}


	base := u128(10)
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u128(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}

parse_u128 :: proc{parse_u128_maybe_prefixed, parse_u128_of_base}


@(private)
lower :: #force_inline proc "contextless" (ch: byte) -> byte { return ('a' - 'A') | ch }



// Parses a 32-bit floating point number from a string.
//
// Returns ok=false if a base 10 float could not be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_f32("12.34eee");
// assert(n == 12.34 && ok);
//
// n, ok = strconv.parse_f32("12.34");
// assert(n == 12.34 && ok);
// ```
parse_f32 :: proc(s: string, n: ^int = nil) -> (value: f32, ok: bool) {
	v: f64 = ---
	v, ok = parse_f64(s, n)
	return f32(v), ok
}

// Parses a 64-bit floating point number from a string.
//
// Returns ok=false if a base 10 float could not be found,
// or if the input string contained more than just the number.
//
// ```
// n, ok := strconv.parse_f32("12.34eee");
// assert(n == 12.34 && ok);
//
// n, ok = strconv.parse_f32("12.34");
// assert(n == 12.34 && ok);
// ```
parse_f64 :: proc(str: string, n: ^int = nil) -> (value: f64, ok: bool) {
	common_prefix_len_ignore_case :: proc "contextless" (s, prefix: string) -> int {
		n := len(prefix)
		if n > len(s) {
			n = len(s)
		}
		for i in 0..<n {
			c := s[i]
			if 'A' <= c && c <= 'Z' {
				c += 'a' - 'A'
			}
			if c != prefix[i] {
				return i
			}
		}
		return n
	}
	check_special :: proc "contextless" (s: string) -> (f: f64, n: int, ok: bool) {
		s := s
		if len(s) > 0 {
			sign := 1
			nsign := 0
			switch s[0] {
			case '+', '-':
				if s[0] == '-' {
					sign = -1
				}
				nsign = 1
				s = s[1:]
				fallthrough
			case 'i', 'I':
				n := common_prefix_len_ignore_case(s, "infinity")
				if 3 < n && n < 8 { // "inf" or "infinity"
					n = 3
				}
				if n == 3 || n == 8 {
					f = 0h7ff00000_00000000 if sign == 1 else 0hfff00000_00000000
					n = nsign + 3
					ok = true
					return
				}
			case 'n', 'N':
				if common_prefix_len_ignore_case(s, "nan") == 3 {
					f = 0h7ff80000_00000001
					n = nsign + 3
					ok = true
					return
				}
			}
		}
		return
	}
	parse_components :: proc "contextless" (s: string) -> (mantissa: u64, exp: int, neg, trunc, hex: bool, i: int, ok: bool) {
		if len(s) == 0 {
			return
		}
		switch s[i] {
		case '+': i += 1
		case '-': i += 1; neg = true
		}

		base := u64(10)
		MAX_MANT_DIGITS := 19
		exp_char := byte('e')
		// support stupid 0x1.ABp100 hex floats even if Odin doesn't
		if i+2 < len(s) && s[i] == '0' && lower(s[i+1]) == 'x' {
			base = 16
			MAX_MANT_DIGITS = 16
			i += 2
			exp_char = 'p'
			hex = true
		}

		underscores := false
		saw_dot, saw_digits := false, false
		nd := 0
		nd_mant := 0
		decimal_point := 0
		loop: for ; i < len(s); i += 1 {
			switch c := s[i]; true {
			case c == '_':
				underscores = true
				continue loop
			case c == '.':
				if saw_dot {
					break loop
				}
				saw_dot = true
				decimal_point = nd
				continue loop

			case '0' <= c && c <= '9':
				saw_digits = true
				if c == '0' && nd == 0 {
					decimal_point -= 1
					continue loop
				}
				nd += 1
				if nd_mant < MAX_MANT_DIGITS {
					mantissa *= base
					mantissa += u64(c - '0')
					nd_mant += 1
				} else if c != '0' {
					trunc = true
				}
				continue loop
			case base == 16 && 'a' <= lower(c) && lower(c) <= 'f':
				saw_digits = true
				nd += 1
				if nd_mant < MAX_MANT_DIGITS {
					MAX_MANT_DIGITS *= 16
					MAX_MANT_DIGITS += int(lower(c) - 'a' + 10)
					nd_mant += 1
				} else {
					trunc = true
				}
				continue loop
			}
			break loop
		}

		if !saw_digits {
			return
		}
		if !saw_dot {
			decimal_point = nd
		}
		if base == 16 {
			decimal_point *= 4
			nd_mant *= 4
		}

		if i < len(s) && lower(s[i]) == exp_char {
			i += 1
			if i >= len(s) { return }
			exp_sign := 1
			switch s[i] {
			case '+': i += 1
			case '-': i += 1; exp_sign = -1
			}
			if i >= len(s) || s[i] < '0' || s[i] > '9' {
				return
			}
			e := 0
			for ; i < len(s) && ('0' <= s[i] && s[i] <= '9' || s[i] == '_'); i += 1 {
				if s[i] == '_' {
					underscores = true
					continue
				}
				if e < 1e5 {
					e = e*10 + int(s[i]) - '0'
				}
			}
			decimal_point += e * exp_sign
		} else if base == 16 {
			return
		}

		if mantissa != 0 {
			exp = decimal_point - nd_mant
		}
		// TODO(bill): check underscore correctness
		ok = true
		return
	}

	parse_hex :: proc(s: string, mantissa: u64, exp: int, neg, trunc: bool) -> (f64, bool) {
		info := &_f64_info

		mantissa, exp := mantissa, exp

		MAX_EXP := 1<<info.expbits + info.bias - 2
		MIN_EXP := info.bias + 1
		exp += int(info.mantbits)

		for mantissa != 0 && mantissa >> (info.mantbits+2) == 0 {
			mantissa <<= 1
			exp -= 1
		}
		if trunc {
			mantissa |= 1
		}

		for mantissa >> (info.mantbits+2) == 0 {
			mantissa = mantissa>>1 | mantissa&1
			exp += 1
		}

		// denormalize
		if mantissa > 1 && exp < MIN_EXP-2 {
			mantissa = mantissa>>1 | mantissa&1
			exp += 1
		}

		round := mantissa & 3
		mantissa >>= 2
		round |= mantissa & 1 // round to even
		exp += 2
		if round == 3 {
			mantissa += 1
			if mantissa == 1 << (1 + info.mantbits) {
				mantissa >>= 1
				exp += 1
			}
		}
		if mantissa>>info.mantbits == 0 {
			// zero or denormal
			exp = info.bias
		}

		ok := true
		if exp > MAX_EXP {
			// infinity or invalid
			mantissa = 1<<info.mantbits
			exp = MAX_EXP + 1
			ok = false
		}

		bits := mantissa & (1<<info.mantbits - 1)
		bits |= u64((exp-info.bias) & (1<<info.expbits - 1)) << info.mantbits
		if neg {
			bits |= 1 << info.mantbits << info.expbits
		}
		return transmute(f64)bits, ok
	}


	nr: int
	defer if n != nil { n^ = nr }

	if value, nr, ok = check_special(str); ok {
		return
	}

	mantissa: u64
	exp:      int
	neg, trunc, hex: bool
	mantissa, exp, neg, trunc, hex, nr = parse_components(str) or_return

	if hex {
		return parse_hex(str, mantissa, exp, neg, trunc)
	}

	trunc_block: if !trunc {
		@static pow10 := [?]f64{
			1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,  1e8,  1e9,
			1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
			1e20, 1e21, 1e22,
		}

		if mantissa>>_f64_info.mantbits != 0 {
			break trunc_block
		}
		f := f64(mantissa)
		if neg {
			f = -f
		}
		switch {
		case exp == 0:
			return f, true
		case exp > 0 && exp <= 15+22:
			if exp > 22 {
				f *= pow10[exp-22]
				exp = 22
			}
			if f > 1e15 || f < 1e-15 {
				break trunc_block
			}
			return f * pow10[exp], true
		case -22 <= exp && exp < 0:
			return f / pow10[-exp], true
		}
	}

	// Solve import cycle
	clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> cstring {
		c := make([]byte, len(s)+1, allocator, loc)
		copy(c, s)
		c[len(s)] = 0
		return cstring(&c[0])
	}

	cstr := clone_to_cstring(s=str, allocator=context.temp_allocator)
	return libc.strtod(cstr, nil), true

	// d: decimal.Decimal
	// decimal.set(&d, str[:nr])
	// b, overflow := decimal_to_float_bits(&d, &_f64_info)
	// value = transmute(f64)b
	// ok = !overflow
	// return
}

append_bool :: proc(buf: []byte, b: bool) -> string {
	n := 0
	if b {
		n = copy(buf, "true")
	} else {
		n = copy(buf, "false")
	}
	return string(buf[:n])
}

append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	return append_bits(buf, u, base, false, 8*size_of(uint), digits, nil)
}
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return append_bits(buf, u64(i), base, true, 8*size_of(int), digits, nil)
}

itoa :: proc(buf: []byte, i: int) -> string {
	return append_int(buf, i64(i), 10)
}
atoi :: proc(s: string) -> int {
	v, _ := parse_int(s)
	return v
}
atof :: proc(s: string) -> f64 {
	v, _  := parse_f64(s)
	return v
}

ftoa :: append_float
append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size))
}


quote :: proc(buf: []byte, str: string) -> string {
	write_byte :: proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ >= len(buf) {
			return
		}
		n := copy(buf[i^:], bytes[:])
		i^ += n
	}

	if buf == nil {
		return ""
	}

	c :: '"'
	i := 0
	s := str

	write_byte(buf, &i, c)
	for width := 0; len(s) > 0; s = s[width:] {
		r := rune(s[0])
		width = 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			write_byte(buf, &i, '\\', 'x')
			write_byte(buf, &i, digits[s[0]>>4])
			write_byte(buf, &i, digits[s[0]&0xf])
		}
		if i < len(buf) {
			x := quote_rune(buf[i:], r)
			i += len(x)
		}
	}
	write_byte(buf, &i, c)
	return string(buf[:i])
}

quote_rune :: proc(buf: []byte, r: rune) -> string {
	write_byte :: proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ < len(buf) {
			n := copy(buf[i^:], bytes[:])
			i^ += n
		}
	}
	write_string :: proc(buf: []byte, i: ^int, s: string) {
		if i^ < len(buf) {
			n := copy(buf[i^:], s)
			i^ += n
		}
	}
	write_rune :: proc(buf: []byte, i: ^int, r: rune) {
		if i^ < len(buf) {
			b, w := utf8.encode_rune(r)
			n := copy(buf[i^:], b[:w])
			i^ += n
		}
	}

	if buf == nil {
		return ""
	}

	i := 0
	write_byte(buf, &i, '\'')

	switch r {
	case '\a': write_string(buf, &i, "\\a")
	case '\b': write_string(buf, &i, "\\b")
	case '\e': write_string(buf, &i, "\\e")
	case '\f': write_string(buf, &i, "\\f")
	case '\n': write_string(buf, &i, "\\n")
	case '\r': write_string(buf, &i, "\\r")
	case '\t': write_string(buf, &i, "\\t")
	case '\v': write_string(buf, &i, "\\v")
	case:
		if r < 32 {
			write_string(buf, &i, "\\x")
			b: [2]byte
			s := append_bits(b[:], u64(r), 16, true, 64, digits, nil)
			switch len(s) {
			case 0: write_string(buf, &i, "00")
			case 1: write_rune(buf, &i, '0')
			case 2: write_string(buf, &i, s)
			}
		} else {
			write_rune(buf, &i, r)
		}
	}
	write_byte(buf, &i, '\'')

	return string(buf[:i])
}




unquote_char :: proc(str: string, quote: byte) -> (r: rune, multiple_bytes: bool, tail_string: string, success: bool) {
	hex_to_int :: proc(c: byte) -> int {
		switch c {
		case '0'..='9': return int(c-'0')
		case 'a'..='f': return int(c-'a')+10
		case 'A'..='F': return int(c-'A')+10
		}
		return -1
	}
	w: int

	if str[0] == quote && quote == '"' {
		return
	} else if str[0] >= 0x80 {
		r, w = utf8.decode_rune_in_string(str)
		return r, true, str[w:], true
	} else if str[0] != '\\' {
		return rune(str[0]), false, str[1:], true
	}

	if len(str) <= 1 {
		return
	}
	s := str
	c := s[1]
	s = s[2:]

	switch c {
	case:
		return

	case 'a':  r = '\a'
	case 'b':  r = '\b'
	case 'f':  r = '\f'
	case 'n':  r = '\n'
	case 'r':  r = '\r'
	case 't':  r = '\t'
	case 'v':  r = '\v'
	case '\\': r = '\\'

	case '"':  r = '"'
	case '\'': r = '\''

	case '0'..='7':
		v := int(c-'0')
		if len(s) < 2 {
			return
		}
		for i in 0..<len(s) {
			d := int(s[i]-'0')
			if d < 0 || d > 7 {
				return
			}
			v = (v<<3) | d
		}
		s = s[2:]
		if v > 0xff {
			return
		}
		r = rune(v)

	case 'x', 'u', 'U':
		count: int
		switch c {
		case 'x': count = 2
		case 'u': count = 4
		case 'U': count = 8
		}

		if len(s) < count {
			return
		}

		for i in 0..<count {
			d := hex_to_int(s[i])
			if d < 0 {
				return
			}
			r = (r<<4) | rune(d)
		}
		s = s[count:]
		if c == 'x' {
			break
		}
		if r > utf8.MAX_RUNE {
			return
		}
		multiple_bytes = true
	}

	success = true
	tail_string = s
	return
}

unquote_string :: proc(lit: string, allocator := context.allocator) -> (res: string, allocated, success: bool) {
	contains_rune :: proc(s: string, r: rune) -> int {
		for c, offset in s {
			if c == r {
				return offset
			}
		}
		return -1
	}

	if len(lit) < 2 {
		return
	}
	if lit[0] == '`' {
		return lit[1:len(lit)-1], false, true
	}

	s := lit
	quote := '"'

	if s == `""` {
		return "", false, true
	}
	s = s[1:len(s)-1]

	if contains_rune(s, '\n') >= 0 {
		return s, false, false
	}

	if contains_rune(s, '\\') < 0 && contains_rune(s, quote) < 0 {
		if quote == '"' {
			return s, false, true
		}
	}
	
	context.allocator = allocator

	buf_len := 3*len(s) / 2
	buf := make([]byte, buf_len)
	offset := 0
	for len(s) > 0 {
		r, multiple_bytes, tail_string, ok := unquote_char(s, byte(quote))
		if !ok {
			delete(buf)
			return s, false, false
		}
		s = tail_string
		if r < 0x80 || !multiple_bytes {
			buf[offset] = byte(r)
			offset += 1
		} else {
			b, w := utf8.encode_rune(r)
			copy(buf[offset:], b[:w])
			offset += w
		}
	}

	new_string := string(buf[:offset])

	return new_string, true, true
}
