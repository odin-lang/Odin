package reflect

import rt "core:runtime"
import "core:strings"

are_types_identical :: proc(a, b: ^rt.Type_Info) -> bool {
	if a == b do return true;

	if (a == nil && b != nil) ||
	   (a != nil && b == nil) {
		return false;
	}


	switch {
	case a.size != b.size, a.align != b.align:
		return false;
	}

	switch x in a.variant {
	case rt.Type_Info_Named:
		y, ok := b.variant.(rt.Type_Info_Named);
		if !ok do return false;
		return x.base == y.base;

	case rt.Type_Info_Integer:
		y, ok := b.variant.(rt.Type_Info_Integer);
		if !ok do return false;
		return x.signed == y.signed;

	case rt.Type_Info_Rune:
		_, ok := b.variant.(rt.Type_Info_Rune);
		return ok;

	case rt.Type_Info_Float:
		_, ok := b.variant.(rt.Type_Info_Float);
		return ok;

	case rt.Type_Info_Complex:
		_, ok := b.variant.(rt.Type_Info_Complex);
		return ok;

	case rt.Type_Info_String:
		_, ok := b.variant.(rt.Type_Info_String);
		return ok;

	case rt.Type_Info_Boolean:
		_, ok := b.variant.(rt.Type_Info_Boolean);
		return ok;

	case rt.Type_Info_Any:
		_, ok := b.variant.(rt.Type_Info_Any);
		return ok;

	case rt.Type_Info_Pointer:
		y, ok := b.variant.(rt.Type_Info_Pointer);
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case rt.Type_Info_Procedure:
		y, ok := b.variant.(rt.Type_Info_Procedure);
		if !ok do return false;
		switch {
		case x.variadic   != y.variadic,
		     x.convention != y.convention:
			return false;
		}

		return are_types_identical(x.params, y.params) && are_types_identical(x.results, y.results);

	case rt.Type_Info_Array:
		y, ok := b.variant.(rt.Type_Info_Array);
		if !ok do return false;
		if x.count != y.count do return false;
		return are_types_identical(x.elem, y.elem);

	case rt.Type_Info_Dynamic_Array:
		y, ok := b.variant.(rt.Type_Info_Dynamic_Array);
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case rt.Type_Info_Slice:
		y, ok := b.variant.(rt.Type_Info_Slice);
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case rt.Type_Info_Tuple:
		y, ok := b.variant.(rt.Type_Info_Tuple);
		if !ok do return false;
		if len(x.types) != len(y.types) do return false;
		for _, i in x.types {
			xt, yt := x.types[i], y.types[i];
			if !are_types_identical(xt, yt) {
				return false;
			}
		}
		return true;

	case rt.Type_Info_Struct:
		y, ok := b.variant.(rt.Type_Info_Struct);
		if !ok do return false;
	   	switch {
		case len(x.types)   != len(y.types),
		     x.is_packed    != y.is_packed,
		     x.is_raw_union != y.is_raw_union,
		     x.custom_align != y.custom_align:
		     return false;
		}
		for _, i in x.types {
			xn, yn := x.names[i], y.names[i];
			xt, yt := x.types[i], y.types[i];
			xl, yl := x.tags[i],  y.tags[i];

			if xn != yn do return false;
			if !are_types_identical(xt, yt) do return false;
			if xl != yl do return false;
		}
		return true;

	case rt.Type_Info_Union:
		y, ok := b.variant.(rt.Type_Info_Union);
		if !ok do return false;
		if len(x.variants) != len(y.variants) do return false;

		for _, i in x.variants {
			xv, yv := x.variants[i], y.variants[i];
			if !are_types_identical(xv, yv) do return false;
		}
		return true;

	case rt.Type_Info_Enum:
		// NOTE(bill): Should be handled above
		return false;

	case rt.Type_Info_Map:
		y, ok := b.variant.(rt.Type_Info_Map);
		if !ok do return false;
		return are_types_identical(x.key, y.key) && are_types_identical(x.value, y.value);

	case rt.Type_Info_Bit_Field:
		y, ok := b.variant.(rt.Type_Info_Bit_Field);
		if !ok do return false;
		if len(x.names) != len(y.names) do return false;

		for _, i in x.names {
			xb, yb := x.bits[i], y.bits[i];
			xo, yo := x.offsets[i], y.offsets[i];
			xn, yn := x.names[i], y.names[i];

			if xb != yb do return false;
			if xo != yo do return false;
			if xn != yn do return false;
		}
		return true;

	case rt.Type_Info_Bit_Set:
		y, ok := b.variant.(rt.Type_Info_Bit_Set);
		if !ok do return false;
		return x.elem == y.elem && x.lower == y.lower && x.upper == y.upper;

	case rt.Type_Info_Opaque:
		y, ok := b.variant.(rt.Type_Info_Opaque);
		if !ok do return false;
		return x.elem == y.elem;

	case rt.Type_Info_Simd_Vector:
		y, ok := b.variant.(rt.Type_Info_Simd_Vector);
		if !ok do return false;
		return x.count == y.count && x.elem == y.elem;
	}

	return false;
}

