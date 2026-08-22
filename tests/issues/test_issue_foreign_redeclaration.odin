// Two declarations of the same foreign symbol whose parameters reach a named struct through a
// slice or a field read the wrong member of the type union and segfaulted the compiler
package test_issues

foreign import lib "this_library_does_not_exist"

Inner :: struct { a: i32, b: i32 }
Other :: struct { c: i32, d: i32 }

Wrap1 :: struct { f: Inner }
Wrap2 :: struct { f: Other }

@(default_calling_convention="c")
foreign lib {
	@(link_name="via_slice") slice_1 :: proc(x: []Inner) ---
	@(link_name="via_field") field_1 :: proc(x: Wrap1) ---
}

@(default_calling_convention="c")
foreign lib {
	@(link_name="via_slice") slice_2 :: proc(x: []Other) ---
	@(link_name="via_field") field_2 :: proc(x: Wrap2) ---
}
