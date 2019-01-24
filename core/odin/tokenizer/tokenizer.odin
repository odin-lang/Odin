package tokenizer

import "core:fmt"
import "core:odin/token"
import "core:strconv"
import "core:unicode/utf8"

Error_Handler :: #type proc(pos: token.Pos, fmt: string, args: ..any);

Tokenizer :: struct {
	// Immutable data
	path: string,
	src:  []byte,
	err:  Error_Handler,

	// Tokenizing state
	ch:          rune,
	offset:      int,
	read_offset: int,
	line_offset: int,
	line_count:  int,

	// Mutable data
	error_count: int,
}

init :: proc(t: ^Tokenizer, src: []byte, path: string, err: Error_Handler = default_error_handler) {
	t.src = src;
	t.err = err;
	t.ch = ' ';
	t.offset = 0;
	t.read_offset = 0;
	t.line_offset = 0;
	t.line_count = len(src) > 0 ? 1 : 0;
	t.error_count = 0;
	t.path = path;

	advance_rune(t);
	if t.ch == utf8.RUNE_BOM {
		advance_rune(t);
	}
}

@(private)
offset_to_pos :: proc(t: ^Tokenizer, offset: int) -> token.Pos {
	line := t.line_count;
	column := offset - t.line_offset + 1;

	return token.Pos {
		file = t.path,
		offset = offset,
		line = line,
		column = column,
	};
}

default_error_handler :: proc(pos: token.Pos, msg: string, args: ..any) {
	fmt.printf_err("%s(%d:%d) ", pos.file, pos.line, pos.column);
	fmt.printf_err(msg, ..args);
	fmt.printf_err("\n");
}

error :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
	pos := offset_to_pos(t, offset);
	if t.err != nil {
		t.err(pos, msg, ..args);
	}
	t.error_count += 1;
}

advance_rune :: proc(using t: ^Tokenizer) {
	if read_offset < len(src) {
		offset = read_offset;
		if ch == '\n' {
			line_offset = offset;
			line_count += 1;
		}
		r, w := rune(src[read_offset]), 1;
		switch {
		case r == 0:
			error(t, t.offset, "illegal character NUL");
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune(src[read_offset:]);
			if r == utf8.RUNE_ERROR && w == 1 {
				error(t, t.offset, "illegal UTF-8 encoding");
			} else if r == utf8.RUNE_BOM && offset > 0 {
				error(t, t.offset, "illegal byte order mark");
			}
		}
		read_offset += w;
		ch = r;
	} else {
		offset = len(src);
		if ch == '\n' {
			line_offset = offset;
			line_count += 1;
		}
		ch = -1;
	}
}

peek_byte :: proc(using t: ^Tokenizer) -> byte {
	if read_offset < len(src) {
		return src[read_offset];
	}
	return 0;
}

skip_whitespace :: proc(t: ^Tokenizer) {
	for t.ch == ' '  ||
	    t.ch == '\t' ||
	    t.ch == '\n' ||
	    t.ch == '\r' {
		advance_rune(t);
	}
}

is_letter :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		switch r {
		case '_':
			return true;
		case 'A'..'Z', 'a'..'z':
			return true;
		}
	}
	// TODO(bill): Add unicode lookup tables
	return false;
}
is_digit :: proc(r: rune) -> bool {
	// TODO(bill): Add unicode lookup tables
	return '0' <= r && r <= '9';
}


scan_comment :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1;
	next := -1;
	general: {
		if t.ch == '/' {
			advance_rune(t);
			for t.ch != '\n' && t.ch >= 0 {
				advance_rune(t);
			}

			next = t.offset;
			if t.ch == '\n' {
				next += 1;
			}
			break general;
		}

		/* style comment */
		advance_rune(t);
		for t.ch >= 0 {
			ch := t.ch;
			advance_rune(t);
			if ch == '*' && t.ch == '/' {
				advance_rune(t);
				next = t.offset;
				break general;
			}
		}

		error(t, offset, "comment not terminated");
	}

	lit := t.src[offset : t.offset];

	// NOTE(bill): Strip CR for line comments
	for len(lit) > 2 && lit[1] == '/' && lit[len(lit)-1] == '\r' {
		lit = lit[:len(lit)-1];
	}


	return string(lit);
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
	offset := t.offset;

	for is_letter(t.ch) || is_digit(t.ch) {
		advance_rune(t);
	}

	return string(t.src[offset : t.offset]);
}

