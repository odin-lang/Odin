#import "os.odin"
#import "mem.odin"
#import "utf8.odin"

PRINT_BUF_SIZE :: 1<<12

fprint :: proc(f: ^os.File, args: ..any) {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprint(^buf, ..args)
	os.write(f, buf)
}

fprintln :: proc(f: ^os.File, args: ..any) {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprintln(^buf, ..args)
	os.write(f, buf)
}
fprintf :: proc(f: ^os.File, fmt: string, args: ..any) {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprintf(^buf, fmt, ..args)
	os.write(f, buf)
}


print :: proc(args: ..any) {
	fprint(os.stdout, ..args)
}
println :: proc(args: ..any) {
	fprintln(os.stdout, ..args)
}
printf :: proc(fmt: string, args: ..any) {
	fprintf(os.stdout, fmt, ..args)
}



fprint_type :: proc(f: ^os.File, info: ^Type_Info) {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	print_type_to_buffer(^buf, info)
	os.write(f, buf)
}



print_byte_buffer :: proc(buf: ^[]byte, b: []byte) {
	if buf.count < buf.capacity {
		n := min(buf.capacity-buf.count, b.count)
		if n > 0 {
			offset := ptr_offset(buf.data, buf.count)
			mem.copy(offset, ^b[0], n)
			buf.count += n
		}
	}
}

print_string_to_buffer :: proc(buf: ^[]byte, s: string) {
	print_byte_buffer(buf, s as []byte)
}


byte_reverse :: proc(b: []byte) {
	n := b.count
	for i := 0; i < n/2; i++ {
		b[i], b[n-1-i] = b[n-1-i], b[i]
	}
}

print_rune_to_buffer :: proc(buf: ^[]byte, r: rune) {
	b, n := utf8.encode_rune(r)
	print_string_to_buffer(buf, b[:n] as string)
}

