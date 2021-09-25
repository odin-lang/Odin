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
	p: Parser
	p.tok = make_tokenizer(data, spec, parse_integers)
	p.spec = spec
	p.allocator = allocator
	assert(p.allocator.procedure != nil)
	advance_token(&p)
	return p
}

parse :: proc(data: []byte, spec := DEFAULT_SPECIFICATION, parse_integers := false, allocator := context.allocator) -> (Value, Error) {
	context.allocator = allocator
	p := make_parser(data, spec, parse_integers, allocator)

	if p.spec == Specification.JSON5 {
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
		return .None
	}
	return .Unexpected_Token
}



parse_value :: proc(p: ^Parser) -> (value: Value, err: Error) {
	token := p.curr_token
	#partial switch token.kind {
	case .Null:
		value = Null{}
		advance_token(p)
		return
	case .False:
		value = Boolean(false)
		advance_token(p)
		return
	case .True:
		value = Boolean(true)
		advance_token(p)
		return

	case .Integer:
		i, _ := strconv.parse_i64(token.text)
		value = Integer(i)
		advance_token(p)
		return
	case .Float:
		f, _ := strconv.parse_f64(token.text)
		value = Float(f)
		advance_token(p)
		return
	case .String:
		value = unquote_string(token, p.spec, p.allocator) or_return
		advance_token(p)
		return

	case .Open_Brace:
		return parse_object(p)

	case .Open_Bracket:
		return parse_array(p)

	case:
		if p.spec == Specification.JSON5 {
			#partial switch token.kind {
			case .Infinity:
				inf: u64 = 0x7ff0000000000000
				if token.text[0] == '-' {
					inf = 0xfff0000000000000
				}
				value = transmute(f64)inf
				advance_token(p)
				return
			case .NaN:
				nan: u64 = 0x7ff7ffffffffffff
				if token.text[0] == '-' {
					nan = 0xfff7ffffffffffff
				}
				value = transmute(f64)nan
				advance_token(p)
				return
			}
		}
	}

	err = .Unexpected_Token
	advance_token(p)
	return
}

parse_array :: proc(p: ^Parser) -> (value: Value, err: Error) {
	expect_token(p, .Open_Bracket) or_return

	array: Array
	array.allocator = p.allocator
	defer if err != .None {
		for elem in array {
			destroy_value(elem)
		}
		delete(array)
	}

	for p.curr_token.kind != .Close_Bracket {
		elem := parse_value(p) or_return
		append(&array, elem)

		// Disallow trailing commas for the time being
		if allow_token(p, .Comma) {
			continue
		} else {
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
	if p.spec == Specification.JSON5 {
		if tok.kind == .String {
			expect_token(p, .String)
			key = unquote_string(tok, p.spec, key_allocator) or_return
			return
		} else if tok.kind == .Ident {
			expect_token(p, .Ident)
			key = clone_string(tok.text, key_allocator) or_return
			return
		}
	}
	if tok_err := expect_token(p, .String); tok_err != .None {
		err = .Expected_String_For_Object_Key
		return
	}
	key = unquote_string(tok, p.spec, key_allocator) or_return
	return
}

parse_object :: proc(p: ^Parser) -> (value: Value, err: Error) {
	expect_token(p, .Open_Brace) or_return

	obj: Object
	obj.allocator = p.allocator
	defer if err != .None {
		for key, elem in obj {
			delete(key, p.allocator)
			destroy_value(elem)
		}
		delete(obj)
	}

	for p.curr_token.kind != .Close_Brace {
		key: string
		key, err = parse_object_key(p, p.allocator)
		if err != .None {
			delete(key, p.allocator)
			return
		}

		if colon_err := expect_token(p, .Colon); colon_err != .None {
			err = .Expected_Colon_After_Key
			return
		}

		elem := parse_value(p) or_return

		if key in obj {
			err = .Duplicate_Object_Key
			delete(key, p.allocator)
			return
		}

		obj[key] = elem

		if p.spec == Specification.JSON5 {
			// Allow trailing commas
			if allow_token(p, .Comma) {
				continue
			}
		} else {
			// Disallow trailing commas
			if allow_token(p, .Comma) {
				continue
			} else {
				break
			}
		}
	}

	expect_token(p, .Close_Brace) or_return
	value = obj
	return
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
				if spec == Specification.JSON5 {
					b[w] = '\x00'
					i += 1
					w += 1
				} else {
					break loop
				}
			case 'v':
				if spec == Specification.JSON5 {
					b[w] = '\v'
					i += 1
					w += 1
				} else {
					break loop
				}

			case 'x':
				if spec == Specification.JSON5 {
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
