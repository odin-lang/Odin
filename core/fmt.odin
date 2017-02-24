#import "os.odin";
#import "mem.odin";
#import "utf8.odin";
#import "types.odin";


_BUFFER_SIZE :: 1<<12;

Buffer :: struct {
	data:   []byte,
	length: int,
}

buffer_write :: proc(buf: ^Buffer, b: []byte) {
	if buf.length < buf.data.count {
		n := min(buf.data.count-buf.length, b.count);
		if n > 0 {
			copy(buf.data[buf.length:], b[:n]);
			buf.length += n;
		}
	}
}
buffer_write_string :: proc(buf: ^Buffer, s: string) {
	buffer_write(buf, cast([]byte)s);
}
buffer_write_byte :: proc(buf: ^Buffer, b: byte) {
	if buf.length < buf.data.count {
		buf.data[buf.length] = b;
		buf.length += 1;
	}
}
buffer_write_rune :: proc(buf: ^Buffer, r: rune) {
	if r < utf8.RUNE_SELF {
		buffer_write_byte(buf, cast(byte)r);
		return;
	}

	b, n := utf8.encode_rune(r);
	buffer_write(buf, b[:n]);
}

Fmt_Info :: struct {
	minus:     bool,
	plus:      bool,
	space:     bool,
	zero:      bool,
	hash:      bool,
	width_set: bool,
	prec_set:  bool,

	width:     int,
	prec:      int,

	reordered:      bool,
	good_arg_index: bool,

	buf: ^Buffer,
	arg: any, // Temporary
}



