#shared_global_scope

/*
@(link_name="__multi3")
__multi3 :: proc "c" (a, b: u128) -> u128 {
	bits_in_dword_2 :: size_of(i64) * 4;
	lower_mask :: u128(~u64(0) >> bits_in_dword_2);


	when ODIN_ENDIAN == "big" {
		TWords :: struct #raw_union {
			all: u128,
			using _: struct {lo, hi: u64},
		};
	} else {
		TWords :: struct #raw_union {
			all: u128,
			using _: struct {hi, lo: u64},
		};
	}

	r: TWords;
	t: u64;

	r.lo =  u64(a & lower_mask) * u64(b & lower_mask);
	t    =  r.lo >> bits_in_dword_2;
	r.lo &= u64(lower_mask);
	t    += u64(a >> bits_in_dword_2) * u64(b & lower_mask);
	r.lo += u64(t & u64(lower_mask)) << bits_in_dword_2;
	r.hi =  t >> bits_in_dword_2;
	t    =  r.lo >> bits_in_dword_2;
	r.lo &= u64(lower_mask);
	t    += u64(b >> bits_in_dword_2) * u64(a & lower_mask);
	r.lo += u64(t & u64(lower_mask)) << bits_in_dword_2;
	r.hi += t >> bits_in_dword_2;
	r.hi += u64(a >> bits_in_dword_2) * u64(b >> bits_in_dword_2);
	return r.all;
}

@(link_name="__umodti3")
__u128_mod :: proc "c" (a, b: u128) -> u128 {
	r: u128;
	__u128_quo_mod(a, b, &r);
	return r;
}

@(link_name="__udivti3")
__u128_quo :: proc "c" (a, b: u128) -> u128 {
	return __u128_quo_mod(a, b, nil);
}

@(link_name="__modti3")
__i128_mod :: proc "c" (a, b: i128) -> i128 {
	r: i128;
	__i128_quo_mod(a, b, &r);
	return r;
}

@(link_name="__divti3")
__i128_quo :: proc "c" (a, b: i128) -> i128 {
	return __i128_quo_mod(a, b, nil);
}

@(link_name="__divmodti4")
__i128_quo_mod :: proc "c" (a, b: i128, rem: ^i128) -> (quo: i128) {
	s: i128;
	s = b >> 127;
	b = (b~s) - s;
	s = a >> 127;
	b = (a~s) - s;

	uquo: u128;
	urem := __u128_quo_mod(transmute(u128)a, transmute(u128)b, &uquo);
	iquo := transmute(i128)uquo;
	irem := transmute(i128)urem;

	iquo = (iquo~s) - s;
	irem = (irem~s) - s;
	if rem != nil do rem^ = irem;
	return iquo;
}


@(link_name="__udivmodti4")
__u128_quo_mod :: proc "c" (a, b: u128, rem: ^u128) -> (quo: u128) {
	alo := u64(a);
	blo := u64(b);
	if b == 0 {
		if rem != nil do rem^ = 0;
		return u128(alo/blo);
	}

	r, d, x, q: u128 = a, b, 1, 0;

	for r >= d && (d>>127)&1 == 0 {
		x <<= 1;
		d <<= 1;
	}

	for x != 0 {
		if r >= d {
			r -= d;
			q |= x;
		}
		x >>= 1;
		d >>= 1;
	}

	if rem != nil do rem^ = r;
	return q;
}
*/
