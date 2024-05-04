package test_128

import "core:fmt"
import "core:os"
import "core:testing"

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

main :: proc() {
	t := testing.T{}

	test_128_align(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@test
test_128_align :: proc(t: ^testing.T) {
	Danger_Struct :: struct {
		x: u128,
		y: u64,
	}

	list := [?]Danger_Struct{{0, 0}, {1, 0}, {2, 0}, {3, 0}}

	expect(t, list[0].x == 0, fmt.tprintf("[0].x (%v) != 0", list[0].x))
	expect(t, list[0].y == 0, fmt.tprintf("[0].y (%v) != 0", list[0].y))

	expect(t, list[1].x == 1, fmt.tprintf("[1].x (%v) != 1", list[1].x))
	expect(t, list[1].y == 0, fmt.tprintf("[1].y (%v) != 0", list[1].y))

	expect(t, list[2].x == 2, fmt.tprintf("[2].x (%v) != 2", list[2].x))
	expect(t, list[2].y == 0, fmt.tprintf("[2].y (%v) != 0", list[2].y))

	expect(t, list[3].x == 3, fmt.tprintf("[3].x (%v) != 3", list[3].x))
	expect(t, list[3].y == 0, fmt.tprintf("[3].y (%v) != 0", list[3].y))
}
