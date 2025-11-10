package test_internal

import "core:testing"



// https://github.com/odin-lang/Odin/pull/5908
@(test)
test_address_of_anonymous_global :: proc(t: ^testing.T) {
	// This loop exists so that we do more computation with stack memory
	// This increases the likelihood of catching a bug where anonymous globals are incorrectly allocated on the stack
	// instead of the data segment
	for _ in 0..<10 {
		testing.expect(t, global_variable.inner.field == 0xDEADBEEF)
	}
}

global_variable := Outer_Struct{
	inner = &Inner_Struct{
		field = 0xDEADBEEF,
	},
}
Outer_Struct :: struct{
	inner: ^Inner_Struct,

	// Must have a second field to prevent the compiler from simplifying the `Outer_Struct` type to `^Inner_Struct`
	// ...I think? In any case, don't remove this field
	_: int,
}
Inner_Struct :: struct{
	field: int,
}



// https://github.com/odin-lang/Odin/pull/5908
//
// Regression test for commit f1e3977cf94dfc0457f05d499cc280d8e1329086 where a larger anonymous global is needed to trigger
// the bug
@(test)
test_address_of_large_anonymous_global :: proc(t: ^testing.T) {
	// This loop exists so that we do more computation with stack memory
	// This increases the likelihood of catching a bug where anonymous globals are incorrectly allocated on the stack
	// instead of the data segment
	for _ in 0..<10 {
		for i in 0..<8 {
			testing.expect(t, global_variable_64.inner.field[i] == i)
		}
	}
}

#assert(size_of(Inner_Struct_64) == 64)
global_variable_64 := Outer_Struct_64{
	inner = &Inner_Struct_64{
		field = [8]int{0, 1, 2, 3, 4, 5, 6, 7},
	},
}
Outer_Struct_64 :: struct{
	inner: ^Inner_Struct_64,

	// Must have a second field to prevent the compiler from simplifying the `Outer_Struct` type to `^Inner_Struct`
	// ...I think? In any case, don't remove this field
	_: int,
}
Inner_Struct_64 :: struct{
	field: [8]int,
}
