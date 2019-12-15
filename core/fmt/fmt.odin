package fmt

import "core:runtime"
import "core:os"
import "core:mem"
import "core:math/bits"
import "core:unicode/utf8"
import "core:strconv"
import "core:strings"
import "core:reflect"


@private
DEFAULT_BUFFER_SIZE :: 1<<12;

Info :: struct {
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

	buf: ^strings.Builder,
	arg: any, // Temporary
	record_level: int,
}

fprint :: proc(fd: os.Handle, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := strings.builder_from_slice(data[:]);
	res := sbprint(&buf, ..args);
	os.write_string(fd, res);
	return len(res);
}

fprintln :: proc(fd: os.Handle, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := strings.builder_from_slice(data[:]);
	res := sbprintln(&buf, ..args);
	os.write_string(fd, res);
	return len(res);
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	data: [DEFAULT_BUFFER_SIZE]byte;
	buf := strings.builder_from_slice(data[:]);
	res := sbprintf(&buf, fmt, ..args);
	os.write_string(fd, res);
	return len(res);
}


// print* procedures return the number of bytes written
print   :: proc(args: ..any)              -> int { return fprint(context.stdout, ..args); }
println :: proc(args: ..any)              -> int { return fprintln(context.stdout, ..args); }
printf  :: proc(fmt: string, args: ..any) -> int { return fprintf(context.stdout, fmt, ..args); }

eprint   :: proc(args: ..any)              -> int { return fprint(context.stderr, ..args); }
eprintln :: proc(args: ..any)              -> int { return fprintln(context.stderr, ..args); }
eprintf  :: proc(fmt: string, args: ..any) -> int { return fprintf(context.stderr, fmt, ..args); }


@(deprecated="prefer eprint")   print_err   :: proc(args: ..any)              -> int { return eprint(..args); }
@(deprecated="prefer eprintf")  printf_err  :: proc(fmt: string, args: ..any) -> int { return eprintf(fmt, ..args); }
@(deprecated="prefer eprintln") println_err :: proc(args: ..any)              -> int { return eprintln(..args); }


// aprint* procedures return a string that was allocated with the current context
// They must be freed accordingly
aprint :: proc(args: ..any) -> string {
	str := strings.make_builder();
	sbprint(&str, ..args);
	return strings.to_string(str);
}
aprintln :: proc(args: ..any) -> string {
	str := strings.make_builder();
	sbprintln(&str, ..args);
	return strings.to_string(str);
}
aprintf :: proc(fmt: string, args: ..any) -> string {
	str := strings.make_builder();
	sbprintf(&str, fmt, ..args);
	return strings.to_string(str);
}


// tprint* procedures return a string that was allocated with the current context's temporary allocator
tprint :: proc(args: ..any) -> string {
	str := strings.make_builder(context.temp_allocator);
	sbprint(&str, ..args);
	return strings.to_string(str);
}
tprintln :: proc(args: ..any) -> string {
	str := strings.make_builder(context.temp_allocator);
	sbprintln(&str, ..args);
	return strings.to_string(str);
}
tprintf :: proc(fmt: string, args: ..any) -> string {
	str := strings.make_builder(context.temp_allocator);
	sbprintf(&str, fmt, ..args);
	return strings.to_string(str);
}


// bprint* procedures return a string using a buffer from an array
bprint :: proc(buf: []byte, args: ..any) -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
	return sbprint(&sb, ..args);
}
bprintln :: proc(buf: []byte, args: ..any) -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
	return sbprintln(&sb, ..args);
}
bprintf :: proc(buf: []byte, fmt: string, args: ..any) -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
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
	buf := strings.builder_from_slice(data[:]);
	reflect.write_type(&buf, info);
	os.write_string(fd, strings.to_string(buf));
}



sbprint :: proc(buf: ^strings.Builder, args: ..any) -> string {
	fi: Info;
	prev_string := false;

	fi.buf = buf;

	for arg, i in args {
		is_string := arg != nil && reflect.is_string(type_info_of(arg.id));
		if i > 0 && !is_string && !prev_string {
			strings.write_byte(buf, ' ');
		}
		fmt_value(&fi, args[i], 'v');
		prev_string = is_string;
	}
	return strings.to_string(buf^);
}

sbprintln :: proc(buf: ^strings.Builder, args: ..any) -> string {
	fi: Info;
	fi.buf = buf;

	for _, i in args {
		if i > 0 do strings.write_byte(buf, ' ');

		fmt_value(&fi, args[i], 'v');
	}
	strings.write_byte(buf, '\n');
	return strings.to_string(buf^);
}

