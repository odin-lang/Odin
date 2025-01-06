package runtime

import "base:intrinsics"

udivmod128 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	_ctz :: intrinsics.count_trailing_zeros
	_clz :: intrinsics.count_leading_zeros

	n := transmute([2]u64)a
	d := transmute([2]u64)b
	q, r: [2]u64
	sr: u32 = 0

	low  :: 1 when ODIN_ENDIAN == .Big else 0
	high :: 1 - low
	U64_BITS :: 8*size_of(u64)
	U128_BITS :: 8*size_of(u128)

	// Special Cases

	if n[high] == 0 {
		if d[high] == 0 {
			if rem != nil {
				res := n[low] % d[low]
				rem^ = u128(res)
			}
			return u128(n[low] / d[low])
		}

		if rem != nil {
			rem^ = u128(n[low])
		}
		return 0
	}

	if d[low] == 0 {
		if d[high] == 0 {
			if rem != nil {
				rem^ = u128(n[high] % d[low])
			}
			return u128(n[high] / d[low])
		}
		if n[low] == 0 {
			if rem != nil {
				r[high] = n[high] % d[high]
				r[low] = 0
				rem^ = transmute(u128)r
			}
			return u128(n[high] / d[high])
		}

		if d[high] & (d[high]-1) == 0 {
			if rem != nil {
				r[low] = n[low]
				r[high] = n[high] & (d[high] - 1)
				rem^ = transmute(u128)r
			}
			return u128(n[high] >> _ctz(d[high]))
		}

		sr = u32(i32(_clz(d[high])) - i32(_clz(n[high])))
		if sr > U64_BITS - 2 {
			if rem != nil {
				rem^ = a
			}
			return 0
		}

		sr += 1

		q[low]  = 0
		q[high] = n[low] << u64(U64_BITS - sr)
		r[high] = n[high] >> sr
		r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr)
	} else {
		if d[high] == 0 {
			if d[low] & (d[low] - 1) == 0 {
				if rem != nil {
					rem^ = u128(n[low] & (d[low] - 1))
				}
				if d[low] == 1 {
					return a
				}
				sr = u32(_ctz(d[low]))
				q[high] = n[high] >> sr
				q[low] = (n[high] << (U64_BITS-sr)) | (n[low] >> sr)
				return transmute(u128)q
			}

			sr = 1 + U64_BITS + u32(_clz(d[low])) - u32(_clz(n[high]))

			switch {
			case sr == U64_BITS:
				q[low]  = 0
				q[high] = n[low]
				r[high] = 0
				r[low]  = n[high]
			case sr < U64_BITS:
				q[low]  = 0
				q[high] = n[low] << (U64_BITS - sr)
				r[high] = n[high] >> sr
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr)
			case:
				q[low]  = n[low] << (U128_BITS - sr)
				q[high] = (n[high] << (U128_BITS - sr)) | (n[low] >> (sr - U64_BITS))
				r[high] = 0
				r[low]  = n[high] >> (sr - U64_BITS)
			}
		} else {
			sr = u32(i32(_clz(d[high])) - i32(_clz(n[high])))

			if sr > U64_BITS - 1 {
				if rem != nil {
					rem^ = a
				}
				return 0
			}

			sr += 1

			q[low] = 0
			if sr == U64_BITS {
				q[high] = n[low]
				r[high] = 0
				r[low]  = n[high]
			} else {
				r[high] = n[high] >> sr
				r[low]  = (n[high] << (U64_BITS - sr)) | (n[low] >> sr)
				q[high] = n[low] << (U64_BITS - sr)
			}
		}
	}

	carry: u32 = 0
	r_all: u128

	for ; sr > 0; sr -= 1 {
		r[high] = (r[high] << 1) | (r[low]  >> (U64_BITS - 1))
		r[low]  = (r[low]  << 1) | (q[high] >> (U64_BITS - 1))
		q[high] = (q[high] << 1) | (q[low]  >> (U64_BITS - 1))
		q[low]  = (q[low]  << 1) | u64(carry)

		r_all = transmute(u128)r
		s := i128(b - r_all - 1) >> (U128_BITS - 1)
		carry = u32(s & 1)
		r_all -= b & u128(s)
		r = transmute([2]u64)r_all
	}

	q_all := ((transmute(u128)q) << 1) | u128(carry)
	if rem != nil {
		rem^ = r_all
	}

	return q_all
}
