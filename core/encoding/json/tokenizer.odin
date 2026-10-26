package encoding_json

import "core:unicode/utf8"

Pos :: struct {
	offset: int,
	line:   int,
	column: int,
}

Token :: struct {
	using pos: Pos,
	kind: Token_Kind,
	text: string,
}

Token_Kind :: enum {
	Invalid,
	EOF,

	Null,
	False,
	True,

	Infinity,
	NaN,

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
	using pos:        Pos,
	data:             string,
	r:                rune, // current rune
	w:                int,  // current rune width in bytes
	curr_line_offset: int,
	spec:             Specification,
	parse_integers:   bool,
	insert_comma:     bool,
}



@(require_results)
make_tokenizer :: proc(data: string, spec := DEFAULT_SPECIFICATION, parse_integers := false) -> Tokenizer {
	t := Tokenizer{pos = {line=1}, data = data, spec = spec, parse_integers = parse_integers}
	next_rune(&t)
	if t.r == utf8.RUNE_BOM {
		next_rune(&t)
	}
	return t
}

next_rune :: proc(t: ^Tokenizer) -> rune #no_bounds_check {
	if t.offset >= len(t.data) {
		t.r = utf8.RUNE_EOF
	} else {
		move_to(t, t.offset + t.w)
	}
	return t.r
}

@(private="file")
move_to :: #force_inline proc "contextless" (t: ^Tokenizer, offset: int) #no_bounds_check {
	t.offset     = offset
	t.pos.column = offset - t.curr_line_offset

	switch {
	case offset >= len(t.data):
		t.r, t.w = utf8.RUNE_EOF, 0
	case t.data[offset] < utf8.RUNE_SELF:
		t.r, t.w = rune(t.data[offset]), 1
	case:
		t.r, t.w = utf8.decode_rune_in_string(t.data[offset:])
	}
}

@(private="file")
digits_end :: #force_inline proc "contextless" (s: string, i: int) -> int #no_bounds_check {
	i := i
	for i < len(s) && '0' <= s[i] && s[i] <= '9' {
		i += 1
	}
	return i
}


