// Tests issue #6240 https://github.com/odin-lang/Odin/issues/6240
package test_issues

// should error - N=10 does not match bit_set range 0..<5
foo :: proc($N: int, b: $B/bit_set[0 ..< N]) {}

// should error without segfaulting - undefined identifier in bit_set range
bar :: proc(b: $B/bit_set[0 ..< asdf]) {}

main :: proc() {
	b: bit_set[0 ..< 5]
	foo(10, b)
	bar(bit_set[0 ..< 1]{})
}
