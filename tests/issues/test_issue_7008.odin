// Tests issue #7008 https://github.com/odin-lang/Odin/issues/7008
package test_issues

import "core:testing"
import "core:slice"

Bar :: struct {
	p: ^Foo,
}

Maybe_Bar :: union {
	Bar,
}

Foo :: struct {
	bar: Maybe_Bar,
	value: byte,
}

@(test)
test_offset_of_is_correct :: proc(t: ^testing.T) {
	foo: Foo
	foo.value = 42

	bytes := slice.bytes_from_ptr(&foo, size_of(Foo))
	testing.expect_value(t, bytes[offset_of(foo.value)], 42)
}
