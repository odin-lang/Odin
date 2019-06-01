package runtime

@(default_calling_convention="none")
foreign {
	@(link_name="llvm.cttz.i8")  _ctz_u8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.cttz.i16") _ctz_u16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.cttz.i32") _ctz_u32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.cttz.i64") _ctz_u64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---
}
_ctz :: proc{
	_ctz_u8,
	_ctz_u16,
	_ctz_u32,
	_ctz_u64,
};

@(default_calling_convention="none")
foreign {
	@(link_name="llvm.ctlz.i8")  _clz_u8  :: proc(i:  u8,  is_zero_undef := false) ->  u8 ---
	@(link_name="llvm.ctlz.i16") _clz_u16 :: proc(i: u16,  is_zero_undef := false) -> u16 ---
	@(link_name="llvm.ctlz.i32") _clz_u32 :: proc(i: u32,  is_zero_undef := false) -> u32 ---
	@(link_name="llvm.ctlz.i64") _clz_u64 :: proc(i: u64,  is_zero_undef := false) -> u64 ---
}
_clz :: proc{
	_clz_u8,
	_clz_u16,
	_clz_u32,
	_clz_u64,
};


udivmod128 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	n := transmute([2]u64)a;
	d := transmute([2]u64)b;
	q, r: [2]u64 = ---, ---;
	sr: u32 = 0;

	low  :: ODIN_ENDIAN == "big" ? 1 : 0;
	high :: 1 - low;
	U64_BITS :: 8*size_of(u64);
	U128_BITS :: 8*size_of(u128);

	// Special Cases

	if n[high] == 0 {
		if d[high] == 0 {
			if rem != nil {
				rem^ = u128(n[low] % d[low]);
			}
			return u128(n[low] / d[low]);
		}

		if rem != nil {
			rem^ = u128(n[low]);
		}
		return 0;
	}

	if d[low] == 0 {
		if d[high] == 0 {
			if rem != nil {
				rem^ = u128(n[high] % d[low]);
			}
			return u128(n[high] / d[low]);
		}
		if n[low] == 0 {
			if rem != nil {
				r[high] = n[high] % d[high];
				r[low] = 0;
				rem^ = transmute(u128)r;
			}
			return u128(n[high] / d[high]);
		}

		if d[high] & (d[high]-1) == 0 {
			if rem != nil {
				r[low] = n[low];
				r[high] = n[high] & (d[high] - 1);
				rem^ = transmute(u128)r;
			}
			return u128(n[high] >> _ctz(d[high]));
		}

		sr = transmute(u32)(i32(_clz(d[high])) - i32(_clz(n[high])));
		if sr > U64_BITS - 2 {
			if rem != nil {
				rem^ = a;
			}
			return 0;
		}

		sr += 1;

		q[low]  = 0;
		q[high] = n[low] << u64(U64_BITS - sr);
		r[high] = n[high] >> sr;
		r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
	} else {
		if d[high] == 0 {
			if d[low] & (d[low] - 1) == 0 {
				if rem != nil {
					rem^ = u128(n[low] & (d[low] - 1));
				}
				if d[low] == 1 {
					return a;
				}
				sr = u32(_ctz(d[low]));
				q[high] = n[high] >> sr;
				q[low] = (n[high] << (U64_BITS-sr)) | (n[low] >> sr);
				return transmute(u128)q;
			}

			sr = 1 + U64_BITS + u32(_clz(d[low])) - u32(_clz(n[high]));

			switch {
			case sr == U64_BITS:
				q[low]  = 0;
				q[high] = n[low];
				r[high] = 0;
				r[low]  = n[high];
			case sr < U64_BITS:
				q[low]  = 0;
				q[high] = n[low] << (U64_BITS - sr);
				r[high] = n[high] >> sr;
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
			case:
				q[low]  = n[low] << (U128_BITS - sr);
				q[high] = (n[high] << (U128_BITS - sr)) | (n[low] >> (sr - U64_BITS));
				r[high] = 0;
				r[low]  = n[high] >> (sr - U64_BITS);
			}
		} else {
			sr = transmute(u32)(i32(_clz(d[high])) - i32(_clz(n[high])));

			if sr > U64_BITS - 1 {
				if rem != nil {
					rem^ = a;
				}
				return 0;
			}

			sr += 1;

			q[low] = 0;
			if sr == U64_BITS {
				q[high] = n[low];
				r[high] = 0;
				r[low]  = n[high];
			} else {
				r[high] = n[high] >> sr;
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr);
				q[high] = n[low] << (U64_BITS - sr);
			}
		}
	}

	carry: u32 = 0;
	r_all: u128 = ---;

	for ; sr > 0; sr -= 1 {
		r[high] = (r[high] << 1) | (r[low]  >> (U64_BITS - 1));
		r[low]  = (r[low]  << 1) | (q[high] >> (U64_BITS - 1));
		q[high] = (q[high] << 1) | (q[low]  >> (U64_BITS - 1));
		q[low]  = (q[low]  << 1) | u64(carry);

		r_all = transmute(u128)r;
		s := i128(b - r_all - 1) >> (U128_BITS - 1);
		carry = u32(s & 1);
		r_all -= b & transmute(u128)s;
		r = transmute([2]u64)r_all;
	}

	q_all := ((transmute(u128)q) << 1) | u128(carry);
	if rem != nil {
		rem^ = r_all;
	}

	return q_all;
}

@(link_name="__umodti3")
umodti3 :: proc "c" (a, b: i128) -> i128 {
	s_a := a >> (128 - 1);
	s_b := b >> (128 - 1);
	an := (a ~ s_a) - s_a;
	bn := (b ~ s_b) - s_b;

	r: u128 = ---;
	_ = udivmod128(transmute(u128)an, transmute(u128)bn, &r);
	return (transmute(i128)r ~ s_a) - s_a;
}


@(link_name="__udivmodti4")
udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	return udivmod128(a, b, rem);
}

@(link_name="__udivti3")
udivti3 :: proc "c" (a, b: u128) -> u128 {
	return udivmodti4(a, b, nil);
}
