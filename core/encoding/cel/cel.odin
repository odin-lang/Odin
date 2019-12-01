package cel;

import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"

Array :: []Value;
Dict  :: map[string]Value;
Nil_Value :: struct{};

Value :: union {
	Nil_Value,
	bool, i64, f64, string,
	Array, Dict,
}

Parser :: struct {
	tokens:           [dynamic]Token,
	prev_token:       Token,
	curr_token:       Token,
	curr_token_index: int,

	allocated_strings: [dynamic]string,

	error_count: int,

	root: Dict,
	dict_stack: [dynamic]^Dict, // NOTE: Pointers may be stored on the stack
}


print_value :: proc(value: Value, pretty := true, indent := 0) {
	print_indent :: proc(indent: int) {
		for _ in 0..<indent do fmt.print("\t");
	}

	switch v in value {
	case bool: fmt.print(v);
	case i64: fmt.print(v);
	case f64: fmt.print(v);
	case string: fmt.print(v);
	case Array:
		fmt.print("[");
		if pretty do fmt.println();
		for e, i in v {
			if pretty {
				print_indent(indent+1);
				print_value(e, pretty, indent+1);
				fmt.println(",");
			} else {
				if i > 0 do fmt.print(", ");
				print_value(e);
			}
		}
		if pretty do print_indent(indent);
		fmt.print("]");
	case Dict:
		fmt.print("{");
		if pretty do fmt.println();

		i := 0;
		for name, val in v {
			if pretty {
				print_indent(indent+1);
				fmt.printf("%s = ", name);
				print_value(val, pretty, indent+1);
				fmt.println(",");
			} else {
				if i > 0 do fmt.print(", ");
				fmt.printf("%s = ", name);
				print_value(val, pretty, indent+1);
				i += 1;
			}
		}

		if pretty do print_indent(indent);
		fmt.print("}");
	case:
		fmt.print("nil");
	case Nil_Value:
		fmt.print("nil");
	}
}
print :: proc(p: ^Parser, pretty := false) {
	for name, val in p.root {
		fmt.printf("%s = ", name);
		print_value(val, pretty);
		fmt.println(";");
	}
}

create_from_string :: proc(src: string) -> (^Parser, bool) {
	return init(transmute([]byte)src);
}


init :: proc(src: []byte) -> (^Parser, bool) {
	t: Tokenizer;
	tokenizer_init(&t, src);
	return create_from_tokenizer(&t);
}


create_from_tokenizer :: proc(t: ^Tokenizer) -> (^Parser, bool) {
	p := new(Parser);
	for {
		tok := scan(t);
		if tok.kind == Kind.Illegal {
			return p, false;
		}
		append(&p.tokens, tok);
		if tok.kind == Kind.EOF {
			break;
		}
	}

	if t.error_count > 0 {
		return p, false;
	}

	if len(p.tokens) == 0 {
		tok := Token{kind = Kind.EOF};
		tok.line, tok.column = 1, 1;
		append(&p.tokens, tok);
		return p, true;
	}

	p.curr_token_index = 0;
	p.prev_token = p.tokens[p.curr_token_index];
	p.curr_token = p.tokens[p.curr_token_index];

	p.root = Dict{};
	p.dict_stack = make([dynamic]^Dict, 0, 4);
	append(&p.dict_stack, &p.root);

	for p.curr_token.kind != Kind.EOF &&
	    p.curr_token.kind != Kind.Illegal &&
	    p.curr_token_index < len(p.tokens) {
		if !parse_assignment(p) {
			break;
		}
	}

	return p, true;
}

destroy :: proc(p: ^Parser) {
	destroy_value :: proc(value: Value) {
		switch v in value {
		case Array:
			for elem in v do destroy_value(elem);
			delete(v);

		case Dict:
			for _, dv in v do destroy_value(dv);
			delete(v);
		}
	}

	delete(p.tokens);
	for s in p.allocated_strings do delete(s);
	delete(p.allocated_strings);
	delete(p.dict_stack);

	destroy_value(p.root);
	free(p);
}

error :: proc(p: ^Parser, pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) Error: ", pos.file, pos.line, pos.column);
	fmt.eprintf(msg, ..args);
	fmt.eprintln();

	p.error_count += 1;
}