@(require_results)
get_token :: proc(t: ^Tokenizer) -> (token: Token, err: Error) {
	skip_digits :: proc(t: ^Tokenizer) {
		if i := digits_end(t.data, t.offset); i != t.offset {
			move_to(t, i)
		}
	}
	skip_hex_digits :: proc(t: ^Tokenizer) {
		for t.offset < len(t.data) {
			next_rune(t)
			switch t.r {
			case '0'..='9', 'a'..='f', 'A'..='F':
				// Okay
			case:
				return
			}
		}
	}

	@(require_results)
	scan_escape :: proc(t: ^Tokenizer) -> bool {
		switch t.r {
		case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
			next_rune(t)
			return true
		case 'u':
			// Expect 4 hexadecimal digits
			for i := 0; i < 4; i += 1 {
				r := next_rune(t)
				switch r {
				case '0'..='9', 'a'..='f', 'A'..='F':
					// Okay
				case:
					return false
				}
			}
			return true
		case:
			// Ignore the next rune regardless
			next_rune(t)
		}
		return false
	}

	skip_whitespace :: proc(t: ^Tokenizer, on_newline: bool) #no_bounds_check {
		i := t.offset
		loop: for i < len(t.data) {
			switch t.data[i] {
			case ' ', '\t', '\v', '\f', '\r':
				i += 1
			case '\n':
				if on_newline {
					break loop
				}
				t.line += 1
				t.curr_line_offset = i
				i += 1
			case 0xe2, 0xef:
				if t.spec != .JSON {
					switch t.data[i:min(i+3, len(t.data))] {
					case "\u2028", "\u2029", "\uFEFF":
						i += 3
						continue loop
					}
				}
				break loop
			case:
				break loop
			}
		}
		if i != t.offset {
			move_to(t, i)
		}
	}

	skip_to_next_line :: proc(t: ^Tokenizer) {
		for t.offset < len(t.data) {
			r := next_rune(t)
			if r == '\n' {
				return
			}
		}
	}

	skip_alphanum :: proc(t: ^Tokenizer) #no_bounds_check {
		i := t.offset
		loop: for i < len(t.data) {
			switch t.data[i] {
			case 'A'..='Z', 'a'..='z', '0'..='9', '_':
				i += 1
			case:
				break loop
			}
		}
		if i != t.offset {
			move_to(t, i)
		}
	}

	skip_whitespace(t, t.insert_comma)

	token.pos = t.pos

	token.kind = .Invalid

	curr_rune := t.r
	next_rune(t)

	block: switch curr_rune {
	case utf8.RUNE_ERROR:
		err = .Illegal_Character
	case utf8.RUNE_EOF, '\x00':
		token.kind = .EOF
		err = .EOF

	case '\n':
		t.insert_comma = false
		token.text = ","
		token.kind = .Comma
		return

	case 'A'..='Z', 'a'..='z', '_':
		token.kind = .Ident

		skip_alphanum(t)

		switch str := string(t.data[token.offset:t.offset]); str {
		case "null":  token.kind = .Null
		case "false": token.kind = .False
		case "true":  token.kind = .True
		case:
			if t.spec != .JSON {
				switch str {
				case "Infinity": token.kind = .Infinity
				case "NaN":      token.kind = .NaN
				}
			}
		}

	case '+':
		err = .Illegal_Character
		if t.spec == .JSON {
			break
		}
		fallthrough

	case '-':
		switch t.r {
		case '0'..='9':
			// Okay
		case:
			// Illegal use of +/-
			err = .Illegal_Character

			if t.spec != .JSON {
				if t.r == 'I' || t.r == 'N' {
					skip_alphanum(t)
				}
				switch string(t.data[token.offset:t.offset]) {
				case "-Infinity": token.kind = .Infinity
				case "-NaN":      token.kind = .NaN
				}
			}
			break block
		}
		fallthrough

	case '0'..='9':
		token.kind = t.parse_integers ? .Integer : .Float
		if t.spec != .JSON { // Hexadecimal Numbers
			if curr_rune == '0' && (t.r == 'x' || t.r == 'X') {
				next_rune(t)
				skip_hex_digits(t)
				break
			}
		}

		data  := t.data
		first := token.offset+1 if curr_rune == '-' || curr_rune == '+' else token.offset

		i := digits_end(data, t.offset)
		int_digits := i - first

		has_dot, frac_digits := false, 0
		if i < len(data) && data[i] == '.' {
			token.kind = .Float
			end := digits_end(data, i+1)
			has_dot, frac_digits, i = true, end - (i+1), end
		}

		has_exp, exp_digits := false, 0
		if i < len(data) && (data[i] == 'e' || data[i] == 'E') {
			token.kind = .Float
			i += 1
			if i < len(data) && (data[i] == '+' || data[i] == '-') {
				i += 1
			}
			end := digits_end(data, i)
			has_exp, exp_digits, i = true, end - i, end
		}

		move_to(t, i)

		valid := (data[first] != '0' || int_digits == 1) &&
		         (!has_dot || frac_digits > 0 || (t.spec != .JSON && !has_exp)) &&
		         (!has_exp || exp_digits > 0)
		if !valid {
			err = .Invalid_Number
		}

	case '.':
		err = .Illegal_Character
		if t.spec != .JSON { // Allow leading decimal point
			skip_digits(t)
			if t.r == 'e' || t.r == 'E' {
				switch r := next_rune(t); r {
				case '+', '-':
					next_rune(t)
				}
				skip_digits(t)
			}
			str := string(t.data[token.offset:t.offset])
			if !is_valid_number(str, t.spec) {
				err = .Invalid_Number
			}
		}


	case '\'':
		err = .Illegal_Character
		if t.spec == .JSON {
			break
		}
		fallthrough
	case '"':
		token.kind = .String
		quote := byte(curr_rune)

		simple, closed := true, false
		i := t.offset
		for i < len(t.data) {
			c := t.data[i]
			if c == '\n' {
				err = .String_Not_Terminated
				break
			}
			i += 1
			if c == quote {
				closed = true
				break
			}
			switch {
			case c == '\\':
				simple = false
				move_to(t, i)
				_ = scan_escape(t)
				i = t.offset
			case c < ' ', c >= utf8.RUNE_SELF:
				simple = false
			}
		}

		move_to(t, i)

		if !simple || !closed {
			str := string(t.data[token.offset : t.offset])
			if !is_valid_string_literal(str, t.spec) {
				err = .Invalid_String
			}
		}


	case ',':
		token.kind = .Comma
		t.insert_comma = false
	case ':': token.kind = .Colon
	case '{': token.kind = .Open_Brace
	case '}': token.kind = .Close_Brace
	case '[': token.kind = .Open_Bracket
	case ']': token.kind = .Close_Bracket

	case '=':
		if t.spec == .MJSON {
			token.kind = .Colon
		} else {
			err = .Illegal_Character
		}

	case '/':
		err = .Illegal_Character
		if t.spec != .JSON {
			switch t.r {
			case '/':
				// Single-line comments
				skip_to_next_line(t)
				return get_token(t)
			case '*':
				// None-nested multi-line comments
				for t.offset < len(t.data) {
					if next_rune(t) == '*' {
						if next_rune(t) == '/' {
							next_rune(t)
							return get_token(t)
						}
					}
				}
				err = .EOF
			}
		}

	case: err = .Illegal_Character
	}

	token.text = string(t.data[token.offset : t.offset])

	if t.spec == .MJSON {
		switch token.kind {
		case .Invalid:
			// preserve insert_comma info
		case .EOF:
			t.insert_comma = false
		case .Colon, .Comma, .Open_Brace, .Open_Bracket:
			t.insert_comma = false
		case .Null, .False, .True, .Infinity, .NaN,
		     .Ident, .Integer, .Float, .String,
		     .Close_Brace, .Close_Bracket:
			t.insert_comma = true
		}
	}

	return
}



