// The field comparison that guards this had been reading a type's name as its field list, so
// signatures this different were accepted whenever the two names differed in length
package test_issues

foreign import lib "this_library_does_not_exist"

Ints :: struct { a: i32, b: i32 }
Floats :: struct { c: f32, d: f32 }

@(default_calling_convention="c")
foreign lib {
	@(link_name="mismatched") mismatched_1 :: proc(x: []Ints) ---
}

@(default_calling_convention="c")
foreign lib {
	@(link_name="mismatched") mismatched_2 :: proc(x: []Floats) ---
}

// Two declarations of the same foreign symbol whose parameters reach a named struct through a
// slice or a field read the wrong member of the type union and segfaulted the compiler

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
