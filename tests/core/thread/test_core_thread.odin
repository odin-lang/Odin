package test_core_thread

import "core:testing"
import "core:thread"
import "core:fmt"
import "core:os"

TEST_count := 0
TEST_fail  := 0

t := &testing.T{}

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.printf("[%v] %v\n", loc, message)
            return
        }
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
    }
}

main :: proc() {
	poly_data_test(t)

	if TEST_fail > 0 {
		os.exit(1)
	}
}

@(test)
poly_data_test :: proc(_t: ^testing.T) {
	MAX :: size_of(rawptr) * thread.MAX_USER_ARGUMENTS

	@static poly_data_test_t: ^testing.T
	poly_data_test_t = _t

	b: [MAX]byte = 8
	t1 := thread.create_and_start_with_poly_data(b, proc(b: [MAX]byte) {
		b_expect: [MAX]byte = 8
		expect(poly_data_test_t, b == b_expect, "thread poly data not correct")
	})
	defer free(t1)

	b1: [3]uintptr = 1
	b2: [MAX / 2]byte = 3
	t2 := thread.create_and_start_with_poly_data2(b1, b2, proc(b: [3]uintptr, b2: [MAX / 2]byte) {
		b_expect: [3]uintptr = 1
		b2_expect: [MAX / 2]byte = 3
		expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		expect(poly_data_test_t, b2 == b2_expect, "thread poly data not correct")
	})
	defer free(t2)

	t3 := thread.create_and_start_with_poly_data3(b1, b2, uintptr(333), proc(b: [3]uintptr, b2: [MAX / 2]byte, b3: uintptr) {
		b_expect: [3]uintptr = 1
		b2_expect: [MAX / 2]byte = 3

		expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		expect(poly_data_test_t, b2 == b2_expect, "thread poly data not correct")
		expect(poly_data_test_t, b3 == 333,       "thread poly data not correct")
	})
	defer free(t3)

	t4 := thread.create_and_start_with_poly_data4(uintptr(111), b1, uintptr(333), u8(5), proc(n: uintptr, b: [3]uintptr, n2: uintptr, n4: u8) {
		b_expect: [3]uintptr = 1

		expect(poly_data_test_t, n == 111,        "thread poly data not correct")
		expect(poly_data_test_t, b == b_expect,   "thread poly data not correct")
		expect(poly_data_test_t, n2 == 333,       "thread poly data not correct")
		expect(poly_data_test_t, n4 == 5,         "thread poly data not correct")
	})
	defer free(t4)

	thread.join_multiple(t1, t2, t3, t4)
}
