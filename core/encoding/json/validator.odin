package encoding_json

import "core:mem"

// NOTE(bill): is_valid will not check for duplicate keys
@(require_results)
is_valid :: proc(data: []byte, spec := DEFAULT_SPECIFICATION, parse_integers := false) -> bool {
	p := make_parser(data, spec, parse_integers, mem.nil_allocator())
	return validate_document(&p)
}

@(private, require_results)
validate_document :: proc(p: ^Parser) -> bool {
	valid: bool
	if p.spec == .MJSON && (p.curr_token.kind == .Ident || p.curr_token.kind == .String || p.curr_token.kind == .EOF) {
		valid = validate_object_body(p, .EOF)
	} else {
		valid = validate_value(p)
	}
	return valid && at_end(p)
}

@(require_results)
validate_object_key :: proc(p: ^Parser) -> bool {
	if p.spec != .JSON {
		if allow_name_token(p) {
			return true
		}
	}
	valid := p.curr_token_err != .Invalid_String
	err := expect_token(p, .String)
	return err == .None && valid
}

@(require_results)
validate_object_body :: proc(p: ^Parser, end_token: Token_Kind) -> bool {
	p.depth += 1
	if p.depth > MAX_DEPTH {
		return false
	}
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
	p.depth -= 1
	return true
}

@(require_results)
validate_object :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, .Open_Brace); err != .None {
		return false
	}

	validate_object_body(p, .Close_Brace) or_return

	if err := expect_closing_token(p, .Close_Brace); err != .None {
		return false
	}
	return true
}

@(require_results)
validate_array :: proc(p: ^Parser) -> bool {
	if err := expect_token(p, .Open_Bracket); err != .None {
		return false
	}
	p.depth += 1
	if p.depth > MAX_DEPTH {
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

	if err := expect_closing_token(p, .Close_Bracket); err != .None {
		return false
	}

	p.depth -= 1
	return true
}

@(require_results)
validate_value :: proc(p: ^Parser) -> bool {
	token := p.curr_token
	if token_error(p) != nil {
		return false
	}

	#partial switch token.kind {
	case .Null, .False, .True, .Integer, .Float, .String:
		advance_token(p)
		return true

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
