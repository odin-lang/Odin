package runtime

_INTEGER_DIGITS :: "0123456789abcdefghijklmnopqrstuvwxyz";

encode_rune :: proc "contextless" (c: rune) -> ([4]u8, int) {
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

print_string :: proc "contextless" (str: string) -> (int, _OS_Errno) {
	return os_write(transmute([]byte)str);
}

print_strings :: proc "contextless" (args: ..string) -> (n: int, err: _OS_Errno) {
	for str in args {
		m: int;
		m, err = os_write(transmute([]byte)str);
		n += m;
		if err != 0 {
			break;
		}
	}
	return;
}

print_byte :: proc "contextless" (b: byte) -> (int, _OS_Errno) {
	return os_write([]byte{b});
}

print_encoded_rune :: proc "contextless" (r: rune) {
	print_byte('\'');

	switch r {
	case '\a': print_string("\\a");
	case '\b': print_string("\\b");
	case '\e': print_string("\\e");
	case '\f': print_string("\\f");
	case '\n': print_string("\\n");
	case '\r': print_string("\\r");
	case '\t': print_string("\\t");
	case '\v': print_string("\\v");
	case:
		if r <= 0 {
			print_string("\\x00");
		} else if r < 32 {
			digits := _INTEGER_DIGITS;
			n0, n1 := u8(r) >> 4, u8(r) & 0xf;
			print_string("\\x");
			print_byte(digits[n0]);
			print_byte(digits[n1]);
		} else {
			print_rune(r);
		}
	}
	print_byte('\'');
}

print_rune :: proc "contextless" (r: rune) -> (int, _OS_Errno) {
	RUNE_SELF :: 0x80;

	if r < RUNE_SELF {
		return print_byte(byte(r));
	}

	b, n := encode_rune(r);
	return os_write(b[:n]);
}


print_u64 :: proc "contextless" (x: u64) {
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

	os_write(a[i:]);
}


print_i64 :: proc "contextless" (x: i64) {
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

	os_write(a[i:]);
}

print_caller_location :: proc "contextless" (using loc: Source_Code_Location) {
	print_string(file_path);
	print_byte('(');
	print_u64(u64(line));
	print_byte(':');
	print_u64(u64(column));
	print_byte(')');
}
print_typeid :: proc "contextless" (id: typeid) {
	if id == nil {
		print_string("nil");
	} else {
		ti := type_info_of(id);
		print_type(ti);
	}
}
print_type :: proc "contextless" (ti: ^Type_Info) {
	if ti == nil {
		print_string("nil");
		return;
	}

	switch info in ti.variant {
	case Type_Info_Named:
		print_string(info.name);
	case Type_Info_Integer:
		switch ti.id {
		case int:     print_string("int");
		case uint:    print_string("uint");
		case uintptr: print_string("uintptr");
		case:
			print_byte('i' if info.signed else 'u');
			print_u64(u64(8*ti.size));
		}
	case Type_Info_Rune:
		print_string("rune");
	case Type_Info_Float:
		print_byte('f');
		print_u64(u64(8*ti.size));
	case Type_Info_Complex:
		print_string("complex");
		print_u64(u64(8*ti.size));
	case Type_Info_Quaternion:
		print_string("quaternion");
		print_u64(u64(8*ti.size));
	case Type_Info_String:
		print_string("string");
	case Type_Info_Boolean:
		switch ti.id {
		case bool: print_string("bool");
		case:
			print_byte('b');
			print_u64(u64(8*ti.size));
		}
	case Type_Info_Any:
		print_string("any");
	case Type_Info_Type_Id:
		print_string("typeid");

	case Type_Info_Pointer:
		if info.elem == nil {
			print_string("rawptr");
		} else {
			print_string("^");
			print_type(info.elem);
		}
	case Type_Info_Procedure:
		print_string("proc");
		if info.params == nil {
			print_string("()");
		} else {
			t := info.params.variant.(Type_Info_Tuple);
			print_byte('(');
			for t, i in t.types {
				if i > 0 { print_string(", "); }
				print_type(t);
			}
			print_string(")");
		}
		if info.results != nil {
			print_string(" -> ");
			print_type(info.results);
		}
	case Type_Info_Tuple:
		count := len(info.names);
		if count != 1 { print_byte('('); }
		for name, i in info.names {
			if i > 0 { print_string(", "); }

			t := info.types[i];

			if len(name) > 0 {
				print_string(name);
				print_string(": ");
			}
			print_type(t);
		}
		if count != 1 { print_string(")"); }

	case Type_Info_Array:
		print_byte('[');
		print_u64(u64(info.count));
		print_byte(']');
		print_type(info.elem);

	case Type_Info_Enumerated_Array:
		print_byte('[');
		print_type(info.index);
		print_byte(']');
		print_type(info.elem);


	case Type_Info_Dynamic_Array:
		print_string("[dynamic]");
		print_type(info.elem);
	case Type_Info_Slice:
		print_string("[]");
		print_type(info.elem);

	case Type_Info_Map:
		print_string("map[");
		print_type(info.key);
		print_byte(']');
		print_type(info.value);

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			print_string("#soa[");
			print_u64(u64(info.soa_len));
			print_byte(']');
			print_type(info.soa_base_type);
			return;
		case .Slice:
			print_string("#soa[]");
			print_type(info.soa_base_type);
			return;
		case .Dynamic:
			print_string("#soa[dynamic]");
			print_type(info.soa_base_type);
			return;
		}

		print_string("struct ");
		if info.is_packed    { print_string("#packed "); }
		if info.is_raw_union { print_string("#raw_union "); }
		if info.custom_align {
			print_string("#align ");
			print_u64(u64(ti.align));
			print_byte(' ');
		}
		print_byte('{');
		for name, i in info.names {
			if i > 0 { print_string(", "); }
			print_string(name);
			print_string(": ");
			print_type(info.types[i]);
		}
		print_byte('}');

	case Type_Info_Union:
		print_string("union ");
		if info.custom_align {
			print_string("#align ");
			print_u64(u64(ti.align));
		}
		if info.no_nil {
			print_string("#no_nil ");
		}
		print_byte('{');
		for variant, i in info.variants {
			if i > 0 { print_string(", "); }
			print_type(variant);
		}
		print_string("}");

	case Type_Info_Enum:
		print_string("enum ");
		print_type(info.base);
		print_string(" {");
		for name, i in info.names {
			if i > 0 { print_string(", "); }
			print_string(name);
		}
		print_string("}");

	case Type_Info_Bit_Set:
		print_string("bit_set[");

		#partial switch elem in type_info_base(info.elem).variant {
		case Type_Info_Enum:
			print_type(info.elem);
		case Type_Info_Rune:
			print_encoded_rune(rune(info.lower));
			print_string("..");
			print_encoded_rune(rune(info.upper));
		case:
			print_i64(info.lower);
			print_string("..");
			print_i64(info.upper);
		}
		if info.underlying != nil {
			print_string("; ");
			print_type(info.underlying);
		}
		print_byte(']');


	case Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			print_string("intrinsics.x86_mmx");
		} else {
			print_string("#simd[");
			print_u64(u64(info.count));
			print_byte(']');
			print_type(info.elem);
		}

	case Type_Info_Relative_Pointer:
		print_string("#relative(");
		print_type(info.base_integer);
		print_string(") ");
		print_type(info.pointer);

	case Type_Info_Relative_Slice:
		print_string("#relative(");
		print_type(info.base_integer);
		print_string(") ");
		print_type(info.slice);
	}
}
