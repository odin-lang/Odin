package runtime

import "core:os"

print_u64 :: proc(fd: os.Handle, x: u64) {
	digits := "0123456789";

	a: [129]byte;
	i := len(a);
	b := u64(10);
	u := x;
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];

	os.write(fd, a[i:]);
}

print_i64 :: proc(fd: os.Handle, x: i64) {
	digits := "0123456789";
	b :: i64(10);

	u := x;
	neg := u < 0;
	u = abs(u);

	a: [129]byte;
	i := len(a);
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];
	if neg {
		i -= 1; a[i] = '-';
	}

	os.write(fd, a[i:]);
}

print_caller_location :: proc(fd: os.Handle, using loc: Source_Code_Location) {
	os.write_string(fd, file_path);
	os.write_byte(fd, '(');
	print_u64(fd, u64(line));
	os.write_byte(fd, ':');
	print_u64(fd, u64(column));
	os.write_byte(fd, ')');
}
print_typeid :: proc(fd: os.Handle, id: typeid) {
	if id == nil {
		os.write_string(fd, "nil");
	} else {
		ti := type_info_of(id);
		print_type(fd, ti);
	}
}
print_type :: proc(fd: os.Handle, ti: ^Type_Info) {
	if ti == nil {
		os.write_string(fd, "nil");
		return;
	}

	switch info in ti.variant {
	case Type_Info_Named:
		os.write_string(fd, info.name);
	case Type_Info_Integer:
		switch ti.id {
		case int:     os.write_string(fd, "int");
		case uint:    os.write_string(fd, "uint");
		case uintptr: os.write_string(fd, "uintptr");
		case:
			os.write_byte(fd, 'i' if info.signed else 'u');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Rune:
		os.write_string(fd, "rune");
	case Type_Info_Float:
		os.write_byte(fd, 'f');
		print_u64(fd, u64(8*ti.size));
	case Type_Info_Complex:
		os.write_string(fd, "complex");
		print_u64(fd, u64(8*ti.size));
	case Type_Info_Quaternion:
		os.write_string(fd, "quaternion");
		print_u64(fd, u64(8*ti.size));
	case Type_Info_String:
		os.write_string(fd, "string");
	case Type_Info_Boolean:
		switch ti.id {
		case bool: os.write_string(fd, "bool");
		case:
			os.write_byte(fd, 'b');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Any:
		os.write_string(fd, "any");
	case Type_Info_Type_Id:
		os.write_string(fd, "typeid");

	case Type_Info_Pointer:
		if info.elem == nil {
			os.write_string(fd, "rawptr");
		} else {
			os.write_string(fd, "^");
			print_type(fd, info.elem);
		}
	case Type_Info_Procedure:
		os.write_string(fd, "proc");
		if info.params == nil {
			os.write_string(fd, "()");
		} else {
			t := info.params.variant.(Type_Info_Tuple);
			os.write_byte(fd, '(');
			for t, i in t.types {
				if i > 0 do os.write_string(fd, ", ");
				print_type(fd, t);
			}
			os.write_string(fd, ")");
		}
		if info.results != nil {
			os.write_string(fd, " -> ");
			print_type(fd, info.results);
		}
	case Type_Info_Tuple:
		count := len(info.names);
		if count != 1 do os.write_byte(fd, '(');
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");

			t := info.types[i];

			if len(name) > 0 {
				os.write_string(fd, name);
				os.write_string(fd, ": ");
			}
			print_type(fd, t);
		}
		if count != 1 do os.write_string(fd, ")");

	case Type_Info_Array:
		os.write_byte(fd, '[');
		print_u64(fd, u64(info.count));
		os.write_byte(fd, ']');
		print_type(fd, info.elem);

	case Type_Info_Enumerated_Array:
		os.write_byte(fd, '[');
		print_type(fd, info.index);
		os.write_byte(fd, ']');
		print_type(fd, info.elem);


	case Type_Info_Dynamic_Array:
		os.write_string(fd, "[dynamic]");
		print_type(fd, info.elem);
	case Type_Info_Slice:
		os.write_string(fd, "[]");
		print_type(fd, info.elem);

	case Type_Info_Map:
		os.write_string(fd, "map[");
		print_type(fd, info.key);
		os.write_byte(fd, ']');
		print_type(fd, info.value);

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			os.write_string(fd, "#soa[");
			print_u64(fd, u64(info.soa_len));
			os.write_byte(fd, ']');
			print_type(fd, info.soa_base_type);
			return;
		case .Slice:
			os.write_string(fd, "#soa[]");
			print_type(fd, info.soa_base_type);
			return;
		case .Dynamic:
			os.write_string(fd, "#soa[dynamic]");
			print_type(fd, info.soa_base_type);
			return;
		}

		os.write_string(fd, "struct ");
		if info.is_packed    do os.write_string(fd, "#packed ");
		if info.is_raw_union do os.write_string(fd, "#raw_union ");
		if info.custom_align {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			os.write_byte(fd, ' ');
		}
		os.write_byte(fd, '{');
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
			os.write_string(fd, ": ");
			print_type(fd, info.types[i]);
		}
		os.write_byte(fd, '}');

	case Type_Info_Union:
		os.write_string(fd, "union ");
		if info.custom_align {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
		}
		if info.no_nil {
			os.write_string(fd, "#no_nil ");
		}
		os.write_byte(fd, '{');
		for variant, i in info.variants {
			if i > 0 do os.write_string(fd, ", ");
			print_type(fd, variant);
		}
		os.write_string(fd, "}");

	case Type_Info_Enum:
		os.write_string(fd, "enum ");
		print_type(fd, info.base);
		os.write_string(fd, " {");
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
		}
		os.write_string(fd, "}");

	case Type_Info_Bit_Field:
		os.write_string(fd, "bit_field ");
		if ti.align != 1 {
			os.write_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			os.write_byte(fd, ' ');
		}
		os.write_string(fd, " {");
		for name, i in info.names {
			if i > 0 do os.write_string(fd, ", ");
			os.write_string(fd, name);
			os.write_string(fd, ": ");
			print_u64(fd, u64(info.bits[i]));
		}
		os.write_string(fd, "}");

	case Type_Info_Bit_Set:
		os.write_string(fd, "bit_set[");

		#partial switch elem in type_info_base(info.elem).variant {
		case Type_Info_Enum:
			print_type(fd, info.elem);
		case Type_Info_Rune:
			os.write_encoded_rune(fd, rune(info.lower));
			os.write_string(fd, "..");
			os.write_encoded_rune(fd, rune(info.upper));
		case:
			print_i64(fd, info.lower);
			os.write_string(fd, "..");
			print_i64(fd, info.upper);
		}
		if info.underlying != nil {
			os.write_string(fd, "; ");
			print_type(fd, info.underlying);
		}
		os.write_byte(fd, ']');

	case Type_Info_Opaque:
		os.write_string(fd, "opaque ");
		print_type(fd, info.elem);

	case Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			os.write_string(fd, "intrinsics.x86_mmx");
		} else {
			os.write_string(fd, "#simd[");
			print_u64(fd, u64(info.count));
			os.write_byte(fd, ']');
			print_type(fd, info.elem);
		}

	case Type_Info_Relative_Pointer:
		os.write_string(fd, "#relative(");
		print_type(fd, info.base_integer);
		os.write_string(fd, ") ");
		print_type(fd, info.pointer);

	case Type_Info_Relative_Slice:
		os.write_string(fd, "#relative(");
		print_type(fd, info.base_integer);
		os.write_string(fd, ") ");
		print_type(fd, info.slice);
	}
}
