package runtime

import "intrinsics"

@(link_name="__umodti3")
umodti3 :: proc "c" (a, b: u128) -> u128 {
	r: u128 = ---;
	_ = udivmod128(a, b, &r);
	return r;
}


@(link_name="__udivmodti4")
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem);
}

@(link_name="__udivti3")
udivti3 :: proc "c" (a, b: u128) -> u128 {
	return udivmodti4(a, b, nil);
}


@(link_name="__modti3")
modti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1);
	s_b := b >> (128 - 1);
	an := (a ~ s_a) - s_a;
	bn := (b ~ s_b) - s_b;

	r: u128 = ---;
	_ = udivmod128(transmute(u128)an, transmute(u128)bn, &r);
	return (transmute(i128)r ~ s_a) - s_a;
}


@(link_name="__divmodti4")
divmodti4 :: proc "c" (a, b: i128, rem: ^i128) -> i128 {
	u := udivmod128(transmute(u128)a, transmute(u128)b, cast(^u128)rem);
	return transmute(i128)u;
}

@(link_name="__divti3")
divti3 :: proc "c" (a, b: i128) -> i128 {
	u := udivmodti4(transmute(u128)a, transmute(u128)b, nil);
	return transmute(i128)u;
}


@(link_name="__fixdfti")
fixdfti :: proc(a: u64) -> i128 {
	significandBits :: 52;
	typeWidth       :: (size_of(u64)*8);
	exponentBits    :: (typeWidth - significandBits - 1);
	maxExponent     :: ((1 << exponentBits) - 1);
	exponentBias    :: (maxExponent >> 1);

	implicitBit     :: (u64(1) << significandBits);
	significandMask :: (implicitBit - 1);
	signBit         :: (u64(1) << (significandBits + exponentBits));
	absMask         :: (signBit - 1);
	exponentMask    :: (absMask ~ significandMask);

	// Break a into sign, exponent, significand
	aRep := a;
	aAbs := aRep & absMask;
	sign := i128(-1 if aRep & signBit != 0 else 1);
	exponent := (aAbs >> significandBits) - exponentBias;
	significand := (aAbs & significandMask) | implicitBit;

	// If exponent is negative, the result is zero.
	if exponent < 0 {
		return 0;
	}

	// If the value is too large for the integer type, saturate.
	if exponent >= size_of(i128) * 8 {
		return max(i128) if sign == 1 else min(i128);
	}

	// If 0 <= exponent < significandBits, right shift to get the result.
	// Otherwise, shift left.
	if exponent < significandBits {
		return sign * i128(significand >> (significandBits - exponent));
	} else {
		return sign * (i128(significand) << (exponent - significandBits));
	}

}
