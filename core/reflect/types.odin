package reflect

import "core:io"
import "core:strings"

@(require_results)
are_types_identical :: proc(a, b: ^Type_Info) -> bool {
	if a == b {
		return true
	}

	if a == nil || b == nil {
		return false
	}

	switch {
	case a.size != b.size, a.align != b.align:
		return false
	}

	switch x in a.variant {
	case Type_Info_Named:
		y := b.variant.(Type_Info_Named) or_return
		return x.base == y.base

	case Type_Info_Integer:
		y := b.variant.(Type_Info_Integer) or_return
		return x.signed == y.signed && x.endianness == y.endianness

	case Type_Info_Rune:
		_, ok := b.variant.(Type_Info_Rune)
		return ok

	case Type_Info_Float:
		_, ok := b.variant.(Type_Info_Float)
		return ok

	case Type_Info_Complex:
		_, ok := b.variant.(Type_Info_Complex)
		return ok

	case Type_Info_Quaternion:
		_, ok := b.variant.(Type_Info_Quaternion)
		return ok

	case Type_Info_Type_Id:
		_, ok := b.variant.(Type_Info_Type_Id)
		return ok

	case Type_Info_String:
		_, ok := b.variant.(Type_Info_String)
		return ok

	case Type_Info_Boolean:
		_, ok := b.variant.(Type_Info_Boolean)
		return ok

	case Type_Info_Any:
		_, ok := b.variant.(Type_Info_Any)
		return ok

	case Type_Info_Pointer:
		y := b.variant.(Type_Info_Pointer) or_return
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Multi_Pointer:
		y := b.variant.(Type_Info_Multi_Pointer) or_return
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Soa_Pointer:
		y := b.variant.(Type_Info_Soa_Pointer) or_return
		return are_types_identical(x.elem, y.elem)


	case Type_Info_Procedure:
		y := b.variant.(Type_Info_Procedure) or_return
		switch {
		case x.variadic   != y.variadic,
		     x.convention != y.convention:
			return false
		}

		return are_types_identical(x.params, y.params) && are_types_identical(x.results, y.results)

	case Type_Info_Array:
		y := b.variant.(Type_Info_Array) or_return
		if x.count != y.count { return false }
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Enumerated_Array:
		y := b.variant.(Type_Info_Enumerated_Array) or_return
		if x.count != y.count { return false }
		return are_types_identical(x.index, y.index) &&
		       are_types_identical(x.elem, y.elem)

	case Type_Info_Dynamic_Array:
		y := b.variant.(Type_Info_Dynamic_Array) or_return
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Slice:
		y := b.variant.(Type_Info_Slice) or_return
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Parameters:
		y := b.variant.(Type_Info_Parameters) or_return
		if len(x.types) != len(y.types) { return false }
		for _, i in x.types {
			xt, yt := x.types[i], y.types[i]
			if !are_types_identical(xt, yt) {
				return false
			}
		}
		return true

	case Type_Info_Struct:
		y := b.variant.(Type_Info_Struct) or_return
		switch {
		case x.field_count   != y.field_count,
		     x.flags         != y.flags,
		     x.soa_kind      != y.soa_kind,
		     x.soa_base_type != y.soa_base_type,
		     x.soa_len       != y.soa_len:
			return false
		}
		for i in 0..<x.field_count {
			xn, yn := x.names[i], y.names[i]
			xt, yt := x.types[i], y.types[i]
			xl, yl := x.tags[i],  y.tags[i]

			if xn != yn { return false }
			if !are_types_identical(xt, yt) { return false }
			if xl != yl { return false }
		}
		return true

	case Type_Info_Union:
		y := b.variant.(Type_Info_Union) or_return
		if len(x.variants) != len(y.variants) { return false }

		for _, i in x.variants {
			xv, yv := x.variants[i], y.variants[i]
			if !are_types_identical(xv, yv) { return false }
		}
		return true

	case Type_Info_Enum:
		// NOTE(bill): Should be handled above
		return false

	case Type_Info_Map:
		y := b.variant.(Type_Info_Map) or_return
		return are_types_identical(x.key, y.key) && are_types_identical(x.value, y.value)

	case Type_Info_Bit_Set:
		y := b.variant.(Type_Info_Bit_Set) or_return
		return x.elem == y.elem && x.lower == y.lower && x.upper == y.upper

	case Type_Info_Simd_Vector:
		y := b.variant.(Type_Info_Simd_Vector) or_return
		return x.count == y.count && x.elem == y.elem

	case Type_Info_Relative_Pointer:
		y := b.variant.(Type_Info_Relative_Pointer) or_return
		return x.base_integer == y.base_integer && x.pointer == y.pointer

	case Type_Info_Relative_Multi_Pointer:
		y := b.variant.(Type_Info_Relative_Multi_Pointer) or_return
		return x.base_integer == y.base_integer && x.pointer == y.pointer
		
	case Type_Info_Matrix:
		y := b.variant.(Type_Info_Matrix) or_return
		if x.row_count != y.row_count { return false }
		if x.column_count != y.column_count { return false }
		if x.layout != y.layout { return false }
		return are_types_identical(x.elem, y.elem)

	case Type_Info_Bit_Field:
		y := b.variant.(Type_Info_Bit_Field) or_return
		if !are_types_identical(x.backing_type, y.backing_type) { return false }
		if x.field_count != y.field_count { return false }
		for _, i in x.names[:x.field_count] {
			if x.names[i] != y.names[i] {
				return false
			}
			if !are_types_identical(x.types[i], y.types[i]) {
				return false
			}
			if x.bit_sizes[i] != y.bit_sizes[i] {
				return false
			}
		}
		return true
	}

	return false
}

