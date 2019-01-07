package json

import "core:mem"

// NOTE(bill): is_valid will not check for duplicate keys
is_valid :: proc(data: []byte, spec := Specification.JSON) -> bool {
	p := make_parser(data, spec, mem.nil_allocator());
	if p.spec == Specification.JSON5 {
		return validate_value(&p);
	}
	return validate_object(&p);
}

validate_object_key :: proc(p: ^Parser) -> bool {
	tok := p.curr_token;
	if p.spec == Specification.JSON5 {
		if tok.kind == Kind.String {
			expect_token(p, Kind.String);
			return true;
		} else if tok.kind == Kind.Ident {
			expect_token(p, Kind.Ident);
			return true;
		}
	}
	err := expect_token(p, Kind.String);
	return err == Error.None;
}
validate_object :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, Kind.Open_Brace); err != Error.None {
		return false;
	}

	for p.curr_token.kind != Kind.Close_Brace {
		if !validate_object_key(p) {
			return false;
		}
		if colon_err := expect_token(p, Kind.Colon); colon_err != Error.None {
			return false;
		}

		if !validate_value(p) {
			return false;
		}

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

	if err := expect_token(p, Kind.Close_Brace); err != Error.None {
		return false;
	}
	return true;
}

validate_array :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, Kind.Open_Bracket); err != Error.None {
		return false;
	}

	for p.curr_token.kind != Kind.Close_Bracket {
		if !validate_value(p) {
			return false;
		}

		// Disallow trailing commas for the time being
		if allow_token(p, Kind.Comma) {
			continue;
		} else {
			break;
		}
	}

	if err := expect_token(p, Kind.Close_Bracket); err != Error.None {
		return false;
	}

	return true;
}

validate_value :: proc(p: ^Parser) -> bool {
	token := p.curr_token;

	using Kind;
	switch token.kind {
	case Null, False, True:
		advance_token(p);
		return true;
	case Integer, Float:
		advance_token(p);
		return true;
	case String:
		advance_token(p);
		return is_valid_string_literal(token.text, p.spec);

	case Open_Brace:
		return validate_object(p);

	case Open_Bracket:
		return validate_array(p);

	case:
		if p.spec == Specification.JSON5 {
			switch token.kind {
			case Infinity, NaN:
				advance_token(p);
				return true;
			}
		}
	}

	return false;
}
