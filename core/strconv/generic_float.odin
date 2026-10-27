package strconv

import "decimal"

Decimal_Slice :: struct {
	digits:        []byte,
	count:         int,
	decimal_point: int,
	neg:           bool,
}

Float_Info :: struct {
	mantbits: uint,
	expbits:  uint,
	bias:     int,
}


_f16_info := Float_Info{10, 5,   -15}
_f32_info := Float_Info{23, 8,  -127}
_f64_info := Float_Info{52, 11, -1023}

/*
Converts a floating-point number to a string with the specified format and precision.

**Inputs**

buf: A byte slice to store the resulting string
val: The floating-point value to be converted
fmt: The formatting byte, accepted values are 'e', 'E', 'f', 'F', 'g', 'G'
precision: The number of decimal places to round to
bit_size: The size of the floating-point number in bits, valid values are 16, 32, 64

Example:

	buf: [32]byte
	val := 3.141592
	fmt := 'f'
	precision := 2
	bit_size := 64
	result := strconv.generic_ftoa(buf[:], val, fmt, precision, bit_size) -> "3.14"

**Returns**
- A byte slice containing the formatted string
*/
generic_ftoa :: proc(buf: []byte, val: f64, fmt: byte, precision, bit_size: int) -> []byte {
	when FAST_FLOAT {
		if bit_size == 64 {
			if res, ok := _ftoa_fast(buf, val, fmt, precision); ok {
				return res
			}
		} else if bit_size == 32 || (bit_size == 16 && precision >= 0) {
			f := f32(f16(val)) if bit_size == 16 else f32(val)
			if res, ok := _ftoa_fast(buf, f, fmt, precision); ok {
				return res
			}
		} else if bit_size == 16 {
			if res, ok := _ftoa_fast_f16(buf, f16(val), fmt); ok {
				return res
			}
		}
	}

	bits: u64
	flt: ^Float_Info
	switch bit_size {
	case 16:
		bits = u64(transmute(u16)f16(val))
		flt = &_f16_info
	case 32:
		bits = u64(transmute(u32)f32(val))
		flt = &_f32_info
	case 64:
		bits = transmute(u64)val
		flt = &_f64_info
	case:
		panic("strconv: invalid bit_size")
	}

	neg  := bits>>(flt.expbits+flt.mantbits) != 0
	exp  := int(bits>>flt.mantbits) & (1<<flt.expbits - 1)
	mant := bits & (u64(1) << flt.mantbits - 1)

	switch exp {
	case 1<<flt.expbits - 1:
		return _format_inf_nan(buf, neg, mant != 0)

	case 0: // denormalized
		exp += 1

	case:
		mant |= u64(1) << flt.mantbits
	}

	exp += flt.bias

	d_: decimal.Decimal
	d := &d_
	decimal.assign(d, mant)
	decimal.shift(d, exp - int(flt.mantbits))
	digs: Decimal_Slice
	prec := precision
	shortest := prec < 0
	if shortest {
		round_shortest(d, mant, exp, flt)
		digs = Decimal_Slice{digits = d.digits[:], count = d.count, decimal_point = d.decimal_point}
		prec = _shortest_precision(digs, fmt)
	} else {
		switch fmt {
		case 'e', 'E':
			decimal.round(d, prec + 1)
		case 'f', 'F':
			decimal.round(d, d.decimal_point+prec)
		case 'g', 'G':
			if prec == 0 {
				prec = 1
			}
			decimal.round(d, prec)
		}

		digs = Decimal_Slice{digits = d.digits[:], count = d.count, decimal_point = d.decimal_point}
	}
	return format_digits(buf, shortest, neg, digs, prec, fmt)
}

_format_inf_nan :: proc "contextless" (buf: []byte, neg, nan: bool) -> []byte {
	s := "NaN" if nan else "-Inf" if neg else "+Inf"
	return buf[:copy(buf, s)]
}

_shortest_precision :: proc "contextless" (digs: Decimal_Slice, fmt: byte) -> int {
	switch fmt {
	case 'e', 'E': return digs.count-1
	case 'f', 'F': return max(digs.count-digs.decimal_point, 0)
	case 'g', 'G': return digs.count
	}
	return -1
}

// Picks scientific 'e' or fixed 'f' notation for 'g', and its precision, as C's %g does.
_choose_g :: #force_inline proc "contextless" (digs: Decimal_Slice, prec: int, shortest: bool, fmt: byte) -> (new_prec: int, new_fmt: byte) {
	exp := digs.decimal_point - 1
	if exp < -4 || exp >= (6 if shortest else prec) {
		return min(prec, digs.count) - 1, fmt + 'e' - 'g'
	}
	p := digs.count if prec > digs.decimal_point else prec
	return max(p - digs.decimal_point, 0), 'f'
}

