package runtime

_INTEGER_DIGITS :: "0123456789abcdefghijklmnopqrstuvwxyz"

@(private="file")
_INTEGER_DIGITS_VAR := _INTEGER_DIGITS

when !ODIN_NO_RTTI {
	print_any_single :: #force_no_inline proc "contextless" (arg: any) {
		x := arg
		if x.data == nil {
			print_string("nil")
			return
		}

		if loc, ok := x.(Source_Code_Location); ok {
			print_caller_location(loc)
			return
		}
		x.id = typeid_base(x.id)
		switch v in x {
		case typeid:     print_typeid(v)
		case ^Type_Info: print_type(v)

		case string:  print_string(v)
		case cstring: print_string(string(v))
		case []byte:  print_string(string(v))

		case rune:  print_rune(v)

		case u8:    print_u64(u64(v))
		case u16:   print_u64(u64(v))
		case u16le: print_u64(u64(v))
		case u16be: print_u64(u64(v))
		case u32:   print_u64(u64(v))
		case u32le: print_u64(u64(v))
		case u32be: print_u64(u64(v))
		case u64:   print_u64(u64(v))
		case u64le: print_u64(u64(v))
		case u64be: print_u64(u64(v))

		case i8:    print_i64(i64(v))
		case i16:   print_i64(i64(v))
		case i16le: print_i64(i64(v))
		case i16be: print_i64(i64(v))
		case i32:   print_i64(i64(v))
		case i32le: print_i64(i64(v))
		case i32be: print_i64(i64(v))
		case i64:   print_i64(i64(v))
		case i64le: print_i64(i64(v))
		case i64be: print_i64(i64(v))

		case int:     print_int(v)
		case uint:    print_uint(v)
		case uintptr: print_uintptr(v)
		case rawptr:  print_uintptr(uintptr(v))

		case bool: print_string("true" if v else "false")
		case b8:   print_string("true" if v else "false")
		case b16:  print_string("true" if v else "false")
		case b32:  print_string("true" if v else "false")
		case b64:  print_string("true" if v else "false")

		case:
			ti := type_info_of(x.id)
			#partial switch v in ti.variant {
			case Type_Info_Pointer, Type_Info_Multi_Pointer:
				print_uintptr((^uintptr)(x.data)^)
				return
			}

			print_string("<invalid-value>")
		}
	}
	println_any :: #force_no_inline proc "contextless" (args: ..any) {
		context = default_context()
		loop: for arg, i in args {
			assert(arg.id != nil)
			if i != 0 {
				print_string(" ")
			}
			print_any_single(arg)
		}
		print_string("\n")
	}
}


encode_rune :: proc "contextless" (c: rune) -> ([4]u8, int) {
	r := c

	buf: [4]u8
	i := u32(r)
	mask :: u8(0x3f)
	if i <= 1<<7-1 {
		buf[0] = u8(r)
		return buf, 1
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | u8(r>>6)
		buf[1] = 0x80 | u8(r) & mask
		return buf, 2
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (0xd800 <= i && i <= 0xdfff) {
		r = 0xfffd
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | u8(r>>12)
		buf[1] = 0x80 | u8(r>>6) & mask
		buf[2] = 0x80 | u8(r)    & mask
		return buf, 3
	}

	buf[0] = 0xf0 | u8(r>>18)
	buf[1] = 0x80 | u8(r>>12) & mask
	buf[2] = 0x80 | u8(r>>6)  & mask
	buf[3] = 0x80 | u8(r)     & mask
	return buf, 4
}

print_string :: #force_no_inline proc "contextless" (str: string) -> (n: int) {
	n, _ = stderr_write(transmute([]byte)str)
	return
}

print_strings :: #force_no_inline proc "contextless" (args: ..string) -> (n: int) {
	for str in args {
		m, err := stderr_write(transmute([]byte)str)
		n += m
		if err != 0 {
			break
		}
	}
	return
}

print_byte :: #force_no_inline proc "contextless" (b: byte) -> (n: int) {
	n, _ = stderr_write([]byte{b})
	return
}

print_encoded_rune :: #force_no_inline proc "contextless" (r: rune) {
	print_byte('\'')

	switch r {
	case '\a': print_string("\\a")
	case '\b': print_string("\\b")
	case '\e': print_string("\\e")
	case '\f': print_string("\\f")
	case '\n': print_string("\\n")
	case '\r': print_string("\\r")
	case '\t': print_string("\\t")
	case '\v': print_string("\\v")
	case:
		if r <= 0 {
			print_string("\\x00")
		} else if r < 32 {
			n0, n1 := u8(r) >> 4, u8(r) & 0xf
			print_string("\\x")
			print_byte(_INTEGER_DIGITS_VAR[n0])
			print_byte(_INTEGER_DIGITS_VAR[n1])
		} else {
			print_rune(r)
		}
	}
	print_byte('\'')
}