scan_string :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1;

	for {
		ch := t.ch;
		if ch == '\n' || ch < 0 {
			error(t, offset, "string literal was not terminated");
			break;
		}
		advance_rune(t);
		if ch == '"' {
			break;
		}
		if ch == '\\' {
			scan_escape(t);
		}
	}

	return string(t.src[offset : t.offset]);
}

scan_raw_string :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1;

	for {
		ch := t.ch;
		if ch == '\n' || ch < 0 {
			error(t, offset, "raw string literal was not terminated");
			break;
		}
		advance_rune(t);
		if ch == '`' {
			break;
		}
	}

	return string(t.src[offset : t.offset]);
}

digit_val :: proc(r: rune) -> int {
	switch r {
	case '0'..'9':
		return int(r-'0');
	case 'A'..'F':
		return int(r-'A' + 10);
	case 'a'..'f':
		return int(r-'a' + 10);
	}
	return 16;
}

scan_escape :: proc(t: ^Tokenizer) -> bool {
	offset := t.offset;

	n: int;
	base, max: u32;
	switch t.ch {
	case 'a', 'b', 'e', 'f', 'n', 't', 'v', '\\', '\'', '\"':
		advance_rune(t);
		return true;

	case '0'..'7':
		n, base, max = 3, 8, 255;
	case 'x':
		advance_rune(t);
		n, base, max = 2, 16, 255;
	case 'u':
		advance_rune(t);
		n, base, max = 4, 16, utf8.MAX_RUNE;
	case 'U':
		advance_rune(t);
		n, base, max = 8, 16, utf8.MAX_RUNE;
	case:
		if t.ch < 0 {
			error(t, offset, "escape sequence was not terminated");
		} else {
			error(t, offset, "unknown escape sequence");
		}
		return false;
	}

	x: u32;
	for n > 0 {
		d := u32(digit_val(t.ch));
		for d >= base {
			if t.ch < 0 {
				error(t, t.offset, "escape sequence was not terminated");
			} else {
				error(t, t.offset, "illegal character %d in escape sequence", t.ch);
			}
			return false;
		}

		x = x*base + d;
		advance_rune(t);
		n -= 1;
	}

	if x > max || 0xd800 <= x && x <= 0xe000 {
		error(t, offset, "escape sequence is an invalid Unicode code point");
		return false;
	}
	return true;
}

scan_rune :: proc(t: ^Tokenizer) -> string {
	offset := t.offset-1;
	valid := true;
	n := 0;
	for {
		ch := t.ch;
		if ch == '\n' || ch < 0 {
			if valid {
				error(t, offset, "rune literal not terminated");
				valid = false;
			}
			break;
		}
		advance_rune(t);
		if ch == '\'' {
			break;
		}
		n += 1;
		if ch == '\\' {
			if !scan_escape(t)  {
				valid = false;
			}
		}
	}

	if valid && n != 1 {
		error(t, offset, "illegal rune literal");
	}

	return string(t.src[offset : t.offset]);
}

