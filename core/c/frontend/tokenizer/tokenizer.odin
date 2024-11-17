package c_frontend_tokenizer

import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode/utf8"


Error_Handler :: #type proc(pos: Pos, fmt: string, args: ..any)


Tokenizer :: struct {
	// Immutable data
	path: string,
	src:  []byte,


	// Tokenizing state
	ch:          rune,
	offset:      int,
	read_offset: int,
	line_offset: int,
	line_count:  int,

	// Extra information for tokens
	at_bol:    bool,
	has_space: bool,

	// Mutable data
	err:  Error_Handler,
	warn: Error_Handler,
	error_count:   int,
	warning_count: int,
}

init_defaults :: proc(t: ^Tokenizer, err: Error_Handler = default_error_handler, warn: Error_Handler = default_warn_handler) {
	t.err = err
	t.warn = warn
}


@(private)
offset_to_pos :: proc(t: ^Tokenizer, offset: int) -> (pos: Pos) {
	pos.file = t.path
	pos.offset = offset
	pos.line = t.line_count
	pos.column = offset - t.line_offset + 1
	return
}

default_error_handler :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

default_warn_handler :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) warning: ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

error_offset :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
	pos := offset_to_pos(t, offset)
	if t.err != nil {
		t.err(pos, msg, ..args)
	}
	t.error_count += 1
}

warn_offset :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
	pos := offset_to_pos(t, offset)
	if t.warn != nil {
		t.warn(pos, msg, ..args)
	}
	t.warning_count += 1
}

error :: proc(t: ^Tokenizer, tok: ^Token, msg: string, args: ..any) {
	pos := tok.pos
	if t.err != nil {
		t.err(pos, msg, ..args)
	}
	t.error_count += 1
}

warn :: proc(t: ^Tokenizer, tok: ^Token, msg: string, args: ..any) {
	pos := tok.pos
	if t.warn != nil {
		t.warn(pos, msg, ..args)
	}
	t.warning_count += 1
}


advance_rune :: proc(t: ^Tokenizer) {
	if t.read_offset < len(t.src) {
		t.offset = t.read_offset
		if t.ch == '\n' {
			t.at_bol = true
			t.line_offset = t.offset
			t.line_count += 1
		}
		r, w := rune(t.src[t.read_offset]), 1
		switch {
		case r == 0:
			error_offset(t, t.offset, "illegal character NUL")
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune(t.src[t.read_offset:])
			if r == utf8.RUNE_ERROR && w == 1 {
				error_offset(t, t.offset, "illegal UTF-8 encoding")
			} else if r == utf8.RUNE_BOM && t.offset > 0 {
				error_offset(t, t.offset, "illegal byte order mark")
			}
		}
		t.read_offset += w
		t.ch = r
	} else {
		t.offset = len(t.src)
		if t.ch == '\n' {
			t.at_bol = true
			t.line_offset = t.offset
			t.line_count += 1
		}
		t.ch = -1
	}
}

advance_rune_n :: proc(t: ^Tokenizer, n: int) {
	for _ in 0..<n {
		advance_rune(t)
	}
}

is_digit :: proc(r: rune) -> bool {
	return '0' <= r && r <= '9'
}

skip_whitespace :: proc(t: ^Tokenizer) {
	for {
		switch t.ch {
		case ' ', '\t', '\r', '\v', '\f', '\n':
			t.has_space = true
			advance_rune(t)
		case:
			return
		}
	}
}