@(require_results)
is_signed :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return i.signed
	case Type_Info_Float:   return true
	}
	return false
}
@(require_results)
is_unsigned :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return !i.signed
	case Type_Info_Float:   return false
	}
	return false
}

@(require_results)
is_byte :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return info.size == 1
	}
	return false
}


@(require_results)
is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Integer)
	return ok
}
@(require_results)
is_rune :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Rune)
	return ok
}
@(require_results)
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Float)
	return ok
}
@(require_results)
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Complex)
	return ok
}
@(require_results)
is_quaternion :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Quaternion)
	return ok
}
@(require_results)
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Any)
	return ok
}
@(require_results)
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_String)
	return ok
}
@(require_results)
is_cstring :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	v, ok := type_info_base(info).variant.(Type_Info_String)
	return ok && v.is_cstring
}
@(require_results)
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Boolean)
	return ok
}
@(require_results)
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Pointer)
	return ok
}
@(require_results)
is_multi_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Multi_Pointer)
	return ok
}
@(require_results)
is_soa_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Soa_Pointer)
	return ok
}
@(require_results)
is_pointer_internally :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch v in info.variant {
	case Type_Info_Pointer, Type_Info_Multi_Pointer,
	     Type_Info_Procedure:
		return true
	case Type_Info_String:
		return v.is_cstring
	}
	return false
}
@(require_results)
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Procedure)
	return ok
}
@(require_results)
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Array)
	return ok
}
@(require_results)
is_enumerated_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Enumerated_Array)
	return ok
}
@(require_results)
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Dynamic_Array)
	return ok
}
@(require_results)
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Map)
	return ok
}
@(require_results)
is_bit_set :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Bit_Set)
	return ok
}
@(require_results)
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Slice)
	return ok
}
@(require_results)
is_parameters :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Parameters)
	return ok
}
@(require_results, deprecated="prefer is_parameters")
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Parameters)
	return ok
}
@(require_results)
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	s, ok := type_info_base(info).variant.(Type_Info_Struct)
	return ok && .raw_union not_in s.flags
}
@(require_results)
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	s, ok := type_info_base(info).variant.(Type_Info_Struct)
	return ok && .raw_union in s.flags
}
@(require_results)
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Union)
	return ok
}
@(require_results)
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Enum)
	return ok
}
@(require_results)
is_simd_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Simd_Vector)
	return ok
}
@(require_results)
is_relative_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Pointer)
	return ok
}
@(require_results)
is_relative_multi_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Multi_Pointer)
	return ok
}


@(require_results)
is_endian_platform :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false}
	info := info
	info = type_info_core(info)
	#partial switch v in info.variant {
	case Type_Info_Integer:
		return v.endianness == .Platform
	case Type_Info_Bit_Set:
		if v.underlying != nil {
			return is_endian_platform(v.underlying)
		}
		return true
	case Type_Info_Pointer:
		return true
	}
	return false
}

