package json

import "core:mem"
import "core:unicode/utf8"
import "core:strconv"

Parser :: struct {
	tok:        Tokenizer,
	prev_token: Token,
	curr_token: Token,
	spec:       Specification,
	allocator:  mem.Allocator,
}

make_parser :: proc(data: []byte, spec := Specification.JSON, allocator := context.allocator) -> Parser {
	p: Parser;
	p.tok = make_tokenizer(data, spec);
	p.spec = spec;
	p.allocator = allocator;
	assert(p.allocator.procedure != nil);
	advance_token(&p);
	return p;
}

parse :: proc(data: []byte, spec := Specification.JSON, allocator := context.allocator) -> (Value, Error) {
	context.allocator = allocator;
	p := make_parser(data, spec, allocator);

	if p.spec == Specification.JSON5 {
		return parse_value(&p);
	}
	return parse_object(&p);
}

token_end_pos :: proc(tok: Token) -> Pos {
	end := tok.pos;
	end.offset += len(tok.text);
	return end;
}

advance_token :: proc(p: ^Parser) -> (Token, Error) {
	err: Error;
	p.prev_token = p.curr_token;
	p.curr_token, err = get_token(&p.tok);
	return p.prev_token, err;
}


allow_token :: proc(p: ^Parser, kind: Kind) -> bool {
	if p.curr_token.kind == kind {
		advance_token(p);
		return true;
	}
	return false;
}

expect_token :: proc(p: ^Parser, kind: Kind) -> Error {
	prev := p.curr_token;
	advance_token(p);
	if prev.kind == kind {
		return Error.None;
	}
	return Error.Unexpected_Token;
}



parse_value :: proc(p: ^Parser) -> (value: Value, err: Error) {
	value.pos = p.curr_token.pos;
	defer value.end = token_end_pos(p.prev_token);

	token := p.curr_token;
	switch token.kind {
	case Kind.Null:
		value.value = Null{};
		advance_token(p);
		return;
	case Kind.False:
		value.value = Boolean(false);
		advance_token(p);
		return;
	case Kind.True:
		value.value = Boolean(true);
		advance_token(p);
		return;

	case Kind.Integer:
		value.value = Integer(strconv.parse_i64(token.text));
		advance_token(p);
		return;
	case Kind.Float:
		value.value = Float(strconv.parse_f64(token.text));
		advance_token(p);
		return;
	case Kind.String:
		value.value = String(unquote_string(token, p.spec, p.allocator));
		advance_token(p);
		return;

	case Kind.Open_Brace:
		return parse_object(p);

	case Kind.Open_Bracket:
		return parse_array(p);

	case:
		if p.spec == Specification.JSON5 {
			switch token.kind {
			case Kind.Infinity:
				inf: u64 = 0x7ff0000000000000;
				if token.text[0] == '-' {
					inf = 0xfff0000000000000;
				}
				value.value = transmute(f64)inf;
				advance_token(p);
				return;
			case Kind.NaN:
				nan: u64 = 0x7ff7ffffffffffff;
				if token.text[0] == '-' {
					nan = 0xfff7ffffffffffff;
				}
				value.value = transmute(f64)nan;
				advance_token(p);
				return;
			}
		}
	}

	err = Error.Unexpected_Token;
	advance_token(p);
	return;
}

parse_array :: proc(p: ^Parser) -> (value: Value, err: Error) {
	value.pos = p.curr_token.pos;
	defer value.end = token_end_pos(p.prev_token);
	if err = expect_token(p, Kind.Open_Bracket); err != Error.None {
		return;
	}

	array: Array;
	array.allocator = p.allocator;
	defer if err != Error.None {
		for elem in array {
			destroy_value(elem);
		}
		delete(array);
	}

	for p.curr_token.kind != Kind.Close_Bracket {
		elem, elem_err := parse_value(p);
		if elem_err != Error.None {
			err = elem_err;
			return;
		}
		append(&array, elem);

		// Disallow trailing commas for the time being
		if allow_token(p, Kind.Comma) {
			continue;
		} else {
			break;
		}
	}

	if err = expect_token(p, Kind.Close_Bracket); err != Error.None {
		return;
	}

	value.value = array;
	return;
}

clone_string :: proc(s: string, allocator: mem.Allocator) -> string {
	n := len(s);
	b := make([]byte, n+1, allocator);
	copy(b, s);
	b[n] = 0;
	return string(b[:n]);
}

parse_object_key :: proc(p: ^Parser) -> (key: string, err: Error) {
	tok := p.curr_token;
	if p.spec == Specification.JSON5 {
		if tok.kind == Kind.String {
			expect_token(p, Kind.String);
			key = unquote_string(tok, p.spec, p.allocator);
			return;
		} else if tok.kind == Kind.Ident {
			expect_token(p, Kind.Ident);
			key = clone_string(tok.text, p.allocator);
			return;
		}
	}
	if tok_err := expect_token(p, Kind.String); tok_err != Error.None {
		err = Error.Expected_String_For_Object_Key;
		return;
	}
	key = unquote_string(tok, p.spec, p.allocator);
	return;
}

