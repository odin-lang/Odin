#+build !bedrock
package runtime

import "base:intrinsics"

udivmod128 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
	n_lo, n_hi := u64(a), u64(a >> 64)
	d_lo, d_hi := u64(b), u64(b >> 64)

	q, r: u128
	switch {
	case b == 0:
		q = u128(n_hi / d_lo)<<64 | u128(n_lo / d_lo)
		r = u128(n_hi % d_lo)<<64 | u128(n_lo % d_lo)

	case n_hi == 0 && d_hi == 0:
		q, r = u128(n_lo / d_lo), u128(n_lo % d_lo)

	case:
		q, r = _udivmod128_wide(a, b)
	}

	if rem != nil {
		rem^ = r
	}
	return q
}

@(private, require_results)
_udivmod128_wide :: #force_no_inline proc "contextless" (a, b: u128) -> (q, r: u128) {
	n_lo, n_hi := u64(a), u64(a >> 64)
	d_lo, d_hi := u64(b), u64(b >> 64)

	switch {
	case b > a:
		q, r = 0, a

	case intrinsics.count_leading_zeros(n_hi) == intrinsics.count_leading_zeros(d_hi):
		q, r = 1, a - b

	case d_hi == 0:
		q_hi: u64
		if n_hi >= d_lo {
			q_hi = n_hi / d_lo
			n_hi = n_hi % d_lo
		}
		when ODIN_ARCH == .amd64 {
			q_lo, r_lo := _udiv128by64_amd64(n_hi, n_lo, d_lo)
		} else {
			q_lo, r_lo := _udiv128by64(n_hi, n_lo, d_lo)
		}
		q, r = u128(q_hi)<<64 | u128(q_lo), u128(r_lo)

	case:
		s  := intrinsics.count_leading_zeros(d_hi)
		v1 := u64((b << s) >> 64)
		u1 := a >> 1
		when ODIN_ARCH == .amd64 {
			q1, _ := _udiv128by64_amd64(u64(u1 >> 64), u64(u1), v1)
		} else {
			q1, _ := _udiv128by64(u64(u1 >> 64), u64(u1), v1)
		}
		q0 := u64((u128(q1) << s) >> 63)
		if q0 != 0 {
			q0 -= 1
		}
		r = a - u128(q0)*b
		if r >= b {
			q0 += 1
			r  -= b
		}
		q = u128(q0)
	}
	return
}

@(private, require_results)
_udiv128by64 :: #force_inline proc "contextless" (u1, u0, v: u64) -> (q, r: u64) {
	B :: u64(1) << 32

	s  := intrinsics.count_leading_zeros(v)
	vn := v << s
	vn1, vn0 := vn >> 32, vn & (B-1)

	un32 := u1<<s | u0>>(64-s)
	un10 := u0 << s

	un1, un0 := un10 >> 32, un10 & (B-1)

	q1   := un32 / vn1
	rhat := un32 - q1*vn1
	for q1 >= B || q1*vn0 > B*rhat + un1 {
		q1   -= 1
		rhat += vn1
		if rhat >= B {
			break
		}
	}

	un21 := un32*B + un1 - q1*vn

	q0 := un21 / vn1
	rhat = un21 - q0*vn1
	for q0 >= B || q0*vn0 > B*rhat + un0 {
		q0   -= 1
		rhat += vn1
		if rhat >= B {
			break
		}
	}

	q = q1*B + q0
	r = (un21*B + un0 - q0*vn) >> s
	return
}