@(require_results)
is_endian_little :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false}
	info := info
	info = type_info_core(info)
	#partial switch v in info.variant {
	case Type_Info_Integer:
		if v.endianness == .Platform {
			return ODIN_ENDIAN == .Little
		}
		return v.endianness == .Little
	case Type_Info_Bit_Set:
		if v.underlying != nil {
			return is_endian_platform(v.underlying)
		}
		return ODIN_ENDIAN == .Little
	case Type_Info_Pointer:
		return ODIN_ENDIAN == .Little
	}
	return ODIN_ENDIAN == .Little
}

@(require_results)
is_endian_big :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false}
	info := info
	info = type_info_core(info)
	#partial switch v in info.variant {
	case Type_Info_Integer:
		if v.endianness == .Platform {
			return ODIN_ENDIAN == .Big
		}
		return v.endianness == .Big
	case Type_Info_Bit_Set:
		if v.underlying != nil {
			return is_endian_platform(v.underlying)
		}
		return ODIN_ENDIAN == .Big
	case Type_Info_Pointer:
		return ODIN_ENDIAN == .Big
	}
	return ODIN_ENDIAN == .Big
}




write_typeid_builder :: proc(buf: ^strings.Builder, id: typeid, n_written: ^int = nil) -> (n: int, err: io.Error) {
	return write_type_writer(strings.to_writer(buf), type_info_of(id))
}
write_typeid_writer :: proc(writer: io.Writer, id: typeid, n_written: ^int = nil) -> (n: int, err: io.Error) {
	return write_type_writer(writer, type_info_of(id), n_written)
}

write_typeid :: proc{
	write_typeid_builder,
	write_typeid_writer,
}

write_type :: proc{
	write_type_builder,
	write_type_writer,
}

