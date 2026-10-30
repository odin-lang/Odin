#+build amd64
package test_issue_asm_pinned_clobbers

import "core:testing"

// The outputs are pinned to rax and rdx, which `div` also writes implicitly
udiv :: asm(u1, u0, v: u64) -> (q, r: u64) [u0 -> q = %rax, u1 -> r = %rdx] { div v }

// rax and rdx still hold the results of a 64-bit division when the template runs
two_digit :: #force_no_inline proc "contextless" (hi, lo, v: u64) -> (q_hi, q_lo, r: u64) {
	q_hi = hi / v
	q_lo, r = udiv(hi % v, lo, v)
	return
}

// The input is pinned to rax, which `mul` overwrites
mul_hi :: asm(x, y: u64) -> (hi: u64) [x = %rax] { mul y; mov hi, %rdx }

// x is used again afterwards, so it must not be assumed to still be in rax
mul_hi_keep :: #force_no_inline proc "contextless" (x, y: u64) -> (hi, x_after: u64) {
	hi = mul_hi(x, y)
	x_after = x
	return
}

@(test)
test_pinned_implicit_outputs :: proc(t: ^testing.T) {
	next :: proc(s: ^u64) -> u64 {
		s^ = s^*6364136223846793005 + 1442695040888963407
		return s^
	}

	s := u64(0x9e37_79b9_7f4a_7c15)
	for _ in 0..<10_000 {
		hi, lo, v := next(&s), next(&s), next(&s) | 1
		q_hi, q_lo, r := two_digit(hi, lo, v)
		n := u128(hi)<<64 | u128(lo)
		if u128(q_hi)<<64 | u128(q_lo) != n / u128(v) || u128(r) != n % u128(v) {
			testing.expectf(t, false, "%v / %v gave (%v:%v, %v)", n, v, q_hi, q_lo, r)
			return
		}

		mh, x_after := mul_hi_keep(hi, lo)
		if mh != u64((u128(hi) * u128(lo)) >> 64) || x_after != hi {
			testing.expectf(t, false, "mul_hi(%v, %v) gave (%v, %v)", hi, lo, mh, x_after)
			return
		}
	}
}
