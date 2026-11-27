package encoding_toml

import "base:runtime"
import "core:math"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

@(private)
Parser :: struct {
	src:       string,
	pos:       int,
	line:      int,
	depth:     int,
	allocator: runtime.Allocator,
}

parse :: proc(data: []byte, allocator := context.allocator) -> (value: Value, err: Parse_Error) {
	context.allocator = allocator
	root := make(Table)
	p := &Parser{src = string(data), line = 1, allocator = allocator}
	if len(data) == 0 {return root, nil}

	current := root
	at_root := true

	for p.pos < len(p.src) {
		skip_space_and_newlines(p)
		if p.pos >= len(p.src) {break}
		if peek(p) == '#' {skip_to_newline(p); continue}

		if peek(p) == '[' {
			p.pos += 1
			array_table := false
			if p.pos < len(p.src) && peek(p) == '[' {
				array_table = true
				p.pos += 1
			}
			skip_whitespace(p)
			path, key_err := parse_key_path(p)
			if key_err != nil {return nil, key_err}
			skip_whitespace(p)
			if array_table {
				if p.pos >= len(p.src) || peek(p) != ']' {return nil, .Expected_Section_Close}
				p.pos += 1
				if p.pos >= len(p.src) || peek(p) != ']' {return nil, .Expected_Section_Close}
				p.pos += 1
			} else {
				if p.pos >= len(p.src) || peek(p) != ']' {return nil, .Expected_Section_Close}
				p.pos += 1
			}
			skip_to_newline(p)

			if array_table {
				table, ok := ensure_array_table(&root, path[:])
				if !ok {return nil, .Duplicate_Table}
				current = table
			} else {
				table, ok := ensure_table(&root, path[:])
				if !ok {return nil, .Duplicate_Table}
				current = table
			}
			delete(path)
			at_root = false
			continue
		}

		keys, key_err := parse_key_path(p)
		if key_err != nil {return nil, key_err}
		skip_whitespace(p)
		if p.pos >= len(p.src) || peek(p) != '=' {return nil, .Expected_Equals}
		p.pos += 1
		skip_whitespace(p)
		val, val_err := parse_value(p)
		if val_err != nil {return nil, val_err}
		skip_whitespace(p)
		if p.pos < len(p.src) && peek(p) == '#' {skip_to_newline(p)}
		if p.pos < len(p.src) && peek(p) != '\n' && peek(p) != '\r' {return nil, .Invalid_Data}

		ensure_table(&root, nil)
		dest_ptr := &current
		if at_root {dest_ptr = &root}
		if len(keys) > 1 {
			sub, sub_ok := ensure_table_path(dest_ptr, keys[:len(keys) - 1])
			if !sub_ok {destroy_value(val); return nil, .Duplicate_Key}
			dest_ptr^ = sub
		}
		key := keys[len(keys) - 1]
		if _, exists := dest_ptr^[key]; exists {destroy_value(val); return nil, .Duplicate_Key}
		dest_ptr^[key] = val
		delete(keys)
		skip_to_newline(p)
	}
	return root, nil
}

@(private)
peek :: proc(p: ^Parser) -> byte {return p.src[p.pos]}

@(private)
skip_whitespace :: proc(p: ^Parser) {
	for p.pos < len(p.src) && (peek(p) == ' ' || peek(p) == '\t') {p.pos += 1}
}

@(private)
skip_space_and_newlines :: proc(p: ^Parser) {
	for p.pos < len(p.src) {
		switch peek(p) {
		case ' ', '\t', '\r', '\n':
			p.pos += 1
		case:
			return
		}
	}
}

@(private)
skip_to_newline :: proc(p: ^Parser) {
	for p.pos < len(p.src) && peek(p) != '\n' {p.pos += 1}
	if p.pos < len(p.src) && peek(p) == '\n' {p.pos += 1; p.line += 1}
}

