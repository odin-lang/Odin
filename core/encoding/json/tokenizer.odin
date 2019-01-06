package json

import "core:unicode/utf8"

Token :: struct {
	using pos: Pos,
	kind: Kind,
	text: string,
}

Kind :: enum {
	Invalid,

	Null,
	False,
	True,

	Ident,

	Integer,
	Float,
	String,

	Colon,
	Comma,

	Open_Brace,
	Close_Brace,

	Open_Bracket,
	Close_Bracket,
}

Tokenizer :: struct {
	using pos: Pos,
	data: string,
	r: rune, // current rune
	w: int,  // current rune width in bytes
	curr_line_offset: int,
}



make_tokenizer :: proc(data: string) -> Tokenizer {
	t := Tokenizer{pos = {line=1}, data = data};
	next_rune(&t);
	return t;
}

next_rune :: proc(t: ^Tokenizer) -> rune #no_bounds_check {
	if t.offset >= len(t.data) {
		return utf8.RUNE_EOF;
	}
	t.offset += t.w;
	t.r, t.w = utf8.decode_rune_in_string(t.data[t.offset:]);
	t.pos.column = t.offset - t.curr_line_offset;
	return t.r;
}


get_token :: proc(t: ^Tokenizer) -> (token: Token, err: Error) {
	skip_digits :: proc(t: ^Tokenizer) {
		for t.offset < len(t.data) {
			next_rune(t);
			if '0' <= t.r && t.r <= '9' {
				// Okay
			} else {
				return;
			}
		}
	}

	scan_espace :: proc(t: ^Tokenizer) -> bool {
		switch t.r {
		case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
			next_rune(t);
			return true;
		case 'u':
			// Expect 4 hexadecimal digits
			for i := 0; i < 4; i += 1 {
				r := next_rune(t);
				switch r {
				case '0'..'9', 'a'..'f', 'A'..'F':
					// Okay
				case:
					return false;
				}
			}
		case:
			// Ignore the next rune regardless
			next_rune(t);
		}
		return false;
	}

	skip_whitespace :: proc(t: ^Tokenizer) -> rune {
		loop: for t.offset < len(t.data) {
			switch t.r {
			case ' ', '\t', '\v', '\f', '\r':
				next_rune(t);
			case '\n':
				t.line += 1;
				t.curr_line_offset = t.offset;
				t.pos.column = 1;
				next_rune(t);
			case:
				break loop;
			}
		}
		return t.r;
	}

	skip_whitespace(t);

	token.pos = t.pos;
	token.kind = Kind.Invalid;

	curr_rune := t.r;
	next_rune(t);

	switch curr_rune {
	case utf8.RUNE_ERROR:
		err = Error.Illegal_Character;
	case utf8.RUNE_EOF, '\x00':
		err = Error.EOF;

	case 'A'..'Z', 'a'..'z', '_':
		token.kind = Kind.Ident;

		for t.offset < len(t.data) {
			switch next_rune(t) {
			case 'A'..'Z', 'a'..'z', '0'..'9', '_':
				continue;
			}

			break;
		}

		switch str := t.data[token.offset:t.offset]; str {
		case "null":  token.kind = Kind.Null;
		case "false": token.kind = Kind.False;
		case "true":  token.kind = Kind.True;
		}

	case '-':
		switch t.r {
		case '0'..'9':
			// Okay
		case:
			// Illegal use of +/-
			err = Error.Illegal_Character;
			break;
		}
		fallthrough;

	case '0'..'9':
		token.kind = Kind.Integer;

		skip_digits(t);
		if t.r == '.' {
			token.kind = Kind.Float;
			next_rune(t);
			skip_digits(t);
		}
		if t.r == 'e' || t.r == 'E' {
			switch r := next_rune(t); r {
			case '+', '-':
				next_rune(t);
			}
			skip_digits(t);
		}

		str := t.data[token.offset:t.offset];
		if !is_valid_number(str) {
			err = Error.Invalid_Number;
		}


	case '"':
		token.kind = Kind.String;
		quote := curr_rune;
		for t.offset < len(t.data) {
			r := t.r;
			if r == '\n' || r < 0 {
				err = Error.String_Not_Terminated;
				break;
			}
			next_rune(t);
			if r == quote {
				break;
			}
			if r == '\\' {
				scan_espace(t);
			}
		}

		if !is_valid_string_literal(t.data[token.offset : t.offset]) {
			err = Error.Invalid_String;
		}

	case ',': token.kind = Kind.Comma;
	case ':': token.kind = Kind.Colon;
	case '{': token.kind = Kind.Open_Brace;
	case '}': token.kind = Kind.Close_Brace;
	case '[': token.kind = Kind.Open_Bracket;
	case ']': token.kind = Kind.Close_Bracket;

	case: err = Error.Illegal_Character;
	}

	token.text = t.data[token.offset : t.offset];

	return;
}



is_valid_number :: proc(s: string) -> bool {
	if s == "" {
		return false;
	}

	if s[0] == '-' {
		s = s[1:];
		if s == "" {
			return false;
		}
	}

	switch s[0] {
	case '0':
		s = s[1:];
	case '1'..'9':
		s = s[1:];
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' do s = s[1:];
	case:
		return false;
	}


	if len(s) >= 2 && s[0] == '.' && '0' <= s[1] && s[1] <= '9' {
		s = s[2:];
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' do s = s[1:];
	}

	if len(s) >= 2 && (s[0] == 'e' || s[0] == 'E') {
		s = s[1:];
		switch s[0] {
		case '+', '-':
			s = s[1:];
			if s == "" {
				return false;
			}
		}
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' do s = s[1:];
	}

	// The string should be empty now to be valid
	return s == "";
}

is_valid_string_literal :: proc(s: string) -> bool {
	if len(s) < 2 || s[0] != '"' || s[len(s)-1] != '"' {
		return false;
	}
	s = s[1 : len(s)-1];

	i := 0;
	for i < len(s) {
		c := s[i];
		switch {
		case c == '\\':
			i += 1;
			if i >= len(s) {
				return false;
			}
			switch s[i] {
			case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
				i += 1;
			case 'u':
				if i >= len(s) {
					return false;
				}
				hex := s[i+1:];
				if len(hex) < 4 {
					return false;
				}
				hex = hex[:4];
				i += 5;

				for j := 0; j < 4; j += 1 {
					c := hex[j];
					switch c {
					case '0'..'9', 'a'..'z', 'A'..'Z':
						// Okay
					case:
						return false;
					}
				}

			case: return false;
			}

		case c == '"', c < ' ':
			return false;

		case c < utf8.RUNE_SELF:
			i += 1;

		case:
			r, width := utf8.decode_rune_in_string(s[i:]);
			if r == utf8.RUNE_ERROR && width == 1 {
				return false;
			}
			i += width;
		}
	}
	if i == len(s) {
		return true;
	}
	return true;
}
