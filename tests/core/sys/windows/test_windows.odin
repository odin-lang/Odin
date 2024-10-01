#+build windows
package test_core_sys_windows

import "base:intrinsics"
import "base:runtime"
import win32 "core:sys/windows"
import "core:testing"

L :: intrinsics.constant_utf16_cstring
expectf :: testing.expectf

@(private)
expect_size :: proc(t: ^testing.T, $act: typeid, exp: int, loc := #caller_location) {
	expectf(t, size_of(act) == exp, "size_of(%v) should be %d was %d", typeid_of(act), exp, size_of(act), loc = loc)
}

@(private)
expect_value :: proc(t: ^testing.T, #any_int act: u32, #any_int exp: u32, loc := #caller_location) {
	expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp, loc = loc)
}

@(private)
expect_value_64 :: proc(t: ^testing.T, #any_int act: u64, #any_int exp: u64, loc := #caller_location) {
	expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp, loc = loc)
}

@(private)
expect_value_int :: proc(t: ^testing.T, act, exp: int, loc := #caller_location) {
	expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp, loc = loc)
}

@(private)
expect_value_uintptr :: proc(t: ^testing.T, act: uintptr, exp: int, loc := #caller_location) {
	expectf(t, act == uintptr(exp), "0x%8X (should be: 0x%8X)", act, uintptr(exp), loc = loc)
}

@(private)
expect_value_str :: proc(t: ^testing.T, wact, wexp: win32.wstring, loc := #caller_location) {
	act, exp: string
	err: runtime.Allocator_Error
	act, err = win32.wstring_to_utf8(wact, 16)
	expectf(t, err == .None, "0x%8X (should be: 0x%8X)", err, 0, loc = loc)
	exp, err = win32.wstring_to_utf8(wexp, 16)
	expectf(t, err == .None, "0x%8X (should be: 0x%8X)", err, 0, loc = loc)
	expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp, loc = loc)
}
