package test_core_strings

import "base:runtime"
import "core:strings"
import "core:testing"

@(test)
test_fix_conversion_allocation_failure :: proc(t: ^testing.T) {
	Conversion :: struct {
		name:    string,
		input:   string,
		convert: Case_Proc,
	}
	conversions := []Conversion{
		{"to_lower",            "\xff\xfe\xfdABC",          proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_lower(s, a) }},
		{"to_upper",            "\xff\xfe\xfdabc",          proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_upper(s, a) }},
		{"to_valid_utf8",       "a\xffb\xfec\xfdd\xfce",    proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_valid_utf8(s, "[?]", a) }},
		{"to_valid_utf8",       "a\xffb\xff",               proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_valid_utf8(s, "[?]", a) }},
		{"to_valid_utf8",       "\xffa\xffé",          proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_valid_utf8(s, "[?]", a) }},
		{"to_valid_utf8",       "\xffa\xffb",               proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_valid_utf8(s, "[?]", a) }},
		{"to_camel_case",       "\xff\xfe hello world",     proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_camel_case(s, a) }},
		{"to_pascal_case",      "\xff\xfe hello world",     proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_pascal_case(s, a) }},
		{"to_delimiter_case",   "\xff\xfeHelloWorld",       proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_delimiter_case(s, ' ', false, a) }},
		{"to_snake_case",       "\xff\xfeHelloWorld",       proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_snake_case(s, a) }},
		{"to_upper_snake_case", "\xff\xfeHelloWorld",       proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_upper_snake_case(s, a) }},
		{"to_kebab_case",       "\xff\xfeHelloWorld",       proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_kebab_case(s, a) }},
		{"to_upper_kebab_case", "\xff\xfeHelloWorld",       proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_upper_kebab_case(s, a) }},
		{"to_ada_case",         "\xff\xfe hello world",     proc(s: string, a: runtime.Allocator) -> (string, runtime.Allocator_Error) { return strings.to_ada_case(s, a) }},
	}
	for c in conversions {
		full, full_err := c.convert(c.input, context.allocator)
		defer delete(full)
		testing.expectf(t, full_err == nil, "%s: %v", c.name, full_err)
		testing.expectf(t, len(full) > len(c.input), "%s: %q must outgrow %q", c.name, full, c.input)

		for once in ([]bool{false, true}) {
			converted := false
			for n in 0..<32 {
				fa := Fail_After_Allocator{backing = context.allocator, left = n, once = once}
				res, err := c.convert(c.input, fail_after_allocator(&fa))
				if err != nil {
					testing.expectf(t, err == .Out_Of_Memory && res == "", "%s %q n=%d once=%v: %q, %v", c.name, c.input, n, once, res, err)
					continue
				}
				testing.expectf(t, res == full, "%s %q n=%d once=%v: %q, want %q", c.name, c.input, n, once, res, full)
				delete(res, fail_after_allocator(&fa))
				if !once || fa.left > 0 {
					converted = true
					break
				}
			}
			testing.expectf(t, converted, "%s %q once=%v never succeeded", c.name, c.input, once)
		}
	}
}

Fail_After_Allocator :: struct {
	backing: runtime.Allocator,
	left:    int,
	once:    bool,
}

fail_after_allocator :: proc(fa: ^Fail_After_Allocator) -> runtime.Allocator {
	return {procedure = fail_after_allocator_proc, data = fa}
}

fail_after_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Fail_After_Allocator)(data)
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