scan_number :: proc(t: ^Tokenizer, seen_decimal_point: bool) -> (token.Kind, string) {
	scan_mantissa :: proc(t: ^Tokenizer, base: int) {
		for digit_val(t.ch) < base || t.ch == '_' {
			advance_rune(t);
		}
	}
	scan_exponent :: proc(t: ^Tokenizer, kind: ^token.Kind) {
		if t.ch == 'e' || t.ch == 'E' {
			kind^ = token.Float;
			advance_rune(t);
			if t.ch == '-' || t.ch == '+' {
				advance_rune(t);
			}
			if digit_val(t.ch) < 10 {
				scan_mantissa(t, 10);
			} else {
				error(t, t.offset, "illegal floating-point exponent");
			}
		}

		// NOTE(bill): This needs to be here for sanity's sake
		if t.ch == 'i' {
			kind^ = token.Imag;
			advance_rune(t);
		}
	}
	scan_fraction :: proc(t: ^Tokenizer, kind: ^token.Kind) -> (early_exit: bool) {
		if t.ch == '.' && peek_byte(t) == '.' {
			return true;
		}
		if t.ch == '.' {
			kind^ = token.Float;
			advance_rune(t);
			scan_mantissa(t, 10);
		}
		return false;
	}


	offset := t.offset;
	kind := token.Integer;

	if seen_decimal_point {
		offset -= 1;
		kind = token.Float;
		scan_mantissa(t, 10);
		scan_exponent(t, &kind);
	} else {
		if t.ch == '0' {
			int_base :: inline proc(t: ^Tokenizer, kind: ^token.Kind, base: int, msg: string) {
				prev := t.offset;
				advance_rune(t);
				scan_mantissa(t, base);
				if t.offset - prev <= 1 {
					kind^ = token.Invalid;
					error(t, t.offset, msg);
				}
			}

			advance_rune(t);
			switch t.ch {
			case 'b': int_base(t, &kind,  2, "illegal binary integer");
			case 'o': int_base(t, &kind,  8, "illegal octal integer");
			case 'd': int_base(t, &kind, 10, "illegal decimal integer");
			case 'z': int_base(t, &kind, 12, "illegal dozenal integer");
			case 'x': int_base(t, &kind, 16, "illegal hexadecimal integer");
			case 'h':
				prev := t.offset;
				advance_rune(t);
				scan_mantissa(t, 16);
				if t.offset - prev <= 1 {
					kind = token.Invalid;
					error(t, t.offset, "illegal hexadecimal floating-point number");
				} else {
					sub := t.src[prev+1 : t.offset];
					digit_count := 0;
					for d in sub {
						if d != '_' {
							digit_count += 1;
						}
					}

					switch digit_count {
					case 8, 16: break;
					case:
						error(t, t.offset, "invalid hexadecimal floating-point number, expected 8 or 16 digits, got %d", digit_count);
					}
				}

			case:
				seen_decimal_point = false;
				scan_mantissa(t, 10);
				if t.ch == '.' {
					seen_decimal_point = true;
					if scan_fraction(t, &kind) {
						return kind, string(t.src[offset : t.offset]);
					}
				}
				scan_exponent(t, &kind);
				return kind, string(t.src[offset : t.offset]);
			}
		}
	}

	scan_mantissa(t, 10);

	if scan_fraction(t, &kind) {
		return kind, string(t.src[offset : t.offset]);
	}

	scan_exponent(t, &kind);

	return kind, string(t.src[offset : t.offset]);
}


