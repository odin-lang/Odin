package test_issue_7779

import "base:runtime"
import "core:testing"
import "core:encoding/hex"

@(test)
test_issue_7779__decode_ok :: proc(t: ^testing.T) {
	// Make sure we don't break the OK case by accident...
	// Intentional leak, so we use the temp allocator.
	dst, err := hex.decode(transmute([]u8)cast(string)"abcd", context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, dst[0], 0xab)
	testing.expect_value(t, dst[1], 0xcd)
}

@(test)
test_issue_7779__decode_odd_length :: proc(t: ^testing.T) {
	dst, err := hex.decode(transmute([]u8)cast(string)"abc")
	testing.expect_value(t, err, hex.Decode_Error.Invalid_Length)
	testing.expect(t, dst == nil)
}

@(test)
test_issue_7779__decode_invalid_char :: proc(t: ^testing.T) {
	dst, err := hex.decode(transmute([]u8)cast(string)"abzy")
	testing.expect_value(t, err, hex.Decode_Error.Invalid_Character)
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
	res, err := hex.decode({ 21, 22 }, allocator)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, res == nil)
}