@(require_results)
is_valid_number :: proc(str: string, spec: Specification) -> bool {
	s := str
	if s == "" {
		return false
	}

	if s[0] == '-' {
		s = s[1:]
		if s == "" {
			return false
		}
	} else if spec != .JSON {
		if s[0] == '+' { // Allow positive sign
			s = s[1:]
			if s == "" {
				return false
			}
		}
	}

	if spec != .JSON && len(s) >= 2 {
		// Allow for hexadecimal strings
		if s[:2] == "0x" || s[:2] == "0X" {
			s = s[2:]
			if len(s) == 0 {
				return false
			}
			hexadecimal_loop: for len(s) > 0 {
				switch s[0] {
				case '0'..='9', 'A'..='Z', 'a'..='z':
					s = s[1:]
				case:
					break hexadecimal_loop
				}
			}
			return len(s) == 0
		}
	}

	switch s[0] {
	case '0':
		s = s[1:]
	case '1'..='9':
		s = s[1:]
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' {
			s = s[1:]
		}
	case '.':
		if spec != .JSON { // Allow leading decimal point
			s = s[1:]
		} else {
			return false
		}
	case:
		return false
	}

	if spec != .JSON {
		if len(s) == 1 && s[0] == '.' { // Allow trailing decimal point
			return true
		}
	}

	if len(s) >= 2 && s[0] == '.' && '0' <= s[1] && s[1] <= '9' {
		s = s[2:]
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' {
			s = s[1:]
		}
	}

	if len(s) >= 2 && (s[0] == 'e' || s[0] == 'E') {
		s = s[1:]
		switch s[0] {
		case '+', '-':
			s = s[1:]
			if s == "" {
				return false
			}
		}
		for len(s) > 0 && '0' <= s[0] && s[0] <= '9' {
			s = s[1:]
		}
	}

	// The string should be empty now to be valid
	return s == ""
}

@(require_results)
is_valid_string_literal :: proc(str: string, spec: Specification) -> bool {
	s := str
	if len(s) < 2 {
		return false
	}
	quote := s[0]
	if s[0] != s[len(s)-1] {
		return false
	}
	switch quote {
	case '"':
		// okay
	case '\'':
		if spec == .JSON {
			return false
		}
		// okay
	case:
		return false
	}
	s = s[1 : len(s)-1]

	i := 0
	for i < len(s) {
		c := s[i]
		switch {
		case c == '\\':
			i += 1
			if i >= len(s) {
				return false
			}
			switch s[i] {
			case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
				i += 1
			case '\r':
				if spec != .JSON && i+1 < len(s) && s[i+1] == '\n' {
					i += 2
				} else {
					return false
				}
			case '\n':
				if spec != .JSON {
					i += 1
				} else {
					return false
				}
			case 'u':
				if i >= len(s) {
					return false
				}
				hex := s[i+1:]
				if len(hex) < 4 {
					return false
				}
				hex = hex[:4]
				i += 5

				for j := 0; j < 4; j += 1 {
					c2 := hex[j]
					switch c2 {
					case '0'..='9', 'a'..='z', 'A'..='Z':
						// Okay
					case:
						return false
					}
				}

			case: return false
			}

		case c == quote, c < ' ':
			return false

		case c < utf8.RUNE_SELF:
			i += 1

		case:
			r, width := utf8.decode_rune_in_string(s[i:])
			if r == utf8.RUNE_ERROR && width == 1 {
				return false
			}
			i += width
		}
	}
	if i == len(s) {
		return true
	}
	return true
}
