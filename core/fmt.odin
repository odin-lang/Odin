#import "os.odin"
#import "mem.odin"
#import "utf8.odin"

PRINT_BUF_SIZE :: 1<<12

fprint :: proc(f: ^os.File, args: ..any) -> int {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprint(^buf, ..args)
	os.write(f, buf)
	return buf.count
}

fprintln :: proc(f: ^os.File, args: ..any) -> int {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprintln(^buf, ..args)
	os.write(f, buf)
	return buf.count
}
fprintf :: proc(f: ^os.File, fmt: string, args: ..any) -> int {
	data: [PRINT_BUF_SIZE]byte
	buf := data[:0]
	bprintf(^buf, fmt, ..args)
	os.write(f, buf)
	return buf.count
}


print :: proc(args: ..any) -> int {
	return fprint(os.stdout, ..args)
}
println :: proc(args: ..any) -> int {
	return fprintln(os.stdout, ..args)
}
printf :: proc(fmt: string, args: ..any) -> int {
	return fprintf(os.stdout, fmt, ..args)
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
			mem.copy(buf.data + buf.count, ^b[0], n)
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

__NUM_TO_CHAR_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$"

print_bool_to_buffer :: proc(buffer: ^[]byte, b : bool) {
	if b { print_string_to_buffer(buffer, "true") }
	else { print_string_to_buffer(buffer, "false") }
}

print_pointer_to_buffer :: proc(buffer: ^[]byte, p: rawptr) #inline {
	print_string_to_buffer(buffer, "0x")
	print_u64_to_buffer(buffer, p as uint as u64)
}

