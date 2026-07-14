package test_issues

import "core:testing"

MyStruct :: struct {
    a: u32,
    b: u32,
    c: u32,
}

Foo :: struct {
    x: [15]u8, // errors with 11, 13, 14, 15
}


myfunc :: #force_no_inline proc( f: Foo ) -> bool {
	return f.x[0] == 45 && f.x[14] == 67
}

foreign import test_lib "build/test_issue_5640_c.o"

foreign test_lib {
	test_stack_next :: proc(
    	r0, r1, r2, r3, r4, r5, r6, r7: i64,
	    s: MyStruct,
		next_arg: i32,
	) -> bool ---
}

@test
test_stack_parameter_alignment_arm64_abi :: proc(t: ^testing.T) {
	s := MyStruct{ a = 42, b = 1337, c = 342 }

	res := test_stack_next(0, 1, 2, 3, 4, 5, 6, 7, s, 999)
	testing.expect(t, res == true)

	res_2 := myfunc({{45, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67}})
	testing.expect(t, res_2 == true)
}
