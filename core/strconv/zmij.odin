package strconv

// Float formatting with Żmij. It gives the shortest round-trip output of f32 and f64, and output
// with a precision for up to 18 significant digits.
// Made available under the Boost Software License 1.0,
// 	see LICENSE at the bottom of the file.

import "base:runtime"
import "core:math/bits"

/*
Computes the shortest decimal digits that parse back to the float with the given bits.
If several are equally short, it returns the one closest to the exact value.

**Inputs**
- buf: Storage for the digits, at least 40 bytes
- mant: The significand, with the implicit bit set for normal numbers
- exp: The biased exponent, 1 for subnormal numbers
- MANTBITS: 52 for f64, 23 for f32, 10 for f16

**Returns**
- The digits, without leading or trailing zeros. Zero gives no digits.
  The 16 bytes after the digits in `buf` are '0'.
*/
_shortest_decimal :: #force_inline proc "contextless" (buf: []byte, mant: u64, exp: int, $MANTBITS: uint) -> Decimal_Slice {
	if mant == 0 {
		_store_zeros16(buf, 0)
		return {digits = buf[:0]}
	}
	// The significand of a power of two has a closer lower neighbor.
	regular := mant != 1 << MANTBITS

	sig, last_digit: u64
	dec_exp: int
	has_last_digit: bool
	when MANTBITS == 52 { // f64
		sig, dec_exp, last_digit, has_last_digit = _to_decimal_f64(mant, exp - 1075, regular)
	} else when MANTBITS == 23 { // f32
		sig, dec_exp, last_digit, has_last_digit = _to_decimal_f32(mant, exp - 150, regular)
	} else { // f16
		sig, dec_exp, last_digit, has_last_digit = _to_decimal_f32(mant, exp - 25, regular)
	}

	// Write `sig` as 16 digits for f64 or 8 for f32, with leading zeros, then the extra digit.
	start, end, n: int
	when MANTBITS == 52 {
		// sig < 10^16, so hi and lo have at most 8 digits each.
		hi := _div_1e8(sig)
		lo := sig - hi*100_000_000
		bcd_hi := _to_bcd8(hi)
		bcd_lo := _to_bcd8(lo)
		_store_digits8(buf, 0, bcd_hi)
		_store_digits8(buf, 8, bcd_lo)
		n = 16

		// Selects, not branches, as has_last_digit is unpredictable. clz and ctz of 0 are 64.
		start_hi := int(bits.count_leading_zeros(bcd_hi) >> 3)
		start_lo := 8 + int(bits.count_leading_zeros(bcd_lo) >> 3)
		start = start_hi if bcd_hi != 0 else start_lo
		end_lo := 16 - int(bits.count_trailing_zeros(bcd_lo) >> 3)
		end_hi := 8 - int(bits.count_trailing_zeros(bcd_hi) >> 3)
		end = end_lo if bcd_lo != 0 else end_hi
		end = n + 1 if has_last_digit && last_digit != 0 else end
	} else {
		// sig < 10^8
		bcd := _to_bcd8(sig)
		_store_digits8(buf, 0, bcd)
		n = 8

		start = int(bits.count_leading_zeros(bcd) >> 3)
		end = 8 - int(bits.count_trailing_zeros(bcd) >> 3)
		end = n + 1 if has_last_digit && last_digit != 0 else end
	}
	buf[n] = '0' + byte(last_digit)
	// With the last digit, the value is (sig*10 + last_digit) * 10^dec_exp,
	// otherwise sig * 10^(dec_exp+1).
	n += int(has_last_digit)
	dec_exp += int(!has_last_digit)
	_store_zeros16(buf, end)

	return {
		digits        = buf[start:end],
		count         = end - start,
		decimal_point = n - start + dec_exp,
	}
}