scan :: proc(t: ^Tokenizer) -> token.Token {
	switch2 :: proc(t: ^Tokenizer, tok0, tok1: token.Kind) -> token.Kind {
		if t.ch == '=' {
			advance_rune(t);
			return tok1;
		}
		return tok0;
	}
	switch3 :: proc(t: ^Tokenizer, tok0, tok1: token.Kind, ch2: rune, tok2: token.Kind) -> token.Kind {
		if t.ch == '=' {
			advance_rune(t);
			return tok1;
		}
		if t.ch == ch2 {
			advance_rune(t);
			return tok2;
		}
		return tok0;
	}
	switch4 :: proc(t: ^Tokenizer, tok0, tok1: token.Kind, ch2: rune, tok2, tok3: token.Kind) -> token.Kind {
		if t.ch == '=' {
			advance_rune(t);
			return tok1;
		}
		if t.ch == ch2 {
			advance_rune(t);
			if t.ch == '=' {
				advance_rune(t);
				return tok3;
			}
			return tok2;
		}
		return tok0;
	}


	skip_whitespace(t);

	offset := t.offset;

	kind: token.Kind;
	lit:  string;
	pos := offset_to_pos(t, offset);

	switch ch := t.ch; true {
	case is_letter(ch):
		lit = scan_identifier(t);
		kind = token.Ident;
		if len(lit) > 1 {
			// TODO(bill): Maybe have a hash table lookup rather than this linear search
			for i in token.B_Keyword_Begin .. token.B_Keyword_End {
				if lit == token.tokens[i] {
					kind = token.Kind(i);
					break;
				}
			}
		}
	case '0' <= ch && ch <= '9':
		kind, lit = scan_number(t, false);
	case:
		advance_rune(t);
		switch ch {
		case -1:
			kind = token.EOF;
		case '"':
			kind = token.String;
			lit = scan_string(t);
		case '\'':
			kind = token.Rune;
			lit = scan_rune(t);
		case '`':
			kind = token.String;
			lit = scan_raw_string(t);
		case '=':
			if t.ch == '>' {
				advance_rune(t);
				kind = token.Double_Arrow_Right;
			} else {
				kind = switch2(t, token.Eq, token.Cmp_Eq);
			}
		case '!': kind = switch2(t, token.Eq, token.Not_Eq);
		case '#': kind = token.Hash;
		case '@': kind = token.At;
		case '$': kind = token.Dollar;
		case '^': kind = token.Pointer;
		case '+': kind = switch2(t, token.Add, token.Add_Eq);
		case '-':
			if t.ch == '>' {
				advance_rune(t);
				kind = token.Arrow_Right;
			} else if t.ch == '-' && peek_byte(t) == '-' {
				advance_rune(t);
				advance_rune(t);
				kind = token.Undef;
			} else {
				kind = switch2(t, token.Sub, token.Sub_Eq);
			}
		case '*': kind = switch2(t, token.Mul, token.Mul_Eq);
		case '/':
			if t.ch == '/' || t.ch == '*' {
				kind = token.Comment;
				lit = scan_comment(t);
			} else {
				kind = switch2(t, token.Quo, token.Quo_Eq);
			}
		case '%': kind = switch4(t, token.Mod, token.Mod_Eq, '%', token.Mod_Mod, token.Mod_Mod_Eq);
		case '&':
			if t.ch == '~' {
				advance_rune(t);
				kind = switch2(t, token.And_Not, token.And_Not_Eq);
			} else {
				kind = switch3(t, token.And, token.And_Eq, '&', token.Cmp_And);
			}
		case '|': kind = switch3(t, token.Or, token.Or_Eq, '&', token.Cmp_Or);
		case '~': kind = token.Xor;
		case '<':
			if t.ch == '-' {
				advance_rune(t);
				kind = token.Arrow_Left;
			} else {
				kind = token.Lt;
			}
		case '>': kind = token.Gt;

		case '≠': kind = token.Not_Eq;
		case '≤': kind = token.Lt_Eq;
		case '≥': kind = token.Gt_Eq;

		case '.':
			if '0' <= t.ch && t.ch <= '9' {
				kind, lit = scan_number(t, true);
			} else {
				kind = token.Period;
				if t.ch == '.' {
					advance_rune(t);
					kind = token.Ellipsis;
				}
			}
		case ':': kind = token.Colon;
		case ',': kind = token.Comma;
		case ';': kind = token.Semicolon;
		case '(': kind = token.Open_Paren;
		case ')': kind = token.Close_Paren;
		case '[': kind = token.Open_Bracket;
		case ']': kind = token.Close_Bracket;
		case '{': kind = token.Open_Brace;
		case '}': kind = token.Close_Brace;
		case:
			if ch != utf8.RUNE_BOM {
				error(t, t.offset, "illegal character %d", ch);
			}
			kind = token.Invalid;
		}
	}

	if lit == "" {
		lit = string(t.src[offset : t.offset]);
	}
	return token.Token{kind, lit, pos};
}
