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
