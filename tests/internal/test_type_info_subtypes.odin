package test_internal

import "base:runtime"
import "core:testing"

@(private="file")
Subtype_Struct :: struct {
	a: int,
	b: f32,
}

@(private="file")
Subtype_Enum :: enum u8 {
	A,
	B = 4,
	C,
}

@(private="file")
Subtype_Bits :: bit_field u16 {
	x: u8 | 4,
	y: u8 | 8,
}

@(private="file", require_results)
check_record :: proc(t: ^testing.T, ti: ^runtime.Type_Info, $V: typeid, loc := #caller_location) -> ^V {
	rec, ok := ti.variant.(^V)
	if !testing.expectf(t, ok, "%v: expected a %v record", ti.id, typeid_of(V), loc = loc) {
		return nil
	}
	testing.expect(t, rawptr(rec) == rawptr(ti), loc = loc)
	testing.expect(t, &rec.header == ti, loc = loc)
	testing.expect_value(t, rec.size, ti.size, loc = loc)
	testing.expect_value(t, rec.align, ti.align, loc = loc)
	testing.expect_value(t, rec.id, ti.id, loc = loc)
	testing.expect_value(t, rec.type_flags, ti.type_flags, loc = loc)

	back, back_ok := rec.variant.(^V)
	testing.expect(t, back_ok && back == rec, loc = loc)
	return rec
}

