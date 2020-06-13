package win32_tests

import "core:fmt"
import "core:sys/win32"

main :: proc(){
    test_utf16_to_utf8 :: proc(str: []u16, comparison: string, expected_result: bool, loc := #caller_location) {
        result := win32.utf16_to_utf8(str[:]);
        fmt.assertf((result == comparison) == expected_result, 
                    "Incorrect utf16_to_utf8 conversion: %q %s %q\nloc = %#v\n", 
                    result, "!=" if expected_result else "==", comparison, loc);
    }

    test_utf16_to_utf8([]u16{}, "", true); 
    test_utf16_to_utf8([]u16{0}, "", true); 
    test_utf16_to_utf8([]u16{0, 't', 'e', 's', 't'}, "", true); 
    test_utf16_to_utf8([]u16{0, 't', 'e', 's', 't', 0}, "", true); 
    test_utf16_to_utf8([]u16{'t', 'e', 's', 't'}, "test", true); 
    test_utf16_to_utf8([]u16{'t', 'e', 's', 't', 0}, "test", true); 
    test_utf16_to_utf8([]u16{'t', 'e', 0, 's', 't'}, "te", true); 
    test_utf16_to_utf8([]u16{'t', 'e', 0, 's', 't', 0}, "te", true); 

    test_wstring_to_utf8 :: proc(str: []u16, comparison: string, expected_result: bool, loc := #caller_location) {
        result := win32.wstring_to_utf8(nil if len(str) == 0 else cast(win32.Wstring)&str[0], -1);
        fmt.assertf((result == comparison) == expected_result, 
                    "Incorrect wstring_to_utf8 conversion: %q %s %q\nloc = %#v\n", 
                    result, "!=" if expected_result else "==", comparison, loc);
    }

    test_wstring_to_utf8([]u16{}, "", true); 
    test_wstring_to_utf8([]u16{0}, "", true); 
    test_wstring_to_utf8([]u16{0, 't', 'e', 's', 't'}, "", true); 
    test_wstring_to_utf8([]u16{0, 't', 'e', 's', 't', 0}, "", true); 
    test_wstring_to_utf8([]u16{'t', 'e', 's', 't', 0}, "test", true); 
    test_wstring_to_utf8([]u16{'t', 'e', 0, 's', 't'}, "te", true); 
    test_wstring_to_utf8([]u16{'t', 'e', 0, 's', 't', 0}, "te", true); 

    // WARNING: Passing a non-zero-terminated string to wstring_to_utf8 is dangerous, 
    //          as it will go out of bounds looking for a zero. 
    //          It will "fail" or "succeed" by having a zero just after the end of the input string or not.
    test_wstring_to_utf8([]u16{'t', 'e', 's', 't'}, "test", false); 
    test_wstring_to_utf8([]u16{'t', 'e', 's', 't', 0}[:4], "test", true); 
    test_wstring_to_utf8([]u16{'t', 'e', 's', 't', 'q'}[:4], "test", false); 
}
