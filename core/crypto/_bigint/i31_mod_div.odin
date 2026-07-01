package _bigint

// Copyright (c) 2016 Thomas Pornin <pornin@bolet.org>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//   1. Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS “AS IS” AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import "base:intrinsics"
import subtle "core:crypto/_subtle"

// `i31_moddiv` support follows.
//
// In this file, we handle big integers with a custom format, i.e.
// without the usual one-word header. Value is split into 31-bit words,
// each stored in a 32-bit slot (top bit is zero) in little-endian order.
//
// The length (in words) is provided explicitly. In some cases,
// the value can be negative (using two's complement representation).
//
// In some cases, the top word is allowed to have a 32th bit.

// Negate big integer conditionally. The value consists of 'len' words,
// with 31 bits in each word (the top bit of each word should be 0,
// except possibly for the last word). If 'ctl' is 1, the negation is
// computed; otherwise, if 'ctl' is 0, then the value is unchanged.
_i31_cond_negate :: proc "contextless" (a: []u32, ctl: u32) {
	cc := ctl
	xm := -ctl >> 1
	for k in 0..<len(a) {
		aw := a[k]
		aw  = (aw ~ xm) + cc
		a[k] = aw & I31_MASK
		cc = aw >> 31
	}
}

// Finish modular reduction. Rules on input parameters:
//
// if `neg` = 1, then `-m <= a < 0`
// if `neg` = 0, then `0 <= a < 2*m`
// If `neg` = 0, then the top word of `a` may use 32 bits.
//
// Also, modulus `m` must be odd.
_i31_finish_mod :: proc "contextless" (a: []u32, m: []u32, neg: u32) {
	_len := uint(len(a))

	// First pass: compare `a` (assumed nonnegative) with `m`.
	// Note that if the final word uses the top extra bit, then
	// subtracting `m` must yield `a` value less than 2^31, since we
	// assumed that `a < 2*m`.
	cc := u32(0)
	for k in 0..<_len {
		aw := a[k]
		mw := m[k]
		cc = (aw - mw - cc) >> 31
	}

	// At this point:
	// 	if `neg` = 1, then we must add `m` (regardless of `cc`)
	// 	if `neg` = 0 and `cc` = 0, then we must subtract `m`
	// 	if `neg` = 0 and `cc` = 1, then we must do nothing
	xm := -neg >> 1
	ym := -(neg | (1 - cc))
	cc = neg
	for k in 0..<_len {
		aw := a[k]
		mw := (m[k] ~ xm) & ym
		aw = aw - mw - cc
		a[k] = aw & I31_MASK
		cc = aw >> 31
	}
}

// Compute:
// 	`a <- (a*pa+b*pb)/(2^31)`
// 	`b <- (a*qa+b*qb)/(2^31)`
//
// The division is assumed to be exact (i.e. the low word is dropped).
// If the final `a` is negative, then it is negated. Similarly for `b`.
//
// Returned value is the combination of two bits:
// 	bit 0: 1 if a had to be negated, 0 otherwise
// 	bit 1: 1 if b had to be negated, 0 otherwise
//
// Factors `pa`, `pb`, `qa` and `qb` must be at most `2^31` in absolute value.
// Source integers `a` and `b` must be nonnegative; top word is not allowed to
// contain an extra 32th bit.
@(require_results)
_i31_co_reduce :: proc "contextless" (a: []u32, b: []u32, pa, pb: u64, qa, qb: u64) -> (res: u32) {
	cca := u64(0)
	ccb := u64(0)
	for k in 0..<len(a) {
		// Since:
		// 	`|pa| <= 2^31`
		// 	`|pb| <= 2^31`
		// 	`0 <= wa <= 2^31 - 1`
		// 	`0 <= wb <= 2^31 - 1`
		// 	`|cca| <= 2^32 - 1`
		// Then:
		// 	`|za| <= (2^31-1)*(2^32) + (2^32-1) = 2^63 - 1`
		//
		// Thus, the new value of `cca` is such that `|cca| <= 2^32 - 1`.
		// The same applies to `ccb`.
		wa := a[k]
		wb := b[k]
		za := u64(wa) * pa + u64(wb) * pb + cca
		zb := u64(wa) * qa + u64(wb) * qb + ccb
		if k > 0 {
			a[k - 1] = u32(za & I31_MASK)
			b[k - 1] = u32(zb & I31_MASK)
		}

		// For the new values of `cca` and `ccb`, we need a signed
		// right-shift; since, in C, right-shifting a signed negative
		// value is implementation-defined, we use a custom portable
		// sign extension expression.
		M :: u64(1 << 32)
		cca = ((za >> 31) ~ M) - M
		ccb = ((zb >> 31) ~ M) - M
	}
	a[len(a) - 1] = u32(cca)
	b[len(a) - 1] = u32(ccb)

	nega := u32(cca >> 63)
	negb := u32(ccb >> 63)
	_i31_cond_negate(a, nega)
	_i31_cond_negate(b, negb)
	return nega | (negb << 1)
}

