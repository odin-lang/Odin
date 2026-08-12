#+vet !cast
#+build !bedrock
package runtime

import "base:intrinsics"

@(private="file")
IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@(link_name="__floattidf", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
floattidf :: proc "c" (a: i128) -> f64 {
	DBL_MANT_DIG :: 53
	if a == 0 {
		return 0.0
	}
	a := a
	N :: size_of(i128) * 8
	s := a >> (N-1)
	a = (a ~ s) - s
	sd: = N - intrinsics.count_leading_zeros(a)  // number of significant digits
	e := i32(sd - 1)        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = i128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
			    i128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0)
		}

		a |= i128((a & 4) != 0)
		a += 1
		a >>= 2

		if a & (i128(1) << DBL_MANT_DIG) != 0 {
			a >>= 1
			e += 1
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd) & 127
	}
	fb: [2]u32
	fb[1] = (u32(s) & 0x80000000) |          // sign
	        (u32(e + 1023) << 20) |          // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
	fb[0] = u32(a)                           // mantissa-low
	return transmute(f64)fb
}


@(link_name="__floattidf_unsigned", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
floattidf_unsigned :: proc "c" (a: u128) -> f64 {
	DBL_MANT_DIG :: 53
	if a == 0 {
		return 0.0
	}
	a := a
	N :: size_of(u128) * 8
	sd: = N - intrinsics.count_leading_zeros(a)  // number of significant digits
	e := i32(sd - 1)        // exponent
	if sd > DBL_MANT_DIG {
		switch sd {
		case DBL_MANT_DIG + 1:
			a <<= 1
		case DBL_MANT_DIG + 2:
			// okay
		case:
			a = u128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
				u128(u128(a) & (~u128(0) >> u128(N + DBL_MANT_DIG+2 - sd)) != 0)
		}

		a |= u128((a & 4) != 0)
		a += 1
		a >>= 2

		if a & (1 << DBL_MANT_DIG) != 0 {
			a >>= 1
			e += 1
		}
	} else {
		a <<= u128(DBL_MANT_DIG - sd)
	}
	fb: [2]u32
	fb[1] = (0) |                            // sign
	        u32((e + 1023) << 20) |          // exponent
	        u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
	fb[0] = u32(a)                           // mantissa-low
	return transmute(f64)fb
}


// f64 -> unsigned integer conversion (truncating toward zero)
// port of clang/compiler-rt's fp_fixuint_impl.inc;
// decompose the f64 into significand and exponent, shift the significand into place,
// saturate out of range values
@(private="file")
fixuint :: proc "contextless" ($U: typeid, a: f64) -> U where intrinsics.type_is_unsigned(U) {
	BITS             :: 8 * size_of(U)
	SIGNIFICAND_BITS :: 52
	EXPONENT_BIAS    :: 1023

	IMPLICIT_BIT     :: (u64(1) << SIGNIFICAND_BITS)
	SIGNIFICAND_MASK :: (IMPLICIT_BIT - 1)

	// Break a into sign, exponent, significand parts.
	a_rep := transmute(u64)a
	negative := (a_rep >> 63) != 0
	exponent := i32((a_rep >> SIGNIFICAND_BITS) & 0x7ff) - EXPONENT_BIAS
	significand := (a_rep & SIGNIFICAND_MASK) | IMPLICIT_BIT

	// If either the value or the exponent is negative, the result is zero.
	if negative || exponent < 0 {
		return 0
	}

	// If the value is too large for the integer type, saturate.
	if exponent >= BITS {
		return max(U)
	}

	// If 0 <= exponent < SIGNIFICAND_BITS, right shift to get the result.
	// Otherwise, shift left.
	if exponent < SIGNIFICAND_BITS {
		return U(significand >> u32(SIGNIFICAND_BITS - exponent))
	}
	return U(significand) << u32(exponent - SIGNIFICAND_BITS)
}

// f64 -> signed integer conversion (truncating toward zero)
// port of clang/compiler-rt's fp_fixint_impl.inc;
// decompose the f64 into significand and exponent, shift the significand into place,
// saturate out of range values
@(private="file")
fixint :: proc "contextless" ($T: typeid, a: f64) -> T where intrinsics.type_is_integer(T), !intrinsics.type_is_unsigned(T) {
	BITS             :: 8 * size_of(T)
	SIGNIFICAND_BITS :: 52
	EXPONENT_BIAS    :: 1023

	IMPLICIT_BIT     :: (u64(1) << SIGNIFICAND_BITS)
	SIGNIFICAND_MASK :: (IMPLICIT_BIT - 1)

	// Break a into sign, exponent, significand parts.
	a_rep := transmute(u64)a
	negative := (a_rep >> 63) != 0
	exponent := i32((a_rep >> SIGNIFICAND_BITS) & 0x7ff) - EXPONENT_BIAS
	significand := (a_rep & SIGNIFICAND_MASK) | IMPLICIT_BIT

	// If exponent is negative, the result is zero.
	if exponent < 0 {
		return 0
	}

	// If the value is too large for the integer type, saturate;
	// (the only exactly representable value with exponent BITS-1 is min(T))
	// this deviates from clang/compiler-rt (it instead wraps from BITS-1 to BITS,
	// that is, f64(1 << 127) would wrap to min(i128) (for T=i128)),
	// while this saturates consistently
	if exponent >= BITS - 1 {
		return min(T) if negative else max(T)
	}

	// If 0 <= exponent < SIGNIFICAND_BITS, right shift to get the result.
	// Otherwise, shift left. After saturation the magnitude is below
	// 1 << (BITS-1), so it fits in T and negation can't overflow
	r: T
	if exponent < SIGNIFICAND_BITS {
		r = T(significand >> u32(SIGNIFICAND_BITS - exponent))
	} else {
		r = T(significand) << u32(exponent - SIGNIFICAND_BITS)
	}
	return -r if negative else r
}

@(link_name="__fixunsdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfti :: proc "c" (a: f64) -> u128 {
	return fixuint(u128, a)
}

@(link_name="__fixunsdfdi", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfdi :: proc "c" (a: f64) -> u64 {
	return fixuint(u64, a)
}

@(link_name="__fixdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixdfti :: proc "c" (a: f64) -> i128 {
	return fixint(i128, a)
}

@(link_name="__fixdfdi", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixdfdi :: proc "c" (a: f64) -> i64 {
	return fixint(i64, a)
}


@(link_name="__umodti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
umodti3 :: proc "c" (a, b: u128) -> u128 {
	r: u128 = ---
	_ = udivmod128(a, b, &r)
	return r
}


@(link_name="__udivmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem)
}

when !IS_WASM {
	@(link_name="__udivti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
	udivti3 :: proc "c" (a, b: u128) -> u128 {
		return udivmodti4(a, b, nil)
	}
}


@(link_name="__modti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
modti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1)
	s_b := b >> (128 - 1)
	an := (a ~ s_a) - s_a
	bn := (b ~ s_b) - s_b

	r: u128 = ---
	_ = udivmod128(u128(an), u128(bn), &r)
	return (i128(r) ~ s_a) - s_a
}


@(link_name="__divmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
divmodti4 :: proc "c" (a, b: i128, rem: ^i128) -> i128 {
	s_a := a >> (128 - 1) // -1 if negative or 0
	s_b := b >> (128 - 1)
	an := (a ~ s_a) - s_a // absolute
	bn := (b ~ s_b) - s_b

	s_b   ~= s_a // quotient sign
	u_s_b := u128(s_b)
	u_s_a := u128(s_a)

	r: u128 = ---
	u := i128((udivmodti4(u128(an), u128(bn), &r) ~ u_s_b) - u_s_b) // negate if negative
	rem^ = i128((r ~ u_s_a) - u_s_a)
	return u
}

@(link_name="__divti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
divti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1) // -1 if negative or 0
	s_b := b >> (128 - 1)
	an := (a ~ s_a) - s_a // absolute
	bn := (b ~ s_b) - s_b

	s_a   ~= s_b // quotient sign
	u_s_a := u128(s_a)

	return i128((udivmodti4(u128(an), u128(bn), nil) ~ u_s_a) - u_s_a) // negate if negative
}

