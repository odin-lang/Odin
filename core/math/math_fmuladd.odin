package math

import "base:intrinsics"
_ :: intrinsics

@(require_results)
fmuladd_f16 :: proc "contextless" (a, b, c: f16) -> f16 {
	when IS_WASM {
		return f16(fmuladd_f64(f64(a), f64(b), f64(c)))
	} else {
		foreign _ {
			@(link_name="llvm.fmuladd.f16", require_results)
			_fmuladd_f16 :: proc "none" (a, b, c: f16) -> f16 ---
		}

		return _fmuladd_f16(a, b, c)
	}
}
@(require_results)
fmuladd_f32 :: proc "contextless" (a, b, c: f32) -> f32 {
	when IS_WASM {
		return f32(fmuladd_f64(f64(a), f64(b), f64(c)))
	} else {
		foreign _ {
			@(link_name="llvm.fmuladd.f32", require_results)
			_fmuladd_f32 :: proc "none" (a, b, c: f32) -> f32 ---
		}

		return _fmuladd_f32(a, b, c)
	}
}
@(require_results)
fmuladd_f64 :: proc "contextless" (a, b, c: f64) -> f64 {
	when IS_WASM {
		return #force_inline fmuladd_slow_f64(a, b, c)
	} else {
		foreign _ {
			@(link_name="llvm.fmuladd.f64", require_results)
			_fmuladd_f64 :: proc "none" (a, b, c: f64) -> f64 ---
		}

		return _fmuladd_f64(a, b, c)
	}
}


@(require_results)
fmuladd_slow_f64 :: proc "contextless" (x, y, z: f64) -> f64 {
	@(require_results)
	split :: proc "contextless" (b: u64) -> (sign: u32, exp: i32, mantissa: u64) {
		MASK  :: 0x7FF
		FRAC_MASK :: 1<<52 - 1

		sign = u32(b >> 63)
		exp = i32(b>>52) & MASK
		mantissa = b & FRAC_MASK

		if exp == 0 {
			shift := uint(intrinsics.count_leading_zeros(mantissa) - 11)
			mantissa <<= shift
			exp = 1 - i32(shift)
		} else {
			mantissa |= 1<<52
		}
		return
	}

	@(require_results)
	mul_u64 :: proc "contextless" (x, y: u64) -> (hi, lo: u64) {
		prod_wide := u128(x) * u128(y)
		hi, lo = u64(prod_wide>>64), u64(prod_wide)
		return
	}

	@(require_results)
	add_u64 :: proc "contextless" (x, y, carry: u64) -> (sum, carry_out: u64) {
		tmp_carry, tmp_carry2: bool
		sum, tmp_carry = intrinsics.overflow_add(x, y)
		sum, tmp_carry2 = intrinsics.overflow_add(sum, carry)
		carry_out = u64(tmp_carry | tmp_carry2)
		return
	}

	@(require_results)
	sub_u64 :: proc "contextless" (x, y, borrow: u64) -> (diff, borrow_out: u64) {
		tmp_borrow, tmp_borrow2: bool
		diff, tmp_borrow = intrinsics.overflow_sub(x, y)
		diff, tmp_borrow2 = intrinsics.overflow_sub(diff, borrow)
		borrow_out = u64(tmp_borrow | tmp_borrow2)
		return
	}

	@(require_results)
	nonzero :: proc "contextless" (x: u64) -> u64 {
		return 1 if x != 0 else 0
	}

	@(require_results)
	zero :: proc "contextless" (x: u64) -> u64 {
		return 1 if x == 0 else 0
	}

	@(require_results)
	shl :: proc "contextless" (u1, u2: u64, n: uint) -> (r1, r2: u64) {
		r1 = u1<<n | u2>>(64-n) | u2<<(n-64)
		r2 = u2<<n
		return
	}
	@(require_results)
	shr :: proc "contextless" (u1, u2: u64, n: uint) -> (r1, r2: u64) {
		r2 = u2>>n | u1<<(64-n) | u1>>(n-64)
		r1 = u1>>n
		return
	}

	@(require_results)
	lz :: proc "contextless" (u1, u2: u64) -> (l: i32) {
		l = i32(intrinsics.count_leading_zeros(u1))
		if l == 64 {
			l += i32(intrinsics.count_leading_zeros(u2))
		}
		return l
	}

	@(require_results)
	shrcompress :: proc "contextless" (u1, u2: u64, n: uint) -> (r1, r2: u64) {
		switch {
		case n == 0:
			return u1, u2
		case n == 64:
			return 0, u1 | nonzero(u2)
		case n >= 128:
			return 0, nonzero(u1 | u2)
		case n < 64:
			r1, r2 = shr(u1, u2, n)
			r2 |= nonzero(u2 & (1<<n - 1))
		case n < 128:
			r1, r2 = shr(u1, u2, n)
			r2 |= nonzero(u1&(1<<(n-64)-1) | u2)
		}
		return
	}




	UVINF :: 0x7ff0_0000_0000_0000
	BIAS :: 1023

	bx, by, bz := transmute(u64)x, transmute(u64)y, transmute(u64)z

	switch {
	case x == 0, y == 0, z == 0,
	     bx&UVINF == UVINF, by&UVINF == UVINF:
	     return x*y + z
	}

	if bz&UVINF == UVINF {
		return z
	}

	xs, xe, xm := split(bx)
	ys, ye, ym := split(by)
	zs, ze, zm := split(bz)

	pe := xe + ye - BIAS + 1

	pm1, pm2 := mul_u64(xm<<10, ym<<11)
	zm1, zm2 := zm<<10, u64(0)
	ps := xs ~ ys // product sign

	is_62_zero := uint((~pm1 >> 62) & 1)
	pm1, pm2 = shl(pm1, pm2, is_62_zero)
	pe -= i32(is_62_zero)

	if pe < ze || pe == ze && pm1 < zm1 {
		// Swap addition operands so |p| >= |z|
		ps, pe, pm1, pm2, zs, ze, zm1, zm2 = zs, ze, zm1, zm2, ps, pe, pm1, pm2
	}

	if ps != zs && pe == ze && pm1 == zm1 && pm2 == zm2 {
		return 0
	}

	zm1, zm2 = shrcompress(zm1, zm2, uint(pe-ze))

	// Compute resulting significands, normalizing if necessary.
	m, c: u64
	if ps == zs {
		// Adding (pm1:pm2) + (zm1:zm2)
		pm2, c = add_u64(pm2, zm2, 0)
		pm1, _ = add_u64(pm1, zm1, c)
		pe -= i32(~pm1 >> 63)
		pm1, m = shrcompress(pm1, pm2, uint(64+pm1>>63))
	} else {
		// Subtracting (pm1:pm2) - (zm1:zm2)
		pm2, c = sub_u64(pm2, zm2, 0)
		pm1, _ = sub_u64(pm1, zm1, c)
		nz := lz(pm1, pm2)
		pe -= nz
		m, pm2 = shl(pm1, pm2, uint(nz-1))
		m |= nonzero(pm2)
	}

	// Round and break ties to even
	if pe > 1022+BIAS || pe == 1022+BIAS && (m+1<<9)>>63 == 1 {
		// rounded value overflows exponent range
		return transmute(f64)(u64(ps)<<63 | UVINF)
	}
	if pe < 0 {
		n := uint(-pe)
		m = m>>n | nonzero(m&(1<<n-1))
		pe = 0
	}
	m = ((m + 1<<9) >> 10) & ~zero((m&(1<<10-1))~1<<9)
	pe &= -i32(nonzero(m))
	return transmute(f64)(u64(ps)<<63 + u64(pe)<<52 + m)
}