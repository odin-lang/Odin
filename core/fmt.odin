import (
	"os.odin";
	"mem.odin";
	"utf8.odin";
	"types.odin";
	"strconv.odin";
	"raw.odin";
)

_BUFFER_SIZE :: 1<<12;

StringBuffer :: union {
	Static {buf: []u8},
	Dynamic{buf: [dynamic]u8},
}

FmtInfo :: struct {
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

	buf: ^StringBuffer,
	arg: any, // Temporary
}


make_string_buffer_from_slice :: proc(b: []u8) -> StringBuffer {
	return StringBuffer.Static{b};
}

make_string_dynamic_buffer :: proc() -> StringBuffer {
	return StringBuffer.Dynamic{make([dynamic]u8)};
}
string_buffer_data :: proc(buf: ^StringBuffer) -> []u8 {
	match b in buf {
	case StringBuffer.Static:
		return b.buf[..];
	case StringBuffer.Dynamic:
		return b.buf[..];
	}
	return nil;
}
string_buffer_data :: proc(buf: StringBuffer) -> []u8 {
	match b in buf {
	case StringBuffer.Static:
		return b.buf[..];
	case StringBuffer.Dynamic:
		return b.buf[..];
	}
	return nil;
}
to_string :: proc(buf: StringBuffer) -> string {
	return string(string_buffer_data(buf));
}


write_string :: proc(buf: ^StringBuffer, s: string) {
	write_bytes(buf, []u8(s));
}
write_bytes :: proc(buf: ^StringBuffer, data: []u8) {
	match b in buf {
	case StringBuffer.Static:
		append(&b.buf, ..data);
	case StringBuffer.Dynamic:
		append(&b.buf, ..data);
	}
}
write_byte :: proc(buf: ^StringBuffer, data: u8) {
	match b in buf {
	case StringBuffer.Static:
		append(&b.buf, data);
	case StringBuffer.Dynamic:
		append(&b.buf, data);
	}
}
write_rune :: proc(buf: ^StringBuffer, r: rune) {
	if r < utf8.RUNE_SELF {
		write_byte(buf, u8(r));
		return;
	}

	b, n := utf8.encode_rune(r);
	write_bytes(buf, b[0..<n]);
}

write_int :: proc(buf: ^StringBuffer, i: i128, base: int) {
	b: [129]u8;
	s := strconv.append_bits(b[0..<0], u128(i), base, true, 128, strconv.digits, 0);
	write_string(buf, s);
}
write_int :: proc(buf: ^StringBuffer, i: i64, base: int) {
	b: [129]u8;
	s := strconv.append_bits(b[0..<0], u128(i), base, true, 64, strconv.digits, 0);
	write_string(buf, s);
}



fprint :: proc(fd: os.Handle, args: ..any) -> int {
	data: [_BUFFER_SIZE]u8;
	buf := make_string_buffer_from_slice(data[0..<0]);
	sbprint(&buf, ..args);
	res := string_buffer_data(buf);
	os.write(fd, res);
	return len(res);
}

fprintln :: proc(fd: os.Handle, args: ..any) -> int {
	data: [_BUFFER_SIZE]u8;
	buf := make_string_buffer_from_slice(data[0..<0]);
	sbprintln(&buf, ..args);
	res := string_buffer_data(buf);
	os.write(fd, res);
	return len(res);
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	data: [_BUFFER_SIZE]u8;
	buf := make_string_buffer_from_slice(data[0..<0]);
	sbprintf(&buf, fmt, ..args);
	res := string_buffer_data(buf);
	os.write(fd, res);
	return len(res);
}


// print* procedures return the number of bytes written
print       :: proc(args: ..any)              -> int { return fprint(os.stdout, ..args); }
print_err   :: proc(args: ..any)              -> int { return fprint(os.stderr, ..args); }
println     :: proc(args: ..any)              -> int { return fprintln(os.stdout, ..args); }
println_err :: proc(args: ..any)              -> int { return fprintln(os.stderr, ..args); }
printf      :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stdout, fmt, ..args); }
printf_err  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stderr, fmt, ..args); }


