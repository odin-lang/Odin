package reflect

import "core:io"
import "core:strings"

are_types_identical :: proc(a, b: ^Type_Info) -> bool {
	if a == b {
		return true;
	}

	if (a == nil && b != nil) ||
	   (a != nil && b == nil) {
		return false;
	}


	switch {
	case a.size != b.size, a.align != b.align:
		return false;
	}

	switch x in a.variant {
	case Type_Info_Named:
		y, ok := b.variant.(Type_Info_Named);
		if !ok { return false; }
		return x.base == y.base;

	case Type_Info_Integer:
		y, ok := b.variant.(Type_Info_Integer);
		if !ok { return false; }
		return x.signed == y.signed && x.endianness == y.endianness;

	case Type_Info_Rune:
		_, ok := b.variant.(Type_Info_Rune);
		return ok;

	case Type_Info_Float:
		_, ok := b.variant.(Type_Info_Float);
		return ok;

	case Type_Info_Complex:
		_, ok := b.variant.(Type_Info_Complex);
		return ok;

	case Type_Info_Quaternion:
		_, ok := b.variant.(Type_Info_Quaternion);
		return ok;

	case Type_Info_Type_Id:
		_, ok := b.variant.(Type_Info_Type_Id);
		return ok;

	case Type_Info_String:
		_, ok := b.variant.(Type_Info_String);
		return ok;

	case Type_Info_Boolean:
		_, ok := b.variant.(Type_Info_Boolean);
		return ok;

	case Type_Info_Any:
		_, ok := b.variant.(Type_Info_Any);
		return ok;

	case Type_Info_Pointer:
		y, ok := b.variant.(Type_Info_Pointer);
		if !ok { return false; }
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Procedure:
		y, ok := b.variant.(Type_Info_Procedure);
		if !ok { return false; }
		switch {
		case x.variadic   != y.variadic,
		     x.convention != y.convention:
			return false;
		}

		return are_types_identical(x.params, y.params) && are_types_identical(x.results, y.results);

	case Type_Info_Array:
		y, ok := b.variant.(Type_Info_Array);
		if !ok { return false; }
		if x.count != y.count { return false; }
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Enumerated_Array:
		y, ok := b.variant.(Type_Info_Enumerated_Array);
		if !ok { return false; }
		if x.count != y.count { return false; }
		return are_types_identical(x.index, y.index) &&
		       are_types_identical(x.elem, y.elem);

	case Type_Info_Dynamic_Array:
		y, ok := b.variant.(Type_Info_Dynamic_Array);
		if !ok { return false; }
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Slice:
		y, ok := b.variant.(Type_Info_Slice);
		if !ok { return false; }
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Tuple:
		y, ok := b.variant.(Type_Info_Tuple);
		if !ok { return false; }
		if len(x.types) != len(y.types) { return false; }
		for _, i in x.types {
			xt, yt := x.types[i], y.types[i];
			if !are_types_identical(xt, yt) {
				return false;
			}
		}
		return true;

	case Type_Info_Struct:
		y, ok := b.variant.(Type_Info_Struct);
		if !ok { return false; }
	   	switch {
		case len(x.types)    != len(y.types),
		     x.is_packed     != y.is_packed,
		     x.is_raw_union  != y.is_raw_union,
		     x.custom_align  != y.custom_align,
		     x.soa_kind      != y.soa_kind,
		     x.soa_base_type != y.soa_base_type,
		     x.soa_len       != y.soa_len:
		     return false;
		}
		for _, i in x.types {
			xn, yn := x.names[i], y.names[i];
			xt, yt := x.types[i], y.types[i];
			xl, yl := x.tags[i],  y.tags[i];

			if xn != yn { return false; }
			if !are_types_identical(xt, yt) { return false; }
			if xl != yl { return false; }
		}
		return true;

	case Type_Info_Union:
		y, ok := b.variant.(Type_Info_Union);
		if !ok { return false; }
		if len(x.variants) != len(y.variants) { return false; }

		for _, i in x.variants {
			xv, yv := x.variants[i], y.variants[i];
			if !are_types_identical(xv, yv) { return false; }
		}
		return true;

	case Type_Info_Enum:
		// NOTE(bill): Should be handled above
		return false;

	case Type_Info_Map:
		y, ok := b.variant.(Type_Info_Map);
		if !ok { return false; }
		return are_types_identical(x.key, y.key) && are_types_identical(x.value, y.value);

	case Type_Info_Bit_Set:
		y, ok := b.variant.(Type_Info_Bit_Set);
		if !ok { return false; }
		return x.elem == y.elem && x.lower == y.lower && x.upper == y.upper;

	case Type_Info_Simd_Vector:
		y, ok := b.variant.(Type_Info_Simd_Vector);
		if !ok { return false; }
		return x.count == y.count && x.elem == y.elem;

	case Type_Info_Relative_Pointer:
		y, ok := b.variant.(Type_Info_Relative_Pointer);
		if !ok { return false; }
		return x.base_integer == y.base_integer && x.pointer == y.pointer;

	case Type_Info_Relative_Slice:
		y, ok := b.variant.(Type_Info_Relative_Slice);
		if !ok { return false; }
		return x.base_integer == y.base_integer && x.slice == y.slice;
	}

	return false;
}

