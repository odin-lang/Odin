package fmt

import "core:math/bits"
import "core:mem"
import "core:os"
import "core:io"
import "core:reflect"
import "core:runtime"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"
import "intrinsics"

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

	writer: io.Writer,
	arg: any, // Temporary
	record_level: int,
}

// Custom formatter signature. It returns true if the formatting was successful and false when it could not be done
User_Formatter :: #type proc(fi: ^Info, arg: any, verb: rune) -> bool;

Register_User_Formatter_Error :: enum {
	None,
	No_User_Formatter,
	Formatter_Previously_Found,
}

// NOTE(bill): This is a pointer to prevent accidental additions
// it is prefixed with `_` rather than marked with a private attribute so that users can access it if necessary
_user_formatters: ^map[typeid]User_Formatter;

set_user_formatters :: proc(m: ^map[typeid]User_Formatter) {
	_user_formatters = m;
}
register_user_formatter :: proc(id: typeid, formatter: User_Formatter) -> Register_User_Formatter_Error {
	if _user_formatters == nil {
		return .No_User_Formatter;
	}
	if prev, found := _user_formatters[id]; found && prev != nil {
		return .Formatter_Previously_Found;
	}
	_user_formatters[id] = formatter;
	return .None;
}


fprint :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	w, _ := io.to_writer(os.stream_from_handle(fd));
	return wprint(w=w, args=args, sep=sep);
}

fprintln :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	w, _ := io.to_writer(os.stream_from_handle(fd));
	return wprintln(w=w, args=args, sep=sep);
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	w, _ := io.to_writer(os.stream_from_handle(fd));
	return wprintf(w, fmt, ..args);
}
fprint_type :: proc(fd: os.Handle, info: ^runtime.Type_Info) -> int {
	w, _ := io.to_writer(os.stream_from_handle(fd));
	return wprint_type(w, info);
}
fprint_typeid :: proc(fd: os.Handle, id: typeid) -> int {
	w, _ := io.to_writer(os.stream_from_handle(fd));
	return wprint_typeid(w, id);
}

// print* procedures return the number of bytes written
print   :: proc(args: ..any, sep := " ") -> int { return fprint(fd=os.stdout, args=args, sep=sep); }
println :: proc(args: ..any, sep := " ") -> int { return fprintln(fd=os.stdout, args=args, sep=sep); }
printf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stdout, fmt, ..args); }

eprint   :: proc(args: ..any, sep := " ") -> int { return fprint(fd=os.stderr, args=args, sep=sep); }
eprintln :: proc(args: ..any, sep := " ") -> int { return fprintln(fd=os.stderr, args=args, sep=sep); }
eprintf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stderr, fmt, ..args); }


@(deprecated="prefer eprint")   print_err   :: proc(args: ..any)              -> int { return eprint(..args); }
@(deprecated="prefer eprintf")  printf_err  :: proc(fmt: string, args: ..any) -> int { return eprintf(fmt, ..args); }
@(deprecated="prefer eprintln") println_err :: proc(args: ..any)              -> int { return eprintln(..args); }


// aprint* procedures return a string that was allocated with the current context
// They must be freed accordingly
aprint :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder;
	strings.init_builder(&str);
	sbprint(buf=&str, args=args, sep=sep);
	return strings.to_string(str);
}
aprintln :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder;
	strings.init_builder(&str);
	sbprintln(buf=&str, args=args, sep=sep);
	return strings.to_string(str);
}
aprintf :: proc(fmt: string, args: ..any) -> string {
	str: strings.Builder;
	strings.init_builder(&str);
	sbprintf(&str, fmt, ..args);
	return strings.to_string(str);
}


// tprint* procedures return a string that was allocated with the current context's temporary allocator
tprint :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder;
	strings.init_builder(&str, context.temp_allocator);
	sbprint(buf=&str, args=args, sep=sep);
	return strings.to_string(str);
}
tprintln :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder;
	strings.init_builder(&str, context.temp_allocator);
	sbprintln(buf=&str, args=args, sep=sep);
	return strings.to_string(str);
}
tprintf :: proc(fmt: string, args: ..any) -> string {
	str: strings.Builder;
	strings.init_builder(&str, context.temp_allocator);
	sbprintf(&str, fmt, ..args);
	return strings.to_string(str);
}


// bprint* procedures return a string using a buffer from an array
bprint :: proc(buf: []byte, args: ..any, sep := " ") -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
	return sbprint(buf=&sb, args=args, sep=sep);
}
bprintln :: proc(buf: []byte, args: ..any, sep := " ") -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
	return sbprintln(buf=&sb, args=args, sep=sep);
}
bprintf :: proc(buf: []byte, fmt: string, args: ..any) -> string {
	sb := strings.builder_from_slice(buf[0:len(buf)]);
	return sbprintf(&sb, fmt, ..args);
}


assertf :: proc(condition: bool, fmt: string, args: ..any, loc := #caller_location) -> bool {
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

panicf :: proc(fmt: string, args: ..any, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = runtime.default_assertion_failure_proc;
	}
	message := tprintf(fmt, ..args);
	p("Panic", message, loc);
}





sbprint :: proc(buf: ^strings.Builder, args: ..any, sep := " ") -> string {
	wprint(w=strings.to_writer(buf), args=args, sep=sep);
	return strings.to_string(buf^);
}

sbprintln :: proc(buf: ^strings.Builder, args: ..any, sep := " ") -> string {
	wprintln(w=strings.to_writer(buf), args=args, sep=sep);
	return strings.to_string(buf^);
}