@(private)
parse_key_path :: proc(p: ^Parser) -> (keys: [dynamic]string, err: Parse_Error) {
	keys = make([dynamic]string)
	for {
		skip_whitespace(p)
		if p.pos >= len(p.src) {return keys, .Invalid_Key}
		key: string
		if peek(p) == '"' {
			p.pos += 1
			start := p.pos
			for p.pos < len(p.src) && peek(p) != '"' {
				if peek(p) == '\\' {p.pos += 1}
				p.pos += 1
			}
			if p.pos >= len(p.src) {return keys, .Unterminated_String}
			raw := p.src[start:p.pos]; p.pos += 1
			unescaped, ok := unescape_basic_string(raw)
			if !ok {return keys, .Invalid_String}
			key = unescaped
		} else if peek(p) == '\'' {
			p.pos += 1
			start := p.pos
			for p.pos < len(p.src) && peek(p) != '\'' {p.pos += 1}
			if p.pos >= len(p.src) {return keys, .Unterminated_String}
			key = strings.clone(p.src[start:p.pos]); p.pos += 1
		} else {
			start := p.pos
			for p.pos < len(p.src) {
				c := peek(p)
				if c == ' ' || c == '\t' || c == '.' || c == '=' || c == ']' {break}
				if c == '\n' || c == '\r' {break}
				p.pos += 1
			}
			if p.pos == start {return keys, .Invalid_Key}
			key = strings.clone(p.src[start:p.pos])
			if !is_bare_key(key) {return keys, .Invalid_Key}
		}
		append(&keys, key)
		skip_whitespace(p)
		if p.pos >= len(p.src) || peek(p) != '.' {break}
		p.pos += 1
	}
	return
}

@(private)
is_bare_key :: proc(key: string) -> bool {
	if len(key) == 0 {return false}
	for c in key {
		if c >= 'A' && c <= 'Z' {continue}
		if c >= 'a' && c <= 'z' {continue}
		if c >= '0' && c <= '9' {continue}
		if c == '-' || c == '_' {continue}
		return false
	}
	return true
}

@(private)
unescape_basic_string :: proc(raw: string) -> (out: string, ok: bool) {
	b, alloc_err := strings.builder_make(context.allocator)
	if alloc_err != nil {return "", false}
	i := 0
	for i < len(raw) {
		c := raw[i]
		if c != '\\' {
			strings.write_byte(&b, c)
			i += 1
			continue
		}
		i += 1
		if i >= len(raw) {strings.builder_destroy(&b); return "", false}
		switch raw[i] {
		case 'b':
			strings.write_byte(&b, '\b')
			i += 1
		case 't':
			strings.write_byte(&b, '\t')
			i += 1
		case 'n':
			strings.write_byte(&b, '\n')
			i += 1
		case 'f':
			strings.write_byte(&b, '\f')
			i += 1
		case 'r':
			strings.write_byte(&b, '\r')
			i += 1
		case 'e':
			strings.write_byte(&b, 0x1b)
			i += 1
		case '"', '\\':
			strings.write_byte(&b, raw[i])
			i += 1
		case '\n':
			i += 1
			for i < len(raw) && (raw[i] == ' ' || raw[i] == '\t') {i += 1}
		case '\r':
			i += 1
			if i < len(raw) && raw[i] == '\n' {i += 1}
			for i < len(raw) && (raw[i] == ' ' || raw[i] == '\t') {i += 1}
		case 'u':
			if i + 4 >= len(raw) {strings.builder_destroy(&b); return "", false}
			n, ok_hex := strconv.parse_u64_of_base(raw[i + 1:i + 5], 16)
			if !ok_hex {strings.builder_destroy(&b); return "", false}
			if n > 0x10ffff ||
			   (n >= 0xd800 && n <= 0xdfff) {strings.builder_destroy(&b); return "", false}
			buf: [4]byte
			encoded, nbytes := utf8.encode_rune(rune(n))
			copy(buf[:], encoded[:nbytes])
			strings.write_string(&b, string(buf[:nbytes]))
			i += 5
		case 'U':
			if i + 8 >= len(raw) {strings.builder_destroy(&b); return "", false}
			n, ok_hex := strconv.parse_u64_of_base(raw[i + 1:i + 9], 16)
			if !ok_hex {strings.builder_destroy(&b); return "", false}
			if n > 0x10ffff ||
			   (n >= 0xd800 && n <= 0xdfff) {strings.builder_destroy(&b); return "", false}
			buf: [4]byte
			encoded, nbytes := utf8.encode_rune(rune(n))
			copy(buf[:], encoded[:nbytes])
			strings.write_string(&b, string(buf[:nbytes]))
			i += 9
		case 'x':
			if i + 2 >= len(raw) {strings.builder_destroy(&b); return "", false}
			n, ok_hex := strconv.parse_u64_of_base(raw[i + 1:i + 3], 16)
			if !ok_hex {strings.builder_destroy(&b); return "", false}
			strings.write_byte(&b, byte(n))
			i += 3
		case:
			strings.builder_destroy(&b)
			return "", false
		}
	}
	result := strings.clone(strings.to_string(b))
	strings.builder_destroy(&b)
	return result, true
}