// Converts a binary FP number bin_sig * 2^bin_exp to the shortest decimal representation.
_to_decimal_f64 :: #force_inline proc "contextless" (bin_sig: u64, bin_exp: int, regular: bool) -> (sig: u64, dec_exp: int, last_digit: u64, has_last_digit: bool) {
	if !regular {
		return _to_decimal_irregular(bin_sig, bin_exp)
	}
	EXTRA_SHIFT :: 6

	dec_exp = _compute_dec_exp(bin_exp, true)
	shift := uint(_compute_exp_shift(bin_exp, dec_exp + 1) + EXTRA_SHIFT)
	even := 1 - (bin_sig & 1)

	// An optimization by Xiang JunBo
	pow10_hi, pow10_lo := _pow10_significand(-dec_exp - 1)
	p_hi, p_lo := _umul192_hi128(pow10_hi, pow10_lo, bin_sig << shift)

	integral   := p_hi >> EXTRA_SHIFT
	fractional := p_hi << (64 - EXTRA_SHIFT) | p_lo >> EXTRA_SHIFT

	half_ulp   := pow10_hi >> (EXTRA_SHIFT + 1 - shift) + even
	round_up   := fractional + half_ulp < fractional
	round_down := half_ulp > fractional
	integral += u64(round_up) // Compute integral before digit.

	// Derive the extra digit from the fractional part, in parallel with rounding.
	// +6 is needed for boundary cases found by Żmij's verify.py.
	digit := _umul128_add_hi64(fractional, 10, 1 << 63 + 6)
	digit = 2 if fractional == 1 << 62 else digit // Round 2.5 to 2.
	return integral, dec_exp, digit, !round_up && !round_down
}

// Converts a binary FP number bin_sig * 2^bin_exp to the shortest decimal representation.
_to_decimal_f32 :: #force_inline proc "contextless" (bin_sig: u64, bin_exp: int, regular: bool) -> (sig: u64, dec_exp: int, last_digit: u64, has_last_digit: bool) {
	if !regular {
		return _to_decimal_irregular(bin_sig, bin_exp)
	}
	EXTRA_SHIFT :: 34

	dec_exp = _compute_dec_exp(bin_exp, true)
	shift := uint(_compute_exp_shift(bin_exp, dec_exp + 1) + EXTRA_SHIFT)
	even := 1 - (bin_sig & 1)

	pow10_hi, _ := _pow10_significand(-dec_exp - 1)
	p, _ := bits.mul_u64(pow10_hi + 1, bin_sig << shift)

	integral   := p >> EXTRA_SHIFT
	fractional := p & (1 << EXTRA_SHIFT - 1)

	half_ulp   := pow10_hi >> (65 - shift) + even
	round_up   := (fractional + half_ulp) >> EXTRA_SHIFT != 0
	round_down := half_ulp > fractional
	integral += u64(round_up)

	digit := (fractional*10 + 1 << (EXTRA_SHIFT - 1)) >> EXTRA_SHIFT
	digit = 2 if fractional == 1 << (EXTRA_SHIFT - 2) else digit // Round 2.5 to 2.
	return integral, dec_exp, digit, !round_up && !round_down
}

// Handles powers of two, whose rounding interval is asymmetric.
_to_decimal_irregular :: proc "contextless" (bin_sig: u64, bin_exp: int) -> (sig: u64, dec_exp: int, last_digit: u64, has_last_digit: bool) {
	EXTRA_SHIFT :: 6

	dec_exp = _compute_dec_exp(bin_exp, false)
	shift := uint(_compute_exp_shift(bin_exp, dec_exp + 1) + EXTRA_SHIFT)

	pow10_hi, pow10_lo := _pow10_significand(-dec_exp - 1)
	p_hi, p_lo := _umul192_hi128(pow10_hi, pow10_lo, bin_sig << shift)

	integral   := p_hi >> EXTRA_SHIFT
	fractional := p_hi << (64 - EXTRA_SHIFT) | p_lo >> EXTRA_SHIFT

	half_ulp   := pow10_hi >> (EXTRA_SHIFT + 1 - shift)
	round_up   := half_ulp > max(u64) - fractional
	round_down := half_ulp >> 1 >= fractional
	integral += u64(round_up)

	digit    := _umul128_add_hi64(fractional, 10, 1 << 63 - 1)
	lo_digit := _umul128_add_hi64(fractional - half_ulp >> 1, 10, max(u64) - (1 << 32))
	digit = max(digit, lo_digit)
	return integral, dec_exp, digit, !round_up && !round_down
}

@(rodata)
_POW10_U64 := [19]u64{
	1,
	10,
	100,
	1_000,
	10_000,
	100_000,
	1_000_000,
	10_000_000,
	100_000_000,
	1_000_000_000,
	10_000_000_000,
	100_000_000_000,
	1_000_000_000_000,
	10_000_000_000_000,
	100_000_000_000_000,
	1_000_000_000_000_000,
	10_000_000_000_000_000,
	100_000_000_000_000_000,
	1_000_000_000_000_000_000,
}