next_token :: proc(p: ^Parser) -> Token {
	p.prev_token = p.curr_token;
	prev := p.prev_token;

	if p.curr_token_index+1 < len(p.tokens) {
		p.curr_token_index += 1;
		p.curr_token = p.tokens[p.curr_token_index];
		return prev;
	}
	p.curr_token_index = len(p.tokens);
	p.curr_token = p.tokens[p.curr_token_index-1];
	error(p, prev.pos, "Token is EOF");
	return prev;
}

unquote_char :: proc(str: string, quote: byte) -> (r: rune, multiple_bytes: bool, tail_string: string, success: bool) {
	hex_to_int :: proc(c: byte) -> int {
		switch c {
		case '0'..'9': return int(c-'0');
		case 'a'..'f': return int(c-'a')+10;
		case 'A'..'F': return int(c-'A')+10;
		}
		return -1;
	}
	w: int;

	if str[0] == quote && quote == '"' {
		return;
	} else if str[0] >= 0x80 {
		r, w = utf8.decode_rune_in_string(str);
		return r, true, str[w:], true;
	} else if str[0] != '\\' {
		return rune(str[0]), false, str[1:], true;
	}

	if len(str) <= 1 {
		return;
	}
	s := str;
	c := s[1];
	s = s[2:];

	switch c {
	case:
		return;

	case 'a':  r = '\a';
	case 'b':  r = '\b';
	case 'f':  r = '\f';
	case 'n':  r = '\n';
	case 'r':  r = '\r';
	case 't':  r = '\t';
	case 'v':  r = '\v';
	case '\\': r = '\\';

	case '"':  r = '"';
	case '\'': r = '\'';

	case '0'..'7':
		v := int(c-'0');
		if len(s) < 2 {
			return;
		}
		for i in 0..<len(s) {
			d := int(s[i]-'0');
			if d < 0 || d > 7 {
				return;
			}
			v = (v<<3) | d;
		}
		s = s[2:];
		if v > 0xff {
			return;
		}
		r = rune(v);

	case 'x', 'u', 'U':
		count: int;
		switch c {
		case 'x': count = 2;
		case 'u': count = 4;
		case 'U': count = 8;
		}

		if len(s) < count {
			return;
		}

		for i in 0..<count {
			d := hex_to_int(s[i]);
			if d < 0 {
				return;
			}
			r = (r<<4) | rune(d);
		}
		s = s[count:];
		if c == 'x' {
			break;
		}
		if r > utf8.MAX_RUNE {
			return;
		}
		multiple_bytes = true;
	}

	success = true;
	tail_string = s;
	return;
}


unquote_string :: proc(p: ^Parser, t: Token) -> (string, bool) {
	if t.kind != Kind.String {
		return t.lit, true;
	}
	s := t.lit;
	quote := '"';

	if s == `""` {
        return "", true;
    }

	if strings.contains_rune(s, '\n') >= 0 {
		return s, false;
	}

	if strings.contains_rune(s, '\\') < 0 && strings.contains_rune(s, quote) < 0 {
		if quote == '"' {
			return s, true;
		}
	}


	buf_len := 3*len(s) / 2;
	buf := make([]byte, buf_len);
	offset := 0;
	for len(s) > 0 {
		r, multiple_bytes, tail_string, ok := unquote_char(s, byte(quote));
		if !ok {
			delete(buf);
			return s, false;
		}
		s = tail_string;
		if r < 0x80 || !multiple_bytes {
			buf[offset] = byte(r);
			offset += 1;
		} else {
			b, w := utf8.encode_rune(r);
			copy(buf[offset:], b[:w]);
			offset += w;
		}
	}

	new_string := string(buf[:offset]);

	append(&p.allocated_strings, new_string);

	return new_string, true;
}


allow_token :: proc(p: ^Parser, kind: Kind) -> bool {
	if p.curr_token.kind == kind {
		next_token(p);
		return true;
	}
	return false;
}

expect_token :: proc(p: ^Parser, kind: Kind) -> Token {
	prev := p.curr_token;
	if prev.kind != kind {
		got := prev.lit;
		if got == "\n" do got = ";";
		error(p, prev.pos, "Expected %s, got %s", kind_to_string[kind], got);
	}
	next_token(p);
	return prev;
}

expect_operator :: proc(p: ^Parser) -> Token {
	prev := p.curr_token;
	if !is_operator(prev.kind) {
		error(p, prev.pos, "Expected an operator, got %s", prev.lit);
	}


	next_token(p);
	return prev;
}