@(private)
ensure_table :: proc(root: ^Table, path: []string) -> (Table, bool) {
	current := root^
	for key in path {
		if existing, ok := current[key]; ok {
			if table, is_table := existing.(Table); is_table {
				current = table
				continue
			}
			return {}, false
		}
		table := make(Table)
		current[key] = table
		current = table
	}
	return current, true
}

@(private)
ensure_table_path :: proc(root: ^Table, path: []string) -> (Table, bool) {
	return ensure_table(root, path)
}

@(private)
ensure_array_table :: proc(root: ^Table, path: []string) -> (Table, bool) {
	if len(path) == 0 {return root^, false}
	parent := root^
	i := 0
	for ; i < len(path) - 1; i += 1 {
		key := path[i]
		if existing, ok := parent[key]; ok {
			if table, is_table := existing.(Table); is_table {
				parent = table
				continue
			}
			return {}, false
		}
		table := make(Table)
		parent[key] = table
		parent = table
	}

	key := path[len(path) - 1]
	if existing, ok := parent[key]; ok {
		#partial switch &a in existing {
		case Array:
			table := make(Table)
			append(&a, table)
			parent[key] = a
			return table, true
		case:
			return {}, false
		}
	}
	a := make(Array)
	table := make(Table)
	append(&a, table)
	parent[key] = a
	return table, true
}

