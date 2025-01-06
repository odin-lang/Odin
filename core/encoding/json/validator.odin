package encoding_json

import "core:mem"

// NOTE(bill): is_valid will not check for duplicate keys
is_valid :: proc(data: []byte, spec := DEFAULT_SPECIFICATION, parse_integers := false) -> bool {
	p := make_parser(data, spec, parse_integers, mem.nil_allocator())
	
	switch p.spec {
	case .JSON:
		return validate_object(&p)
	case .JSON5:
		return validate_value(&p)
	case .MJSON:
		#partial switch p.curr_token.kind {
		case .Ident, .String:
			return validate_object_body(&p, .EOF)
		}
		return validate_value(&p)
	}
	return validate_object(&p)
}

validate_object_key :: proc(p: ^Parser) -> bool {
	if p.spec != .JSON {
		if allow_token(p, .Ident) {
			return true
		}
	}
	err := expect_token(p, .String)
	return err == .None
}

validate_object_body :: proc(p: ^Parser, end_token: Token_Kind) -> bool {
	for p.curr_token.kind != end_token {
		if !validate_object_key(p) {
			return false
		}
		if parse_colon(p) != nil {
			return false
		}
		validate_value(p) or_return

		if parse_comma(p) {
			break
		}
	}
	return true
}

validate_object :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, .Open_Brace); err != .None {
		return false
	}
	
	validate_object_body(p, .Close_Brace) or_return

	if err := expect_token(p, .Close_Brace); err != .None {
		return false
	}
	return true
}

validate_array :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, .Open_Bracket); err != .None {
		return false
	}

	for p.curr_token.kind != .Close_Bracket {
		if !validate_value(p) {
			return false
		}

		if parse_comma(p) {
			break
		}
	}

	if err := expect_token(p, .Close_Bracket); err != .None {
		return false
	}

	return true
}

validate_value :: proc(p: ^Parser) -> bool {
	token := p.curr_token

	#partial switch token.kind {
	case .Null, .False, .True:
		advance_token(p)
		return true
	case .Integer, .Float:
		advance_token(p)
		return true
	case .String:
		advance_token(p)
		return is_valid_string_literal(token.text, p.spec)

	case .Open_Brace:
		return validate_object(p)

	case .Open_Bracket:
		return validate_array(p)
		
	case .Ident:
		if p.spec == .MJSON {
			advance_token(p)
			return true
		}
		return false

	case:
		if p.spec != .JSON {
			#partial switch token.kind {
			case .Infinity, .NaN:
				advance_token(p)
				return true
			}
		}
	}

	return false
}
