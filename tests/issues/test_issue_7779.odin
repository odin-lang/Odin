package test_issues

import "base:runtime"
import "core:testing"
import "core:encoding/hex"

@(test)
test_issue_7779__decode_ok :: proc(t: ^testing.T) {
	// Make sure we don't break the OK case by accident...
	// Intentional leak, so we use the temp allocator.
	dst, ok := hex.decode(transmute([]u8)cast(string)"abcd", context.temp_allocator)
	testing.expect_value(t, ok, true)
	testing.expect_value(t, dst[0], 0xab)
	testing.expect_value(t, dst[1], 0xcd)
}

@(test)
test_issue_7779__decode_odd_length :: proc(t: ^testing.T) {
	dst, ok := hex.decode(transmute([]u8)cast(string)"abc")
	testing.expect_value(t, ok, false)
	testing.expect(t, dst == nil)
}

@(test)
test_issue_7779__decode_invalid_char :: proc(t: ^testing.T) {
	dst, ok := hex.decode(transmute([]u8)cast(string)"abzy")
	testing.expect_value(t, ok, false)
	testing.expect(t, dst == nil)
}

@(test)
test_issue_7779__allocator_error_encode :: proc(t: ^testing.T) {
	// Test that nothing crashes on allocation failure.
	allocator := runtime.nil_allocator()
	res, err := hex.encode({ 1, 2 }, allocator)
	testing.expect(t, err != nil)
	testing.expect(t, res == nil)
}

@(test)
test_issue_7779__allocator_error_encode_upper :: proc(t: ^testing.T) {
	// Test that nothing crashes on allocation failure.
	allocator := runtime.nil_allocator()
	res, err := hex.encode_upper({ 1, 2 }, allocator)
	testing.expect(t, err != nil)
	testing.expect(t, res == nil)
}

@(test)
test_issue_7779__allocator_error_decode :: proc(t: ^testing.T) {
	// Test that nothing crashes on allocation failure.
	allocator := runtime.nil_allocator()
	res, ok := hex.decode({ 21, 22 }, allocator)
	testing.expect_value(t, ok, false)
	testing.expect(t, res == nil)
}