write_type_builder :: proc(buf: ^strings.Builder, ti: ^Type_Info) -> int {
	n, _ := write_type_writer(strings.to_writer(buf), ti)
	return n
}
write_type_writer :: #force_no_inline proc(w: io.Writer, ti: ^Type_Info, n_written: ^int = nil) -> (n: int, err: io.Error) {
	defer if n_written != nil {
		n_written^ += n
	}
	if ti == nil {
		io.write_string(w, "nil", &n) or_return
		return
	}
	
	switch info in ti.variant {
	case Type_Info_Named:
		io.write_string(w, info.name, &n) or_return
	case Type_Info_Integer:
		switch ti.id {
		case int:     io.write_string(w, "int",     &n) or_return
		case uint:    io.write_string(w, "uint",    &n) or_return
		case uintptr: io.write_string(w, "uintptr", &n) or_return
		case:
			io.write_byte(w, 'i' if info.signed else 'u', &n) or_return
			io.write_i64(w, i64(8*ti.size), 10,           &n) or_return
			switch info.endianness {
			case .Platform: // Okay
			case .Little: io.write_string(w, "le", &n) or_return
			case .Big:    io.write_string(w, "be", &n) or_return
			}
		}
	case Type_Info_Rune:
		io.write_string(w, "rune", &n) or_return
	case Type_Info_Float:
		io.write_byte(w, 'f', &n)               or_return
		io.write_i64(w, i64(8*ti.size), 10, &n) or_return
		switch info.endianness {
		case .Platform: // Okay
		case .Little: io.write_string(w, "le", &n) or_return
		case .Big:    io.write_string(w, "be", &n) or_return
		}
	case Type_Info_Complex:
		io.write_string(w, "complex", &n)       or_return
		io.write_i64(w, i64(8*ti.size), 10, &n) or_return
	case Type_Info_Quaternion:
		io.write_string(w, "quaternion", &n)    or_return
		io.write_i64(w, i64(8*ti.size), 10, &n) or_return
	case Type_Info_String:
		if info.is_cstring {
			io.write_string(w, "cstring", &n) or_return
		} else {
			io.write_string(w, "string", &n)  or_return
		}
	case Type_Info_Boolean:
		switch ti.id {
		case bool: io.write_string(w, "bool", &n) or_return
		case:
			io.write_byte(w, 'b', &n)               or_return
			io.write_i64(w, i64(8*ti.size), 10, &n) or_return
		}
	case Type_Info_Any:
		io.write_string(w, "any", &n) or_return

	case Type_Info_Type_Id:
		io.write_string(w, "typeid", &n) or_return

	case Type_Info_Pointer:
		if info.elem == nil {
			io.write_string(w, "rawptr", &n) or_return
		} else {
			io.write_string(w, "^", &n) or_return
			write_type(w, info.elem, &n) or_return
		}
	case Type_Info_Multi_Pointer:
		io.write_string(w, "[^]", &n) or_return
		write_type(w, info.elem, &n) or_return
	case Type_Info_Soa_Pointer:
		io.write_string(w, "#soa ^", &n) or_return
		write_type(w, info.elem, &n) or_return
	case Type_Info_Procedure:
		io.write_string(w, "proc", &n) or_return
		if info.params == nil {
			io.write_string(w, "()", &n) or_return
		} else {
			t := info.params.variant.(Type_Info_Parameters)
			io.write_string(w, "(", &n) or_return
			for t, i in t.types {
				if i > 0 {
					io.write_string(w, ", ", &n) or_return
				}
				write_type(w, t, &n) or_return
			}
			io.write_string(w, ")", &n) or_return
		}
		if info.results != nil {
			io.write_string(w, " -> ", &n)  or_return
			write_type(w, info.results, &n) or_return
		}
	case Type_Info_Parameters:
		count := len(info.names)
		if count != 1 { 
			io.write_string(w, "(", &n) or_return 
		}
		for name, i in info.names {
			if i > 0 { io.write_string(w, ", ", &n) or_return }

			t := info.types[i]

			if len(name) > 0 {
				io.write_string(w, name, &n) or_return
				io.write_string(w, ": ", &n) or_return
			}
			write_type(w, t, &n) or_return
		}
		if count != 1 { 
			io.write_string(w, ")", &n) or_return 
		}

	case Type_Info_Array:
		io.write_string(w, "[",              &n) or_return
		io.write_i64(w, i64(info.count), 10, &n) or_return
		io.write_string(w, "]",              &n) or_return
		write_type(w, info.elem,             &n) or_return

	case Type_Info_Enumerated_Array:
		if info.is_sparse {
			io.write_string(w, "#sparse", &n) or_return
		}
		io.write_string(w, "[",   &n) or_return
		write_type(w, info.index, &n) or_return
		io.write_string(w, "]",   &n) or_return
		write_type(w, info.elem,  &n) or_return

	case Type_Info_Dynamic_Array:
		io.write_string(w, "[dynamic]", &n) or_return
		write_type(w, info.elem,        &n) or_return
	case Type_Info_Slice:
		io.write_string(w, "[]", &n) or_return
		write_type(w, info.elem, &n) or_return

	case Type_Info_Map:
		io.write_string(w, "map[", &n) or_return
		write_type(w, info.key,    &n) or_return
		io.write_byte(w, ']',      &n) or_return
		write_type(w, info.value,  &n) or_return

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			io.write_string(w, "#soa[",           &n) or_return
			io.write_i64(w, i64(info.soa_len),    10) or_return
			io.write_byte(w, ']',                 &n) or_return
			write_type(w, info.soa_base_type,     &n) or_return
			return
		case .Slice:
			io.write_string(w, "#soa[]",      &n) or_return
			write_type(w, info.soa_base_type, &n) or_return
			return
		case .Dynamic:
			io.write_string(w, "#soa[dynamic]", &n) or_return
			write_type(w, info.soa_base_type,   &n) or_return
			return
		}

		io.write_string(w, "struct ", &n) or_return
		if .packed    in info.flags { io.write_string(w, "#packed ",    &n) or_return }
		if .raw_union in info.flags { io.write_string(w, "#raw_union ", &n) or_return }
		if .no_copy   in info.flags { io.write_string(w, "#no_copy ", &n) or_return }
		if .align in info.flags {
			io.write_string(w, "#align(",      &n) or_return
			io.write_i64(w, i64(ti.align), 10, &n) or_return
			io.write_string(w, ") ",           &n) or_return
		}
		io.write_byte(w, '{', &n) or_return
		for name, i in info.names[:info.field_count] {
			if i > 0 { io.write_string(w, ", ", &n) or_return }
			io.write_string(w, name,     &n) or_return
			io.write_string(w, ": ",     &n) or_return
			write_type(w, info.types[i], &n) or_return
		}
		io.write_byte(w, '}', &n) or_return

	case Type_Info_Union:
		io.write_string(w, "union ", &n) or_return
		if info.no_nil     { io.write_string(w, "#no_nil ", &n)     or_return }
		if info.shared_nil { io.write_string(w, "#shared_nil ", &n) or_return }
		if info.custom_align {
			io.write_string(w, "#align(",      &n) or_return
			io.write_i64(w, i64(ti.align), 10, &n) or_return
			io.write_string(w, ") ",           &n) or_return
		}
		io.write_byte(w, '{', &n) or_return
		for variant, i in info.variants {
			if i > 0 { io.write_string(w, ", ", &n) or_return }
			write_type(w, variant, &n) or_return
		}
		io.write_byte(w, '}', &n) or_return

	case Type_Info_Enum:
		io.write_string(w, "enum ", &n) or_return
		write_type(w, info.base, &n) or_return
		io.write_string(w, " {", &n) or_return
		for name, i in info.names {
			if i > 0 { io.write_string(w, ", ", &n) or_return }
			io.write_string(w, name, &n) or_return
		}
		io.write_byte(w, '}', &n) or_return

	case Type_Info_Bit_Set:
		io.write_string(w, "bit_set[", &n) or_return
		switch {
		case is_enum(info.elem):
			write_type(w, info.elem, &n) or_return
		case is_rune(info.elem):
			io.write_encoded_rune(w, rune(info.lower), true, &n) or_return
			io.write_string(w, "..=",                        &n) or_return
			io.write_encoded_rune(w, rune(info.upper), true, &n) or_return
		case:
			io.write_i64(w, info.lower, 10, &n) or_return
			io.write_string(w, "..=",       &n) or_return
			io.write_i64(w, info.upper, 10, &n) or_return
		}
		if info.underlying != nil {
			io.write_string(w, "; ",       &n) or_return
			write_type(w, info.underlying, &n) or_return
		}
		io.write_byte(w, ']', &n) or_return

	case Type_Info_Bit_Field:
		io.write_string(w, "bit_field ", &n) or_return
		write_type(w, info.backing_type, &n) or_return
		io.write_string(w, " {",         &n) or_return
		for name, i in info.names[:info.field_count] {
			if i > 0 { io.write_string(w, ", ", &n) or_return }
			io.write_string(w, name,     &n) or_return
			io.write_string(w, ": ",     &n) or_return
			write_type(w, info.types[i], &n) or_return
			io.write_string(w, " | ",    &n) or_return
			io.write_u64(w, u64(info.bit_sizes[i]), 10, &n) or_return
		}
		io.write_string(w, "}", &n) or_return

	case Type_Info_Simd_Vector:
		io.write_string(w, "#simd[",         &n) or_return
		io.write_i64(w, i64(info.count), 10, &n) or_return
		io.write_byte(w, ']',                &n) or_return
		write_type(w, info.elem,             &n) or_return

	case Type_Info_Relative_Pointer:
		io.write_string(w, "#relative(", &n) or_return
		write_type(w, info.base_integer, &n) or_return
		io.write_string(w, ") ",         &n) or_return
		write_type(w, info.pointer,      &n) or_return

	case Type_Info_Relative_Multi_Pointer:
		io.write_string(w, "#relative(", &n) or_return
		write_type(w, info.base_integer, &n) or_return
		io.write_string(w, ") ",         &n) or_return
		write_type(w, info.pointer,      &n) or_return
		
	case Type_Info_Matrix:
		if info.layout == .Row_Major {
			io.write_string(w, "#row_major ",   &n) or_return
		}
		io.write_string(w, "matrix[",               &n) or_return
		io.write_i64(w, i64(info.row_count), 10,    &n) or_return
		io.write_string(w, ", ",                    &n) or_return
		io.write_i64(w, i64(info.column_count), 10, &n) or_return
		io.write_string(w, "]",                     &n) or_return
		write_type(w, info.elem,                    &n) or_return
	}

	return
}

