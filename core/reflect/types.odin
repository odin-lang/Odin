package reflect

import "core:io"
import "core:strings"

are_types_identical :: proc(a, b: ^Type_Info) -> bool {
	if a == b {
		return true
	}

	if (a == nil && b != nil) ||
	   (a != nil && b == nil) {
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

	case Type_Info_Tuple:
		y := b.variant.(Type_Info_Tuple) or_return
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
		case len(x.types)    != len(y.types),
		     x.is_packed     != y.is_packed,
		     x.is_raw_union  != y.is_raw_union,
		     x.custom_align  != y.custom_align,
		     x.soa_kind      != y.soa_kind,
		     x.soa_base_type != y.soa_base_type,
		     x.soa_len       != y.soa_len:
		     return false
		}
		for _, i in x.types {
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

	case Type_Info_Relative_Slice:
		y := b.variant.(Type_Info_Relative_Slice) or_return
		return x.base_integer == y.base_integer && x.slice == y.slice
	}

	return false
}

is_signed :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return i.signed
	case Type_Info_Float:   return true
	}
	return false
}
is_unsigned :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return !i.signed
	case Type_Info_Float:   return false
	}
	return false
}

is_byte :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return info.size == 1
	}
	return false
}


is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Integer)
	return ok
}
is_rune :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Rune)
	return ok
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Float)
	return ok
}
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Complex)
	return ok
}
is_quaternion :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Quaternion)
	return ok
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Any)
	return ok
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_String)
	return ok
}
is_cstring :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	v, ok := type_info_base(info).variant.(Type_Info_String)
	return ok && v.is_cstring
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Boolean)
	return ok
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Pointer)
	return ok
}
is_multi_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Multi_Pointer)
	return ok
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Procedure)
	return ok
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Array)
	return ok
}
is_enumerated_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Enumerated_Array)
	return ok
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Dynamic_Array)
	return ok
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Map)
	return ok
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Slice)
	return ok
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Tuple)
	return ok
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	s, ok := type_info_base(info).variant.(Type_Info_Struct)
	return ok && !s.is_raw_union
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	s, ok := type_info_base(info).variant.(Type_Info_Struct)
	return ok && s.is_raw_union
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Union)
	return ok
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Enum)
	return ok
}
is_simd_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Simd_Vector)
	return ok
}
is_relative_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Pointer)
	return ok
}
is_relative_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Slice)
	return ok
}








