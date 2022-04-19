package json

import "core:mem"
import "core:unicode/utf8"
import "core:strconv"

Parser :: struct {
	tok:            Tokenizer,
	prev_token:     Token,
	curr_token:     Token,
	spec:           Specification,
	allocator:      mem.Allocator,
	parse_integers: bool,
}

make_parser :: proc(data: []byte, spec := DEFAULT_SPECIFICATION, parse_integers := false, allocator := context.allocator) -> Parser {
	return make_parser_from_string(string(data), spec, parse_integers, allocator)
}
make_parser_from_string :: proc(data: string, spec := DEFAULT_SPECIFICATION, parse_integers := false, allocator := context.allocator) -> Parser {
	p: Parser
	p.tok = make_tokenizer(data, spec, parse_integers)
	p.spec = spec
	p.allocator = allocator
	assert(p.allocator.procedure != nil)
	advance_token(&p)
	return p
}


parse :: proc(data: []byte, spec := DEFAULT_SPECIFICATION, parse_integers := false, allocator := context.allocator) -> (Value, Error) {
	return parse_string(string(data), spec, parse_integers, allocator)
}

parse_string :: proc(data: string, spec := DEFAULT_SPECIFICATION, parse_integers := false, allocator := context.allocator) -> (Value, Error) {
	context.allocator = allocator
	p := make_parser_from_string(data, spec, parse_integers, allocator)

	switch p.spec {
	case .JSON:
		return parse_object(&p)
	case .JSON5:
		return parse_value(&p)
	case .MJSON:
		#partial switch p.curr_token.kind {
		case .Ident, .String:
			return parse_object_body(&p, .EOF)
		}
		return parse_value(&p)
	}
	return parse_object(&p)
}

token_end_pos :: proc(tok: Token) -> Pos {
	end := tok.pos
	end.offset += len(tok.text)
	return end
}

advance_token :: proc(p: ^Parser) -> (Token, Error) {
	err: Error
	p.prev_token = p.curr_token
	p.curr_token, err = get_token(&p.tok)
	return p.prev_token, err
}


allow_token :: proc(p: ^Parser, kind: Token_Kind) -> bool {
	if p.curr_token.kind == kind {
		advance_token(p)
		return true
	}
	return false
}

expect_token :: proc(p: ^Parser, kind: Token_Kind) -> Error {
	prev := p.curr_token
	advance_token(p)
	if prev.kind == kind {
		return nil
	}
	return .Unexpected_Token
}


parse_colon :: proc(p: ^Parser) -> (err: Error) {
	colon_err := expect_token(p, .Colon) 
	if colon_err == nil {
		return nil
	}
	return .Expected_Colon_After_Key
}

parse_comma :: proc(p: ^Parser) -> (do_break: bool) {
	switch p.spec {
	case .JSON5, .MJSON:
		if allow_token(p, .Comma) {
			return false
		}
		return false
	case .JSON:
		if !allow_token(p, .Comma) {
			return true
		}
	}
	return false
}

parse_value :: proc(p: ^Parser) -> (value: Value, err: Error) {
	err = .None
	token := p.curr_token
	#partial switch token.kind {
	case .Null:
		advance_token(p)
		value = Null{}
		return
	case .False:
		advance_token(p)
		value = Boolean(false)
		return
	case .True:
		advance_token(p)
		value = Boolean(true)
		return

	case .Integer:
		advance_token(p)
		i, _ := strconv.parse_i64(token.text)
		value = Integer(i)
		return
	case .Float:
		advance_token(p)
		f, _ := strconv.parse_f64(token.text)
		value = Float(f)
		return
		
	case .Ident:
		if p.spec == .MJSON {
			advance_token(p)
			return string(token.text), nil
		}
		
	case .String:
		advance_token(p)
		return unquote_string(token, p.spec, p.allocator)

	case .Open_Brace:
		return parse_object(p)

	case .Open_Bracket:
		return parse_array(p)

	case:
		if p.spec != .JSON {
			switch {
			case allow_token(p, .Infinity):
				inf: u64 = 0x7ff0000000000000
				if token.text[0] == '-' {
					inf = 0xfff0000000000000
				}
				value = transmute(f64)inf
				return
			case allow_token(p, .NaN):
				nan: u64 = 0x7ff7ffffffffffff
				if token.text[0] == '-' {
					nan = 0xfff7ffffffffffff
				}
				value = transmute(f64)nan
				return
			}
		}
	}

	err = .Unexpected_Token
	advance_token(p)
	return
}

parse_array :: proc(p: ^Parser) -> (value: Value, err: Error) {
	err = .None
	expect_token(p, .Open_Bracket) or_return

	array: Array
	array.allocator = p.allocator
	defer if err != nil {
		for elem in array {
			destroy_value(elem)
		}
		delete(array)
	}

	for p.curr_token.kind != .Close_Bracket {
		elem := parse_value(p) or_return
		append(&array, elem)
		
		if parse_comma(p) {
			break
		}
	}

	expect_token(p, .Close_Bracket) or_return
	value = array
	return
}

@(private)
bytes_make :: proc(size, alignment: int, allocator: mem.Allocator) -> (bytes: []byte, err: Error) {
	b, berr := mem.alloc_bytes(size, alignment, allocator)
	if berr != nil {
		if berr == .Out_Of_Memory {
			err = .Out_Of_Memory
		} else {
			err = .Invalid_Allocator
		}
	}
	bytes = b
	return
}

clone_string :: proc(s: string, allocator: mem.Allocator) -> (str: string, err: Error) {
	n := len(s)
	b := bytes_make(n+1, 1, allocator) or_return
	copy(b, s)
	if len(b) > n {
		b[n] = 0
		str = string(b[:n])
	}
	return
}

