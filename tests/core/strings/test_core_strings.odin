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
		{s = "Hello", start = 0, end = 0, sub = "", ok = true},
		{s = "Hello", start = 3, end = 3, sub = "", ok = true},
		{s = "Hello", start = len("Hello"), end = len("Hello"), sub = "", ok = true},
		{s = "Hello", end = len("Hello") + 1, sub = "Hello", ok = false},
		{s = "小猫咪", start = 0, end = 3, sub = "小猫咪", ok = true},
		{s = "小猫咪", start = 1, end = 3, sub = "猫咪", ok = true},
		{s = "小猫咪", start = 1, end = 5, sub = "猫咪", ok = false},
		{s = "小猫咪", start = 1, end = 1, sub = "", ok = true},
		{s = "小猫咪", start = 1, end = 1, sub = "", ok = true},
		{s = "小猫咪", start = 3, end = 3, sub = "", ok = true},
	}

	for tc in cases {
		sub, ok := strings.substring(tc.s, tc.start, tc.end)
		testing.expectf(t, ok == tc.ok, "expected %v[%v:%v] to return ok: %v", tc.s, tc.start, tc.end, tc.ok)
		testing.expectf(t, sub == tc.sub, "expected %v[%v:%v] to return sub: %v, got: %v", tc.s, tc.start, tc.end, tc.sub, sub)
	}
}

@(test)
test_substring_from :: proc(t: ^testing.T) {
	Case :: struct {
		s:     string,
		start: int,
		sub:   string,
		ok:    bool,
	}
	cases := []Case {
		{ok = true},
		{s = "", start = -1, ok = false},
		{s = "", start = 1, ok = false},
		{s = "Hello", start = 0, sub = "Hello", ok = true},
		{s = "Hello", start = 1, sub = "ello", ok = true},
		// rune_start one past the last rune: valid, empty tail (not out of bounds).
		{s = "Hello", start = len("Hello"), sub = "", ok = true},
		// rune_start genuinely out of bounds.
		{s = "Hello", start = len("Hello") + 1, ok = false},
		{s = "小猫咪", start = 0, sub = "小猫咪", ok = true},
		{s = "小猫咪", start = 1, sub = "猫咪", ok = true},
		// Same boundary case as above, but with multi-byte runes: the byte
		// length differs from the rune count, which is what used to trip
		// this up.
		{s = "小猫咪", start = 3, sub = "", ok = true},
		{s = "小猫咪", start = 4, ok = false},
		{s = "héllo", start = 5, sub = "", ok = true},
	}

	for tc in cases {
		sub, ok := strings.substring_from(tc.s, tc.start)
		testing.expectf(t, ok == tc.ok, "expected substring_from(%v, %v) to return ok: %v, got: %v", tc.s, tc.start, tc.ok, ok)
		testing.expectf(t, sub == tc.sub, "expected substring_from(%v, %v) to return sub: %v, got: %v", tc.s, tc.start, tc.sub, sub)
	}
}

