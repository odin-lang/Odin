package test_core_thread

import "core:testing"
import "core:thread"
import "base:intrinsics"

@(test)
poly_data_test :: proc(_t: ^testing.T) {
	MAX :: size_of(rawptr) * thread.MAX_USER_ARGUMENTS

	@static poly_data_test_t: ^testing.T
	poly_data_test_t = _t

	b: [MAX]byte = 8
	t1 := thread.create_and_start_with_poly_data(b, proc(b: [MAX]byte) {
		b_expect: [MAX]byte = 8
		testing.expect(poly_data_test_t, b == b_expect, "thread poly data not correct")
	})
	defer free(t1)

	b1: [3]uintptr = 1
	b2: [MAX / 2]byte = 3
	t2 := thread.create_and_start_with_poly_data2(b1, b2, proc(b: [3]uintptr, b2: [MAX / 2]byte) {
		b_expect: [3]uintptr = 1
		b2_expect: [MAX / 2]byte = 3
		testing.expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		testing.expect(poly_data_test_t, b2 == b2_expect, "thread poly data not correct")
	})
	defer free(t2)

	t3 := thread.create_and_start_with_poly_data3(b1, b2, uintptr(333), proc(b: [3]uintptr, b2: [MAX / 2]byte, b3: uintptr) {
		b_expect: [3]uintptr = 1
		b2_expect: [MAX / 2]byte = 3

		testing.expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		testing.expect(poly_data_test_t, b2 == b2_expect, "thread poly data not correct")
		testing.expect(poly_data_test_t, b3 == 333,       "thread poly data not correct")
	})
	defer free(t3)

	t4 := thread.create_and_start_with_poly_data4(uintptr(111), b1, uintptr(333), u8(5), proc(n: uintptr, b: [3]uintptr, n2: uintptr, n4: u8) {
		b_expect: [3]uintptr = 1

		testing.expect(poly_data_test_t, n == 111,        "thread poly data not correct")
		testing.expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		testing.expect(poly_data_test_t, n2 == 333,       "thread poly data not correct")
		testing.expect(poly_data_test_t, n4 == 5,         "thread poly data not correct")
	})
	defer free(t4)

	thread.join_multiple(t1, t2, t3, t4)
}