package test_core_fmt

import "core:fmt"
import "core:strings"
import "core:testing"

// Arrays of plain integers skip `_fmt_arg` for each element. They must print as their elements do one at a time,
// endian-specific and 128-bit integers included.

@(private="file")
Distinct_Int :: distinct int

@(private="file")
ARRAY_VERBS := [?]string{"%v", "%d", "%x", "%X", "%b", "%o", "%z", "%5d", "%-4x", "%+d", "%c", "%f", "%#v"}

@(private="file")
check_array :: proc(t: ^testing.T, values: []$T, loc := #caller_location) {
	for verb in ARRAY_VERBS {
		sb := strings.builder_make(context.temp_allocator)
		hash := verb == "%#v"
		strings.write_byte(&sb, '[')
		if hash {
			strings.write_byte(&sb, '\n')
		}
		for v, i in values {
			switch {
			case hash:   strings.write_byte(&sb, '\t')
			case i > 0:  strings.write_string(&sb, ", ")
			}
			fmt.sbprintf(&sb, verb, v)
			if hash {
				strings.write_string(&sb, ",\n")
			}
		}
		strings.write_byte(&sb, ']')

		want := strings.to_string(sb)
		got  := fmt.tprintf(verb, values)
		testing.expectf(t, got == want, "(%s, %T): got %q, want %q", verb, values, got, want, loc = loc)
	}
}

@(test)
test_fmt_integer_arrays :: proc(t: ^testing.T) {
	check_array(t, []i8{-128, -1, 0, 1, 127})
	check_array(t, []u8{0, 1, 0x7f, 0x80, 0xff})
	check_array(t, []i16{min(i16), -2, 0, 300, max(i16)})
	check_array(t, []u16{0, 1, 0x1234, max(u16)})
	check_array(t, []i32{min(i32), -70000, 0, 70000, max(i32)})
	check_array(t, []u32{0, 1, 0xdeadbeef, max(u32)})
	check_array(t, []i64{min(i64), -1, 0, max(i64)})
	check_array(t, []u64{0, 1, max(u64)})
	check_array(t, []int{-42, 0, 42})
	check_array(t, []uint{0, 42, max(uint)})
	check_array(t, []uintptr{0, 0x1000, max(uintptr)})

	check_array(t, []i16le{-2, 0, 300})
	check_array(t, []u16be{1, 0x1234, max(u16be)})
	check_array(t, []i32be{-70000, 0, 70000})
	check_array(t, []u32le{1, 0xdeadbeef})
	check_array(t, []i64be{min(i64be), -1, max(i64be)})
	check_array(t, []u64le{0, max(u64le)})

	check_array(t, []i128{min(i128), -1, max(i128)})
	check_array(t, []u128{0, max(u128)})
	check_array(t, []Distinct_Int{-3, 0, 3})

	fixed := [3]i32{-1, 0, 1}
	check_array(t, fixed[:])
	testing.expect_value(t, fmt.tprintf("%v", fixed), "[-1, 0, 1]")
}