print_rune :: #force_no_inline proc "contextless" (r: rune) -> int #no_bounds_check {
	RUNE_SELF :: 0x80

	if r < RUNE_SELF {
		return print_byte(byte(r))
	}

	b, n := encode_rune(r)
	m, _ := stderr_write(b[:n])
	return m
}


print_u64 :: #force_no_inline proc "contextless" (x: u64) #no_bounds_check {
	a: [129]byte
	i := len(a)
	b := u64(10)
	u := x
	for u >= b {
		i -= 1; a[i] = _INTEGER_DIGITS_VAR[u % b]
		u /= b
	}
	i -= 1; a[i] = _INTEGER_DIGITS_VAR[u % b]

	stderr_write(a[i:])
}


print_i64 :: #force_no_inline proc "contextless" (x: i64) #no_bounds_check {
	b :: i64(10)

	u := x
	neg := u < 0
	u = abs(u)

	a: [129]byte
	i := len(a)
	for u >= b {
		i -= 1; a[i] = _INTEGER_DIGITS_VAR[u % b]
		u /= b
	}
	i -= 1; a[i] = _INTEGER_DIGITS_VAR[u % b]
	if neg {
		i -= 1; a[i] = '-'
	}

	stderr_write(a[i:])
}

print_uint    :: proc "contextless" (x: uint)    { print_u64(u64(x)) }
print_uintptr :: proc "contextless" (x: uintptr) { print_u64(u64(x)) }
print_int     :: proc "contextless" (x: int)     { print_i64(i64(x)) }

print_caller_location :: #force_no_inline proc "contextless" (loc: Source_Code_Location) {
	print_string(loc.file_path)
	when ODIN_ERROR_POS_STYLE == .Default {
		print_byte('(')
		print_u64(u64(loc.line))
		if loc.column != 0 {
			print_byte(':')
			print_u64(u64(loc.column))
		}
		print_byte(')')
	} else when ODIN_ERROR_POS_STYLE == .Unix {
		print_byte(':')
		print_u64(u64(loc.line))
		if loc.column != 0 {
			print_byte(':')
			print_u64(u64(loc.column))
		}
		print_byte(':')
	} else {
		#panic("unhandled ODIN_ERROR_POS_STYLE")
	}
}
print_typeid :: #force_no_inline proc "contextless" (id: typeid) {
	when ODIN_NO_RTTI {
		if id == nil {
			print_string("nil")
		} else {
			print_string("<unknown type>")
		}
	} else {
		if id == nil {
			print_string("nil")
		} else {
			ti := type_info_of(id)
			print_type(ti)
		}
	}
}