@test
test_type_info_subtype_records :: proc(t: ^testing.T) {
	{
		named := check_record(t, type_info_of(Subtype_Struct), runtime.Type_Info_Named)
		if named != nil {
			testing.expect_value(t, named.name, "Subtype_Struct")
			testing.expect_value(t, named.pkg,  "test_internal")

			s := check_record(t, named.base, runtime.Type_Info_Struct)
			if s != nil {
				testing.expect_value(t, s.field_count, 2)
				testing.expect_value(t, s.names[1], "b")
				testing.expect(t, s.types[1] == type_info_of(f32))
				testing.expect_value(t, s.offsets[1], offset_of(Subtype_Struct, b))
			}
		}
	}

	{
		i := check_record(t, type_info_of(i32be), runtime.Type_Info_Integer)
		if i != nil {
			testing.expect(t, i.signed)
			testing.expect_value(t, i.endianness, runtime.Platform_Endianness.Big)
		}
	}
	_ = check_record(t, type_info_of(rune), runtime.Type_Info_Rune)
	_ = check_record(t, type_info_of(f32), runtime.Type_Info_Float)
	_ = check_record(t, type_info_of(complex64), runtime.Type_Info_Complex)
	_ = check_record(t, type_info_of(quaternion128), runtime.Type_Info_Quaternion)
	{
		s := check_record(t, type_info_of(cstring), runtime.Type_Info_String)
		if s != nil {
			testing.expect(t, s.is_cstring)
		}
	}
	_ = check_record(t, type_info_of(bool), runtime.Type_Info_Boolean)
	_ = check_record(t, type_info_of(any), runtime.Type_Info_Any)
	_ = check_record(t, type_info_of(typeid), runtime.Type_Info_Type_Id)
	{
		p := check_record(t, type_info_of(^int), runtime.Type_Info_Pointer)
		if p != nil {
			testing.expect(t, p.elem == type_info_of(int))
		}
		raw := check_record(t, type_info_of(rawptr), runtime.Type_Info_Pointer)
		if raw != nil {
			testing.expect(t, raw.elem == nil)
		}
	}
	_ = check_record(t, type_info_of([^]int), runtime.Type_Info_Multi_Pointer)
	{
		p := check_record(t, type_info_of(proc(a: int, b: string) -> f32), runtime.Type_Info_Procedure)
		if p != nil {
			params := check_record(t, p.params, runtime.Type_Info_Parameters)
			if params != nil {
				testing.expect_value(t, len(params.types), 2)
				testing.expect_value(t, params.names[1], "b")
			}
		}
	}
	{
		a := check_record(t, type_info_of([3]u16), runtime.Type_Info_Array)
		if a != nil {
			testing.expect_value(t, a.count, 3)
			testing.expect_value(t, a.elem_size, size_of(u16))
		}
	}
	{
		a := check_record(t, type_info_of(#sparse[Subtype_Enum]int), runtime.Type_Info_Enumerated_Array)
		if a != nil {
			testing.expect(t, a.is_sparse)
		}
	}
	_ = check_record(t, type_info_of([dynamic]int), runtime.Type_Info_Dynamic_Array)
	_ = check_record(t, type_info_of([]int), runtime.Type_Info_Slice)
	{
		u := check_record(t, type_info_of(union{int, f32}), runtime.Type_Info_Union)
		if u != nil {
			testing.expect_value(t, len(u.variants), 2)
		}
	}
	{
		e := check_record(t, runtime.type_info_base(type_info_of(Subtype_Enum)), runtime.Type_Info_Enum)
		if e != nil {
			testing.expect_value(t, len(e.names), 3)
			testing.expect_value(t, e.values[2], 5)
		}
	}
	_ = check_record(t, type_info_of(map[string]int), runtime.Type_Info_Map)
	_ = check_record(t, type_info_of(bit_set[Subtype_Enum]), runtime.Type_Info_Bit_Set)
	_ = check_record(t, type_info_of(#simd[4]f32), runtime.Type_Info_Simd_Vector)
	_ = check_record(t, type_info_of(matrix[2, 3]f32), runtime.Type_Info_Matrix)
	_ = check_record(t, type_info_of(#soa^#soa[]Subtype_Struct), runtime.Type_Info_Soa_Pointer)
	{
		b := check_record(t, runtime.type_info_base(type_info_of(Subtype_Bits)), runtime.Type_Info_Bit_Field)
		if b != nil {
			testing.expect_value(t, b.field_count, 2)
			testing.expect_value(t, b.bit_sizes[1], 8)
		}
	}
	{
		f := check_record(t, type_info_of([dynamic; 4]u8), runtime.Type_Info_Fixed_Capacity_Dynamic_Array)
		if f != nil {
			testing.expect_value(t, f.capacity, 4)
		}
	}
}

@test
test_type_info_subtype_layout :: proc(t: ^testing.T) {
	testing.expect_value(t, align_of(runtime.Type_Info), 8)
	testing.expect_value(t, size_of(runtime.Type_Info_Rune), size_of(runtime.Type_Info))
	testing.expect_value(t, offset_of(runtime.Type_Info_Named, name), size_of(runtime.Type_Info))
	testing.expect_value(t, offset_of(runtime.Type_Info_Struct, types), size_of(runtime.Type_Info))
	testing.expect_value(t, offset_of(runtime.Type_Info_Enum, base), size_of(runtime.Type_Info))
}

@test
test_type_info_subtype_enum_iteration :: proc(t: ^testing.T) {
	seen: [dynamic]Subtype_Enum
	defer delete(seen)
	for e in Subtype_Enum {
		append(&seen, e)
	}
	testing.expect_value(t, len(seen), 3)
	if len(seen) == 3 {
		testing.expect_value(t, seen[0], Subtype_Enum.A)
		testing.expect_value(t, seen[1], Subtype_Enum.B)
		testing.expect_value(t, seen[2], Subtype_Enum.C)
	}
}

@test
test_type_info_subtype_base_chains :: proc(t: ^testing.T) {
	testing.expect(t, runtime.type_info_base(type_info_of(Subtype_Enum)) != type_info_of(Subtype_Enum))
	testing.expect(t, runtime.type_info_core(type_info_of(Subtype_Enum)) == type_info_of(u8))
	testing.expect(t, runtime.type_info_core(type_info_of(Subtype_Bits)) == type_info_of(u16))

	unknown := runtime.__type_info_of(transmute(typeid)u64(0x0123_4567_89ab_cdef))
	testing.expect(t, unknown == runtime.type_table[0])
	testing.expect(t, unknown.variant == nil)
}