/*
Converts a decimal floating-point number into a byte buffer with the given format

**Inputs**
- buf: The byte buffer to store the formatted number
- shortest: If true, generates the shortest representation of the number
- neg: If true, the number is negative
- digs: The decimal number to be formatted
- precision: The number of digits after the decimal point
- fmt: The format specifier (accepted values: 'f', 'F', 'e', 'E', 'g', 'G')

**Returns**
- A byte slice containing the formatted decimal floating-point number
*/
format_digits :: proc(buf: []byte, shortest: bool, neg: bool, digs: Decimal_Slice, precision: int, fmt: byte) -> []byte {
	Buffer :: struct {
		b: []byte,
		n: int,
	}

	to_bytes :: proc(b: Buffer) -> []byte {
		return b.b[:b.n]
	}
	add_byte :: proc(buf: ^Buffer, c: byte) {
		if buf.n < len(buf.b) {
			buf.b[buf.n] = c
			buf.n += 1
		}
	}
	add_zeros :: proc(buf: ^Buffer, count: int) {
		n := clamp(count, 0, len(buf.b) - buf.n)
		for &c in buf.b[buf.n:][:n] {
			c = '0'
		}
		buf.n += n
	}

	b := Buffer{b = buf}
	prec := precision

	switch fmt {
	case 'f', 'F', 'e', 'E':
		prec = min(prec, len(buf)) // clamp to buffer length
	}

	switch fmt {
	case 'f', 'F':
		add_byte(&b, '-' if neg else '+')

		// integer, padded with zeros when needed
		if digs.decimal_point > 0 {
			m := min(digs.count, digs.decimal_point)
			b.n += copy(buf[b.n:], digs.digits[0:m])
			add_zeros(&b, digs.decimal_point - m)
		} else {
			add_byte(&b, '0')
		}


		// fractional part
		if prec > 0 {
			add_byte(&b, '.')
			lead := clamp(-digs.decimal_point, 0, prec)
			add_zeros(&b, lead)
			lo := min(max(digs.decimal_point, 0), digs.count)
			hi := max(min(digs.count, digs.decimal_point + prec), lo)
			b.n += copy(buf[b.n:], digs.digits[lo:hi])
			add_zeros(&b, prec - lead - (hi - lo))
		}
		return to_bytes(b)

	case 'e', 'E':
		add_byte(&b, '-' if neg else '+')

		ch := byte('0')
		if digs.count != 0 {
			ch = digs.digits[0]
		}
		add_byte(&b, ch)

		if prec > 0 {
			add_byte(&b, '.')
			i := 1
			m := min(digs.count, prec+1)
			if i < m {
				b.n += copy(buf[b.n:], digs.digits[i:m])
				i = m
			}
			add_zeros(&b, prec + 1 - i)
		}

		add_byte(&b, fmt)
		exp := digs.decimal_point-1
		if digs.count == 0 {
			// Zero has exponent of 0
			exp = 0
		}

		ch = '+'
		if exp < 0 {
			ch = '-'
			exp = -exp
		}
		add_byte(&b, ch)

		if exp >= 100 {
			add_byte(&b, byte(exp/100)+'0')
		}
		add_byte(&b, byte(exp/10)%10+'0') // at least two digits
		add_byte(&b, byte(exp%10)+'0')

		return to_bytes(b)

	case 'g', 'G':
		p, f := _choose_g(digs, prec, shortest, fmt)
		return format_digits(buf, shortest, neg, digs, p, f)

	case:
		add_byte(&b, '%')
		add_byte(&b, fmt)
		return to_bytes(b)
	}


}
/*
Rounds the given decimal number to its shortest representation, considering the provided floating-point format

**Inputs**
- d: The decimal number to round
- mant: The mantissa of the floating-point number
- exp: The exponent of the floating-point number
- flt: Pointer to the Float_Info structure containing information about the floating-point format
*/
round_shortest :: proc(d: ^decimal.Decimal, mant: u64, exp: int, flt: ^Float_Info) {
	if mant == 0 { // If mantissa is zero, the number is zero
		d.count = 0
		return
	}

	/*
		10^(dp-nd) > 2^(exp-mantbits)
		log2(10) * (dp-nd) > exp-mantbits
		log(2) >~ 0.332
		332*(dp-nd) >= 100*(exp-mantbits)
	 */
	minexp := flt.bias+1
	if exp > minexp && 332*(d.decimal_point-d.count) >= 100*(exp - int(flt.mantbits)) {
		// Number is already its shortest
		return
	}

	upper_: decimal.Decimal; upper := &upper_
	decimal.assign(upper, 2*mant + 1)
	decimal.shift(upper, exp - int(flt.mantbits) - 1)

	mantlo: u64
	explo:  int
	if mant > 1<<flt.mantbits || exp == minexp {
		mantlo = mant-1
		explo = exp
	} else {
		mantlo = 2*mant - 1
		explo = exp-1
	}
	lower_: decimal.Decimal; lower := &lower_
	decimal.assign(lower, 2*mantlo + 1)
	decimal.shift(lower, explo - int(flt.mantbits) - 1)

	inclusive := mant%2 == 0

	// upper_delta tells if rounding d up stays below upper, with 0 equal, 1 one unit above and 2 more
	upper_delta: u8
	for ui := 0; ; ui += 1 {
		i := ui - upper.decimal_point + d.decimal_point
		if i >= d.count {
			break
		}
		li := ui - upper.decimal_point + lower.decimal_point
		l: byte = '0' // lower digit
		if li >= 0 && li < lower.count {
			l = lower.digits[li]
		}
		m: byte = '0' // middle digit
		if i >= 0 {
			m = d.digits[i]
		}
		u: byte = '0' // upper digit
		if ui < upper.count {
			u = upper.digits[ui]
		}

		ok_round_down := l != m || inclusive && li+1 == lower.count

		switch {
		case upper_delta == 0 && m+1 < u:
			upper_delta = 2
		case upper_delta == 0 && m != u:
			upper_delta = 1
		case upper_delta == 1 && (m != '9' || u != '0'):
			upper_delta = 2
		}
		ok_round_up := upper_delta > 0 && (inclusive || upper_delta > 1 || ui+1 < upper.count)

		if ok_round_down && ok_round_up {
			decimal.round(d, i+1)
			return
		}
		if ok_round_down {
			decimal.round_down(d, i+1)
			return
		}
		if ok_round_up {
			decimal.round_up(d, i+1)
			return
		}
	}

}
/*
Converts a decimal number to its floating-point representation with the given format and returns the resulting bits

**Inputs**
- d: Pointer to the decimal number to convert
- info: Pointer to the Float_Info structure containing information about the floating-point format

**Returns**
- b: The bits representing the floating-point number
- overflow: A boolean indicating whether an overflow occurred during conversion
*/
decimal_to_float_bits :: proc(d: ^decimal.Decimal, info: ^Float_Info) -> (b: u64, overflow: bool) {
	overflow_end :: proc "contextless" (d: ^decimal.Decimal, info: ^Float_Info) -> (u64, bool) {
		mant: u64 = 0
		exp:  int = 1<<info.expbits - 1 + info.bias
		return end(d, mant, exp, info, true)
	}
	end :: proc "contextless" (d: ^decimal.Decimal, mant: u64, exp: int, info: ^Float_Info, is_overflow: bool) -> (bits: u64, overflow: bool) {
		bits = mant & (u64(1)<<info.mantbits - 1)
		bits |= u64((exp-info.bias) & (1<<info.expbits - 1)) << info.mantbits
		if d.neg {
			bits |= 1 << info.mantbits << info.expbits
		}
		overflow = is_overflow
		return
	}

	if d.count == 0 {
		return end(d, 0, info.bias, info, false)
	}


	if d.decimal_point > 310 {
		return overflow_end(d, info)
	} else if d.decimal_point < -330 {
		return end(d, 0, info.bias, info, false)
	}

	@(static, rodata) power_table := [?]int{1, 3, 6, 9, 13, 16, 19, 23, 26}


	exp := 0
	for d.decimal_point > 0 {
		n := 27 if d.decimal_point >= len(power_table) else power_table[d.decimal_point]
		decimal.shift(d, -n)
		exp += n
	}
	for d.decimal_point < 0 || d.decimal_point == 0 && d.digits[0] < '5' {
		n := 27 if -d.decimal_point >= len(power_table) else power_table[-d.decimal_point]
		decimal.shift(d, n)
		exp -= n
	}

	// go from [0.5, 1) to [1, 2)
	exp -= 1

	// Min rep exp is 1+bias
	if exp < info.bias + 1 {
		n := info.bias + 1 - exp
		decimal.shift(d, -n)
		exp += n
	}

	if (exp-info.bias) >= (1<<info.expbits - 1) {
		return overflow_end(d, info)
	}

	// Extract 1 + mantbits
	decimal.shift(d, int(1 + info.mantbits))
	mant := decimal.rounded_integer(d)

	// Rounding for shift down
	if mant == 2<<info.mantbits {
		mant >>= 1
		exp += 1
		if (exp-info.bias) >= (1<<info.expbits - 1) {
			return overflow_end(d, info)
		}
	}

	// Check for denormalized mantissa
	if mant & (1<<info.mantbits) == 0 {
		exp = info.bias
	}

	return end(d, mant, exp, info, false)
}