/*
Formats an f16, f32 or f64 with the shortest output, or with a precision if the output needs at most
18 significant digits.

**Inputs**
- buf: The output buffer
- val: The float, f16, f32 or f64. An f16 is only handled for the shortest output. Its type selects the code for its layout at compile time.
- fmt: Only 'e', 'E', 'f', 'F', 'g' and 'G' are handled
- precision: The precision, or a negative value for the shortest output

**Returns**
- res: The formatted number
- ok: false if the value is not handled
*/
_ftoa_fast :: #force_inline proc "contextless" (buf: []byte, val: $T, fmt: byte, precision: int, flags: Float_Flags) -> (res: []byte, ok: bool) where T == f16 || T == f32 || T == f64 {
	when T == f64 {
		MANTBITS :: 52
		EXPBITS  :: 11
		float_bits := transmute(u64)val
	} else when T == f16 {
		MANTBITS :: 10
		EXPBITS  :: 5
		float_bits := u64(transmute(u16)val)
	} else {
		MANTBITS :: 23
		EXPBITS  :: 8
		float_bits := u64(transmute(u32)val)
	}
	neg  := float_bits >> (EXPBITS + MANTBITS) != 0
	exp  := int(float_bits >> MANTBITS) & (1<<EXPBITS - 1)
	mant := float_bits & (1<<MANTBITS - 1)
	if exp == 1<<EXPBITS - 1 {
		return _format_inf_nan(buf, neg, mant != 0), true
	}
	switch fmt {
	case 'e', 'E', 'f', 'F', 'g', 'G':
	case:
		return
	}

	digit_buf: [64]byte
	digs: Decimal_Slice
	prec := precision
	shortest := precision < 0
	if shortest {
		if exp == 0 {
			exp = 1 // Subnormal
		} else {
			mant |= 1 << MANTBITS
		}
		digs = _shortest_decimal(digit_buf[:], mant, exp, MANTBITS)
		prec = _shortest_precision(digs, fmt)
	} else {
		// Above 400, every nonzero float needs more than 18 digits, and the sums below cannot overflow.
		if precision > 400 {
			return
		}

		num_digits: int
		switch fmt {
		case 'e', 'E':
			num_digits = prec + 1
		case 'g', 'G':
			if prec == 0 {
				prec = 1
			}
			num_digits = prec
		}
		if num_digits > 18 {
			return
		}

		digs = Decimal_Slice{digits = digit_buf[:0]}
		if exp != 0 || mant != 0 {
			if exp == 0 {
				// Normalize the subnormal significand.
				shift := uint(bits.count_leading_zeros(mant)) - (63 - MANTBITS)
				mant <<= shift
				exp = 1 - int(shift)
			} else {
				mant |= 1 << MANTBITS
			}
			bin_exp := exp - (1<<(EXPBITS-1) - 1) - int(MANTBITS)

			sig: u64
			lead_exp: int
			if num_digits > 0 {
				sig, lead_exp = _to_decimal_precision(mant, bin_exp, num_digits, MANTBITS)
			} else {
				sig, num_digits, lead_exp = _to_decimal_fixed(mant, bin_exp, prec, MANTBITS) or_return
			}
			if sig != 0 {
				digs = _precision_digits(digit_buf[:], sig, num_digits, lead_exp)
			}
		}
		if digs.count == 0 {
			_store_zeros16(digit_buf[:], 0)
			_store_zeros16(digit_buf[:], 16)
		}
	}

	f := fmt
	if fmt == 'g' || fmt == 'G' {
		prec, f = _choose_g(digs, prec, shortest, fmt)
	}
	return _format_precision(buf, neg, digs, prec, f, flags), true
}


// Note: this gets its own proc so it does not get inlined
_ftoa_fast_f16 :: #force_no_inline proc "contextless" (buf: []byte, val: f16, fmt: byte, flags: Float_Flags) -> (res: []byte, ok: bool) {
	return _ftoa_fast(buf, val, fmt, -1, flags)
}

// Scales bin_sig * 2^bin_exp by 10^-dec_exp, retaining the fractional part.
_scale :: #force_inline proc "contextless" (bin_sig: u64, bin_exp, dec_exp: int, $MANTBITS: uint) -> (integral, fraction, tail: u64) {
	SHIFT :: 64 - (MANTBITS + 1)
	point_shift := uint(int(SHIFT) - _compute_exp_shift(bin_exp, dec_exp)) // 1 ..< 64
	pow10_hi, pow10_lo := _pow10_significand(-dec_exp)
	hi, lo := _umul192_hi128(pow10_hi, pow10_lo + 1, bin_sig << SHIFT)
	return hi >> point_shift, hi << (64 - point_shift), lo
}

