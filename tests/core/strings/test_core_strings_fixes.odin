package test_core_strings

import "base:runtime"
import "core:strings"
import "core:testing"

@(test)
test_fix_scrub :: proc(t: ^testing.T) {
	Case :: struct {
		s, replacement, want: string,
	}
	cases := []Case{
		{"",                     "?",      ""},
		{"abc",                  "?",      "abc"},
		{"a\xffb",               "?",      "a?b"},
		{"ab\xff",               "?",      "ab?"},
		{"\xffab",               "?",      "?ab"},
		{"\xff",                 "?",      "?"},
		{"Hello\xC0\x80World",   "?",      "Hello?World"},
		{"a\xff\xfe\xfdb",       "?",      "a?b"},
		{"a\xffb\xfec",          "?",      "a?b?c"},
		{"a\xe2\x82",            "?",      "a?"},
		{"a�b",             "?",      "a�b"},
		{"�\xff�",     "?",      "�?�"},
		{"a\xffb",               "",       "ab"},
		{"\xffa\xff",            "�", "�a�"},
	}
	for c in cases {
		res, err := strings.scrub(c.s, c.replacement)
		testing.expectf(t, err == nil && res == c.want, "scrub(%q, %q) = %q, %v; want %q", c.s, c.replacement, res, err, c.want)
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
		{"",                  4, ""},
		{"\t",                4, "    "},
		{"ab\tx",             4, "ab  x"},
		{"é\tx",         4, "é   x"},
		{"日本\tx",   4, "日本  x"},
		{"a\xff\tb",          4, "a\xff  b"},
		{"a\xff\xfeb",        4, "a\xff\xfeb"},
		{"a\nb\tc",           4, "a\nb   c"},
		{"éé\t\t.", 3, "éé    ."},
	}
	for c in cases {
		res, err := strings.expand_tabs(c.s, c.tab_size)
		testing.expectf(t, err == nil && res == c.want, "expand_tabs(%q, %d) = %q, %v; want %q", c.s, c.tab_size, res, err, c.want)
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
		{.Left,   "ab",     5, "\xffx",            "ab\xffx\xff"},
		{.Right,  "ab",     5, "\xffx",            "\xffx\xffab"},
		{.Centre, "x",      5, "€€aaaa", "€€x€€"},
		{.Centre, "é", 4, "ab",               "aéab"},
		{.Left,   "abc",    2, " ",                "abc"},
		{.Left,   "abc",    5, "",                 "abc"},
	}
	for c in cases {
		res: string
		err: runtime.Allocator_Error
		switch c.justify {
		case .Left:   res, err = strings.left_justify(c.str, c.length, c.pad)
		case .Right:  res, err = strings.right_justify(c.str, c.length, c.pad)
		case .Centre: res, err = strings.centre_justify(c.str, c.length, c.pad)
		}
		testing.expectf(t, err == nil && res == c.want, "%v(%q, %d, %q) = %q, %v; want %q", c.justify, c.str, c.length, c.pad, res, err, c.want)
		delete(res)
	}
}

@(test)
test_fix_allocation_failure :: proc(t: ^testing.T) {
	Case :: struct {
		name:    string,
		input:   string,
		convert: Case_Proc,
	}
	cases := []Case{
		{"scrub",          "\xff\xfeabc\xffdef\xfe", proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.scrub(s, "<replacement>", a) }},
		{"scrub",          "\xffabcdefghij\xffklmnopqrst", proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.scrub(s, "<replacement>", a) }},
		{"expand_tabs",    "a\tb\tc\td\te\tf\tg\th", proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.expand_tabs(s, 8, a) }},
		{"expand_tabs",    "\t\t\t\t",               proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.expand_tabs(s, 16, a) }},
		{"expand_tabs",    "\tabcdefghijklmnopqrstuvwxyz", proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.expand_tabs(s, 4, a) }},
		{"centre_justify", "x",                      proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.centre_justify(s, 5, "€€aaaa", a) }},
		{"left_justify",   "x",                      proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.left_justify(s, 9, "€€aaaa", a) }},
		{"right_justify",  "x",                      proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.right_justify(s, 9, "€€aaaa", a) }},
	}
	for c in cases {
		full, full_err := c.convert(c.input, context.allocator)
		defer delete(full)
		testing.expectf(t, full_err == nil, "%s: %v", c.name, full_err)

		for once in ([]bool{false, true}) {
			converted := false
			for n in 0..<32 {
				fa := Fail_After_Allocator{backing = context.allocator, left = n, once = once}
				res, err := c.convert(c.input, fail_after_allocator(&fa))
				if err != nil {
					testing.expectf(t, err == .Out_Of_Memory && res == "", "%s n=%d once=%v: %q, %v", c.name, n, once, res, err)
					continue
				}
				testing.expectf(t, res == full, "%s n=%d once=%v: %q, want %q", c.name, n, once, res, full)
				delete(res, fail_after_allocator(&fa))
				if !once || fa.left > 0 {
					converted = true
					break
				}
			}
			testing.expectf(t, converted, "%s once=%v never succeeded", c.name, once)
		}
	}
}