sbprintf :: proc(buf: ^strings.Builder, fmt: string, args: ..any) -> string {
	wprintf(w=strings.to_writer(buf), fmt=fmt, args=args);
	return strings.to_string(buf^);
}


wprint :: proc(w: io.Writer, args: ..any, sep := " ") -> int {
	fi: Info;
	fi.writer = w;

	// NOTE(bill): Old approach
	// prev_string := false;
	// for arg, i in args {
	// 	is_string := arg != nil && reflect.is_string(type_info_of(arg.id));
	// 	if i > 0 && !is_string && !prev_string {
	// 		io.write_byte(writer, ' ');
	// 	}
	// 	fmt_value(&fi, args[i], 'v');
	// 	prev_string = is_string;
	// }
	// NOTE(bill, 2020-06-19): I have found that the previous approach was not what people were expecting
	// and were expecting `*print` to be the same `*println` except for the added newline
	// so I am going to keep the same behaviour as `*println` for `*print`


	size0 := io.size(auto_cast w);

	for _, i in args {
		if i > 0 {
			io.write_string(fi.writer, sep);
		}

		fmt_value(&fi, args[i], 'v');
	}
	io.flush(auto_cast w);

	size1 := io.size(auto_cast w);
	return int(size1 - size0);
}

wprintln :: proc(w: io.Writer, args: ..any, sep := " ") -> int {
	fi: Info;
	fi.writer = w;

	size0 := io.size(auto_cast w);

	for _, i in args {
		if i > 0 {
			io.write_string(fi.writer, sep);
		}

		fmt_value(&fi, args[i], 'v');
	}
	io.write_byte(fi.writer, '\n');
	io.flush(auto_cast w);

	size1 := io.size(auto_cast w);
	return int(size1 - size0);
}

wprintf :: proc(w: io.Writer, fmt: string, args: ..any) -> int {
	fi: Info;
	arg_index: int = 0;
	end := len(fmt);
	was_prev_index := false;

	size0 := io.size(auto_cast w);

	loop: for i := 0; i < end; /**/ {
		fi = Info{writer = w, good_arg_index = true, reordered = fi.reordered};

		prev_i := i;
		for i < end && !(fmt[i] == '%' || fmt[i] == '{' || fmt[i] == '}') {
			i += 1;
		}
		if i > prev_i {
			io.write_string(fi.writer, fmt[prev_i:i]);
		}
		if i >= end {
			break loop;
		}

		char := fmt[i];
		// Process a "char"
		i += 1;

		if char == '}' {
			if i < end && fmt[i] == char {
				// Skip extra one
				i += 1;
			}
			io.write_byte(fi.writer, char);
			continue loop;
		} else if char == '{' {
			if i < end && fmt[i] == char {
				// Skip extra one
				i += 1;
				io.write_byte(fi.writer, char);
				continue loop;
			}
		}

		if char == '%' {
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
					io.write_string(w, "%!(BAD WIDTH)");
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
						io.write_string(fi.writer, "%!(BAD PRECISION)");
					}
					was_prev_index = false;
				} else {
					fi.prec, i, fi.prec_set = _parse_int(fmt, i);
				}
			}

			if !was_prev_index {
				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));
			}

			if i >= end {
				io.write_string(fi.writer, "%!(NO VERB)");
				break loop;
			}

			verb, w := utf8.decode_rune_in_string(fmt[i:]);
			i += w;

			switch {
			case verb == '%':
				io.write_byte(fi.writer, '%');
			case !fi.good_arg_index:
				io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER)");
			case arg_index >= len(args):
				io.write_string(fi.writer, "%!(MISSING ARGUMENT)");
			case:
				fmt_arg(&fi, args[arg_index], verb);
				arg_index += 1;
			}


		} else if char == '{' {
			if i < end && fmt[i] != '}' && fmt[i] != ':' {
				new_arg_index, new_i, ok := _parse_int(fmt, i);
				if ok {
					fi.reordered = true;
					was_prev_index = true;
					arg_index = new_arg_index;
					i = new_i;
				} else {
					io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER ");
					// Skip over the bad argument
					start_index := i;
					for i < end && fmt[i] != '}' && fmt[i] != ':' {
						i += 1;
					}
					fmt_arg(&fi, fmt[start_index:i], 'v');
					io.write_string(fi.writer, ")");
				}
			}

			verb: rune = 'v';

			if i < end && fmt[i] == ':' {
				i += 1;
				prefix_loop_percent: for ; i < end; i += 1 {
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
						break prefix_loop_percent;
					}
				}

				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));

				// Width
				if i < end && fmt[i] == '*' {
					i += 1;
					fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index);
					if !fi.width_set {
						io.write_string(fi.writer, "%!(BAD WIDTH)");
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
							io.write_string(fi.writer, "%!(BAD PRECISION)");
						}
						was_prev_index = false;
					} else {
						fi.prec, i, fi.prec_set = _parse_int(fmt, i);
					}
				}

				if !was_prev_index {
					arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args));
				}


				if i >= end {
					io.write_string(fi.writer, "%!(NO VERB)");
					break loop;
				}

				w: int = 1;
				verb, w = utf8.decode_rune_in_string(fmt[i:]);
				i += w;
			}

			if i >= end {
				io.write_string(fi.writer, "%!(MISSING CLOSE BRACE)");
				break loop;
			}

			brace, w := utf8.decode_rune_in_string(fmt[i:]);
			i += w;

			switch {
			case brace != '}':
				io.write_string(fi.writer, "%!(MISSING CLOSE BRACE)");
			case !fi.good_arg_index:
				io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER)");
			case arg_index >= len(args):
				io.write_string(fi.writer, "%!(MISSING ARGUMENT)");
			case:
				fmt_arg(&fi, args[arg_index], verb);
				arg_index += 1;
			}
		}
	}

	if !fi.reordered && arg_index < len(args) {
		io.write_string(fi.writer, "%!(EXTRA ");
		for arg, index in args[arg_index:] {
			if index > 0 {
				io.write_string(fi.writer, ", ");
			}

			if arg == nil {
				io.write_string(fi.writer, "<nil>");
			} else {
				fmt_arg(&fi, args[index], 'v');
			}
		}
		io.write_string(fi.writer, ")");
	}

	io.flush(auto_cast w);

	size1 := io.size(auto_cast w);
	return int(size1 - size0);
}