// Rounds a retained fixed-point value to nearest, ties to even.
_round_even :: #force_inline proc "contextless" (integral, fraction, tail: u64) -> u64 {
	HALF :: 1 << 63
	round_up := fraction > HALF || (fraction == HALF && (tail != 0 || integral & 1 != 0))
	return integral + u64(round_up)
}

// Converts a binary FP number bin_sig * 2**bin_exp to a correctly rounded
// decimal with `num_digits` significant digits.
_to_decimal_precision :: #force_inline proc "contextless" (bin_sig: u64, bin_exp, num_digits: int, $MANTBITS: uint) -> (sig: u64, lead_exp: int) {
	// The estimate of the first digit's exponent can be one too small.
	dec_exp := _compute_dec_exp(bin_exp + int(MANTBITS), true) - (num_digits - 1)
	integral, fraction, tail := _scale(bin_sig, bin_exp, dec_exp, MANTBITS)
	sig = _round_even(integral, fraction, tail)
	if sig >= _POW10_U64[num_digits] {
		// Round one decimal place coarser the fraction disambiguates a trailing 5.
		sig = integral / 10
		last_digit := integral - sig*10
		has_fraction := fraction | tail != 0
		round_up := last_digit > 5 || (last_digit == 5 && (has_fraction || sig & 1 != 0))
		sig += u64(round_up)
		dec_exp += 1
	}
	return sig, dec_exp + num_digits - 1
}

// Rounds bin_sig * 2^bin_exp to `prec` digits after the point. Fails above 18 digits.
_to_decimal_fixed :: #force_inline proc "contextless" (bin_sig: u64, bin_exp, prec: int, $MANTBITS: uint) -> (sig: u64, num_digits, lead_exp: int, ok: bool) {
	// The first digit's exponent is e0 or e0+1.
	e0 := _compute_dec_exp(bin_exp + int(MANTBITS), true)
	if e0 + 1 + prec >= 1 && e0 + 2 + prec <= 18 {
		// Common case, 1 <= value*10^prec < 10^18, so scale by 10^prec directly.
		integral, fraction, tail := _scale(bin_sig, bin_exp, -prec, MANTBITS)
		sig = _round_even(integral, fraction, tail)
		num_digits = e0 + 1 + prec
		num_digits += int(sig >= _POW10_U64[num_digits])
		return sig, num_digits, num_digits - 1 - prec, true
	}

	// Scale to 18 significant digits, or 19 if the estimate is one too small.
	dec_exp := e0 - 17
	integral, fraction, tail := _scale(bin_sig, bin_exp, dec_exp, MANTBITS)
	has_fraction := fraction | tail != 0
	num_scaled_digits := 18 + int(integral >= _POW10_U64[18])
	lead_exp = dec_exp + num_scaled_digits - 1
	num_digits = lead_exp + 1 + prec

	if num_digits <= 0 {
		// Rounds to 0, or up to 10^-prec above half. Only 18 scaled digits can be above half.
		HALF :: 5 * 100_000_000_000_000_000
		if num_scaled_digits == 18 && lead_exp == -prec - 1 && (integral > HALF || (integral == HALF && has_fraction)) {
			return 1, 1, -prec, true
		}
		return 0, 0, 0, true
	}
	if num_digits > 18 {
		return
	}

	if num_digits < num_scaled_digits {
		// Round the dropped digits and the fraction in one step.
		pow := _POW10_U64[num_scaled_digits - num_digits]
		sig = integral / pow
		remainder := integral - sig*pow
		half := pow / 2
		round_up := remainder > half || (remainder == half && (has_fraction || sig & 1 != 0))
		sig += u64(round_up)
	} else {
		sig = _round_even(integral, fraction, tail)
	}
	if sig >= _POW10_U64[num_digits] {
		// Rounding carried into a new first digit, as in 9.99 -> 10.0.
		lead_exp += 1
		sig = sig / 10
	}
	return sig, num_digits, lead_exp, true
}