fprint :: proc(fd: os.Handle, args: ...any) -> int {
	data: [_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprint(^buf, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}

fprintln :: proc(fd: os.Handle, args: ...any) -> int {
	data: [_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprintln(^buf, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ...any) -> int {
	data: [_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	bprintf(^buf, fmt, ...args);
	os.write(fd, buf.data[:buf.length]);
	return buf.length;
}


print :: proc(args: ...any) -> int {
	return fprint(os.stdout, ...args);
}
println :: proc(args: ...any) -> int {
	return fprintln(os.stdout, ...args);
}
printf :: proc(fmt: string, args: ...any) -> int {
	return fprintf(os.stdout, fmt, ...args);
}


fprint_type :: proc(fd: os.Handle, info: ^Type_Info) {
	data: [_BUFFER_SIZE]byte;
	buf := Buffer{data[:], 0};
	buffer_write_type(^buf, info);
	os.write(fd, buf.data[:buf.length]);
}

buffer_write_type :: proc(buf: ^Buffer, ti: ^Type_Info) {
	if ti == nil {
		return;
	}

	using Type_Info;
	match info in ti {
	case Named:
		buffer_write_string(buf, info.name);
	case Integer:
		match {
		case ti == type_info(int):  buffer_write_string(buf, "int");
		case ti == type_info(uint): buffer_write_string(buf, "uint");
		default:
			buffer_write_string(buf, info.signed ? "i" : "u");
			fi := Fmt_Info{buf = buf};
			fmt_int(^fi, cast(u64)(8*info.size), false, 'd');
		}

	case Float:
		match info.size {
		case 4: buffer_write_string(buf, "f32");
		case 8: buffer_write_string(buf, "f64");
		}
	case String:  buffer_write_string(buf, "string");
	case Boolean: buffer_write_string(buf, "bool");
	case Pointer:
		if info.elem == nil {
			buffer_write_string(buf, "rawptr");
		} else {
			buffer_write_string(buf, "^");
			buffer_write_type(buf, info.elem);
		}
	case Procedure:
		buffer_write_string(buf, "proc");
		if info.params == nil {
			buffer_write_string(buf, "()");
		} else {
			t := union_cast(^Tuple)info.params;
			buffer_write_string(buf, "(");
			for type, i in t.types {
				if i > 0 { buffer_write_string(buf, ", "); }
				buffer_write_type(buf, type);
			}
			buffer_write_string(buf, ")");
		}
		if info.results != nil {
			buffer_write_string(buf, " -> ");
			buffer_write_type(buf, info.results);
		}
	case Tuple:
		count := info.names.count;
		if count != 1 { buffer_write_string(buf, "("); }
		for name, i in info.names {
			if i > 0 { buffer_write_string(buf, ", "); }

			type := info.types[i];

			if name.count > 0 {
				buffer_write_string(buf, name);
				buffer_write_string(buf, ": ");
			}
			buffer_write_type(buf, type);
		}
		if count != 1 { buffer_write_string(buf, ")"); }

	case Array:
		buffer_write_string(buf, "[");
		fi := Fmt_Info{buf = buf};
		fmt_int(^fi, cast(u64)info.count, false, 'd');
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);
	case Dynamic_Array:
		buffer_write_string(buf, "[...]");
		buffer_write_type(buf, info.elem);
	case Slice:
		buffer_write_string(buf, "[");
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);
	case Vector:
		buffer_write_string(buf, "[vector ");
		fi := Fmt_Info{buf = buf};
		fmt_int(^fi, cast(u64)info.count, false, 'd');
		buffer_write_string(buf, "]");
		buffer_write_type(buf, info.elem);

	case Map:
		buffer_write_string(buf, "map[");
		buffer_write_type(buf, info.key);
		buffer_write_byte(buf, ']');
		buffer_write_type(buf, info.value);

	case Struct:
		buffer_write_string(buf, "struct ");
		if info.packed  { buffer_write_string(buf, "#packed "); }
		if info.ordered { buffer_write_string(buf, "#ordered "); }
		if info.custom_align {
			buffer_write_string(buf, "#align ");
			fi := Fmt_Info{buf = buf};
			fmt_int(^fi, cast(u64)info.align, false, 'd');
			buffer_write_byte(buf, ' ');
		}
		buffer_write_byte(buf, '{');
		for name, i in info.names {
			if i > 0 {
				buffer_write_string(buf, ", ");
			}
			buffer_write_string(buf, name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, info.types[i]);
		}
		buffer_write_byte(buf, '}');

	case Union:
		buffer_write_string(buf, "union {");
		cf := info.common_fields;
		total_count := 0;
		for name, i in cf.names {
			if i > 0 {
				buffer_write_string(buf, ", ");
			}
			buffer_write_string(buf, name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, cf.types[i]);
			total_count += 1;
		}
		for name, i in info.variant_names {
			if total_count > 0 || i > 0 {
				buffer_write_string(buf, ", ");
			}
			buffer_write_string(buf, name);
			buffer_write_byte(buf, '{');
			defer buffer_write_byte(buf, '}');

			variant_type := type_info_base(info.variant_types[i]);
			variant := union_cast(^Struct)variant_type;

			vc := variant.names.count-cf.names.count;
			for j in 0..<vc {
				if j > 0 {
					buffer_write_string(buf, ", ");
				}
				index := j + cf.names.count;
				buffer_write_string(buf, variant.names[index]);
				buffer_write_string(buf, ": ");
				buffer_write_type(buf, variant.types[index]);
			}
		}
		buffer_write_string(buf, "}");

	case Raw_Union:
		buffer_write_string(buf, "raw_union {");
		for name, i in info.names {
			if i > 0 {
				buffer_write_string(buf, ", ");
			}
			buffer_write_string(buf, name);
			buffer_write_string(buf, ": ");
			buffer_write_type(buf, info.types[i]);
		}
		buffer_write_string(buf, "}");

	case Enum:
		buffer_write_string(buf, "enum ");
		buffer_write_type(buf, info.base);
		buffer_write_string(buf, " {");
		for name, i in info.names {
			if i > 0 {
				buffer_write_string(buf, ", ");
			}
			buffer_write_string(buf, name);
		}
		buffer_write_string(buf, "}");
	}
}


bprint :: proc(buf: ^Buffer, args: ...any) -> int {
	fi: Fmt_Info;
	fi.buf = buf;

	prev_string := false;
	for arg, i in args {
		is_string := arg.data != nil && types.is_string(arg.type_info);
		if i > 0 && !is_string && !prev_string {
			buffer_write_byte(buf, ' ');
		}
		fmt_value(^fi, args[i], 'v');
		prev_string = is_string;
	}
	return buf.length;
}

bprintln :: proc(buf: ^Buffer, args: ...any) -> int {
	fi: Fmt_Info;
	fi.buf = buf;

	for arg, i in args {
		if i > 0 {
			buffer_write_byte(buf, ' ');
		}
		fmt_value(^fi, args[i], 'v');
	}
	buffer_write_byte(buf, '\n');
	return buf.length;
}

sprint :: proc(buf: []byte, args: ...any) -> string {
	b: Buffer;
	b.data = buf;
	count := bprint(^b, ...args);
	return cast(string)b.data[:b.length];
}
sprintln :: proc(buf: []byte, args: ...any) -> string {
	b: Buffer;
	b.data = buf;
	count := bprintln(^b, ...args);
	return cast(string)b.data[:b.length];
}
sprintf :: proc(buf: []byte, fmt: string, args: ...any) -> string {
	b: Buffer;
	b.data = buf;
	count := bprintf(^b, fmt, ...args);
	return cast(string)b.data[:b.length];
}




parse_int :: proc(s: string, offset: int) -> (result: int, offset: int, ok: bool) {
	is_digit :: proc(r: rune) -> bool #inline {
		return '0' <= r && r <= '9';
	}

	result := 0;
	ok := true;

	i := 0;
	for o in offset..<s.count {
		c := cast(rune)s[offset+i];
		if !is_digit(c) {
			break;
		}
		i += 1;

		result *= 10;
		result += cast(int)(c - '0');
	}

	return result, offset+i, i != 0;
}

_arg_number :: proc(fi: ^Fmt_Info,
                    arg_index: int,
                    format: string,
                    offset: int,
                    arg_count: int,
                    ) -> (index: int, offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if format.count < 3 {
			return 0, 1, false;
		}

		for i in 1..<format.count {
			if format[i] == ']' {
				width, new_index, ok := parse_int(format, 1);
				if !ok || new_index != i {
					return 0, i+1, false;
				}
				return width-1, i+1, true;
			}
		}

		return 0, 1, false;
	}


	if format.count <= offset || format[offset] != '[' {
		return arg_index, offset, false;
	}
	fi.reordered = true;
	index, width, ok := parse_arg_number(format[offset:]);
	if ok && 0 <= index && index < arg_count {
		return index, offset+width, true;
	}
	fi.good_arg_index = false;
	return arg_index, offset+width, false;
}

int_from_arg :: proc(args: []any, arg_index: int) -> (int, int, bool) {
	num := 0;
	new_arg_index := arg_index;
	ok := true;
	if arg_index < args.count {
		arg := args[arg_index];
		arg.type_info = type_info_base(arg.type_info);
		match i in arg {
		case int:  num = i;
		case i8:   num = cast(int)i;
		case i16:  num = cast(int)i;
		case i32:  num = cast(int)i;
		case i64:  num = cast(int)i;
		case u8:   num = cast(int)i;
		case u16:  num = cast(int)i;
		case u32:  num = cast(int)i;
		case u64:  num = cast(int)i;
		default:
			ok = false;
		}
	}

	return num, new_arg_index, ok;
}


fmt_bad_verb :: proc(using fi: ^Fmt_Info, verb: rune) {
	assert(verb != 'v');
	buffer_write_string(buf, "%!");
	buffer_write_rune(buf, verb);
	buffer_write_byte(buf, '(');
	if arg.type_info != nil {
		buffer_write_type(buf, arg.type_info);
		buffer_write_byte(buf, '=');
		fmt_value(fi, arg, 'v');
	} else {
		buffer_write_string(buf, "<nil>");
	}
	buffer_write_byte(buf, ')');
}

fmt_bool :: proc(using fi: ^Fmt_Info, b: bool, verb: rune) {
	match verb {
	case 't', 'v':
		buffer_write_string(buf, b ? "true" : "false");
	default:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^Fmt_Info, width: int) {
	if width <= 0 {
		return;
	}
	pad_byte: byte = ' ';
	if fi.zero {
		pad_byte = '0';
	}

	count := min(width, fi.buf.data.count-fi.buf.length);
	start := fi.buf.length;
	for i in start..<count {
		fi.buf.data[i] = pad_byte;
	}
	fi.buf.length += count;
}

fmt_integer :: proc(fi: ^Fmt_Info, u: u64, base: int, signed: bool, digits: string) {
	negative := signed && cast(i64)u < 0;
	if signed {
		u = cast(u64)abs(cast(i64)u);
	}
	buf: [256]byte;
	if fi.width_set || fi.prec_set {
		width := fi.width + fi.prec + 3;
		if width > buf.count {
			// TODO(bill):????
			panic("fmt_integer buffer overrun. Width and precision too big");
		}
	}

	prec := 0;
	if fi.prec_set {
		prec = fi.prec;
		if prec == 0 && u == 0 {
			old_zero := fi.zero;
			fi.zero = false;
			fmt_write_padding(fi, fi.width);
			fi.zero = old_zero;
			return;
		}
	} else if fi.zero && fi.width_set {
		prec = fi.width;
		if negative || fi.plus || fi.space {
			// There needs to be space for the "sign"
			prec -= 1;
		}
	}

	i := buf.count;

	match base {
	case 2, 8, 10, 16:
		break;
	default:
		panic("fmt_integer: unknown base, whoops");
	}

	for b := cast(u64)base; u >= b;  {
		i -= 1;
		next := u / b;
		buf[i] = digits[u%b];
		u = next;
	}
	i -= 1;
	buf[i] = digits[u];
	for i > 0 && prec > buf.count-i {
		i -= 1;
		buf[i] = '0';
	}

	if fi.hash {
		i -= 1;
		match base {
		case 2:  buf[i] = 'b';
		case 8:  buf[i] = 'o';
		case 10: buf[i] = 'd';
		case 16: buf[i] = digits[16];
		}
		i -= 1;
		buf[i] = '0';
	}

	if negative {
		i -= 1;
		buf[i] = '-';
	} else if fi.plus {
		i -= 1;
		buf[i] = '+';
	} else if fi.space {
		i -= 1;
		buf[i] = ' ';
	}

	old_zero := fi.zero;
	defer fi.zero = old_zero;
	fi.zero = false;

	if !fi.width_set || fi.width == 0 {
		buffer_write(fi.buf, buf[i:]);
	} else {
		width := fi.width - utf8.rune_count(cast(string)buf[i:]);
			if width > 0 {
			if fi.minus {
				// Right pad
				buffer_write(fi.buf, buf[i:]);
				fmt_write_padding(fi, width);
			} else {
				// Left pad
				fmt_write_padding(fi, width);
				buffer_write(fi.buf, buf[i:]);
			}
		}
	}

}

__DIGITS_LOWER := "0123456789abcdefx";
__DIGITS_UPPER := "0123456789ABCDEFX";

fmt_rune :: proc(fi: ^Fmt_Info, r: rune) {
	buffer_write_rune(fi.buf, r);
}

fmt_int :: proc(fi: ^Fmt_Info, u: u64, signed: bool, verb: rune) {
	match verb {
	case 'v': fmt_integer(fi, u, 10, signed, __DIGITS_LOWER);
	case 'b': fmt_integer(fi, u,  2, signed, __DIGITS_LOWER);
	case 'o': fmt_integer(fi, u,  8, signed, __DIGITS_LOWER);
	case 'd': fmt_integer(fi, u, 10, signed, __DIGITS_LOWER);
	case 'x': fmt_integer(fi, u, 16, signed, __DIGITS_LOWER);
	case 'X': fmt_integer(fi, u, 16, signed, __DIGITS_UPPER);
	case 'c', 'r':
		fmt_rune(fi, cast(rune)u);
	case 'U':
		r := cast(rune)u;
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb);
		} else {
			buffer_write_string(fi.buf, "U+");
			fmt_integer(fi, u, 16, false, __DIGITS_UPPER);
		}

	default:
		fmt_bad_verb(fi, verb);
	}
}


