#import "os.odin";
#import "mem.odin";
#import "utf8.odin";

const PRINT_BUF_SIZE = 1<<12;

proc fprint(f ^os.File, args ..any) -> int {
	data: [PRINT_BUF_SIZE]byte;
	buf := data[:0];
	bprint(^buf, ..args);
	os.write(f, buf);
	return buf.count;
}

proc fprintln(f ^os.File, args ..any) -> int {
	data: [PRINT_BUF_SIZE]byte;
	buf := data[:0];
	bprintln(^buf, ..args);
	os.write(f, buf);
	return buf.count;
}
proc fprintf(f ^os.File, fmt string, args ..any) -> int {
	data: [PRINT_BUF_SIZE]byte;
	buf := data[:0];
	bprintf(^buf, fmt, ..args);
	os.write(f, buf);
	return buf.count;
}


proc print(args ..any) -> int {
	return fprint(os.stdout, ..args);
}
proc println(args ..any) -> int {
	return fprintln(os.stdout, ..args);
}
proc printf(fmt string, args ..any) -> int {
	return fprintf(os.stdout, fmt, ..args);
}



proc fprint_type(f ^os.File, info ^Type_Info) {
	data: [PRINT_BUF_SIZE]byte;
	buf := data[:0];
	bprint_type(^buf, info);
	os.write(f, buf);
}



proc print_byte_buffer(buf ^[]byte, b []byte) {
	if buf.count < buf.capacity {
		n := min(buf.capacity-buf.count, b.count);
		if n > 0 {
			mem.copy(buf.data + buf.count, b.data, n);
			buf.count += n;
		}
	}
}

proc bprint_string(buf ^[]byte, s string) {
	print_byte_buffer(buf, s as []byte);
}


proc byte_reverse(b []byte) {
	n := b.count;
	for i := 0; i < n/2; i++ {
		b[i], b[n-1-i] = b[n-1-i], b[i];
	}
}

proc bprint_rune(buf ^[]byte, r rune) {
	b, n := utf8.encode_rune(r);
	bprint_string(buf, b[:n] as string);
}

proc bprint_space(buf ^[]byte) { bprint_rune(buf, ' '); }
proc bprint_nl   (buf ^[]byte) { bprint_rune(buf, '\n'); }

__NUM_TO_CHAR_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$";

proc bprint_bool(buffer ^[]byte, b bool) {
	if b {
		bprint_string(buffer, "true");
	} else {
		bprint_string(buffer, "false");
	}
}

proc bprint_pointer(buffer ^[]byte, p rawptr) #inline {
	bprint_string(buffer, "0x");
	bprint_u64(buffer, p as uint as u64);
}

proc bprint_f16 (buffer ^[]byte, f f32)  #inline { print__f64(buffer, f as f64, 4); }
proc bprint_f32 (buffer ^[]byte, f f32)  #inline { print__f64(buffer, f as f64, 7); }
proc bprint_f64 (buffer ^[]byte, f f64)  #inline { print__f64(buffer, f as f64, 16); }
proc bprint_u64(buffer ^[]byte, value u64) {
	i := value;
	buf: [20]byte;
	len := 0;
	if i == 0 {
		buf[len] = '0';
		len++;
	}
	for i > 0 {
		buf[len] = __NUM_TO_CHAR_TABLE[i % 10];
		len++;
		i /= 10;
	}
	byte_reverse(buf[:len]);
	bprint_string(buffer, buf[:len] as string);
}
proc bprint_i64(buffer ^[]byte, value i64) {
	// TODO(bill): Cleanup printing
	i := value;
	if i < 0 {
		i = -i;
		bprint_rune(buffer, '-');
	}
	bprint_u64(buffer, i as u64);
}

