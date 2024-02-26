package test_core_strings

import "core:strings"
import "core:testing"
import "core:fmt"
import "core:os"
import "base:runtime"
import "core:mem"

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
	test_cut(&t)
	test_case_conversion(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
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

@test
test_last_index_any_small_string_found :: proc(t: ^testing.T) {
	index := strings.last_index_any(".", "/:.\"")
	expect(t, index == 0, "last_index_any should be 0")
}

@test
test_last_index_any_small_string_not_found :: proc(t: ^testing.T) {
	index := strings.last_index_any(".", "/:\"")
	expect(t, index == -1, "last_index_any should be -1")
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

Case_Kind :: enum {
	Lower_Space_Case,
	Upper_Space_Case,
	Lower_Snake_Case,
	Upper_Snake_Case,
	Lower_Kebab_Case,
	Upper_Kebab_Case,
	Camel_Case,
	Pascal_Case,
	Ada_Case,
}

Case_Proc :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error)

test_cases := [Case_Kind]struct{s: string, p: Case_Proc}{
	.Lower_Space_Case = {"hellope world", to_lower_space_case},
	.Upper_Space_Case = {"HELLOPE WORLD", to_upper_space_case},
	.Lower_Snake_Case = {"hellope_world", to_snake_case},
	.Upper_Snake_Case = {"HELLOPE_WORLD", to_upper_snake_case},
	.Lower_Kebab_Case = {"hellope-world", to_kebab_case},
	.Upper_Kebab_Case = {"HELLOPE-WORLD", to_upper_kebab_case},
	.Camel_Case       = {"hellopeWorld",  to_camel_case},
	.Pascal_Case      = {"HellopeWorld",  to_pascal_case},
	.Ada_Case         = {"Hellope_World", to_ada_case},
}

to_lower_space_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) {
	return strings.to_delimiter_case(r, ' ', false, allocator)
}
to_upper_space_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) {
	return strings.to_delimiter_case(r, ' ', true, allocator)
}

// NOTE: we have these wrappers as having #optional_allocator_error changes the type to not be equivalent
to_snake_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_snake_case(r, allocator) }
to_upper_snake_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_upper_snake_case(r, allocator) }
to_kebab_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_kebab_case(r, allocator) }
to_upper_kebab_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_upper_kebab_case(r, allocator) }
to_camel_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_camel_case(r, allocator) }
to_pascal_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_pascal_case(r, allocator) }
to_ada_case :: proc(r: string, allocator: runtime.Allocator) -> (string, mem.Allocator_Error) { return strings.to_ada_case(r, allocator) }

@test
test_case_conversion :: proc(t: ^testing.T) {
	for entry in test_cases {
		for test_case, case_kind in test_cases {
			result, err := entry.p(test_case.s, context.allocator)
			msg := fmt.tprintf("ERROR: We got the allocation error '{}'\n", err)
			expect(t, err == nil, msg)
			defer delete(result)

			msg = fmt.tprintf("ERROR: Input `{}` to converter {} does not match `{}`, got `{}`.\n", test_case.s, case_kind, entry.s, result)
			expect(t, result == entry.s, msg)
		}
	}
}