// Compute:
// 	`a <- (a*pa+b*pb)/(2^31) mod m`
// 	`b <- (a*qa+b*qb)/(2^31) mod m`
//
// 	`m0i` is equal to `-1/m[0] mod 2^31`.
//
// Factors `pa`, `pb`, `qa` and `qb` must be at most `2^31` in absolute value.
// Source integers `a` and `b` must be nonnegative; top word is not allowed
// to contain an extra 32th bit.
_i31_co_reduce_mod :: proc "contextless" (a: []u32, b: []u32, pa, pb, qa, qb: u64, m: []u32, m0i: u32) {
	cca := u64(0)
	ccb := u64(0)
	fa  := u64((a[0] * u32(pa) + b[0] * u32(pb)) * m0i) & I31_MASK
	fb  := u64((a[0] * u32(qa) + b[0] * u32(qb)) * m0i) & I31_MASK

	for k in 0..<len(a) {
		// In this loop, carries 'cca' and 'ccb' always fit on 33 bits
		// (in absolute value).
		wa := u64(a[k])
		wb := u64(b[k])
		za := wa * pa + wb * pb + u64(m[k]) * fa + cca
		zb := wa * qa + wb * qb + u64(m[k]) * fb + ccb
		if k > 0 {
			a[k - 1] = u32(za) & I31_MASK
			b[k - 1] = u32(zb) & I31_MASK
		}
		M :: u64(1 << 32)
		cca = ((za >> 31) ~ M) - M
		ccb = ((zb >> 31) ~ M) - M
	}
	a[len(a) - 1] = u32(cca)
	b[len(a) - 1] = u32(ccb)

	// At this point:
	// 	`-m <= a < 2*m`
	// 	`-m <= b < 2*m`
	//
	// 	(this is a case of Montgomery reduction)
	//
	// The top word of 'a' and 'b' may have a 32-th bit set.
	// We may have to add or subtract the modulus.
	_i31_finish_mod(a, m, u32(cca >> 63))
	_i31_finish_mod(b, m, u32(ccb >> 63))
}

