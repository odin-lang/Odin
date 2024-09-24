package test_core_strings

import "core:strings"
import "core:testing"
import "base:runtime"

@test
test_index_any_small_string_not_found :: proc(t: ^testing.T) {
	index := strings.index_any(".", "/:\"")
	testing.expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_larger_string_not_found :: proc(t: ^testing.T) {
	index := strings.index_any("aaaaaaaa.aaaaaaaa", "/:\"")
	testing.expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_small_string_found :: proc(t: ^testing.T) {
	index := strings.index_any(".", "/:.\"")
	testing.expect(t, index == 0, "index_any should be 0")
}

@test
test_index_any_larger_string_found :: proc(t: ^testing.T) {
	index := strings.index_any("aaaaaaaa:aaaaaaaa", "/:\"")
	testing.expect(t, index == 8, "index_any should be 8")
}

@test
test_last_index_any_small_string_found :: proc(t: ^testing.T) {
	index := strings.last_index_any(".", "/:.\"")
	testing.expect(t, index == 0, "last_index_any should be 0")
}

@test
test_last_index_any_small_string_not_found :: proc(t: ^testing.T) {
	index := strings.last_index_any(".", "/:\"")
	testing.expect(t, index == -1, "last_index_any should be -1")
}

Cut_Test :: struct {
	input:  string,
	offset: int,
	length: int,
	output: string,
}

cut_tests :: []Cut_Test{
	{"some example text", 0, 0, "some example text" },
	{"some example text", 0, 4, "some"              },
	{"some example text", 2, 2, "me"                },
	{"some example text", 5, 7, "example"           },
	{"some example text", 5, 0, "example text"      },
	{"恥ずべきフクロウ",        0, 0, "恥ずべきフクロウ"        },
	{"恥ずべきフクロウ",        4, 0, "フクロウ"             },
}

@test
test_cut :: proc(t: ^testing.T) {
	for test in cut_tests {
		res := strings.cut(test.input, test.offset, test.length)

		testing.expectf(
			t,
			res == test.output,
			"cut(\"%v\", %v, %v) expected to return \"%v\", got \"%v\"",
			test.input, test.offset, test.length, test.output, res,
		)
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

Case_Proc :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error)

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

to_lower_space_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	return strings.to_delimiter_case(r, ' ', false, allocator)
}
to_upper_space_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	return strings.to_delimiter_case(r, ' ', true, allocator)
}

// NOTE: we have these wrappers as having #optional_allocator_error changes the type to not be equivalent
to_snake_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_snake_case(r, allocator) }
to_upper_snake_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_upper_snake_case(r, allocator) }
to_kebab_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_kebab_case(r, allocator) }
to_upper_kebab_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_upper_kebab_case(r, allocator) }
to_camel_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_camel_case(r, allocator) }
to_pascal_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_pascal_case(r, allocator) }
to_ada_case :: proc(r: string, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_ada_case(r, allocator) }

@test
test_case_conversion :: proc(t: ^testing.T) {
	for entry in test_cases {
		for test_case, case_kind in test_cases {
			result, err := entry.p(test_case.s, context.allocator)
			testing.expectf(t, err == nil, "ERROR: We got the allocation error '{}'\n", err)
			defer delete(result)

			testing.expectf(t, result == entry.s, "ERROR: Input `{}` to converter {} does not match `{}`, got `{}`.\n", test_case.s, case_kind, entry.s, result)
		}
	}
}

@(test)
test_substring :: proc(t: ^testing.T) {
	Case :: struct {
		s:     string,
		start: int,
		end:   int,
		sub:   string,
		ok:    bool,
	}
	cases := []Case {
		{ok = true},
		{s = "", start = -1, ok = false},
		{s = "", end = -1, ok = false},
		{s = "", end = +1, ok = false},
		{s = "Hello", end = len("Hello"), sub = "Hello", ok = true},
		{s = "Hello", start = 1, end = len("Hello"), sub = "ello", ok = true},
		{s = "Hello", start = 1, end = len("Hello") - 1, sub = "ell", ok = true},
		{s = "Hello", end = len("Hello") + 1, sub = "Hello", ok = false},
		{s = "小猫咪", start = 0, end = 3, sub = "小猫咪", ok = true},
		{s = "小猫咪", start = 1, end = 3, sub = "猫咪", ok = true},
		{s = "小猫咪", start = 1, end = 5, sub = "猫咪", ok = false},
		{s = "小猫咪", start = 1, end = 1, sub = "", ok = true},
	}

	for tc in cases {
		sub, ok := strings.substring(tc.s, tc.start, tc.end)
		testing.expectf(t, ok == tc.ok, "expected %v[%v:%v] to return ok: %v", tc.s, tc.start, tc.end, tc.ok)
		testing.expectf(t, sub == tc.sub, "expected %v[%v:%v] to return sub: %v, got: %v", tc.s, tc.start, tc.end, tc.sub, sub)
	}
}
