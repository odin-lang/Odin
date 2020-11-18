package text_scanner

import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

Position :: struct {
	filename: string, // filename, if present
	offset:   int,    // byte offset, starting @ 0
	line:     int,    // line number, starting @ 1
	column:   int,    // column number, starting @ 1 (character count per line)
}

position_is_valid :: proc(pos: Position) -> bool {
	return pos.line > 0;
}

position_to_string :: proc(pos: Position, allocator := context.temp_allocator) -> string {
	s := pos.filename;
	if s == "" {
		s = "<input>";
	}

	context.allocator = allocator;
	if position_is_valid(pos) {
		return fmt.aprintf("%s(%d:%d)", s, pos.line, pos.column);
	} else {
		return strings.clone(s);
	}
}

EOF        :: -1;
Ident      :: -2;
Int        :: -3;
Float      :: -4;
Char       :: -5;
String     :: -6;
Raw_String :: -7;
Comment    :: -8;

Scan_Flag :: enum u32 {
	Scan_Idents,
	Scan_Ints,
	Scan_C_Int_Prefixes,
	Scan_Floats,
	Scan_Chars,
	Scan_Strings,
	Scan_Raw_Strings,
	Scan_Comments,
	Skip_Comments,
}
Scan_Flags :: bit_set[Scan_Flag; u32];

Odin_Like_Tokens :: Scan_Flags{.Scan_Idents, .Scan_Ints, .Scan_Floats, .Scan_Chars, .Scan_Strings, .Scan_Raw_Strings, .Scan_Comments, .Skip_Comments};
C_Like_Tokens    :: Scan_Flags{.Scan_Idents, .Scan_Ints, .Scan_C_Int_Prefixes, .Scan_Floats, .Scan_Chars, .Scan_Strings, .Scan_Raw_Strings, .Scan_Comments, .Skip_Comments};

Odin_Whitespace :: 1<<'\t' | 1<<'\n' | 1<<'\r' | 1<<' ';
C_Whitespace    :: 1<<'\t' | 1<<'\n' | 1<<'\r' | 1<<'\v' | 1<<'\f' | 1<<' ';


Scanner :: struct {
	src: string,

	src_pos: int,
	src_end: int,

	tok_pos: int,
	tok_end: int,

	ch: rune,

	line:   int,
	column: int,
	prev_line_len: int,
	prev_char_len: int,

	error: proc(s: ^Scanner, msg: string),
	error_count: int,

	flags: Scan_Flags,
	whitespace: u64,

	is_ident_rune: proc(ch: rune, i: int) -> bool,

	pos: Position,
}

init :: proc(s: ^Scanner, src: string, filename := "") -> ^Scanner {
	s^ = {};

	s.src = src;
	s.pos.filename = filename;

	s.tok_pos = -1;

	s.ch = -2; // no char read yet, not an EOF

	s.line = 1;

	s.flags = Odin_Like_Tokens;
	s.whitespace = Odin_Whitespace;

	return s;
}


@(private)
advance :: proc(s: ^Scanner) -> rune {
	if s.src_pos >= len(s.src) {
		s.prev_char_len = 0;
		return EOF;
	}
	ch, width := rune(s.src[s.src_pos]), 1;

	if ch >= utf8.RUNE_SELF {
		ch, width = utf8.decode_rune_in_string(s.src[s.src_pos:]);
		if ch == utf8.RUNE_ERROR && width == 1 {
			s.src_pos += width;
			s.prev_char_len = width;
			s.column += 1;
			error(s, "invalid UTF-8 encoding");
			return ch;
		}
	}

	s.src_pos += width;
	s.prev_char_len = width;
	s.column += 1;

	switch ch {
	case 0:
		error(s, "invalid character NUL");
	case '\n':
		s.line += 1;
		s.prev_line_len = s.column;
		s.column = 0;
	}

	return ch;
}

