package test_core_bytes

import "base:runtime"
import "core:bytes"
import "core:testing"

@(test)
test_fix_scrub :: proc(t: ^testing.T) {
	Case :: struct {
		s, replacement, want: string,
	}
	cases := []Case{
		{"",                   "?",      ""},
		{"abc",                "?",      "abc"},
		{"a\xffb",             "?",      "a?b"},
		{"ab\xff",             "?",      "ab?"},
		{"\xffab",             "?",      "?ab"},
		{"Hello\xC0\x80World", "?",      "Hello?World"},
		{"a\xff\xfe\xfdb",     "?",      "a?b"},
		{"a\xffb\xfec",        "?",      "a?b?c"},
		{"a�b",           "?",      "a�b"},
		{"a\xffb",             "",       "ab"},
		{"\xffa\xff",          "�", "�a�"},
	}
	for c in cases {
		res, err := bytes.scrub(transmute([]byte)c.s, transmute([]byte)c.replacement)
		testing.expectf(t, err == nil && string(res) == c.want, "scrub(%q, %q) = %q, %v; want %q", c.s, c.replacement, string(res), err, c.want)
		delete(res)
	}
}

@(test)
test_fix_expand_tabs :: proc(t: ^testing.T) {
	Case :: struct {
		s:        string,
		tab_size: int,
		want:     string,
	}
	cases := []Case{
		{"\t",              4, "    "},
		{"ab\tx",           4, "ab  x"},
		{"é\tx",       4, "é   x"},
		{"日本\tx", 4, "日本  x"},
		{"a\xff\tb",        4, "a\xff  b"},
		{"a\nb\tc",         4, "a\nb   c"},
	}
	for c in cases {
		res, err := bytes.expand_tabs(transmute([]byte)c.s, c.tab_size)
		testing.expectf(t, err == nil && string(res) == c.want, "expand_tabs(%q, %d) = %q, %v; want %q", c.s, c.tab_size, string(res), err, c.want)
		delete(res)
	}
}

@(test)
test_fix_justify :: proc(t: ^testing.T) {
	Justify :: enum { Left, Right, Centre }
	Case :: struct {
		justify: Justify,
		str:     string,
		length:  int,
		pad:     string,
		want:    string,
	}
	cases := []Case{
		{.Left,   "abc",    5, " ",                "abc  "},
		{.Right,  "abc",    5, " ",                "  abc"},
		{.Centre, "abc",    6, " ",                " abc  "},
		{.Left,   "é", 3, ".",                "é.."},
		{.Right,  "ab",     5, "\xffx",            "\xffx\xffab"},
		{.Centre, "x",      5, "€€aaaa", "€€x€€"},
		{.Left,   "abc",    2, " ",                "abc"},
	}
	for c in cases {
		str := transmute([]byte)c.str
		pad := transmute([]byte)c.pad
		res: []byte
		err: runtime.Allocator_Error
		switch c.justify {
		case .Left:   res, err = bytes.left_justify(str, c.length, pad)
		case .Right:  res, err = bytes.right_justify(str, c.length, pad)
		case .Centre: res, err = bytes.centre_justify(str, c.length, pad)
		}
		testing.expectf(t, err == nil && string(res) == c.want, "%v(%q, %d, %q) = %q, %v; want %q", c.justify, c.str, c.length, c.pad, string(res), err, c.want)
		delete(res)
	}

	buf: [4]byte
	empty := buf[:0]
	for j in Justify {
		res: []byte
		err: runtime.Allocator_Error
		switch j {
		case .Left:   res, err = bytes.left_justify(transmute([]byte)string("ab"), 5, empty)
		case .Right:  res, err = bytes.right_justify(transmute([]byte)string("ab"), 5, empty)
		case .Centre: res, err = bytes.centre_justify(transmute([]byte)string("ab"), 5, empty)
		}
		testing.expectf(t, err == nil && string(res) == "ab", "%v with an empty pad: %q, %v", j, string(res), err)
		delete(res)
	}
}

@(test)
test_fix_reverse_allocator :: proc(t: ^testing.T) {
	fa := Failing_Allocator{backing = context.allocator, left = 0}
	res, err := bytes.reverse(transmute([]byte)string("abc"), failing_allocator(&fa))
	testing.expectf(t, err == .Out_Of_Memory && res == nil, "reverse with a failing allocator: %q, %v", string(res), err)

	fa = Failing_Allocator{backing = context.allocator, left = 1}
	res, err = bytes.reverse(transmute([]byte)string("abé"), failing_allocator(&fa))
	testing.expectf(t, err == nil && string(res) == "éba", "reverse: %q, %v", string(res), err)
	testing.expect_value(t, fa.left, 0)
	delete(res, failing_allocator(&fa))
}

