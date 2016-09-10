#load "runtime.odin"
#load "win32.odin"
#load "file.odin"

print_string_to_buffer :: proc(buf: ^[]byte, s: string) {
	// NOTE(bill): This is quite a hack
	// TODO(bill): Should I allow the raw editing of a slice by exposing its
	// internal members?
	Raw_Bytes :: struct #ordered {
		data: ^byte
		len:  int
		cap:  int
	}

	slice := buf as ^Raw_Bytes
	if slice.len < slice.cap {
		n := min(slice.cap-slice.len, len(s))
		offset := ((slice.data as int) + slice.len) as ^byte
		memory_copy(offset, ^s[0], n)
		slice.len += n
	}
}

byte_reverse :: proc(b: []byte) {
	n := len(b)
	for i := 0; i < n/2; i++ {
		b[i], b[n-1-i] = b[n-1-i], b[i]
	}
}

encode_rune :: proc(r: rune) -> ([4]byte, int) {
	buf: [4]byte
	i := r as u32
	mask: byte : 0x3f
	if i <= 1<<7-1 {
		buf[0] = r as byte
		return buf, 1
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | (r>>6) as byte
		buf[1] = 0x80 | (r)    as byte & mask
		return buf, 2
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (i >= 0xd800 && i <= 0xdfff) {
		r = 0xfffd
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | (r>>12) as byte
		buf[1] = 0x80 | (r>>6)  as byte & mask
		buf[2] = 0x80 | (r)     as byte & mask
		return buf, 3
	}

	buf[0] = 0xf0 | (r>>18) as byte
	buf[1] = 0x80 | (r>>12) as byte & mask
	buf[2] = 0x80 | (r>>6)  as byte & mask
	buf[3] = 0x80 | (r)     as byte & mask
	return buf, 4
}

print_rune_to_buffer :: proc(buf: ^[]byte, r: rune) {
	b, n := encode_rune(r)
	print_string_to_buffer(buf, b[:n] as string)
}

print_space_to_buffer :: proc(buf: ^[]byte) { print_rune_to_buffer(buf, #rune " ") }
print_nl_to_buffer    :: proc(buf: ^[]byte) { print_rune_to_buffer(buf, #rune "\n") }

print_int_to_buffer :: proc(buf: ^[]byte, i: int) {
	print_int_base_to_buffer(buf, i, 10);
}
PRINT__NUM_TO_CHAR_TABLE :: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$"
print_int_base_to_buffer :: proc(buffer: ^[]byte, i, base: int) {

	buf: [65]byte
	len := 0
	negative := false
	if i < 0 {
		negative = true
		i = -i
	}
	if i == 0 {
		buf[len] = #rune "0"
		len++
	}
	for i > 0 {
		buf[len] = PRINT__NUM_TO_CHAR_TABLE[i % base]
		len++
		i /= base
	}

	if negative {
		buf[len] = #rune "-"
		len++
	}

	byte_reverse(buf[:len])
	print_string_to_buffer(buffer, buf[:len] as string)
}

print_uint_to_buffer :: proc(buffer: ^[]byte, i: uint) {
	print_uint_base_to_buffer(buffer, i, 10, 0, #rune " ")
}
print_uint_base_to_buffer :: proc(buffer: ^[]byte, i, base: uint, min_width: int, pad_char: byte) {
	buf: [65]byte
	len := 0
	if i == 0 {
		buf[len] = #rune "0"
		len++
	}
	for i > 0 {
		buf[len] = PRINT__NUM_TO_CHAR_TABLE[i % base]
		len++
		i /= base
	}
	for len < min_width {
		buf[len] = pad_char
		len++
	}

	byte_reverse(buf[:len])
	print_string_to_buffer(buffer, buf[:len] as string)
}

print_bool_to_buffer :: proc(buffer: ^[]byte, b : bool) {
	if b { print_string_to_buffer(buffer, "true") }
	else { print_string_to_buffer(buffer, "false") }
}

print_pointer_to_buffer :: proc(buffer: ^[]byte, p: rawptr) #inline { print_uint_base_to_buffer(buffer, p as uint, 16, 0, #rune " ") }

print_f32_to_buffer :: proc(buffer: ^[]byte, f: f32) #inline { print__f64(buffer, f as f64, 7) }
print_f64_to_buffer :: proc(buffer: ^[]byte, f: f64) #inline { print__f64(buffer, f, 10) }

print__f64 :: proc(buffer: ^[]byte, f: f64, decimal_places: int) {
	if f == 0 {
		print_rune_to_buffer(buffer, #rune "0")
		return
	}
	if f < 0 {
		print_rune_to_buffer(buffer, #rune "-")
		f = -f
	}

	print_u64_to_buffer :: proc(buffer: ^[]byte, i: u64) {
		buf: [22]byte
		len := 0
		if i == 0 {
			buf[len] = #rune "0"
			len++
		}
		for i > 0 {
			buf[len] = PRINT__NUM_TO_CHAR_TABLE[i % 10]
			len++
			i /= 10
		}
		byte_reverse(buf[:len])
		print_string_to_buffer(buffer, buf[:len] as string)
	}

	i := f as u64
	print_u64_to_buffer(buffer, i)
	f -= i as f64

	print_rune_to_buffer(buffer, #rune ".")

	mult := 10.0
	for decimal_places := 6; decimal_places >= 0; decimal_places-- {
		i = (f * mult) as u64
		print_u64_to_buffer(buffer, i as u64)
		f -= i as f64 / mult
		mult *= 10
	}
}



print_any_to_buffer :: proc(buf: ^[]byte, arg: any)  {
	using Type_Info
	match type info : arg.type_info {
	case Named:
		a: any
		a.type_info = info.base
		a.data = arg.data
		match type b : info.base {
		case Struct:
			print_string_to_buffer(buf, info.name)
			print_string_to_buffer(buf, "{")
			for i := 0; i < len(b.fields); i++ {
				f := b.fields[i];
				if i > 0 {
					print_string_to_buffer(buf, ", ")
				}
				print_any_to_buffer(buf, f.name)
				print_string_to_buffer(buf, " = ")
				v: any
				v.type_info = f.type_info
				v.data = ptr_offset(arg.data as ^u8, f.offset)
				print_any_to_buffer(buf, v)
			}
			print_string_to_buffer(buf, "}")

		default:
			print_any_to_buffer(buf, a)
		}

	case Integer:
		if info.signed {
			u: uint = 0;
			if arg.data != null {
				match info.size {
				case 1:  u = (arg.data as ^u8)^   as uint
				case 2:  u = (arg.data as ^u16)^  as uint
				case 4:  u = (arg.data as ^u32)^  as uint
				case 8:  u = (arg.data as ^u64)^  as uint
				case 16: u = (arg.data as ^u128)^ as uint
				}
			}
			print_uint_to_buffer(buf, u)
		} else {
			v: int = 0;
			if arg.data != null {
				match info.size {
				case 1:  v = (arg.data as ^i8)^   as int
				case 2:  v = (arg.data as ^i16)^  as int
				case 4:  v = (arg.data as ^i32)^  as int
				case 8:  v = (arg.data as ^i64)^  as int
				case 16: v = (arg.data as ^i128)^ as int
				}
			}
			print_int_to_buffer(buf, v)
		}

	case Float:
		f: f64 = 0
		if arg.data != null {
			match info.size {
			case 4: f = (arg.data as ^f32)^ as f64
			case 8: f = (arg.data as ^f64)^ as f64
			}
		}
		print_f64_to_buffer(buf, f)

	case String:
		s := ""
		if arg.data != null {
			s = (arg.data as ^string)^
		}
		print_string_to_buffer(buf, s)

	case Boolean:
		v := false;
		if arg.data != null {
			v = (arg.data as ^bool)^
		}
		print_bool_to_buffer(buf, v)

	case Pointer:
		v := null;
		if arg.data != null {
			v = (arg.data as ^rawptr)^
		}
		print_pointer_to_buffer(buf, v)

	case Enum:
		v: any
		v.data = arg.data
		v.type_info = info.base
		print_any_to_buffer(buf, v)


	case Array:
		print_string_to_buffer(buf, "[")
		for i := 0; i < info.len; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = (arg.data as int + i*info.elem_size) as rawptr
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}
		print_string_to_buffer(buf, "]")

	case Slice:
		slice := arg.data as ^struct { data: rawptr; len, cap: int }
		print_string_to_buffer(buf, "[")
		for i := 0; i < slice.len; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = (slice.data as int + i*info.elem_size) as rawptr
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}
		print_string_to_buffer(buf, "]")

	case Vector:
		print_string_to_buffer(buf, "<")
		for i := 0; i < info.len; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = (arg.data as int + i*info.elem_size) as rawptr
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}
		print_string_to_buffer(buf, ">")


	case Struct:
		print_string_to_buffer(buf, "(struct ")
		for i := 0; i < len(info.fields); i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_any_to_buffer(buf, info.fields[i].name)
		}
		print_string_to_buffer(buf, ")")
	case Union:     print_string_to_buffer(buf, "(union)")
	case Raw_Union: print_string_to_buffer(buf, "(raw_union)")
	case Procedure:
		print_string_to_buffer(buf, "(procedure 0x")
		print_pointer_to_buffer(buf, (arg.data as ^rawptr)^)
		print_string_to_buffer(buf, ")")
	default:
		print_string_to_buffer(buf, "")
	}
}

type_info_is_string :: proc(info: ^Type_Info) -> bool {
	using Type_Info
	if info == null {
		return false
	}

	for {
		match type i : info {
		case Named:
			info = i.base
			continue
		case String:
			return true
		default:
			return false
		}
	}
	return false
}

print_to_buffer :: proc(buf: ^[]byte, args: ..any) {
	prev_string := false
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if i > 0 {
			print_space_to_buffer(buf)
		}
		print_any_to_buffer(buf, arg)
	}
}

println_to_buffer :: proc(buf: ^[]byte, args: ..any) {
	print_to_buffer(buf, ..args)
	print_nl_to_buffer(buf)
}

print :: proc(args: ..any) {
	data: [4096]byte
	buf := data[:0]
	print_to_buffer(^buf, ..args)
	file_write(file_get_standard(File_Standard.OUTPUT), buf)
}


println :: proc(args: ..any) {
	data: [4096]byte
	buf := data[:0]
	println_to_buffer(^buf, ..args)
	file_write(file_get_standard(File_Standard.OUTPUT), buf)
}
