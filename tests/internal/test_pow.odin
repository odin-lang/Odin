package test_internal_math_pow

import "core:fmt"
import "core:math"
import "core:os"
import "core:testing"

@test
pow_test :: proc(t: ^testing.T) {
	for exp in -2000..=2000 {
		{
			v1 := math.pow(2, f64(exp))
			v2 := math.pow2_f64(exp)
			_v1 := transmute(u64)v1
			_v2 := transmute(u64)v2
			expect(t, _v1 == _v2, fmt.tprintf("Expected math.pow2_f64(%d) == math.pow(2, %d) (= %x), got %x", exp, exp, v1, v2))
		}
		{
			v1 := math.pow(2, f32(exp))
			v2 := math.pow2_f32(exp)
			_v1 := transmute(u32)v1
			_v2 := transmute(u32)v2
			expect(t, _v1 == _v2, fmt.tprintf("Expected math.pow2_f32(%d) == math.pow(2, %d) (= %x), got %x", exp, exp, v1, v2))
		}
		{
			v1 := math.pow(2, f16(exp))
			v2 := math.pow2_f16(exp)
			_v1 := transmute(u16)v1
			_v2 := transmute(u16)v2
			expect(t, _v1 == _v2, fmt.tprintf("Expected math.pow2_f16(%d) == math.pow(2, %d) (= %x), got %x", exp, exp, v1, v2))
		}
	}
}

// -------- -------- -------- -------- -------- -------- -------- -------- -------- --------

main :: proc() {
	t := testing.T{}

	pow_test(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

TEST_count := 0
TEST_fail  := 0

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