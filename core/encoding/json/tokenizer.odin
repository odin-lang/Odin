package encoding_json

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

// Where the string token at `s[start]` ends, as `scan_string` finds it: after its closing quote, or
// at a newline or the end of `s` that leaves it unterminated. No other byte matters, as no escape or
// UTF-8 sequence can hide a quote or a newline.
@(private="file")
string_token_end :: proc "contextless" (s: string, start: int) -> (end: int, closed: bool) #no_bounds_check {
	quote := s[start]
	i := start + 1
	for i < len(s) {
		i = string_stop(s, i, quote)
		if i >= len(s) || s[i] == '\n' {
			return i, false
		}
		if s[i] == quote {
			return i + 1, true
		}
		i += 2
	}
	return len(s), false
}

@(require_results)
get_token :: proc(t: ^Tokenizer) -> (token: Token, err: Error) #no_bounds_check {
	data  := t.data
	start := t.offset
	end   := 0

	scan: for start < len(data) {
		c := data[start]
		switch c {
		case ' ', '\t', '\v', '\f', '\r':
			start += 1
			continue
		case '\n':
			if t.insert_comma {
				break scan
			}
			t.line += 1
			t.curr_line_offset = start
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
				if e, closed := string_token_end(data, start); closed {
					end = e
					break
				}
			} else if e := plain_run_end(data, start+1, '"'); e < len(data) && data[e] == '"' {
				end = e + 1
				break
			}
			end, err = scan_string(t, start)
		case '\'':
			if t.spec == .JSON {
				break scan
			}
			token.kind = .String
			if t.validated {
				if e, closed := string_token_end(data, start); closed {
					end, err = e, .Illegal_Character
					break
				}
			}
			end, err = scan_string(t, start)
			if err == nil {
				err = .Illegal_Character
			}

		case 'A'..='Z', 'a'..='z', '_':
			end = alphanum_end(data, start+1)
			token.kind = ident_kind(data[start:end], t.spec)

		case '-', '+':
			if start+1 >= len(data) || data[start+1] - '0' > 9 {
				break scan
			}
			if c == '+' && t.spec == .JSON {
				break scan
			}
			end, token.kind, err = scan_decimal(t, start)
			if c == '+' && err == nil {
				err = .Illegal_Character
			}

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

		token.pos  = {start, t.line, start - t.curr_line_offset}
		token.text = data[start:end]
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
get_other_token :: #force_no_inline proc(t: ^Tokenizer) -> (token: Token, err: Error) {
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

	skip_alphanum :: proc(t: ^Tokenizer) {
		if i := alphanum_end(t.data, t.offset); i != t.offset {
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
		skip_alphanum(t)
		token.kind = ident_kind(t.data[token.offset:t.offset], t.spec)

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

		end, kind, number_err := scan_decimal(t, token.offset)
		token.kind = kind
		if number_err != nil {
			err = number_err
		}
		move_to(t, end)

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
		end, string_err := scan_string(t, token.offset)
		if string_err != nil {
			err = string_err
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
alphanum_end :: proc "contextless" (s: string, i: int) -> int #no_bounds_check {
	i := i
	for i < len(s) {
		switch s[i] {
		case 'A'..='Z', 'a'..='z', '0'..='9', '_':
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
	         (!has_dot || frac_digits > 0 || (t.spec != .JSON && !has_exp)) &&
	         (!has_exp || exp_digits > 0)
	if !valid {
		err = .Invalid_Number
	}
	return
}

// Scans the string literal whose opening quote is at `t.data[start]`.
@(private="file")
scan_string :: proc(t: ^Tokenizer, start: int) -> (end: int, err: Error) #no_bounds_check {
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
		case c < ' ':
			invalid = true
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
	return i, err
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
			i = plain_run_end(s, i, quote)

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

@(private)
count_validated_array :: proc(s: string, open: int, spec: Specification) -> (count: uintptr) #no_bounds_check {
	rune_width :: #force_inline proc "contextless" (s: string, i: int) -> int {
		if s[i] < utf8.RUNE_SELF {
			return 1
		}
		_, w := utf8.decode_rune_in_string(s[i:])
		return w
	}
	number_end :: proc "contextless" (s: string, start: int) -> int #no_bounds_check {
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
			i, _ = string_token_end(s, i)

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

		case 'A'..='Z', 'a'..='z', '_':
			count += uintptr(depth == 0)
			i = alphanum_end(s, i+1)

		case '-', '+':
			count += uintptr(depth == 0)
			if i+1 < len(s) && (s[i+1] == 'I' || s[i+1] == 'N') {
				i = alphanum_end(s, i+1)
			} else {
				i = number_end(s, i+1)
			}

		case '0'..='9':
			count += uintptr(depth == 0)
			is_hex := false
			if c == '0' && spec != .JSON && i+1 < len(s) {
				is_hex = s[i+1] == 'x' || s[i+1] == 'X'
			}
			if is_hex {
				for i += 2; i < len(s); /**/ {
					i += rune_width(s, i)
					if i >= len(s) {
						break
					}
					switch s[i] {
					case '0'..='9', 'a'..='f', 'A'..='F':
						continue
					}
					break
				}
			} else {
				i = number_end(s, i+1)
			}

		case '/':
			if i+1 < len(s) && s[i+1] == '*' {
				for i += 1; i < len(s); /**/ {
					i += rune_width(s, i)
					if i < len(s) && s[i] == '*' {
						i += 1
						if i < len(s) && s[i] == '/' {
							i += 1
							break
						}
					}
				}
			} else {
				for i < len(s) && s[i] != '\n' {
					i += 1
				}
			}

		case:
			i += 1
		}
	}
	return
}
