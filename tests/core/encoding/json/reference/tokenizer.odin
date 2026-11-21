package encoding_json_reference

import "base:intrinsics"
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
	validated:        bool,
}



@(require_results)
make_tokenizer :: proc(data: string, spec := DEFAULT_SPECIFICATION, parse_integers := false) -> Tokenizer {
	t := Tokenizer{pos = {line=1, column=1}, data = data, spec = spec, parse_integers = parse_integers}
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
	t.pos.column = offset - t.curr_line_offset + 1

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
	ONES  :: 0x0101_0101_0101_0101
	HIGHS :: 0x8080_8080_8080_8080

	i := i
	for i+8 <= len(s) {
		x := u64(intrinsics.unaligned_load((^u64le)(raw_data(s[i:]))))
		y := x &~ HIGHS

		non_digits := (~(y + ONES*(0x80-'0')) | (y + ONES*(0x80-'9'-1)) | x) & HIGHS
		if non_digits != 0 {
			return i + int(intrinsics.count_trailing_zeros(non_digits) >> 3)
		}
		i += 8
	}

	for i < len(s) && '0' <= s[i] && s[i] <= '9' {
		i += 1
	}
	return i
}

@(private)
plain_run_end :: proc "contextless" (s: string, i: int, quote: byte) -> int #no_bounds_check {
	ONES  :: 0x0101_0101_0101_0101
	HIGHS :: 0x8080_8080_8080_8080

	i := i
	for i+8 <= len(s) {
		x := intrinsics.unaligned_load((^u64)(raw_data(s[i:])))
		q := x ~ ONES*u64(quote)
		b := x ~ ONES*'\\'

		if ((x - ONES*' ') & ~x | (q - ONES) & ~q | (b - ONES) & ~b | x) & HIGHS != 0 {
			break
		}
		i += 8
	}

	for i < len(s) {
		c := s[i]
		if c < ' ' || c >= utf8.RUNE_SELF ||
		   c == quote || c == '\\' {
			break
		}
		i += 1
	}
	return i
}

@(private)
string_stop :: proc "contextless" (s: string, i: int, quote: byte) -> int #no_bounds_check {
	ONES  :: 0x0101_0101_0101_0101
	HIGHS :: 0x8080_8080_8080_8080

	i := i
	for i+8 <= len(s) {
		x := u64(intrinsics.unaligned_load((^u64le)(raw_data(s[i:]))))
		q := x ~ ONES*u64(quote)
		b := x ~ ONES*'\\'
		n := x ~ ONES*'\n'

		found := ((q - ONES) & ~q | (b - ONES) & ~b | (n - ONES) & ~n) & HIGHS
		if found != 0 {
			return i + int(intrinsics.count_trailing_zeros(found) >> 3)
		}
		i += 8
	}

	for i < len(s) && s[i] != quote && s[i] != '\\' && s[i] != '\n' {
		i += 1
	}
	return i
}

// Where the string token at `s[start]` ends, as `scan_string` finds it: after its closing quote,
// or at a newline or the end of `s` that leaves it unterminated. `lines` counts the escaped LFs
// inside it and `line_start` is the offset after the last one. No other byte matters:
// an escape hides at most the quote, backslash or line break after it,
// and no UTF-8 sequence holds a quote or a newline.
@(private="file")
string_token_end :: proc "contextless" (s: string, start: int) -> (end: int, closed: bool, lines: int, line_start: int) #no_bounds_check {
	quote := s[start]
	i := start + 1
	for i < len(s) {
		i = string_stop(s, i, quote)
		if i >= len(s) || s[i] == '\n' {
			return i, false, lines, line_start
		}
		if s[i] == quote {
			return i + 1, true, lines, line_start
		}
		if i+2 < len(s) && s[i+1] == '\r' && s[i+2] == '\n' {
			i += 1
		}
		i += 2
		if i <= len(s) && s[i-1] == '\n' {
			lines += 1
			line_start = i
		}
	}
	return len(s), false, lines, line_start
}