// Writes the 1 to 18 digits of a nonzero sig to `buf`, without trailing zeros.
_precision_digits :: #force_inline proc "contextless" (buf: []byte, sig: u64, num_digits, lead_exp: int) -> Decimal_Slice {
	// Pad to 18 digits, x = aa bbbbbbbb cccccccc, with a nonzero first digit.
	x := sig * _POW10_U64[18 - num_digits]
	ab := _div_1e8(x)
	c := x - ab*100_000_000
	a := _div_1e8(ab)
	b := ab - a*100_000_000

	bcd_a := _to_bcd8(a)
	bcd_b := _to_bcd8(b)
	bcd_c := _to_bcd8(c)
	_store_digits8(buf, 0, bcd_a)
	_store_digits8(buf, 8, bcd_b)
	_store_digits8(buf, 16, bcd_c)

	end := 24 - int(bits.count_trailing_zeros(bcd_c) >> 3)
	end  = end if bcd_c != 0 else 16 - int(bits.count_trailing_zeros(bcd_b) >> 3)
	end  = end if bcd_c != 0 || bcd_b != 0 else 8 - int(bits.count_trailing_zeros(bcd_a) >> 3)
	return {digits = buf[6:end], count = end - 6, decimal_point = lead_exp + 1}
}

/*
Writes digits in the 'e', 'E', 'f' or 'F' format with fixed-size copies

**Inputs**
- buf: The output buffer. Output that does not fit is dropped.
- neg: If true, the number is negative
- digs: The digits, padded with '0' so 48 bytes from the first digit can be read
- precision: The precision. With 'e', at most 18 significant digits.
- fmt: 'e', 'E', 'f' or 'F'
*/
_format_precision :: #force_inline proc "contextless" (buf: []byte, neg: bool, digs: Decimal_Slice, precision: int, fmt: byte, flags: Float_Flags) -> []byte #no_bounds_check {

	copy8  :: #force_inline proc "contextless" (dst, src: [^]byte) { (^[8]byte)(dst)^ = (^[8]byte)(src)^ }
	copy16 :: #force_inline proc "contextless" (dst, src: [^]byte) { (^[16]byte)(dst)^ = (^[16]byte)(src)^ }

	d := raw_data(digs.digits)
	count := digs.count
	dp := digs.decimal_point
	prec := precision

	size: int
	if fmt == 'f' || fmt == 'F' {
		size = 1 + max(dp, 1) + (1 + prec if prec > 0 else 0)
	} else {
		size = 2 + (1 + prec if prec > 0 else 0) + 5
	}
	tmp: [448]byte = ---
	direct := len(buf) >= size + 32
	out := raw_data(buf) if direct else raw_data(tmp[:])

	n: int
	if neg {
		out[0] = '-'
		n += 1
	} else if .Plus in flags {
		out[0] = '+'
		n += 1
	}

	switch fmt {
	case 'f', 'F':
		if dp >= 18 {
			copy16(out[n+0:], d)
			copy16(out[n+16:], d[16:])
			runtime.memset(out[n+count:], '0', dp - count)
			n += dp
			if prec > 0 {
				out[n] = '.'
				runtime.memset(out[n+1:], '0', prec)
				n += 1 + prec
			}
		} else if dp > 0 {
			copy16(out[n+0:], d)
			copy16(out[n+16:], d[16:])
			n += dp
			if prec > 0 {
				out[n] = '.'
				n += 1
				copy16(out[n:], d[dp:])
				copy8(out[n+16:], d[dp+16:])
				n += prec
			}
		} else {
			out[n] = '0'
			n += 1
			if prec > 0 {
				out[n] = '.'
				n += 1
				lead := prec if count == 0 else clamp(-dp, 0, prec)
				if lead <= 16 {
					(^[16]byte)(out[n:])^ = '0'
				} else {
					runtime.memset(out[n:], '0', lead)
				}
				copy16(out[n+lead:], d)
				copy8(out[n+lead+16:], d[16:])
				n += prec
			}
		}

	case:
		out[n] = d[0]
		n += 1
		if prec > 0 {
			out[n] = '.'
			n += 1
			copy16(out[n:], d[1:])
			out[n+16] = d[17]
			n += prec
		}
		exp := dp - 1 if count != 0 else 0
		out[n] = fmt
		out[n+1] = '+' if exp >= 0 else '-'
		e := uint(abs(exp))
		h := e / 100
		e -= h*100
		t := e / 10
		out[n+2] = '0' + byte(h)
		n += 2 + int(h != 0)
		out[n] = '0' + byte(t)
		out[n+1] = '0' + byte(e - t*10)
		n += 2
	}

	return buf[:n] if direct else buf[:copy(buf, tmp[:n])]
}