next :: proc(s: ^Scanner) -> rune {
	s.tok_pos = -1;
	s.pos.line = 0;
	ch := peek(s);
	if ch != EOF {
		s.ch = advance(s);
	}
	return ch;
}

peek :: proc(s: ^Scanner) -> rune {
	if s.ch == -2 {
		s.ch = advance(s);
		if s.ch == '\ufeff' { // Ignore BOM
			s.ch = advance(s);
		}
	}
	return s.ch;
}


error :: proc(s: ^Scanner, msg: string) {
	s.error_count += 1;
	if s.error != nil {
		s.error(s, msg);
		return;
	}
	p := s.pos;
	if !position_is_valid(p) {
		p = position(s);
	}

	s := p.filename;
	if s == "" {
		s = "<input>";
	}

	if position_is_valid(p) {
		fmt.eprintf("%s(%d:%d): %s\n", s, p.line, p.column, msg);
	} else {
		fmt.eprintf("%s: %s\n", s, msg);
	}
}

errorf :: proc(s: ^Scanner, format: string, args: ..any) {
	error(s, fmt.tprintf(format, ..args));
}

@(private)
is_ident_rune :: proc(s: ^Scanner, ch: rune, i: int) -> bool {
	if s.is_ident_rune != nil {
		return s.is_ident_rune(ch, i);
	}
	return ch == '_' || unicode.is_letter(ch) || unicode.is_digit(ch) && i > 0;
}

@(private)
scan_identifier :: proc(s: ^Scanner) -> rune {
	ch := advance(s);
	for i := 1; is_ident_rune(s, ch, i); i += 1 {
		ch = advance(s);
	}
	return ch;
}

@(private) lower      :: proc(ch: rune) -> rune { return ('a' - 'A') | ch; }
@(private) is_decimal :: proc(ch: rune) -> bool { return '0' <= ch && ch <= '9'; }
@(private) is_hex     :: proc(ch: rune) -> bool { return '0' <= ch && ch <= '9' || 'a' <= lower(ch) && lower(ch) <= 'f'; }



