package runtime

_INTEGER_DIGITS :: "0123456789abcdefghijklmnopqrstuvwxyz";

encode_rune :: proc(c: rune) -> ([4]u8, int) {
	r := c;

	buf: [4]u8;
	i := u32(r);
	mask :: u8(0x3f);
	if i <= 1<<7-1 {
		buf[0] = u8(r);
		return buf, 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | u8(r>>6);
		buf[1] = 0x80 | u8(r) & mask;
		return buf, 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (0xd800 <= i && i <= 0xdfff) {
		r = 0xfffd;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | u8(r>>12);
		buf[1] = 0x80 | u8(r>>6) & mask;
		buf[2] = 0x80 | u8(r)    & mask;
		return buf, 3;
	}

	buf[0] = 0xf0 | u8(r>>18);
	buf[1] = 0x80 | u8(r>>12) & mask;
	buf[2] = 0x80 | u8(r>>6)  & mask;
	buf[3] = 0x80 | u8(r)     & mask;
	return buf, 4;
}

print_string :: proc(fd: _OS_Handle, str: string) -> (int, _OS_Errno) {
	return os_write(fd, transmute([]byte)str);
}

print_byte :: proc(fd: _OS_Handle, b: byte) -> (int, _OS_Errno) {
	return os_write(fd, []byte{b});
}

print_encoded_rune :: proc(fd: _OS_Handle, r: rune) {
	print_byte(fd, '\'');

	switch r {
	case '\a': print_string(fd, "\\a");
	case '\b': print_string(fd, "\\b");
	case '\e': print_string(fd, "\\e");
	case '\f': print_string(fd, "\\f");
	case '\n': print_string(fd, "\\n");
	case '\r': print_string(fd, "\\r");
	case '\t': print_string(fd, "\\t");
	case '\v': print_string(fd, "\\v");
	case:
		if r <= 0 {
			print_string(fd, "\\x00");
		} else if r < 32 {
			digits := _INTEGER_DIGITS;
			n0, n1 := u8(r) >> 4, u8(r) & 0xf;
			print_string(fd, "\\x");
			print_byte(fd, digits[n0]);
			print_byte(fd, digits[n1]);
		} else {
			print_rune(fd, r);
		}
	}
	print_byte(fd, '\'');
}

print_rune :: proc(fd: _OS_Handle, r: rune) -> (int, _OS_Errno) {
	RUNE_SELF :: 0x80;

	if r < RUNE_SELF {
		return print_byte(fd, byte(r));
	}

	b, n := encode_rune(r);
	return os_write(fd, b[:n]);
}


print_u64 :: proc(fd: _OS_Handle, x: u64) {
	digits := _INTEGER_DIGITS;

	a: [129]byte;
	i := len(a);
	b := u64(10);
	u := x;
	for u >= b {
		i -= 1; a[i] = digits[u % b];
		u /= b;
	}
	i -= 1; a[i] = digits[u % b];

	os_write(fd, a[i:]);
}


print_i64 :: proc(fd: _OS_Handle, x: i64) {
	digits := _INTEGER_DIGITS;
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

	os_write(fd, a[i:]);
}

print_caller_location :: proc(fd: _OS_Handle, using loc: Source_Code_Location) {
	print_string(fd, file_path);
	print_byte(fd, '(');
	print_u64(fd, u64(line));
	print_byte(fd, ':');
	print_u64(fd, u64(column));
	print_byte(fd, ')');
}
print_typeid :: proc(fd: _OS_Handle, id: typeid) {
	if id == nil {
		print_string(fd, "nil");
	} else {
		ti := type_info_of(id);
		print_type(fd, ti);
	}
}
print_type :: proc(fd: _OS_Handle, ti: ^Type_Info) {
	if ti == nil {
		print_string(fd, "nil");
		return;
	}

	switch info in ti.variant {
	case Type_Info_Named:
		print_string(fd, info.name);
	case Type_Info_Integer:
		switch ti.id {
		case int:     print_string(fd, "int");
		case uint:    print_string(fd, "uint");
		case uintptr: print_string(fd, "uintptr");
		case:
			print_byte(fd, 'i' if info.signed else 'u');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Rune:
		print_string(fd, "rune");
	case Type_Info_Float:
		print_byte(fd, 'f');
		print_u64(fd, u64(8*ti.size));
	case Type_Info_Complex:
		print_string(fd, "complex");
		print_u64(fd, u64(8*ti.size));
	case Type_Info_Quaternion:
		print_string(fd, "quaternion");
		print_u64(fd, u64(8*ti.size));
	case Type_Info_String:
		print_string(fd, "string");
	case Type_Info_Boolean:
		switch ti.id {
		case bool: print_string(fd, "bool");
		case:
			print_byte(fd, 'b');
			print_u64(fd, u64(8*ti.size));
		}
	case Type_Info_Any:
		print_string(fd, "any");
	case Type_Info_Type_Id:
		print_string(fd, "typeid");

	case Type_Info_Pointer:
		if info.elem == nil {
			print_string(fd, "rawptr");
		} else {
			print_string(fd, "^");
			print_type(fd, info.elem);
		}
	case Type_Info_Procedure:
		print_string(fd, "proc");
		if info.params == nil {
			print_string(fd, "()");
		} else {
			t := info.params.variant.(Type_Info_Tuple);
			print_byte(fd, '(');
			for t, i in t.types {
				if i > 0 do print_string(fd, ", ");
				print_type(fd, t);
			}
			print_string(fd, ")");
		}
		if info.results != nil {
			print_string(fd, " -> ");
			print_type(fd, info.results);
		}
	case Type_Info_Tuple:
		count := len(info.names);
		if count != 1 do print_byte(fd, '(');
		for name, i in info.names {
			if i > 0 do print_string(fd, ", ");

			t := info.types[i];

			if len(name) > 0 {
				print_string(fd, name);
				print_string(fd, ": ");
			}
			print_type(fd, t);
		}
		if count != 1 do print_string(fd, ")");

	case Type_Info_Array:
		print_byte(fd, '[');
		print_u64(fd, u64(info.count));
		print_byte(fd, ']');
		print_type(fd, info.elem);

	case Type_Info_Enumerated_Array:
		print_byte(fd, '[');
		print_type(fd, info.index);
		print_byte(fd, ']');
		print_type(fd, info.elem);


	case Type_Info_Dynamic_Array:
		print_string(fd, "[dynamic]");
		print_type(fd, info.elem);
	case Type_Info_Slice:
		print_string(fd, "[]");
		print_type(fd, info.elem);

	case Type_Info_Map:
		print_string(fd, "map[");
		print_type(fd, info.key);
		print_byte(fd, ']');
		print_type(fd, info.value);

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			print_string(fd, "#soa[");
			print_u64(fd, u64(info.soa_len));
			print_byte(fd, ']');
			print_type(fd, info.soa_base_type);
			return;
		case .Slice:
			print_string(fd, "#soa[]");
			print_type(fd, info.soa_base_type);
			return;
		case .Dynamic:
			print_string(fd, "#soa[dynamic]");
			print_type(fd, info.soa_base_type);
			return;
		}

		print_string(fd, "struct ");
		if info.is_packed    do print_string(fd, "#packed ");
		if info.is_raw_union do print_string(fd, "#raw_union ");
		if info.custom_align {
			print_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			print_byte(fd, ' ');
		}
		print_byte(fd, '{');
		for name, i in info.names {
			if i > 0 do print_string(fd, ", ");
			print_string(fd, name);
			print_string(fd, ": ");
			print_type(fd, info.types[i]);
		}
		print_byte(fd, '}');

	case Type_Info_Union:
		print_string(fd, "union ");
		if info.custom_align {
			print_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
		}
		if info.no_nil {
			print_string(fd, "#no_nil ");
		}
		print_byte(fd, '{');
		for variant, i in info.variants {
			if i > 0 do print_string(fd, ", ");
			print_type(fd, variant);
		}
		print_string(fd, "}");

	case Type_Info_Enum:
		print_string(fd, "enum ");
		print_type(fd, info.base);
		print_string(fd, " {");
		for name, i in info.names {
			if i > 0 do print_string(fd, ", ");
			print_string(fd, name);
		}
		print_string(fd, "}");

	case Type_Info_Bit_Field:
		print_string(fd, "bit_field ");
		if ti.align != 1 {
			print_string(fd, "#align ");
			print_u64(fd, u64(ti.align));
			print_byte(fd, ' ');
		}
		print_string(fd, " {");
		for name, i in info.names {
			if i > 0 do print_string(fd, ", ");
			print_string(fd, name);
			print_string(fd, ": ");
			print_u64(fd, u64(info.bits[i]));
		}
		print_string(fd, "}");

	case Type_Info_Bit_Set:
		print_string(fd, "bit_set[");

		#partial switch elem in type_info_base(info.elem).variant {
		case Type_Info_Enum:
			print_type(fd, info.elem);
		case Type_Info_Rune:
			print_encoded_rune(fd, rune(info.lower));
			print_string(fd, "..");
			print_encoded_rune(fd, rune(info.upper));
		case:
			print_i64(fd, info.lower);
			print_string(fd, "..");
			print_i64(fd, info.upper);
		}
		if info.underlying != nil {
			print_string(fd, "; ");
			print_type(fd, info.underlying);
		}
		print_byte(fd, ']');

	case Type_Info_Opaque:
		print_string(fd, "opaque ");
		print_type(fd, info.elem);

	case Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			print_string(fd, "intrinsics.x86_mmx");
		} else {
			print_string(fd, "#simd[");
			print_u64(fd, u64(info.count));
			print_byte(fd, ']');
			print_type(fd, info.elem);
		}

	case Type_Info_Relative_Pointer:
		print_string(fd, "#relative(");
		print_type(fd, info.base_integer);
		print_string(fd, ") ");
		print_type(fd, info.pointer);

	case Type_Info_Relative_Slice:
		print_string(fd, "#relative(");
		print_type(fd, info.base_integer);
		print_string(fd, ") ");
		print_type(fd, info.slice);
	}
}
