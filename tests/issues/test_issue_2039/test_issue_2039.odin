package test_issue_2039

import "core:testing"

VTable :: struct {
	get: proc(t: ^VTable) -> ^VTable,
}

Foo :: struct {
	pad:          int,
	using vtable: VTable,
}

Foo_Again :: struct {
	header:    [2]int,
	using foo: ^Foo,
}

Wrapper :: struct {
	using foo_again: Foo_Again,
}

get :: proc(t: ^VTable) -> ^VTable {
	return t
}

// Tests issue #2039 https://github.com/odin-lang/Odin/issues/2039
@(test)
test_issue_2039 :: proc(t: ^testing.T) {
	foo := Foo{vtable = {get = get}}
	foo_again := Foo_Again{foo = &foo}
	wrapper := Wrapper{foo_again = foo_again}

	// Converting through a 'using' pointer field refers to the pointed-to value
	testing.expect(t, foo_again->get() == &foo.vtable)
	testing.expect(t, wrapper->get() == &foo.vtable)

	from_value: ^VTable = foo_again
	testing.expect(t, from_value == &foo.vtable)

	from_pointer: ^VTable = &foo_again
	testing.expect(t, from_pointer == &foo.vtable)

	from_nested: ^VTable = wrapper
	testing.expect(t, from_nested == &foo.vtable)

	foo_ptr: ^Foo = wrapper
	testing.expect(t, foo_ptr == &foo)

	vtable: VTable = foo_again
	testing.expect(t, vtable.get == get)
}
