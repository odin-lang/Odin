package test_issue_udivmod128_zero_divisor

import "base:intrinsics"
import "base:runtime"
import "core:testing"

// Run with each non-trapping `-integer-division-by-zero` mode; the wide path used to loop ~2^64 times under `all-bits`
@test
test_udivmod128_zero_divisor :: proc(t: ^testing.T) {
	zero: u128
	zero = intrinsics.volatile_load(&zero)

	values := [?]u128{
		0,
		5,
		1 << 40,
		u128(max(u64)),
		1 << 64,
		1 << 64 | 5,
		0xdead_beef << 70 | 0x1234,
		max(u128),
	}
	for a in values {
		r: u128
		q := runtime.udivmod128(a, zero, &r)
		testing.expect_value(t, q, a / zero)
		testing.expect_value(t, r, a % zero)
	}
}