fmt_float :: proc(fi: ^Fmt_Info, v: f64, bit_size: int, verb: rune) {
	match verb {
	// case 'e', 'E', 'f', 'F', 'g', 'G', 'v':
	// case 'f', 'F', 'v':

	// TODO(bill): This is a shit copy from gb.h and I really need a decent implementation
	case 'f', 'F', 'v':
		width := 0;
		if fi.width_set {
			width = max(fi.width, 0);
		}
		prec := 3;
		if fi.prec_set {
			prec = max(fi.prec, 0);
		}

		if v == 0 {
			buffer_write_byte(fi.buf, '0');
			if fi.hash && width > 0 {
				buffer_write_byte(fi.buf, '.');
			}
		} else {
			signed := v < 0;
			v = abs(v);

			if signed {
				buffer_write_byte(fi.buf, '-');
			}

			val := cast(u64)v;
			fi.minus = false;
			fi.width = 0;
			fi.prec = 0;
			// TODO(bill): Write integer to buffer than use this crap
			fmt_integer(fi, val, 10, false, __DIGITS_LOWER);

			if fi.hash || prec > 0 {
				arg := v - cast(f64)val;
				mult: f64 = 10;
				buffer_write_byte(fi.buf, '.');
				for _ in 0..<prec {
					val := cast(u64)(arg*mult);
					buffer_write_byte(fi.buf, __DIGITS_LOWER[cast(u64)val]);
					arg -= cast(f64)val / mult;
					mult *= 10;
				}
			}
		}


		if width > 0 {
			fill: byte = ' ';
			match {
			case fi.zero:  fill = '0';
			case fi.space: fill = ' ';
			}

			for width > 0 {
				width -= 1;
				buffer_write_byte(fi.buf, fill);
			}
		}
	default:
		fmt_bad_verb(fi, verb);
		return;
	}
}
fmt_string :: proc(fi: ^Fmt_Info, s: string, verb: rune) {
	match verb {
	case 's', 'v':
		buffer_write_string(fi.buf, s);
	default:
		fmt_bad_verb(fi, verb);
	}
}

