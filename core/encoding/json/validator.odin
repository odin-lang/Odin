package json

import "core:mem"

// NOTE(bill): is_valid will not check for duplicate keys
is_valid :: proc(data: string) -> bool {
	p := make_parser(data, mem.nil_allocator());
	return validate_object(&p);
}

validate_object :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, Kind.Open_Brace); err != Error.None {
		return false;
	}

	for p.curr_token.kind != Kind.Close_Brace {
		tok := p.curr_token;
		if tok_err := expect_token(p, Kind.String); tok_err != Error.None {
			return false;
		}
		if colon_err := expect_token(p, Kind.Colon); colon_err != Error.None {
			return false;
		}

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
	switch token.kind {
	case Kind.Null:
		advance_token(p);
		return true;
	case Kind.False:
		advance_token(p);
		return true;
	case Kind.True:
		advance_token(p);
		return true;
	case Kind.Integer:
		advance_token(p);
		return true;
	case Kind.Float:
		advance_token(p);
		return true;
	case Kind.String:
		advance_token(p);
		return is_valid_string_literal(token.text);

	case Kind.Open_Brace:
		return validate_object(p);

	case Kind.Open_Bracket:
		return validate_array(p);
	}

	return false;
}
