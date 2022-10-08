// Tests issue #2113 https://github.com/odin-lang/Odin/issues/2113
// Causes a panic on compilation
package test_issues

T :: struct {
    a: int,
}

main :: proc() {
    array: #soa[1]T
    a := &array[0]
    _ = a
}