@(private)
parse_value :: proc(p: ^Parser) -> (value: Value, err: Parse_Error) {
	skip_whitespace(p)
	if p.pos >= len(p.src) {return nil, .Invalid_Value}
	c := peek(p)
	switch c {
	case '"':
		if p.pos + 2 < len(p.src) && p.src[p.pos:p.pos + 3] == `"""` {
			return parse_multiline_basic_string(p)
		}
		p.pos += 1
		start := p.pos
		escaped := false
		for p.pos < len(p.src) {
			c = peek(p)
			if escaped {escaped = false; p.pos += 1; continue}
			if c == '\\' {escaped = true; p.pos += 1; continue}
			if c == '"' {
				raw := p.src[start:p.pos]; p.pos += 1
				s, ok := unescape_basic_string(raw)
				if !ok {return nil, .Invalid_String}
				return s, nil
			}
			if c == '\n' || c == '\r' {return nil, .Unterminated_String}
			p.pos += 1
		}
		return nil, .Unterminated_String
	case '\'':
		if p.pos + 2 < len(p.src) && p.src[p.pos:p.pos + 3] == `'''` {
			return parse_multiline_literal_string(p)
		}
		p.pos += 1
		start := p.pos
		for p.pos < len(p.src) && peek(p) != '\'' {p.pos += 1}
		if p.pos >= len(p.src) {return nil, .Unterminated_String}
		s := strings.clone(p.src[start:p.pos]); p.pos += 1
		return s, nil
	case '[':
		return parse_array(p)
	case '{':
		return parse_inline_table(p)
	case:
		start := p.pos
		for p.pos < len(p.src) {
			c = peek(p)
			if c == ',' || c == ']' || c == '}' || c == '#' || c == '\n' || c == '\r' {break}
			p.pos += 1
		}
		raw := strings.trim_space(p.src[start:p.pos])
		switch raw {
		case "true":
			return true, nil
		case "false":
			return false, nil
		case "inf":
			return Float(math.inf_f64(1)), nil
		case "+inf":
			return Float(math.inf_f64(1)), nil
		case "-inf":
			return Float(math.inf_f64(-1)), nil
		case "nan":
			return Float(math.nan_f64()), nil
		case "+nan":
			return Float(math.nan_f64()), nil
		case "-nan":
			return Float(math.nan_f64()), nil
		}
		clean_buf: [256]byte
		clean_len := 0
		for ci in 0 ..< len(raw) {
			if raw[ci] != '_' {
				clean_buf[clean_len] = raw[ci]
				clean_len += 1
			}
		}

		is_digits :: proc(s: string) -> bool {
			if len(s) == 0 {return false}
			for c in s {
				if c < '0' || c > '9' {return false}
			}
			return true
		}

		is_local_date :: proc(s: string) -> bool {
			return(
				len(s) == 10 &&
				s[4] == '-' &&
				s[7] == '-' &&
				is_digits(s[0:4]) &&
				is_digits(s[5:7]) &&
				is_digits(s[8:10]) \
			)
		}

		is_local_time :: proc(s: string) -> bool {
			return(
				len(s) >= 8 &&
				s[2] == ':' &&
				s[5] == ':' &&
				is_digits(s[0:2]) &&
				is_digits(s[3:5]) &&
				is_digits(s[6:8]) \
			)
		}

		is_local_datetime :: proc(s: string) -> bool {
			if len(s) < 19 {return false}
			return(
				(s[10] == 'T' || s[10] == 't' || s[10] == ' ') &&
				is_local_date(s[0:10]) &&
				is_local_time(s[11:]) \
			)
		}

		is_offset_datetime :: proc(s: string) -> bool {
			if !is_local_datetime(s) {return false}
			if len(s) > 0 {
				last := s[len(s) - 1]
				if last == 'Z' || last == 'z' {return true}
			}
			if len(s) >= 6 {
				suffix := s[len(s) - 6:]
				return(
					(suffix[0] == '+' || suffix[0] == '-') &&
					suffix[3] == ':' &&
					is_digits(suffix[1:3]) &&
					is_digits(suffix[4:6]) \
				)
			}
			return false
		}
		clean := string(clean_buf[:clean_len])
		if len(clean) >= 2 && clean[0] == '0' {
			switch clean[1] {
			case 'x', 'X':
				if n, ok := strconv.parse_u64_of_base(clean[2:], 16);
				   ok {return Integer(i64(n)), nil}
			case 'o', 'O':
				if n, ok := strconv.parse_u64_of_base(clean[2:], 8);
				   ok {return Integer(i64(n)), nil}
			case 'b', 'B':
				if n, ok := strconv.parse_u64_of_base(clean[2:], 2);
				   ok {return Integer(i64(n)), nil}
			}
		}
		raw = clean
		if n, ok := strconv.parse_i64(raw); ok {
			return Integer(n), nil
		}
		if f, ok := strconv.parse_f64(raw); ok {
			return Float(f), nil
		}
		if is_offset_datetime(raw) {
			return Offset_DateTime(strings.clone(raw)), nil
		}
		if is_local_datetime(raw) {
			return Local_DateTime(strings.clone(raw)), nil
		}
		if is_local_date(raw) {
			return Local_Date(strings.clone(raw)), nil
		}
		if is_local_time(raw) {
			return Local_Time(strings.clone(raw)), nil
		}
		return nil, .Invalid_Value
	}
}