@(test)
test_fix_allocation_failure :: proc(t: ^testing.T) {
	Convert :: proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error)
	Case :: struct {
		name:    string,
		input:   string,
		convert: Convert,
	}
	cases := []Case{
		{"scrub",          "\xff\xfeabc\xffdef\xfe", proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.scrub(s, transmute([]byte)string("<replacement>"), a) }},
		{"scrub",          "\xffabcdefghij\xffklmnopqrst", proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.scrub(s, transmute([]byte)string("<replacement>"), a) }},
		{"expand_tabs",    "a\tb\tc\td\te\tf\tg\th", proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.expand_tabs(s, 8, a) }},
		{"expand_tabs",    "\t\t\t\t",               proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.expand_tabs(s, 16, a) }},
		{"expand_tabs",    "\tabcdefghijklmnopqrstuvwxyz", proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.expand_tabs(s, 4, a) }},
		{"centre_justify", "x",                      proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.centre_justify(s, 5, transmute([]byte)string("€€aaaa"), a) }},
		{"left_justify",   "x",                      proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.left_justify(s, 9, transmute([]byte)string("€€aaaa"), a) }},
		{"right_justify",  "x",                      proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.right_justify(s, 9, transmute([]byte)string("€€aaaa"), a) }},
		{"reverse",        "abé",               proc(s: []byte, a: runtime.Allocator) -> ([]byte, runtime.Allocator_Error) { return bytes.reverse(s, a) }},
	}
	for c in cases {
		input := transmute([]byte)c.input
		full, full_err := c.convert(input, context.allocator)
		defer delete(full)
		testing.expectf(t, full_err == nil, "%s: %v", c.name, full_err)

		for once in ([]bool{false, true}) {
			converted := false
			for n in 0..<32 {
				fa := Failing_Allocator{backing = context.allocator, left = n, once = once}
				res, err := c.convert(input, failing_allocator(&fa))
				if err != nil {
					testing.expectf(t, err == .Out_Of_Memory && len(res) == 0, "%s n=%d once=%v: %q, %v", c.name, n, once, string(res), err)
					continue
				}
				testing.expectf(t, string(res) == string(full), "%s n=%d once=%v: %q, want %q", c.name, n, once, string(res), string(full))
				delete(res, failing_allocator(&fa))
				if !once || fa.left > 0 {
					converted = true
					break
				}
			}
			testing.expectf(t, converted, "%s once=%v never succeeded", c.name, once)
		}
	}
}

@(test)
test_fix_split_empty_separator :: proc(t: ^testing.T) {
	src   := "aé€b"
	s     := transmute([]byte)src
	runes := []string{"a", "é", "€", "b"}

	for sep, k in ([][]byte{nil, s[:0]}) {
		parts := bytes.split(s, sep)
		expect_parts(t, parts, runes, "split", k)
		delete(parts)

		parts = bytes.split_after(s, sep)
		expect_parts(t, parts, runes, "split_after", k)
		delete(parts)

		parts = bytes.split_n(s, sep, 2)
		expect_parts(t, parts, {"a", "é€b"}, "split_n", k)
		delete(parts)

		parts = bytes.split(s[:0], sep)
		expect_parts(t, parts, {}, "split of an empty slice", k)
		delete(parts)

		it := s
		i := 0
		for part in bytes.split_iterator(&it, sep) {
			if !testing.expectf(t, i < len(runes), "split_iterator sep %d: more than %d parts", k, len(runes)) {
				break
			}
			testing.expectf(t, string(part) == runes[i], "split_iterator sep %d part %d: %q, want %q", k, i, string(part), runes[i])
			i += 1
		}
		testing.expectf(t, i == len(runes), "split_iterator sep %d: %d parts, want %d", k, i, len(runes))
	}
}

expect_parts :: proc(t: ^testing.T, parts: [][]byte, want: []string, what: string, sep: int, loc := #caller_location) {
	testing.expectf(t, len(parts) == len(want), "%s sep %d: %d parts, want %d", what, sep, len(parts), len(want), loc = loc)
	for part, i in parts[:min(len(parts), len(want))] {
		testing.expectf(t, string(part) == want[i], "%s sep %d part %d: %q, want %q", what, sep, i, string(part), want[i], loc = loc)
	}
}

Failing_Allocator :: struct {
	backing: runtime.Allocator,
	left:    int,
	once:    bool,
}

failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.left == 0 {
			if fa.once {
				fa.left = -1
			}
			return nil, .Out_Of_Memory
		}
		if fa.left > 0 {
			fa.left -= 1
		}
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}
