package test_core_strings

import "core:strings"
import "core:testing"
import "core:fmt"
import "core:os"


expect  :: testing.expect
log     :: testing.log

main :: proc() {
	t := testing.T{}
	test_index_any_small_string_not_found(&t)
	test_index_any_larger_string_not_found(&t)
	test_index_any_small_string_found(&t)
	test_index_any_larger_string_found(&t)
	test_cut(&t)

	if t.error_count > 0 {
		os.exit(1)
	}
}

@test
test_index_any_small_string_not_found :: proc(t: ^testing.T) {
	index := strings.index_any(".", "/:\"")
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

Cut_Test :: struct {
	input:  string,
	offset: int,
	length: int,
	output: string,
}

cut_tests :: []Cut_Test{
	{"some example text", 0, 4, "some"        },
	{"some example text", 2, 2, "me"          },
	{"some example text", 5, 7, "example"     },
	{"some example text", 5, 0, "example text"},
	{"恥ずべきフクロウ",        4, 0, "フクロウ"       },
}

@test
test_cut :: proc(t: ^testing.T) {
	for test in cut_tests {
		res := strings.cut(test.input, test.offset, test.length)
		defer delete(res)

		msg := fmt.tprintf("cut(\"%v\", %v, %v) expected to return \"%v\", got \"%v\"",
			test.input, test.offset, test.length, test.output, res)
		expect(t, res == test.output, msg)
	}
}