/*
proc bprint_u128(buffer ^[]byte, value u128) {
	a := value transmute [2]u64;
	if a[1] != 0 {
		bprint_u64(buffer, a[1]);
	}
	bprint_u64(buffer, a[0]);
}
proc bprint_i128(buffer ^[]byte, value i128) {
	i := value;
	if i < 0 {
		i = -i;
		bprint_rune(buffer, '-');
	}
	bprint_u128(buffer, i as u128);
}
*/


proc print__f64(buffer ^[]byte, value f64, decimal_places int) {
	f := value;
	if f == 0 {
		bprint_rune(buffer, '0');
		return;
	}
	if f < 0 {
		bprint_rune(buffer, '-');
		f = -f;
	}

	i := f as u64;
	bprint_u64(buffer, i);
	f -= i as f64;

	bprint_rune(buffer, '.');

	mult: f64 = 10.0;
	for ; decimal_places >= 0; decimal_places-- {
		i = (f * mult) as u64;
		bprint_u64(buffer, i as u64);
		f -= i as f64 / mult;
		mult *= 10;
	}
}

proc bprint_type(buf ^[]byte, ti ^Type_Info) {
	if ti == nil {
		return;
	}

	using Type_Info;
	match type info : ti {
	case Named:
		bprint_string(buf, info.name);
	case Integer:
		match {
		case ti == type_info(int):  bprint_string(buf, "int");
		case ti == type_info(uint): bprint_string(buf, "uint");
		default:
			if info.signed {
				bprint_string(buf, "i");
			} else {
				bprint_string(buf, "u");
			}
			bprint_u64(buf, 8*info.size as u64);
		}

	case Float:
		match info.size {
		case 4: bprint_string(buf, "f32");
		case 8: bprint_string(buf, "f64");
		}
	case String:  bprint_string(buf, "string");
	case Boolean: bprint_string(buf, "bool");
	case Pointer:
		if info.elem == nil {
			bprint_string(buf, "rawptr");
		} else {
			bprint_string(buf, "^");
			bprint_type(buf, info.elem);
		}
	case Maybe:
		bprint_string(buf, "?");
		bprint_type(buf, info.elem);
	case Procedure:
		bprint_string(buf, "proc");
		if info.params == nil {
			bprint_string(buf, "()");
		} else {
			count := (info.params as ^Tuple).fields.count;
			if count == 1 { bprint_string(buf, "("); }
			bprint_type(buf, info.params);
			if count == 1 { bprint_string(buf, ")"); }
		}
		if info.results != nil {
			bprint_string(buf, " -> ");
			bprint_type(buf, info.results);
		}
	case Tuple:
		count := info.fields.count;
		if count != 1 { bprint_string(buf, "("); }
		for i := 0; i < count; i++ {
			if i > 0 { bprint_string(buf, ", "); }

			f := info.fields[i];

			if f.name.count > 0 {
				bprint_string(buf, f.name);
				bprint_string(buf, ": ");
			}
			bprint_type(buf, f.type_info);
		}
		if count != 1 { bprint_string(buf, ")"); }

	case Array:
		bprint_string(buf, "[");
		bprint_i64(buf, info.count as i64);
		bprint_string(buf, "]");
		bprint_type(buf, info.elem);
	case Slice:
		bprint_string(buf, "[");
		bprint_string(buf, "]");
		bprint_type(buf, info.elem);
	case Vector:
		bprint_string(buf, "[vector ");
		bprint_i64(buf, info.count as i64);
		bprint_string(buf, "]");
		bprint_type(buf, info.elem);

	case Struct:
		bprint_string(buf, "struct ");
		if info.packed  { bprint_string(buf, "#packed "); }
		if info.ordered { bprint_string(buf, "#ordered "); }
		bprint_string(buf, "{");
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}
			bprint_any(buf, info.fields[i].name);
			bprint_string(buf, ": ");
			bprint_type(buf, info.fields[i].type_info);
		}
		bprint_string(buf, "}");

	case Union:
		bprint_string(buf, "union {");
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}
			bprint_any(buf, info.fields[i].name);
			bprint_string(buf, ": ");
			bprint_type(buf, info.fields[i].type_info);
		}
		bprint_string(buf, "}");

	case Raw_Union:
		bprint_string(buf, "raw_union {");
		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}
			bprint_any(buf, info.fields[i].name);
			bprint_string(buf, ": ");
			bprint_type(buf, info.fields[i].type_info);
		}
		bprint_string(buf, "}");

	case Enum:
		bprint_string(buf, "enum ");
		bprint_type(buf, info.base);
		bprint_string(buf, "{}");
	}
}