fix_advance :: proc(p: ^Parser) {
	for {
		switch t := p.curr_token; t.kind {
		case Kind.EOF, Kind.Semicolon:
			return;
		}
		next_token(p);
	}
}

copy_value :: proc(value: Value) -> Value {
	switch v in value {
	case Array:
		a := make(Array, len(v));
		for elem, idx in v {
			a[idx] = copy_value(elem);
		}
		return a;
	case Dict:
		d := make(Dict, cap(v));
		for key, val in v {
			d[key] = copy_value(val);
		}
		return d;
	}
	return value;
}

lookup_value :: proc(p: ^Parser, name: string) -> (Value, bool) {
	for i := len(p.dict_stack)-1; i >= 0; i -= 1 {
		d := p.dict_stack[i];
		if val, ok := d[name]; ok {
			return copy_value(val), true;
		}
	}

	return nil, false;
}

parse_operand :: proc(p: ^Parser) -> (Value, Pos) {
	tok := p.curr_token;
	switch p.curr_token.kind {
	case Kind.Ident:
		next_token(p);
		v, ok := lookup_value(p, tok.lit);
		if !ok do error(p, tok.pos, "Undeclared identifier %s", tok.lit);
		return v, tok.pos;

	case Kind.True:
		next_token(p);
		return true, tok.pos;
	case Kind.False:
		next_token(p);
		return false, tok.pos;

	case Kind.Nil:
		next_token(p);
		return Nil_Value{}, tok.pos;

	case Kind.Integer:
		next_token(p);
		return strconv.parse_i64(tok.lit), tok.pos;

	case Kind.Float:
		next_token(p);
		return strconv.parse_f64(tok.lit), tok.pos;

	case Kind.String:
		next_token(p);
		str, ok := unquote_string(p, tok);
		if !ok do error(p, tok.pos, "Unable to unquote string");
		return string(str), tok.pos;

	case Kind.Open_Paren:
		expect_token(p, Kind.Open_Paren);
		expr, _ := parse_expr(p);
		expect_token(p, Kind.Close_Paren);
		return expr, tok.pos;

	case Kind.Open_Bracket:
		expect_token(p, Kind.Open_Bracket);
		elems := make([dynamic]Value, 0, 4);
		for p.curr_token.kind != Kind.Close_Bracket &&
		    p.curr_token.kind != Kind.EOF {
			elem, _ := parse_expr(p);
			append(&elems, elem);

			if p.curr_token.kind == Kind.Semicolon && p.curr_token.lit == "\n" {
				next_token(p);
			} else if !allow_token(p, Kind.Comma) {
				break;
			}

		}
		expect_token(p, Kind.Close_Bracket);
		return Array(elems[:]), tok.pos;

	case Kind.Open_Brace:
		expect_token(p, Kind.Open_Brace);

    	dict := Dict{};
    	append(&p.dict_stack, &dict);
    	defer pop(&p.dict_stack);

		for p.curr_token.kind != Kind.Close_Brace &&
		    p.curr_token.kind != Kind.EOF {
		    name_tok := p.curr_token;
		    if !allow_token(p, Kind.Ident) && !allow_token(p, Kind.String) {
		    	name_tok = expect_token(p, Kind.Ident);
		    }

			name, ok := unquote_string(p, name_tok);
			if !ok do error(p, tok.pos, "Unable to unquote string");
		    expect_token(p, Kind.Assign);
			elem, _ := parse_expr(p);

			if _, ok2 := dict[name]; ok2 {
				error(p, name_tok.pos, "Previous declaration of %s in this scope", name);
			} else {
				dict[name] = elem;
			}

			if p.curr_token.kind == Kind.Semicolon && p.curr_token.lit == "\n" {
				next_token(p);
			} else if !allow_token(p, Kind.Comma) {
				break;
			}
		}
		expect_token(p, Kind.Close_Brace);
		return dict, tok.pos;

	}
	return nil, tok.pos;
}

