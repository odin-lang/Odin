package fmt

import "core:math/bits"
import "core:mem"
import "core:io"
import "core:reflect"
import "core:runtime"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"
import "core:intrinsics"

// Internal data structure that stores the required information for formatted printing
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
	ignore_user_formatters: bool,
	in_bad: bool,

	writer: io.Writer,
	arg: any, // Temporary
	indirection_level: int,
	record_level: int,

	optional_len: Maybe(int),
	use_nul_termination: bool,

	n: int, // bytes written
}

// Custom formatter signature. It returns true if the formatting was successful and false when it could not be done
User_Formatter :: #type proc(fi: ^Info, arg: any, verb: rune) -> bool

// Example User Formatter:
// SomeType :: struct {
// 	value: int,
// }
// // Custom Formatter for SomeType
// User_Formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
// 	m := cast(^SomeType)arg.data
// 	switch verb {
// 	case 'v', 'd':
// 		fmt.fmt_int(fi, u64(m.value), true, 8 * size_of(SomeType), verb)
// 	case:
// 		return false
// 	}
// 	return true
// }
// main :: proc() {
// 	// Ensure the fmt._user_formatters map is initialized
// 	fmt.set_user_formatters(new(map[typeid]fmt.User_Formatter))
// 	err := fmt.register_user_formatter(type_info_of(SomeType).id, User_Formatter)
// 	assert(err == .None)
// 	// Use the custom formatter
// 	x := SomeType{42}
// 	fmt.println("Custom type value: ", x)
// }

Register_User_Formatter_Error :: enum {
	None,
	No_User_Formatter,
	Formatter_Previously_Found,
}

// NOTE(bill): This is a pointer to prevent accidental additions
// it is prefixed with `_` rather than marked with a private attribute so that users can access it if necessary
_user_formatters: ^map[typeid]User_Formatter