@(private)
scan_number :: proc(s: ^Scanner, ch: rune, seen_dot: bool) -> (rune, rune) {
	lit_name :: proc(prefix: rune) -> string {
		switch prefix {
		case 'b': return "binary literal";
		case 'o': return "octal literal";
		case 'z': return "dozenal literal";
		case 'x': return "hexadecimal literal";
		}
		return "decimal literal";
	}

	digits :: proc(s: ^Scanner, ch0: rune, base: int, invalid: ^rune) -> (ch: rune, digsep: int) {
		ch = ch0;
		if base <= 10 {
			max := rune('0' + base);
			for is_decimal(ch) || ch == '_' {
				ds := 1;
				if ch == '_' {
					ds = 2;
				} else if ch >= max && invalid^ == 0 {
					invalid^ = ch;
				}
				digsep |= ds;
				ch = advance(s);
			}
		} else {
			for is_hex(ch) || ch == '_' {
				ds := 1;
				if ch == '_' {
					ds = 2;
				}
				digsep |= ds;
				ch = advance(s);
			}
		}
		return;
	}

	ch, seen_dot := ch, seen_dot;

	base := 10;
	prefix := rune(0);
	digsep := 0;
	invalid := rune(0);

	tok: rune;
	ds: int;

	if !seen_dot {
		tok = Int;
		ch0 := ch;
		if ch == '0' {
			ch = advance(s);

			p := lower(ch);
			if .Scan_C_Int_Prefixes in s.flags {
				switch lower(ch) {
				case 'b':
					ch = advance(s);
					base, prefix = 2, 'b';
				case 'x':
					ch = advance(s);
					base, prefix = 16, 'x';
				case:
					base, prefix = 8, 'o';
					digsep = 1; // Leading zero
				}
			} else {
				switch lower(ch) {
				case 'b':
					ch = advance(s);
					base, prefix = 2, 'b';
				case 'o':
					ch = advance(s);
					base, prefix = 8, 'o';
				case 'd':
					ch = advance(s);
					base, prefix = 10, 'd';
				case 'z':
					ch = advance(s);
					base, prefix = 12, 'z';
				case 'x':
					ch = advance(s);
					base, prefix = 16, 'x';
				case:
					digsep = 1; // Leading zero
				}
			}
		}

		ch, ds = digits(s, ch, base, &invalid);
		digsep |= ds;
		if ch == '.' && .Scan_Floats in s.flags {
			ch = advance(s);
			seen_dot = true;
		}
	}

	if seen_dot {
		tok = Float;
		if prefix != 0 && prefix != 'x' {
			errorf(s, "invalid radix point in %s", lit_name(prefix));
		}
		ch, ds = digits(s, ch, base, &invalid);
		digsep |= ds;
	}

	if digsep&1 == 0 {
		errorf(s, "%s has no digits", lit_name(prefix));
	}

	if e := lower(ch); (e == 'e' || e == 'p') && .Scan_Floats in s.flags {
		switch {
		case e == 'e' && prefix != 0:
			errorf(s, "%q exponent requires decimal mantissa", ch);
		case e == 'p' && prefix != 'x':
			errorf(s, "%q exponent requires hexadecimal mantissa", ch);
		}
		ch = advance(s);
		tok = Float;
		if ch == '+' || ch == '-' {
			ch = advance(s);
		}
		ch, ds = digits(s, ch, 10, nil);
		digsep |= ds;
		if ds&1 == 0 {
			error(s, "exponent has no digits");
		}
	} else if prefix == 'x' && tok == Float {
		error(s, "hexadecimal mantissa requires a 'p' exponent");
	}

	if tok == Int && invalid != 0 {
		errorf(s, "invalid digit %q in %s", invalid, lit_name(prefix));
	}

	if digsep&2 != 0 {
		s.tok_end = s.src_pos - s.prev_char_len;
	}
	return tok, ch;
}

@(private)
scan_string :: proc(s: ^Scanner, quote: rune) -> (n: int) {
	digit_val :: proc(ch: rune) -> int {
		switch v := lower(ch); v {
		case '0'..'9': return int(v - '0');
		case 'a'..'z': return int(v - 'a');
		}
		return 16;
	}

	scan_digits :: proc(s: ^Scanner, ch: rune, base, n: int) -> rune {
		ch, n := ch, n;
		for n > 0 && digit_val(ch) < base {
			ch = advance(s);
			n -= 1;
		}
		if n > 0 {
			error(s, "invalid char escape");
		}
		return ch;
	}

	ch := advance(s);
	for ch != quote {
		if ch == '\n' || ch < 0 {
			error(s, "literal no terminated");
			return;
		}
		if ch == '\\' {
			ch = advance(s);
			switch ch {
			case quote, 'a', 'b', 'e', 'f', 'n', 'r', 't', 'v', '\\':
				ch = advance(s);
			case '0'..'7': ch = scan_digits(s, advance(s), 8, 3);
			case 'x':      ch = scan_digits(s, advance(s), 16, 2);
			case 'u':      ch = scan_digits(s, advance(s), 16, 4);
			case 'U':      ch = scan_digits(s, advance(s), 16, 8);
			case:
				error(s, "invalid char escape");
			}
		} else {
			ch = advance(s);
		}
		n += 1;
	}
	return;
}

@(private)
scan_raw_string :: proc(s: ^Scanner) {
	ch := advance(s);
	for ch != '`' {
		if ch < 0 {
			error(s, "literal not terminated");
			return;
		}
		ch = advance(s);
	}
}

@(private)
scan_char :: proc(s: ^Scanner) {
	if scan_string(s, '\'') != 1 {
		error(s, "invalid char literal");
	}
}

