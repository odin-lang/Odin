// Test for issue #6874 https://github.com/odin-lang/Odin/issues/6874

package test_issues

import "core:fmt"

PersonData :: struct {
    health: int,
    age: int,
}

MyUnion :: union {
    f32,
    int,
    PersonData,
}

change_union_data :: proc(data: MyUnion) {
    switch &v in data {
    case int:
        v = 10
    case f32:
        fmt.println("f32")
    case PersonData:
        fmt.println("PersonData")
        fmt.println(v)
    }
}

main :: proc() {
    val: MyUnion = int(12)
    fmt.printfln("Before the call: %v", val)
    change_union_data(val)
    fmt.printfln("After the call: %v", val)
}