proc make_any(type_info ^Type_Info, data rawptr) -> any {
	a: any;
	a.type_info = type_info;
	a.data = data;
	return a;
}

proc bprint_any(buf ^[]byte, arg any) {
	if arg.type_info == nil {
		bprint_string(buf, "<nil>");
		return;
	}

	if arg.data == nil {
		bprint_string(buf, "<nil>");
		return;
	}

	using Type_Info;
	match type info : arg.type_info {
	case Named:
		a := make_any(info.base, arg.data);
		match type b : info.base {
		case Struct:
			bprint_string(buf, info.name);
			bprint_string(buf, "{");
			for i := 0; i < b.fields.count; i++ {
				f := b.fields[i];
				if i > 0 {
					bprint_string(buf, ", ");
				}
				bprint_string(buf, f.name);
				// bprint_any(buf, f.offset);
				bprint_string(buf, " = ");
				data := arg.data as ^byte + f.offset;
				bprint_any(buf, make_any(f.type_info, data));
			}
			bprint_string(buf, "}");

		default:
			bprint_any(buf, a);
		}

	case Integer:
		match type i : arg {
		case i8:   bprint_i64(buf, i as i64);
		case u8:   bprint_u64(buf, i as u64);
		case i16:  bprint_i64(buf, i as i64);
		case u16:  bprint_u64(buf, i as u64);
		case i32:  bprint_i64(buf, i as i64);
		case u32:  bprint_u64(buf, i as u64);
		case i64:  bprint_i64(buf, i);
		case u64:  bprint_u64(buf, i);
		// case i128: bprint_i128(buf, i);
		// case u128: bprint_u128(buf, i);

		case int:  bprint_i64(buf, i as i64);
		case uint: bprint_u64(buf, i as u64);
		}

	case Float:
		match type f : arg {
		// case f16:  bprint_f64(buf, f as f64);
		case f32:  bprint_f32(buf, f);
		case f64:  bprint_f64(buf, f);
		// case f128: bprint_f64(buf, f as f64);
		}

	case String:
		match type s : arg {
		case string: bprint_string(buf, s);
		}

	case Boolean:
		match type b : arg {
		case bool: bprint_bool(buf, b);
		}

	case Pointer:
		match type p : arg {
		case ^Type_Info: bprint_type(buf, p);
		default:         bprint_pointer(buf, (arg.data as ^rawptr)^);
		}

	case Maybe:
		size := mem.size_of_type_info(info.elem);
		data := slice_ptr(arg.data as ^byte, size+1);
		if data[size] != 0 {
			bprint_any(buf, make_any(info.elem, arg.data));
		} else {
			bprint_string(buf, "nil");
		}

	case Enum:
		value: i64 = 0;

		match type i : make_any(info.base, arg.data) {
		case i8:   value = i as i64;
		case i16:  value = i as i64;
		case i32:  value = i as i64;
		case i64:  value = i as i64;
		case u8:   value = i as i64;
		case u16:  value = i as i64;
		case u32:  value = i as i64;
		case u64:  value = i as i64;
		}
		bprint_string(buf, __enum_to_string(arg.type_info, value));

	case Array:
		bprintf(buf, "[%]%{", info.count, info.elem);
		defer bprint_string(buf, "}");

		for i := 0; i < info.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}

			data := arg.data as ^byte + i*info.elem_size;
			bprint_any(buf, make_any(info.elem, data));
		}

	case Slice:
		slice := arg.data as ^[]byte;
		bprintf(buf, "[]%{", info.elem);
		defer bprint_string(buf, "}");

		for i := 0; i < slice.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}

			data := slice.data + i*info.elem_size;
			bprint_any(buf, make_any(info.elem, data));
		}

	case Vector:
		proc is_bool(type_info ^Type_Info) -> bool {
			match type info : type_info {
			case Named:
				return is_bool(info.base);
			case Boolean:
				return true;
			}
			return false;
		}

		bprintf(buf, "[vector %]%{", info.count, info.elem);
		defer bprint_string(buf, "}");

		if is_bool(info.elem) {
			return;
		}

		for i := 0; i < info.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}

			data := arg.data as ^byte + i*info.elem_size;
			bprint_any(buf, make_any(info.elem, data));
		}


	case Struct:
		bprintf(buf, "%{", arg.type_info);
		defer bprint_string(buf, "}");

		for i := 0; i < info.fields.count; i++ {
			if i > 0 {
				bprint_string(buf, ", ");
			}
			bprint_string(buf, info.fields[i].name);
			bprint_string(buf, " = ");
			data := arg.data as ^byte + info.fields[i].offset;
			ti := info.fields[i].type_info;
			bprint_any(buf, make_any(ti, data));
		}

	case Union:
		bprint_string(buf, "(union)");
	case Raw_Union:
		bprint_string(buf, "(raw_union)");
	case Procedure:
		bprint_type(buf, arg.type_info);
		bprint_string(buf, " @ ");
		bprint_pointer(buf, (arg.data as ^rawptr)^);
	}
}