@(private="file")
count_lines :: proc "contextless" (t: ^Tokenizer, start, end: int) #no_bounds_check {
	for i in start..<end {
		if t.data[i] == '\n' {
			t.line += 1
			t.curr_line_offset = i + 1
		}
	}
	t.pos.column = t.offset - t.curr_line_offset + 1
}

@(private="file")
unicode_space_width :: proc "contextless" (s: string, i: int) -> int #no_bounds_check {
	switch s[i] {
	case 0xc2:
		if i+1 < len(s) && s[i+1] == 0xa0 {
			return 2
		}
	case 0xe1:
		if i+2 < len(s) && s[i+1] == 0x9a && s[i+2] == 0x80 {
			return 3
		}
	case 0xe2:
		if i+2 < len(s) {
			switch s[i+1] {
			case 0x80:
				switch s[i+2] {
				case 0x80..=0x8a, 0xa8, 0xa9, 0xaf:
					return 3
				}
			case 0x81:
				if s[i+2] == 0x9f {
					return 3
				}
			}
		}
	case 0xe3:
		if i+2 < len(s) && s[i+1] == 0x80 && s[i+2] == 0x80 {
			return 3
		}
	case 0xef:
		if i+2 < len(s) && s[i+1] == 0xbb && s[i+2] == 0xbf {
			return 3
		}
	}
	return 0
}

@(private="file")
line_comment_end :: proc "contextless" (s: string, i: int) -> int #no_bounds_check {
	i := i
	for i < len(s) {
		switch s[i] {
		case '\n', '\r':
			return i
		case 0xe2:
			if i+2 < len(s) && s[i+1] == 0x80 && (s[i+2] == 0xa8 || s[i+2] == 0xa9) {
				return i
			}
		}
		i += 1
	}
	return i
}

@(require_results)
get_token :: proc(t: ^Tokenizer) -> (token: Token, err: Error) #no_bounds_check {
	for {
		comment: bool
		token, err, comment = get_token_or_comment(t)
		if !comment {
			return
		}
	}
}

@(private="file", require_results)
get_token_or_comment :: #force_inline proc(t: ^Tokenizer) -> (token: Token, err: Error, comment: bool) #no_bounds_check {
	data  := t.data
	start := t.offset
	end   := 0
	lines, line_start := 0, 0

	scan: for start < len(data) {
		c := data[start]
		switch c {
		case ' ', '\t', '\r':
			start += 1
			continue
		case '\v', '\f':
			if t.spec == .JSON {
				break scan
			}
			start += 1
			continue
		case '\n':
			if t.insert_comma {
				break scan
			}
			t.line += 1
			t.curr_line_offset = start + 1
			start += 1
			continue

		case ',':
			token.kind = .Comma
			t.insert_comma = false
			end = start + 1
		case ':': token.kind, end = .Colon,         start + 1
		case '{': token.kind, end = .Open_Brace,    start + 1
		case '}': token.kind, end = .Close_Brace,   start + 1
		case '[': token.kind, end = .Open_Bracket,  start + 1
		case ']': token.kind, end = .Close_Bracket, start + 1

		case '"':
			token.kind = .String
			if t.validated {
				if e, closed, l, ls := string_token_end(data, start); closed {
					end, lines, line_start = e, l, ls
					break
				}
			} else if e := plain_run_end(data, start+1, '"'); e < len(data) && data[e] == '"' {
				end = e + 1
				break
			}
			end, err, lines, line_start = scan_string(t, start)
		case '\'':
			if t.spec == .JSON {
				break scan
			}
			token.kind = .String
			if t.validated {
				if e, closed, l, ls := string_token_end(data, start); closed {
					end, lines, line_start = e, l, ls
					break
				}
			}
			end, err, lines, line_start = scan_string(t, start)

		case '$':
			if t.spec == .JSON {
				break scan
			}
			fallthrough
		case 'A'..='Z', 'a'..='z', '_':
			end = alphanum_end(data, start+1, t.spec)
			token.kind = ident_kind(data[start:end], t.spec)

		case '-', '+':
			if start+1 >= len(data) || data[start+1] - '0' > 9 {
				break scan
			}
			if c == '+' && t.spec == .JSON {
				break scan
			}
			if t.spec != .JSON && data[start+1] == '0' && start+2 < len(data) && (data[start+2] == 'x' || data[start+2] == 'X') {
				break scan
			}
			end, token.kind, err = scan_decimal(t, start)

		case '0'..='9':
			if c == '0' && t.spec != .JSON && start+1 < len(data) {
				if x := data[start+1]; x == 'x' || x == 'X' {
					break scan
				}
			}
			end, token.kind, err = scan_decimal(t, start)

		case:
			break scan
		}

		token.pos  = {start, t.line, start - t.curr_line_offset + 1}
		token.text = data[start:end]
		if lines > 0 {
			t.line += lines
			t.curr_line_offset = line_start
		}
		move_to(t, end)
		if t.spec == .MJSON {
			update_insert_comma(t, token.kind)
		}
		return
	}

	if start != t.offset {
		move_to(t, start)
	}
	return get_other_token(t)
}