parse_object_key :: proc(p: ^Parser, key_allocator: mem.Allocator) -> (key: string, err: Error) {
	tok := p.curr_token
	if p.spec != .JSON {
		if allow_token(p, .Ident) {
			return clone_string(tok.text, key_allocator)
		}
	}
	if tok_err := expect_token(p, .String); tok_err != nil {
		err = .Expected_String_For_Object_Key
		return
	}
	return unquote_string(tok, p.spec, key_allocator)
}

parse_object_body :: proc(p: ^Parser, end_token: Token_Kind) -> (obj: Object, err: Error) {
	obj.allocator = p.allocator
	defer if err != nil {
		for key, elem in obj {
			delete(key, p.allocator)
			destroy_value(elem)
		}
		delete(obj)
	}

	for p.curr_token.kind != end_token {
		key := parse_object_key(p, p.allocator) or_return
		parse_colon(p) or_return
		elem := parse_value(p) or_return

		if key in obj {
			err = .Duplicate_Object_Key
			delete(key, p.allocator)
			return
		}

		obj[key] = elem
		
		if parse_comma(p) {
			break
		}
	}	
	return obj, .None
}

parse_object :: proc(p: ^Parser) -> (value: Value, err: Error) {
	expect_token(p, .Open_Brace) or_return
	obj := parse_object_body(p, .Close_Brace) or_return
	expect_token(p, .Close_Brace) or_return
	return obj, .None
}


// IMPORTANT NOTE(bill): unquote_string assumes a mostly valid string
unquote_string :: proc(token: Token, spec: Specification, allocator := context.allocator) -> (value: string, err: Error) {
	get_u2_rune :: proc(s: string) -> rune {
		if len(s) < 4 || s[0] != '\\' || s[1] != 'x' {
			return -1
		}

		r: rune
		for c in s[2:4] {
			x: rune
			switch c {
			case '0'..='9': x = c - '0'
			case 'a'..='f': x = c - 'a' + 10
			case 'A'..='F': x = c - 'A' + 10
			case: return -1
			}
			r = r*16 + x
		}
		return r
	}
	get_u4_rune :: proc(s: string) -> rune {
		if len(s) < 6 || s[0] != '\\' || s[1] != 'u' {
			return -1
		}

		r: rune
		for c in s[2:6] {
			x: rune
			switch c {
			case '0'..='9': x = c - '0'
			case 'a'..='f': x = c - 'a' + 10
			case 'A'..='F': x = c - 'A' + 10
			case: return -1
			}
			r = r*16 + x
		}
		return r
	}

	if token.kind != .String {
		return "", nil
	}
	s := token.text
	if len(s) <= 2 {
		return "", nil
	}
	quote := s[0]
	if s[0] != s[len(s)-1] {
		// Invalid string
		return "", nil
	}
	s = s[1:len(s)-1]

	i := 0
	for i < len(s) {
		c := s[i]
		if c == '\\' || c == quote || c < ' ' {
			break
		}
		if c < utf8.RUNE_SELF {
			i += 1
			continue
		}
		r, w := utf8.decode_rune_in_string(s)
		if r == utf8.RUNE_ERROR && w == 1 {
			break
		}
		i += w
	}
	if i == len(s) {
		return clone_string(s, allocator)
	}

	b := bytes_make(len(s) + 2*utf8.UTF_MAX, 1, allocator) or_return
	w := copy(b, s[0:i])

	if len(b) == 0 && allocator.data == nil {
		// `unmarshal_count_array` calls us with a nil allocator
		return string(b[:w]), nil
	}

	loop: for i < len(s) {
		c := s[i]
		switch {
		case c == '\\':
			i += 1
			if i >= len(s) {
				break loop
			}
			switch s[i] {
			case: break loop
			case '"',  '\'', '\\', '/':
				b[w] = s[i]
				i += 1
				w += 1

			case 'b':
				b[w] = '\b'
				i += 1
				w += 1
			case 'f':
				b[w] = '\f'
				i += 1
				w += 1
			case 'r':
				b[w] = '\r'
				i += 1
				w += 1
			case 't':
				b[w] = '\t'
				i += 1
				w += 1
			case 'n':
				b[w] = '\n'
				i += 1
				w += 1
			case 'u':
				i -= 1 // Include the \u in the check for sanity sake
				r := get_u4_rune(s[i:])
				if r < 0 {
					break loop
				}
				i += 6

				buf, buf_width := utf8.encode_rune(r)
				copy(b[w:], buf[:buf_width])
				w += buf_width


			case '0':
				if spec != .JSON {
					b[w] = '\x00'
					i += 1
					w += 1
				} else {
					break loop
				}
			case 'v':
				if spec != .JSON {
					b[w] = '\v'
					i += 1
					w += 1
				} else {
					break loop
				}

			case 'x':
				if spec != .JSON {
					i -= 1 // Include the \x in the check for sanity sake
					r := get_u2_rune(s[i:])
					if r < 0 {
						break loop
					}
					i += 4

					buf, buf_width := utf8.encode_rune(r)
					copy(b[w:], buf[:buf_width])
					w += buf_width
				} else {
					break loop
				}
			}

		case c == quote, c < ' ':
			break loop

		case c < utf8.RUNE_SELF:
			b[w] = c
			i += 1
			w += 1

		case:
			r, width := utf8.decode_rune_in_string(s[i:])
			i += width

			buf, buf_width := utf8.encode_rune(r)
			assert(buf_width <= width)
			copy(b[w:], buf[:buf_width])
			w += buf_width
		}
	}

	return string(b[:w]), nil
}