print_f32_to_buffer :: proc(buffer: ^[]byte, f: f32) #inline { print__f64(buffer, f as f64, 7) }
print_f64_to_buffer :: proc(buffer: ^[]byte, f: f64) #inline { print__f64(buffer, f, 10) }
print_u64_to_buffer :: proc(buffer: ^[]byte, value: u64) {
	i := value
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
print_i64_to_buffer :: proc(buffer: ^[]byte, value: i64) {
	i := value
	neg := i < 0
	if neg {
		i = -i
		print_rune_to_buffer(buffer, #rune "-")
	}
	print_u64_to_buffer(buffer, i as u64)
}

print__f64 :: proc(buffer: ^[]byte, value: f64, decimal_places: int) {
	f := value
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
	if ti == nil { return }

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
			print_u64_to_buffer(buf, 8*info.size as u64)
		}

	case Float:
		match info.size {
		case 4: print_string_to_buffer(buf, "f32")
		case 8: print_string_to_buffer(buf, "f64")
		}
	case String:  print_string_to_buffer(buf, "string")
	case Boolean: print_string_to_buffer(buf, "bool")
	case Pointer:
		if info.elem == nil {
			print_string_to_buffer(buf, "rawptr")
		} else {
			print_string_to_buffer(buf, "^")
			print_type_to_buffer(buf, info.elem)
		}
	case Maybe:
		print_string_to_buffer(buf, "?")
		print_type_to_buffer(buf, info.elem)
	case Procedure:
		print_string_to_buffer(buf, "proc")
		if info.params == nil {
			print_string_to_buffer(buf, "()")
		} else {
			count := (info.params as ^Tuple).fields.count
			if count == 1 { print_string_to_buffer(buf, "(") }
			print_type_to_buffer(buf, info.params)
			if count == 1 { print_string_to_buffer(buf, ")") }
		}
		if info.results != nil {
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
		print_i64_to_buffer(buf, info.count as i64)
		print_string_to_buffer(buf, "]")
		print_type_to_buffer(buf, info.elem)
	case Slice:
		print_string_to_buffer(buf, "[")
		print_string_to_buffer(buf, "]")
		print_type_to_buffer(buf, info.elem)
	case Vector:
		print_string_to_buffer(buf, "{")
		print_i64_to_buffer(buf, info.count as i64)
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


make_any :: proc(type_info: ^Type_Info, data: rawptr) -> any {
	a: any
	a.type_info = type_info
	a.data = data
	return a
}

print_any_to_buffer :: proc(buf: ^[]byte, arg: any) {
	if arg.type_info == nil {
		print_string_to_buffer(buf, "<nil>")
		return
	}

	using Type_Info
	match type info : arg.type_info {
	case Named:
		a := make_any(info.base, arg.data)
		match type b : info.base {
		case Struct:
			print_string_to_buffer(buf, info.name)
			print_string_to_buffer(buf, "{")
			for i := 0; i < b.fields.count; i++ {
				f := b.fields[i];
				if i > 0 {
					print_string_to_buffer(buf, ", ")
				}
				print_string_to_buffer(buf, f.name)
				// print_any_to_buffer(buf, f.offset)
				print_string_to_buffer(buf, " = ")
				data := arg.data as ^byte + f.offset
				print_any_to_buffer(buf, make_any(f.type_info, data))
			}
			print_string_to_buffer(buf, "}")

		default:
			print_any_to_buffer(buf, a)
		}

	case Integer:
		if arg.data != nil {
			match type i : arg {
			case i8:  print_i64_to_buffer(buf, i as i64)
			case i16: print_i64_to_buffer(buf, i as i64)
			case i32: print_i64_to_buffer(buf, i as i64)
			case i64: print_i64_to_buffer(buf, i as i64)
			case u8:  print_u64_to_buffer(buf, i as u64)
			case u16: print_u64_to_buffer(buf, i as u64)
			case u32: print_u64_to_buffer(buf, i as u64)
			case u64: print_u64_to_buffer(buf, i as u64)
			}
		} else {
			print_u64_to_buffer(buf, 0)
		}

	case Float:
		if arg.data != nil {
			match type f : arg {
			case f32: print_f64_to_buffer(buf, f as f64)
			case f64: print_f64_to_buffer(buf, f as f64)
			}
		} else {
			print_f64_to_buffer(buf, 0)
		}

	case String:
		if arg.data != nil {
			match type s : arg {
			case string: print_string_to_buffer(buf, s)
			}
		} else {
			print_string_to_buffer(buf, "")
		}

	case Boolean:
		if arg.data != nil {
			match type b : arg {
			case bool: print_bool_to_buffer(buf, b)
			}
		} else {
			print_bool_to_buffer(buf, false)
		}

	case Pointer:
		if arg.data != nil {
			match type p : arg {
			case ^Type_Info: print_type_to_buffer(buf, p)
			default:         print_pointer_to_buffer(buf, (arg.data as ^rawptr)^)
			}
		} else {
			print_pointer_to_buffer(buf, nil)
		}

	case Maybe:
		size := mem.size_of_type_info(info.elem)
		data := slice_ptr(arg.data as ^byte, size+1)
		if data[size] != 0 && arg.data != nil {
			print_any_to_buffer(buf, make_any(info.elem, arg.data))
		} else {
			print_string_to_buffer(buf, "nil")
		}

	case Enum:
		value: i64 = 0

		match type i : make_any(info.base, arg.data) {
		case i8:  value = i as i64
		case i16: value = i as i64
		case i32: value = i as i64
		case i64: value = i as i64
		case u8:  value = i as i64
		case u16: value = i as i64
		case u32: value = i as i64
		case u64: value = i as i64
		}
		print_string_to_buffer(buf, __enum_to_string(arg.type_info, value))

	case Array:
		bprintf(buf, "[%]%{", info.count, info.elem)
		defer print_string_to_buffer(buf, "}")

		for i := 0; i < info.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			data := arg.data as ^byte + i*info.elem_size
			print_any_to_buffer(buf, make_any(info.elem, data))
		}

	case Slice:
		slice := arg.data as ^[]byte
		bprintf(buf, "[]%{", info.elem)
		defer print_string_to_buffer(buf, "}")

		for i := 0; i < slice.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			data := slice.data + i*info.elem_size
			print_any_to_buffer(buf, make_any(info.elem, data))
		}

	case Vector:
		is_bool :: proc(type_info: ^Type_Info) -> bool {
			match type info : type_info {
			case Named:
				return is_bool(info.base)
			case Boolean:
				return true
			}
			return false
		}

		bprintf(buf, "{%}%{", info.count, info.elem)
		defer print_string_to_buffer(buf, "}")

		if is_bool(info.elem) {
			return
		}

		for i := 0; i < info.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}

			data := arg.data as ^byte + i*info.elem_size
			print_any_to_buffer(buf, make_any(info.elem, data))
		}


	case Struct:
		if arg.data == nil {
			print_string_to_buffer(buf, "nil")
			return
		}

		bprintf(buf, "%{", arg.type_info)
		defer print_string_to_buffer(buf, "}")

		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				print_string_to_buffer(buf, ", ")
			}
			print_string_to_buffer(buf, info.fields[i].name)
			print_string_to_buffer(buf, " = ")
			data := arg.data as ^byte + info.fields[i].offset
			ti := info.fields[i].type_info
			print_any_to_buffer(buf, make_any(ti, data))
		}

	case Union:
		print_string_to_buffer(buf, "(union)")
	case Raw_Union:
		print_string_to_buffer(buf, "(raw_union)")
	case Procedure:
		print_type_to_buffer(buf, arg.type_info)
		print_string_to_buffer(buf, " @ 0x")
		print_pointer_to_buffer(buf, (arg.data as ^rawptr)^)
	}
}


bprintf :: proc(buf: ^[]byte, fmt: string, args: ..any) -> int {
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
	return buf.count
}


bprint :: proc(buf: ^[]byte, args: ..any) -> int {
	is_type_string :: proc(info: ^Type_Info) -> bool {
		using Type_Info
		if info == nil {
			return false
		}

		match type i : type_info_base(info) {
		case String:
			return true
		}
		return false
	}


	prev_string := false
	for i := 0; i < args.count; i++ {
		arg := args[i]
		is_string := arg.data != nil && is_type_string(arg.type_info)
		if i > 0 && !is_string && !prev_string {
			print_space_to_buffer(buf)
		}
		print_any_to_buffer(buf, arg)
		prev_string = is_string;
	}
	return buf.count
}

bprintln :: proc(buf: ^[]byte, args: ..any) -> int {
	for i := 0; i < args.count; i++ {
		if i > 0 {
			append(buf, #rune " ")
		}
		print_any_to_buffer(buf, args[i])
	}
	print_nl_to_buffer(buf)
	return buf.count
}
