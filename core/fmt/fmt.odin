package fmt

import "core:runtime"
import "core:os"
import "core:mem"
import "core:unicode/utf8"
import "core:types"
import "core:strconv"


@(private)
DEFAULT_BUFFER_SIZE :: 1<<12;

String_Buffer :: distinct [dynamic]byte;

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
	indent:    int,

	reordered:      bool,
	good_arg_index: bool,

	buf: ^String_Buffer,
	arg: any, // Temporary
}

string_buffer_from_slice :: proc(backing: []byte) -> String_Buffer {
	s := transmute(mem.Raw_Slice)backing;
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = mem.nil_allocator(),
	};
	return transmute(String_Buffer)d;
}


to_string :: proc(buf: String_Buffer) -> string {
	return string(buf[:]);
}


write_string :: proc(buf: ^String_Buffer, s: string) {
	append_string(buf, s);
}
write_bytes :: proc(buf: ^String_Buffer, data: []byte) {
	append(buf, ..data);
}
write_byte :: proc(buf: ^String_Buffer, data: byte) {
	append(buf, data);
}
write_rune :: proc(buf: ^String_Buffer, r: rune) {
	if r < utf8.RUNE_SELF {
		write_byte(buf, byte(r));
		return;
	}

	b, n := utf8.encode_rune(r);
	write_bytes(buf, b[:n]);
}
write_encoded_rune :: proc(buf: ^String_Buffer, r: rune) {
	write_byte(buf, '\'');
	switch r {
	case '\a': write_string(buf, "\\a");
	case '\b': write_string(buf, "\\b");
	case '\e': write_string(buf, "\\e");
	case '\f': write_string(buf, "\\f");
	case '\n': write_string(buf, "\\n");
	case '\r': write_string(buf, "\\r");
	case '\t': write_string(buf, "\\t");
	case '\v': write_string(buf, "\\v");
	case:
		if r < 32 {
			write_string(buf, "\\x");
			b: [2]byte;
			s := strconv.append_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil);
			switch len(s) {
			case 0: write_string(buf, "00");
			case 1: write_rune(buf, '0');
			case 2: write_string(buf, s);
			}
		} else {
			write_rune(buf, r);
		}

	}
	write_byte(buf, '\'');
}

write_u64 :: proc(buf: ^String_Buffer, i: u64, base: int) {
	b: [129]byte;
	s := strconv.append_bits(b[:], u64(i), base, false, 64, strconv.digits, nil);
	write_string(buf, s);
}
write_i64 :: proc(buf: ^String_Buffer, i: i64, base: int) {
	b: [129]byte;
	s := strconv.append_bits(b[:], u64(i), base, true, 64, strconv.digits, nil);
	write_string(buf, s);
}

fprint :: proc(fd: os.Handle, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := string_buffer_from_slice(data[:]);
	res := sbprint(&buf, ..args);
	os.write_string(fd, res);
	return len(res);
}

fprintln :: proc(fd: os.Handle, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := string_buffer_from_slice(data[:]);
	res := sbprintln(&buf, ..args);
	os.write_string(fd, res);
	return len(res);
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := string_buffer_from_slice(data[:]);
	res := sbprintf(&buf, fmt, ..args);
	os.write_string(fd, res);
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
	buf := String_Buffer(make([dynamic]byte));
	sbprint(&buf, ..args);
	return to_string(buf);
}
aprintln :: proc(args: ..any) -> string {
	buf := String_Buffer(make([dynamic]byte));
	sbprintln(&buf, ..args);
	return to_string(buf);
}
aprintf :: proc(fmt: string, args: ..any) -> string {
	buf := String_Buffer(make([dynamic]byte));
	sbprintf(&buf, fmt, ..args);
	return to_string(buf);
}


// tprint* procedures return a string that was allocated with the current context's temporary allocator
tprint :: proc(args: ..any) -> string {
	buf := String_Buffer(make([dynamic]byte, context.temp_allocator));
	sbprint(&buf, ..args);
	return to_string(buf);
}
tprintln :: proc(args: ..any) -> string {
	buf := String_Buffer(make([dynamic]byte, context.temp_allocator));
	sbprintln(&buf, ..args);
	return to_string(buf);
}
tprintf :: proc(fmt: string, args: ..any) -> string {
	buf := String_Buffer(make([dynamic]byte, context.temp_allocator));
	sbprintf(&buf, fmt, ..args);
	return to_string(buf);
}