// aprint* procedures return a string that was allocated with the current context
// They must be freed accordingly
aprint :: proc(args: ..any) -> string {
	buf := make_string_dynamic_buffer();
	sbprint(&buf, ..args);
	return to_string(buf);
}
aprintln :: proc(args: ..any) -> string {
	buf := make_string_dynamic_buffer();
	sbprintln(&buf, ..args);
	return to_string(buf);
}
aprintf :: proc(fmt: string, args: ..any) -> string {
	buf := make_string_dynamic_buffer();
	sbprintf(&buf, fmt, ..args);
	return to_string(buf);
}


// bprint* procedures return a string that was allocated with the current context
// They must be freed accordingly
bprint :: proc(buf: []u8, args: ..any) -> string {
	sb := make_string_buffer_from_slice(buf[0..<0..<len(buf)]);
	return sbprint(&sb, ..args);
}
bprintln :: proc(buf: []u8, args: ..any) -> string {
	sb := make_string_buffer_from_slice(buf[0..<0..<len(buf)]);
	return sbprintln(&sb, ..args);
}
bprintf :: proc(buf: []u8, fmt: string, args: ..any) -> string {
	sb := make_string_buffer_from_slice(buf[0..<0..<len(buf)]);
	return sbprintf(&sb, fmt, ..args);
}






fprint_type :: proc(fd: os.Handle, info: ^TypeInfo) {
	data: [_BUFFER_SIZE]u8;
	buf := make_string_buffer_from_slice(data[0..<0]);
	write_type(&buf, info);
	os.write(fd, string_buffer_data(buf));
}

write_type :: proc(buf: ^StringBuffer, ti: ^TypeInfo) {
	if ti == nil do return;

	using TypeInfo;
	match info in ti {
	case Named:
		write_string(buf, info.name);
	case Integer:
		match {
		case ti == type_info(int):  write_string(buf, "int");
		case ti == type_info(uint): write_string(buf, "uint");
		case:
			write_string(buf, info.signed ? "i" : "u");
			write_int(buf, i64(8*info.size), 10);
		}
	case Rune:
		write_string(buf, "rune");
	case Float:
		match info.size {
		case 2: write_string(buf, "f16");
		case 4: write_string(buf, "f32");
		case 8: write_string(buf, "f64");
		}
	case Complex:
		match info.size {
		case 4:  write_string(buf, "complex32");
		case 8:  write_string(buf, "complex64");
		case 16: write_string(buf, "complex128");
		}
	case String:  write_string(buf, "string");
	case Boolean: write_string(buf, "bool");
	case Any:
		write_string(buf, "any");
	case Atomic:
		write_string(buf, "atomic ");
		write_type(buf, info.elem);

	case Pointer:
		if info.elem == nil {
			write_string(buf, "rawptr");
		} else {
			write_string(buf, "^");
			write_type(buf, info.elem);
		}
	case Procedure:
		write_string(buf, "proc");
		if info.params == nil {
			write_string(buf, "()");
		} else {
			t := info.params.(^Tuple);
			write_string(buf, "(");
			for t, i in t.types {
				if i > 0 do write_string(buf, ", ");
				write_type(buf, t);
			}
			write_string(buf, ")");
		}
		if info.results != nil {
			write_string(buf, " -> ");
			write_type(buf, info.results);
		}
	case Tuple:
		count := len(info.names);
		if count != 1 do write_string(buf, "(");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");

			t := info.types[i];

			if len(name) > 0 {
				write_string(buf, name);
				write_string(buf, ": ");
			}
			write_type(buf, t);
		}
		if count != 1 do write_string(buf, ")");

	case Array:
		write_string(buf, "[");
		fi := FmtInfo{buf = buf};
		write_int(buf, i64(info.count), 10);
		write_string(buf, "]");
		write_type(buf, info.elem);
	case DynamicArray:
		write_string(buf, "[dynamic]");
		write_type(buf, info.elem);
	case Slice:
		write_string(buf, "[]");
		write_type(buf, info.elem);
	case Vector:
		write_string(buf, "[vector ");
		write_int(buf, i64(info.count), 10);
		write_string(buf, "]");
		write_type(buf, info.elem);

	case Map:
		write_string(buf, "map[");
		write_type(buf, info.key);
		write_byte(buf, ']');
		write_type(buf, info.value);

	case Struct:
		write_string(buf, "struct ");
		if info.packed  do write_string(buf, "#packed ");
		if info.ordered do write_string(buf, "#ordered ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_int(buf, i64(info.align), 10);
			write_byte(buf, ' ');
		}
		write_byte(buf, '{');
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_type(buf, info.types[i]);
		}
		write_byte(buf, '}');

	case Union:
		write_string(buf, "union {");
		cf := info.common_fields;
		total_count := 0;
		for name, i in cf.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_type(buf, cf.types[i]);
			total_count++;
		}
		for name, i in info.variant_names {
			if total_count > 0 || i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_byte(buf, '{');
			defer write_byte(buf, '}');

			variant_type := type_info_base(info.variant_types[i]);
			variant := variant_type.(^Struct);

			vc := len(variant.names)-len(cf.names);
			for j in 0..<vc {
				if j > 0 do write_string(buf, ", ");
				index := j + len(cf.names);
				write_string(buf, variant.names[index]);
				write_string(buf, ": ");
				write_type(buf, variant.types[index]);
			}
		}
		write_string(buf, "}");

	case RawUnion:
		write_string(buf, "raw_union {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_type(buf, info.types[i]);
		}
		write_string(buf, "}");

	case Enum:
		write_string(buf, "enum ");
		write_type(buf, info.base);
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
		}
		write_string(buf, "}");
	case BitField:
		write_string(buf, "bit_field ");
		if info.align != 1 {
			write_string(buf, "#align ");
			write_int(buf, i64(info.align), 10);
			write_rune(buf, ' ');
		}
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_int(buf, i64(info.bits[i]), 10);
		}
		write_string(buf, "}");

	}
}


