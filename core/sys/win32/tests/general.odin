package win32_tests

import win32 "core:sys/windows"
import "core:testing"

utf16_to_utf8 :: proc(t: ^testing.T, str: []u16, comparison: string, expected_result: bool, loc := #caller_location) {
    result, _ := win32.utf16_to_utf8(str[:])
    testing.expect(t, (result == comparison) == expected_result, "Incorrect utf16_to_utf8 conversion", loc)
}

wstring_to_utf8 :: proc(t: ^testing.T, str: []u16, comparison: string, expected_result: bool, loc := #caller_location) {
    result, _ := win32.wstring_to_utf8(nil if len(str) == 0 else cast(win32.Wstring)&str[0], -1)
    testing.expect(t, (result == comparison) == expected_result, "Incorrect wstring_to_utf8 conversion", loc)
}

@test
test_utf :: proc(t: ^testing.T) {
    utf16_to_utf8(t, []u16{}, "", true)
    utf16_to_utf8(t, []u16{0}, "", true)
    utf16_to_utf8(t, []u16{0, 't', 'e', 's', 't'}, "", true)
    utf16_to_utf8(t, []u16{0, 't', 'e', 's', 't', 0}, "", true)
    utf16_to_utf8(t, []u16{'t', 'e', 's', 't'}, "test", true)
    utf16_to_utf8(t, []u16{'t', 'e', 's', 't', 0}, "test", true)
    utf16_to_utf8(t, []u16{'t', 'e', 0, 's', 't'}, "te", true)
    utf16_to_utf8(t, []u16{'t', 'e', 0, 's', 't', 0}, "te", true)

    wstring_to_utf8(t, []u16{}, "", true)
    wstring_to_utf8(t, []u16{0}, "", true)
    wstring_to_utf8(t, []u16{0, 't', 'e', 's', 't'}, "", true)
    wstring_to_utf8(t, []u16{0, 't', 'e', 's', 't', 0}, "", true)
    wstring_to_utf8(t, []u16{'t', 'e', 's', 't', 0}, "test", true)
    wstring_to_utf8(t, []u16{'t', 'e', 0, 's', 't'}, "te", true)
    wstring_to_utf8(t, []u16{'t', 'e', 0, 's', 't', 0}, "te", true)

    // WARNING: Passing a non-zero-terminated string to wstring_to_utf8 is dangerous, 
    //          as it will go out of bounds looking for a zero. 
    //          It will "fail" or "succeed" by having a zero just after the end of the input string or not.
    wstring_to_utf8(t, []u16{'t', 'e', 's', 't'}, "test", false)
    wstring_to_utf8(t, []u16{'t', 'e', 's', 't', 0}[:4], "test", true)
    wstring_to_utf8(t, []u16{'t', 'e', 's', 't', 'q'}[:4], "test", false)
}