package test_internal

import "core:testing"

// #force_no_inline so conversions are not folded;
// they must go through the runtime __fixunsdfti/__fixdfti
@(private="file") f64_to_u128 :: #force_no_inline proc(f: f64) -> u128 { return u128(f) }
@(private="file") f64_to_i128 :: #force_no_inline proc(f: f64) -> i128 { return i128(f) }
@(private="file") f32_to_u128 :: #force_no_inline proc(f: f32) -> u128 { return u128(f) }
@(private="file") f32_to_i128 :: #force_no_inline proc(f: f32) -> i128 { return i128(f) }

@test
test_f64_to_u128 :: proc(t: ^testing.T) {
	testing.expect_value(t, f64_to_u128(2.75), 2) // trunc toward 0
	testing.expect_value(t, f64_to_u128(0.75), 0) // < 1
	testing.expect_value(t, f64_to_u128(-3.5), 0) // negative to 0
	testing.expect_value(t, f64_to_u128(f64(1 << 51)), u128(1) << 51) // significand shifts right
	testing.expect_value(t, f64_to_u128(f64(1 << 52)), u128(1) << 52) // no shift
	testing.expect_value(t, f64_to_u128(f64(1 << 53)), u128(1) << 53) // significand shifts left
	testing.expect_value(t, f64_to_u128(1e19), 10_000_000_000_000_000_000)
	testing.expect_value(t, f64_to_u128(f64(1 << 80)), u128(1) << 80) // > max(u64)
	testing.expect_value(t, f64_to_u128(2 * f64(1 << 127)), max(u128)) // out of range saturates, implementation specific
}

@test
test_f64_to_i128 :: proc(t: ^testing.T) {
	testing.expect_value(t, f64_to_i128(-2.75), -2) // trunc toward 0
	testing.expect_value(t, f64_to_i128(-0.75), 0)  // |f| < 1
	testing.expect_value(t, f64_to_i128(1e19), 10_000_000_000_000_000_000) // > max(i64)
	testing.expect_value(t, f64_to_i128(f64(-(1 << 80))), -(i128(1) << 80))
	testing.expect_value(t, f64_to_i128(f64(1 << 126)), i128(1) << 126)
	testing.expect_value(t, f64_to_i128(f64(min(i128))), min(i128)) // exact
	// out of range saturates, implementation specific
	testing.expect_value(t, f64_to_i128(f64(1 << 127)), max(i128))
	testing.expect_value(t, f64_to_i128(2 * f64(1 << 127)), max(i128))
}

@test
test_f32_to_u128 :: proc(t: ^testing.T) {
	testing.expect_value(t, f32_to_u128(2.75), 2) // trunc toward 0
	testing.expect_value(t, f32_to_u128(f32(1 << 80)), u128(1) << 80) // > max(u64)
}

@test
test_f32_to_i128 :: proc(t: ^testing.T) {
	testing.expect_value(t, f32_to_i128(-2.75), -2) // trunc toward 0
	testing.expect_value(t, f32_to_i128(f32(-(1 << 80))), -(i128(1) << 80))
}