sbprintf :: proc(b: ^strings.Builder, fmt: string, args: ..any) -> string {
	fi: Info;
	arg_index: int = 0;
	end := len(fmt);
	was_prev_index := false;


	loop: for i := 0; i < end; /**/ {
		fi = Info{buf = b, good_arg_index = true};

		prev_i := i;
		for i < end && fmt[i] != '%' {
			i += 1;
		}
		if i > prev_i {
			strings.write_string(b, fmt[prev_i:i]);
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
				strings.write_string(b, "%!(BAD WIDTH)");
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
					strings.write_string(fi.buf, "%!(BAD PRECISION)");
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
			strings.write_string(b, "%!(NO VERB)");
			break loop;
		}

		verb, w := utf8.decode_rune_in_string(fmt[i:]);
		i += w;

		switch {
		case verb == '%':
			strings.write_byte(b, '%');
		case !fi.good_arg_index:
			strings.write_string(b, "%!(BAD ARGUMENT NUMBER)");
		case arg_index >= len(args):
			strings.write_string(b, "%!(MISSING ARGUMENT)");
		case:
			fmt_arg(&fi, args[arg_index], verb);
			arg_index += 1;
		}
	}

	if !fi.reordered && arg_index < len(args) {
		strings.write_string(b, "%!(EXTRA ");
		for arg, index in args[arg_index:] {
			if index > 0 do strings.write_string(b, ", ");

			if arg == nil do strings.write_string(b, "<nil>");
			else          do fmt_arg(&fi, args[index], 'v');
		}
		strings.write_string(b, ")");
	}

	return strings.to_string(b^);
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

_arg_number :: proc(fi: ^Info, arg_index: int, format: string, offset, arg_count: int) -> (index, new_offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if len(format) < 3 do return 0, 1, false;

		for i in 1..<len(format) {
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

	if ok {
		new_arg_index += 1;
	}

	return num, new_arg_index, ok;
}


fmt_bad_verb :: proc(using fi: ^Info, verb: rune) {
	strings.write_string(buf, "%!");
	strings.write_rune(buf, verb);
	strings.write_byte(buf, '(');
	if arg.id != nil {
		reflect.write_typeid(buf, arg.id);
		strings.write_byte(buf, '=');
		fmt_value(fi, arg, 'v');
	} else {
		strings.write_string(buf, "<nil>");
	}
	strings.write_byte(buf, ')');
}

fmt_bool :: proc(using fi: ^Info, b: bool, verb: rune) {
	switch verb {
	case 't', 'v':
		strings.write_string(buf, b ? "true" : "false");
	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^Info, width: int) {
	if width <= 0 do return;

	pad_byte: byte = '0';
	if fi.space do pad_byte = ' ';

	for i := 0; i < width; i += 1 {
		strings.write_byte(fi.buf, pad_byte);
	}
}

_fmt_int :: proc(fi: ^Info, u: u64, base: int, is_signed: bool, bit_size: int, digits: string) {
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

	flags: strconv.Int_Flags;
	if fi.hash && !fi.zero do flags |= {.Prefix};
	if fi.plus             do flags |= {.Plus};
	if fi.space            do flags |= {.Space};
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
			strings.write_byte(fi.buf, '0');
			strings.write_byte(fi.buf, c);
		}
	}

	prev_zero := fi.zero;
	defer fi.zero = prev_zero;
	fi.zero = false;
	_pad(fi, s);
}

_fmt_int_128 :: proc(fi: ^Info, u: u128, base: int, is_signed: bool, bit_size: int, digits: string) {
	_, neg := strconv.is_integer_negative_128(u, is_signed, bit_size);

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

	flags: strconv.Int_Flags;
	if fi.hash && !fi.zero do flags |= {.Prefix};
	if fi.plus             do flags |= {.Plus};
	if fi.space            do flags |= {.Space};
	s := strconv.append_bits_128(buf[start:], u, base, is_signed, bit_size, digits, flags);

	if fi.hash && fi.zero {
		c: byte = 0;
		switch base {
		case 2:  c = 'b';
		case 8:  c = 'o';
		case 12: c = 'z';
		case 16: c = 'x';
		}
		if c != 0 {
			strings.write_byte(fi.buf, '0');
			strings.write_byte(fi.buf, c);
		}
	}

	prev_zero := fi.zero;
	defer fi.zero = prev_zero;
	fi.zero = false;
	_pad(fi, s);
}

__DIGITS_LOWER := "0123456789abcdefx";
__DIGITS_UPPER := "0123456789ABCDEFX";

fmt_rune :: proc(fi: ^Info, r: rune, verb: rune) {
	switch verb {
	case 'c', 'r', 'v':
		strings.write_rune(fi.buf, r);
	case:
		fmt_int(fi, u64(r), false, 32, verb);
	}
}

fmt_int :: proc(fi: ^Info, u: u64, is_signed: bool, bit_size: int, verb: rune) {
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
			strings.write_string(fi.buf, "U+");
			_fmt_int(fi, u, 16, false, bit_size, __DIGITS_UPPER);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}

fmt_int_128 :: proc(fi: ^Info, u: u128, is_signed: bool, bit_size: int, verb: rune) {
	switch verb {
	case 'v': _fmt_int_128(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
	case 'b': _fmt_int_128(fi, u,  2, is_signed, bit_size, __DIGITS_LOWER);
	case 'o': _fmt_int_128(fi, u,  8, is_signed, bit_size, __DIGITS_LOWER);
	case 'd': _fmt_int_128(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
	case 'z': _fmt_int_128(fi, u, 12, is_signed, bit_size, __DIGITS_LOWER);
	case 'x': _fmt_int_128(fi, u, 16, is_signed, bit_size, __DIGITS_LOWER);
	case 'X': _fmt_int_128(fi, u, 16, is_signed, bit_size, __DIGITS_UPPER);
	case 'c', 'r':
		fmt_rune(fi, rune(u), verb);
	case 'U':
		r := rune(u);
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb);
		} else {
			strings.write_string(fi.buf, "U+");
			_fmt_int_128(fi, u, 16, false, bit_size, __DIGITS_UPPER);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}

_pad :: proc(fi: ^Info, s: string) {
	if !fi.width_set {
		strings.write_string(fi.buf, s);
		return;
	}


	width := fi.width - utf8.rune_count_in_string(s);
	if fi.minus { // right pad
		strings.write_string(fi.buf, s);
		fmt_write_padding(fi, width);
	} else { // left pad
		fmt_write_padding(fi, width);
		strings.write_string(fi.buf, s);
	}
}

fmt_float :: proc(fi: ^Info, v: f64, bit_size: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v':
		prec: int = 3;
		if fi.prec_set do prec = fi.prec;
		buf: [386]byte;

		str := strconv.append_float(buf[1:], v, 'f', prec, bit_size);
		b := buf[:len(str)+1];
		if b[1] == '+' || b[1] == '-' {
			b = b[1:];
		} else {
			b[0] = '+';
		}

		if fi.space && !fi.plus && b[0] == '+' {
			b[0] = ' ';
		}

		if len(b) > 1 && (b[1] == 'N' || b[1] == 'I') {
			strings.write_string(fi.buf, string(b));
			return;
		}

		if fi.plus || b[0] != '+' {
			if fi.zero && fi.width_set && fi.width > len(b) {
				strings.write_byte(fi.buf, b[0]);
				fmt_write_padding(fi, fi.width - len(b));
				strings.write_string(fi.buf, string(b[1:]));
			} else {
				_pad(fi, string(b));
			}
		} else {
			_pad(fi, string(b[1:]));
		}

	case 'e', 'E':
		prec: int = 3;
		if fi.prec_set do prec = fi.prec;
		buf: [386]byte;

		str := strconv.append_float(buf[1:], v, 'e', prec, bit_size);
		b := buf[:len(str)+1];
		if b[1] == '+' || b[1] == '-' {
			b = b[1:];
		} else {
			b[0] = '+';
		}

		if fi.space && !fi.plus && b[0] == '+' {
			b[0] = ' ';
		}

		if len(b) > 1 && (b[1] == 'N' || b[1] == 'I') {
			strings.write_string(fi.buf, string(b));
			return;
		}

		if fi.plus || str[0] != '+' {
			if fi.zero && fi.width_set && fi.width > len(b) {
				strings.write_byte(fi.buf, b[0]);
				fmt_write_padding(fi, fi.width - len(b));
				strings.write_string(fi.buf, string(b[1:]));
			} else {
				_pad(fi, string(b));
			}
		} else {
			_pad(fi, string(b[1:]));
		}

	case 'h', 'H':
		prev_fi := fi^;
		defer fi^ = prev_fi;
		fi.hash = false;
		fi.width = bit_size;
		fi.zero = true;
		fi.plus = false;

		u: u64;
		switch bit_size {
		case 32: u = u64(transmute(u32)f32(v));
		case 64: u = transmute(u64)v;
		case: panic("Unhandled float size");
		}

		strings.write_string(fi.buf, "0h");
		_fmt_int(fi, u, 16, false, bit_size, verb == 'h' ? __DIGITS_LOWER : __DIGITS_UPPER);


	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_string :: proc(fi: ^Info, s: string, verb: rune) {
	switch verb {
	case 's', 'v':
		strings.write_string(fi.buf, s);

	case 'q': // quoted string
		strings.write_quoted_string(fi.buf, s, '"');

	case 'x', 'X':
		space := fi.space;
		fi.space = false;
		defer fi.space = space;

		for i in 0..<len(s) {
			if i > 0 && space do strings.write_byte(fi.buf, ' ');
			char_set := __DIGITS_UPPER;
			if verb == 'x' do char_set = __DIGITS_LOWER;
			_fmt_int(fi, u64(s[i]), 16, false, 8, char_set);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}
fmt_cstring :: proc(fi: ^Info, s: cstring, verb: rune) {
	fmt_string(fi, string(s), verb);
}

fmt_pointer :: proc(fi: ^Info, p: rawptr, verb: rune) {
	u := u64(uintptr(p));
	switch verb {
	case 'p', 'v':
		if !fi.hash || verb == 'v' {
			strings.write_string(fi.buf, "0x");
		}
		_fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);

	case 'b': _fmt_int(fi, u,  2, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'o': _fmt_int(fi, u,  8, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'd': _fmt_int(fi, u, 10, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'x': _fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'X': _fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);

	case:
		fmt_bad_verb(fi, verb);
	}
}

enum_value_to_string :: proc(val: any) -> (string, bool) {
	v := val;
	v.id = runtime.typeid_base(v.id);
	type_info := type_info_of(v.id);

	switch e in type_info.variant {
	case: return "", false;
	case runtime.Type_Info_Enum:
		get_str :: proc(i: $T, e: runtime.Type_Info_Enum) -> (string, bool) {
			if reflect.is_string(e.base) {
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
	ti := runtime.type_info_base(type_info_of(T));
	if e, ok := ti.variant.(runtime.Type_Info_Enum); ok {
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

fmt_enum :: proc(fi: ^Info, v: any, verb: rune) {
	if v.id == nil || v.data == nil {
		strings.write_string(fi.buf, "<nil>");
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
			strings.write_string(fi.buf, str);
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

fmt_bit_set :: proc(fi: ^Info, v: any, name: string = "") {
	is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
		if ti == nil {
			return false;
		}
		t := runtime.type_info_base(ti);
		switch info in t.variant {
		case runtime.Type_Info_Integer:
			switch info.endianness {
			case .Platform: return false;
			case .Little:   return ODIN_ENDIAN != "little";
			case .Big:      return ODIN_ENDIAN != "big";
			}
		}
		return false;
	}

	byte_swap :: bits.byte_swap;

	type_info := type_info_of(v.id);
	switch info in type_info.variant {
	case runtime.Type_Info_Named:
		val := v;
		val.id = info.base.id;
		fmt_bit_set(fi, val, info.name);

	case runtime.Type_Info_Bit_Set:
		bits: u128;
		bit_size := u128(8*type_info.size);

		do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying);

		switch bit_size {
		case  0: bits = 0;
		case  8:
			x := (^u8)(v.data)^;
			bits = u128(x);
		case 16:
			x := (^u16)(v.data)^;
			if do_byte_swap do x = byte_swap(x);
			bits = u128(x);
		case 32:
			x := (^u32)(v.data)^;
			if do_byte_swap do x = byte_swap(x);
			bits = u128(x);
		case 64:
			x := (^u64)(v.data)^;
			if do_byte_swap do x = byte_swap(x);
			bits = u128(x);
		case 128:
			x := (^u128)(v.data)^;
			if do_byte_swap do x = byte_swap(x);
			bits = u128(x);
		case: panic("unknown bit_size size");
		}

		et := runtime.type_info_base(info.elem);

		if name != "" {
			strings.write_string(fi.buf, name);
		} else {
			reflect.write_type(fi.buf, type_info);
		}
		strings.write_byte(fi.buf, '{');
		defer strings.write_byte(fi.buf, '}');

		e, is_enum := et.variant.(runtime.Type_Info_Enum);
		commas := 0;
		loop: for i in 0 ..< bit_size {
			if bits & (1<<i) == 0 {
				continue loop;
			}

			if commas > 0 do strings.write_string(fi.buf, ", ");

			if is_enum do for ev, evi in e.values {
				v := enum_value_to_u64(ev);
				if v == u64(i) {
					strings.write_string(fi.buf, e.names[evi]);
					commas += 1;
					continue loop;
				}
			}
			strings.write_i64(fi.buf, i64(i), 10);
			commas += 1;
		}
	}
}
fmt_bit_field :: proc(fi: ^Info, v: any, bit_field_name: string = "") {
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

		if bit_field_name != "" {
			strings.write_string(fi.buf, bit_field_name);
			strings.write_byte(fi.buf, '{');
		} else {
			strings.write_string(fi.buf, "bit_field{");
		}
		for name, i in info.names {
			if i > 0 {
				strings.write_string(fi.buf, ", ");
			}
			bits := u64(info.bits[i]);
			offset := u64(info.offsets[i]);
			strings.write_string(fi.buf, name);
			strings.write_string(fi.buf, " = ");

			n := 8*u64(size_of(u64));
			sa := n - bits;
			u := data>>offset;
			u <<= sa;
			u >>= sa;

			strings.write_u64(fi.buf, u, 10);

		}
		strings.write_byte(fi.buf, '}');
	}
}

fmt_opaque :: proc(fi: ^Info, v: any) {
	is_nil :: proc(data: rawptr, n: int) -> bool {
		if data == nil do return true;
		if n == 0 do return true;

		a := (^byte)(data);
		for i in 0..<n do if mem.ptr_offset(a, i)^ != 0 {
			return false;
		}
		return true;
	}

	rt :: runtime;

	type_info := type_info_of(v.id);

	if is_nil(v.data, type_info.size) {
		strings.write_string(fi.buf, "nil");
		return;
	}

	if ot, ok := rt.type_info_base(type_info).variant.(rt.Type_Info_Opaque); ok {
		elem := rt.type_info_base(ot.elem);
		if elem == nil do return;
		reflect.write_type(fi.buf, type_info);
		strings.write_byte(fi.buf, '{');
		defer strings.write_byte(fi.buf, '}');

		switch in elem.variant {
		case rt.Type_Info_Integer, rt.Type_Info_Pointer, rt.Type_Info_Float:
			fmt_value(fi, any{v.data, elem.id}, 'v');
		case:
			// Okay
		}
	} else {
		reflect.write_type(fi.buf, type_info);
		strings.write_byte(fi.buf, '{');
		strings.write_byte(fi.buf, '}');
	}
}

fmt_value :: proc(fi: ^Info, v: any, verb: rune) {
	if v.data == nil || v.id == nil {
		strings.write_string(fi.buf, "<nil>");
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
				strings.write_string(fi.buf, info.name);
				strings.write_string(fi.buf, "{}");
				return;
			};

			is_soa := b.soa_kind != .None;

			strings.write_string(fi.buf, info.name);
			strings.write_byte(fi.buf, is_soa ? '[' : '{');

			hash   := fi.hash;   defer fi.hash = hash;
			indent := fi.indent; defer fi.indent -= 1;

			fi.hash = false;
			fi.indent += 1;

			if hash	do strings.write_byte(fi.buf, '\n');
			defer {
				if hash do for in 0..<indent do strings.write_byte(fi.buf, '\t');
				strings.write_byte(fi.buf, is_soa ? ']' : '}');
			}

			if is_soa {
				fi.indent += 1;
				defer fi.indent -= 1;

				base_type_name: string;
				if v, ok := b.soa_base_type.variant.(runtime.Type_Info_Named); ok {
					base_type_name = v.name;
				}

				for index in 0..<uintptr(b.soa_len) {
					if !hash && index > 0 do strings.write_string(fi.buf, ", ");

					field_count := -1;

					if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");

					strings.write_string(fi.buf, base_type_name);
					strings.write_byte(fi.buf, '{');
					defer strings.write_byte(fi.buf, '}');

					for name, i in b.names {
						field_count += 1;

						if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");
						if hash do for in 0..<fi.indent do strings.write_byte(fi.buf, '\t');

						strings.write_string(fi.buf, name);
						strings.write_string(fi.buf, " = ");

						t := b.types[i].variant.(runtime.Type_Info_Array).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							strings.write_string(fi.buf, "any{}");
						} else {
							data := rawptr(uintptr(v.data) + b.offsets[i] + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}

						if hash do strings.write_string(fi.buf, ",\n");
					}
				}
			} else {
				field_count := -1;
				for name, i in b.names {
					field_count += 1;

					if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");
					if hash do for in 0..<fi.indent do strings.write_byte(fi.buf, '\t');

					strings.write_string(fi.buf, name);
					strings.write_string(fi.buf, " = ");

					if t := b.types[i]; reflect.is_any(t) {
						strings.write_string(fi.buf, "any{}");
					} else {
						data := rawptr(uintptr(v.data) + b.offsets[i]);
						fmt_arg(fi, any{data, t.id}, 'v');
					}

					if hash do strings.write_string(fi.buf, ",\n");
				}
			}

		case runtime.Type_Info_Bit_Set:
			fmt_bit_set(fi, v);
		case runtime.Type_Info_Bit_Field:
			fmt_bit_field(fi, v);
		case runtime.Type_Info_Opaque:
			fmt_opaque(fi, v);
		case:
			fmt_value(fi, any{v.data, info.base.id}, verb);
		}

	case runtime.Type_Info_Boolean:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_Integer:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_Rune:       fmt_arg(fi, v, verb);
	case runtime.Type_Info_Float:      fmt_arg(fi, v, verb);
	case runtime.Type_Info_Complex:    fmt_arg(fi, v, verb);
	case runtime.Type_Info_Quaternion: fmt_arg(fi, v, verb);
	case runtime.Type_Info_String:     fmt_arg(fi, v, verb);

	case runtime.Type_Info_Pointer:
		if v.id == typeid_of(^runtime.Type_Info) {
			reflect.write_type(fi.buf, (^^runtime.Type_Info)(v.data)^);
		} else {
			ptr := (^rawptr)(v.data)^;
			if verb != 'p' && info.elem != nil {
				a := any{ptr, info.elem.id};

				elem := runtime.type_info_base(info.elem);
				if elem != nil do switch e in elem.variant {
				case runtime.Type_Info_Array,
				     runtime.Type_Info_Slice,
				     runtime.Type_Info_Dynamic_Array,
				     runtime.Type_Info_Map:
					if ptr == nil {
						strings.write_string(fi.buf, "<nil>");
						return;
					}
					if fi.record_level < 1 {
					  	fi.record_level += 1;
						defer fi.record_level -= 1;
						strings.write_byte(fi.buf, '&');
						fmt_value(fi, a, verb);
						return;
					}

				case runtime.Type_Info_Struct,
				     runtime.Type_Info_Union:
					if ptr == nil {
						strings.write_string(fi.buf, "<nil>");
						return;
					}
					if fi.record_level < 1 {
						fi.record_level += 1;
						defer fi.record_level -= 1;
						strings.write_byte(fi.buf, '&');
						fmt_value(fi, a, verb);
						return;
					}
				}
			}
			fmt_pointer(fi, ptr, verb);
		}

	case runtime.Type_Info_Array:
		strings.write_byte(fi.buf, '[');
		defer strings.write_byte(fi.buf, ']');
		for i in 0..<info.count {
			if i > 0 do strings.write_string(fi.buf, ", ");

			data := uintptr(v.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}

	case runtime.Type_Info_Dynamic_Array:
		if verb == 'p' {
			slice := cast(^mem.Raw_Dynamic_Array)v.data;
			fmt_pointer(fi, slice.data, 'p');
		} else {
			strings.write_byte(fi.buf, '[');
			defer strings.write_byte(fi.buf, ']');
			array := cast(^mem.Raw_Dynamic_Array)v.data;
			for i in 0..<array.len {
				if i > 0 do strings.write_string(fi.buf, ", ");

				data := uintptr(array.data) + uintptr(i*info.elem_size);
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
			}
		}

	case runtime.Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			strings.write_string(fi.buf, "intrinsics.x86_mmx<>");
		}
		strings.write_byte(fi.buf, '<');
		defer strings.write_byte(fi.buf, '>');
		for i in 0..<info.count {
			if i > 0 do strings.write_string(fi.buf, ", ");

			data := uintptr(v.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}


	case runtime.Type_Info_Slice:
		if verb == 'p' {
			slice := cast(^mem.Raw_Slice)v.data;
			fmt_pointer(fi, slice.data, 'p');
		} else {
			strings.write_byte(fi.buf, '[');
			defer strings.write_byte(fi.buf, ']');
			slice := cast(^mem.Raw_Slice)v.data;
			for i in 0..<slice.len {
				if i > 0 do strings.write_string(fi.buf, ", ");

				data := uintptr(slice.data) + uintptr(i*info.elem_size);
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
			}
		}
	case runtime.Type_Info_Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		strings.write_string(fi.buf, "map[");
		defer strings.write_byte(fi.buf, ']');

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

			for i in 0..<entries.len {
				if i > 0 do strings.write_string(fi.buf, ", ");

				data := uintptr(entries.data) + uintptr(i*entry_size);
				header := cast(^runtime.Map_Entry_Header)data;

				if reflect.is_string(info.key) {
					strings.write_string(fi.buf, header.key.str);
				} else {
					fi := Info{buf = fi.buf};
					fmt_arg(&fi, any{rawptr(&header.key.hash), info.key.id}, 'v');
				}

				strings.write_string(fi.buf, "=");

				value := data + entry_type.offsets[2];
				fmt_arg(fi, any{rawptr(value), info.value.id}, 'v');
			}
		}

	case runtime.Type_Info_Struct:
		if info.is_raw_union {
			strings.write_string(fi.buf, "(raw_union)");
			return;
		}

		is_soa := info.soa_kind != .None;

		strings.write_byte(fi.buf, is_soa ? '[' : '{');
		defer strings.write_byte(fi.buf, is_soa ? ']' : '}');

		fi.indent += 1;  defer fi.indent -= 1;
		hash := fi.hash; defer fi.hash = hash;
		fi.hash = false;


		if hash	do strings.write_byte(fi.buf, '\n');

		if is_soa {
			fi.indent += 1;
			defer fi.indent -= 1;

			base_type_name: string;
			if v, ok := info.soa_base_type.variant.(runtime.Type_Info_Named); ok {
				base_type_name = v.name;
			}

			actual_field_count := len(info.names);

			n := uintptr(info.soa_len);

			if info.soa_kind == .Slice {
				actual_field_count = len(info.names)-1; // len

				n = uintptr((^int)(uintptr(v.data) + info.offsets[actual_field_count])^);

			} else if info.soa_kind == .Dynamic {
				actual_field_count = len(info.names)-3; // len, cap, allocator

				n = uintptr((^int)(uintptr(v.data) + info.offsets[actual_field_count])^);
			}



			for index in 0..<n {
				if !hash && index > 0 do strings.write_string(fi.buf, ", ");

				field_count := -1;

				if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");

				strings.write_string(fi.buf, base_type_name);
				strings.write_byte(fi.buf, '{');
				defer strings.write_byte(fi.buf, '}');

				for i in 0..<actual_field_count {
					name := info.names[i];
					field_count += 1;

					if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");
					if hash do for in 0..<fi.indent do strings.write_byte(fi.buf, '\t');

					strings.write_string(fi.buf, name);
					strings.write_string(fi.buf, " = ");

					if info.soa_kind == .Fixed {
						t := info.types[i].variant.(runtime.Type_Info_Array).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							strings.write_string(fi.buf, "any{}");
						} else {
							data := rawptr(uintptr(v.data) + info.offsets[i] + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}
					} else {
						t := info.types[i].variant.(runtime.Type_Info_Pointer).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							strings.write_string(fi.buf, "any{}");
						} else {
							field_ptr := (^^byte)(uintptr(v.data) + info.offsets[i])^;
							data := rawptr(uintptr(field_ptr) + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}
					}

					if hash do strings.write_string(fi.buf, ",\n");
				}
			}
		} else {
			field_count := -1;
			for name, i in info.names {
				field_count += 1;

				if !hash && field_count > 0 do strings.write_string(fi.buf, ", ");
				if hash do for in 0..<fi.indent do strings.write_byte(fi.buf, '\t');

				strings.write_string(fi.buf, name);
				strings.write_string(fi.buf, " = ");

				if t := info.types[i]; reflect.is_any(t) {
					strings.write_string(fi.buf, "any{}");
				} else {
					data := rawptr(uintptr(v.data) + info.offsets[i]);
					fmt_arg(fi, any{data, t.id}, 'v');
				}

				if hash do strings.write_string(fi.buf, ",\n");
			}
		}


	case runtime.Type_Info_Union:
		if type_info.size == 0 {
			strings.write_string(fi.buf, "nil");
			return;
		}

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
		assert(tag >= 0);

		if v.data == nil {
			strings.write_string(fi.buf, "nil");
		} else if info.no_nil {
			id := info.variants[tag].id;
			fmt_arg(fi, any{v.data, id}, verb);
		} else if tag == 0 {
			strings.write_string(fi.buf, "nil");
		} else {
			id := info.variants[tag-1].id;
			fmt_arg(fi, any{v.data, id}, verb);
		}

	case runtime.Type_Info_Enum:
		fmt_enum(fi, v, verb);

	case runtime.Type_Info_Procedure:
		ptr := (^rawptr)(v.data)^;
		if ptr == nil {
			strings.write_string(fi.buf, "nil");
		} else {
			reflect.write_typeid(fi.buf, v.id);
			strings.write_string(fi.buf, " @ ");
			fmt_pointer(fi, ptr, 'p');
		}

	case runtime.Type_Info_Type_Id:
		id := (^typeid)(v.data)^;
		reflect.write_typeid(fi.buf, id);

	case runtime.Type_Info_Bit_Field:
		fmt_bit_field(fi, v);

	case runtime.Type_Info_Bit_Set:
		fmt_bit_set(fi, v);

	case runtime.Type_Info_Opaque:
		fmt_opaque(fi, v);
	}
}

fmt_complex :: proc(fi: ^Info, c: complex128, bits: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v', 'h', 'H':
		r, i := real(c), imag(c);
		fmt_float(fi, r, bits/2, verb);
		if !fi.plus && i >= 0 {
			strings.write_rune(fi.buf, '+');
		}
		fmt_float(fi, i, bits/2, verb);
		strings.write_rune(fi.buf, 'i');

	case:
		fmt_bad_verb(fi, verb);
		return;
	}
}

fmt_quaternion  :: proc(fi: ^Info, q: quaternion256, bits: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v', 'h', 'H':
		r, i, j, k := real(q), imag(q), jmag(q), kmag(q);

		fmt_float(fi, r, bits/4, verb);

		if !fi.plus && i >= 0 do strings.write_rune(fi.buf, '+');
		fmt_float(fi, i, bits/4, verb);
		strings.write_rune(fi.buf, 'i');

		if !fi.plus && j >= 0 do strings.write_rune(fi.buf, '+');
		fmt_float(fi, j, bits/4, verb);
		strings.write_rune(fi.buf, 'j');

		if !fi.plus && k >= 0 do strings.write_rune(fi.buf, '+');
		fmt_float(fi, k, bits/4, verb);
		strings.write_rune(fi.buf, 'k');

	case:
		fmt_bad_verb(fi, verb);
		return;
	}
}

fmt_arg :: proc(fi: ^Info, arg: any, verb: rune) {
	if arg == nil {
		strings.write_string(fi.buf, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := type_info_of(arg.id);
		switch a in arg {
		case ^runtime.Type_Info: ti = a;
		}
		reflect.write_type(fi.buf, ti);
		return;
	}


	custom_types: switch a in arg {
	case runtime.Source_Code_Location:
		if fi.hash && verb == 'v' {
			strings.write_string(fi.buf, a.file_path);
			strings.write_byte(fi.buf, '(');
			strings.write_i64(fi.buf, i64(a.line), 10);
			strings.write_byte(fi.buf, ':');
			strings.write_i64(fi.buf, i64(a.column), 10);
			strings.write_byte(fi.buf, ')');
			return;
		}
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

	case quaternion128: fmt_quaternion(fi, quaternion256(a), 128, verb);
	case quaternion256: fmt_quaternion(fi, a, 256, verb);

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

	case typeid:  reflect.write_typeid(fi.buf, a);

	case i16le:     fmt_int(fi, u64(a), true,  16, verb);
	case u16le:     fmt_int(fi, u64(a), false, 16, verb);
	case i32le:     fmt_int(fi, u64(a), true,  32, verb);
	case u32le:     fmt_int(fi, u64(a), false, 32, verb);
	case i64le:     fmt_int(fi, u64(a), true,  64, verb);
	case u64le:     fmt_int(fi, u64(a), false, 64, verb);

	case i16be:     fmt_int(fi, u64(a), true,  16, verb);
	case u16be:     fmt_int(fi, u64(a), false, 16, verb);
	case i32be:     fmt_int(fi, u64(a), true,  32, verb);
	case u32be:     fmt_int(fi, u64(a), false, 32, verb);
	case i64be:     fmt_int(fi, u64(a), true,  64, verb);
	case u64be:     fmt_int(fi, u64(a), false, 64, verb);

	case i128:     fmt_int_128(fi, u128(a), true,  128, verb);
	case u128:     fmt_int_128(fi, u128(a), false, 128, verb);

	case i128le:   fmt_int_128(fi, u128(a), true,  128, verb);
	case u128le:   fmt_int_128(fi, u128(a), false, 128, verb);

	case i128be:   fmt_int_128(fi, u128(a), true,  128, verb);
	case u128be:   fmt_int_128(fi, u128(a), false, 128, verb);

	case: fmt_value(fi, arg, verb);
	}

}




