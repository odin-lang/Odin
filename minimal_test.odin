package test

import "core:fmt"

main :: proc() {
    // The bug involves the compiler handling enums backed by unsigned ints as signed ints

    // I have never seen it happen when working with enums directly
    Test_Enum :: enum u32 {
        SMALL_VALUE = 0xFF,
        BIG_VALUE   = 0xFF00_0000, // negative if interpreted as i32
    }
    // These will all evaluate to false
    fmt.printfln("Should be false. Got %t.", Test_Enum.SMALL_VALUE > Test_Enum.BIG_VALUE)
    fmt.printfln("Should be false. Got %t.", Test_Enum(0xF) > Test_Enum.BIG_VALUE)
    fmt.printfln("Should be false. Got %t.", Test_Enum(0xF) > Test_Enum(0xF000_0000))
    fmt.printfln("Should be false. Got %t.", Test_Enum.SMALL_VALUE > max(Test_Enum))
    fmt.printfln("Should be false. Got %t.", Test_Enum(0xF) > max(Test_Enum))

    // But I have seen it happen when working with enums generically
    test_proc :: proc(lhs: $T, rhs: T) -> bool {
        return lhs > rhs
    }
    // The enum value comparisons below are the same as the comparisons in the block above
    // These will all evaluate to true
    fmt.printfln("Should be false. Got %t.", test_proc(Test_Enum.SMALL_VALUE, Test_Enum.BIG_VALUE))
    fmt.printfln("Should be false. Got %t.", test_proc(Test_Enum(0xF), Test_Enum.BIG_VALUE))
    fmt.printfln("Should be false. Got %t.", test_proc(Test_Enum(0xF), Test_Enum(0xF000_0000)))
    fmt.printfln("Should be false. Got %t.", test_proc(Test_Enum.SMALL_VALUE, max(Test_Enum)))
    fmt.printfln("Should be false. Got %t.", test_proc(Test_Enum(0xF), max(Test_Enum)))
}