@(private)
scan_comment :: proc(s: ^Scanner, ch: rune) -> rune {
	ch := ch;
	if ch == '/' { // line comment
		ch = advance(s);
		for ch != '\n' && ch >= 0 {
			ch = advance(s);
		}
		return ch;
	}

	// block /**/ comment
	ch = advance(s);
	for {
		if ch < 0 {
			error(s, "comment not terminated");
			break;
		}
		ch0 := ch;
		ch = advance(s);
		if ch0 == '*' && ch == '/' {
			return advance(s);
		}
	}
	return ch;
}

scan :: proc(s: ^Scanner) -> (tok: rune) {
	ch := peek(s);
	if ch == EOF {
		return ch;
	}

	// reset position
	s.tok_pos = -1;
	s.pos.line = 0;

	redo: for {
		for s.whitespace & (1<<uint(ch)) != 0 {
			ch = advance(s);
		}

		s.tok_pos = s.src_pos - s.prev_char_len;
		s.pos.offset = s.tok_pos;

		if s.column > 0 {
			s.pos.line = s.line;
			s.pos.column = s.column;
		} else {
			// previous character was newline
			s.pos.line = s.line - 1;
			s.pos.column = s.prev_line_len;
		}

		tok = ch;
		if is_ident_rune(s, ch, 0) {
			if .Scan_Idents in s.flags {
				tok = Ident;
				ch = scan_identifier(s);
			} else {
				ch = advance(s);
			}

		} else if is_decimal(ch) {
			if s.flags >= {.Scan_Ints, .Scan_Floats} {
				tok, ch = scan_number(s, ch, false);
			} else {
				ch = advance(s);
			}
		} else {
			switch ch {
			case EOF:
				break;
			case '"':
				if .Scan_Strings in s.flags {
					scan_string(s, '"');
					tok = String;
				}
				ch = advance(s);
			case '\'':
				if .Scan_Chars in s.flags {
					scan_string(s, '\'');
					tok = Char;
				}
				ch = advance(s);
			case '`':
				if .Scan_Raw_Strings in s.flags {
					scan_raw_string(s);
					tok = Raw_String;
				}
				ch = advance(s);
			case '.':
				ch = advance(s);
				if is_decimal(ch) && .Scan_Floats in s.flags {
					tok, ch = scan_number(s, ch, true);
				}
			case '/':
				ch = advance(s);
				if (ch == '/' || ch == '*') && .Scan_Comments in s.flags {
					if .Skip_Comments in s.flags {
						s.tok_pos = -1;
						ch = scan_comment(s, ch);
						continue redo;
					}
					ch = scan_comment(s, ch);
					tok = Comment;
				}
			case:
				ch = advance(s);
			}
		}

		break redo;
	}

	s.tok_end = s.src_pos - s.prev_char_len;

	s.ch = ch;
	return tok;
}

position :: proc(s: ^Scanner) -> Position {
	pos: Position;
	pos.filename = s.pos.filename;
	pos.offset = s.src_pos - s.prev_char_len;
	switch {
	case s.column > 0:
		pos.line = s.line;
		pos.column = s.column;
	case s.prev_line_len > 0:
		pos.line = s.line-1;
		pos.column = s.prev_line_len;
	case:
		pos.line = 1;
		pos.column = 1;
	}
	return pos;
}

token_text :: proc(s: ^Scanner) -> string {
	if s.tok_pos < 0 {
		return "";
	}
	return string(s.src[s.tok_pos:s.tok_end]);
}

token_string :: proc(tok: rune, allocator := context.temp_allocator) -> string {
	context.allocator = allocator;
	switch tok {
	case EOF:        return strings.clone("EOF");
	case Ident:      return strings.clone("Ident");
	case Int:        return strings.clone("Int");
	case Float:      return strings.clone("Float");
	case Char:       return strings.clone("Char");
	case String:     return strings.clone("String");
	case Raw_String: return strings.clone("Raw_String");
	case Comment:    return strings.clone("Comment");
	}
	return fmt.aprintf("%q", tok);
}
