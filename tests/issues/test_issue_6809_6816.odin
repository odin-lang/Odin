// Tests issue: https://github.com/odin-lang/Odin/issues/6809
// & https://github.com/odin-lang/Odin/issues/6816

package test_issues

import "core:testing"

foreign import test_lib "build/test_issue_6809_6816_c.o"

foreign test_lib {
    test_i8   :: proc "c" (val: i8) -> bool ---
    test_u8   :: proc "c" (val: u8) -> bool ---
    test_bool :: proc "c" (val: bool) -> bool ---
}

@test
test_macos_proc_argument_abi :: proc(t: ^testing.T) {

    res_i8 := test_i8(-1)
    testing.expectf(t, res_i8 == true, "test_i8(-1) -> Expected: true, Got: %v\n", res_i8)

    res_u8 := test_u8(200)
    testing.expectf(t, res_u8 == true, "test_u8(200) -> Expected: true, Got: %v\n", res_u8)

    res_bool := test_bool(true)
    testing.expectf(t, res_bool == true, "test_bool(true) -> Expected: true, Got: %v\n", res_bool)
}
