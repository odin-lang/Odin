package test_internal

import "base:runtime"
import "core:testing"

@(private="file")
Untagged :: struct {
	a: int,
	b: f32,
	c: string,
	d: [4]u8,
	e: bool,
}

@(private="file")
Tagged :: struct {
	a: int    `json:"alpha"`,
	b: f32,
	c: string `json:"gamma" fmt:"q"`,
}

@(private="file")
Base :: struct {
	x, y: int,
}

@(private="file")
Derived :: struct {
	using base: Base,
	z:          int,
}

@(private="file")
Untagged_Bits :: bit_field u16 {
	lo: u8  | 4,
	hi: u16 | 12,
}

@(private="file")
Tagged_Bits :: bit_field u16 {
	lo: u8  | 4 `tag:"low"`,
	hi: u16 | 12,
}

@(private="file")
Counting :: enum {
	Zero,
	One,
	Two,
	Three,
}

@(private="file")
From_One :: enum {
	A = 1,
	B,
	C,
}

@(private="file")
Sparse :: enum i16 {
	Neg = -3,
	Big = 1000,
	Mid = 7,
}

@(private="file", require_results)
struct_info :: proc($T: typeid) -> ^runtime.Type_Info_Struct {
	return runtime.type_info_base(type_info_of(T)).variant.(^runtime.Type_Info_Struct)
}

@(private="file", require_results)
bit_field_info :: proc($T: typeid) -> ^runtime.Type_Info_Bit_Field {
	return runtime.type_info_base(type_info_of(T)).variant.(^runtime.Type_Info_Bit_Field)
}

@(private="file", require_results)
enum_info :: proc($T: typeid) -> ^runtime.Type_Info_Enum {
	return runtime.type_info_base(type_info_of(T)).variant.(^runtime.Type_Info_Enum)
}

@test
test_type_info_member_tags :: proc(t: ^testing.T) {
	untagged := struct_info(Untagged)
	testing.expect_value(t, untagged.field_count, 5)
	for i in 0..<untagged.field_count {
		testing.expect_value(t, untagged.tags[i], "")
	}
	testing.expect_value(t, untagged.names[2], "c")
	testing.expect(t, untagged.types[3] == type_info_of([4]u8))
	testing.expect_value(t, untagged.offsets[1], offset_of(Untagged, b))

	tagged := struct_info(Tagged)
	testing.expect_value(t, tagged.tags[0], `json:"alpha"`)
	testing.expect_value(t, tagged.tags[1], "")
	testing.expect_value(t, tagged.tags[2], `json:"gamma" fmt:"q"`)

	untagged_bits := bit_field_info(Untagged_Bits)
	for i in 0..<untagged_bits.field_count {
		testing.expect_value(t, untagged_bits.tags[i], "")
	}
	testing.expect_value(t, untagged_bits.bit_sizes[1], 12)
	testing.expect_value(t, untagged_bits.bit_offsets[1], 4)

	tagged_bits := bit_field_info(Tagged_Bits)
	testing.expect_value(t, tagged_bits.tags[0], `tag:"low"`)
	testing.expect_value(t, tagged_bits.tags[1], "")

	testing.expect(t, untagged_bits.id != tagged_bits.id)
	testing.expect(t, untagged_bits != tagged_bits)
}

@test
test_type_info_member_usings :: proc(t: ^testing.T) {
	derived := struct_info(Derived)
	testing.expect(t, derived.usings[0])
	testing.expect(t, !derived.usings[1])

	untagged := struct_info(Untagged)
	for i in 0..<untagged.field_count {
		testing.expect(t, !untagged.usings[i])
	}
}

@test
test_type_info_enum_values :: proc(t: ^testing.T) {
	counting := enum_info(Counting)
	testing.expect_value(t, len(counting.values), 4)
	for v, i in counting.values {
		testing.expect_value(t, v, runtime.Type_Info_Enum_Value(i))
	}
	testing.expect_value(t, counting.names[3], "Three")

	from_one := enum_info(From_One)
	testing.expect_value(t, len(from_one.values), 3)
	testing.expect_value(t, from_one.values[0], 1)
	testing.expect_value(t, from_one.values[2], 3)

	sparse := enum_info(Sparse)
	testing.expect_value(t, sparse.values[0], -3)
	testing.expect_value(t, sparse.values[1], 1000)
	testing.expect_value(t, sparse.values[2], 7)

	seen: [dynamic]Counting
	defer delete(seen)
	for e in Counting {
		append(&seen, e)
	}
	testing.expect_value(t, len(seen), 4)
	if len(seen) == 4 {
		testing.expect_value(t, seen[3], Counting.Three)
	}
}