scan_comment :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1
	next := -1
	general: {
		if t.ch == '/'{ // line comments
			advance_rune(t)
			for t.ch != '\n' && t.ch >= 0 {
				advance_rune(t)
			}

			next = t.offset
			if t.ch == '\n' {
				next += 1
			}
			break general
		}

		/* style comment */
		advance_rune(t)
		for t.ch >= 0 {
			ch := t.ch
			advance_rune(t)
			if ch == '*' && t.ch == '/' {
				advance_rune(t)
				next = t.offset
				break general
			}
		}

		error_offset(t, offset, "comment not terminated")
	}

	lit := t.src[offset : t.offset]

	// NOTE(bill): Strip CR for line comments
	for len(lit) > 2 && lit[1] == '/' && lit[len(lit)-1] == '\r' {
		lit = lit[:len(lit)-1]
	}


	return string(lit)
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
	offset := t.offset

	for is_ident1(t.ch) {
		advance_rune(t)
	}

	return string(t.src[offset : t.offset])
}

scan_string :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1

	for {
		ch := t.ch
		if ch == '\n' || ch < 0 {
			error_offset(t, offset, "string literal was not terminated")
			break
		}
		advance_rune(t)
		if ch == '"' {
			break
		}
		if ch == '\\' {
			scan_escape(t)
		}
	}

	return string(t.src[offset : t.offset])
}

digit_val :: proc(r: rune) -> int {
	switch r {
	case '0'..='9':
		return int(r-'0')
	case 'A'..='F':
		return int(r-'A' + 10)
	case 'a'..='f':
		return int(r-'a' + 10)
	}
	return 16
}

scan_escape :: proc(t: ^Tokenizer) -> bool {
	offset := t.offset

	esc := t.ch
	n: int
	base, max: u32
	switch esc {
	case 'a', 'b', 'e', 'f', 'n', 't', 'v', 'r', '\\', '\'', '"':
		advance_rune(t)
		return true

	case '0'..='7':
		for digit_val(t.ch) < 8 {
			advance_rune(t)
		}
		return true
	case 'x':
		advance_rune(t)
		for digit_val(t.ch) < 16 {
			advance_rune(t)
		}
		return true
	case 'u':
		advance_rune(t)
		n, base, max = 4, 16, utf8.MAX_RUNE
	case 'U':
		advance_rune(t)
		n, base, max = 8, 16, utf8.MAX_RUNE
	case:
		if t.ch < 0 {
			error_offset(t, offset, "escape sequence was not terminated")
		} else {
			break
		}
		return false
	}

	x: u32
	main_loop: for n > 0 {
		d := u32(digit_val(t.ch))
		if d >= base {
			if t.ch == '"' || t.ch == '\'' {
				break main_loop
			}
			if t.ch < 0 {
				error_offset(t, t.offset, "escape sequence was not terminated")
			} else {
				error_offset(t, t.offset, "illegal character '%r' : %d in escape sequence", t.ch, t.ch)
			}
			return false
		}

		x = x*base + d
		advance_rune(t)
		n -= 1
	}

	if x > max || 0xd800 <= x && x <= 0xdfff {
		error_offset(t, offset, "escape sequence is an invalid Unicode code point")
		return false
	}
	return true
}

scan_rune :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1
	valid := true
	n := 0
	for {
		ch := t.ch
		if ch == '\n' || ch < 0 {
			if valid {
				error_offset(t, offset, "rune literal not terminated")
				valid = false
			}
			break
		}
		advance_rune(t)
		if ch == '\'' {
			break
		}
		n += 1
		if ch == '\\' {
			if !scan_escape(t)  {
				valid = false
			}
		}
	}

	if valid && n != 1 {
		error_offset(t, offset, "illegal rune literal")
	}

	return string(t.src[offset : t.offset])
}