wprint_type :: proc(w: io.Writer, info: ^runtime.Type_Info) -> int {
	n := reflect.write_type(w, info);
	io.flush(auto_cast w);
	return n;
}
wprint_typeid :: proc(w: io.Writer, id: typeid) -> int {
	n := reflect.write_type(w, type_info_of(id));
	io.flush(auto_cast w);
	return n;
}




_parse_int :: proc(s: string, offset: int) -> (result: int, new_offset: int, ok: bool) {
	is_digit :: #force_inline proc(r: byte) -> bool { return '0' <= r && r <= '9' }

	new_offset = offset;
	for new_offset <= len(s) {
		c := s[new_offset];
		if !is_digit(c) {
			break;
		}
		new_offset += 1;

		result *= 10;
		result += int(c)-'0';
	}
	ok = new_offset > offset;
	return;
}

_arg_number :: proc(fi: ^Info, arg_index: int, format: string, offset, arg_count: int) -> (index, new_offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if len(format) < 3 {
			return 0, 1, false;
		}

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
		num, ok = reflect.as_int(args[arg_index]);
	}

	if ok {
		new_arg_index += 1;
	}

	return num, new_arg_index, ok;
}


fmt_bad_verb :: proc(using fi: ^Info, verb: rune) {
	io.write_string(writer, "%!");
	io.write_rune(writer, verb);
	io.write_byte(writer, '(');
	if arg.id != nil {
		reflect.write_typeid(writer, arg.id);
		io.write_byte(writer, '=');
		fmt_value(fi, arg, 'v');
	} else {
		io.write_string(writer, "<nil>");
	}
	io.write_byte(writer, ')');
}