@(test)
test_substring_to :: proc(t: ^testing.T) {
	Case :: struct {
		s:   string,
		end: int,
		sub: string,
		ok:  bool,
	}
	cases := []Case {
		{ok = true},
		{s = "", end = -1, ok = false},
		{s = "Hello", end = 0, sub = "", ok = true},
		{s = "Hello", end = 3, sub = "Hel", ok = true},
		// rune_end one past the last rune: valid, whole string.
		{s = "Hello", end = len("Hello"), sub = "Hello", ok = true},
		// rune_end genuinely out of bounds: fails, but keeps the (untrimmed) string.
		{s = "Hello", end = len("Hello") + 1, sub = "Hello", ok = false},
		{s = "小猫咪", end = 1, sub = "小", ok = true},
		{s = "小猫咪", end = 3, sub = "小猫咪", ok = true},
		{s = "小猫咪", end = 4, sub = "小猫咪", ok = false},
	}

	for tc in cases {
		sub, ok := strings.substring_to(tc.s, tc.end)
		testing.expectf(t, ok == tc.ok, "expected substring_to(%v, %v) to return ok: %v, got: %v", tc.s, tc.end, tc.ok, ok)
		testing.expectf(t, sub == tc.sub, "expected substring_to(%v, %v) to return sub: %v, got: %v", tc.s, tc.end, tc.sub, sub)
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
		{"Hellopé",         "Hellopé"},
		{"Hellope! €",      "Hellope! €"},
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

@test
test_compare_empty :: proc(t: ^testing.T) {
	buf: [1]u8
	empty := string(buf[:0])

	testing.expect_value(t, strings.compare("", empty), 0)
	testing.expect_value(t, strings.compare(empty, ""), 0)
	testing.expect(t, !("" < empty) && !(empty < ""), "two empty strings must not order before each other")
}

@test
test_non_zeroed_allocations :: proc(t: ^testing.T) {
	backing := make([]byte, 64 * mem.Kilobyte)
	defer delete(backing)
	// backing memory filled with 0xAA, so any byte left unwritten shows up
	mem.set(raw_data(backing), 0xAA, len(backing))

	arena: mem.Arena
	mem.arena_init(&arena, backing)
	a := mem.arena_allocator(&arena)

	expect_strings :: proc(t: ^testing.T, got, want: []string, loc := #caller_location) {
		if !testing.expectf(t, len(got) == len(want), "expected %v, got %v", want, got, loc = loc) {
			return
		}
		for _, i in want {
			testing.expectf(t, got[i] == want[i], "expected %v, got %v", want, got, loc = loc)
		}
	}

	testing.expect_value(t, strings.clone("Hello", a), "Hello")
	testing.expect_value(t, strings.clone("", a), "")

	cstr := strings.clone_to_cstring("Hello", a)
	testing.expect_value(t, string(cstr), "Hello")

	from_bytes := strings.clone_from_bytes(transmute([]byte)string("Hello"), a)
	testing.expect_value(t, from_bytes, "Hello")
	testing.expect_value(t, raw_data(from_bytes)[len(from_bytes)], 0)

	testing.expect_value(t, strings.join({"a", "bc", "def"}, ", ", a), "a, bc, def")
	testing.expect_value(t, strings.join({"a"}, ", ", a), "a")
	testing.expect_value(t, strings.concatenate({"a", "", "bc", "def"}, a), "abcdef")

	expect_strings(t, strings.split("anb", "", a), {"a", "n", "b"})
	expect_strings(t, strings.split_n("anb", "", 2, a), {"a", "nb"})
	expect_strings(t, strings.split_n("a,b", ",", 5, a), {"a", "b"})
	expect_strings(t, strings.split_multi("a,b;;c", {",", ";"}, a), {"a", "b", "", "c"})
	expect_strings(t, strings.fields("  a bb\t ccc ", a), {"a", "bb", "ccc"})
	// non-ASCII input goes to fields_proc
	expect_strings(t, strings.fields("  a bb\t ccc ñ ", a), {"a", "bb", "ccc", "ñ"})
	many := strings.fields(strings.repeat("ñ ", 40, a), a)
	testing.expect_value(t, len(many), 40)
	for field in many {
		testing.expect_value(t, field, "ñ")
	}

	testing.expect_value(t, strings.repeat("abc", 5, a), "abcabcabcabcabc")
	testing.expect_value(t, strings.repeat("abc", 0, a), "")

	replaced, _ := strings.replace("aXbXc", "X", "YYY", -1, a)
	testing.expect_value(t, replaced, "aYYYbYYYc")
	replaced, _ = strings.replace("aXXbXXc", "XX", "Y", 1, a)
	testing.expect_value(t, replaced, "aYbXXc")
	replaced, _ = strings.replace("añb", "", "-", -1, a)
	testing.expect_value(t, replaced, "-a-ñ-b-")

	testing.expect_value(t, strings.reverse("anb", a), "bna")
	testing.expect_value(t, strings.reverse("\xffa", a), "a\xff")

	long_a := strings.concatenate({strings.repeat("a", 80, a), "b"}, a)
	long_b := strings.concatenate({strings.repeat("a", 80, a), "c"}, a)
	testing.expect_value(t, strings.levenshtein_distance(long_a, long_b, a), 1)
	testing.expect_value(t, strings.levenshtein_distance("cat", long_b, a), 80)

	{
		m: strings.Intern
		strings.intern_init(&m, a)
		defer strings.intern_destroy(&m)

		hi, _ := strings.intern_get(&m, "Hi")
		testing.expect_value(t, hi, "Hi")
		empty, _ := strings.intern_get(&m, "")
		testing.expect_value(t, empty, "")
		interned_cstr, _ := strings.intern_get_cstring(&m, "Hi")
		testing.expect_value(t, string(interned_cstr), "Hi")
		testing.expect_value(t, raw_data(hi), (^byte)(interned_cstr))
	}

	{
		b := strings.builder_make_none(a)
		strings.builder_grow(&b, 8)
		strings.write_string(&b, "aXbXc")
		strings.builder_grow(&b, 32)
		strings.builder_replace_all(&b, "X", "YYY")
		testing.expect_value(t, strings.to_string(b), "aYYYbYYYc")
		strings.builder_replace_all(&b, "YYY", "Z")
		testing.expect_value(t, strings.to_string(b), "aZbZc")
		strings.builder_replace(&b, "", "-", -1)
		testing.expect_value(t, strings.to_string(b), "-a-Z-b-Z-c-")
		strings.builder_replace(&b, "-", "+++", 2)
		testing.expect_value(t, strings.to_string(b), "+++a+++Z-b-Z-c-")
	}
}