is_signed :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return i.signed;
	case Type_Info_Float:   return true;
	}
	return false;
}
is_unsigned :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return !i.signed;
	case Type_Info_Float:   return false;
	}
	return false;
}

is_byte :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	#partial switch i in type_info_base(info).variant {
	case Type_Info_Integer: return info.size == 1;
	}
	return false;
}


is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Integer);
	return ok;
}
is_rune :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Rune);
	return ok;
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Float);
	return ok;
}
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Complex);
	return ok;
}
is_quaternion :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Quaternion);
	return ok;
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Any);
	return ok;
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_String);
	return ok;
}
is_cstring :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	v, ok := type_info_base(info).variant.(Type_Info_String);
	return ok && v.is_cstring;
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Boolean);
	return ok;
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Pointer);
	return ok;
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Procedure);
	return ok;
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Array);
	return ok;
}
is_enumerated_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Enumerated_Array);
	return ok;
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Dynamic_Array);
	return ok;
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Map);
	return ok;
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Slice);
	return ok;
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Tuple);
	return ok;
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	s, ok := type_info_base(info).variant.(Type_Info_Struct);
	return ok && !s.is_raw_union;
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	s, ok := type_info_base(info).variant.(Type_Info_Struct);
	return ok && s.is_raw_union;
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Union);
	return ok;
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Enum);
	return ok;
}
is_simd_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Simd_Vector);
	return ok;
}
is_relative_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Pointer);
	return ok;
}
is_relative_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).variant.(Type_Info_Relative_Slice);
	return ok;
}








write_typeid_builder :: proc(buf: ^strings.Builder, id: typeid) {
	write_type(buf, type_info_of(id));
}
write_typeid_writer :: proc(writer: io.Writer, id: typeid) {
	write_type(writer, type_info_of(id));
}

write_typeid :: proc{
	write_typeid_builder,
	write_typeid_writer,
};

write_type :: proc{
	write_type_builder,
	write_type_writer,
};