write_typeid_builder :: proc(buf: ^strings.Builder, id: typeid) {
	write_type(buf, type_info_of(id))
}
write_typeid_writer :: proc(writer: io.Writer, id: typeid) {
	write_type(writer, type_info_of(id))
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
write_type_writer :: proc(w: io.Writer, ti: ^Type_Info) -> (n: int, err: io.Error) {
	if ti == nil {
		return io.write_string(w, "nil")
	}

	_n1 :: proc(err: io.Error, n: ^int) -> io.Error { 
		n^ += 1 if err == nil else 0 
		return err
	}
	_n2 :: io.n_wrapper
	_n :: proc{_n1, _n2}

	switch info in ti.variant {
	case Type_Info_Named:
		return io.write_string(w, info.name)
	case Type_Info_Integer:
		switch ti.id {
		case int:     return io.write_string(w, "int")
		case uint:    return io.write_string(w, "uint")
		case uintptr: return io.write_string(w, "uintptr")
		case:
			_n(io.write_byte(w, 'i' if info.signed else 'u'), &n) or_return
			_n(io.write_i64(w, i64(8*ti.size), 10),           &n) or_return
			switch info.endianness {
			case .Platform: // Okay
			case .Little: _n(io.write_string(w, "le"), &n) or_return
			case .Big:    _n(io.write_string(w, "be"), &n) or_return
			}
		}
	case Type_Info_Rune:
		_n(io.write_string(w, "rune"), &n) or_return
	case Type_Info_Float:
		_n(io.write_byte(w, 'f'), &n)               or_return
		_n(io.write_i64(w, i64(8*ti.size), 10), &n) or_return
		switch info.endianness {
		case .Platform: // Okay
		case .Little: _n(io.write_string(w, "le"), &n) or_return
		case .Big:    _n(io.write_string(w, "be"), &n) or_return
		}
	case Type_Info_Complex:
		_n(io.write_string(w, "complex"), &n)       or_return
		_n(io.write_i64(w, i64(8*ti.size), 10), &n) or_return
	case Type_Info_Quaternion:
		_n(io.write_string(w, "quaternion"), &n)    or_return
		_n(io.write_i64(w, i64(8*ti.size), 10), &n) or_return
	case Type_Info_String:
		if info.is_cstring {
			_n(io.write_string(w, "cstring"), &n) or_return
		} else {
			_n(io.write_string(w, "string"), &n)  or_return
		}
	case Type_Info_Boolean:
		switch ti.id {
		case bool: _n(io.write_string(w, "bool"), &n) or_return
		case:
			_n(io.write_byte(w, 'b'), &n)               or_return
			_n(io.write_i64(w, i64(8*ti.size), 10), &n) or_return
		}
	case Type_Info_Any:
		_n(io.write_string(w, "any"), &n) or_return

	case Type_Info_Type_Id:
		_n(io.write_string(w, "typeid"), &n) or_return

	case Type_Info_Pointer:
		if info.elem == nil {
			return io.write_string(w, "rawptr")
		} else {
			_n(io.write_string(w, "^"), &n) or_return
			return write_type(w, info.elem)
		}
	case Type_Info_Multi_Pointer:
		_n(io.write_string(w, "[^]"), &n) or_return
		return write_type(w, info.elem)
	case Type_Info_Procedure:
		_n(io.write_string(w, "proc"), &n) or_return
		if info.params == nil {
			_n(io.write_string(w, "()"), &n) or_return
		} else {
			t := info.params.variant.(Type_Info_Tuple)
			_n(io.write_string(w, "("), &n) or_return
			for t, i in t.types {
				if i > 0 {
					_n(io.write_string(w, ", "), &n) or_return
				}
				_n(write_type(w, t), &n) or_return
			}
			_n(io.write_string(w, ")"), &n) or_return
		}
		if info.results != nil {
			_n(io.write_string(w, " -> "), &n)  or_return
			_n(write_type(w, info.results), &n) or_return
		}
	case Type_Info_Tuple:
		count := len(info.names)
		if count != 1 { 
			_n(io.write_string(w, "("), &n) or_return 
		}
		for name, i in info.names {
			if i > 0 { _n(io.write_string(w, ", "), &n) or_return }

			t := info.types[i]

			if len(name) > 0 {
				_n(io.write_string(w, name), &n) or_return
				_n(io.write_string(w, ": "), &n) or_return
			}
			_n(write_type(w, t), &n) or_return
		}
		if count != 1 { 
			_n(io.write_string(w, ")"), &n) or_return 
		}

	case Type_Info_Array:
		_n(io.write_string(w, "["),              &n) or_return
		_n(io.write_i64(w, i64(info.count), 10), &n) or_return
		_n(io.write_string(w, "]"),              &n) or_return
		_n(write_type(w, info.elem),             &n) or_return

	case Type_Info_Enumerated_Array:
		_n(io.write_string(w, "["),   &n) or_return
		_n(write_type(w, info.index), &n) or_return
		_n(io.write_string(w, "]"),   &n) or_return
		_n(write_type(w, info.elem),  &n) or_return

	case Type_Info_Dynamic_Array:
		_n(io.write_string(w, "[dynamic]"), &n) or_return
		_n(write_type(w, info.elem),        &n) or_return
	case Type_Info_Slice:
		_n(io.write_string(w, "[]"), &n) or_return
		_n(write_type(w, info.elem), &n) or_return

	case Type_Info_Map:
		_n(io.write_string(w, "map["), &n) or_return
		_n(write_type(w, info.key),    &n) or_return
		_n(io.write_byte(w, ']'),      &n) or_return
		_n(write_type(w, info.value),  &n) or_return

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			_n(io.write_string(w, "#soa["),        &n) or_return
			_n(io.write_i64(w, i64(info.soa_len)), &n) or_return
			_n(io.write_byte(w, ']'),              &n) or_return
			_n(write_type(w, info.soa_base_type),  &n) or_return
			return
		case .Slice:
			_n(io.write_string(w, "#soa[]"),      &n) or_return
			_n(write_type(w, info.soa_base_type), &n) or_return
			return
		case .Dynamic:
			_n(io.write_string(w, "#soa[dynamic]"), &n) or_return
			_n(write_type(w, info.soa_base_type),   &n) or_return
			return
		}

		_n(io.write_string(w, "struct "), &n) or_return
		if info.is_packed    { _n(io.write_string(w, "#packed "),    &n) or_return }
		if info.is_raw_union { _n(io.write_string(w, "#raw_union "), &n) or_return }
		if info.custom_align {
			_n(io.write_string(w, "#align "),      &n) or_return
			_n(io.write_i64(w, i64(ti.align), 10), &n) or_return
			_n(io.write_byte(w, ' '),              &n) or_return
		}
		_n(io.write_byte(w, '{'), &n) or_return
		for name, i in info.names {
			if i > 0 { _n(io.write_string(w, ", "), &n) or_return }
			_n(io.write_string(w, name),     &n) or_return
			_n(io.write_string(w, ": "),     &n) or_return
			_n(write_type(w, info.types[i]), &n) or_return
		}
		_n(io.write_byte(w, '}'), &n) or_return

	case Type_Info_Union:
		_n(io.write_string(w, "union "), &n) or_return
		if info.maybe {
			_n(io.write_string(w, "#maybe "), &n) or_return
		}
		if info.custom_align {
			_n(io.write_string(w, "#align "),      &n) or_return
			_n(io.write_i64(w, i64(ti.align), 10), &n) or_return
			_n(io.write_byte(w, ' '),              &n) or_return
		}
		_n(io.write_byte(w, '{'), &n) or_return
		for variant, i in info.variants {
			if i > 0 { _n(io.write_string(w, ", "), &n) or_return }
			_n(write_type(w, variant), &n) or_return
		}
		_n(io.write_byte(w, '}'), &n) or_return

	case Type_Info_Enum:
		_n(io.write_string(w, "enum "), &n) or_return
		_n(write_type(w, info.base), &n) or_return
		_n(io.write_string(w, " {"), &n) or_return
		for name, i in info.names {
			if i > 0 { _n(io.write_string(w, ", "), &n) or_return }
			_n(io.write_string(w, name), &n) or_return
		}
		_n(io.write_byte(w, '}'), &n) or_return

	case Type_Info_Bit_Set:
		_n(io.write_string(w, "bit_set["), &n) or_return
		switch {
		case is_enum(info.elem):
			_n(write_type(w, info.elem), &n) or_return
		case is_rune(info.elem):
			_n(io.write_encoded_rune(w, rune(info.lower)), &n) or_return
			_n(io.write_string(w, ".."),                   &n) or_return
			_n(io.write_encoded_rune(w, rune(info.upper)), &n) or_return
		case:
			_n(io.write_i64(w, info.lower, 10), &n) or_return
			_n(io.write_string(w, ".."),        &n) or_return
			_n(io.write_i64(w, info.upper, 10), &n) or_return
		}
		if info.underlying != nil {
			_n(io.write_string(w, "; "),       &n) or_return
			_n(write_type(w, info.underlying), &n) or_return
		}
		_n(io.write_byte(w, ']'), &n) or_return

	case Type_Info_Simd_Vector:
		_n(io.write_string(w, "#simd["),     &n) or_return
		_n(io.write_i64(w, i64(info.count)), &n) or_return
		_n(io.write_byte(w, ']'),            &n) or_return
		_n(write_type(w, info.elem),         &n) or_return

	case Type_Info_Relative_Pointer:
		_n(io.write_string(w, "#relative("), &n) or_return
		_n(write_type(w, info.base_integer), &n) or_return
		_n(io.write_string(w, ") "),         &n) or_return
		_n(write_type(w, info.pointer),      &n) or_return

	case Type_Info_Relative_Slice:
		_n(io.write_string(w, "#relative("), &n) or_return
		_n(write_type(w, info.base_integer), &n) or_return
		_n(io.write_string(w, ") "),         &n) or_return
		_n(write_type(w, info.slice),        &n) or_return
	}

	return
}

