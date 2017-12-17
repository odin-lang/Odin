are_types_identical :: proc(a, b: ^Type_Info) -> bool {
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
	case Type_Info_Named:
		y, ok := b.variant.(Type_Info_Named);
		if !ok do return false;
		return x.base == y.base;

	case Type_Info_Integer:
		y, ok := b.variant.(Type_Info_Integer);
		if !ok do return false;
		return x.signed == y.signed;

	case Type_Info_Rune:
		_, ok := b.variant.(Type_Info_Rune);
		return ok;

	case Type_Info_Float:
		_, ok := b.variant.(Type_Info_Float);
		return ok;

	case Type_Info_Complex:
		_, ok := b.variant.(Type_Info_Complex);
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
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Procedure:
		y, ok := b.variant.(Type_Info_Procedure);
		if !ok do return false;
		switch {
		case x.variadic   != y.variadic,
		     x.convention != y.convention:
			return false;
		}

		return are_types_identical(x.params, y.params) && are_types_identical(x.results, y.results);

	case Type_Info_Array:
		y, ok := b.variant.(Type_Info_Array);
		if !ok do return false;
		if x.count != y.count do return false;
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Dynamic_Array:
		y, ok := b.variant.(Type_Info_Dynamic_Array);
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Slice:
		y, ok := b.variant.(Type_Info_Slice);
		if !ok do return false;
		return are_types_identical(x.elem, y.elem);

	case Type_Info_Tuple:
		y, ok := b.variant.(Type_Info_Tuple);
		if !ok do return false;
		if len(x.types) != len(y.types) do return false;
		for _, i in x.types {
			xt, yt := x.types[i], y.types[i];
			if !are_types_identical(xt, yt) {
				return false;
			}
		}
		return true;

	case Type_Info_Struct:
		y, ok := b.variant.(Type_Info_Struct);
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

			if xn != yn do return false;
			if !are_types_identical(xt, yt) do return false;
		}
		return true;

	case Type_Info_Union:
		y, ok := b.variant.(Type_Info_Union);
		if !ok do return false;
		if len(x.variants) != len(y.variants) do return false;

		for _, i in x.variants {
			xv, yv := x.variants[i], y.variants[i];
			if !are_types_identical(xv, yv) do return false;
		}
		return true;

	case Type_Info_Enum:
		// NOTE(bill): Should be handled above
		return false;

	case Type_Info_Map:
		y, ok := b.variant.(Type_Info_Map);
		if !ok do return false;
		return are_types_identical(x.key, y.key) && are_types_identical(x.value, y.value);

	case Type_Info_Bit_Field:
		y, ok := b.variant.(Type_Info_Bit_Field);
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
	}

	return false;
}


is_signed :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	switch i in type_info_base(info).variant {
	case Type_Info_Integer: return i.signed;
	case Type_Info_Float:   return true;
	}
	return false;
}
is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Integer);
	return ok;
}
is_rune :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Rune);
	return ok;
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Float);
	return ok;
}
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Complex);
	return ok;
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Any);
	return ok;
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_String);
	return ok;
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Boolean);
	return ok;
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Pointer);
	return ok;
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Procedure);
	return ok;
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Array);
	return ok;
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Dynamic_Array);
	return ok;
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Map);
	return ok;
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Slice);
	return ok;
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Tuple);
	return ok;
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	s, ok := type_info_base(info).variant.(Type_Info_Struct);
	return ok && !s.is_raw_union;
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	s, ok := type_info_base(info).variant.(Type_Info_Struct);
	return ok && s.is_raw_union;
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Union);
	return ok;
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(Type_Info_Enum);
	return ok;
}
