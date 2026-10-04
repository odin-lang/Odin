package strconv

import "base:intrinsics"

/*
Scans a hexadecimal floating-point number at the start of `s`.
`[+-] 0x hexdigits [. hexdigits] (p|P) [+-] digits`
A `_` between digits is skipped

**Returns**
- mantissa, exp: The value is `mantissa * 2^exp`. If `trunc` is true, the significant hex digits after the first 16 were dropped, and at least one of them was not zero.
- neg: The number has a minus sign.
- nr: The number of bytes in the number.
- ok: `false` if `s` does not start with a hexadecimal float.
*/
scan_hex_float :: proc "contextless" (s: string) -> (mantissa: u64, exp: int, neg, trunc: bool, nr: int, ok: bool) #no_bounds_check {
	MAX_HEX_DIGITS :: 16

	n := len(s)
	if n == 0 {
		return
	}
	neg = s[0] == '-'
	i := int(neg || s[0] == '+')
	// "0x" is a hex prefix only if another byte follows it.
	if !(i+2 < n && s[i] == '0' && lower(s[i+1]) == 'x') {
		return
	}
	i += 2

	nd := 0 // number of significant hex digits in the mantissa
	saw_digits := false

	// Integer part. Leading zeros do not count as significant digits.
	for i < n && (s[i] == '0' || s[i] == '_') {
		saw_digits ||= s[i] == '0'
		i += 1
	}
	for i+8 <= n && nd+8 <= MAX_HEX_DIGITS {
		v := read8_to_u64(s, i)
		if !is_eight_hex_digits(v) {
			break
		}
		mantissa = mantissa<<32 | parse_eight_hex_digits(v)
		nd += 8
		i += 8
		saw_digits = true
	}
	for i < n {
		d := hex_digit_table[s[i]]
		if d >= 16 {
			if s[i] != '_' {
				break
			}
		} else if nd < MAX_HEX_DIGITS {
			mantissa = mantissa<<4 | u64(d)
			nd += 1
			saw_digits = true
		} else {
			exp += 4 // dropped digit
			trunc ||= d != 0
		}
		i += 1
	}

	// Fraction part
	if i < n && s[i] == '.' {
		i += 1
		if mantissa == 0 {
			// Leading zeros of the fraction change only the exponent
			for i < n && (s[i] == '0' || s[i] == '_') {
				if s[i] == '0' {
					exp -= 4
					saw_digits = true
				}
				i += 1
			}
		}
		for i+8 <= n && nd+8 <= MAX_HEX_DIGITS {
			v := read8_to_u64(s, i)
			if !is_eight_hex_digits(v) {
				break
			}
			mantissa = mantissa<<32 | parse_eight_hex_digits(v)
			nd += 8
			exp -= 32
			i += 8
			saw_digits = true
		}
		if i+4 <= n && nd+4 <= MAX_HEX_DIGITS {
			// Four digits: pad them with "0000" and use the 8-digit code.
			v := u64(read4_to_u32(s, i)) | 0x3030_3030 << 32
			if is_eight_hex_digits(v) {
				mantissa = mantissa<<16 | parse_eight_hex_digits(v) >> 16
				nd += 4
				exp -= 16
				i += 4
				saw_digits = true
			}
		}
		for i < n {
			d := hex_digit_table[s[i]]
			if d >= 16 {
				if s[i] != '_' {
					break
				}
			} else if mantissa == 0 && d == 0 {
				exp -= 4 // a leading zero of the fraction
				saw_digits = true
			} else if nd < MAX_HEX_DIGITS {
				mantissa = mantissa<<4 | u64(d)
				nd += 1
				exp -= 4
				saw_digits = true
			} else {
				trunc ||= d != 0 // dropped digit
				saw_digits = true
			}
			i += 1
		}
	}
	if !saw_digits {
		return
	}

	// The binary exponent is required. The first byte after `p` and the sign must be a digit.
	if !(i < n && lower(s[i]) == 'p') {
		return
	}
	i += 1
	exp_neg := false
	if i < n && (s[i] == '+' || s[i] == '-') {
		exp_neg = s[i] == '-'
		i += 1
	}
	if i >= n || s[i] - '0' > 9 {
		return
	}
	x := 0
	for i < n && (s[i] - '0' <= 9 || s[i] == '_') {
		if s[i] != '_' && x < 100_000 { // larger exponents overflow or underflow anyway
			x = x*10 + int(s[i] - '0')
		}
		i += 1
	}
	exp += -x if exp_neg else x

	if mantissa == 0 {
		exp = 0
		trunc = false
	}
	nr, ok = i, true
	return
}

