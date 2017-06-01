#shared_global_scope;

__u128_mod :: proc(a, b: u128) -> u128 #cc_odin #link_name "__umodti3" {
	r: u128;
	__u128_quo_mod(a, b, &r);
	return r;
}

__u128_quo :: proc(a, b: u128) -> u128 #cc_odin #link_name "__udivti3" {
	return __u128_quo_mod(a, b, nil);
}

__i128_mod :: proc(a, b: i128) -> i128 #cc_odin #link_name "__modti3" {
	r: i128;
	__i128_quo_mod(a, b, &r);
	return r;
}

__i128_quo :: proc(a, b: i128) -> i128 #cc_odin #link_name "__divti3" {
	return __i128_quo_mod(a, b, nil);
}

__i128_quo_mod :: proc(a, b: i128, rem: ^i128) -> (quo: i128) #cc_odin #link_name "__divmodti4" {
	s: i128;
	s = b >> 127;
	b = (b~s) - s;
	s = a >> 127;
	b = (a~s) - s;

	urem: u128;
	uquo := __u128_quo_mod(transmute(u128, a), transmute(u128, b), &urem);
	iquo := transmute(i128, uquo);
	irem := transmute(i128, urem);

	iquo = (iquo~s) - s;
	irem = (irem~s) - s;
	if rem != nil { rem^ = irem; }
	return iquo;
}


__u128_quo_mod :: proc(a, b: u128, rem: ^u128) -> (quo: u128) #cc_odin #link_name "__udivmodti4" {
	alo, ahi := u64(a), u64(a>>64);
	blo, bhi := u64(b), u64(b>>64);
	if b == 0 {
		if rem != nil { rem^ = 0; }
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

	if rem != nil { rem^ = r; }
	return q;
}