parse_atom_expr :: proc(p: ^Parser, operand: Value, pos: Pos) -> (Value, Pos) {
	loop := true;
	for operand := operand; loop;  {
		switch p.curr_token.kind {
		case Kind.Period:
			next_token(p);
			tok := next_token(p);

			switch tok.kind {
			case Kind.Ident:
				d, ok := operand.(Dict);
				if !ok || d == nil {
					error(p, tok.pos, "Expected a dictionary");
					operand = nil;
					continue;
				}
				name, usok := unquote_string(p, tok);
				if !usok do error(p, tok.pos, "Unable to unquote string");
				val, found := d[name];
				if !found {
					error(p, tok.pos, "Field %s not found in dictionary", name);
					operand = nil;
					continue;
				}
				operand = val;
			case:
				error(p, tok.pos, "Expected a selector, got %s", tok.kind);
				operand = nil;
			}

		case Kind.Open_Bracket:
			expect_token(p, Kind.Open_Bracket);
			index, index_pos := parse_expr(p);
			expect_token(p, Kind.Close_Bracket);


			switch a in operand {
			case Array:
				i, ok := index.(i64);
				if !ok {
					error(p, index_pos, "Index must be an integer for an array");
					operand = nil;
					continue;
				}

				if 0 <= i && i < i64(len(a)) {
					operand = a[i];
				} else {
					error(p, index_pos, "Index %d out of bounds range 0..%d", i, len(a));
					operand = nil;
					continue;
				}

			case Dict:
				key, ok := index.(string);
				if !ok {
					error(p, index_pos, "Index must be a string for a dictionary");
					operand = nil;
					continue;
				}

				val, found := a[key];
				if found {
					operand = val;
				} else {
					error(p, index_pos, "`%s` was not found in the dictionary", key);
					operand = nil;
					continue;
				}



			case:
				error(p, index_pos, "Indexing is only allowed on an array or dictionary");
			}

		case:
			loop = false;
		}
	}

	return operand, pos;
}

parse_unary_expr :: proc(p: ^Parser) -> (Value, Pos) {
	op := p.curr_token;
	switch p.curr_token.kind {
	case Kind.At:
		next_token(p);
		tok := expect_token(p, Kind.String);
		v, ok := lookup_value(p, tok.lit);
		if !ok do error(p, tok.pos, "Undeclared identifier %s", tok.lit);
		return parse_atom_expr(p, v, tok.pos);

	case Kind.Add, Kind.Sub:
		next_token(p);
		// TODO(bill): Calcuate values as you go!
		expr, pos := parse_unary_expr(p);

		switch e in expr {
		case i64: if op.kind == Kind.Sub do return -e, pos;
		case f64: if op.kind == Kind.Sub do return -e, pos;
		case:
			error(p, op.pos, "Unary operator %s can only be used on integers or floats", op.lit);
			return nil, op.pos;
		}

		return expr, op.pos;

	case Kind.Not:
		next_token(p);
		expr, _ := parse_unary_expr(p);
		if v, ok := expr.(bool); ok {
			return !v, op.pos;
		}
		error(p, op.pos, "Unary operator %s can only be used on booleans", op.lit);
		return nil, op.pos;
	}

	return parse_atom_expr(p, parse_operand(p));
}


value_order :: proc(v: Value) -> int {
	switch _ in v {
	case bool, string:
		return 1;
	case i64:
		return 2;
	case f64:
		return 3;
	}
	return 0;
}

match_values :: proc(left, right: ^Value) -> bool {
	if value_order(right^) < value_order(left^) {
		return match_values(right, left);
	}

	switch x in left^ {
	case:
		right^ = left^;
	case bool, string:
		return true;
	case i64:
		switch y in right^ {
		case i64:
			return true;
		case f64:
			left^ = f64(x);
			return true;
		}

	case f64:
		switch y in right {
		case f64:
			return true;
		}
	}

	return false;
}