proc bprintf(buf ^[]byte, fmt string, args ..any) -> int {
	proc is_digit(r rune) -> bool #inline {
		return '0' <= r && r <= '9';
	}

	proc parse_int(s string, offset int) -> (int, int) {
		result := 0;

		for ; offset < s.count; offset++ {
			c := s[offset] as rune;
			if !is_digit(c) {
				break;
			}

			result *= 10;
			result += (c - '0') as int;
		}

		return result, offset;
	}

	prev := 0;
	implicit_index := 0;

	for i := 0; i < fmt.count; i++ {
		r := fmt[i] as rune;
		index := implicit_index;

		if r != '%' {
			continue;
		}

		bprint_string(buf, fmt[prev:i]);
		i++; // Skip %
		if i < fmt.count {
			next := fmt[i] as rune;

			if next == '%' {
				bprint_string(buf, "%");
				i++;
				prev = i;
				continue;
			}

			if is_digit(next) {
				index, i = parse_int(fmt, i);
			}
		}

		if 0 <= index && index < args.count {
			bprint_any(buf, args[index]);
			implicit_index = index+1;
		} else {
			// TODO(bill): Error check index out bounds
			bprint_string(buf, "<invalid>");
		}

		prev = i;
	}

	bprint_string(buf, fmt[prev:]);
	return buf.count;
}


proc bprint(buf ^[]byte, args ..any) -> int {
	proc is_type_string(info ^Type_Info) -> bool {
		using Type_Info;
		if info == nil {
			return false;
		}

		match type i : type_info_base(info) {
		case String:
			return true;
		}
		return false;
	}


	prev_string := false;
	for i := 0; i < args.count; i++ {
		arg := args[i];
		is_string := arg.data != nil && is_type_string(arg.type_info);
		if i > 0 && !is_string && !prev_string {
			bprint_space(buf);
		}
		bprint_any(buf, arg);
		prev_string = is_string;
	}
	return buf.count;
}

proc bprintln(buf ^[]byte, args ..any) -> int {
	for i := 0; i < args.count; i++ {
		if i > 0 {
			append(buf, ' ');
		}
		bprint_any(buf, args[i]);
	}
	bprint_nl(buf);
	return buf.count;
}