fmt_pointer :: proc(fi: ^Fmt_Info, p: rawptr, verb: rune) {
	match verb {
	case 'p', 'v':
		// Okay
	default:
		fmt_bad_verb(fi, verb);
		return;
	}
	u := cast(u64)cast(uint)p;
	if !fi.hash || verb == 'v' {
		buffer_write_string(fi.buf, "0x");
	}
	fmt_integer(fi, u, 16, false, __DIGITS_UPPER);
}

fmt_enum :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.type_info == nil || v.data == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}

	using Type_Info;
	match e in v.type_info {
	default:
		fmt_bad_verb(fi, verb);
		return;
	case Enum:
		match verb {
		case 'd', 'f':
			fmt_arg(fi, any{type_info_base(e.base), v.data}, verb);
		case 's', 'v':
			i: i64;
			f: f64;
			ok := false;
			a := any{type_info_base(e.base), v.data};
			match v in a {
			case i8:   i = cast(i64)v;
			case i16:  i = cast(i64)v;
			case i32:  i = cast(i64)v;
			case i64:  i = cast(i64)v;
			case int:  i = cast(i64)v;
			case u8:   i = cast(i64)v;
			case u16:  i = cast(i64)v;
			case u32:  i = cast(i64)v;
			case u64:  i = cast(i64)v;
			case uint: i = cast(i64)v;
			case f32:  f = cast(f64)v; i = transmute(i64)f;
			case f64:  f = cast(f64)v; i = transmute(i64)f;
			}

			if types.is_string(e.base) {
				for val, idx in e.values {
					if val.i == i {
						buffer_write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			} else if e.values.count == 0 {
				buffer_write_string(fi.buf, "");
				ok = true;
			} else {
				for val, idx in e.values {
					if val.i == i {
						buffer_write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			}

			if !ok {
				buffer_write_string(fi.buf, "!%(BAD ENUM VALUE)");
			}
		default:
			fmt_bad_verb(fi, verb);
			return;
		}
	}
}


fmt_value :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.data == nil || v.type_info == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}

	using Type_Info;
	match info in v.type_info {
	case Named:
		match b in info.base {
		case Struct:
			if verb != 'v' {
				fmt_bad_verb(fi, verb);
				return;
			}
			buffer_write_string(fi.buf, info.name);
			buffer_write_byte(fi.buf, '{');
			for _, i in b.names {
				if i > 0 {
					buffer_write_string(fi.buf, ", ");
				}
				buffer_write_string(fi.buf, b.names[i]);
				buffer_write_string(fi.buf, " = ");
				data := cast(^byte)v.data + b.offsets[i];
				fmt_arg(fi, any{b.types[i], cast(rawptr)data}, 'v');
			}
			buffer_write_byte(fi.buf, '}');

		default:
			fmt_value(fi, any{info.base, v.data}, verb);
		}

	case Boolean: fmt_arg(fi, v, verb);
	case Float:   fmt_arg(fi, v, verb);
	case Integer: fmt_arg(fi, v, verb);
	case String:  fmt_arg(fi, v, verb);

	case Pointer:
		if v.type_info == type_info(^Type_Info) {
			buffer_write_type(fi.buf, (cast(^^Type_Info)v.data)^);
		} else {
			fmt_pointer(fi, (cast(^rawptr)v.data)^, verb);
		}

	case Array:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_byte(fi.buf, '[');
		defer buffer_write_byte(fi.buf, ']');
		for i in 0..<info.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := cast(^byte)v.data + i*info.elem_size;
			fmt_arg(fi, any{info.elem, cast(rawptr)data}, 'v');
		}

	case Dynamic_Array:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_byte(fi.buf, '[');
		defer buffer_write_byte(fi.buf, ']');
		array := cast(^Raw_Dynamic_Array)v.data;
		for i in 0..<array.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := cast(^byte)array.data + i*info.elem_size;
			fmt_arg(fi, any{info.elem, cast(rawptr)data}, 'v');
		}

	case Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_string(fi.buf, "map[");
		defer buffer_write_byte(fi.buf, ']');
		entries := ^(cast(^Raw_Dynamic_Map)v.data).entries;
		gs := union_cast(^Struct)type_info_base(info.generated_struct);
		ed := union_cast(^Dynamic_Array)type_info_base(gs.types[1]);

		entry_type := union_cast(^Struct)ed.elem;
		entry_size := ed.elem_size;
		for i in 0..<entries.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := cast(^byte)entries.data + i*entry_size;

			header := cast(^__Map_Entry_Header)data;
			if types.is_string(info.key) {
				buffer_write_string(fi.buf, header.key.str);
			} else {
				fi := Fmt_Info{buf = fi.buf};
				fmt_arg(^fi, any{info.key, cast(rawptr)^header.key.hash}, 'v');
			}

			buffer_write_string(fi.buf, "=");

			value := data + entry_type.offsets[2];
			fmt_arg(fi, any{info.value, cast(rawptr)value}, 'v');
		}

	case Slice:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		buffer_write_byte(fi.buf, '[');
		defer buffer_write_byte(fi.buf, ']');
		slice := cast(^[]byte)v.data;
		for i in 0..<slice.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			data := slice.data + i*info.elem_size;
			fmt_arg(fi, any{info.elem, cast(rawptr)data}, 'v');
		}

	case Vector:
		buffer_write_byte(fi.buf, '<');
		defer buffer_write_byte(fi.buf, '>');

		for i in 0..<info.count {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}

			data := cast(^byte)v.data + i*info.elem_size;
			fmt_value(fi, any{info.elem, cast(rawptr)data}, 'v');
		}

	case Struct:
		buffer_write_byte(fi.buf, '{');
		defer buffer_write_byte(fi.buf, '}');

		for _, i in info.names {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			buffer_write_string(fi.buf, info.names[i]);
			buffer_write_string(fi.buf, " = ");
			data := cast(^byte)v.data + info.offsets[i];
			fmt_value(fi, any{info.types[i], cast(rawptr)data}, 'v');
		}

	case Union:
		buffer_write_byte(fi.buf, '{');
		defer buffer_write_byte(fi.buf, '}');

		cf := info.common_fields;

		for _, i in cf.names {
			if i > 0 {
				buffer_write_string(fi.buf, ", ");
			}
			buffer_write_string(fi.buf, cf.names[i]);
			buffer_write_string(fi.buf, " = ");
			data := cast(^byte)v.data + cf.offsets[i];
			fmt_value(fi, any{cf.types[i], cast(rawptr)data}, 'v');
		}

	case Raw_Union:
		buffer_write_string(fi.buf, "(raw_union)");

	case Enum:
		fmt_enum(fi, v, verb);

	case Procedure:
		buffer_write_type(fi.buf, v.type_info);
		buffer_write_string(fi.buf, " @ ");
		fmt_pointer(fi, (cast(^rawptr)v.data)^, 'p');
	}
}