is_signed :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	switch i in rt.type_info_base(info).variant {
	case rt.Type_Info_Integer: return i.signed;
	case rt.Type_Info_Float:   return true;
	}
	return false;
}
is_integer :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Integer);
	return ok;
}
is_rune :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Rune);
	return ok;
}
is_float :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Float);
	return ok;
}
is_complex :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Complex);
	return ok;
}
is_any :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Any);
	return ok;
}
is_string :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_String);
	return ok;
}
is_boolean :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Boolean);
	return ok;
}
is_pointer :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Pointer);
	return ok;
}
is_procedure :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Procedure);
	return ok;
}
is_array :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Array);
	return ok;
}
is_dynamic_array :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Dynamic_Array);
	return ok;
}
is_dynamic_map :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Map);
	return ok;
}
is_slice :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Slice);
	return ok;
}
is_tuple :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Tuple);
	return ok;
}
is_struct :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	s, ok := rt.type_info_base(info).variant.(rt.Type_Info_Struct);
	return ok && !s.is_raw_union;
}
is_raw_union :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	s, ok := rt.type_info_base(info).variant.(rt.Type_Info_Struct);
	return ok && s.is_raw_union;
}
is_union :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Union);
	return ok;
}
is_enum :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Enum);
	return ok;
}
is_opaque :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Opaque);
	return ok;
}
is_simd_vector :: proc(info: ^rt.Type_Info) -> bool {
	if info == nil do return false;
	_, ok := rt.type_info_base(info).variant.(rt.Type_Info_Simd_Vector);
	return ok;
}






write_typeid :: proc(buf: ^strings.Builder, id: typeid) {
	write_type(buf, type_info_of(id));
}

