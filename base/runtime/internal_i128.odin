#+vet !cast
#+build !bedrock
package runtime

import "base:intrinsics"

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



@(link_name="__fixunsdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfti :: #force_no_inline proc "c" (a: f64) -> u128 {
	// TODO(bill): implement `fixunsdfti` correctly
	x := u64(a)
	return u128(x)
}

@(link_name="__fixunsdfdi", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixunsdfdi :: #force_no_inline proc "c" (a: f64) -> i128 {
	// TODO(bill): implement `fixunsdfdi` correctly
	x := i64(a)
	return i128(x)
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


@(link_name="__fixdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
fixdfti :: proc "c" (a: u64) -> i128 {
	significandBits :: 52
	typeWidth       :: (size_of(u64)*8)
	exponentBits    :: (typeWidth - significandBits - 1)
	maxExponent     :: ((1 << exponentBits) - 1)
	exponentBias    :: (maxExponent >> 1)

	implicitBit     :: (u64(1) << significandBits)
	significandMask :: (implicitBit - 1)
	signBit         :: (u64(1) << (significandBits + exponentBits))
	absMask         :: (signBit - 1)
	exponentMask    :: (absMask ~ significandMask)

	// Break a into sign, exponent, significand
	aRep := a
	aAbs := aRep & absMask
	sign := i128(-1 if aRep & signBit != 0 else 1)
	exponent := u64((aAbs >> significandBits) - exponentBias)
	significand := u64((aAbs & significandMask) | implicitBit)

	// If exponent is negative, the result is zero.
	if exponent < 0 {
		return 0
	}

	// If the value is too large for the integer type, saturate.
	if exponent >= size_of(i128) * 8 {
		return max(i128) if sign == 1 else min(i128)
	}

	// If 0 <= exponent < significandBits, right shift to get the result.
	// Otherwise, shift left.
	if exponent < significandBits {
		return sign * i128(significand >> (significandBits - exponent))
	} else {
		return sign * (i128(significand) << (exponent - significandBits))
	}

}