fmt_bool :: proc(using fi: ^Info, b: bool, verb: rune) {
	switch verb {
	case 't', 'v':
		io.write_string(writer, b ? "true" : "false");
	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_write_padding :: proc(fi: ^Info, width: int) {
	if width <= 0 {
		return;
	}

	pad_byte: byte = '0';
	if fi.space {
		pad_byte = ' ';
	}

	for i := 0; i < width; i += 1 {
		io.write_byte(fi.writer, pad_byte);
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
	if fi.hash && !fi.zero { flags |= {.Prefix}; }
	if fi.plus             { flags |= {.Plus};   }
	if fi.space            { flags |= {.Space};  }
	s := strconv.append_bits(buf[start:], u, base, is_signed, bit_size, digits, flags);

	if fi.hash && fi.zero && fi.indent == 0 {
		c: byte = 0;
		switch base {
		case 2:  c = 'b';
		case 8:  c = 'o';
		case 12: c = 'z';
		case 16: c = 'x';
		}
		if c != 0 {
			io.write_byte(fi.writer, '0');
			io.write_byte(fi.writer, c);
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
	if fi.hash && !fi.zero { flags |= {.Prefix}; }
	if fi.plus             { flags |= {.Plus};   }
	if fi.space            { flags |= {.Space};  }
	s := strconv.append_bits_128(buf[start:], u, base, is_signed, bit_size, digits, flags);

	if fi.hash && fi.zero && fi.indent == 0 {
		c: byte = 0;
		switch base {
		case 2:  c = 'b';
		case 8:  c = 'o';
		case 12: c = 'z';
		case 16: c = 'x';
		}
		if c != 0 {
			io.write_byte(fi.writer, '0');
			io.write_byte(fi.writer, c);
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
		io.write_rune(fi.writer, r);
	case 'q':
		strings.write_quoted_rune(fi.writer, r);
	case:
		fmt_int(fi, u64(r), false, 32, verb);
	}
}

fmt_int :: proc(fi: ^Info, u: u64, is_signed: bool, bit_size: int, verb: rune) {
	switch verb {
	case 'v': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
	case 'b': _fmt_int(fi, u,  2, is_signed, bit_size, __DIGITS_LOWER);
	case 'o': _fmt_int(fi, u,  8, is_signed, bit_size, __DIGITS_LOWER);
	case 'i', 'd': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
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
			io.write_string(fi.writer, "U+");
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
	case 'i', 'd': _fmt_int_128(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER);
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
			io.write_string(fi.writer, "U+");
			_fmt_int_128(fi, u, 16, false, bit_size, __DIGITS_UPPER);
		}

	case:
		fmt_bad_verb(fi, verb);
	}
}

_pad :: proc(fi: ^Info, s: string) {
	if !fi.width_set {
		io.write_string(fi.writer, s);
		return;
	}


	width := fi.width - utf8.rune_count_in_string(s);
	if fi.minus { // right pad
		io.write_string(fi.writer, s);
		fmt_write_padding(fi, width);
	} else { // left pad
		fmt_write_padding(fi, width);
		io.write_string(fi.writer, s);
	}
}

fmt_float :: proc(fi: ^Info, v: f64, bit_size: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v':
		prec: int = 3;
		if fi.prec_set {
			prec = fi.prec;
		}
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
			io.write_string(fi.writer, string(b));
			return;
		}

		if fi.plus || b[0] != '+' {
			if fi.zero && fi.width_set && fi.width > len(b) {
				io.write_byte(fi.writer, b[0]);
				fmt_write_padding(fi, fi.width - len(b));
				io.write_string(fi.writer, string(b[1:]));
			} else {
				_pad(fi, string(b));
			}
		} else {
			_pad(fi, string(b[1:]));
		}

	case 'e', 'E':
		prec: int = 3;
		if fi.prec_set {
			prec = fi.prec;
		}
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
			io.write_string(fi.writer, string(b));
			return;
		}

		if fi.plus || str[0] != '+' {
			if fi.zero && fi.width_set && fi.width > len(b) {
				io.write_byte(fi.writer, b[0]);
				fmt_write_padding(fi, fi.width - len(b));
				io.write_string(fi.writer, string(b[1:]));
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

		io.write_string(fi.writer, "0h");
		_fmt_int(fi, u, 16, false, bit_size, __DIGITS_LOWER if verb == 'h' else __DIGITS_UPPER);


	case:
		fmt_bad_verb(fi, verb);
	}
}


fmt_string :: proc(fi: ^Info, s: string, verb: rune) {
	switch verb {
	case 's', 'v':
		io.write_string(fi.writer, s);
		if fi.width_set && len(s) < fi.width {
			for _ in 0..<fi.width - len(s) {
				io.write_byte(fi.writer, ' ');
			}
		}

	case 'q': // quoted string
		strings.write_quoted_string(fi.writer, s, '"');

	case 'x', 'X':
		space := fi.space;
		fi.space = false;
		defer fi.space = space;

		for i in 0..<len(s) {
			if i > 0 && space {
				io.write_byte(fi.writer, ' ');
			}
			char_set := __DIGITS_UPPER;
			if verb == 'x' {
				char_set = __DIGITS_LOWER;
			}
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
			io.write_string(fi.writer, "0x");
		}
		_fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER);

	case 'b': _fmt_int(fi, u,  2, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'o': _fmt_int(fi, u,  8, false, 8*size_of(rawptr), __DIGITS_UPPER);
	case 'i', 'd': _fmt_int(fi, u, 10, false, 8*size_of(rawptr), __DIGITS_UPPER);
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

	#partial switch e in type_info.variant {
	case: return "", false;
	case runtime.Type_Info_Enum:
		Enum_Value :: runtime.Type_Info_Enum_Value;

		ev_, ok := reflect.as_i64(val);
		ev := Enum_Value(ev_);

		if ok {
			if len(e.values) == 0 {
				return "", true;
			} else {
				for val, idx in e.values {
					if val == ev {
						return e.names[idx], true;
					}
				}
			}
			return "", false;
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
		io.write_string(fi.writer, "<nil>");
		return;
	}

	type_info := type_info_of(v.id);
	#partial switch e in type_info.variant {
	case: fmt_bad_verb(fi, verb);
	case runtime.Type_Info_Enum:
		switch verb {
		case: fmt_bad_verb(fi, verb);
		case 'i', 'd', 'f':
			fmt_arg(fi, any{v.data, runtime.type_info_base(e.base).id}, verb);
		case 's', 'v':
			str, ok := enum_value_to_string(v);
			if !ok {
				str = "!%(BAD ENUM VALUE)";
			}
			io.write_string(fi.writer, str);
		}
	}
}


stored_enum_value_to_string :: proc(enum_type: ^runtime.Type_Info, ev: runtime.Type_Info_Enum_Value, offset: int = 0) -> (string, bool) {
	et := runtime.type_info_base(enum_type);
	ev := ev;
	ev += runtime.Type_Info_Enum_Value(offset);
	#partial switch e in et.variant {
	case: return "", false;
	case runtime.Type_Info_Enum:
		if reflect.is_string(e.base) {
			for val, idx in e.values {
				if val == ev {
					return e.names[idx], true;
				}
			}
		} else if len(e.values) == 0 {
			return "", true;
		} else {
			for val, idx in e.values {
				if val == ev {
					return e.names[idx], true;
				}
			}
		}
		return "", false;
	}

	return "", false;
}

fmt_bit_set :: proc(fi: ^Info, v: any, name: string = "") {
	is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
		if ti == nil {
			return false;
		}
		t := runtime.type_info_base(ti);
		#partial switch info in t.variant {
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
	#partial switch info in type_info.variant {
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
			if do_byte_swap { x = byte_swap(x); }
			bits = u128(x);
		case 32:
			x := (^u32)(v.data)^;
			if do_byte_swap { x = byte_swap(x); }
			bits = u128(x);
		case 64:
			x := (^u64)(v.data)^;
			if do_byte_swap { x = byte_swap(x); }
			bits = u128(x);
		case 128:
			x := (^u128)(v.data)^;
			if do_byte_swap { x = byte_swap(x); }
			bits = u128(x);
		case: panic("unknown bit_size size");
		}

		et := runtime.type_info_base(info.elem);

		if name != "" {
			io.write_string(fi.writer, name);
		} else {
			reflect.write_type(fi.writer, type_info);
		}
		io.write_byte(fi.writer, '{');
		defer io.write_byte(fi.writer, '}');

		e, is_enum := et.variant.(runtime.Type_Info_Enum);
		commas := 0;
		loop: for i in 0 ..< bit_size {
			if bits & (1<<i) == 0 {
				continue loop;
			}

			if commas > 0 {
				io.write_string(fi.writer, ", ");
			}

			if is_enum {
				for ev, evi in e.values {
					v := u64(ev);
					if v == u64(i) {
						io.write_string(fi.writer, e.names[evi]);
						commas += 1;
						continue loop;
					}
				}
			}
			v := i64(i) + info.lower;
			io.write_i64(fi.writer, v, 10);
			commas += 1;
		}
	}
}

fmt_write_indent :: proc(fi: ^Info) {
	for in 0..<fi.indent {
		io.write_byte(fi.writer, '\t');
	}
}

fmt_write_array :: proc(fi: ^Info, array_data: rawptr, count: int, elem_size: int, elem_id: typeid, verb: rune) {
	io.write_byte(fi.writer, '[');
	defer io.write_byte(fi.writer, ']');

	if fi.hash {
		io.write_byte(fi.writer, '\n');
		defer fmt_write_indent(fi);

		indent := fi.indent;
		fi.indent += 1;
		defer fi.indent = indent;

		for i in 0..<count {
			fmt_write_indent(fi);

			data := uintptr(array_data) + uintptr(i*elem_size);
			fmt_arg(fi, any{rawptr(data), elem_id}, verb);

			io.write_string(fi.writer, ",\n");
		}
	} else {
		for i in 0..<count {
			if i > 0 { io.write_string(fi.writer, ", "); }

			data := uintptr(array_data) + uintptr(i*elem_size);
			fmt_arg(fi, any{rawptr(data), elem_id}, verb);
		}
	}
}

fmt_value :: proc(fi: ^Info, v: any, verb: rune) {
	write_padded_number :: proc(fi: ^Info, i: i64, width: int) {
		n := width-1;
		for x := i; x >= 10; x /= 10 {
			n -= 1;
		}
		for in 0..<n {
			io.write_byte(fi.writer, '0');
		}
		io.write_i64(fi.writer, i, 10);
	}


	if v.data == nil || v.id == nil {
		io.write_string(fi.writer, "<nil>");
		return;
	}

	if _user_formatters != nil {
		formatter := _user_formatters[v.id];
		if formatter != nil {
			if ok := formatter(fi, v, verb); !ok {
				fmt_bad_verb(fi, verb);
			}
			return;
		}
	}

	type_info := type_info_of(v.id);
	switch info in type_info.variant {
	case runtime.Type_Info_Any:   // Ignore
	case runtime.Type_Info_Tuple: // Ignore

	case runtime.Type_Info_Named:
		// Built-in Custom Formatters for core library types
		switch a in v {
		case runtime.Source_Code_Location:
			io.write_string(fi.writer, a.file_path);
			io.write_byte(fi.writer, '(');
			io.write_int(fi.writer, a.line);
			io.write_byte(fi.writer, ':');
			io.write_int(fi.writer, a.column);
			io.write_byte(fi.writer, ')');
			return;

		case time.Duration:
			ffrac :: proc(buf: []byte, v: u64, prec: int) -> (nw: int, nv: u64) {
				v := v;
				w := len(buf);
				print := false;
				for in 0..<prec {
					digit := v % 10;
					print = print || digit != 0;
					if print {
						w -= 1;
						buf[w] = byte(digit) + '0';
					}
					v /= 10;
				}
				if print {
					w -= 1;
					buf[w] = '.';
				}
				return w, v;
			}
			fint :: proc(buf: []byte, v: u64) -> int {
				v := v;
				w := len(buf);
				if v == 0 {
					w -= 1;
					buf[w] = '0';
				} else {
					for v > 0 {
						w -= 1;
						buf[w] = byte(v%10) + '0';
						v /= 10;
					}
				}
				return w;
			}

			buf: [32]byte;
			w := len(buf);
			u := u64(a);
			neg := a < 0;
			if neg {
				u = -u;
			}

			if u < u64(time.Second) {
				prec: int;
				w -= 1;
				buf[w] = 's';
				w -= 1;
				switch {
				case u == 0:
					io.write_string(fi.writer, "0s");
					return;
				case u < u64(time.Microsecond):
					prec = 0;
					buf[w] = 'n';
				case u < u64(time.Millisecond):
					prec = 3;
					// U+00B5 'µ' micro sign == 0xC2 0xB5
					w -= 1; // Need room for two bytes
					copy(buf[w:], "µ");
				case:
					prec = 6;
					buf[w] = 'm';
				}
				w, u = ffrac(buf[:w], u, prec);
				w = fint(buf[:w], u);
			} else {
				w -= 1;
				buf[w] = 's';
				w, u = ffrac(buf[:w], u, 9);
				w = fint(buf[:w], u%60);
				u /= 60;
				if u > 0 {
					w -= 1;
					buf[w] = 'm';
					w = fint(buf[:w], u%60);
					u /= 60;
					if u > 0 {
						w -= 1;
						buf[w] = 'h';
						w = fint(buf[:w], u);
					}
				}
			}

			if neg {
				w -= 1;
				buf[w] = '-';
			}
			io.write_string(fi.writer, string(buf[w:]));
			return;

		case time.Time:
			t := a;
			y, mon, d := time.date(t);
			h, min, s := time.clock(t);
			ns := i64(t._nsec - (t._nsec/1e9 + time.UNIX_TO_ABSOLUTE)*1e9) % 1e9;
			write_padded_number(fi, i64(y), 4);
			io.write_byte(fi.writer, '-');
			write_padded_number(fi, i64(mon), 2);
			io.write_byte(fi.writer, '-');
			write_padded_number(fi, i64(d), 2);
			io.write_byte(fi.writer, ' ');

			write_padded_number(fi, i64(h), 2);
			io.write_byte(fi.writer, ':');
			write_padded_number(fi, i64(min), 2);
			io.write_byte(fi.writer, ':');
			write_padded_number(fi, i64(s), 2);
			io.write_byte(fi.writer, '.');
			write_padded_number(fi, i64(ns), 9);
			io.write_string(fi.writer, " +0000 UTC");
			return;
		}

		#partial switch b in info.base.variant {
		case runtime.Type_Info_Struct:
			if verb != 'v' {
				fmt_bad_verb(fi, verb);
				return;
			}
			if b.is_raw_union {
				io.write_string(fi.writer, info.name);
				io.write_string(fi.writer, "{}");
				return;
			};

			is_soa := b.soa_kind != .None;

			io.write_string(fi.writer, info.name);
			io.write_byte(fi.writer, '[' if is_soa else '{');

			hash   := fi.hash;   defer fi.hash = hash;
			indent := fi.indent; defer fi.indent -= 1;

			// fi.hash = false;
			fi.indent += 1;

			if hash	{
				io.write_byte(fi.writer, '\n');
			}
			defer {
				if hash {
					for in 0..<indent { io.write_byte(fi.writer, '\t'); }
				}
				io.write_byte(fi.writer, ']' if is_soa else '}');
			}

			if is_soa {
				fi.indent += 1;
				defer fi.indent -= 1;

				base_type_name: string;
				if v, ok := b.soa_base_type.variant.(runtime.Type_Info_Named); ok {
					base_type_name = v.name;
				}

				for index in 0..<uintptr(b.soa_len) {
					if !hash && index > 0 { io.write_string(fi.writer, ", "); }

					field_count := -1;

					if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }

					io.write_string(fi.writer, base_type_name);
					io.write_byte(fi.writer, '{');
					defer io.write_byte(fi.writer, '}');

					for name, i in b.names {
						field_count += 1;

						if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }
						if hash {
							fmt_write_indent(fi);
						}

						io.write_string(fi.writer, name);
						io.write_string(fi.writer, " = ");

						t := b.types[i].variant.(runtime.Type_Info_Array).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							io.write_string(fi.writer, "any{}");
						} else {
							data := rawptr(uintptr(v.data) + b.offsets[i] + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}

						if hash { io.write_string(fi.writer, ",\n"); }
					}
				}
			} else {
				field_count := -1;
				for name, i in b.names {
					field_count += 1;

					if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }
					if hash {
						fmt_write_indent(fi);
					}

					io.write_string(fi.writer, name);
					io.write_string(fi.writer, " = ");

					if t := b.types[i]; reflect.is_any(t) {
						io.write_string(fi.writer, "any{}");
					} else {
						data := rawptr(uintptr(v.data) + b.offsets[i]);
						fmt_arg(fi, any{data, t.id}, 'v');
					}

					if hash { io.write_string(fi.writer, ",\n"); }
				}
			}

		case runtime.Type_Info_Bit_Set:
			fmt_bit_set(fi, v);
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
			reflect.write_type(fi.writer, (^^runtime.Type_Info)(v.data)^);
		} else {
			ptr := (^rawptr)(v.data)^;
			if verb != 'p' && info.elem != nil {
				a := any{ptr, info.elem.id};

				elem := runtime.type_info_base(info.elem);
				if elem != nil {
					#partial switch e in elem.variant {
					case runtime.Type_Info_Array,
					     runtime.Type_Info_Slice,
					     runtime.Type_Info_Dynamic_Array,
					     runtime.Type_Info_Map:
						if ptr == nil {
							io.write_string(fi.writer, "<nil>");
							return;
						}
						if fi.record_level < 1 {
						  	fi.record_level += 1;
							defer fi.record_level -= 1;
							io.write_byte(fi.writer, '&');
							fmt_value(fi, a, verb);
							return;
						}

					case runtime.Type_Info_Struct,
					     runtime.Type_Info_Union:
						if ptr == nil {
							io.write_string(fi.writer, "<nil>");
							return;
						}
						if fi.record_level < 1 {
							fi.record_level += 1;
							defer fi.record_level -= 1;
							io.write_byte(fi.writer, '&');
							fmt_value(fi, a, verb);
							return;
						}
					}
				}
			}
			fmt_pointer(fi, ptr, verb);
		}

	case runtime.Type_Info_Array:
		if (verb == 's' || verb == 'q') && reflect.is_byte(info.elem) {
			s := strings.string_from_ptr((^byte)(v.data), info.count);
			fmt_string(fi, s, verb);
		} else {
			fmt_write_array(fi, v.data, info.count, info.elem_size, info.elem.id, verb);
		}

	case runtime.Type_Info_Enumerated_Array:
		if fi.hash {
			io.write_string(fi.writer, "[\n");
			defer {
				io.write_byte(fi.writer, '\n');
				fmt_write_indent(fi);
				io.write_byte(fi.writer, ']');
			}
			indent := fi.indent;
			fi.indent += 1;
			defer fi.indent = indent;

			for i in 0..<info.count {
				fmt_write_indent(fi);

				idx, ok := stored_enum_value_to_string(info.index, info.min_value, i);
				if ok {
					io.write_byte(fi.writer, '.');
					io.write_string(fi.writer, idx);
				} else {
					io.write_i64(fi.writer, i64(info.min_value)+i64(i));
				}
				io.write_string(fi.writer, " = ");

				data := uintptr(v.data) + uintptr(i*info.elem_size);
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);

				io.write_string(fi.writer, ",\n");
			}
		} else {
			io.write_byte(fi.writer, '[');
			defer io.write_byte(fi.writer, ']');
			for i in 0..<info.count {
				if i > 0 { io.write_string(fi.writer, ", "); }

				idx, ok := stored_enum_value_to_string(info.index, info.min_value, i);
				if ok {
					io.write_byte(fi.writer, '.');
					io.write_string(fi.writer, idx);
				} else {
					io.write_i64(fi.writer, i64(info.min_value)+i64(i));
				}
				io.write_string(fi.writer, " = ");

				data := uintptr(v.data) + uintptr(i*info.elem_size);
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
			}
		}

	case runtime.Type_Info_Dynamic_Array:
		array := cast(^mem.Raw_Dynamic_Array)v.data;
		if (verb == 's' || verb == 'q') && reflect.is_byte(info.elem) {
			s := strings.string_from_ptr((^byte)(array.data), array.len);
			fmt_string(fi, s, verb);
		} else if verb == 'p' {
			fmt_pointer(fi, array.data, 'p');
		} else {
			fmt_write_array(fi, array.data, array.len, info.elem_size, info.elem.id, verb);
		}

	case runtime.Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			io.write_string(fi.writer, "intrinsics.x86_mmx<>");
		}
		io.write_byte(fi.writer, '<');
		defer io.write_byte(fi.writer, '>');
		for i in 0..<info.count {
			if i > 0 { io.write_string(fi.writer, ", "); }

			data := uintptr(v.data) + uintptr(i*info.elem_size);
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb);
		}


	case runtime.Type_Info_Slice:
		slice := cast(^mem.Raw_Slice)v.data;
		if (verb == 's' || verb == 'q') && reflect.is_byte(info.elem) {
			s := strings.string_from_ptr((^byte)(slice.data), slice.len);
			fmt_string(fi, s, verb);
		} else if verb == 'p' {
			fmt_pointer(fi, slice.data, 'p');
		} else {
			fmt_write_array(fi, slice.data, slice.len, info.elem_size, info.elem.id, verb);
		}
	case runtime.Type_Info_Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb);
			return;
		}

		io.write_string(fi.writer, "map[");
		defer io.write_byte(fi.writer, ']');

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
				if i > 0 { io.write_string(fi.writer, ", "); }

				data := uintptr(entries.data) + uintptr(i*entry_size);

				key := data + entry_type.offsets[2];
				fmt_arg(&Info{writer = fi.writer}, any{rawptr(key), info.key.id}, 'v');

				io.write_string(fi.writer, "=");

				value := data + entry_type.offsets[3];
				fmt_arg(fi, any{rawptr(value), info.value.id}, 'v');
			}
		}

	case runtime.Type_Info_Struct:
		if info.is_raw_union {
			io.write_string(fi.writer, "(raw_union)");
			return;
		}

		is_soa := info.soa_kind != .None;

		io.write_byte(fi.writer, '[' if is_soa else '{');
		defer io.write_byte(fi.writer, ']' if is_soa else '}');

		fi.indent += 1;  defer fi.indent -= 1;
		hash := fi.hash; defer fi.hash = hash;
		// fi.hash = false;


		if hash	{ io.write_byte(fi.writer, '\n'); }

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
				if !hash && index > 0 { io.write_string(fi.writer, ", "); }

				field_count := -1;

				if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }

				io.write_string(fi.writer, base_type_name);
				io.write_byte(fi.writer, '{');
				defer io.write_byte(fi.writer, '}');

				for i in 0..<actual_field_count {
					name := info.names[i];
					field_count += 1;

					if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }
					if hash {
						fmt_write_indent(fi);
					}

					io.write_string(fi.writer, name);
					io.write_string(fi.writer, " = ");

					if info.soa_kind == .Fixed {
						t := info.types[i].variant.(runtime.Type_Info_Array).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							io.write_string(fi.writer, "any{}");
						} else {
							data := rawptr(uintptr(v.data) + info.offsets[i] + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}
					} else {
						t := info.types[i].variant.(runtime.Type_Info_Pointer).elem;
						t_size := uintptr(t.size);
						if reflect.is_any(t) {
							io.write_string(fi.writer, "any{}");
						} else {
							field_ptr := (^^byte)(uintptr(v.data) + info.offsets[i])^;
							data := rawptr(uintptr(field_ptr) + index*t_size);
							fmt_arg(fi, any{data, t.id}, 'v');
						}
					}

					if hash { io.write_string(fi.writer, ",\n"); }
				}
			}
		} else {
			field_count := -1;
			for name, i in info.names {
				field_count += 1;

				if !hash && field_count > 0 { io.write_string(fi.writer, ", "); }
				if hash {
					fmt_write_indent(fi);
				}

				io.write_string(fi.writer, name);
				io.write_string(fi.writer, " = ");

				if t := info.types[i]; reflect.is_any(t) {
					io.write_string(fi.writer, "any{}");
				} else {
					data := rawptr(uintptr(v.data) + info.offsets[i]);
					fmt_arg(fi, any{data, t.id}, 'v');
				}

				if hash {
					io.write_string(fi.writer, ",\n");
				}
			}
		}


	case runtime.Type_Info_Union:
		if type_info.size == 0 {
			io.write_string(fi.writer, "nil");
			return;
		}


		if reflect.type_info_union_is_pure_maybe(info) {
			if v.data == nil {
				io.write_string(fi.writer, "nil");
			} else {
				id := info.variants[0].id;
				fmt_arg(fi, any{v.data, id}, verb);
			}
			return;
		}

		tag: i64 = -1;
		tag_ptr := uintptr(v.data) + info.tag_offset;
		tag_any := any{rawptr(tag_ptr), info.tag_type.id};

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
			io.write_string(fi.writer, "nil");
		} else if info.no_nil {
			id := info.variants[tag].id;
			fmt_arg(fi, any{v.data, id}, verb);
		} else if tag == 0 {
			io.write_string(fi.writer, "nil");
		} else {
			id := info.variants[tag-1].id;
			fmt_arg(fi, any{v.data, id}, verb);
		}

	case runtime.Type_Info_Enum:
		fmt_enum(fi, v, verb);

	case runtime.Type_Info_Procedure:
		ptr := (^rawptr)(v.data)^;
		if ptr == nil {
			io.write_string(fi.writer, "nil");
		} else {
			reflect.write_typeid(fi.writer, v.id);
			io.write_string(fi.writer, " @ ");
			fmt_pointer(fi, ptr, 'p');
		}

	case runtime.Type_Info_Type_Id:
		id := (^typeid)(v.data)^;
		reflect.write_typeid(fi.writer, id);

	case runtime.Type_Info_Bit_Set:
		fmt_bit_set(fi, v);

	case runtime.Type_Info_Relative_Pointer:
		ptr := reflect.relative_pointer_to_absolute_raw(v.data, info.base_integer.id);
		absolute_ptr := any{ptr, info.pointer.id};

		fmt_value(fi, absolute_ptr, verb);

	case runtime.Type_Info_Relative_Slice:
		ptr := reflect.relative_pointer_to_absolute_raw(v.data, info.base_integer.id);

		if verb == 'p' {
			fmt_pointer(fi, ptr, 'p');
		} else if ptr == nil {
			io.write_string(fi.writer, "[]");
		} else {
			len_ptr := uintptr(v.data) + uintptr(info.base_integer.size);
			len_any := any{rawptr(len_ptr), info.base_integer.id};
			len, _ := reflect.as_int(len_any);
			slice_type := reflect.type_info_base(info.slice).variant.(runtime.Type_Info_Slice);

			io.write_byte(fi.writer, '[');
			defer io.write_byte(fi.writer, ']');

			for i in 0..<len {
				if i > 0 { io.write_string(fi.writer, ", "); }

				data := uintptr(ptr) + uintptr(i*slice_type.elem_size);
				fmt_arg(fi, any{rawptr(data), slice_type.elem.id}, verb);
			}
		}

	}

	handle_relative_pointer :: proc(ptr: ^$T) -> rawptr where intrinsics.type_is_integer(T) {
		if ptr^ == 0 {
			return nil;
		}
		when intrinsics.type_is_unsigned(T) {
			return rawptr(uintptr(ptr) + uintptr(ptr^));
		} else {
			return rawptr(uintptr(ptr) + uintptr(i64(ptr^)));
		}
	}
}