// bprint* procedures return a string using a buffer from an array
bprint :: proc(buf: []byte, args: ..any) -> string {
	sb := string_buffer_from_slice(buf[0:len(buf)]);
	return sbprint(&sb, ..args);
}
bprintln :: proc(buf: []byte, args: ..any) -> string {
	sb := string_buffer_from_slice(buf[0:len(buf)]);
	return sbprintln(&sb, ..args);
}
bprintf :: proc(buf: []byte, fmt: string, args: ..any) -> string {
	sb := string_buffer_from_slice(buf[0:len(buf)]);
	return sbprintf(&sb, fmt, ..args);
}


assertf :: proc "contextless" (condition: bool, fmt: string, args: ..any, loc := #caller_location) -> bool {
	if !condition {
		p := context.assertion_failure_proc;
		if p == nil {
			p = runtime.default_assertion_failure_proc;
		}
		message := tprintf(fmt, ..args);
		p("Runtime assertion", message, loc);
	}
	return condition;
}

panicf :: proc "contextless" (fmt: string, args: ..any, loc := #caller_location) {
	p := context.assertion_failure_proc;
	if p == nil {
		p = runtime.default_assertion_failure_proc;
	}
	message := tprintf(fmt, ..args);
	p("Panic", message, loc);
}





fprint_type :: proc(fd: os.Handle, info: ^runtime.Type_Info) {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := string_buffer_from_slice(data[:]);
	write_type(&buf, info);
	os.write(fd, buf[:]);
}

write_typeid :: proc(buf: ^String_Buffer, id: typeid) {
	write_type(buf, type_info_of(id));
}

write_type :: proc(buf: ^String_Buffer, ti: ^runtime.Type_Info) {
	if ti == nil {
		write_string(buf, "nil");
		return;
	}

	switch info in ti.variant {
	case runtime.Type_Info_Named:
		write_string(buf, info.name);
	case runtime.Type_Info_Integer:
		a := any{id = ti.id};
		switch in a {
		case int:     write_string(buf, "int");
		case uint:    write_string(buf, "uint");
		case uintptr: write_string(buf, "uintptr");
		case:
			write_byte(buf, info.signed ? 'i' : 'u');
			write_i64(buf, i64(8*ti.size), 10);
		}
	case runtime.Type_Info_Rune:
		write_string(buf, "rune");
	case runtime.Type_Info_Float:
		write_byte(buf, 'f');
		write_i64(buf, i64(8*ti.size), 10);
	case runtime.Type_Info_Complex:
		write_string(buf, "complex");
		write_i64(buf, i64(8*ti.size), 10);
	case runtime.Type_Info_String:
		if info.is_cstring {
			write_string(buf, "cstring");
		} else {
			write_string(buf, "string");
		}
	case runtime.Type_Info_Boolean:
		a := any{id = ti.id};
		switch in a {
		case bool: write_string(buf, "bool");
		case:
			write_byte(buf, 'b');
			write_i64(buf, i64(8*ti.size), 10);
		}
	case runtime.Type_Info_Any:
		write_string(buf, "any");

	case runtime.Type_Info_Type_Id:
		write_string(buf, "typeid");

	case runtime.Type_Info_Pointer:
		if info.elem == nil {
			write_string(buf, "rawptr");
		} else {
			write_string(buf, "^");
			write_type(buf, info.elem);
		}
	case runtime.Type_Info_Procedure:
		write_string(buf, "proc");
		if info.params == nil {
			write_string(buf, "()");
		} else {
			t := info.params.variant.(runtime.Type_Info_Tuple);
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
	case runtime.Type_Info_Tuple:
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

	case runtime.Type_Info_Array:
		write_string(buf, "[");
		write_i64(buf, i64(info.count), 10);
		write_string(buf, "]");
		write_type(buf, info.elem);
	case runtime.Type_Info_Dynamic_Array:
		write_string(buf, "[dynamic]");
		write_type(buf, info.elem);
	case runtime.Type_Info_Slice:
		write_string(buf, "[]");
		write_type(buf, info.elem);

	case runtime.Type_Info_Map:
		write_string(buf, "map[");
		write_type(buf, info.key);
		write_byte(buf, ']');
		write_type(buf, info.value);

	case runtime.Type_Info_Struct:
		write_string(buf, "struct ");
		if info.is_packed    do write_string(buf, "#packed ");
		if info.is_raw_union do write_string(buf, "#raw_union ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
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

	case runtime.Type_Info_Union:
		write_string(buf, "union {");
		for variant, i in info.variants {
			if i > 0 do write_string(buf, ", ");
			write_type(buf, variant);
		}
		write_string(buf, "}");

	case runtime.Type_Info_Enum:
		write_string(buf, "enum ");
		write_type(buf, info.base);
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
		}
		write_string(buf, "}");

	case runtime.Type_Info_Bit_Field:
		write_string(buf, "bit_field ");
		if ti.align != 1 {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_rune(buf, ' ');
		}
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_i64(buf, i64(info.bits[i]), 10);
		}
		write_string(buf, "}");

	case runtime.Type_Info_Bit_Set:
		write_string(buf, "bit_set[");
		switch {
		case types.is_enum(info.elem):
			write_type(buf, info.elem);
		case types.is_rune(info.elem):
			write_encoded_rune(buf, rune(info.lower));
			write_string(buf, "..");
			write_encoded_rune(buf, rune(info.upper));
		case:
			write_i64(buf, info.lower, 10);
			write_string(buf, "..");
			write_i64(buf, info.upper, 10);
		}
		if info.underlying != nil {
			write_string(buf, "; ");
			write_type(buf, info.underlying);
		}
		write_byte(buf, ']');
	}
}