parse_object :: proc(p: ^Parser) -> (value: Value, err: Error) {
	value.pos = p.curr_token.pos;
	defer value.end = token_end_pos(p.prev_token);

	if err = expect_token(p, Kind.Open_Brace); err != Error.None {
		value.pos = p.curr_token.pos;
		return;
	}

	obj: Object;
	obj.allocator = p.allocator;
	defer if err != Error.None {
		for key, elem in obj {
			delete(key, p.allocator);
			destroy_value(elem);
		}
		delete(obj);
	}

	for p.curr_token.kind != Kind.Close_Brace {
		key: string;
		key, err = parse_object_key(p);
		if err != Error.None {
			delete(key, p.allocator);
			value.pos = p.curr_token.pos;
			return;
		}

		if colon_err := expect_token(p, Kind.Colon); colon_err != Error.None {
			err = Error.Expected_Colon_After_Key;
			value.pos = p.curr_token.pos;
			return;
		}

		elem, elem_err := parse_value(p);
		if elem_err != Error.None {
			err = elem_err;
			value.pos = p.curr_token.pos;
			return;
		}

		if key in obj {
			err = Error.Duplicate_Object_Key;
			value.pos = p.curr_token.pos;
			delete(key, p.allocator);
			return;
		}

		obj[key] = elem;

		if p.spec == Specification.JSON5 {
			// Allow trailing commas
			if allow_token(p, Kind.Comma) {
				continue;
			}
		} else {
			// Disallow trailing commas
			if allow_token(p, Kind.Comma) {
				continue;
			} else {
				break;
			}
		}
	}

	if err = expect_token(p, Kind.Close_Brace); err != Error.None {
		value.pos = p.curr_token.pos;
		return;
	}

	value.value = obj;
	return;
}


// IMPORTANT NOTE(bill): unquote_string assumes a mostly valid string
unquote_string :: proc(token: Token, spec: Specification, allocator := context.allocator) -> string {
	get_u2_rune :: proc(s: string) -> rune {
		if len(s) < 4 || s[0] != '\\' || s[1] != 'x' {
			return -1;
		}

		r: rune;
		for c in s[2:4] {
			x: rune;
			switch c {
			case '0'..'9': x = c - '0';
			case 'a'..'f': x = c - 'a' + 10;
			case 'A'..'F': x = c - 'A' + 10;
			case: return -1;
			}
			r = r*16 + x;
		}
		return r;
	}
	get_u4_rune :: proc(s: string) -> rune {
		if len(s) < 6 || s[0] != '\\' || s[1] != 'u' {
			return -1;
		}

		r: rune;
		for c in s[2:6] {
			x: rune;
			switch c {
			case '0'..'9': x = c - '0';
			case 'a'..'f': x = c - 'a' + 10;
			case 'A'..'F': x = c - 'A' + 10;
			case: return -1;
			}
			r = r*16 + x;
		}
		return r;
	}

	if token.kind != Kind.String {
		return "";
	}
	s := token.text;
	if len(s) <= 2 {
		return "";
	}
	quote := s[0];
	if s[0] != s[len(s)-1] {
		// Invalid string
		return "";
	}
	s = s[1:len(s)-1];

	i := 0;
	for i < len(s) {
		c := s[i];
		if c == '\\' || c == quote || c < ' ' {
			break;
		}
		if c < utf8.RUNE_SELF {
			i += 1;
			continue;
		}
		r, w := utf8.decode_rune_in_string(s);
		if r == utf8.RUNE_ERROR && w == 1 {
			break;
		}
		i += w;
	}
	if i == len(s) {
		return clone_string(s, allocator);
	}

	b := make([]byte, len(s) + 2*utf8.UTF_MAX, allocator);
	w := copy(b, s[0:i]);
	loop: for i < len(s) {
		c := s[i];
		switch {
		case c == '\\':
			i += 1;
			if i >= len(s) {
				break loop;
			}
			switch s[i] {
			case: break loop;
			case '"',  '\'', '\\', '/':
				b[w] = s[i];
				i += 1;
				w += 1;

			case 'b':
				b[w] = '\b';
				i += 1;
				w += 1;
			case 'f':
				b[w] = '\f';
				i += 1;
				w += 1;
			case 'r':
				b[w] = '\r';
				i += 1;
				w += 1;
			case 't':
				b[w] = '\t';
				i += 1;
				w += 1;
			case 'n':
				b[w] = '\n';
				i += 1;
				w += 1;
			case 'u':
				i -= 1; // Include the \u in the check for sanity sake
				r := get_u4_rune(s[i:]);
				if r < 0 {
					break loop;
				}
				i += 6;

				buf, buf_width := utf8.encode_rune(r);
				copy(b[w:], buf[:buf_width]);
				w += buf_width;


			case '0':
				if spec == Specification.JSON5 {
					b[w] = '\x00';
					i += 1;
					w += 1;
				} else {
					break loop;
				}
			case 'v':
				if spec == Specification.JSON5 {
					b[w] = '\v';
					i += 1;
					w += 1;
				} else {
					break loop;
				}

			case 'x':
				if spec == Specification.JSON5 {
					i -= 1; // Include the \x in the check for sanity sake
					r := get_u2_rune(s[i:]);
					if r < 0 {
						break loop;
					}
					i += 4;

					buf, buf_width := utf8.encode_rune(r);
					copy(b[w:], buf[:buf_width]);
					w += buf_width;
				} else {
					break loop;
				}
			}

		case c == quote, c < ' ':
			break loop;

		case c < utf8.RUNE_SELF:
			b[w] = c;
			i += 1;
			w += 1;

		case:
			r, width := utf8.decode_rune_in_string(s[i:]);
			i += width;

			buf, buf_width := utf8.encode_rune(r);
			assert(buf_width <= width);
			copy(b[w:], buf[:buf_width]);
			w += buf_width;
		}
	}

	return string(b[:w]);
}