calculate_binary_value :: proc(p: ^Parser, op: Kind, a, b: Value) -> (Value, bool) {
	// TODO(bill): Calculate value as you go!
	x, y := a, b;
	match_values(&x, &y);


	switch a in x {
	case: return x, true;

	case bool:
		b, ok := y.(bool);
		if !ok do return nil, false;
		switch op {
		case Kind.Eq:    return a == b, true;
		case Kind.NotEq: return a != b, true;
		case Kind.And:   return a && b, true;
		case Kind.Or:    return a || b, true;
		}

	case i64:
		b, ok := y.(i64);
		if !ok do return nil, false;
		switch op {
		case Kind.Add:   return a + b, true;
		case Kind.Sub:   return a - b, true;
		case Kind.Mul:   return a * b, true;
		case Kind.Quo:   return a / b, true;
		case Kind.Rem:   return a % b, true;
		case Kind.Eq:    return a == b, true;
		case Kind.NotEq: return a != b, true;
		case Kind.Lt:    return a <  b, true;
		case Kind.Gt:    return a >  b, true;
		case Kind.LtEq:  return a <= b, true;
		case Kind.GtEq:  return a >= b, true;
		}

	case f64:
		b, ok := y.(f64);
		if !ok do return nil, false;

		switch op {
		case Kind.Add:   return a + b, true;
		case Kind.Sub:   return a - b, true;
		case Kind.Mul:   return a * b, true;
		case Kind.Quo:   return a / b, true;
		case Kind.Eq:    return a == b, true;
		case Kind.NotEq: return a != b, true;
		case Kind.Lt:    return a <  b, true;
		case Kind.Gt:    return a >  b, true;
		case Kind.LtEq:  return a <= b, true;
		case Kind.GtEq:  return a >= b, true;
		}

	case string:
		b, ok := y.(string);
		if !ok do return nil, false;

		switch op {
		case Kind.Add:
			n := len(a) + len(b);
			data := make([]byte, n);
			copy(data[:], a);
			copy(data[len(a):], b);
			s := string(data);
			append(&p.allocated_strings, s);
			return s, true;

		case Kind.Eq:    return a == b, true;
		case Kind.NotEq: return a != b, true;
		case Kind.Lt:    return a <  b, true;
		case Kind.Gt:    return a >  b, true;
		case Kind.LtEq:  return a <= b, true;
		case Kind.GtEq:  return a >= b, true;
		}
	}

	return nil, false;
}

parse_binary_expr :: proc(p: ^Parser, prec_in: int) -> (Value, Pos) {
	expr, pos := parse_unary_expr(p);
	for prec := precedence(p.curr_token.kind); prec >= prec_in; prec -= 1 {
		for {
			op := p.curr_token;
			op_prec := precedence(op.kind);
			if op_prec != prec {
				break;
			}
			expect_operator(p);

			if op.kind == Kind.Question {
				cond := expr;
				x, _ := parse_expr(p);
				expect_token(p, Kind.Colon);
				y, _ := parse_expr(p);

				if t, ok := cond.(bool); ok {
					expr = t ? x : y;
				} else {
					error(p, pos, "Condition must be a boolean");
				}

			} else {
				right, right_pos := parse_binary_expr(p, prec+1);
				if right == nil {
					error(p, right_pos, "Expected expression on the right-hand side of the binary operator %s", op.lit);
				}
				left := expr;
				ok: bool;
				expr, ok = calculate_binary_value(p, op.kind, left, right);
				if !ok {
					error(p, pos, "Invalid binary operation");
				}
			}
		}
	}
	return expr, pos;
}

parse_expr :: proc(p: ^Parser) -> (Value, Pos) {
	return parse_binary_expr(p, 1);
}

expect_semicolon :: proc(p: ^Parser) {
	kind := p.curr_token.kind;

	switch kind {
	case Kind.Comma:
		error(p, p.curr_token.pos, "Expected ';', got ','");
		next_token(p);
	case Kind.Semicolon:
		next_token(p);
	case Kind.EOF:
		// okay
	case:
		error(p, p.curr_token.pos, "Expected ';', got %s", p.curr_token.lit);
		fix_advance(p);
	}
}

parse_assignment :: proc(p: ^Parser) -> bool {
	top_dict :: proc(p: ^Parser) -> ^Dict {
		assert(len(p.dict_stack) > 0);
		return p.dict_stack[len(p.dict_stack)-1];
	}

	if p.curr_token.kind == Kind.Semicolon {
		next_token(p);
		return true;
	}
	if p.curr_token.kind == Kind.EOF {
		return false;
	}

	tok := p.curr_token;
	if allow_token(p, Kind.Ident) || allow_token(p, Kind.String) {
		expect_token(p, Kind.Assign);
		name, ok := unquote_string(p, tok);
		if !ok do error(p, tok.pos, "Unable to unquote string");
		expr, _ := parse_expr(p);
		d := top_dict(p);
		if _, ok2 := d[name]; ok2 {
			error(p, tok.pos, "Previous declaration of %s", name);
		} else {
			d[name] = expr;
		}
		expect_semicolon(p);
		return true;
	}
	error(p, tok.pos, "Expected an assignment, got %s", kind_to_string[tok.kind]);
	fix_advance(p);
	return false;
}