@(optimization_mode="favor_size")
print_type :: #force_no_inline proc "contextless" (ti: ^Type_Info) {
	if ti == nil {
		print_string("nil")
		return
	}

	switch info in ti.variant {
	case Type_Info_Named:
		print_string(info.name)
	case Type_Info_Integer:
		switch ti.id {
		case int:     print_string("int")
		case uint:    print_string("uint")
		case uintptr: print_string("uintptr")
		case:
			print_byte('i' if info.signed else 'u')
			print_u64(u64(8*ti.size))
		}
	case Type_Info_Rune:
		print_string("rune")
	case Type_Info_Float:
		print_byte('f')
		print_u64(u64(8*ti.size))
	case Type_Info_Complex:
		print_string("complex")
		print_u64(u64(8*ti.size))
	case Type_Info_Quaternion:
		print_string("quaternion")
		print_u64(u64(8*ti.size))
	case Type_Info_String:
		print_string("string")
	case Type_Info_Boolean:
		switch ti.id {
		case bool: print_string("bool")
		case:
			print_byte('b')
			print_u64(u64(8*ti.size))
		}
	case Type_Info_Any:
		print_string("any")
	case Type_Info_Type_Id:
		print_string("typeid")

	case Type_Info_Pointer:
		if info.elem == nil {
			print_string("rawptr")
		} else {
			print_string("^")
			print_type(info.elem)
		}
	case Type_Info_Multi_Pointer:
		print_string("[^]")
		print_type(info.elem)
	case Type_Info_Soa_Pointer:
		print_string("#soa ^")
		print_type(info.elem)
	case Type_Info_Procedure:
		print_string("proc")
		if info.params == nil {
			print_string("()")
		} else {
			t := info.params.variant.(Type_Info_Parameters)
			print_byte('(')
			for t, i in t.types {
				if i > 0 { print_string(", ") }
				print_type(t)
			}
			print_string(")")
		}
		if info.results != nil {
			print_string(" -> ")
			print_type(info.results)
		}
	case Type_Info_Parameters:
		count := len(info.names)
		if count != 1 { print_byte('(') }
		for name, i in info.names {
			if i > 0 { print_string(", ") }

			t := info.types[i]

			if len(name) > 0 {
				print_string(name)
				print_string(": ")
			}
			print_type(t)
		}
		if count != 1 { print_string(")") }

	case Type_Info_Array:
		print_byte('[')
		print_u64(u64(info.count))
		print_byte(']')
		print_type(info.elem)

	case Type_Info_Enumerated_Array:
		if info.is_sparse {
			print_string("#sparse")
		}
		print_byte('[')
		print_type(info.index)
		print_byte(']')
		print_type(info.elem)


	case Type_Info_Dynamic_Array:
		print_string("[dynamic]")
		print_type(info.elem)
	case Type_Info_Slice:
		print_string("[]")
		print_type(info.elem)

	case Type_Info_Map:
		print_string("map[")
		print_type(info.key)
		print_byte(']')
		print_type(info.value)

	case Type_Info_Struct:
		switch info.soa_kind {
		case .None: // Ignore
		case .Fixed:
			print_string("#soa[")
			print_u64(u64(info.soa_len))
			print_byte(']')
			print_type(info.soa_base_type)
			return
		case .Slice:
			print_string("#soa[]")
			print_type(info.soa_base_type)
			return
		case .Dynamic:
			print_string("#soa[dynamic]")
			print_type(info.soa_base_type)
			return
		}

		print_string("struct ")
		if .packed    in info.flags { print_string("#packed ") }
		if .raw_union in info.flags { print_string("#raw_union ") }
		if .no_copy   in info.flags { print_string("#no_copy ") }
		if .align in info.flags {
			print_string("#align(")
			print_u64(u64(ti.align))
			print_string(") ")
		}
		print_byte('{')
		for name, i in info.names[:info.field_count] {
			if i > 0 { print_string(", ") }
			print_string(name)
			print_string(": ")
			print_type(info.types[i])
		}
		print_byte('}')

	case Type_Info_Union:
		print_string("union ")
		if info.custom_align {
			print_string("#align(")
			print_u64(u64(ti.align))
			print_string(") ")
		}
		if info.no_nil {
			print_string("#no_nil ")
		}
		print_byte('{')
		for variant, i in info.variants {
			if i > 0 { print_string(", ") }
			print_type(variant)
		}
		print_string("}")

	case Type_Info_Enum:
		print_string("enum ")
		print_type(info.base)
		print_string(" {")
		for name, i in info.names {
			if i > 0 { print_string(", ") }
			print_string(name)
		}
		print_string("}")

	case Type_Info_Bit_Set:
		print_string("bit_set[")

		#partial switch elem in type_info_base(info.elem).variant {
		case Type_Info_Enum:
			print_type(info.elem)
		case Type_Info_Rune:
			print_encoded_rune(rune(info.lower))
			print_string("..")
			print_encoded_rune(rune(info.upper))
		case:
			print_i64(info.lower)
			print_string("..")
			print_i64(info.upper)
		}
		if info.underlying != nil {
			print_string("; ")
			print_type(info.underlying)
		}
		print_byte(']')

	case Type_Info_Bit_Field:
		print_string("bit_field ")
		print_type(info.backing_type)
		print_string(" {")
		for name, i in info.names[:info.field_count] {
			if i > 0 { print_string(", ") }
			print_string(name)
			print_string(": ")
			print_type(info.types[i])
			print_string(" | ")
			print_u64(u64(info.bit_sizes[i]))
		}
		print_byte('}')


	case Type_Info_Simd_Vector:
		print_string("#simd[")
		print_u64(u64(info.count))
		print_byte(']')
		print_type(info.elem)
		
	case Type_Info_Matrix:
		print_string("matrix[")
		print_u64(u64(info.row_count))
		print_string(", ")
		print_u64(u64(info.column_count))
		print_string("]")
		print_type(info.elem)
	}
}