_parse_int :: proc(s: string, offset: int) -> (result: int, offset: int, ok: bool) {
	is_digit :: proc(r: rune) -> bool #inline {
		return '0' <= r && r <= '9';
	}

	result := 0;
	ok := true;

	i := 0;
	for i < len(s[offset..]) {
		c := rune(s[offset+i]);
		if !is_digit(c) do break;
		i++;

		result *= 10;
		result += int(c)-'0';
	}

	return result, offset+i, i != 0;
}

_arg_number :: proc(fi: ^FmtInfo, arg_index: int, format: string, offset, arg_count: int) -> (index, offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if len(format) < 3 {
			return 0, 1, false;
		}

		for i in 1..len(format) {
			if format[i] == ']' {
				width, new_index, ok := _parse_int(format, 1);
				if !ok || new_index != i {
					return 0, i+1, false;
				}
				return width-1, i+1, true;
			}
		}

		return 0, 1, false;
	}


	if len(format) <= offset || format[offset] != '[' {
		return arg_index, offset, false;
	}
	fi.reordered = true;
	index, width, ok := parse_arg_number(format[offset..]);
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
	if arg_index < len(args) {
		arg := args[arg_index];
		arg.type_info = type_info_base(arg.type_info);
		match i in arg {
		case int:  num = i;
		case i8:   num = int(i);
		case i16:  num = int(i);
		case i32:  num = int(i);
		case i64:  num = int(i);
		case u8:   num = int(i);
		case u16:  num = int(i);
		case u32:  num = int(i);
		case u64:  num = int(i);
		case:
			ok = false;
		}
	}

	return num, new_arg_index, ok;
}