/*
Converts `mantissa * 2^exp` to the bits of the float type that `info` describes, rounded to
nearest, ties to even. `trunc` means that the exact value is a little larger than
`mantissa * 2^exp` (nonzero digits were dropped).

**Returns**
- float_bits: The bits of the float, with the sign.
- ok: `false` if the value overflows. Then `float_bits` is infinity.
*/
hex_float_bits :: proc "contextless" (mantissa: u64, exp: int, neg, trunc: bool, info: ^Float_Info) -> (float_bits: u64, ok: bool) {
	M := int(info.mantbits)
	sign := u64(neg) << info.mantbits << info.expbits
	if mantissa == 0 {
		return sign, true
	}

	// Normalize: the top bit of m is set, so the value is in [2^(e+63), 2^(e+64)).
	lz := intrinsics.count_leading_zeros(mantissa)
	m := mantissa << lz
	e := exp - int(lz)

	biased := e + 63 - info.bias // the biased exponent of a normal result
	shift := 63 - M              // keep M+1 bits for a normal result
	if biased < 1 {
		// Subnormal: keep fewer bits.
		shift += 1 - biased
		biased = 0
	}

	// Round to nearest, ties to even. `trunc` is a sticky bit below all bits of m.
	kept, rest, half: u64
	switch {
	case shift < 64:
		kept = m >> uint(shift)
		rest = m & (1<<uint(shift) - 1)
		half = 1 << uint(shift - 1)
	case shift == 64:
		rest = m
		half = 1 << 63
	case:
		return sign, true // less than half of the smallest subnormal
	}
	if rest > half || (rest == half && (trunc || kept & 1 == 1)) {
		kept += 1
	}

	if biased == 0 {
		// Subnormal
		return sign | kept, true
	}
	if kept == 1 << uint(M+1) {
		kept >>= 1
		biased += 1
	}
	if biased >= 1<<info.expbits - 1 {
		return sign | u64(1<<info.expbits - 1) << info.mantbits, false
	}
	return sign | u64(biased) << info.mantbits | kept & (1<<info.mantbits - 1), true
}

// NOTE(MatthiasH): direct lookup was always faster in benchmarks
@(rodata)
hex_digit_table := [256]u8{
	0..<'0' = 0xff, ':'..<'A' = 0xff, 'G'..<'a' = 0xff, 'g'..=255 = 0xff,
	'0' =  0, '1' =  1, '2' =  2, '3' =  3, '4' =  4,
	'5' =  5, '6' =  6, '7' =  7, '8' =  8, '9' =  9,
	'a' = 10, 'b' = 11, 'c' = 12, 'd' = 13, 'e' = 14, 'f' = 15,
	'A' = 10, 'B' = 11, 'C' = 12, 'D' = 13, 'E' = 14, 'F' = 15,
}

is_eight_hex_digits :: #force_inline proc "contextless" (v: u64) -> bool {
	ONES :: 0x0101_0101_0101_0101
	HIGH :: 0x8080_8080_8080_8080
	in_range :: #force_inline proc "contextless" (v: u64, $lo, $hi: u64) -> u64 {
		return (v + (0x80 - lo)*ONES) &~ (v + (0x7f - hi)*ONES)
	}
	digit  := in_range(v, '0', '9')
	letter := in_range(v | 0x20*ONES, 'a', 'f')
	return (digit | letter) &~ v & HIGH == HIGH
}

parse_eight_hex_digits :: #force_inline proc "contextless" (v: u64) -> u64 {
	x := (v & 0x0f0f_0f0f_0f0f_0f0f) + ((v >> 6) & 0x0101_0101_0101_0101) * 9
	x = ((x << 4) + (x >> 8)) & 0x00ff_00ff_00ff_00ff
	x = ((x << 8) + (x >> 16)) & 0x0000_ffff_0000_ffff
	return ((x << 16) + (x >> 32)) & 0xffff_ffff
}