@(private)
parse_array :: proc(p: ^Parser) -> (value: Value, err: Parse_Error) {
	p.pos += 1
	a := make(Array)
	p.depth += 1
	defer p.depth -= 1
	if p.depth > 128 {return nil, .Maximum_Depth}
	for {
		skip_whitespace(p)
		for p.pos < len(p.src) && (peek(p) == '\n' || peek(p) == '\r') {p.pos += 1}
		skip_whitespace(p)
		if p.pos >= len(p.src) {delete(a); return nil, .Unterminated_Array}
		if peek(p) == ']' {p.pos += 1; return a, nil}
		if peek(p) == ',' {p.pos += 1; continue}
		val, val_err := parse_value(p)
		if val_err != nil {destroy_value(a); return nil, val_err}
		append(&a, val)
		skip_whitespace(p)
		if p.pos < len(p.src) && peek(p) == '#' {skip_to_newline(p)}
		if p.pos < len(p.src) && peek(p) == ',' {p.pos += 1; continue}
		if p.pos < len(p.src) && peek(p) == ']' {p.pos += 1; return a, nil}
		for p.pos < len(p.src) && (peek(p) == '\n' || peek(p) == '\r') {p.pos += 1}
		skip_whitespace(p)
		if p.pos >= len(p.src) {destroy_value(a); return nil, .Unterminated_Array}
		if peek(p) == ']' {p.pos += 1; return a, nil}
	}
}

@(private)
parse_inline_table :: proc(p: ^Parser) -> (value: Value, err: Parse_Error) {
	p.pos += 1
	table := make(Table)
	p.depth += 1
	defer p.depth -= 1
	for {
		skip_whitespace(p)
		for p.pos < len(p.src) && (peek(p) == '\n' || peek(p) == '\r') {p.pos += 1}
		skip_whitespace(p)
		if p.pos >= len(p.src) {destroy_value(table); return nil, .Unterminated_Inline_Table}
		if peek(p) == '}' {p.pos += 1; return table, nil}
		keys, key_err := parse_key_path(p)
		if key_err != nil {destroy_value(table); return nil, key_err}
		skip_whitespace(p)
		if p.pos >= len(p.src) ||
		   peek(p) != '=' {destroy_value(table); return nil, .Expected_Equals}
		p.pos += 1
		skip_whitespace(p)
		val, val_err := parse_value(p)
		if val_err != nil {destroy_value(table); return nil, val_err}
		dest_ptr := &table
		if len(keys) > 1 {
			sub, ok := ensure_table_path(dest_ptr, keys[:len(keys) - 1])
			if !ok {destroy_value(val); destroy_value(table); return nil, .Duplicate_Key}
			dest_ptr^ = sub
		}
		dest_ptr^[keys[len(keys) - 1]] = val
		delete(keys)
		skip_whitespace(p)
		for p.pos < len(p.src) && (peek(p) == '\n' || peek(p) == '\r') {p.pos += 1}
		skip_whitespace(p)
		if p.pos < len(p.src) && peek(p) == ',' {
			p.pos += 1
			continue
		}
		if p.pos < len(p.src) && peek(p) == '}' {p.pos += 1; return table, nil}
		destroy_value(table); return nil, .Unterminated_Inline_Table
	}
}

@(private)
parse_multiline_basic_string :: proc(p: ^Parser) -> (value: Value, err: Parse_Error) {
	p.pos += 3
	if p.pos < len(p.src) && peek(p) == '\n' {p.pos += 1}
	start := p.pos
	for p.pos + 2 < len(p.src) {
		if p.src[p.pos:p.pos + 3] == `"""` {
			raw := p.src[start:p.pos]
			p.pos += 3
			s, ok := unescape_basic_string(raw)
			if !ok {return nil, .Invalid_String}
			return s, nil
		}
		p.pos += 1
	}
	return nil, .Unterminated_String
}

@(private)
parse_multiline_literal_string :: proc(p: ^Parser) -> (value: Value, err: Parse_Error) {
	p.pos += 3
	if p.pos < len(p.src) && peek(p) == '\n' {p.pos += 1}
	start := p.pos
	for p.pos + 2 < len(p.src) {
		if p.src[p.pos:p.pos + 3] == `'''` {
			s := strings.clone(p.src[start:p.pos]); p.pos += 3
			return s, nil
		}
		p.pos += 1
	}
	return nil, .Unterminated_String
}