write_type :: proc(buf: ^strings.Builder, ti: ^rt.Type_Info) {
	using strings;
	if ti == nil {
		write_string(buf, "nil");
		return;
	}

	switch info in ti.variant {
	case rt.Type_Info_Named:
		write_string(buf, info.name);
	case rt.Type_Info_Integer:
		switch ti.id {
		case int:     write_string(buf, "int");
		case uint:    write_string(buf, "uint");
		case uintptr: write_string(buf, "uintptr");
		case:
			write_byte(buf, info.signed ? 'i' : 'u');
			write_i64(buf, i64(8*ti.size), 10);
			switch info.endianness {
			case .Little: write_string(buf, "le");
			case .Big:    write_string(buf, "be");
			}
		}
	case rt.Type_Info_Rune:
		write_string(buf, "rune");
	case rt.Type_Info_Float:
		write_byte(buf, 'f');
		write_i64(buf, i64(8*ti.size), 10);
	case rt.Type_Info_Complex:
		write_string(buf, "complex");
		write_i64(buf, i64(8*ti.size), 10);
	case rt.Type_Info_String:
		if info.is_cstring {
			write_string(buf, "cstring");
		} else {
			write_string(buf, "string");
		}
	case rt.Type_Info_Boolean:
		switch ti.id {
		case bool: write_string(buf, "bool");
		case:
			write_byte(buf, 'b');
			write_i64(buf, i64(8*ti.size), 10);
		}
	case rt.Type_Info_Any:
		write_string(buf, "any");

	case rt.Type_Info_Type_Id:
		write_string(buf, "typeid");

	case rt.Type_Info_Pointer:
		if info.elem == nil {
			write_string(buf, "rawptr");
		} else {
			write_string(buf, "^");
			write_type(buf, info.elem);
		}
	case rt.Type_Info_Procedure:
		write_string(buf, "proc");
		if info.params == nil {
			write_string(buf, "()");
		} else {
			t := info.params.variant.(rt.Type_Info_Tuple);
			write_string(buf, "(");
			for t, i in t.types {
				if i > 0 do write_string(buf, ", ");
				write_type(buf, t);
			}
			write_string(buf, ")");
		}
		if info.results != nil {
			write_string(buf, " -> ");
			write_type(buf, info.results);
		}
	case rt.Type_Info_Tuple:
		count := len(info.names);
		if count != 1 do write_string(buf, "(");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");

			t := info.types[i];

			if len(name) > 0 {
				write_string(buf, name);
				write_string(buf, ": ");
			}
			write_type(buf, t);
		}
		if count != 1 do write_string(buf, ")");

	case rt.Type_Info_Array:
		write_string(buf, "[");
		write_i64(buf, i64(info.count), 10);
		write_string(buf, "]");
		write_type(buf, info.elem);
	case rt.Type_Info_Dynamic_Array:
		write_string(buf, "[dynamic]");
		write_type(buf, info.elem);
	case rt.Type_Info_Slice:
		write_string(buf, "[]");
		write_type(buf, info.elem);

	case rt.Type_Info_Map:
		write_string(buf, "map[");
		write_type(buf, info.key);
		write_byte(buf, ']');
		write_type(buf, info.value);

	case rt.Type_Info_Struct:
		#complete switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			write_string(buf, "#soa[");
			write_i64(buf, i64(info.soa_len));
			write_byte(buf, ']');
			write_type(buf, info.soa_base_type);
			return;
		case .Slice:
			write_string(buf, "#soa[]");
			write_type(buf, info.soa_base_type);
			return;
		case .Dynamic:
			write_string(buf, "#soa[dynamic]");
			write_type(buf, info.soa_base_type);
			return;
		}

		write_string(buf, "struct ");
		if info.is_packed    do write_string(buf, "#packed ");
		if info.is_raw_union do write_string(buf, "#raw_union ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_byte(buf, '{');
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_type(buf, info.types[i]);
		}
		write_byte(buf, '}');

	case rt.Type_Info_Union:
		write_string(buf, "union ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_byte(buf, '{');
		for variant, i in info.variants {
			if i > 0 do write_string(buf, ", ");
			write_type(buf, variant);
		}
		write_byte(buf, '}');

	case rt.Type_Info_Enum:
		write_string(buf, "enum ");
		write_type(buf, info.base);
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
		}
		write_byte(buf, '}');

	case rt.Type_Info_Bit_Field:
		write_string(buf, "bit_field ");
		if ti.align != 1 {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_i64(buf, i64(info.bits[i]), 10);
		}
		write_byte(buf, '}');

	case rt.Type_Info_Bit_Set:
		write_string(buf, "bit_set[");
		switch {
		case is_enum(info.elem):
			write_type(buf, info.elem);
		case is_rune(info.elem):
			write_encoded_rune(buf, rune(info.lower));
			write_string(buf, "..");
			write_encoded_rune(buf, rune(info.upper));
		case:
			write_i64(buf, info.lower, 10);
			write_string(buf, "..");
			write_i64(buf, info.upper, 10);
		}
		if info.underlying != nil {
			write_string(buf, "; ");
			write_type(buf, info.underlying);
		}
		write_byte(buf, ']');

	case rt.Type_Info_Opaque:
		write_string(buf, "opaque ");
		write_type(buf, info.elem);

	case rt.Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			write_string(buf, "intrinsics.x86_mmx");
		} else {
			write_string(buf, "#simd[");
			write_i64(buf, i64(info.count));
			write_byte(buf, ']');
			write_type(buf, info.elem);
		}
	}
}