fmt_complex :: proc(fi: ^Info, c: complex128, bits: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v', 'h', 'H':
		r, i := real(c), imag(c);
		fmt_float(fi, r, bits/2, verb);
		if !fi.plus && i >= 0 {
			io.write_rune(fi.writer, '+');
		}
		fmt_float(fi, i, bits/2, verb);
		io.write_rune(fi.writer, 'i');

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

		if !fi.plus && i >= 0 {
			io.write_rune(fi.writer, '+');
		}
		fmt_float(fi, i, bits/4, verb);
		io.write_rune(fi.writer, 'i');

		if !fi.plus && j >= 0 {
			io.write_rune(fi.writer, '+');
		}
		fmt_float(fi, j, bits/4, verb);
		io.write_rune(fi.writer, 'j');

		if !fi.plus && k >= 0 {
			io.write_rune(fi.writer, '+');
		}
		fmt_float(fi, k, bits/4, verb);
		io.write_rune(fi.writer, 'k');

	case:
		fmt_bad_verb(fi, verb);
		return;
	}
}

fmt_arg :: proc(fi: ^Info, arg: any, verb: rune) {
	if arg == nil {
		io.write_string(fi.writer, "<nil>");
		return;
	}
	fi.arg = arg;

	if verb == 'T' {
		ti := type_info_of(arg.id);
		switch a in arg {
		case ^runtime.Type_Info: ti = a;
		}
		reflect.write_type(fi.writer, ti);
		return;
	}

	if _user_formatters != nil {
		formatter := _user_formatters[arg.id];
		if formatter != nil {
			if ok := formatter(fi, arg, verb); !ok {
				fmt_bad_verb(fi, verb);
			}
			return;
		}
	}


	custom_types: switch a in arg {
	case runtime.Source_Code_Location:
		if fi.hash && verb == 'v' {
			io.write_string(fi.writer, a.file_path);
			io.write_byte(fi.writer, '(');
			io.write_i64(fi.writer, i64(a.line), 10);
			io.write_byte(fi.writer, ':');
			io.write_i64(fi.writer, i64(a.column), 10);
			io.write_byte(fi.writer, ')');
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

	case f32le:      fmt_float(fi, f64(a), 32, verb);
	case f64le:      fmt_float(fi, f64(a), 64, verb);

	case f32be:      fmt_float(fi, f64(a), 32, verb);
	case f64be:      fmt_float(fi, f64(a), 64, verb);

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

	case typeid:  reflect.write_typeid(fi.writer, a);

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