fmt_arg :: proc(fi: ^Fmt_Info, arg: any, verb: rune) {
	if arg.data == nil || arg.type_info == nil {
		buffer_write_string(fi.buf, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := arg.type_info;
		match a in arg {
		case ^Type_Info: ti = a;
		}
		buffer_write_type(fi.buf, ti);
		return;
	}


	base_arg := arg;
	base_arg.type_info = type_info_base(base_arg.type_info);
	match a in base_arg {
	case bool:    fmt_bool(fi, a, verb);
	case f32:     fmt_float(fi, cast(f64)a, 32, verb);
	case f64:     fmt_float(fi, a, 64, verb);

	case int:     fmt_int(fi, cast(u64)a, true, verb);
	case i8:      fmt_int(fi, cast(u64)a, true, verb);
	case i16:     fmt_int(fi, cast(u64)a, true, verb);
	case i32:     fmt_int(fi, cast(u64)a, true, verb);
	case i64:     fmt_int(fi, cast(u64)a, true, verb);
	case uint:    fmt_int(fi, cast(u64)a, false, verb);
	case u8:      fmt_int(fi, cast(u64)a, false, verb);
	case u16:     fmt_int(fi, cast(u64)a, false, verb);
	case u32:     fmt_int(fi, cast(u64)a, false, verb);
	case u64:     fmt_int(fi, cast(u64)a, false, verb);
	case string:  fmt_string(fi, a, verb);
	default:      fmt_value(fi, arg, verb);
	}

}


bprintf :: proc(b: ^Buffer, fmt: string, args: ...any) -> int {
	fi := Fmt_Info{};
	end := fmt.count;
	arg_index := 0;
	was_prev_index := false;
	for i := 0; i < end;  {
		fi = Fmt_Info{buf = b, good_arg_index = true};

		prev_i := i;
		for i < end && fmt[i] != '%' {
			i += 1;
		}
		if i > prev_i {
			buffer_write_string(b, fmt[prev_i:i]);
		}
		if i >= end {
			break;
		}

		// Process a "verb"
		i += 1;


		for ; i < end; i += 1 {
			skip_loop := false;
			c := fmt[i];
			match c {
			case '+':
				fi.plus = true;
			case '-':
				fi.minus = true;
				fi.zero = false;
			case ' ':
				fi.space = true;
			case '#':
				fi.hash = true;
			case '0':
				fi.zero = !fi.minus;
			default:
				skip_loop = true;
			}

			if skip_loop {
				break;
			}
		}

		arg_index, i, was_prev_index = _arg_number(^fi, arg_index, fmt, i, args.count);

		// Width
		if i < end && fmt[i] == '*' {
			i += 1;
			fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index);
			if !fi.width_set {
				buffer_write_string(b, "%!(BAD WIDTH)");
			}

			if fi.width < 0 {
				fi.width = -fi.width;
				fi.minus = true;
				fi.zero  = false;
			}
			was_prev_index = false;
		} else {
			fi.width, i, fi.width_set = parse_int(fmt, i);
			if was_prev_index && fi.width_set { // %[6]2d
				fi.good_arg_index = false;
			}
		}

		// Precision
		if i < end && fmt[i] == '.' {
			i += 1;
			if was_prev_index { // %[6].2d
				fi.good_arg_index = false;
			}
			if i < end && fmt[i] == '*' {
				arg_index, i, was_prev_index = _arg_number(^fi, arg_index, fmt, i, args.count);
				i += 1;
				fi.prec, arg_index, fi.prec_set = int_from_arg(args, arg_index);
				if fi.prec < 0 {
					fi.prec = 0;
					fi.prec_set = false;
				}
				if !fi.prec_set {
					buffer_write_string(fi.buf, "%!(BAD PRECISION)");
				}
				was_prev_index = false;
			} else {
				fi.prec, i, fi.prec_set = parse_int(fmt, i);
				if !fi.prec_set {
					fi.prec_set = true;
					fi.prec = 0;
				}
			}
		}

		if !was_prev_index {
			arg_index, i, was_prev_index = _arg_number(^fi, arg_index, fmt, i, args.count);
		}

		if i >= end {
			buffer_write_string(b, "%!(NO VERB)");
			break;
		}

		verb, w := utf8.decode_rune(fmt[i:]);
		i += w;

		if verb == '%' {
			buffer_write_byte(b, '%');
		} else if !fi.good_arg_index {
			buffer_write_string(b, "%!(BAD ARGUMENT NUMBER)");
		} else if arg_index >= args.count {
			buffer_write_string(b, "%!(MISSING ARGUMENT)");
		} else {
			fmt_arg(^fi, args[arg_index], verb);
			arg_index += 1;
		}
	}

	if !fi.reordered && arg_index < args.count {
		buffer_write_string(b, "%!(EXTRA ");
		for arg, index in args[arg_index:] {
			if index > 0 {
				buffer_write_string(b, ", ");
			}
			if arg.data == nil || arg.type_info == nil {
				buffer_write_string(b, "<nil>");
			} else {
				fmt_arg(^fi, args[index], 'v');
			}
		}
		buffer_write_string(b, ")");
	}

	return b.length;
}