scan_number :: proc(t: ^Tokenizer, seen_decimal_point: bool) -> (Token_Kind, string) {
	scan_mantissa :: proc(t: ^Tokenizer, base: int) {
		for digit_val(t.ch) < base {
			advance_rune(t)
		}
	}
	scan_exponent :: proc(t: ^Tokenizer) {
		if t.ch == 'e' || t.ch == 'E' || t.ch == 'p' || t.ch == 'P' {
			advance_rune(t)
			if t.ch == '-' || t.ch == '+' {
				advance_rune(t)
			}
			if digit_val(t.ch) < 10 {
				scan_mantissa(t, 10)
			} else {
				error_offset(t, t.offset, "illegal floating-point exponent")
			}
		}
	}
	scan_fraction :: proc(t: ^Tokenizer) -> (early_exit: bool) {
		if t.ch == '.' && peek(t) == '.' {
			return true
		}
		if t.ch == '.' {
			advance_rune(t)
			scan_mantissa(t, 10)
		}
		return false
	}

	check_end := true


	offset := t.offset
	seen_point := seen_decimal_point

	if seen_point {
		offset -= 1
		scan_mantissa(t, 10)
		scan_exponent(t)
	} else {
		if t.ch == '0' {
			int_base :: proc(t: ^Tokenizer, base: int, msg: string) {
				prev := t.offset
				advance_rune(t)
				scan_mantissa(t, base)
				if t.offset - prev <= 1 {
					error_offset(t, t.offset, msg)
				}
			}

			advance_rune(t)
			switch t.ch {
			case 'b', 'B':
				int_base(t, 2, "illegal binary integer")
			case 'x', 'X':
				int_base(t, 16, "illegal hexadecimal integer")
			case:
				seen_point = false
				scan_mantissa(t, 10)
				if t.ch == '.' {
					seen_point = true
					if scan_fraction(t) {
						check_end = false
					}
				}
				if check_end {
					scan_exponent(t)
					check_end = false
				}
			}
		}
	}

	if check_end {
		scan_mantissa(t, 10)

		if !scan_fraction(t) {
			scan_exponent(t)
		}
	}

	return .Number, string(t.src[offset : t.offset])
}

scan_punct :: proc(t: ^Tokenizer, ch: rune) -> (kind: Token_Kind) {
	kind = .Punct
	switch ch {
	case:
		kind = .Invalid

	case '<', '>':
		if t.ch == ch {
			advance_rune(t)
		}
		if t.ch == '=' {
			advance_rune(t)
		}
	case '!', '+', '-', '*', '/', '%', '^', '=':
		if t.ch == '=' {
			advance_rune(t)
		}
	case '#':
		if t.ch == '#' {
			advance_rune(t)
		}
	case '&':
		if t.ch == '=' || t.ch == '&' {
			advance_rune(t)
		}
	case '|':
		if t.ch == '=' || t.ch == '|' {
			advance_rune(t)
		}
	case '(', ')', '[', ']', '{', '}':
		// okay
	case '~', ',', ':', ';', '?':
		// okay
	case '`':
		// okay
	case '.':
		if t.ch == '.' && peek(t) == '.' {
			advance_rune(t)
			advance_rune(t) // consume last '.'
		}
	}
	return
}

peek :: proc(t: ^Tokenizer) -> byte {
	if t.read_offset < len(t.src) {
		return t.src[t.read_offset]
	}
	return 0
}
peek_str :: proc(t: ^Tokenizer, str: string) -> bool {
	if t.read_offset < len(t.src) {
		return strings.has_prefix(string(t.src[t.offset:]), str)
	}
	return false
}

scan_literal_prefix :: proc(t: ^Tokenizer, str: string, prefix: ^string) -> bool {
	if peek_str(t, str) {
		offset := t.offset
		for _ in str {
			advance_rune(t)
		}
		prefix^ = string(t.src[offset:][:len(str)-1])
		return true
	}
	return false
}


allow_next_to_be_newline :: proc(t: ^Tokenizer) -> bool {
	if t.ch == '\n' {
		advance_rune(t)
		return true
	} else if t.ch == '\r' && peek(t) == '\n' { // allow for MS-DOS style line endings
		advance_rune(t) // \r
		advance_rune(t) // \n
		return true
	}
	return false
}