_parse_int :: proc(s: string, offset: int) -> (result: int, new_offset: int, ok: bool) {
	is_digit :: inline proc(r: byte) -> bool { return '0' <= r && r <= '9' }

	new_offset = offset;
	for new_offset <= len(s) {
		c := s[new_offset];
		if !is_digit(c) do break;
		new_offset += 1;

		result *= 10;
		result += int(c)-'0';
	}
	ok = new_offset > offset;
	return;
}

_arg_number :: proc(fi: ^Fmt_Info, arg_index: int, format: string, offset, arg_count: int) -> (index, new_offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if len(format) < 3 do return 0, 1, false;

		for i in 1..len(format)-1 {
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

	width: int;
	index, width, ok = parse_arg_number(format[offset:]);
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
		arg.id = runtime.typeid_base(arg.id);
		switch i in arg {
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


fmt_bad_verb :: proc(using fi: ^Fmt_Info, verb: rune) {
	write_string(buf, "%!");
	write_rune(buf, verb);
	write_byte(buf, '(');
	if arg.id != nil {
		write_typeid(buf, arg.id);
		write_byte(buf, '=');
		fmt_value(fi, arg, 'v');
	} else {
		write_string(buf, "<nil>");
	}
	write_byte(buf, ')');
}

fmt_bool :: proc(using fi: ^Fmt_Info, b: bool, verb: rune) {
	switch verb {
	case 't', 'v':
		write_string(buf, b ? "true" : "false");
	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^Fmt_Info, width: int) {
	if width <= 0 do return;

	pad_byte: byte = '0';
	if fi.space do pad_byte = ' ';

	for _ in 0..width-1 {
		write_byte(fi.buf, pad_byte);
	}
}

_fmt_int :: proc(fi: ^Fmt_Info, u: u64, base: int, is_signed: bool, bit_size: int, digits: string) {
	_, neg := strconv.is_integer_negative(u, is_signed, bit_size);

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
			prec -= 1;
		}
	}

	switch base {
	case 2, 8, 10, 12, 16:
		break;
	case:
		panic("_fmt_int: unknown base, whoops");
	}

	buf: [256]byte;
	start := 0;

	using strconv.Int_Flag;
	flags: strconv.Int_Flags;
	if fi.hash && !fi.zero do flags |= {Prefix};
	if fi.plus             do flags |= {Plus};
	if fi.space            do flags |= {Space};
	s := strconv.append_bits(buf[start:], u, base, is_signed, bit_size, digits, flags);

	if fi.hash && fi.zero {
		c: byte = 0;
		switch base {
		case 2:  c = 'b';
		case 8:  c = 'o';
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

fmt_rune :: proc(fi: ^Fmt_Info, r: rune, verb: rune) {
	switch verb {
	case 'c', 'r', 'v':
		write_rune(fi.buf, r);
	case:
		fmt_int(fi, u64(r), false, 32, verb);
	}
}

fmt_int :: proc(fi: ^Fmt_Info, u: u64, is_signed: bool, bit_size: int, verb: rune) {
	switch verb {
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

_pad :: proc(fi: ^Fmt_Info, s: string) {
	if !fi.width_set {
		write_string(fi.buf, s);
		return;
	}


	width := fi.width - utf8.rune_count_from_string(s);
	if fi.minus { // right pad
		write_string(fi.buf, s);
		fmt_write_padding(fi, width);
	} else { // left pad
		fmt_write_padding(fi, width);
		write_string(fi.buf, s);
	}
}

fmt_float :: proc(fi: ^Fmt_Info, v: f64, bit_size: int, verb: rune) {
	switch verb {
	// case 'e', 'E', 'f', 'F', 'g', 'G', 'v':
	// case 'f', 'F', 'v':

	case 'f', 'F', 'v':
		prec: int = 3;
		if fi.prec_set do prec = fi.prec;
		buf: [386]byte;

		str := strconv.append_float(buf[1:], v, 'f', prec, bit_size);
		str = string(buf[:len(str)+1]);
		if str[1] == '+' || str[1] == '-' {
			str = str[1:];
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
				write_string(fi.buf, str[1:]);
			} else {
				_pad(fi, str);
			}
		} else {
			_pad(fi, str[1:]);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}
fmt_string :: proc(fi: ^Fmt_Info, s: string, verb: rune) {
	switch verb {
	case 's', 'v':
		write_string(fi.buf, s);

	case 'x', 'X':
		space := fi.space;
		fi.space = false;
		defer fi.space = space;

		for i in 0..len(s)-1 {
			if i > 0 && space do write_byte(fi.buf, ' ');
			char_set := __DIGITS_UPPER;
			if verb == 'x' do char_set = __DIGITS_LOWER;
			_fmt_int(fi, u64(s[i]), 16, false, 8, char_set);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}
fmt_cstring :: proc(fi: ^Fmt_Info, s: cstring, verb: rune) {
	fmt_string(fi, string(s), verb);
}

fmt_pointer :: proc(fi: ^Fmt_Info, p: rawptr, verb: rune) {
	switch verb {
	case 'p', 'v':
		u := u64(uintptr(p));
		if !fi.hash || verb == 'v' {
			write_string(fi.buf, "0x");
		}
		_fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case:
		fmt_bad_verb(fi, verb);
	}
}

enum_value_to_string :: proc(v: any) -> (string, bool) {
	v.id = runtime.typeid_base(v.id);
	type_info := type_info_of(v.id);

	switch e in type_info.variant {
	case: return "", false;
	case runtime.Type_Info_Enum:
		get_str :: proc(i: $T, e: runtime.Type_Info_Enum) -> (string, bool) {
			if types.is_string(e.base) {
				for val, idx in e.values {
					if v, ok := val.(T); ok && v == i {
						return e.names[idx], true;
					}
				}
			} else if len(e.values) == 0 {
				return "", true;
			} else {
				for val, idx in e.values {
					if v, ok := val.(T); ok && v == i {
						return e.names[idx], true;
					}
				}
			}
			return "", false;
		}

		a := any{v.data, runtime.type_info_base(e.base).id};
		switch v in a {
		case rune:    return get_str(v, e);
		case i8:      return get_str(v, e);
		case i16:     return get_str(v, e);
		case i32:     return get_str(v, e);
		case i64:     return get_str(v, e);
		case int:     return get_str(v, e);
		case u8:      return get_str(v, e);
		case u16:     return get_str(v, e);
		case u32:     return get_str(v, e);
		case u64:     return get_str(v, e);
		case uint:    return get_str(v, e);
		case uintptr: return get_str(v, e);
		}
	}

	return "", false;
}

string_to_enum_value :: proc($T: typeid, s: string) -> (T, bool) {
	ti := type_info_base(type_info_of(T));
	if e, ok := ti.variant.(Type_Info_Enum); ok {
		for str, idx in e.names {
			if s == str {
				// NOTE(bill): Unsafe cast
				ptr := cast(^T)&e.values[idx];
				return ptr^, true;
			}
		}
	}
	return T{}, false;
}

fmt_enum :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.id == nil || v.data == nil {
		write_string(fi.buf, "<nil>");
		return;
	}

	type_info := type_info_of(v.id);
	switch e in type_info.variant {
	case: fmt_bad_verb(fi, verb);
	case runtime.Type_Info_Enum:
		switch verb {
		case: fmt_bad_verb(fi, verb);
		case 'd', 'f':
			fmt_arg(fi, any{v.data, runtime.type_info_base(e.base).id}, verb);
		case 's', 'v':
			str, ok := enum_value_to_string(v);
			if !ok do str = "!%(BAD ENUM VALUE)";
			write_string(fi.buf, str);
		}
	}
}



enum_value_to_u64 :: proc(ev: runtime.Type_Info_Enum_Value) -> u64 {
	switch i in ev {
	case rune:    return u64(i);
	case i8:      return u64(i);
	case i16:     return u64(i);
	case i32:     return u64(i);
	case i64:     return u64(i);
	case int:     return u64(i);
	case u8:      return u64(i);
	case u16:     return u64(i);
	case u32:     return u64(i);
	case u64:     return u64(i);
	case uint:    return u64(i);
	case uintptr: return u64(i);
	}
	return 0;
}

fmt_bit_set :: proc(fi: ^Fmt_Info, v: any, name: string = "") {
	type_info := type_info_of(v.id);
	switch info in type_info.variant {
	case runtime.Type_Info_Named:
		val := v;
		val.id = info.base.id;
		fmt_bit_set(fi, val, info.name);

	case runtime.Type_Info_Bit_Set:
		bits: u64;
		bit_size := u64(8*type_info.size);
		verb := 'b';

		switch bit_size {
		case  0: bits = 0;
		case  8: bits = u64( (^u8)(v.data)^);
		case 16: bits = u64((^u16)(v.data)^);
		case 32: bits = u64((^u32)(v.data)^);
		case 64: bits = u64((^u64)(v.data)^);
		case: panic("unknown bit_size size");
		}

		et := runtime.type_info_base(info.elem);

		if name != "" {
			write_string(fi.buf, name);
		} else {
			write_type(fi.buf, type_info);
		}
		write_byte(fi.buf, '{');
		defer write_byte(fi.buf, '}');

		e, is_enum := et.variant.(runtime.Type_Info_Enum);
		commas := 0;
		loop: for i in 0 .. bit_size-1 {
			if bits & (1<<i) == 0 {
				continue loop;
			}

			if commas > 0 do write_string(fi.buf, ", ");

			defer commas += 1;

			if is_enum do for ev, evi in e.values {
				v := enum_value_to_u64(ev);
				if v == i {
					write_string(fi.buf, e.names[evi]);
					continue loop;
				}
			}
			write_i64(fi.buf, i64(i), 10);
		}
	}
}
fmt_bit_field :: proc(fi: ^Fmt_Info, v: any, name: string = "") {
	type_info := type_info_of(v.id);
	switch info in type_info.variant {
	case runtime.Type_Info_Named:
		val := v;
		val.id = info.base.id;
		fmt_bit_field(fi, val, info.name);
	case runtime.Type_Info_Bit_Field:
		data: u64 = 0;
		switch type_info.size {
		case 1: data = cast(u64) (^u8)(v.data)^;
		case 2: data = cast(u64)(^u16)(v.data)^;
		case 4: data = cast(u64)(^u32)(v.data)^;
		case 8: data = cast(u64)(^u64)(v.data)^;
		}

		if name != "" {
			write_string(fi.buf, name);
			write_byte(fi.buf, '{');
		} else {
			write_string(fi.buf, "bit_field{");
		}
		for name, i in info.names {
			if i > 0 {
				write_string(fi.buf, ", ");
			}
			bits := u64(info.bits[i]);
			offset := u64(info.offsets[i]);
			write_string(fi.buf, name);
			write_string(fi.buf, " = ");

			n := 8*u64(size_of(u64));
			sa := n - bits;
			u := data>>offset;
			u <<= sa;
			u >>= sa;

			write_u64(fi.buf, u, 10);

		}
		write_byte(fi.buf, '}');
	case:
		write_string(fi.buf, "HERE");
	}
}

fmt_value :: proc(fi: ^Fmt_Info, v: any, verb: rune) {
	if v.data == nil || v.id == nil {
		write_string(fi.buf, "<nil>");
		return;
	}

	type_info := type_info_of(v.id);
	switch info in type_info.variant {
	case runtime.Type_Info_Named:
		switch b in info.base.variant {
		case runtime.Type_Info_Struct:
			if verb != 'v' {
				fmt_bad_verb(fi, verb);
				return;
			}
			if b.is_raw_union {
				write_string(fi.buf, info.name);
				write_string(fi.buf, "{}");
				return;
			};
			write_string(fi.buf, info.name);
			write_byte(fi.buf, '{');

			hash   := fi.hash;   defer fi.hash = hash;
			indent := fi.indent; defer fi.indent -= 1;

			fi.hash = false;
			fi.indent += 1;

			if hash	do write_byte(fi.buf, '\n');

			for _, i in b.names {
				if !hash && i > 0 do write_string(fi.buf, ", ");
				if hash do for in 0..fi.indent-1 do write_byte(fi.buf, '\t');

				write_string(fi.buf, b.names[i]);
				write_string(fi.buf, " = ");

				if t := b.types[i]; types.is_any(t) {
					write_string(fi.buf, "any{}");
				} else {
					data := rawptr(uintptr(v.data) + b.offsets[i]);
					fmt_arg(fi, any{data, t.id}, 'v');
				}

				if hash do write_string(fi.buf, ",\n");
			}

			if hash do for in 0..indent-1 do write_byte(fi.buf, '\t');
			write_byte(fi.buf, '}');

		case runtime.Type_Info_Bit_Set:
			fmt_bit_set(fi, v);
		case runtime.Type_Info_Bit_Field:
			fmt_bit_field(fi, v);
		case:
			fmt_value(fi, any{v.data, info.base.id}, verb);
		}

	case runtime.Type_Info_Boolean:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_Integer:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_Rune:       fmt_arg(fi, v, verb);
	case runtime.Type_Info_Float:      fmt_arg(fi, v, verb);
	case runtime.Type_Info_Complex:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_String:     fmt_arg(fi, v, verb);

	case runtime.Type_Info_Pointer:
		if v.id == typeid_of(^runtime.Type_Info) {
			write_type(fi.buf, (^^runtime.Type_Info)(v.data)^);
		} else {
			fmt_pointer(fi, (^rawptr)(v.data)^, verb);
		}

	case runtime.Type_Info_Array:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		for i in 0..info.count-1 {
			if i > 0 do write_string(fi.buf, ", ");

			data := uintptr(v.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}

	case runtime.Type_Info_Dynamic_Array:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		array := cast(^mem.Raw_Dynamic_Array)v.data;
		for i in 0..array.len-1 {
			if i > 0 do write_string(fi.buf, ", ");

			data := uintptr(array.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}

	case runtime.Type_Info_Slice:
		write_byte(fi.buf, '[');
		defer write_byte(fi.buf, ']');
		slice := cast(^mem.Raw_Slice)v.data;
		for i in 0..slice.len-1 {
			if i > 0 do write_string(fi.buf, ", ");

			data := uintptr(slice.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}

	case runtime.Type_Info_Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		write_string(fi.buf, "map[");
		defer write_byte(fi.buf, ']');

		m := (^mem.Raw_Map)(v.data);
		if m != nil {
			if info.generated_struct == nil {
				return;
			}
			entries    := &m.entries;
			gs         := runtime.type_info_base(info.generated_struct).variant.(runtime.Type_Info_Struct);
			ed         := runtime.type_info_base(gs.types[1]).variant.(runtime.Type_Info_Dynamic_Array);
			entry_type := ed.elem.variant.(runtime.Type_Info_Struct);
			entry_size := ed.elem_size;

			for i in 0..entries.len-1 {
				if i > 0 do write_string(fi.buf, ", ");

				data := uintptr(entries.data) + uintptr(i*entry_size);
				header := cast(^runtime.Map_Entry_Header)data;

				if types.is_string(info.key) {
					write_string(fi.buf, header.key.str);
				} else {
					fi := Fmt_Info{buf = fi.buf};
					fmt_arg(&fi, any{rawptr(&header.key.hash), info.key.id}, 'v');
				}

				write_string(fi.buf, "=");

				value := data + entry_type.offsets[2];
				fmt_arg(fi, any{rawptr(value), info.value.id}, 'v');
			}
		}

	case runtime.Type_Info_Struct:
		if info.is_raw_union {
			write_string(fi.buf, "(raw_union)");
			return;
		}

		write_byte(fi.buf, '{');
		defer write_byte(fi.buf, '}');

		fi.indent += 1;  defer fi.indent -= 1;
		hash := fi.hash; defer fi.hash = hash;
		fi.hash = false;


		if hash	do write_byte(fi.buf, '\n');

		for _, i in info.names {
			if !hash && i > 0 do write_string(fi.buf, ", ");
			if hash {
				for in 0..fi.indent-1 {
					write_byte(fi.buf, '\t');
				}
			}

			write_string(fi.buf, info.names[i]);
			write_string(fi.buf, " = ");

			if t := info.types[i]; types.is_any(t) {
				write_string(fi.buf, "any{}");
			} else {
				data := uintptr(v.data) + info.offsets[i];
				fmt_arg(fi, any{rawptr(data), t.id}, 'v');
			}
			if hash do write_string(fi.buf, ",\n");
		}

	case runtime.Type_Info_Union:
		tag_ptr := uintptr(v.data) + info.tag_offset;
		tag_any := any{rawptr(tag_ptr), info.tag_type.id};

		tag: i64 = -1;
		switch i in tag_any {
		case u8:   tag = i64(i);
		case i8:   tag = i64(i);
		case u16:  tag = i64(i);
		case i16:  tag = i64(i);
		case u32:  tag = i64(i);
		case i32:  tag = i64(i);
		case u64:  tag = i64(i);
		case i64:  tag = i64(i);
		case: panic("Invalid union tag type");
		}

		if v.data == nil || tag == 0 {
			write_string(fi.buf, "nil");
		} else {
			id := info.variants[tag-1].id;
			fmt_arg(fi, any{v.data, id}, verb);
		}

	case runtime.Type_Info_Enum:
		fmt_enum(fi, v, verb);

	case runtime.Type_Info_Procedure:
		ptr := (^rawptr)(v.data)^;
		if ptr == nil {
			write_string(fi.buf, "nil");
		} else {
			write_typeid(fi.buf, v.id);
			write_string(fi.buf, " @ ");
			fmt_pointer(fi, ptr, 'p');
		}

	case runtime.Type_Info_Type_Id:
		id := (^typeid)(v.data)^;
		write_typeid(fi.buf, id);

	case runtime.Type_Info_Bit_Field:
		fmt_bit_field(fi, v);

	case runtime.Type_Info_Bit_Set:
		fmt_bit_set(fi, v);
	}
}

fmt_complex :: proc(fi: ^Fmt_Info, c: complex128, bits: int, verb: rune) {
	switch verb {
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

fmt_arg :: proc(fi: ^Fmt_Info, arg: any, verb: rune) {
	if arg == nil {
		write_string(fi.buf, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := type_info_of(arg.id);
		switch a in arg {
		case ^runtime.Type_Info: ti = a;
		}
		write_type(fi.buf, ti);
		return;
	}

	base_arg := arg;
	base_arg.id = runtime.typeid_base(base_arg.id);
	switch a in base_arg {
	case bool:       fmt_bool(fi, bool(a), verb);
	case b8:         fmt_bool(fi, bool(a), verb);
	case b16:        fmt_bool(fi, bool(a), verb);
	case b32:        fmt_bool(fi, bool(a), verb);
	case b64:        fmt_bool(fi, bool(a), verb);

	case any:        fmt_arg(fi,  a, verb);
	case rune:       fmt_rune(fi, a, verb);

	case f32:        fmt_float(fi, f64(a), 32, verb);
	case f64:        fmt_float(fi, a,      64, verb);

	case complex64:  fmt_complex(fi, complex128(a), 64, verb);
	case complex128: fmt_complex(fi, a, 128, verb);

	case i8:      fmt_int(fi, u64(a), true,   8, verb);
	case u8:      fmt_int(fi, u64(a), false,  8, verb);
	case i16:     fmt_int(fi, u64(a), true,  16, verb);
	case u16:     fmt_int(fi, u64(a), false, 16, verb);
	case i32:     fmt_int(fi, u64(a), true,  32, verb);
	case u32:     fmt_int(fi, u64(a), false, 32, verb);
	case i64:     fmt_int(fi, u64(a), true,  64, verb);
	case u64:     fmt_int(fi, u64(a), false, 64, verb);
	case int:     fmt_int(fi, u64(a), true,  8*size_of(int), verb);
	case uint:    fmt_int(fi, u64(a), false, 8*size_of(uint), verb);
	case uintptr: fmt_int(fi, u64(a), false, 8*size_of(uintptr), verb);

	case string:  fmt_string(fi, a, verb);
	case cstring: fmt_cstring(fi, a, verb);

	case typeid:  write_typeid(fi.buf, a);

	case: fmt_value(fi, arg, verb);
	}

}



sbprint :: proc(buf: ^String_Buffer, args: ..any) -> string {
	fi: Fmt_Info;
	prev_string := false;

	fi.buf = buf;

	for arg, i in args {
		is_string := arg != nil && types.is_string(type_info_of(arg.id));
		if i > 0 && !is_string && !prev_string {
			write_byte(buf, ' ');
		}
		fmt_value(&fi, args[i], 'v');
		prev_string = is_string;
	}
	return to_string(buf^);
}

sbprintln :: proc(buf: ^String_Buffer, args: ..any) -> string {
	fi: Fmt_Info;
	fi.buf = buf;

	for _, i in args {
		if i > 0 do write_byte(buf, ' ');

		fmt_value(&fi, args[i], 'v');
	}
	write_byte(buf, '\n');
	return to_string(buf^);
}

sbprintf :: proc(b: ^String_Buffer, fmt: string, args: ..any) -> string {
	fi: Fmt_Info;
	arg_index: int = 0;
	end := len(fmt);
	was_prev_index := false;


	loop: for i := 0; i < end; /**/ {
		fi = Fmt_Info{buf = b, good_arg_index = true};

		prev_i := i;
		for i < end && fmt[i] != '%' {
			i += 1;
		}
		if i > prev_i {
			write_string(b, fmt[prev_i:i]);
		}
		if i >= end {
			break loop;
		}

		// Process a "verb"
		i += 1;

		prefix_loop: for ; i < end; i += 1 {
			switch fmt[i] {
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
			i += 1;
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
			i += 1;
			if was_prev_index { // %[6].2d
				fi.good_arg_index = false;
			}
			if i < end && fmt[i] == '*' {
				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));
				i += 1;
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
			break loop;
		}

		verb, w := utf8.decode_rune_from_string(fmt[i:]);
		i += w;

		switch {
		case verb == '%':
			write_byte(b, '%');
		case !fi.good_arg_index:
			write_string(b, "%!(BAD ARGUMENT NUMBER)");
		case arg_index >= len(args):
			write_string(b, "%!(MISSING ARGUMENT)");
		case:
			fmt_arg(&fi, args[arg_index], verb);
			arg_index += 1;
		}
	}

	if !fi.reordered && arg_index < len(args) {
		write_string(b, "%!(EXTRA ");
		for arg, index in args[arg_index:] {
			if index > 0 do write_string(b, ", ");

			if arg == nil do write_string(b, "<nil>");
			else          do fmt_arg(&fi, args[index], 'v');
		}
		write_string(b, ")");
	}

	return to_string(b^);
}