fmt_bad_verb :: proc(using fi: ^FmtInfo, verb: rune) {
	assert(verb != 'v');
	write_string(buf, "%!");
	write_rune(buf, verb);
	write_byte(buf, '(');
	if arg.type_info != nil {
		write_type(buf, arg.type_info);
		write_byte(buf, '=');
		fmt_value(fi, arg, 'v');
	} else {
		write_string(buf, "<nil>");
	}
	write_byte(buf, ')');
}

fmt_bool :: proc(using fi: ^FmtInfo, b: bool, verb: rune) {
	match verb {
	case 't', 'v':
		write_string(buf, b ? "true" : "false");
	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^FmtInfo, width: int) {
	if width <= 0 do return;

	pad_byte: u8 = fi.space ? ' ' : '0';

	for _ in 0..<width {
		write_byte(fi.buf, pad_byte);
	}
}

_fmt_int :: proc(fi: ^FmtInfo, u: u128, base: int, is_signed: bool, bit_size: int, digits: string) {
	_, neg := strconv.is_integer_negative(u128(u), is_signed, bit_size);

	BUF_SIZE :: 256;
	if fi.width_set || fi.prec_set {
		width := fi.width + fi.prec + 3; // 3 extra bytes for sign and prefix
		if width > BUF_SIZE {
			// TODO(bill):????
			panic("_fmt_int: buffer overrun. Width and precision too big");
		}
	}

	prec := 0;
	if fi.prec_set {
		prec = fi.prec;
		if prec == 0 && u == 0 {
			prev_zero := fi.zero;
			fi.zero = false;
			fmt_write_padding(fi, fi.width);
			fi.zero = prev_zero;
			return;
		}
	} else if fi.zero && fi.width_set {
		prec = fi.width;
		if neg || fi.plus || fi.space {
			// There needs to be space for the "sign"
			prec--;
		}
	}

	match base {
	case 2, 8, 10, 12, 16:
		break;
	case:
		panic("_fmt_int: unknown base, whoops");
	}

	buf: [256]u8;
	start := 0;

	flags: strconv.IntFlag;
	if fi.hash && !fi.zero do flags |= strconv.IntFlag.Prefix;
	if fi.plus             do flags |= strconv.IntFlag.Plus;
	if fi.space            do flags |= strconv.IntFlag.Space;
	s := strconv.append_bits(buf[start..<start], u128(u), base, is_signed, bit_size, digits, flags);

	if fi.hash && fi.zero {
		c: u8;
		match base {
		case 2:  c = 'b';
		case 8:  c = 'o';
		case 10: c = 'd';
		case 12: c = 'z';
		case 16: c = 'x';
		}
		if c != 0 {
			write_byte(fi.buf, '0');
			write_byte(fi.buf, c);
		}
	}

	prev_zero := fi.zero;
	defer fi.zero = prev_zero;
	fi.zero = false;
	_pad(fi, s);
}


__DIGITS_LOWER := "0123456789abcdefx";
__DIGITS_UPPER := "0123456789ABCDEFX";

fmt_rune :: proc(fi: ^FmtInfo, r: rune, verb: rune) {
	match verb {
	case 'c', 'r', 'v':
		write_rune(fi.buf, r);
	case:
		fmt_bad_verb(fi, verb);
	}
}

fmt_int :: proc(fi: ^FmtInfo, u: u128, is_signed: bool, bit_size: int, verb: rune) {
	match verb {
	case 'v': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
	case 'b': _fmt_int(fi, u,  2, is_signed, bit_size, __DIGITS_LOWER);
	case 'o': _fmt_int(fi, u,  8, is_signed, bit_size, __DIGITS_LOWER);
	case 'd': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
	case 'z': _fmt_int(fi, u, 12, is_signed, bit_size, __DIGITS_LOWER);
	case 'x': _fmt_int(fi, u, 16, is_signed, bit_size, __DIGITS_LOWER);
	case 'X': _fmt_int(fi, u, 16, is_signed, bit_size, __DIGITS_UPPER);
	case 'c', 'r':
		fmt_rune(fi, rune(u), verb);
	case 'U':
		r := rune(u);
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb);
		} else {
			write_string(fi.buf, "U+");
			_fmt_int(fi, u, 16, false, bit_size, __DIGITS_UPPER);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}

_pad :: proc(fi: ^FmtInfo, s: string) {
	if !fi.width_set {
		write_string(fi.buf, s);
		return;
	}


	width := fi.width - utf8.rune_count(s);
	if fi.minus { // right pad
		write_string(fi.buf, s);
		fmt_write_padding(fi, width);
	} else { // left pad
		fmt_write_padding(fi, width);
		write_string(fi.buf, s);
	}
}

fmt_float :: proc(fi: ^FmtInfo, v: f64, bit_size: int, verb: rune) {
	match verb {
	// case 'e', 'E', 'f', 'F', 'g', 'G', 'v':
	// case 'f', 'F', 'v':

	case 'f', 'F', 'v':
		prec: int = fi.prec_set ? fi.prec : 3;
		buf: [386]u8;

		str := strconv.append_float(buf[1..<1], v, 'f', prec, bit_size);
		str = string(buf[0..len(str)]);
		if str[1] == '+' || str[1] == '-' {
			str = str[1..];
		} else {
			str[0] = '+';
		}

		if fi.space && !fi.plus && str[0] == '+' {
			str[0] = ' ';
		}

		if len(str) > 1 && str[1] == 'N' && str[1] == 'I' {
			write_string(fi.buf, str);
			return;
		}

		if fi.plus || str[0] != '+' {
			if fi.zero && fi.width_set && fi.width > len(str) {
				write_byte(fi.buf, str[0]);
				fmt_write_padding(fi, fi.width - len(str));
				write_string(fi.buf, str[1..]);
			} else {
				_pad(fi, str);
			}
		} else {
			_pad(fi, str[1..]);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}
fmt_string :: proc(fi: ^FmtInfo, s: string, verb: rune) {
	match verb {
	case 's', 'v':
		write_string(fi.buf, s);

	case 'x', 'X':
		space := fi.space;
		fi.space = false;
		defer fi.space = space;

		for i in 0..<len(s) {
			if i > 0 && space do write_byte(fi.buf, ' ');
			_fmt_int(fi, u128(s[i]), 16, false, 8, verb == 'x' ? __DIGITS_LOWER : __DIGITS_UPPER);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}

fmt_pointer :: proc(fi: ^FmtInfo, p: rawptr, verb: rune) {
	match verb {
	case 'p', 'v':
		// Okay
	case:
		fmt_bad_verb(fi, verb);
		return;
	}
	u := u128(uint(p));
	if !fi.hash || verb == 'v' {
		write_string(fi.buf, "0x");
	}
	_fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);
}

fmt_enum :: proc(fi: ^FmtInfo, v: any, verb: rune) {
	if v.type_info == nil || v.data == nil {
		write_string(fi.buf, "<nil>");
		return;
	}

	using TypeInfo;
	match e in v.type_info {
	case:
		fmt_bad_verb(fi, verb);
		return;
	case Enum:
		match verb {
		case 'd', 'f':
			fmt_arg(fi, any{v.data, type_info_base(e.base)}, verb);
		case 's', 'v':
			i:  i128;
			f:  f64;
			ok: bool;
			a := any{v.data, type_info_base(e.base)};
			match v in a {
			case rune:  i = i128(v);
			case i8:   i = i128(v);
			case i16:  i = i128(v);
			case i32:  i = i128(v);
			case i64:  i = i128(v);
			case i128: i = i128(v);
			case int:  i = i128(v);
			case u8:   i = i128(v);
			case u16:  i = i128(v);
			case u32:  i = i128(v);
			case u64:  i = i128(v);
			case u128: i = i128(v);
			case uint: i = i128(v);

			case f32:  f = f64(v); i = i128(transmute(i64, f));
			case f64:  f = f64(v); i = i128(transmute(i64, f));
			}

			if types.is_string(e.base) {
				for val, idx in e.values {
					if val.i == i {
						write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			} else if len(e.values) == 0 {
				write_string(fi.buf, "");
				ok = true;
			} else {
				for val, idx in e.values {
					if val.i == i {
						write_string(fi.buf, e.names[idx]);
						ok = true;
						break;
					}
				}
			}

			if !ok {
				write_string(fi.buf, "!%(BAD ENUM VALUE)");
			}
		case:
			fmt_bad_verb(fi, verb);
			return;
		}
	}
}


fmt_value :: proc(fi: ^FmtInfo, v: any, verb: rune) {
	if v.data == nil || v.type_info == nil {
		write_string(fi.buf, "<nil>");
		return;
	}

	using TypeInfo;
	match info in v.type_info {
	case Named:
		match b in info.base {
		case Struct:
			if verb != 'v' {
				fmt_bad_verb(fi, verb);
				return;
			}
			write_string(fi.buf, info.name);
			write_byte(fi.buf, '{');
			for _, i in b.names {
				if i > 0 do write_string(fi.buf, ", ");
				write_string(fi.buf, b.names[i]);
				write_string(fi.buf, " = ");

				data := ^u8(v.data) + b.offsets[i];
				fmt_arg(fi, any{rawptr(data), b.types[i]}, 'v');
			}
			write_byte(fi.buf, '}');

		case:
			fmt_value(fi, any{v.data, info.base}, verb);
		}

	case Boolean:    fmt_arg(fi, v, verb);
	case Integer:    fmt_arg(fi, v, verb);
	case Rune:       fmt_arg(fi, v, verb);
	case Float:      fmt_arg(fi, v, verb);
	case Complex:    fmt_arg(fi, v, verb);
	case String:     fmt_arg(fi, v, verb);

	case Pointer:
		if v.type_info == type_info(^TypeInfo) {
			write_type(fi.buf, ^^TypeInfo(v.data)^);
		} else {
			fmt_pointer(fi, ^rawptr(v.data)^, verb);
		}

	case Atomic:
		fmt_arg(fi, any{v.data, info.elem}, verb);

	case Array:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		for i in 0..<info.count {
			if i > 0 do write_string(fi.buf, ", ");

			data := ^u8(v.data) + i*info.elem_size;
			fmt_arg(fi, any{rawptr(data), info.elem}, verb);
		}

	case DynamicArray:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		array := ^raw.DynamicArray(v.data);
		for i in 0..<array.len {
			if i > 0 do write_string(fi.buf, ", ");

			data := ^u8(array.data) + i*info.elem_size;
			fmt_arg(fi, any{rawptr(data), info.elem}, verb);
		}

	case Slice:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		slice := ^[]u8(v.data);
		for _, i in slice {
			if i > 0 do write_string(fi.buf, ", ");

			data := &slice[0] + i*info.elem_size;
			fmt_arg(fi, any{rawptr(data), info.elem}, verb);
		}

	case Vector:
		write_byte(fi.buf, '<');
		defer write_byte(fi.buf, '>');

		for i in 0..<info.count {
			if i > 0 do write_string(fi.buf, ", ");

			data := ^u8(v.data) + i*info.elem_size;
			fmt_value(fi, any{rawptr(data), info.elem}, verb);
		}

	case Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		write_string(fi.buf, "map[");
		defer write_byte(fi.buf, ']');

		entries    := &(^raw.DynamicMap(v.data).entries);
		gs         := type_info_base(info.generated_struct).(^Struct);
		ed         := type_info_base(gs.types[1]).(^DynamicArray);
		entry_type := ed.elem.(^Struct);
		entry_size := ed.elem_size;

		for i in 0..<entries.len {
			if i > 0 do write_string(fi.buf, ", ");

			data := ^u8(entries.data) + i*entry_size;
			header := ^__MapEntryHeader(data);

			if types.is_string(info.key) {
				write_string(fi.buf, header.key.str);
			} else {
				fi := FmtInfo{buf = fi.buf};
				fmt_arg(&fi, any{rawptr(&header.key.hash), info.key}, 'v');
			}

			write_string(fi.buf, "=");

			value := data + entry_type.offsets[2];
			fmt_arg(fi, any{rawptr(value), info.value}, 'v');
		}



	case Struct:
		write_byte(fi.buf, '{');
		defer write_byte(fi.buf, '}');

		for _, i in info.names {
			if i > 0 do write_string(fi.buf, ", ");

			write_string(fi.buf, info.names[i]);
			write_string(fi.buf, " = ");
			data := ^u8(v.data) + info.offsets[i];
			fmt_value(fi, any{rawptr(data), info.types[i]}, 'v');
		}

	case Union:
		write_byte(fi.buf, '{');
		defer write_byte(fi.buf, '}');

		cf := info.common_fields;
		for _, i in cf.names {
			if i > 0 do write_string(fi.buf, ", ");

			write_string(fi.buf, cf.names[i]);
			write_string(fi.buf, " = ");
			data := ^u8(v.data) + cf.offsets[i];
			fmt_value(fi, any{rawptr(data), cf.types[i]}, 'v');
		}

	case RawUnion:
		write_string(fi.buf, "(raw_union)");

	case Enum:
		fmt_enum(fi, v, verb);

	case Procedure:
		write_type(fi.buf, v.type_info);
		write_string(fi.buf, " @ ");
		fmt_pointer(fi, ^rawptr(v.data)^, 'p');
	}
}

fmt_complex :: proc(fi: ^FmtInfo, c: complex128, bits: int, verb: rune) {
	match verb {
	case 'f', 'F', 'v':
		r, i := real(c), imag(c);
		fmt_float(fi, r, bits/2, verb);
		if !fi.plus && i >= 0 {
			write_rune(fi.buf, '+');
		}
		fmt_float(fi, i, bits/2, verb);
		write_rune(fi.buf, 'i');

	case:
		fmt_bad_verb(fi, verb);
		return;
	}
}

_u128_to_lo_hi :: proc(a: u128) -> (lo, hi: u64) { return u64(a), u64(a>>64); }
_i128_to_lo_hi :: proc(a: u128) -> (lo: u64 hi: i64) { return u64(a), i64(a>>64); }


do_foo :: proc(fi: ^FmtInfo, f: f64) {
	fmt_string(fi, "Hellope$%!", 'v');
}

fmt_arg :: proc(fi: ^FmtInfo, arg: any, verb: rune) {
	if arg == nil {
		write_string(fi.buf, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := arg.type_info;
		match a in arg {
		case ^TypeInfo: ti = a;
		}
		write_type(fi.buf, ti);
		return;
	}


	base_arg := arg;
	base_arg.type_info = type_info_base(base_arg.type_info);
	match a in base_arg {
	case any:           fmt_arg(fi,  a, verb);
	case bool:          fmt_bool(fi, a, verb);
	case rune:          fmt_rune(fi, a, verb);

	case f32:           fmt_float(fi, f64(a), 32, verb);
	case f64:           fmt_float(fi, a,      64, verb);

	case complex64:     fmt_complex(fi, complex128(a), 64, verb);
	case complex128:    fmt_complex(fi, a, 128, verb);

	case int:     fmt_int(fi, u128(a), true,  8*size_of(int), verb);
	case i8:      fmt_int(fi, u128(a), true,  8, verb);
	case i16:     fmt_int(fi, u128(a), true,  16, verb);
	case i32:     fmt_int(fi, u128(a), true,  32, verb);
	case i64:     fmt_int(fi, u128(a), true,  64, verb);
	case i128:    fmt_int(fi, u128(a), true, 128, verb);

	case uint:    fmt_int(fi, u128(a), false, 8*size_of(uint), verb);
	case u8:      fmt_int(fi, u128(a), false, 8, verb);
	case u16:     fmt_int(fi, u128(a), false, 16, verb);
	case u32:     fmt_int(fi, u128(a), false, 32, verb);
	case u64:     fmt_int(fi, u128(a), false, 64, verb);
	case u128:    fmt_int(fi, u128(a), false, 128, verb);


	case string:  fmt_string(fi, a, verb);


	case:         fmt_value(fi, arg, verb);
	}

}



sbprint :: proc(buf: ^StringBuffer, args: ..any) -> string {
	fi: FmtInfo;
	prev_string := false;

	fi.buf = buf;

	for arg, i in args {
		is_string := arg != nil && types.is_string(arg.type_info);
		if i > 0 && !is_string && !prev_string {
			write_byte(buf, ' ');
		}
		fmt_value(&fi, args[i], 'v');
		prev_string = is_string;
	}
	return to_string(buf^);
}

sbprintln :: proc(buf: ^StringBuffer, args: ..any) -> string {
	fi: FmtInfo;
	fi.buf = buf;

	for arg, i in args {
		if i > 0 do write_byte(buf, ' ');

		fmt_value(&fi, args[i], 'v');
	}
	write_byte(buf, '\n');
	return to_string(buf^);
}

sbprintf :: proc(b: ^StringBuffer, fmt: string, args: ..any) -> string {
	fi: FmtInfo;
	arg_index: int = 0;
	end := len(fmt);
	was_prev_index := false;


	for i := 0; i < end; /**/ {
		fi = FmtInfo{buf = b, good_arg_index = true};

		prev_i := i;
		for i < end && fmt[i] != '%' {
			i++;
		}
		if i > prev_i {
			write_string(b, fmt[prev_i..<i]);
		}
		if i >= end {
			break;
		}

		// Process a "verb"
		i++;

		prefix_loop: for ; i < end; i++ {
			match fmt[i] {
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
			case:
				break prefix_loop;
			}
		}

		arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));

		// Width
		if i < end && fmt[i] == '*' {
			i++;
			fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index);
			if !fi.width_set {
				write_string(b, "%!(BAD WIDTH)");
			}

			if fi.width < 0 {
				fi.width = -fi.width;
				fi.minus = true;
				fi.zero  = false;
			}
			was_prev_index = false;
		} else {
			fi.width, i, fi.width_set = _parse_int(fmt, i);
			if was_prev_index && fi.width_set { // %[6]2d
				fi.good_arg_index = false;
			}
		}

		// Precision
		if i < end && fmt[i] == '.' {
			i++;
			if was_prev_index { // %[6].2d
				fi.good_arg_index = false;
			}
			if i < end && fmt[i] == '*' {
				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));
				i++;
				fi.prec, arg_index, fi.prec_set = int_from_arg(args, arg_index);
				if fi.prec < 0 {
					fi.prec = 0;
					fi.prec_set = false;
				}
				if !fi.prec_set {
					write_string(fi.buf, "%!(BAD PRECISION)");
				}
				was_prev_index = false;
			} else {
				fi.prec, i, fi.prec_set = _parse_int(fmt, i);
				if !fi.prec_set {
					// fi.prec_set = true;
					// fi.prec = 0;
				}
			}
		}

		if !was_prev_index {
			arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));
		}

		if i >= end {
			write_string(b, "%!(NO VERB)");
			break;
		}

		verb, w := utf8.decode_rune(fmt[i..]);
		i += w;

		if verb == '%' {
			write_byte(b, '%');
		} else if !fi.good_arg_index {
			write_string(b, "%!(BAD ARGUMENT NUMBER)");
		} else if arg_index >= len(args) {
			write_string(b, "%!(MISSING ARGUMENT)");
		} else {
			fmt_arg(&fi, args[arg_index], verb);
			arg_index++;
		}
	}

	if !fi.reordered && arg_index < len(args) {
		write_string(b, "%!(EXTRA ");
		for arg, index in args[arg_index..] {
			if index > 0 do write_string(b, ", ");

			if arg == nil do write_string(b, "<nil>");
			else          do fmt_arg(&fi, args[index], 'v');
		}
		write_string(b, ")");
	}

	return to_string(b^);
}