print_space_to_buffer :: proc(buf: ^[]byte) { print_rune_to_buffer(buf, #rune " ") }
print_nl_to_buffer    :: proc(buf: ^[]byte) { print_rune_to_buffer(buf, #rune "\n") }

print_int_to_buffer :: proc(buf: ^[]byte, i: int) {
	print_int_base_to_buffer(buf, i, 10);
}

__NUM_TO_CHAR_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$"

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
		buf[len] = __NUM_TO_CHAR_TABLE[i % base]
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
		buf[len] = __NUM_TO_CHAR_TABLE[i % base]
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

print_pointer_to_buffer :: proc(buffer: ^[]byte, p: rawptr) #inline {
	print_string_to_buffer(buffer, "0x")
	print_uint_base_to_buffer(buffer, p as uint, 16, size_of(int), #rune "0")
}

print_f32_to_buffer :: proc(buffer: ^[]byte, f: f32) #inline { print__f64(buffer, f as f64, 7) }
print_f64_to_buffer :: proc(buffer: ^[]byte, f: f64) #inline { print__f64(buffer, f, 10) }
print_u64_to_buffer :: proc(buffer: ^[]byte, i: u64) {
	buf: [22]byte
	len := 0
	if i == 0 {
		buf[len] = #rune "0"
		len++
	}
	for i > 0 {
		buf[len] = __NUM_TO_CHAR_TABLE[i % 10]
		len++
		i /= 10
	}
	byte_reverse(buf[:len])
	print_string_to_buffer(buffer, buf[:len] as string)
}
print_i64_to_buffer :: proc(buffer: ^[]byte, i: i64) {
	neg := i < 0
	if neg {
		i = -i
		print_rune_to_buffer(buffer, #rune "-")
	}
	print_u64_to_buffer(buffer, i as u64)
}

print__f64 :: proc(buffer: ^[]byte, f: f64, decimal_places: int) {
	if f == 0 {
		print_rune_to_buffer(buffer, #rune "0")
		return
	}
	if f < 0 {
		print_rune_to_buffer(buffer, #rune "-")
		f = -f
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

print_type_to_buffer :: proc(buf: ^[]byte, ti: ^Type_Info) {
	if ti == null { return }

	using Type_Info
	match type info : ti {
	case Named:
		print_string_to_buffer(buf, info.name)
	case Integer:
		match {
		case ti == type_info(int):
			print_string_to_buffer(buf, "int")
		case ti == type_info(uint):
			print_string_to_buffer(buf, "uint")
		default:
			if info.signed {
				print_string_to_buffer(buf, "i")
			} else {
				print_string_to_buffer(buf, "u")
			}
			print_int_to_buffer(buf, 8*info.size)
		}

	case Float:
		match info.size {
		case 4: print_string_to_buffer(buf, "f32")
		case 8: print_string_to_buffer(buf, "f64")
		}
	case String:  print_string_to_buffer(buf, "string")
	case Boolean: print_string_to_buffer(buf, "bool")
	case Pointer:
		print_string_to_buffer(buf, "^")
		print_type_to_buffer(buf, info.elem)
	case Procedure:
		print_string_to_buffer(buf, "proc")
		if info.params == null {
			print_string_to_buffer(buf, "()")
		} else {
			count := (info.params as ^Tuple).fields.count
			if count == 1 { print_string_to_buffer(buf, "(") }
			print_type_to_buffer(buf, info.params)
			if count == 1 { print_string_to_buffer(buf, ")") }
		}
		if info.results != null {
			print_string_to_buffer(buf, " -> ")
			print_type_to_buffer(buf, info.results)
		}
	case Tuple:
		count := info.fields.count
		if count != 1 { print_string_to_buffer(buf, "(") }
		for i := 0; i < count; i++ {
			if i > 0 { print_string_to_buffer(buf, ", ") }

			f := info.fields[i]

			if f.name.count > 0 {
				print_string_to_buffer(buf, f.name)
				print_string_to_buffer(buf, ": ")
			}
			print_type_to_buffer(buf, f.type_info)
		}
		if count != 1 { print_string_to_buffer(buf, ")") }

	case Array:
		print_string_to_buffer(buf, "[")
		print_int_to_buffer(buf, info.count)
		print_string_to_buffer(buf, "]")
		print_type_to_buffer(buf, info.elem)
	case Slice:
		print_string_to_buffer(buf, "[")
		print_string_to_buffer(buf, "]")
		print_type_to_buffer(buf, info.elem)
	case Vector:
		print_string_to_buffer(buf, "{")
		print_int_to_buffer(buf, info.count)
		print_string_to_buffer(buf, "}")
		print_type_to_buffer(buf, info.elem)

	case Struct:
		print_string_to_buffer(buf, "struct ")
		if info.packed  { print_string_to_buffer(buf, "#packed ") }
		if info.ordered { print_string_to_buffer(buf, "#ordered ") }
		print_string_to_buffer(buf, "{")
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_any_to_buffer(buf, info.fields[i].name)
			print_string_to_buffer(buf, ": ")
			print_type_to_buffer(buf, info.fields[i].type_info)
		}
		print_string_to_buffer(buf, "}")

	case Union:
		print_string_to_buffer(buf, "union {")
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_any_to_buffer(buf, info.fields[i].name)
			print_string_to_buffer(buf, ": ")
			print_type_to_buffer(buf, info.fields[i].type_info)
		}
		print_string_to_buffer(buf, "}")

	case Raw_Union:
		print_string_to_buffer(buf, "raw_union {")
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_any_to_buffer(buf, info.fields[i].name)
			print_string_to_buffer(buf, ": ")
			print_type_to_buffer(buf, info.fields[i].type_info)
		}
		print_string_to_buffer(buf, "}")

	case Enum:
		print_string_to_buffer(buf, "enum ")
		print_type_to_buffer(buf, info.base)
		print_string_to_buffer(buf, "{}")
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
			for i := 0; i < b.fields.count; i++ {
				f := b.fields[i];
				if i > 0 {
					print_string_to_buffer(buf, ", ")
				}
				print_any_to_buffer(buf, f.name)
				print_string_to_buffer(buf, " = ")
				v: any
				v.type_info = f.type_info
				v.data = ptr_offset(arg.data as ^byte, f.offset)
				print_any_to_buffer(buf, v)
			}
			print_string_to_buffer(buf, "}")

		default:
			print_any_to_buffer(buf, a)
		}

	case Integer:
		if info.signed {
			i: i64 = 0;
			if arg.data != null {
				match info.size {
				case 1:  i = (arg.data as ^i8)^   as i64
				case 2:  i = (arg.data as ^i16)^  as i64
				case 4:  i = (arg.data as ^i32)^  as i64
				case 8:  i = (arg.data as ^i64)^  as i64
				}
			}
			print_i64_to_buffer(buf, i)
		} else {
			i: u64 = 0;
			if arg.data != null {
				match info.size {
				case 1:  i = (arg.data as ^u8)^   as u64
				case 2:  i = (arg.data as ^u16)^  as u64
				case 4:  i = (arg.data as ^u32)^  as u64
				case 8:  i = (arg.data as ^u64)^  as u64
				}
			}
			print_u64_to_buffer(buf, i)
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
		if arg.data != null {
			if arg.type_info == type_info(^Type_Info) {
				print_type_to_buffer(buf, (arg.data as ^^Type_Info)^)
			} else {
				print_pointer_to_buffer(buf, (arg.data as ^rawptr)^)
			}
		} else {
			print_pointer_to_buffer(buf, null)
		}

	case Enum:
		value: i64 = 0
		match type i : info.base {
		case Integer:
			if i.signed {
				if arg.data != null {
					match i.size {
					case 1:  value = (arg.data as ^i8)^   as i64
					case 2:  value = (arg.data as ^i16)^  as i64
					case 4:  value = (arg.data as ^i32)^  as i64
					case 8:  value = (arg.data as ^i64)^  as i64
					}
				}
			} else {
				if arg.data != null {
					match i.size {
					case 1:  value = (arg.data as ^u8)^   as i64
					case 2:  value = (arg.data as ^u16)^  as i64
					case 4:  value = (arg.data as ^u32)^  as i64
					case 8:  value = (arg.data as ^u64)^  as i64
					}
				}
			}
		}
		print_string_to_buffer(buf, __enum_to_string(arg.type_info, value))


	case Array:
		print_string_to_buffer(buf, "[")
		defer print_string_to_buffer(buf, "]")

		for i := 0; i < info.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = (arg.data as int + i*info.elem_size) as rawptr
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}

	case Slice:
		slice := arg.data as ^[]byte
		print_string_to_buffer(buf, "[")
		defer print_string_to_buffer(buf, "]")

		for i := 0; i < slice.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = ptr_offset(slice.data, i*info.elem_size)
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}

	case Vector:
		print_string_to_buffer(buf, "<")
		defer print_string_to_buffer(buf, ">")

		for i := 0; i < info.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			elem: any
			elem.data = ptr_offset(arg.data as ^byte, i*info.elem_size)
			elem.type_info = info.elem
			print_any_to_buffer(buf, elem)
		}


	case Struct:
		print_string_to_buffer(buf, "struct")
		print_string_to_buffer(buf, "{")
		defer print_string_to_buffer(buf, "}")

		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_any_to_buffer(buf, info.fields[i].name)
			print_string_to_buffer(buf, " = ")
			a: any
			a.data = ptr_offset(arg.data as ^byte, info.fields[i].offset)
			a.type_info = info.fields[i].type_info
			print_any_to_buffer(buf, a)
		}

	case Union:
		print_string_to_buffer(buf, "(union)")
	case Raw_Union:
		print_string_to_buffer(buf, "(raw_union)")
	case Procedure:
		print_type_to_buffer(buf, arg.type_info)
		print_string_to_buffer(buf, " @ 0x")
		print_pointer_to_buffer(buf, (arg.data as ^rawptr)^)

	default:
	}
}


bprintf :: proc(buf: ^[]byte, fmt: string, args: ..any) {
	is_digit :: proc(r: rune) -> bool #inline {
		return r >= #rune "0" && r <= #rune "9"
	}

	parse_int :: proc(s: string, offset: int) -> (int, int) {
		result := 0

		for ; offset < s.count; offset++ {
			c := s[offset] as rune
			if !is_digit(c) {
				break
			}

			result *= 10
			result += (c - #rune "0") as int
		}

		return result, offset
	}

	prev := 0
	implicit_index := 0

	for i := 0; i < fmt.count; i++ {
		r := fmt[i] as rune
		index := implicit_index

		if r != #rune "%" {
			continue
		}

		print_string_to_buffer(buf, fmt[prev:i])
		i++ // Skip %
		if i < fmt.count {
			next := fmt[i] as rune

			if next == #rune "%" {
				print_string_to_buffer(buf, "%")
				i++
				prev = i
				continue
			}

			if is_digit(next) {
				index, i = parse_int(fmt, i)
			}
		}

		if 0 <= index && index < args.count {
			print_any_to_buffer(buf, args[index])
			implicit_index = index+1
		} else {
			// TODO(bill): Error check index out bounds
			print_string_to_buffer(buf, "<invalid>")
		}

		prev = i
	}

	print_string_to_buffer(buf, fmt[prev:])
}


bprint :: proc(buf: ^[]byte, args: ..any) {
	is_type_string :: proc(info: ^Type_Info) -> bool {
		using Type_Info
		info = type_info_base(info)
		if info == null {
			return false
		}

		match type i : info {
		case String:
			return true
		}
		return false
	}


	prev_string := false
	for i := 0; i < args.count; i++ {
		arg := args[i]
		is_string := arg.data != null && is_type_string(arg.type_info)
		if i > 0 && !is_string && !prev_string {
			print_space_to_buffer(buf)
		}
		print_any_to_buffer(buf, arg)
		prev_string = is_string;
	}
}

bprintln :: proc(buf: ^[]byte, args: ..any) {
	for i := 0; i < args.count; i++ {
		if i > 0 {
			append(buf, #rune " ")
		}
		print_any_to_buffer(buf, args[i])
	}
	print_nl_to_buffer(buf)
}
