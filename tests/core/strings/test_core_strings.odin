package test_core_image

import "core:strings"
import "core:testing"
import "core:fmt"
import "core:os"

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
	test_index_any_small_string_not_found(&t)
	test_index_any_larger_string_not_found(&t)
	test_index_any_small_string_found(&t)
	test_index_any_larger_string_found(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@test
test_index_any_small_string_not_found :: proc(t: ^testing.T) {
	index := strings.index_any(".", "/:\"")
	log(t, index)
	expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_larger_string_not_found :: proc(t: ^testing.T) {
	index := strings.index_any("aaaaaaaa.aaaaaaaa", "/:\"")
	expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_small_string_found :: proc(t: ^testing.T) {
	index := strings.index_any(".", "/:.\"")
	expect(t, index == 0, "index_any should be 0")
}

@test
test_index_any_larger_string_found :: proc(t: ^testing.T) {
	index := strings.index_any("aaaaaaaa:aaaaaaaa", "/:\"")
	expect(t, index == 8, "index_any should be 8")
}