@(private="file", require_results)
get_other_token :: #force_no_inline proc(t: ^Tokenizer) -> (token: Token, err: Error, comment: bool) {
	skip_digits :: proc(t: ^Tokenizer) {
		if i := digits_end(t.data, t.offset); i != t.offset {
			move_to(t, i)
		}
	}
	skip_hex_digits :: proc(t: ^Tokenizer) -> (digits: int) {
		for {
			switch t.r {
			case '0'..='9', 'a'..='f', 'A'..='F':
				// Okay
				next_rune(t)
				digits += 1
			case:
				return
			}
		}
	}
	scan_leading_dot :: proc(t: ^Tokenizer, token: ^Token) -> Error {
		skip_digits(t)
		if t.r == 'e' || t.r == 'E' {
			switch r := next_rune(t); r {
			case '+', '-':
				next_rune(t)
			}
			skip_digits(t)
		}
		token.kind = .Float
		if !is_valid_number(string(t.data[token.offset:t.offset]), t.spec) {
			return .Invalid_Number
		}
		return nil
	}

	skip_whitespace :: proc(t: ^Tokenizer, on_newline: bool) #no_bounds_check {
		i := t.offset
		loop: for i < len(t.data) {
			switch t.data[i] {
			case ' ', '\t', '\r':
				i += 1
			case '\v', '\f':
				if t.spec == .JSON {
					break loop
				}
				i += 1
			case '\n':
				if on_newline {
					break loop
				}
				t.line += 1
				t.curr_line_offset = i + 1
				i += 1
			case 0xc2, 0xe1, 0xe2, 0xe3, 0xef:
				if t.spec != .JSON {
					if w := unicode_space_width(t.data, i); w > 0 {
						i += w
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

	skip_alphanum :: proc(t: ^Tokenizer) {
		if i := alphanum_end(t.data, t.offset, t.spec); i != t.offset {
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
		count_lines(t, token.offset, t.offset)
		token.text = ","
		token.kind = .Comma
		return

	case '$':
		if t.spec == .JSON {
			err = .Illegal_Character
			break
		}
		fallthrough
	case 'A'..='Z', 'a'..='z', '_':
		skip_alphanum(t)
		token.kind = ident_kind(t.data[token.offset:t.offset], t.spec)

	case '+':
		if t.spec == .JSON {
			err = .Illegal_Character
			break
		}
		fallthrough

	case '-':
		switch t.r {
		case '0'..='9':
			// Okay
		case '.':
			if t.spec != .JSON {
				next_rune(t)
				err = scan_leading_dot(t, &token)
				break block
			}
			err = .Illegal_Character
			break block
		case:
			// Illegal use of +/-
			err = .Illegal_Character

			if t.spec != .JSON {
				if t.r == 'I' || t.r == 'N' {
					skip_alphanum(t)
				}
				switch string(t.data[token.offset+1:t.offset]) {
				case "Infinity": token.kind, err = .Infinity, nil
				case "NaN":      token.kind, err = .NaN, nil
				}
			}
			break block
		}
		fallthrough

	case '0'..='9':
		token.kind = t.parse_integers ? .Integer : .Float
		if t.spec != .JSON { // Hexadecimal Numbers
			hex := token.offset
			if curr_rune == '-' || curr_rune == '+' {
				hex += 1
			}
			if hex+1 < len(t.data) && t.data[hex] == '0' && (t.data[hex+1] == 'x' || t.data[hex+1] == 'X') {
				move_to(t, hex+2)
				if skip_hex_digits(t) == 0 {
					err = .Invalid_Number
				}
				break
			}
		}

		end, kind, number_err := scan_decimal(t, token.offset)
		token.kind = kind
		if number_err != nil {
			err = number_err
		}
		move_to(t, end)

	case '.':
		err = .Illegal_Character
		if t.spec != .JSON { // Allow leading decimal point
			err = scan_leading_dot(t, &token)
		}


	case '\'':
		err = .Illegal_Character
		if t.spec == .JSON {
			break
		}
		fallthrough
	case '"':
		token.kind = .String
		end, string_err, lines, line_start := scan_string(t, token.offset)
		if string_err != nil {
			err = string_err
		}
		if lines > 0 {
			t.line += lines
			t.curr_line_offset = line_start
		}
		move_to(t, end)

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
				move_to(t, line_comment_end(t.data, t.offset))
				comment = true
				return
			case '*':
				// None-nested multi-line comments
				for t.offset < len(t.data) {
					r := next_rune(t)
					for r == '*' {
						r = next_rune(t)
						if r == '/' {
							next_rune(t)
							count_lines(t, token.offset, t.offset)
							comment = true
							return
						}
					}
				}
				count_lines(t, token.offset, t.offset)
				err = .EOF
			}
		}

	case: err = .Illegal_Character
	}

	token.text = string(t.data[token.offset : t.offset])

	if t.spec == .MJSON {
		update_insert_comma(t, token.kind)
	}

	return
}

@(private="file")
update_insert_comma :: proc "contextless" (t: ^Tokenizer, kind: Token_Kind) {
	switch kind {
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

@(private="file")
alphanum_end :: proc "contextless" (s: string, i: int, spec: Specification) -> int #no_bounds_check {
	i := i
	for i < len(s) {
		switch s[i] {
		case 'A'..='Z', 'a'..='z', '0'..='9', '_':
			i += 1
		case '$':
			if spec == .JSON {
				return i
			}
			i += 1
		case:
			return i
		}
	}
	return i
}

@(private="file")
ident_kind :: proc(str: string, spec: Specification) -> Token_Kind {
	switch str {
	case "null":  return .Null
	case "false": return .False
	case "true":  return .True
	}
	if spec != .JSON {
		switch str {
		case "Infinity": return .Infinity
		case "NaN":      return .NaN
		}
	}
	return .Ident
}

// Scans the decimal number at `t.data[start]`, a digit or a sign followed by a digit.
@(private="file")
scan_decimal :: #force_inline proc "contextless" (t: ^Tokenizer, start: int) -> (end: int, kind: Token_Kind, err: Error) #no_bounds_check {
	data := t.data
	kind = t.parse_integers ? .Integer : .Float

	i := start + 1
	first_digit, int_digits := data[start], 1
	if first_digit == '-' || first_digit == '+' {
		first_digit, int_digits = data[i], 0
	}

	end = digits_end(data, i)
	int_digits += end - i

	has_dot, frac_digits := false, 0
	has_exp, exp_digits  := false, 0
	if end < len(data) && data[end] == '.' {
		kind = .Float
		e := digits_end(data, end+1)
		has_dot, frac_digits, end = true, e - (end+1), e
	}

	if end < len(data) && (data[end] == 'e' || data[end] == 'E') {
		kind = .Float
		end += 1
		if end < len(data) && (data[end] == '+' || data[end] == '-') {
			end += 1
		}
		e := digits_end(data, end)
		has_exp, exp_digits, end = true, e - end, e
	}

	valid := (first_digit != '0' || int_digits == 1) &&
	         (!has_dot || frac_digits > 0 || t.spec != .JSON) &&
	         (!has_exp || exp_digits > 0)
	if !valid {
		err = .Invalid_Number
	}
	return
}

// Scans the string literal whose opening quote is at `t.data[start]`.
@(private="file")
scan_string :: proc(t: ^Tokenizer, start: int) -> (end: int, err: Error, lines: int, line_start: int) #no_bounds_check {
	data  := t.data
	quote := data[start]

	closed, escaped, invalid := false, false, false

	i := start + 1
	loop: for {
		i = plain_run_end(data, i, quote)
		if i >= len(data) {
			break
		}
		c := data[i]
		switch {
		case c == '\n':
			err = .String_Not_Terminated
			break loop
		case c == quote:
			i += 1
			closed = true
			break loop
		case c == '\\':
			escaped = true
			move_to(t, i+1)
			_ = scan_escape(t)
			i = t.offset
			if data[i-1] == '\n' {
				lines += 1
				line_start = i
			}
		case c < ' ':
			if t.spec == .JSON || c == '\r' {
				invalid = true
			}
			i += 1
		case escaped:
			i += 1
		case:
			r, w := utf8.decode_rune_in_string(data[i:])
			if r == utf8.RUNE_ERROR && w == 1 {
				invalid = true
			}
			i += w
		}
	}

	if (!closed || escaped) && !t.validated {
		if !is_valid_string_literal(data[start:i], t.spec) {
			err = .Invalid_String
		}
	} else if invalid {
		err = .Invalid_String
	}
	return i, err, lines, line_start
}

@(private="file", require_results)
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
	case '\r':
		if next_rune(t) == '\n' {
			next_rune(t)
		}
	case:
		// Ignore the next rune regardless
		next_rune(t)
	}
	return false
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
				case '0'..='9', 'A'..='F', 'a'..='f':
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
			if len(s) < 2 || s[1] < '0' || s[1] > '9' {
				return false
			}
		} else {
			return false
		}
	case:
		return false
	}

	if spec != .JSON {
		if len(s) >= 1 && s[0] == '.' && (len(s) == 1 || s[1] == 'e' || s[1] == 'E') { // Allow trailing decimal point
			s = s[1:]
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
	valid, valid_utf8 := check_string_literal(str, spec)
	return valid && valid_utf8
}

@(private, require_results)
check_string_literal :: proc(str: string, spec: Specification) -> (valid, valid_utf8: bool) {
	valid_utf8 = true
	s := str
	if len(s) < 2 {
		return
	}
	quote := s[0]
	if s[0] != s[len(s)-1] {
		return
	}
	switch quote {
	case '"':
		// okay
	case '\'':
		if spec == .JSON {
			return
		}
		// okay
	case:
		return
	}
	s = s[1 : len(s)-1]

	i := 0
	for i < len(s) {
		c := s[i]
		switch {
		case c == '\\':
			i += 1
			if i >= len(s) {
				return
			}
			switch s[i] {
			case '"', '\\', '/', 'b', 'n', 'r', 't', 'f':
				i += 1
			case '\'':
				if spec == .JSON {
					return
				}
				i += 1
			case '\r':
				if spec == .JSON {
					return
				}
				i += 1
				if i < len(s) && s[i] == '\n' {
					i += 1
				}
			case '\n':
				if spec != .JSON {
					i += 1
				} else {
					return
				}
			case 'v':
				if spec == .JSON {
					return
				}
				i += 1
			case '0':
				if spec == .JSON || i+1 < len(s) && '0' <= s[i+1] && s[i+1] <= '9' {
					return
				}
				i += 1
			case 'x':
				if spec == .JSON || i+2 >= len(s) {
					return
				}
				_ = hex_digit_value(s[i+1]) or_return
				_ = hex_digit_value(s[i+2]) or_return
				i += 3
			case '1'..='9':
				return
			case 'u':
				if i >= len(s) {
					return
				}
				hex := s[i+1:]
				if len(hex) < 4 {
					return
				}
				hex = hex[:4]
				i += 5

				for j := 0; j < 4; j += 1 {
					c2 := hex[j]
					switch c2 {
					case '0'..='9', 'a'..='f', 'A'..='F':
						// Okay
					case:
						return
					}
				}

			case:
				if spec == .JSON {
					return
				}
			}

		case c == quote:
			return

		case c < ' ':
			if spec == .JSON || c == '\n' || c == '\r' {
				return
			}
			i += 1

		case c < utf8.RUNE_SELF:
			i = plain_run_end(s, i, quote)

		case:
			r, width := utf8.decode_rune_in_string(s[i:])
			if r == utf8.RUNE_ERROR && width == 1 {
				valid_utf8 = false
			}
			i += width
		}
	}
	if i == len(s) {
		return true, valid_utf8
	}
	return true, valid_utf8
}

@(private)
count_validated_array :: proc(s: string, open: int, spec: Specification) -> (count: uintptr) #no_bounds_check {
	number_end :: proc "contextless" (s: string, start: int, spec: Specification) -> int #no_bounds_check {
		if spec != .JSON && start+1 < len(s) && s[start] == '0' && (s[start+1] == 'x' || s[start+1] == 'X') {
			i := start + 2
			for i < len(s) {
				switch s[i] {
				case '0'..='9', 'a'..='f', 'A'..='F':
					i += 1
					continue
				}
				break
			}
			return i
		}
		i := digits_end(s, start)
		if i < len(s) && s[i] == '.' {
			i = digits_end(s, i+1)
		}
		if i < len(s) && (s[i] == 'e' || s[i] == 'E') {
			i += 1
			if i < len(s) && (s[i] == '+' || s[i] == '-') {
				i += 1
			}
			i = digits_end(s, i)
		}
		return i
	}

	depth := 0
	i := open + 1
	for i < len(s) {
		c := s[i]
		switch c {
		case '"', '\'':
			count += uintptr(depth == 0)
			i, _, _, _ = string_token_end(s, i)

		case '[', '{':
			count += uintptr(depth == 0)
			depth += 1
			i += 1

		case ']', '}':
			if depth == 0 {
				return
			}
			depth -= 1
			i += 1

		case 'A'..='Z', 'a'..='z', '_', '$':
			count += uintptr(depth == 0)
			i = alphanum_end(s, i+1, spec)

		case '-', '+':
			count += uintptr(depth == 0)
			if i+1 < len(s) && (s[i+1] == 'I' || s[i+1] == 'N') {
				i = alphanum_end(s, i+1, spec)
			} else {
				i = number_end(s, i+1, spec)
			}

		case '0'..='9':
			count += uintptr(depth == 0)
			i = number_end(s, i, spec)

		case '/':
			if i+1 < len(s) && s[i+1] == '*' {
				for i += 2; i < len(s); i += 1 {
					if s[i] == '*' && i+1 < len(s) && s[i+1] == '/' {
						i += 2
						break
					}
				}
			} else {
				i = line_comment_end(s, i)
			}

		case:
			i += 1
		}
	}
	return
}