// Compute `x/y % m`, result in `x`. Values `x` and `y` must be between
// `0` and `m-1`, and have the same announced bit length as `m`. Modulus
// `m` must be odd.
//
// The `m0i` parameter is equal to `-1/m mod 2^31`.
//
// The array 't' must point to a temporary area that can hold at least three
// integers of the size of `m`.
//
// `m` may not overlap `x` and `y`. `x` and `y` may overlap each other
// (this can be useful to test whether a value is invertible modulo `m`).
//
// `t` must be disjoint from all other arrays.
//
// Returned value is `1` on success, `0` otherwise. Success is attained if
// `y` is invertible modulo `m`.
@(require_results)
i31_moddiv :: proc "contextless" (x, y, m: []u32, m0i: u32, t: []u32) -> u32 {
	// Algorithm is an extended binary GCD. We maintain four values
	// a, b, u and v, with the following invariants:
	//
	//   a * x = y * u mod m
	//   b * x = y * v mod m
	//
	// Starting values are:
	//
	//   a = y
	//   b = m
	//   u = x
	//   v = 0
	//
	// The formal definition of the algorithm is a sequence of steps:
	// 	  - If a is even, then a <- a/2 and u <- u/2 mod m.
	//   - Otherwise, if b is even, then b <- b/2 and v <- v/2 mod m.
	//   - Otherwise, if a > b, then a <- (a-b)/2 and u <- (u-v)/2 mod m.
	//   - Otherwise, b <- (b-a)/2 and v <- (v-u)/2 mod m.
	//
	// Algorithm stops when a = b. At that point, they both are equal
	// to GCD(y,m); the modular division succeeds if that value is 1.
	// The result of the modular division is then u (or v: both are
	// equal at that point).
	//
	// Each step makes either a or b shrink by at least one bit; hence,
	// if m has bit length k bits, then 2k-2 steps are sufficient.
	//
	// Though complexity is quadratic in the size of m, the bit-by-bit
	// processing is not very efficient. We can speed up processing by
	// remarking that the decisions are taken based only on observation
	// of the top and low bits of a and b.
	// 	In the loop below, at each iteration, we use the two top words
	// of a and b, and the low words of a and b, to compute reduction
	// parameters pa, pb, qa and qb such that the new values for a
	// and b are:
	//
	//   a' = (a*pa + b*pb) / (2^31)
	//   b' = (a*qa + b*qb) / (2^31)
	//
	// the division being exact.
	//
	// Since the choices are based on the top words, they may be slightly
	// off, requiring an optional correction: if a' < 0, then we replace
	// pa with -pa, and pb with -pb. The total length of a and b is
	// thus reduced by at least 30 bits at each iteration.
	//
	// The stopping conditions are still the same, though: when a
	// and b become equal, they must be both odd (since m is odd,
	// the GCD cannot be even), therefore the next operation is a
	// subtraction, and one of the values becomes 0. At that point,
	// nothing else happens, i.e. one value is stuck at 0, and the
	// other one is the GCD.
	_len := uint(m[0] + 31) >> 5
	a := t[:_len]
	b := t[_len:2 * _len]
	u := x[1:]
	v := t[2 * _len:3 * _len]
	copy(a, y[1:])
	copy(b, m[1:])
	intrinsics.mem_zero(raw_data(v), len(v) * size_of(u32))

	 // Loop below ensures that a and b are reduced by some bits each,
	 // for a total of at least 30 bits.
	for num := ((m[0] - (m[0] >> 5)) << 1) + 30; num >= 30; num -= 30 {
		// Extract top words of a and b. If j is the highest
		// index >= 1 such that a[j] != 0 or b[j] != 0, then we want
		// (a[j] << 31) + a[j - 1], and (b[j] << 31) + b[j - 1].
		// If a and b are down to one word each, then we use a[0]
		// and b[0].
		a0, a1, b0, b1: u32
		c0, c1 := ~u32(0), ~u32(0) // -1
		for j := _len - 1; j > 0; j -= 1{
			aw := a[j]
			bw := b[j]
			a0 ~= (a0 ~ aw) & c0
			a1 ~= (a1 ~ aw) & c1
			b0 ~= (b0 ~ bw) & c0
			b1 ~= (b1 ~ bw) & c1
			c1 = c0
			c0 &= (((aw | bw) + I31_MASK) >> 31) - 1
		}

		// If c1 = 0, then we grabbed two words for a and b.
		// If c1 != 0 but c0 = 0, then we grabbed one word. It
		// is not possible that c1 != 0 and c0 != 0, because that
		// would mean that both integers are zero.
		a1 |= a0 & c1
		a0 &= ~c1
		b1 |= b0 & c1
		b0 &= ~c1
		a_hi := (u64(a0) << 31) + u64(a1)
		b_hi := (u64(b0) << 31) + u64(b1)
		a_lo := a[0]
		b_lo := b[0]

		// Compute reduction factors:
		//
		//   a' = a*pa + b*pb
		//   b' = a*qa + b*qb
		//
		// such that a' and b' are both multiple of 2^31, but are
		// only marginally larger than a and b.
		pa, pb, qa, qb: i64 = 1, 0, 0, 1
		for i in uint(0)..<31 {
			// At each iteration:
			//
			//   a <- (a-b)/2 if: a is odd, b is odd, a_hi > b_hi
			//   b <- (b-a)/2 if: a is odd, b is odd, a_hi <= b_hi
			//   a <- a/2 if: a is even
			//   b <- b/2 if: a is odd, b is even
			//
			// We multiply a_lo and b_lo by 2 at each
			// iteration, thus a division by 2 really is a
			// non-multiplication by 2.

			// r = GT(a_hi, b_hi)
			r := u32(subtle.gt(a_hi, b_hi))

			// cAB = 1 if b must be subtracted from a
			// cBA = 1 if a must be subtracted from b
			// cA = 1 if a is divided by 2, 0 otherwise
			//
			// Rules:
			//
			//   cAB and cBA cannot be both 1.
			//   if a is not divided by 2, b is.
			oa := (a_lo >> i) & 1
			ob := (b_lo >> i) & 1
			cAB := oa & ob & r
			cBA := oa & ob & subtle.not(r)
			cA := cAB | subtle.not(oa)

			// Conditional subtractions.
			a_lo -= b_lo & -cAB
			a_hi -= b_hi & -u64(cAB)
			pa -= qa & -i64(cAB)
			pb -= qb & -i64(cAB)
			b_lo -= a_lo & -cBA
			b_hi -= a_hi & -u64(cBA)
			qa -= pa & -i64(cBA)
			qb -= pb & -i64(cBA)

			// Shifting.
			a_lo += a_lo & (cA - 1)
			pa += pa & (i64(cA) - 1)
			pb += pb & (i64(cA) - 1)
			a_hi ~= (a_hi ~ (a_hi >> 1)) & -u64(cA)
			b_lo += b_lo & -cA
			qa += qa & -i64(cA)
			qb += qb & -i64(cA)
			b_hi ~= (b_hi ~ (b_hi >> 1)) & (u64(cA) - 1)
		}

		// Replace a and b with new values a' and b'.
		r := _i31_co_reduce(a, b, u64(pa), u64(pb), u64(qa), u64(qb))
		pa -= pa * (i64(r & 1) << 1)
		pb -= pb * (i64(r & 1) << 1)
		qa -= qa * i64(r & 2)
		qb -= qb * i64(r & 2)
		_i31_co_reduce_mod(u, v, u64(pa), u64(pb), u64(qa), u64(qb), m[1:], m0i)
	}

	// Now one of the arrays should be 0, and the other contains
	// the GCD. If a is 0, then u is 0 as well, and v contains
	// the division result.
	// Result is correct if and only if GCD is 1.
	r := (a[0] | b[0]) ~ 1
	u[0] |= v[0]
	for k := uint(1); k < _len; k += 1 {
		r |= a[k] | b[k]
		u[k] |= v[k]
	}
	return subtle.eq0(r)
}
