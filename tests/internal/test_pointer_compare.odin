package test_internal

import "core:testing"

// Keeps the addresses out of constant folding, so the comparison is emitted as an icmp.
@(private="file")
not_const :: proc(v: $T) -> T { return v }

@(private="file")
LOW  :: uintptr(0x0000_0000_0000_1000)

@(private="file")
HIGH :: uintptr(1 << (8 * size_of(uintptr) - 1)) + 0x1000

@(test)
pointer_compare_is_unsigned :: proc(t: ^testing.T) {
	lo := not_const(transmute(^u8)LOW)
	hi := not_const(transmute(^u8)HIGH)
	testing.expect(t, hi > lo)
	testing.expect(t, hi >= lo)
	testing.expect(t, lo < hi)
	testing.expect(t, lo <= hi)
	testing.expect(t, !(hi < lo))
	testing.expect(t, !(lo > hi))
}

@(test)
multi_pointer_compare_is_unsigned :: proc(t: ^testing.T) {
	lo := not_const(transmute([^]u8)LOW)
	hi := not_const(transmute([^]u8)HIGH)
	testing.expect(t, hi > lo)
	testing.expect(t, hi >= lo)
	testing.expect(t, lo < hi)
	testing.expect(t, lo <= hi)
	testing.expect(t, !(hi < lo))
	testing.expect(t, !(lo > hi))
}

@(test)
rawptr_compare_is_unsigned :: proc(t: ^testing.T) {
	lo := not_const(transmute(rawptr)LOW)
	hi := not_const(transmute(rawptr)HIGH)
	testing.expect(t, hi > lo)
	testing.expect(t, lo < hi)
}

@(test)
pointer_compare_matches_uintptr :: proc(t: ^testing.T) {
	lo := not_const(transmute([^]u8)LOW)
	hi := not_const(transmute([^]u8)HIGH)
	testing.expect_value(t, hi > lo, uintptr(hi) > uintptr(lo))
	testing.expect_value(t, lo < hi, uintptr(lo) < uintptr(hi))
}
