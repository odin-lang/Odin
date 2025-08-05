package test_core_strings

import "base:runtime"
import "core:mem"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

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

@test
test_index_multi_overlapping_substrs :: proc(t: ^testing.T) {
	index, width := strings.index_multi("some example text", {"ample", "exam"})
	testing.expect_value(t, index, 5)
	testing.expect_value(t, width, 4)
}

@test
test_index_multi_not_found :: proc(t: ^testing.T) {
	index, _ := strings.index_multi("some example text", {"ey", "tey"})
	testing.expect_value(t, index, -1)
}

@test
test_index_multi_with_empty_string :: proc(t: ^testing.T) {
	index, _ := strings.index_multi("some example text", {"ex", ""})
	testing.expect_value(t, index, -1)
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

@test
test_builder_to_cstring_with_nil_allocator :: proc(t: ^testing.T) {
	b := strings.builder_make_none(mem.nil_allocator())

	cstr, err := strings.to_cstring(&b)
	testing.expect_value(t, cstr, nil)
	testing.expect_value(t, err, mem.Allocator_Error.Out_Of_Memory)
}

@test
test_builder_to_cstring :: proc(t: ^testing.T) {
	buf: [8]byte
	a: mem.Arena
	mem.arena_init(&a, buf[:])

	b := strings.builder_make_none(mem.arena_allocator(&a))

	{
		cstr, err := strings.to_cstring(&b)
		testing.expectf(t, cstr != nil, "expected cstr to not be nil, got %v", cstr)
		testing.expect_value(t, err, nil)
	}

	n := strings.write_byte(&b, 'a')
	testing.expect(t, n == 1)

	{
		cstr, err := strings.to_cstring(&b)
		testing.expectf(t, cstr != nil, "expected cstr to not be nil, got %v", cstr)
		testing.expect_value(t, err, nil)
	}

	n = strings.write_string(&b, "aaaaaaa")
	testing.expect(t, n == 7)

	{
		cstr, err := strings.to_cstring(&b)
		testing.expect(t, cstr == nil)
		testing.expect(t, err == .Out_Of_Memory)
	}
}

@test
test_prefix_length :: proc(t: ^testing.T) {
	prefix_length :: proc "contextless" (a, b: string) -> (n: int) {
		_len := min(len(a), len(b))

		// Scan for matches including partial codepoints.
		#no_bounds_check for n < _len && a[n] == b[n] {
			n += 1
		}

		// Now scan to ignore partial codepoints.
		if n > 0 {
			s := a[:n]
			n = 0
			for {
				r0, w := utf8.decode_rune(s[n:])
				if r0 != utf8.RUNE_ERROR {
					n += w
				} else {
					break
				}
			}
		}
		return
	}

	cases := [][2]string{
		{"Hellope, there!", "Hellope, world!"},
		{"Hellope, there!", "Foozle"},
		{"Hellope, there!", "Hell"},
		{"Hellope! 🦉",     "Hellope! 🦉"},
	}

	for v in cases {
		p_scalar := prefix_length(v[0], v[1])
		p_simd   := strings.prefix_length(v[0], v[1])
		testing.expect_value(t, p_simd, p_scalar)

		s := v[0]
		for len(s) > 0 {
			p_scalar = prefix_length(v[0], s)
			p_simd   = strings.prefix_length(v[0], s)
			testing.expect_value(t, p_simd, p_scalar)
			s = s[:len(s) - 1]
		}
	}
}