// Computes the decimal exponent as floor(log10(2**bin_exp)) if regular or
// floor(log10(3/4 * 2**bin_exp)) otherwise, without branching.
_compute_dec_exp :: #force_inline proc "contextless" (bin_exp: int, regular: bool) -> int {
	LOG10_2_SIG        :: 315653 // round(log10(2) * 2^20)
	LOG10_3_OVER_4_SIG :: 131072 // -log10(3/4) * 2^20, rounded to a power of two
	return (bin_exp*LOG10_2_SIG - (0 if regular else LOG10_3_OVER_4_SIG)) >> 20
}

// Computes a shift so that, after scaling by a power of 10, the intermediate
// result always has a fixed 128-bit fractional part.
_compute_exp_shift :: #force_inline proc "contextless" (bin_exp: int, dec_exp: int) -> int {
	LOG2_POW10_SIG :: 217707 // round(log2(10) * 2^16) + 1
	pow10_bin_exp := (-dec_exp*LOG2_POW10_SIG) >> 16 // floor(log2(10^-dec_exp))
	return bin_exp + pow10_bin_exp + 1
}

// Computes the 128-bit significand of 10^k rounded down.
_pow10_significand :: #force_inline proc "contextless" (k: int) -> (hi, lo: u64) {
	p := &_POWER_OF_FIVE_128[k - _SMALLEST_POWER_OF_FIVE]
	hi, lo = p[0], p[1]
	// The table rounds 10^-27 ..= 10^-1 up by one, and lo is never 0 there.
	lo -= u64(uint(k + 27) < 27)
	return
}

// Returns the high 128 bits of the 192-bit product (x_hi*2^64 + x_lo) * y.
_umul192_hi128 :: #force_inline proc "contextless" (x_hi, x_lo, y: u64) -> (hi, lo: u64) {
	p := u128(x_hi)*u128(y) + (u128(x_lo)*u128(y)) >> 64
	return u64(p >> 64), u64(p)
}

// Returns x / 10^8 without a division, which is a library call on 32-bit targets.
_div_1e8 :: #force_inline proc "contextless" (x: u64) -> u64 {
	q, _ := bits.mul_u64(x, 0xabcc77118461cefd)
	return q >> 26
}

// Returns (x*y + c) >> 64.
_umul128_add_hi64 :: #force_inline proc "contextless" (x, y, c: u64) -> u64 {
	return u64((u128(x)*u128(y) + u128(c)) >> 64)
}

// Converts an 8-decimal-digit value to its BCD representation.
_to_bcd8 :: #force_inline proc "contextless" (abcdefgh: u64) -> u64 {
	// An optimization from Xiang JunBo. Base 10000 -> 100 -> 10, with div and mod in one step.
	DIV10K_SIG :: (1 << 40) / 10000 + 1
	NEG10K     :: (1 << 32) - 10000
	DIV100_SIG :: (1 << 19) / 100 + 1
	NEG100     :: (1 << 16) - 100
	DIV10_SIG  :: (1 << 10) / 10 + 1
	NEG10      :: (1 << 8) - 10

	abcd_efgh       := abcdefgh + NEG10K*((abcdefgh*DIV10K_SIG) >> 40)
	ab_cd_ef_gh     := abcd_efgh + NEG100*(((abcd_efgh*DIV100_SIG) >> 19) & 0x7f_0000_007f)
	a_b_c_d_e_f_g_h := ab_cd_ef_gh + NEG10*(((ab_cd_ef_gh*DIV10_SIG) >> 10) & 0xf_000f_000f_000f)
	return a_b_c_d_e_f_g_h
}

_store_digits8 :: #force_inline proc "contextless" (buf: []byte, i: int, bcd: u64) {
	(^[8]byte)(raw_data(buf[i:][:8]))^ = transmute([8]byte)u64be(bcd + 0x3030_3030_3030_3030)
}

_store_zeros16 :: #force_inline proc "contextless" (buf: []byte, i: int) {
	(^[16]byte)(raw_data(buf[i:][:16]))^ = '0'
}


/*
Ported from the scalar path and the precision mode of Żmij.

  Żmij: https://github.com/vitaut/zmij

Copyright (c) 2025 - present, Victor Zverovich
Distributed under the MIT license (see LICENSE) or alternatively
the Boost Software License, Version 1.0.

This port uses the Boost Software License, Version 1.0.

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