write_type_builder :: proc(buf: ^strings.Builder, ti: ^Type_Info) -> int {
	return write_type_writer(strings.to_writer(buf), ti);
}
write_type_writer :: proc(w: io.Writer, ti: ^Type_Info) -> (n: int) {
	using strings;
	if ti == nil {
		return write_string(w, "nil");
	}

	_n1 :: proc(err: io.Error) -> int { return 1 if err == nil else 0; };
	_n2 :: proc(n: int, _: io.Error) -> int { return n; };
	_n :: proc{_n1, _n2};

	switch info in ti.variant {
	case Type_Info_Named:
		return write_string(w, info.name);
	case Type_Info_Integer:
		switch ti.id {
		case int:     return write_string(w, "int");
		case uint:    return write_string(w, "uint");
		case uintptr: return write_string(w, "uintptr");
		case:
			n += _n(io.write_byte(w, 'i' if info.signed else 'u'));
			n += _n(io.write_i64(w, i64(8*ti.size), 10));
			switch info.endianness {
			case .Platform: // Okay
			case .Little: n += write_string(w, "le");
			case .Big:    n += write_string(w, "be");
			}
		}
	case Type_Info_Rune:
		n += _n(io.write_string(w, "rune"));
	case Type_Info_Float:
		n += _n(io.write_byte(w, 'f'));
		n += _n(io.write_i64(w, i64(8*ti.size), 10));
		switch info.endianness {
		case .Platform: // Okay
		case .Little: n += write_string(w, "le");
		case .Big:    n += write_string(w, "be");
		}
	case Type_Info_Complex:
		n += _n(io.write_string(w, "complex"));
		n += _n(io.write_i64(w, i64(8*ti.size), 10));
	case Type_Info_Quaternion:
		n += _n(io.write_string(w, "quaternion"));
		n += _n(io.write_i64(w, i64(8*ti.size), 10));
	case Type_Info_String:
		if info.is_cstring {
			n += write_string(w, "cstring");
		} else {
			n += write_string(w, "string");
		}
	case Type_Info_Boolean:
		switch ti.id {
		case bool: n += write_string(w, "bool");
		case:
			n += _n(io.write_byte(w, 'b'));
			n += _n(io.write_i64(w, i64(8*ti.size), 10));
		}
	case Type_Info_Any:
		n += write_string(w, "any");

	case Type_Info_Type_Id:
		n += write_string(w, "typeid");

	case Type_Info_Pointer:
		if info.elem == nil {
			write_string(w, "rawptr");
		} else {
			write_string(w, "^");
			write_type(w, info.elem);
		}
	case Type_Info_Procedure:
		n += write_string(w, "proc");
		if info.params == nil {
			n += write_string(w, "()");
		} else {
			t := info.params.variant.(Type_Info_Tuple);
			n += write_string(w, "(");
			for t, i in t.types {
				if i > 0 {
					n += write_string(w, ", ");
				}
				n += write_type(w, t);
			}
			n += write_string(w, ")");
		}
		if info.results != nil {
			n += write_string(w, " -> ");
			n += write_type(w, info.results);
		}
	case Type_Info_Tuple:
		count := len(info.names);
		if count != 1 { n += write_string(w, "("); }
		for name, i in info.names {
			if i > 0 { n += write_string(w, ", "); }

			t := info.types[i];

			if len(name) > 0 {
				n += write_string(w, name);
				n += write_string(w, ": ");
			}
			n += write_type(w, t);
		}
		if count != 1 { n += write_string(w, ")"); }

	case Type_Info_Array:
		n += _n(io.write_string(w, "["));
		n += _n(io.write_i64(w, i64(info.count), 10));
		n += _n(io.write_string(w, "]"));
		n += write_type(w, info.elem);

	case Type_Info_Enumerated_Array:
		n += write_string(w, "[");
		n += write_type(w, info.index);
		n += write_string(w, "]");
		n += write_type(w, info.elem);

	case Type_Info_Dynamic_Array:
		n += _n(io.write_string(w, "[dynamic]"));
		n += write_type(w, info.elem);
	case Type_Info_Slice:
		n += _n(io.write_string(w, "[]"));
		n += write_type(w, info.elem);

	case Type_Info_Map:
		n += _n(io.write_string(w, "map["));
		n += write_type(w, info.key);
		n += _n(io.write_byte(w, ']'));
		n += write_type(w, info.value);

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			n += _n(io.write_string(w, "#soa["));
			n += _n(io.write_i64(w, i64(info.soa_len)));
			n += _n(io.write_byte(w, ']'));
			n += write_type(w, info.soa_base_type);
			return;
		case .Slice:
			n += _n(io.write_string(w, "#soa[]"));
			n += write_type(w, info.soa_base_type);
			return;
		case .Dynamic:
			n += _n(io.write_string(w, "#soa[dynamic]"));
			n += write_type(w, info.soa_base_type);
			return;
		}

		n += write_string(w, "struct ");
		if info.is_packed    { n += write_string(w, "#packed "); }
		if info.is_raw_union { n += write_string(w, "#raw_union "); }
		if info.custom_align {
			n += _n(io.write_string(w, "#align "));
			n += _n(io.write_i64(w, i64(ti.align), 10));
			n += _n(io.write_byte(w, ' '));
		}
		n += _n(io.write_byte(w, '{'));
		for name, i in info.names {
			if i > 0 { n += write_string(w, ", "); }
			n += _n(io.write_string(w, name));
			n += _n(io.write_string(w, ": "));
			n += write_type(w, info.types[i]);
		}
		n += _n(io.write_byte(w, '}'));

	case Type_Info_Union:
		n += write_string(w, "union ");
		if info.custom_align {
			n += write_string(w, "#align ");
			n += _n(io.write_i64(w, i64(ti.align), 10));
			n += _n(io.write_byte(w, ' '));
		}
		n += _n(io.write_byte(w, '{'));
		for variant, i in info.variants {
			if i > 0 { n += write_string(w, ", "); }
			n += write_type(w, variant);
		}
		n += _n(io.write_byte(w, '}'));

	case Type_Info_Enum:
		n += write_string(w, "enum ");
		n += write_type(w, info.base);
		n += write_string(w, " {");
		for name, i in info.names {
			if i > 0 { n += write_string(w, ", "); }
			n += write_string(w, name);
		}
		n += _n(io.write_byte(w, '}'));

	case Type_Info_Bit_Set:
		n += write_string(w, "bit_set[");
		switch {
		case is_enum(info.elem):
			n += write_type(w, info.elem);
		case is_rune(info.elem):
			n += write_encoded_rune(w, rune(info.lower));
			n += write_string(w, "..");
			n += write_encoded_rune(w, rune(info.upper));
		case:
			n += _n(io.write_i64(w, info.lower, 10));
			n += write_string(w, "..");
			n += _n(io.write_i64(w, info.upper, 10));
		}
		if info.underlying != nil {
			n += write_string(w, "; ");
			n += write_type(w, info.underlying);
		}
		n += _n(io.write_byte(w, ']'));

	case Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			n += write_string(w, "intrinsics.x86_mmx");
		} else {
			n += write_string(w, "#simd[");
			n += _n(io.write_i64(w, i64(info.count)));
			n += _n(io.write_byte(w, ']'));
			n += write_type(w, info.elem);
		}

	case Type_Info_Relative_Pointer:
		n += write_string(w, "#relative(");
		n += write_type(w, info.base_integer);
		n += write_string(w, ") ");
		n += write_type(w, info.pointer);

	case Type_Info_Relative_Slice:
		n += write_string(w, "#relative(");
		n += write_type(w, info.base_integer);
		n += write_string(w, ") ");
		n += write_type(w, info.slice);
	}

	return;
}