scan :: proc(t: ^Tokenizer, f: ^File) -> ^Token {
	skip_whitespace(t)

	offset := t.offset

	kind: Token_Kind
	lit: string
	prefix: string

	switch ch := t.ch; {
	case scan_literal_prefix(t, `u8"`, &prefix):
		kind = .String
		lit = scan_string(t)
	case scan_literal_prefix(t, `u"`, &prefix):
		kind = .String
		lit = scan_string(t)
	case scan_literal_prefix(t, `L"`, &prefix):
		kind = .String
		lit = scan_string(t)
	case scan_literal_prefix(t, `U"`, &prefix):
		kind = .String
		lit = scan_string(t)
	case scan_literal_prefix(t, `u'`, &prefix):
		kind = .Char
		lit = scan_rune(t)
	case scan_literal_prefix(t, `L'`, &prefix):
		kind = .Char
		lit = scan_rune(t)
	case scan_literal_prefix(t, `U'`, &prefix):
		kind = .Char
		lit = scan_rune(t)

	case is_ident0(ch):
		lit = scan_identifier(t)
		kind = .Ident
	case '0' <= ch && ch <= '9':
		kind, lit = scan_number(t, false)
	case:
		advance_rune(t)
		switch ch {
		case -1:
			kind = .EOF
		case '\\':
			kind = .Punct
			if allow_next_to_be_newline(t) {
				t.at_bol = true
				t.has_space = false
				return scan(t, f)
			}

		case '.':
			if is_digit(t.ch) {
				kind, lit = scan_number(t, true)
			} else {
				kind = scan_punct(t, ch)
			}
		case '"':
			kind = .String
			lit = scan_string(t)
		case '\'':
			kind = .Char
			lit = scan_rune(t)
		case '/':
			if t.ch == '/' || t.ch == '*' {
				kind = .Comment
				lit = scan_comment(t)
				t.has_space = true
				break
			}
			fallthrough
		case:
			kind = scan_punct(t, ch)
			if kind == .Invalid && ch != utf8.RUNE_BOM {
				error_offset(t, t.offset, "illegal character '%r': %d", ch, ch)
			}
		}
	}

	if lit == "" {
		lit = string(t.src[offset : t.offset])
	}

	if kind == .Comment {
		return scan(t, f)
	}

	tok := new(Token)
	tok.kind = kind
	tok.lit = lit
	tok.pos = offset_to_pos(t, offset)
	tok.file = f
	tok.prefix = prefix
	tok.at_bol = t.at_bol
	tok.has_space = t.has_space

	t.at_bol, t.has_space = false, false

	return tok
}

tokenize :: proc(t: ^Tokenizer, f: ^File) -> ^Token {
	setup_tokenizer: {
		t.src = f.src
		t.ch = ' '
		t.offset = 0
		t.read_offset = 0
		t.line_offset = 0
		t.line_count = len(t.src) > 0 ? 1 : 0
		t.error_count = 0
		t.path = f.name


		advance_rune(t)
		if t.ch == utf8.RUNE_BOM {
			advance_rune(t)
		}
	}


	t.at_bol = true
	t.has_space = false

	head: Token
	curr := &head
	for {
		tok := scan(t, f)
		if tok == nil {
			break
		}
		curr.next = tok
		curr = curr.next
		if tok.kind == .EOF {
			break
		}
	}

	return head.next
}

add_new_file :: proc(t: ^Tokenizer, name: string, src: []byte, id: int) -> ^File {
	file := new(File)
	file.id = id
	file.src = src
	file.name = name
	file.display_name = name
	return file
}

tokenize_file :: proc(t: ^Tokenizer, path: string, id: int, loc := #caller_location) -> ^Token {
	src, ok := os.read_entire_file(path)
	if !ok {
		return nil
	}
	return tokenize(t, add_new_file(t, path, src, id))
}


inline_tokenize :: proc(t: ^Tokenizer, tok: ^Token, src: []byte) -> ^Token {
	file := new(File)
	file.src = src
	if tok.file != nil {
		file.id = tok.file.id
		file.name = tok.file.name
		file.display_name = tok.file.name
	}

	return tokenize(t, file)
}