// Sets user-defined formatters for custom print formatting of specific types
//
// Inputs:
// - m: A pointer to a map of typeids to User_Formatter structs.
//
// NOTE: Must be called before using register_user_formatter.
//
set_user_formatters :: proc(m: ^map[typeid]User_Formatter) {
	assert(_user_formatters == nil, "set_user_formatters must not be called more than once.")
    _user_formatters = m
}
// Registers a user-defined formatter for a specific typeid
//
// Inputs:
// - id: The typeid of the custom type.
// - formatter: The User_Formatter function for the custom type.
//
// Returns: A Register_User_Formatter_Error value indicating the success or failure of the operation.
//
// WARNING: set_user_formatters must be called before using this procedure.
//
register_user_formatter :: proc(id: typeid, formatter: User_Formatter) -> Register_User_Formatter_Error {
	if _user_formatters == nil {
		return .No_User_Formatter
	}
	if prev, found := _user_formatters[id]; found && prev != nil {
		return .Formatter_Previously_Found
	}
	_user_formatters[id] = formatter
	return .None
}
// 	Creates a formatted string
//
// 	*Allocates Using Context's Allocator*
//
// 	Inputs:
// 	- args: A variadic list of arguments to be formatted.
// 	- sep: An optional separator string (default is a single space).
//
// 	Returns: A formatted string. 
//
aprint :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder
	strings.builder_init(&str)
	sbprint(&str, ..args, sep=sep)
	return strings.to_string(str)
}
// 	Creates a formatted string with a newline character at the end
//
// 	*Allocates Using Context's Allocator*
//
// 	Inputs:
// 	- args: A variadic list of arguments to be formatted.
// 	- sep: An optional separator string (default is a single space).
//
// 	Returns: A formatted string with a newline character at the end.
//
aprintln :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder
	strings.builder_init(&str)
	sbprintln(&str, ..args, sep=sep)
	return strings.to_string(str)
}
// 	Creates a formatted string using a format string and arguments
//
// 	*Allocates Using Context's Allocator*
//
// 	Inputs:
// 	- fmt: A format string with placeholders for the provided arguments.
// 	- args: A variadic list of arguments to be formatted.
//
// 	Returns: A formatted string. The returned string must be freed accordingly.
//
aprintf :: proc(fmt: string, args: ..any, allocator := context.allocator) -> string {
	str: strings.Builder
	strings.builder_init(&str, allocator)
	sbprintf(&str, fmt, ..args)
	return strings.to_string(str)
}
// 	Creates a formatted string
//
// 	*Allocates Using Context's Temporary Allocator*
//
// 	Inputs:
// 	- args: A variadic list of arguments to be formatted.
// 	- sep: An optional separator string (default is a single space).
//
// 	Returns: A formatted string.
//
tprint :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprint(&str, ..args, sep=sep)
	return strings.to_string(str)
}
// 	Creates a formatted string with a newline character at the end
//
// 	*Allocates Using Context's Temporary Allocator*
//
// 	Inputs:
// 	- args: A variadic list of arguments to be formatted.
// 	- sep: An optional separator string (default is a single space).
//
// 	Returns: A formatted string with a newline character at the end.
//
tprintln :: proc(args: ..any, sep := " ") -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprintln(&str, ..args, sep=sep)
	return strings.to_string(str)
}
// 	Creates a formatted string using a format string and arguments
//
// 	*Allocates Using Context's Temporary Allocator*
//
// 	Inputs:
// 	- fmt: A format string with placeholders for the provided arguments.
// 	- args: A variadic list of arguments to be formatted.
//
// 	Returns: A formatted string.
//
tprintf :: proc(fmt: string, args: ..any) -> string {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprintf(&str, fmt, ..args)
	return strings.to_string(str)
}
// Creates a formatted string using a supplied buffer as the backing array. Writes into the buffer.
//
// Inputs:
// - buf: The backing buffer
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: A formatted string
//
bprint :: proc(buf: []byte, args: ..any, sep := " ") -> string {
	sb := strings.builder_from_bytes(buf[0:len(buf)])
	return sbprint(&sb, ..args, sep=sep)
}
// Creates a formatted string using a supplied buffer as the backing array, appends newline. Writes into the buffer.
//
// Inputs:
// - buf: The backing buffer
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: A formatted string with a newline character at the end
//
bprintln :: proc(buf: []byte, args: ..any, sep := " ") -> string {
	sb := strings.builder_from_bytes(buf[0:len(buf)])
	return sbprintln(&sb, ..args, sep=sep)
}
// Creates a formatted string using a supplied buffer as the backing array. Writes into the buffer.
//
// Inputs:
// - buf: The backing buffer
// - fmt: A format string with placeholders for the provided arguments
// - args: A variadic list of arguments to be formatted
//
// Returns: A formatted string
//
bprintf :: proc(buf: []byte, fmt: string, args: ..any) -> string {
	sb := strings.builder_from_bytes(buf[0:len(buf)])
	return sbprintf(&sb, fmt, ..args)
}
// Runtime assertion with a formatted message
//
// Inputs:
// - condition: The boolean condition to be asserted
// - fmt: A format string with placeholders for the provided arguments
// - args: A variadic list of arguments to be formatted
// - loc: The location of the caller
//
// Returns: True if the condition is met, otherwise triggers a runtime assertion with a formatted message
//
assertf :: proc(condition: bool, fmt: string, args: ..any, loc := #caller_location) -> bool {
	if !condition {
		p := context.assertion_failure_proc
		if p == nil {
			p = runtime.default_assertion_failure_proc
		}
		message := tprintf(fmt, ..args)
		p("Runtime assertion", message, loc)
	}
	return condition
}
// Runtime panic with a formatted message
//
// Inputs:
// - fmt: A format string with placeholders for the provided arguments
// - args: A variadic list of arguments to be formatted
// - loc: The location of the caller
//
panicf :: proc(fmt: string, args: ..any, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = runtime.default_assertion_failure_proc
	}
	message := tprintf(fmt, ..args)
	p("Panic", message, loc)
}
// Creates a formatted C string
//
// *Allocates Using Context's Allocator*
//
// Inputs:
// - format: A format string with placeholders for the provided arguments
// - args: A variadic list of arguments to be formatted
//
// Returns: A formatted C string
//
caprintf :: proc(format: string, args: ..any) -> cstring {
	str: strings.Builder
	strings.builder_init(&str)
	sbprintf(&str, format, ..args)
	strings.write_byte(&str, 0)
	s := strings.to_string(str)
	return cstring(raw_data(s))
}
// Creates a formatted C string
//
// *Allocates Using Context's Temporary Allocator*
//
// Inputs:
// - format: A format string with placeholders for the provided arguments
// - args: A variadic list of arguments to be formatted
//
// Returns: A formatted C string
//
ctprintf :: proc(format: string, args: ..any) -> cstring {
	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	sbprintf(&str, format, ..args)
	strings.write_byte(&str, 0)
	s := strings.to_string(str)
	return cstring(raw_data(s))
}
// Formats using the default print settings and writes to the given strings.Builder
//
// Inputs:
// - buf: A pointer to a strings.Builder to store the formatted string
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: A formatted string
//
sbprint :: proc(buf: ^strings.Builder, args: ..any, sep := " ") -> string {
	wprint(strings.to_writer(buf), ..args, sep=sep, flush=true)
	return strings.to_string(buf^)
}
// Formats and writes to a strings.Builder buffer using the default print settings
//
// Inputs:
// - buf: A pointer to a strings.Builder buffer
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: The resulting formatted string
//
sbprintln :: proc(buf: ^strings.Builder, args: ..any, sep := " ") -> string {
	wprintln(strings.to_writer(buf), ..args, sep=sep, flush=true)
	return strings.to_string(buf^)
}
// Formats and writes to a strings.Builder buffer according to the specified format string
//
// Inputs:
// - buf: A pointer to a strings.Builder buffer
// - fmt: The format string
// - args: A variadic list of arguments to be formatted
//
// Returns: The resulting formatted string
//
sbprintf :: proc(buf: ^strings.Builder, fmt: string, args: ..any) -> string {
	wprintf(strings.to_writer(buf), fmt, ..args, flush=true)
	return strings.to_string(buf^)
}
// Formats and writes to an io.Writer using the default print settings
//
// Inputs:
// - w: An io.Writer to write to
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: The number of bytes written
//
wprint :: proc(w: io.Writer, args: ..any, sep := " ", flush := true) -> int {
	fi: Info
	fi.writer = w

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


	for _, i in args {
		if i > 0 {
			io.write_string(fi.writer, sep, &fi.n)
		}

		fmt_value(&fi, args[i], 'v')
	}
	if flush {
		io.flush(w)
	}

	return fi.n
}
// Formats and writes to an io.Writer using the default print settings with a newline character at the end
//
// Inputs:
// - w: An io.Writer to write to
// - args: A variadic list of arguments to be formatted
// - sep: An optional separator string (default is a single space)
//
// Returns: The number of bytes written
//
wprintln :: proc(w: io.Writer, args: ..any, sep := " ", flush := true) -> int {
	fi: Info
	fi.writer = w

	for _, i in args {
		if i > 0 {
			io.write_string(fi.writer, sep, &fi.n)
		}

		fmt_value(&fi, args[i], 'v')
	}
	io.write_byte(fi.writer, '\n', &fi.n)
	if flush {
		io.flush(w)
	}
	return fi.n
}
// Formats and writes to an io.Writer according to the specified format string
//
// Inputs:
// - w: An io.Writer to write to
// - fmt: The format string
// - args: A variadic list of arguments to be formatted
//
// Returns: The number of bytes written
//
wprintf :: proc(w: io.Writer, fmt: string, args: ..any, flush := true) -> int {
	fi: Info
	arg_index: int = 0
	end := len(fmt)
	was_prev_index := false

	loop: for i := 0; i < end; /**/ {
		fi = Info{writer = w, good_arg_index = true, reordered = fi.reordered, n = fi.n}

		prev_i := i
		for i < end && !(fmt[i] == '%' || fmt[i] == '{' || fmt[i] == '}') {
			i += 1
		}
		if i > prev_i {
			io.write_string(fi.writer, fmt[prev_i:i], &fi.n)
		}
		if i >= end {
			break loop
		}

		char := fmt[i]
		// Process a "char"
		i += 1

		if char == '}' {
			if i < end && fmt[i] == char {
				// Skip extra one
				i += 1
			}
			io.write_byte(fi.writer, char, &fi.n)
			continue loop
		} else if char == '{' {
			if i < end && fmt[i] == char {
				// Skip extra one
				i += 1
				io.write_byte(fi.writer, char, &fi.n)
				continue loop
			}
		}

		if char == '%' {
			prefix_loop: for ; i < end; i += 1 {
				switch fmt[i] {
				case '+':
					fi.plus = true
				case '-':
					fi.minus = true
					fi.zero = false
				case ' ':
					fi.space = true
				case '#':
					fi.hash = true
				case '0':
					fi.zero = !fi.minus
				case:
					break prefix_loop
				}
			}

			arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))

			// Width
			if i < end && fmt[i] == '*' {
				i += 1
				fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index)
				if !fi.width_set {
					io.write_string(w, "%!(BAD WIDTH)", &fi.n)
				}

				if fi.width < 0 {
					fi.width = -fi.width
					fi.minus = true
					fi.zero  = false
				}
				was_prev_index = false
			} else {
				fi.width, i, fi.width_set = _parse_int(fmt, i)
				if was_prev_index && fi.width_set { // %[6]2d
					fi.good_arg_index = false
				}
			}

			// Precision
			if i < end && fmt[i] == '.' {
				i += 1
				if was_prev_index { // %[6].2d
					fi.good_arg_index = false
				}
				if i < end && fmt[i] == '*' {
					arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))
					i += 1
					fi.prec, arg_index, fi.prec_set = int_from_arg(args, arg_index)
					if fi.prec < 0 {
						fi.prec = 0
						fi.prec_set = false
					}
					if !fi.prec_set {
						io.write_string(fi.writer, "%!(BAD PRECISION)", &fi.n)
					}
					was_prev_index = false
				} else {
					fi.prec, i, fi.prec_set = _parse_int(fmt, i)
				}
			}

			if !was_prev_index {
				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))
			}

			if i >= end {
				io.write_string(fi.writer, "%!(NO VERB)", &fi.n)
				break loop
			}

			verb, w := utf8.decode_rune_in_string(fmt[i:])
			i += w

			switch {
			case verb == '%':
				io.write_byte(fi.writer, '%', &fi.n)
			case !fi.good_arg_index:
				io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER)", &fi.n)
			case arg_index >= len(args):
				io.write_string(fi.writer, "%!(MISSING ARGUMENT)", &fi.n)
			case:
				fmt_arg(&fi, args[arg_index], verb)
				arg_index += 1
			}


		} else if char == '{' {
			if i < end && fmt[i] != '}' && fmt[i] != ':' {
				new_arg_index, new_i, ok := _parse_int(fmt, i)
				if ok {
					fi.reordered = true
					was_prev_index = true
					arg_index = new_arg_index
					i = new_i
				} else {
					io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER ", &fi.n)
					// Skip over the bad argument
					start_index := i
					for i < end && fmt[i] != '}' && fmt[i] != ':' {
						i += 1
					}
					fmt_arg(&fi, fmt[start_index:i], 'v')
					io.write_string(fi.writer, ")", &fi.n)
				}
			}

			verb: rune = 'v'

			if i < end && fmt[i] == ':' {
				i += 1
				prefix_loop_percent: for ; i < end; i += 1 {
					switch fmt[i] {
					case '+':
						fi.plus = true
					case '-':
						fi.minus = true
						fi.zero = false
					case ' ':
						fi.space = true
					case '#':
						fi.hash = true
					case '0':
						fi.zero = !fi.minus
					case:
						break prefix_loop_percent
					}
				}

				arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))

				// Width
				if i < end && fmt[i] == '*' {
					i += 1
					fi.width, arg_index, fi.width_set = int_from_arg(args, arg_index)
					if !fi.width_set {
						io.write_string(fi.writer, "%!(BAD WIDTH)", &fi.n)
					}

					if fi.width < 0 {
						fi.width = -fi.width
						fi.minus = true
						fi.zero  = false
					}
					was_prev_index = false
				} else {
					fi.width, i, fi.width_set = _parse_int(fmt, i)
					if was_prev_index && fi.width_set { // %[6]2d
						fi.good_arg_index = false
					}
				}

				// Precision
				if i < end && fmt[i] == '.' {
					i += 1
					if was_prev_index { // %[6].2d
						fi.good_arg_index = false
					}
					if i < end && fmt[i] == '*' {
						arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))
						i += 1
						fi.prec, arg_index, fi.prec_set = int_from_arg(args, arg_index)
						if fi.prec < 0 {
							fi.prec = 0
							fi.prec_set = false
						}
						if !fi.prec_set {
							io.write_string(fi.writer, "%!(BAD PRECISION)", &fi.n)
						}
						was_prev_index = false
					} else {
						fi.prec, i, fi.prec_set = _parse_int(fmt, i)
					}
				}

				if !was_prev_index {
					arg_index, i, was_prev_index = _arg_number(&fi, arg_index, fmt, i, len(args))
				}


				if i >= end {
					io.write_string(fi.writer, "%!(NO VERB)", &fi.n)
					break loop
				}

				w: int = 1
				verb, w = utf8.decode_rune_in_string(fmt[i:])
				i += w
			}

			if i >= end {
				io.write_string(fi.writer, "%!(MISSING CLOSE BRACE)", &fi.n)
				break loop
			}

			brace, w := utf8.decode_rune_in_string(fmt[i:])
			i += w

			switch {
			case brace != '}':
				io.write_string(fi.writer, "%!(MISSING CLOSE BRACE)", &fi.n)
			case !fi.good_arg_index:
				io.write_string(fi.writer, "%!(BAD ARGUMENT NUMBER)", &fi.n)
			case arg_index >= len(args):
				io.write_string(fi.writer, "%!(MISSING ARGUMENT)", &fi.n)
			case:
				fmt_arg(&fi, args[arg_index], verb)
				arg_index += 1
			}
		}
	}

	if !fi.reordered && arg_index < len(args) {
		io.write_string(fi.writer, "%!(EXTRA ", &fi.n)
		for arg, index in args[arg_index:] {
			if index > 0 {
				io.write_string(fi.writer, ", ", &fi.n)
			}

			if arg == nil {
				io.write_string(fi.writer, "<nil>", &fi.n)
			} else {
				fmt_arg(&fi, args[index], 'v')
			}
		}
		io.write_string(fi.writer, ")", &fi.n)
	}
	if flush {
		io.flush(w)
	}

	return fi.n
}
// Writes a ^runtime.Type_Info value to an io.Writer
//
// Inputs:
// - w: An io.Writer to write to
// - info: A pointer to a runtime.Type_Info value
//
// Returns: The number of bytes written and an io.Error if encountered
//
wprint_type :: proc(w: io.Writer, info: ^runtime.Type_Info, flush := true) -> (int, io.Error) {
	n, err := reflect.write_type(w, info)
	if flush {
		io.flush(w)
	}
	return n, err
}
// Writes a typeid value to an io.Writer
//
// Inputs:
// - w: An io.Writer to write to
// - id: A typeid value
//
// Returns: The number of bytes written and an io.Error if encountered
//
wprint_typeid :: proc(w: io.Writer, id: typeid, flush := true) -> (int, io.Error) {
	n, err := reflect.write_type(w, type_info_of(id))
	if flush {
		io.flush(w)
	}
	return n, err
}
// Parses an integer from a given string starting at a specified offset
//
// Inputs:
// - s: The string to parse the integer from
// - offset: The position in the string to start parsing the integer
//
// Returns:
// - result: The parsed integer
// - new_offset: The position in the string after parsing the integer
// - ok: A boolean indicating if the parsing was successful
//
_parse_int :: proc(s: string, offset: int) -> (result: int, new_offset: int, ok: bool) {
	is_digit :: #force_inline proc(r: byte) -> bool { return '0' <= r && r <= '9' }

	new_offset = offset
	for new_offset < len(s) {
		c := s[new_offset]
		is_digit(c) or_break

		new_offset += 1

		result *= 10
		result += int(c)-'0'
	}
	ok = new_offset > offset
	return
}
// Parses an argument number from a format string and determines if it's valid
//
// Inputs:
// - fi: A pointer to an Info structure
// - arg_index: The current argument index
// - format: The format string to parse
// - offset: The current position in the format string
// - arg_count: The total number of arguments
//
// Returns:
// - index: The parsed argument index
// - new_offset: The new position in the format string
// - ok: A boolean indicating if the parsed argument number is valid
//
_arg_number :: proc(fi: ^Info, arg_index: int, format: string, offset, arg_count: int) -> (index, new_offset: int, ok: bool) {
	parse_arg_number :: proc(format: string) -> (int, int, bool) {
		if len(format) < 3 {
			return 0, 1, false
		}

		for i in 1..<len(format) {
			if format[i] == ']' {
				width, new_index, ok := _parse_int(format, 1)
				if !ok || new_index != i {
					return 0, i+1, false
				}
				return width-1, i+1, true
			}
		}

		return 0, 1, false
	}


	if len(format) <= offset || format[offset] != '[' {
		return arg_index, offset, false
	}
	fi.reordered = true

	width: int
	index, width, ok = parse_arg_number(format[offset:])
	if ok && 0 <= index && index < arg_count {
		return index, offset+width, true
	}
	fi.good_arg_index = false
	return arg_index, offset+width, false
}
// Retrieves an integer from a list of any type at the specified index
//
// Inputs:
// - args: A list of values of any type
// - arg_index: The index to retrieve the integer from
//
// Returns:
// - int: The integer value at the specified index
// - new_arg_index: The new argument index
// - ok: A boolean indicating if the conversion to integer was successful
//
int_from_arg :: proc(args: []any, arg_index: int) -> (int, int, bool) {
	num := 0
	new_arg_index := arg_index
	ok := true
	if arg_index < len(args) {
		num, ok = reflect.as_int(args[arg_index])
	}

	if ok {
		new_arg_index += 1
	}

	return num, new_arg_index, ok
}
// Writes a bad verb error message
//
// Inputs:
// - fi: A pointer to an Info structure
// - verb: The invalid format verb
//
fmt_bad_verb :: proc(fi: ^Info, verb: rune) {
	prev_in_bad := fi.in_bad
	defer fi.in_bad = prev_in_bad
	fi.in_bad = true

	io.write_string(fi.writer, "%!", &fi.n)
	io.write_rune(fi.writer, verb, &fi.n)
	io.write_byte(fi.writer, '(', &fi.n)
	if fi.arg.id != nil {
		reflect.write_typeid(fi.writer, fi.arg.id, &fi.n)
		io.write_byte(fi.writer, '=', &fi.n)
		fmt_value(fi, fi.arg, 'v')
	} else {
		io.write_string(fi.writer, "<nil>", &fi.n)
	}
	io.write_byte(fi.writer, ')', &fi.n)
}
// Formats a boolean value according to the specified format verb
//
// Inputs:
// - fi: A pointer to an Info structure
// - b: The boolean value to format
// - verb: The format verb
//
fmt_bool :: proc(fi: ^Info, b: bool, verb: rune) {
	switch verb {
	case 't', 'v':
		fmt_string(fi, b ? "true" : "false", 's')
	case:
		fmt_bad_verb(fi, verb)
	}
}
// Writes padding characters for formatting
//
// Inputs:
// - fi: A pointer to an Info structure
// - width: The number of padding characters to write
//
fmt_write_padding :: proc(fi: ^Info, width: int) {
	if width <= 0 {
		return
	}

	pad_byte: byte = ' '
	if !fi.space {
		pad_byte = '0'
	}

	for i := 0; i < width; i += 1 {
		io.write_byte(fi.writer, pad_byte, &fi.n)
	}
}
// Formats an integer value with specified base, sign, bit size, and digits
//
// Inputs:
// - fi: A pointer to an Info structure
// - u: The integer value to format
// - base: The base for integer formatting
// - is_signed: A boolean indicating if the integer is signed
// - bit_size: The bit size of the integer
// - digits: A string containing the digits for formatting
//
// WARNING: May panic if the width and precision are too big, causing a buffer overrun
//
_fmt_int :: proc(fi: ^Info, u: u64, base: int, is_signed: bool, bit_size: int, digits: string) {
	_, neg := strconv.is_integer_negative(u, is_signed, bit_size)

	BUF_SIZE :: 256
	if fi.width_set || fi.prec_set {
		width := fi.width + fi.prec + 3 // 3 extra bytes for sign and prefix
		if width > BUF_SIZE {
			// TODO(bill):????
			panic("_fmt_int: buffer overrun. Width and precision too big")
		}
	}

	prec := 0
	if fi.prec_set {
		prec = fi.prec
		if prec == 0 && u == 0 {
			prev_zero := fi.zero
			fi.zero = false
			fmt_write_padding(fi, fi.width)
			fi.zero = prev_zero
			return
		}
	} else if fi.zero && fi.width_set {
		prec = fi.width
		if neg || fi.plus {
			// There needs to be space for the "sign"
			prec -= 1
		}
	}

	switch base {
	case 2, 8, 10, 12, 16:
		break
	case:
		panic("_fmt_int: unknown base, whoops")
	}

	buf: [256]byte
	start := 0

	flags: strconv.Int_Flags
	if fi.hash && !fi.zero { flags |= {.Prefix} }
	if fi.plus             { flags |= {.Plus}   }
	s := strconv.append_bits(buf[start:], u, base, is_signed, bit_size, digits, flags)

	if fi.hash && fi.zero && fi.indent == 0 {
		c: byte = 0
		switch base {
		case 2:  c = 'b'
		case 8:  c = 'o'
		case 12: c = 'z'
		case 16: c = 'x'
		}
		if c != 0 {
			io.write_byte(fi.writer, '0', &fi.n)
			io.write_byte(fi.writer, c, &fi.n)
		}
	}

	prev_zero := fi.zero
	defer fi.zero = prev_zero
	fi.zero = false
	_pad(fi, s)
}
// Formats an int128 value based on the provided formatting options.
//
// Inputs:
// - fi: A pointer to the Info struct containing formatting options.
// - u: The int128 value to be formatted.
// - base: The base to be used for formatting the integer (e.g. 2, 8, 10, 12, 16).
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 64, 128).
// - digits: A string containing the digit characters to use for the formatted integer.
//
// WARNING: Panics if the formatting options result in a buffer overrun.
//
_fmt_int_128 :: proc(fi: ^Info, u: u128, base: int, is_signed: bool, bit_size: int, digits: string) {
	_, neg := strconv.is_integer_negative_128(u, is_signed, bit_size)

	BUF_SIZE :: 256
	if fi.width_set || fi.prec_set {
		width := fi.width + fi.prec + 3 // 3 extra bytes for sign and prefix
		if width > BUF_SIZE {
			// TODO(bill):????
			panic("_fmt_int: buffer overrun. Width and precision too big")
		}
	}

	prec := 0
	if fi.prec_set {
		prec = fi.prec
		if prec == 0 && u == 0 {
			prev_zero := fi.zero
			fi.zero = false
			fmt_write_padding(fi, fi.width)
			fi.zero = prev_zero
			return
		}
	} else if fi.zero && fi.width_set {
		prec = fi.width
		if neg || fi.plus {
			// There needs to be space for the "sign"
			prec -= 1
		}
	}

	switch base {
	case 2, 8, 10, 12, 16:
		break
	case:
		panic("_fmt_int: unknown base, whoops")
	}

	buf: [256]byte
	start := 0

	flags: strconv.Int_Flags
	if fi.hash && !fi.zero { flags |= {.Prefix} }
	if fi.plus             { flags |= {.Plus}   }
	s := strconv.append_bits_128(buf[start:], u, base, is_signed, bit_size, digits, flags)

	if fi.hash && fi.zero && fi.indent == 0 {
		c: byte = 0
		switch base {
		case 2:  c = 'b'
		case 8:  c = 'o'
		case 12: c = 'z'
		case 16: c = 'x'
		}
		if c != 0 {
			io.write_byte(fi.writer, '0', &fi.n)
			io.write_byte(fi.writer, c, &fi.n)
		}
	}

	prev_zero := fi.zero
	defer fi.zero = prev_zero
	fi.zero = false
	_pad(fi, s)
}
// Units of measurements:
__MEMORY_LOWER := " b kib mib gib tib pib eib"
__MEMORY_UPPER := " B KiB MiB GiB TiB PiB EiB"
// Formats an integer value as bytes with the best representation.
//
// Inputs:
// - fi: A pointer to an Info structure
// - u: The integer value to format
// - is_signed: A boolean indicating if the integer is signed
// - bit_size: The bit size of the integer
// - digits: A string containing the digits for formatting
//
_fmt_memory :: proc(fi: ^Info, u: u64, is_signed: bool, bit_size: int, units: string) {
	abs, neg := strconv.is_integer_negative(u, is_signed, bit_size)

	// Default to a precision of 2, but if less than a kb, 0
	prec := fi.prec if (fi.prec_set || abs < mem.Kilobyte) else 2

	div, off, unit_len := 1, 0, 1
	for n := abs; n >= mem.Kilobyte; n /= mem.Kilobyte {
		div *= mem.Kilobyte
		off += 4

		// First iteration is slightly different because you go from
		// units of length 1 to units of length 2.
		if unit_len == 1 {
			off = 2
			unit_len  = 3
		}
	}

	// If hash, we add a space between the value and the suffix.
	if fi.hash {
		unit_len += 1
	} else {
		off += 1
	}

	amt := f64(abs) / f64(div)
	if neg {
		amt = -amt
	}

	buf: [256]byte
	str := strconv.append_float(buf[:], amt, 'f', prec, 64)

	// Add the unit at the end.
	copy(buf[len(str):], units[off:off+unit_len])
	str = string(buf[:len(str)+unit_len])
	 
	 if !fi.plus {
	 	// Strip sign from "+<value>" but not "+Inf".
	 	if str[0] == '+' && str[1] != 'I' {
			str = str[1:] 
		}
	}

	_pad(fi, str)
}
// Hex Values:
__DIGITS_LOWER := "0123456789abcdefx"
__DIGITS_UPPER := "0123456789ABCDEFX"
// Formats a rune value according to the specified formatting verb.
//
// Inputs:
// - fi: A pointer to the Info struct containing formatting options.
// - r: The rune value to be formatted.
// - verb: The formatting verb to use (e.g. 'c', 'r', 'v', 'q').
//
fmt_rune :: proc(fi: ^Info, r: rune, verb: rune) {
	switch verb {
	case 'c', 'r', 'v':
		io.write_rune(fi.writer, r, &fi.n)
	case 'q':
		fi.n += io.write_quoted_rune(fi.writer, r)
	case:
		fmt_int(fi, u64(r), false, 32, verb)
	}
}
// Formats an integer value according to the specified formatting verb.
//
// Inputs:
// - fi: A pointer to the Info struct containing formatting options.
// - u: The integer value to be formatted.
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 32, 64).
// - verb: The formatting verb to use (e.g. 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X', 'c', 'r', 'U').
//
fmt_int :: proc(fi: ^Info, u: u64, is_signed: bool, bit_size: int, verb: rune) {
	switch verb {
	case 'v': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER)
	case 'b': _fmt_int(fi, u,  2, is_signed, bit_size, __DIGITS_LOWER)
	case 'o': _fmt_int(fi, u,  8, is_signed, bit_size, __DIGITS_LOWER)
	case 'i', 'd': _fmt_int(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER)
	case 'z': _fmt_int(fi, u, 12, is_signed, bit_size, __DIGITS_LOWER)
	case 'x': _fmt_int(fi, u, 16, is_signed, bit_size, __DIGITS_LOWER)
	case 'X': _fmt_int(fi, u, 16, is_signed, bit_size, __DIGITS_UPPER)
	case 'c', 'r':
		fmt_rune(fi, rune(u), verb)
	case 'U':
		r := rune(u)
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb)
		} else {
			io.write_string(fi.writer, "U+", &fi.n)
			_fmt_int(fi, u, 16, false, bit_size, __DIGITS_UPPER)
		}
	case 'm': _fmt_memory(fi, u, is_signed, bit_size, __MEMORY_LOWER)
	case 'M': _fmt_memory(fi, u, is_signed, bit_size, __MEMORY_UPPER)

	case:
		fmt_bad_verb(fi, verb)
	}
}
// Formats an int128 value according to the specified formatting verb.
//
// Inputs:
// - fi: A pointer to the Info struct containing formatting options.
// - u: The int128 value to be formatted.
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 64, 128).
// - verb: The formatting verb to use (e.g. 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X', 'c', 'r', 'U').
//
fmt_int_128 :: proc(fi: ^Info, u: u128, is_signed: bool, bit_size: int, verb: rune) {
	switch verb {
	case 'v': _fmt_int_128(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER)
	case 'b': _fmt_int_128(fi, u,  2, is_signed, bit_size, __DIGITS_LOWER)
	case 'o': _fmt_int_128(fi, u,  8, is_signed, bit_size, __DIGITS_LOWER)
	case 'i', 'd': _fmt_int_128(fi, u, 10, is_signed, bit_size, __DIGITS_LOWER)
	case 'z': _fmt_int_128(fi, u, 12, is_signed, bit_size, __DIGITS_LOWER)
	case 'x': _fmt_int_128(fi, u, 16, is_signed, bit_size, __DIGITS_LOWER)
	case 'X': _fmt_int_128(fi, u, 16, is_signed, bit_size, __DIGITS_UPPER)
	case 'c', 'r':
		fmt_rune(fi, rune(u), verb)
	case 'U':
		r := rune(u)
		if r < 0 || r > utf8.MAX_RUNE {
			fmt_bad_verb(fi, verb)
		} else {
			io.write_string(fi.writer, "U+", &fi.n)
			_fmt_int_128(fi, u, 16, false, bit_size, __DIGITS_UPPER)
		}

	case:
		fmt_bad_verb(fi, verb)
	}
}
// Pads a formatted string with the appropriate padding, based on the provided formatting options.
//
// Inputs:
// - fi: A pointer to the Info struct containing formatting options.
// - s: The string to be padded.
//
_pad :: proc(fi: ^Info, s: string) {
	if !fi.width_set {
		io.write_string(fi.writer, s, &fi.n)
		return
	}


	width := fi.width - utf8.rune_count_in_string(s)
	if fi.minus { // right pad
		io.write_string(fi.writer, s, &fi.n)
		fmt_write_padding(fi, width)
	} else if !fi.space && s != "" && s[0] == '-' {
		// left pad accounting for zero pad of negative number
		io.write_byte(fi.writer, '-', &fi.n)
		fmt_write_padding(fi, width)
		io.write_string(fi.writer, s[1:], &fi.n)
	} else { // left pad
		fmt_write_padding(fi, width)
		io.write_string(fi.writer, s, &fi.n)
	}
}
// Formats a floating-point number with a specific format and precision.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - v: The floating-point number to format.
// - bit_size: The size of the floating-point number in bits (16, 32, or 64).
// - verb: The format specifier character.
// - float_fmt: The byte format used for formatting the float (either 'f' or 'e').
//
// NOTE: Can return "NaN", "+Inf", "-Inf", "+<value>", or "-<value>".
//
_fmt_float_as :: proc(fi: ^Info, v: f64, bit_size: int, verb: rune, float_fmt: byte) {
	prec := fi.prec if fi.prec_set else 3
	buf: [386]byte

	// Can return "NaN", "+Inf", "-Inf", "+<value>", "-<value>".
	str := strconv.append_float(buf[:], v, float_fmt, prec, bit_size)

	if !fi.plus {
		// Strip sign from "+<value>" but not "+Inf".
		if str[0] == '+' && str[1] != 'I' {
			str = str[1:] 
		}
	}

	_pad(fi, str)
}
// Formats a floating-point number with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - v: The floating-point number to format.
// - bit_size: The size of the floating-point number in bits (16, 32, or 64).
// - verb: The format specifier character.
//
fmt_float :: proc(fi: ^Info, v: f64, bit_size: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'g', 'G', 'v':
		_fmt_float_as(fi, v, bit_size, verb, 'f')
	case 'e', 'E':
		// BUG(): "%.3e" returns "3.000e+00"
		_fmt_float_as(fi, v, bit_size, verb, 'e')

	case 'h', 'H':
		prev_fi := fi^
		defer fi^ = prev_fi
		fi.hash = false
		fi.width = bit_size
		fi.zero = true
		fi.plus = false

		u: u64
		switch bit_size {
		case 16: u = u64(transmute(u16)f16(v))
		case 32: u = u64(transmute(u32)f32(v))
		case 64: u = transmute(u64)v
		case: panic("Unhandled float size")
		}

		io.write_string(fi.writer, "0h", &fi.n)
		_fmt_int(fi, u, 16, false, bit_size, __DIGITS_LOWER if verb == 'h' else __DIGITS_UPPER)


	case:
		fmt_bad_verb(fi, verb)
	}
}
// Formats a string with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - s: The string to format.
// - verb: The format specifier character (e.g. 's', 'v', 'q', 'x', 'X').
//
fmt_string :: proc(fi: ^Info, s: string, verb: rune) {
	s, verb := s, verb
	if ol, ok := fi.optional_len.?; ok {
		s = s[:clamp(ol, 0, len(s))]
	}
	if !fi.in_bad && fi.record_level > 0 && verb == 'v' {
		verb = 'q'
	}

	switch verb {
	case 's', 'v':
		if fi.width_set {
			if fi.width > len(s) {
				if fi.minus {
					io.write_string(fi.writer, s, &fi.n)
				}

				for _ in 0..<fi.width - len(s) {
					io.write_byte(fi.writer, ' ', &fi.n)
				}

				if !fi.minus {
					io.write_string(fi.writer, s, &fi.n)
				}
			}
			else {
				io.write_string(fi.writer, s, &fi.n)
			}
		}
		else
		{
			io.write_string(fi.writer, s, &fi.n)
		}

	case 'q': // quoted string
		io.write_quoted_string(fi.writer, s, '"', &fi.n)

	case 'x', 'X':
		space := fi.space
		fi.space = false
		defer fi.space = space

		for i in 0..<len(s) {
			if i > 0 && space {
				io.write_byte(fi.writer, ' ', &fi.n)
			}
			char_set := __DIGITS_UPPER
			if verb == 'x' {
				char_set = __DIGITS_LOWER
			}
			_fmt_int(fi, u64(s[i]), 16, false, 8, char_set)
		}

	case:
		fmt_bad_verb(fi, verb)
	}
}
// Formats a C-style string with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - s: The C-style string to format.
// - verb: The format specifier character (Ref fmt_string).
//
fmt_cstring :: proc(fi: ^Info, s: cstring, verb: rune) {
	fmt_string(fi, string(s), verb)
}
// Formats a raw pointer with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - p: The raw pointer to format.
// - verb: The format specifier character (e.g. 'p', 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X').
//
fmt_pointer :: proc(fi: ^Info, p: rawptr, verb: rune) {
	u := u64(uintptr(p))
	switch verb {
	case 'p', 'v':
		if !fi.hash && verb == 'v' {
			io.write_string(fi.writer, "0x", &fi.n)
		}
		_fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER)

	case 'b': _fmt_int(fi, u,  2, false, 8*size_of(rawptr), __DIGITS_UPPER)
	case 'o': _fmt_int(fi, u,  8, false, 8*size_of(rawptr), __DIGITS_UPPER)
	case 'i', 'd': _fmt_int(fi, u, 10, false, 8*size_of(rawptr), __DIGITS_UPPER)
	case 'z': _fmt_int(fi, u, 12, false, 8*size_of(rawptr), __DIGITS_UPPER)
	case 'x': _fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER)
	case 'X': _fmt_int(fi, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER)

	case:
		fmt_bad_verb(fi, verb)
	}
}
// Formats a Structure of Arrays (SoA) pointer with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - p: The SoA pointer to format.
// - verb: The format specifier character.
//
fmt_soa_pointer :: proc(fi: ^Info, p: runtime.Raw_Soa_Pointer, verb: rune) {
	io.write_string(fi.writer, "#soa{data=0x", &fi.n)
	_fmt_int(fi, u64(uintptr(p.data)), 16, false, 8*size_of(rawptr), __DIGITS_UPPER)
	io.write_string(fi.writer, ", index=", &fi.n)
	_fmt_int(fi, u64(p.index), 10, false, 8*size_of(rawptr), __DIGITS_UPPER)
	io.write_string(fi.writer, "}", &fi.n)
}
// String representation of an enum value.
//
// Inputs:
// - val: The enum value.
//
// Returns: The string representation of the enum value and a boolean indicating success.
//
enum_value_to_string :: proc(val: any) -> (string, bool) {
	v := val
	v.id = runtime.typeid_base(v.id)
	type_info := type_info_of(v.id)

	#partial switch e in type_info.variant {
	case: return "", false
	case runtime.Type_Info_Enum:
		Enum_Value :: runtime.Type_Info_Enum_Value

		ev_, ok := reflect.as_i64(val)
		ev := Enum_Value(ev_)

		if ok {
			if len(e.values) == 0 {
				return "", true
			} else {
				for val, idx in e.values {
					if val == ev {
						return e.names[idx], true
					}
				}
			}
			return "", false
		}
	}

	return "", false
}
// Returns the enum value of a string representation.
//
// $T: The typeid of the enum type.
// Inputs:
// - s: The string representation of the enum value.
//
// Returns: The enum value and a boolean indicating success.
//
string_to_enum_value :: proc($T: typeid, s: string) -> (T, bool) {
	ti := runtime.type_info_base(type_info_of(T))
	if e, ok := ti.variant.(runtime.Type_Info_Enum); ok {
		for str, idx in e.names {
			if s == str {
				// NOTE(bill): Unsafe cast
				ptr := cast(^T)&e.values[idx]
				return ptr^, true
			}
		}
	}
	return T{}, false
}
// Formats an enum value with a specific format.
//
// Inputs:
// - fi: Pointer to the Info struct containing format settings.
// - v: The enum value to format.
// - verb: The format specifier character (e.g. 'i','d','f','s','v','q').
//
fmt_enum :: proc(fi: ^Info, v: any, verb: rune) {
	if v.id == nil || v.data == nil {
		io.write_string(fi.writer, "<nil>", &fi.n)
		return
	}

	type_info := type_info_of(v.id)
	#partial switch e in type_info.variant {
	case: fmt_bad_verb(fi, verb)
	case runtime.Type_Info_Enum:
		switch verb {
		case: fmt_bad_verb(fi, verb)
		case 'i', 'd', 'f':
			fmt_arg(fi, any{v.data, runtime.type_info_base(e.base).id}, verb)
		case 's', 'v', 'q':
			if str, ok := enum_value_to_string(v); ok {
				fmt_string(fi, str, verb)
			} else {
				io.write_string(fi.writer, "%!(BAD ENUM VALUE=", &fi.n)
				fmt_arg(fi, any{v.data, runtime.type_info_base(e.base).id}, 'i')
				io.write_string(fi.writer, ")", &fi.n)
			}
		}
	}
}
// Converts a stored enum value to a string representation
//
// Inputs:
// - enum_type: A pointer to the runtime.Type_Info of the enumeration.
// - ev: The runtime.Type_Info_Enum_Value of the stored enum value.
// - offset: An optional integer to adjust the enumeration value (default is 0).
//
// Returns: A tuple containing the string representation of the enum value and a bool indicating success.
//
stored_enum_value_to_string :: proc(enum_type: ^runtime.Type_Info, ev: runtime.Type_Info_Enum_Value, offset: int = 0) -> (string, bool) {
	et := runtime.type_info_base(enum_type)
	ev := ev
	ev += runtime.Type_Info_Enum_Value(offset)
	#partial switch e in et.variant {
	case: return "", false
	case runtime.Type_Info_Enum:
		if reflect.is_string(e.base) {
			for val, idx in e.values {
				if val == ev {
					return e.names[idx], true
				}
			}
		} else if len(e.values) == 0 {
			return "", true
		} else {
			for val, idx in e.values {
				if val == ev {
					return e.names[idx], true
				}
			}
		}
		return "", false
	}

	return "", false
}
// Formats a bit set and writes it to the provided Info structure
//
// Inputs:
// - fi: A pointer to the Info structure where the formatted bit set will be written.
// - v: The bit set value to be formatted.
// - name: An optional string for the name of the bit set (default is an empty string).
//
fmt_bit_set :: proc(fi: ^Info, v: any, name: string = "") {
	is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
		if ti == nil {
			return false
		}
		t := runtime.type_info_base(ti)
		#partial switch info in t.variant {
		case runtime.Type_Info_Integer:
			switch info.endianness {
			case .Platform: return false
			case .Little:   return ODIN_ENDIAN != .Little
			case .Big:      return ODIN_ENDIAN != .Big
			}
		}
		return false
	}

	byte_swap :: bits.byte_swap

	type_info := type_info_of(v.id)
	#partial switch info in type_info.variant {
	case runtime.Type_Info_Named:
		val := v
		val.id = info.base.id
		fmt_bit_set(fi, val, info.name)

	case runtime.Type_Info_Bit_Set:
		bits: u128
		bit_size := u128(8*type_info.size)

		do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)

		switch bit_size {
		case  0: bits = 0
		case  8:
			x := (^u8)(v.data)^
			bits = u128(x)
		case 16:
			x := (^u16)(v.data)^
			if do_byte_swap { x = byte_swap(x) }
			bits = u128(x)
		case 32:
			x := (^u32)(v.data)^
			if do_byte_swap { x = byte_swap(x) }
			bits = u128(x)
		case 64:
			x := (^u64)(v.data)^
			if do_byte_swap { x = byte_swap(x) }
			bits = u128(x)
		case 128:
			x := (^u128)(v.data)^
			if do_byte_swap { x = byte_swap(x) }
			bits = x
		case: panic("unknown bit_size size")
		}

		et := runtime.type_info_base(info.elem)

		if name != "" {
			io.write_string(fi.writer, name, &fi.n)
		} else {
			reflect.write_type(fi.writer, type_info, &fi.n)
		}
		io.write_byte(fi.writer, '{', &fi.n)
		defer io.write_byte(fi.writer, '}', &fi.n)

		e, is_enum := et.variant.(runtime.Type_Info_Enum)
		commas := 0
		loop: for i in 0 ..< bit_size {
			if bits & (1<<i) == 0 {
				continue loop
			}

			if commas > 0 {
				io.write_string(fi.writer, ", ", &fi.n)
			}

			if is_enum {
				for ev, evi in e.values {
					v := u64(ev)
					if v == u64(i) {
						io.write_string(fi.writer, e.names[evi], &fi.n)
						commas += 1
						continue loop
					}
				}
			}
			v := i64(i) + info.lower
			io.write_i64(fi.writer, v, 10, &fi.n)
			commas += 1
		}
	}
}
// Writes the specified number of indents to the provided Info structure
//
// Inputs:
// - fi: A pointer to the Info structure where the indents will be written.
//
fmt_write_indent :: proc(fi: ^Info) {
	for _ in 0..<fi.indent {
		io.write_byte(fi.writer, '\t', &fi.n)
	}
}
// Formats an array and writes it to the provided Info structure
//
// Inputs:
// - fi: A pointer to the Info structure where the formatted array will be written.
// - array_data: A raw pointer to the array data.
// - count: The number of elements in the array.
// - elem_size: The size of each element in the array.
// - elem_id: The typeid of the array elements.
// - verb: The formatting verb to be used for the array elements.
//
fmt_write_array :: proc(fi: ^Info, array_data: rawptr, count: int, elem_size: int, elem_id: typeid, verb: rune) {
	io.write_byte(fi.writer, '[', &fi.n)
	defer io.write_byte(fi.writer, ']', &fi.n)

	if count <= 0 {
		return
	}
	fi.record_level += 1
	defer fi.record_level -= 1
	
	if fi.hash {
		io.write_byte(fi.writer, '\n', &fi.n)
		defer fmt_write_indent(fi)

		indent := fi.indent
		fi.indent += 1
		defer fi.indent = indent

		for i in 0..<count {
			fmt_write_indent(fi)

			data := uintptr(array_data) + uintptr(i*elem_size)
			fmt_arg(fi, any{rawptr(data), elem_id}, verb)

			io.write_string(fi.writer, ",\n", &fi.n)
		}
	} else {
		for i in 0..<count {
			if i > 0 { io.write_string(fi.writer, ", ", &fi.n) }

			data := uintptr(array_data) + uintptr(i*elem_size)
			fmt_arg(fi, any{rawptr(data), elem_id}, verb)
		}
	}
}
// Handles struct tag processing for formatting
//
// Inputs:
// - data: A raw pointer to the data being processed
// - info: Type information about the struct
// - idx: The index of the tag in the struct
// - verb: A mutable pointer to the rune representing the format verb
// - optional_len: A mutable pointer to an integer holding the optional length (if applicable)
// - use_nul_termination: A mutable pointer to a boolean flag indicating if NUL termination is used
//
// Returns: A boolean value indicating whether to continue processing the tag
//
@(private)
handle_tag :: proc(data: rawptr, info: reflect.Type_Info_Struct, idx: int, verb: ^rune, optional_len: ^int, use_nul_termination: ^bool) -> (do_continue: bool) {
	handle_optional_len :: proc(data: rawptr, info: reflect.Type_Info_Struct, field_name: string, optional_len: ^int) {
		if optional_len == nil {
			return
		}
		for f, i in info.names {
			if f != field_name {
				continue
			}
			ptr := rawptr(uintptr(data) + info.offsets[i])
			field := any{ptr, info.types[i].id}
			if new_len, iok := reflect.as_int(field); iok {
				optional_len^ = max(new_len, 0)
			}
			break
		}
	}
	tag := info.tags[idx]
	if vt, ok := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "fmt"); ok {
		value := strings.trim_space(string(vt))
		switch value {
		case "": return false
		case "-": return true
		}
		r, w := utf8.decode_rune_in_string(value)
		value = value[w:]
		if value == "" || value[0] == ',' {
			verb^ = r
			if len(value) > 0 && value[0] == ',' {
				field_name := value[1:]
				if field_name == "0" {
					if use_nul_termination != nil {
						use_nul_termination^ = true
					}
				} else {
					switch r {
					case 's', 'q':
						handle_optional_len(data, info, field_name, optional_len)
					case 'v':
						#partial switch reflect.type_kind(info.types[idx].id) {
						case .String, .Multi_Pointer, .Array, .Slice, .Dynamic_Array:
							handle_optional_len(data, info, field_name, optional_len)
						}
					}
				}
			}
		}
	}
	return false
}
// Formats a struct for output, handling various struct types (e.g., SOA, raw unions)
//
// Inputs:
// - fi: A mutable pointer to an Info struct containing formatting state
// - v: The value to be formatted
// - the_verb: The formatting verb to be used (e.g. 'v')
// - info: Type information about the struct
// - type_name: The name of the type being formatted
//
fmt_struct :: proc(fi: ^Info, v: any, the_verb: rune, info: runtime.Type_Info_Struct, type_name: string) {
	if the_verb != 'v' {
		fmt_bad_verb(fi, the_verb)
		return
	}
	if info.is_raw_union {
		if type_name == "" {
			io.write_string(fi.writer, "(raw union)", &fi.n)
		} else {
			io.write_string(fi.writer, type_name, &fi.n)
			io.write_string(fi.writer, "{}", &fi.n)
		}
		return
	}

	is_soa := info.soa_kind != .None

	io.write_string(fi.writer, type_name, &fi.n)
	io.write_byte(fi.writer, '[' if is_soa else '{', &fi.n)
	fi.record_level += 1
	defer fi.record_level -= 1

	hash   := fi.hash;   defer fi.hash = hash
	indent := fi.indent; defer fi.indent -= 1
	do_trailing_comma := hash

	// fi.hash = false;
	fi.indent += 1

	if hash	{
		io.write_byte(fi.writer, '\n', &fi.n)
	}
	defer {
		if hash {
			for _ in 0..<indent { io.write_byte(fi.writer, '\t', &fi.n) }
		}
		io.write_byte(fi.writer, ']' if is_soa else '}', &fi.n)
	}

	if is_soa {
		fi.indent += 1
		defer fi.indent -= 1

		base_type_name: string
		if v, ok := info.soa_base_type.variant.(runtime.Type_Info_Named); ok {
			base_type_name = v.name
		}

		actual_field_count := len(info.names)

		n := uintptr(info.soa_len)

		if info.soa_kind == .Slice {
			actual_field_count = len(info.names)-1 // len

			n = uintptr((^int)(uintptr(v.data) + info.offsets[actual_field_count])^)

		} else if info.soa_kind == .Dynamic {
			actual_field_count = len(info.names)-3 // len, cap, allocator

			n = uintptr((^int)(uintptr(v.data) + info.offsets[actual_field_count])^)
		}


		for index in 0..<n {
			if !hash && index > 0 { io.write_string(fi.writer, ", ", &fi.n) }

			field_count := -1

			if !hash && field_count > 0 { io.write_string(fi.writer, ", ", &fi.n) }

			io.write_string(fi.writer, base_type_name, &fi.n)
			io.write_byte(fi.writer, '{', &fi.n)
			defer io.write_byte(fi.writer, '}', &fi.n)
			fi.record_level += 1
			defer fi.record_level -= 1

			for i in 0..<actual_field_count {
				verb := 'v'
				name := info.names[i]
				field_count += 1

				if !hash && field_count > 0 { io.write_string(fi.writer, ", ", &fi.n) }
				if hash {
					fmt_write_indent(fi)
				}

				io.write_string(fi.writer, name, &fi.n)
				io.write_string(fi.writer, " = ", &fi.n)

				if info.soa_kind == .Fixed {
					t := info.types[i].variant.(runtime.Type_Info_Array).elem
					t_size := uintptr(t.size)
					if reflect.is_any(t) {
						io.write_string(fi.writer, "any{}", &fi.n)
					} else {
						data := rawptr(uintptr(v.data) + info.offsets[i] + index*t_size)
						fmt_arg(fi, any{data, t.id}, verb)
					}
				} else {
					t := info.types[i].variant.(runtime.Type_Info_Pointer).elem
					t_size := uintptr(t.size)
					if reflect.is_any(t) {
						io.write_string(fi.writer, "any{}", &fi.n)
					} else {
						field_ptr := (^^byte)(uintptr(v.data) + info.offsets[i])^
						data := rawptr(uintptr(field_ptr) + index*t_size)
						fmt_arg(fi, any{data, t.id}, verb)
					}
				}

				if hash { io.write_string(fi.writer, ",\n", &fi.n) }
			}
		}
	} else {
		field_count := -1
		for name, i in info.names {
			optional_len: int = -1
			use_nul_termination: bool = false
			verb := 'v'
			if handle_tag(v.data, info, i, &verb, &optional_len, &use_nul_termination) {
				continue
			}
			field_count += 1

			if optional_len >= 0 {
				fi.optional_len = optional_len
			}
			defer if optional_len >= 0 {
				fi.optional_len = nil
			}
			fi.use_nul_termination = use_nul_termination
			defer fi.use_nul_termination = false

			if !do_trailing_comma && field_count > 0 { io.write_string(fi.writer, ", ") }
			if hash {
				fmt_write_indent(fi)
			}

			io.write_string(fi.writer, name, &fi.n)
			io.write_string(fi.writer, " = ", &fi.n)

			if t := info.types[i]; reflect.is_any(t) {
				io.write_string(fi.writer, "any{}", &fi.n)
			} else {
				data := rawptr(uintptr(v.data) + info.offsets[i])
				fmt_arg(fi, any{data, t.id}, verb)
			}

			if do_trailing_comma { io.write_string(fi.writer, ",\n", &fi.n) }
		}
	}
}
// Searches for the first NUL-terminated element in a given buffer
//
// Inputs:
// - ptr: The raw pointer to the buffer.
// - elem_size: The size of each element in the buffer.
// - max_n: The maximum number of elements to search (use -1 for no limit).
//
// Returns: The number of elements before the first NUL-terminated element.
//
@(private)
search_nul_termination :: proc(ptr: rawptr, elem_size: int, max_n: int) -> (n: int) {
	for p := uintptr(ptr); max_n < 0 || n < max_n; p += uintptr(elem_size) {
		if mem.check_zero_ptr(rawptr(p), elem_size) {
			break
		}
		n += 1
	}
	return n
}
// Formats a NUL-terminated array into a string representation
//
// Inputs:
// - fi: Pointer to the formatting Info struct.
// - data: The raw pointer to the array data.
// - max_n: The maximum number of elements to process.
// - elem_size: The size of each element in the array.
// - elem: Pointer to the type information of the array element.
// - verb: The formatting verb.
//
fmt_array_nul_terminated :: proc(fi: ^Info, data: rawptr, max_n: int, elem_size: int, elem: ^reflect.Type_Info, verb: rune) {
	if data == nil {
		io.write_string(fi.writer, "<nil>", &fi.n)
		return
	}
	n := search_nul_termination(data, elem_size, max_n)
	fmt_array(fi, data, n, elem_size, elem, verb)
}
// Formats an array into a string representation
//
// Inputs:
// - fi: Pointer to the formatting Info struct.
// - data: The raw pointer to the array data.
// - n: The number of elements in the array.
// - elem_size: The size of each element in the array.
// - elem: Pointer to the type information of the array element.
// - verb: The formatting verb (e.g. 's','q','p').
//
fmt_array :: proc(fi: ^Info, data: rawptr, n: int, elem_size: int, elem: ^reflect.Type_Info, verb: rune) {
	if data == nil && n > 0 {
		io.write_string(fi.writer, "nil")
		return
	}
	if verb == 's' || verb == 'q' {
		print_utf16 :: proc(fi: ^Info, s: []$T) where size_of(T) == 2, intrinsics.type_is_integer(T) {
			REPLACEMENT_CHAR :: '\ufffd'
			_surr1           :: 0xd800
			_surr2           :: 0xdc00
			_surr3           :: 0xe000
			_surr_self       :: 0x10000

			for i := 0; i < len(s); i += 1 {
				r := rune(REPLACEMENT_CHAR)

				switch c := s[i]; {
				case c < _surr1, _surr3 <= c:
					r = rune(c)
				case _surr1 <= c && c < _surr2 && i+1 < len(s) &&
					_surr2 <= s[i+1] && s[i+1] < _surr3:
					r1, r2 := rune(c), rune(s[i+1])
					if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
						r = (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self
					}
					i += 1
				}
				io.write_rune(fi.writer, r, &fi.n)
			}
		}

		print_utf32 :: proc(fi: ^Info, s: []$T) where size_of(T) == 4 {
			for r in s {
				io.write_rune(fi.writer, rune(r), &fi.n)
			}
		}

		switch reflect.type_info_base(elem).id {
		case byte:  fmt_string(fi, string(([^]byte)(data)[:n]), verb); return
		case u16:   print_utf16(fi, ([^]u16)(data)[:n]);               return
		case u16le: print_utf16(fi, ([^]u16le)(data)[:n]);             return
		case u16be: print_utf16(fi, ([^]u16be)(data)[:n]);             return
		case u32:   print_utf32(fi, ([^]u32)(data)[:n]);               return
		case u32le: print_utf32(fi, ([^]u32le)(data)[:n]);             return
		case u32be: print_utf32(fi, ([^]u32be)(data)[:n]);             return
		case rune:  print_utf32(fi, ([^]rune)(data)[:n]);              return
		}
	}
	if verb == 'p' {
		fmt_pointer(fi, data, 'p')
	} else {
		fmt_write_array(fi, data, n, elem_size, elem.id, verb)
	}
}
// Formats a named type into a string representation
//
// Inputs:
// - fi: Pointer to the formatting Info struct.
// - v: The value to format.
// - verb: The formatting verb.
// - info: The named type information.
//
// NOTE: This procedure supports built-in custom formatters for core library types such as runtime.Source_Code_Location, time.Duration, and time.Time.
//
fmt_named :: proc(fi: ^Info, v: any, verb: rune, info: runtime.Type_Info_Named) {
	write_padded_number :: proc(fi: ^Info, i: i64, width: int) {
		n := width-1
		for x := i; x >= 10; x /= 10 {
			n -= 1
		}
		for _ in 0..<n {
			io.write_byte(fi.writer, '0', &fi.n)
		}
		io.write_i64(fi.writer, i, 10, &fi.n)
	}

	// Built-in Custom Formatters for core library types
	switch a in v {
	case runtime.Source_Code_Location:
		io.write_string(fi.writer, a.file_path, &fi.n)

		when ODIN_ERROR_POS_STYLE == .Default {
			io.write_byte(fi.writer, '(', &fi.n)
			io.write_int(fi.writer, int(a.line), 10, &fi.n)
			io.write_byte(fi.writer, ':', &fi.n)
			io.write_int(fi.writer, int(a.column), 10, &fi.n)
			io.write_byte(fi.writer, ')', &fi.n)
		} else when ODIN_ERROR_POS_STYLE == .Unix {
			io.write_byte(fi.writer, ':', &fi.n)
			io.write_int(fi.writer, int(a.line), 10, &fi.n)
			io.write_byte(fi.writer, ':', &fi.n)
			io.write_int(fi.writer, int(a.column), 10, &fi.n)
			io.write_byte(fi.writer, ':', &fi.n)
		} else {
			#panic("Unhandled ODIN_ERROR_POS_STYLE")
		}
		return

	case time.Duration:
		ffrac :: proc(buf: []byte, v: u64, prec: int) -> (nw: int, nv: u64) {
			v := v
			w := len(buf)
			print := false
			for _ in 0..<prec {
				digit := v % 10
				print = print || digit != 0
				if print {
					w -= 1
					buf[w] = byte(digit) + '0'
				}
				v /= 10
			}
			if print {
				w -= 1
				buf[w] = '.'
			}
			return w, v
		}
		fint :: proc(buf: []byte, v: u64) -> int {
			v := v
			w := len(buf)
			if v == 0 {
				w -= 1
				buf[w] = '0'
			} else {
				for v > 0 {
					w -= 1
					buf[w] = byte(v%10) + '0'
					v /= 10
				}
			}
			return w
		}

		buf: [32]byte
		w := len(buf)
		u := u64(a)
		neg := a < 0
		if neg {
			u = -u
		}

		if u < u64(time.Second) {
			prec: int
			w -= 1
			buf[w] = 's'
			w -= 1
			switch {
			case u == 0:
				io.write_string(fi.writer, "0s", &fi.n)
				return
			case u < u64(time.Microsecond):
				prec = 0
				buf[w] = 'n'
			case u < u64(time.Millisecond):
				prec = 3
				// U+00B5 'µ' micro sign == 0xC2 0xB5
				w -= 1 // Need room for two bytes
				copy(buf[w:], "µ")
			case:
				prec = 6
				buf[w] = 'm'
			}
			w, u = ffrac(buf[:w], u, prec)
			w = fint(buf[:w], u)
		} else {
			w -= 1
			buf[w] = 's'
			w, u = ffrac(buf[:w], u, 9)
			w = fint(buf[:w], u%60)
			u /= 60
			if u > 0 {
				w -= 1
				buf[w] = 'm'
				w = fint(buf[:w], u%60)
				u /= 60
				if u > 0 {
					w -= 1
					buf[w] = 'h'
					w = fint(buf[:w], u)
				}
			}
		}

		if neg {
			w -= 1
			buf[w] = '-'
		}
		io.write_string(fi.writer, string(buf[w:]), &fi.n)
		return

	case time.Time:
		t := a
		y, mon, d := time.date(t)
		h, min, s := time.clock(t)
		ns := (t._nsec - (t._nsec/1e9 + time.UNIX_TO_ABSOLUTE)*1e9) % 1e9
		write_padded_number(fi, i64(y), 4)
		io.write_byte(fi.writer, '-', &fi.n)
		write_padded_number(fi, i64(mon), 2)
		io.write_byte(fi.writer, '-', &fi.n)
		write_padded_number(fi, i64(d), 2)
		io.write_byte(fi.writer, ' ', &fi.n)

		write_padded_number(fi, i64(h), 2)
		io.write_byte(fi.writer, ':', &fi.n)
		write_padded_number(fi, i64(min), 2)
		io.write_byte(fi.writer, ':', &fi.n)
		write_padded_number(fi, i64(s), 2)
		io.write_byte(fi.writer, '.', &fi.n)
		write_padded_number(fi, (ns), 9)
		io.write_string(fi.writer, " +0000 UTC", &fi.n)
		return
	}

	#partial switch b in info.base.variant {
	case runtime.Type_Info_Struct:
		fmt_struct(fi, v, verb, b, info.name)
	case runtime.Type_Info_Bit_Set:
		fmt_bit_set(fi, v)
	case:
		fmt_value(fi, any{v.data, info.base.id}, verb)
	}
}
// Formats a union type into a string representation
//
// Inputs:
// - fi: Pointer to the formatting Info struct.
// - v: The value to format.
// - verb: The formatting verb.
// - info: The union type information.
// - type_size: The size of the union type.
//
fmt_union :: proc(fi: ^Info, v: any, verb: rune, info: runtime.Type_Info_Union, type_size: int) {
	if type_size == 0 {
		io.write_string(fi.writer, "nil", &fi.n)
		return
	}

	if reflect.type_info_union_is_pure_maybe(info) {
		if v.data == nil {
			io.write_string(fi.writer, "nil", &fi.n)
		} else {
			id := info.variants[0].id
			fmt_arg(fi, any{v.data, id}, verb)
		}
		return
	}

	tag: i64 = -1
	tag_ptr := uintptr(v.data) + info.tag_offset
	tag_any := any{rawptr(tag_ptr), info.tag_type.id}

	switch i in tag_any {
	case u8:   tag = i64(i)
	case i8:   tag = i64(i)
	case u16:  tag = i64(i)
	case i16:  tag = i64(i)
	case u32:  tag = i64(i)
	case i32:  tag = i64(i)
	case u64:  tag = i64(i)
	case i64:  tag = i
	case: panic("Invalid union tag type")
	}
	assert(tag >= 0)

	if v.data == nil {
		io.write_string(fi.writer, "nil", &fi.n)
	} else if info.no_nil {
		id := info.variants[tag].id
		fmt_arg(fi, any{v.data, id}, verb)
	} else if tag == 0 {
		io.write_string(fi.writer, "nil", &fi.n)
	} else {
		id := info.variants[tag-1].id
		fmt_arg(fi, any{v.data, id}, verb)
	}
}
// Formats a matrix as a string
//
// Inputs:
// - fi: A pointer to an Info struct containing formatting information.
// - v: The matrix value to be formatted.
// - verb: The formatting verb rune.
// - info: A runtime.Type_Info_Matrix struct containing matrix type information.
//
fmt_matrix :: proc(fi: ^Info, v: any, verb: rune, info: runtime.Type_Info_Matrix) {
	io.write_string(fi.writer, "matrix[", &fi.n)
	defer io.write_byte(fi.writer, ']', &fi.n)

	fi.indent += 1

	if fi.hash {
		// Printed as it is written
		io.write_byte(fi.writer, '\n', &fi.n)
		for row in 0..<info.row_count {
			fmt_write_indent(fi)
			for col in 0..<info.column_count {
				if col > 0 { io.write_string(fi.writer, ", ", &fi.n) }

				offset := (row + col*info.elem_stride)*info.elem_size

				data := uintptr(v.data) + uintptr(offset)
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb)
			}
			io.write_string(fi.writer, ",\n", &fi.n)
		}
	} else {
		// Printed in Row-Major layout to match text layout
		for row in 0..<info.row_count {
			if row > 0 { io.write_string(fi.writer, "; ", &fi.n) }
			for col in 0..<info.column_count {
				if col > 0 { io.write_string(fi.writer, ", ", &fi.n) }

				offset := (row + col*info.elem_stride)*info.elem_size

				data := uintptr(v.data) + uintptr(offset)
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb)
			}
		}
	}

	fi.indent -= 1

	if fi.hash {
		fmt_write_indent(fi)
	}
}
// Formats a value based on its type and formatting verb
//
// Inputs:
// - fi: A pointer to an Info struct containing formatting information.
// - v: The value to be formatted.
// - verb: The formatting verb rune.
//
// NOTE: Uses user formatters if available and not ignored.
//
fmt_value :: proc(fi: ^Info, v: any, verb: rune) {
	if v.data == nil || v.id == nil {
		io.write_string(fi.writer, "<nil>", &fi.n)
		return
	}

	if _user_formatters != nil && !fi.ignore_user_formatters {
		formatter := _user_formatters[v.id]
		if formatter != nil {
			fi.ignore_user_formatters = false
			if ok := formatter(fi, v, verb); !ok {
				fi.ignore_user_formatters = true
				fmt_bad_verb(fi, verb)
			}
			return
		}
	}
	fi.ignore_user_formatters = false

	type_info := type_info_of(v.id)
	switch info in type_info.variant {
	case runtime.Type_Info_Any:        // Ignore
	case runtime.Type_Info_Parameters: // Ignore

	case runtime.Type_Info_Named:
		fmt_named(fi, v, verb, info)

	case runtime.Type_Info_Boolean:    fmt_arg(fi, v, verb)
	case runtime.Type_Info_Integer:    fmt_arg(fi, v, verb)
	case runtime.Type_Info_Rune:       fmt_arg(fi, v, verb)
	case runtime.Type_Info_Float:      fmt_arg(fi, v, verb)
	case runtime.Type_Info_Complex:    fmt_arg(fi, v, verb)
	case runtime.Type_Info_Quaternion: fmt_arg(fi, v, verb)
	case runtime.Type_Info_String:     fmt_arg(fi, v, verb)

	case runtime.Type_Info_Pointer:
		if v.id == typeid_of(^runtime.Type_Info) {
			reflect.write_type(fi.writer, (^^runtime.Type_Info)(v.data)^, &fi.n)
		} else {
			ptr := (^rawptr)(v.data)^
			if verb != 'p' && info.elem != nil {
				a := any{ptr, info.elem.id}

				elem := runtime.type_info_base(info.elem)
				if elem != nil {
					#partial switch e in elem.variant {
					case runtime.Type_Info_Array,
					     runtime.Type_Info_Slice,
					     runtime.Type_Info_Dynamic_Array,
					     runtime.Type_Info_Map:
						if ptr == nil {
							io.write_string(fi.writer, "<nil>", &fi.n)
							return
						}
						if fi.indirection_level < 1 {
						  	fi.indirection_level += 1
							defer fi.indirection_level -= 1
							io.write_byte(fi.writer, '&')
							fmt_value(fi, a, verb)
							return
						}

					case runtime.Type_Info_Struct,
					     runtime.Type_Info_Union:
						if ptr == nil {
							io.write_string(fi.writer, "<nil>", &fi.n)
							return
						}
						if fi.indirection_level < 1 {
							fi.indirection_level += 1
							defer fi.indirection_level -= 1
							io.write_byte(fi.writer, '&', &fi.n)
							fmt_value(fi, a, verb)
							return
						}
					}
				}
			}
			fmt_pointer(fi, ptr, verb)
		}

	case runtime.Type_Info_Soa_Pointer:
		ptr := (^runtime.Raw_Soa_Pointer)(v.data)^
		fmt_soa_pointer(fi, ptr, verb)

	case runtime.Type_Info_Multi_Pointer:
		ptr := (^rawptr)(v.data)^
		if ptr == nil {
			io.write_string(fi.writer, "<nil>", &fi.n)
			return
		}
		if verb != 'p' && info.elem != nil {
			a := any{ptr, info.elem.id}

			elem := runtime.type_info_base(info.elem)
			if elem != nil {
				if n, ok := fi.optional_len.?; ok {
					fmt_array(fi, ptr, n, elem.size, elem, verb)
					return
				} else if fi.use_nul_termination {
					fmt_array_nul_terminated(fi, ptr, -1, elem.size, elem, verb)
					return
				}

				#partial switch e in elem.variant {
				case runtime.Type_Info_Integer:
					switch verb {
					case 's', 'q':
						switch elem.id {
						case u8:
							fmt_cstring(fi, cstring(ptr), verb)
							return
						case u16, u32, rune:
							n := search_nul_termination(ptr, elem.size, -1)
							fmt_array(fi, ptr, n, elem.size, elem, verb)
							return
						}
					}

				case runtime.Type_Info_Array,
				     runtime.Type_Info_Slice,
				     runtime.Type_Info_Dynamic_Array,
				     runtime.Type_Info_Map:
					if fi.indirection_level < 1 {
					  	fi.indirection_level += 1
						defer fi.indirection_level -= 1
						io.write_byte(fi.writer, '&', &fi.n)
						fmt_value(fi, a, verb)
						return
					}

				case runtime.Type_Info_Struct,
				     runtime.Type_Info_Union:
					if fi.indirection_level < 1 {
						fi.indirection_level += 1
						defer fi.indirection_level -= 1
						io.write_byte(fi.writer, '&', &fi.n)
						fmt_value(fi, a, verb)
						return
					}
				}
			}
		}
		fmt_pointer(fi, ptr, verb)

	case runtime.Type_Info_Enumerated_Array:
		fi.record_level += 1
		defer fi.record_level -= 1

		if fi.hash {
			io.write_string(fi.writer, "[\n", &fi.n)
			defer {
				io.write_byte(fi.writer, '\n', &fi.n)
				fmt_write_indent(fi)
				io.write_byte(fi.writer, ']', &fi.n)
			}
			indent := fi.indent
			fi.indent += 1
			defer fi.indent = indent

			for i in 0..<info.count {
				fmt_write_indent(fi)

				idx, ok := stored_enum_value_to_string(info.index, info.min_value, i)
				if ok {
					io.write_byte(fi.writer, '.', &fi.n)
					io.write_string(fi.writer, idx, &fi.n)
				} else {
					io.write_i64(fi.writer, i64(info.min_value)+i64(i), 10, &fi.n)
				}
				io.write_string(fi.writer, " = ", &fi.n)

				data := uintptr(v.data) + uintptr(i*info.elem_size)
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb)

				io.write_string(fi.writer, ",\n", &fi.n)
			}
		} else {
			io.write_byte(fi.writer, '[', &fi.n)
			defer io.write_byte(fi.writer, ']', &fi.n)
			for i in 0..<info.count {
				if i > 0 { io.write_string(fi.writer, ", ", &fi.n) }

				idx, ok := stored_enum_value_to_string(info.index, info.min_value, i)
				if ok {
					io.write_byte(fi.writer, '.', &fi.n)
					io.write_string(fi.writer, idx, &fi.n)
				} else {
					io.write_i64(fi.writer, i64(info.min_value)+i64(i), 10, &fi.n)
				}
				io.write_string(fi.writer, " = ", &fi.n)

				data := uintptr(v.data) + uintptr(i*info.elem_size)
				fmt_arg(fi, any{rawptr(data), info.elem.id}, verb)
			}
		}

	case runtime.Type_Info_Array:
		n := info.count
		ptr := v.data
		if ol, ok := fi.optional_len.?; ok {
			n = min(n, ol)
		} else if fi.use_nul_termination {
			fmt_array_nul_terminated(fi, ptr, n, info.elem_size, info.elem, verb)
			return
		}
		fmt_array(fi, ptr, n, info.elem_size, info.elem, verb)

	case runtime.Type_Info_Slice:
		slice := cast(^mem.Raw_Slice)v.data
		n := slice.len
		ptr := slice.data
		if ol, ok := fi.optional_len.?; ok {
			n = min(n, ol)
		} else if fi.use_nul_termination {
			fmt_array_nul_terminated(fi, ptr, n, info.elem_size, info.elem, verb)
			return
		}
		fmt_array(fi, ptr, n, info.elem_size, info.elem, verb)

	case runtime.Type_Info_Dynamic_Array:
		array := cast(^mem.Raw_Dynamic_Array)v.data
		n := array.len
		ptr := array.data
		if ol, ok := fi.optional_len.?; ok {
			n = min(n, ol)
		} else if fi.use_nul_termination {
			fmt_array_nul_terminated(fi, ptr, n, info.elem_size, info.elem, verb)
			return
		}
		fmt_array(fi, ptr, n, info.elem_size, info.elem, verb)

	case runtime.Type_Info_Simd_Vector:
		io.write_byte(fi.writer, '<', &fi.n)
		defer io.write_byte(fi.writer, '>', &fi.n)
		for i in 0..<info.count {
			if i > 0 { io.write_string(fi.writer, ", ", &fi.n) }

			data := uintptr(v.data) + uintptr(i*info.elem_size)
			fmt_arg(fi, any{rawptr(data), info.elem.id}, verb)
		}


	case runtime.Type_Info_Map:
		if verb != 'v' {
			fmt_bad_verb(fi, verb)
			return
		}

		io.write_string(fi.writer, "map[", &fi.n)
		defer io.write_byte(fi.writer, ']', &fi.n)
		fi.record_level += 1
		defer fi.record_level -= 1

		m := (^mem.Raw_Map)(v.data)
		if m != nil {
			if info.map_info == nil {
				return
			}
			map_cap := uintptr(runtime.map_cap(m^))
			ks, vs, hs, _, _ := runtime.map_kvh_data_dynamic(m^, info.map_info)
			j := 0
			for bucket_index in 0..<map_cap {
				runtime.map_hash_is_valid(hs[bucket_index]) or_continue

				if j > 0 {
					io.write_string(fi.writer, ", ", &fi.n)
				}
				j += 1

				key   := runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index)
				value := runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index)

				fmt_arg(&Info{writer = fi.writer}, any{rawptr(key), info.key.id}, 'v')
				io.write_string(fi.writer, "=", &fi.n)
				fmt_arg(fi, any{rawptr(value), info.value.id}, 'v')
			}
		}

	case runtime.Type_Info_Struct:
		fmt_struct(fi, v, verb, info, "")

	case runtime.Type_Info_Union:
		fmt_union(fi, v, verb, info, type_info.size)

	case runtime.Type_Info_Enum:
		fmt_enum(fi, v, verb)

	case runtime.Type_Info_Procedure:
		ptr := (^rawptr)(v.data)^
		if ptr == nil {
			io.write_string(fi.writer, "nil", &fi.n)
		} else {
			reflect.write_typeid(fi.writer, v.id, &fi.n)
			io.write_string(fi.writer, " @ ", &fi.n)
			fmt_pointer(fi, ptr, 'p')
		}

	case runtime.Type_Info_Type_Id:
		id := (^typeid)(v.data)^
		reflect.write_typeid(fi.writer, id, &fi.n)

	case runtime.Type_Info_Bit_Set:
		fmt_bit_set(fi, v)

	case runtime.Type_Info_Relative_Pointer:
		ptr := reflect.relative_pointer_to_absolute_raw(v.data, info.base_integer.id)
		absolute_ptr := any{ptr, info.pointer.id}

		fmt_value(fi, absolute_ptr, verb)

	case runtime.Type_Info_Relative_Multi_Pointer:
		ptr := reflect.relative_pointer_to_absolute_raw(v.data, info.base_integer.id)
		absolute_ptr := any{ptr, info.pointer.id}

		fmt_value(fi, absolute_ptr, verb)

	case runtime.Type_Info_Matrix:
		fmt_matrix(fi, v, verb, info)
	}
}
// Formats a complex number based on the given formatting verb
//
// Inputs:
// - fi: A pointer to an Info struct containing formatting information.
// - c: The complex128 value to be formatted.
// - bits: The number of bits in the complex number (32 or 64).
// - verb: The formatting verb rune ('f', 'F', 'v', 'h', 'H').
//
fmt_complex :: proc(fi: ^Info, c: complex128, bits: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v', 'h', 'H':
		r, i := real(c), imag(c)
		fmt_float(fi, r, bits/2, verb)
		if !fi.plus && i >= 0 {
			io.write_rune(fi.writer, '+', &fi.n)
		}
		fmt_float(fi, i, bits/2, verb)
		io.write_rune(fi.writer, 'i', &fi.n)

	case:
		fmt_bad_verb(fi, verb)
		return
	}
}
// Formats a quaternion number based on the given formatting verb
//
// Inputs:
// - fi: A pointer to an Info struct containing formatting information.
// - q: The quaternion256 value to be formatted.
// - bits: The number of bits in the quaternion number (64, 128, or 256).
// - verb: The formatting verb rune ('f', 'F', 'v', 'h', 'H').
//
fmt_quaternion  :: proc(fi: ^Info, q: quaternion256, bits: int, verb: rune) {
	switch verb {
	case 'f', 'F', 'v', 'h', 'H':
		r, i, j, k := real(q), imag(q), jmag(q), kmag(q)

		fmt_float(fi, r, bits/4, verb)

		if !fi.plus && i >= 0 {
			io.write_rune(fi.writer, '+', &fi.n)
		}
		fmt_float(fi, i, bits/4, verb)
		io.write_rune(fi.writer, 'i', &fi.n)

		if !fi.plus && j >= 0 {
			io.write_rune(fi.writer, '+', &fi.n)
		}
		fmt_float(fi, j, bits/4, verb)
		io.write_rune(fi.writer, 'j', &fi.n)

		if !fi.plus && k >= 0 {
			io.write_rune(fi.writer, '+', &fi.n)
		}
		fmt_float(fi, k, bits/4, verb)
		io.write_rune(fi.writer, 'k', &fi.n)

	case:
		fmt_bad_verb(fi, verb)
		return
	}
}
// Formats an argument based on its type and the given formatting verb
//
// Inputs:
// - fi: A pointer to an Info struct containing formatting information.
// - arg: The value to be formatted.
// - verb: The formatting verb rune (e.g. 'T').
//
// NOTE: Uses user formatters if available and not ignored.
//
fmt_arg :: proc(fi: ^Info, arg: any, verb: rune) {
	if arg == nil {
		io.write_string(fi.writer, "<nil>")
		return
	}
	fi.arg = arg

	if verb == 'T' {
		ti := type_info_of(arg.id)
		switch a in arg {
		case ^runtime.Type_Info: ti = a
		}
		reflect.write_type(fi.writer, ti, &fi.n)
		return
	}

	if _user_formatters != nil {
		formatter := _user_formatters[arg.id]
		if formatter != nil {
			if ok := formatter(fi, arg, verb); !ok {
				fmt_bad_verb(fi, verb)
			}
			return
		}
	}

	arg_info := type_info_of(arg.id)
	if info, ok := arg_info.variant.(runtime.Type_Info_Named); ok {
		fmt_named(fi, arg, verb, info)
		return
	}

	base_arg := arg
	base_arg.id = runtime.typeid_base(base_arg.id)
	switch a in base_arg {
	case bool:       fmt_bool(fi, a, verb)
	case b8:         fmt_bool(fi, bool(a), verb)
	case b16:        fmt_bool(fi, bool(a), verb)
	case b32:        fmt_bool(fi, bool(a), verb)
	case b64:        fmt_bool(fi, bool(a), verb)

	case any:        fmt_arg(fi,  a, verb)
	case rune:       fmt_rune(fi, a, verb)

	case f16:        fmt_float(fi, f64(a), 16, verb)
	case f32:        fmt_float(fi, f64(a), 32, verb)
	case f64:        fmt_float(fi, a,      64, verb)

	case f16le:      fmt_float(fi, f64(a), 16, verb)
	case f32le:      fmt_float(fi, f64(a), 32, verb)
	case f64le:      fmt_float(fi, f64(a), 64, verb)

	case f16be:      fmt_float(fi, f64(a), 16, verb)
	case f32be:      fmt_float(fi, f64(a), 32, verb)
	case f64be:      fmt_float(fi, f64(a), 64, verb)

	case complex32:  fmt_complex(fi, complex128(a), 32, verb)
	case complex64:  fmt_complex(fi, complex128(a), 64, verb)
	case complex128: fmt_complex(fi, a, 128, verb)

	case quaternion64:  fmt_quaternion(fi, quaternion256(a),  64, verb)
	case quaternion128: fmt_quaternion(fi, quaternion256(a), 128, verb)
	case quaternion256: fmt_quaternion(fi, a, 256, verb)

	case i8:      fmt_int(fi, u64(a), true,   8, verb)
	case u8:      fmt_int(fi, u64(a), false,  8, verb)
	case i16:     fmt_int(fi, u64(a), true,  16, verb)
	case u16:     fmt_int(fi, u64(a), false, 16, verb)
	case i32:     fmt_int(fi, u64(a), true,  32, verb)
	case u32:     fmt_int(fi, u64(a), false, 32, verb)
	case i64:     fmt_int(fi, u64(a), true,  64, verb)
	case u64:     fmt_int(fi,     a,  false, 64, verb)
	case int:     fmt_int(fi, u64(a), true,  8*size_of(int), verb)
	case uint:    fmt_int(fi, u64(a), false, 8*size_of(uint), verb)
	case uintptr: fmt_int(fi, u64(a), false, 8*size_of(uintptr), verb)

	case string:  fmt_string(fi, a, verb)
	case cstring: fmt_cstring(fi, a, verb)

	case typeid:  reflect.write_typeid(fi.writer, a, &fi.n)

	case i16le:     fmt_int(fi, u64(a), true,  16, verb)
	case u16le:     fmt_int(fi, u64(a), false, 16, verb)
	case i32le:     fmt_int(fi, u64(a), true,  32, verb)
	case u32le:     fmt_int(fi, u64(a), false, 32, verb)
	case i64le:     fmt_int(fi, u64(a), true,  64, verb)
	case u64le:     fmt_int(fi, u64(a), false, 64, verb)

	case i16be:     fmt_int(fi, u64(a), true,  16, verb)
	case u16be:     fmt_int(fi, u64(a), false, 16, verb)
	case i32be:     fmt_int(fi, u64(a), true,  32, verb)
	case u32be:     fmt_int(fi, u64(a), false, 32, verb)
	case i64be:     fmt_int(fi, u64(a), true,  64, verb)
	case u64be:     fmt_int(fi, u64(a), false, 64, verb)

	case i128:     fmt_int_128(fi, u128(a), true,  128, verb)
	case u128:     fmt_int_128(fi,       a, false, 128, verb)

	case i128le:   fmt_int_128(fi, u128(a), true,  128, verb)
	case u128le:   fmt_int_128(fi, u128(a), false, 128, verb)

	case i128be:   fmt_int_128(fi, u128(a), true,  128, verb)
	case u128be:   fmt_int_128(fi, u128(a), false, 128, verb)

	case: fmt_value(fi, arg, verb)
	}

}
