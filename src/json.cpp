enum JsonKind : u8 {
	Json_Invalid,
	Json_Null,
	Json_Boolean,
	Json_Number,
	Json_String,
	Json_Array,
	Json_Object,
};

struct JsonValue;

struct JsonObjectEntry {
	String     key;
	JsonValue *value;
};

struct JsonValue {
	JsonKind kind;
	union {
		bool                   boolean;
		f64                    number;
		String                 string;
		Slice<JsonValue *>     array;
		Slice<JsonObjectEntry> object;
	};
};

struct JsonError {
	i32         line;
	i32         column;
	char const *message;
};

struct JsonParser {
	gbAllocator allocator;
	String      text;
	isize       offset;
	isize       depth;
	JsonError   error;
};

enum { JSON_MAX_DEPTH = 512 };

gb_internal bool json_error(JsonParser *p, char const *message) {
	if (p->error.message != nullptr) {
		return false;
	}

	p->error.line    = 1;
	p->error.column  = 1;
	p->error.message = message;

	for (isize i = 0; i < p->offset && i < p->text.len; i++) {
		if (p->text[i] == '\n') {
			p->error.line  += 1;
			p->error.column = 1;
		} else {
			p->error.column += 1;
		}
	}
	return false;
}

gb_internal void json_skip_whitespace(JsonParser *p) {
	while (p->offset < p->text.len) {
		u8 next = 0;
		if (p->offset+1 < p->text.len) {
			next = p->text[p->offset+1];
		}

		switch (p->text[p->offset]) {
		case ' ':
		case '\t':
		case '\n':
		case '\r':
			p->offset += 1;
			continue;
		case '/':
			if (next == '/') {
				while (p->offset < p->text.len && p->text[p->offset] != '\n') {
					p->offset += 1;
				}
				continue;
			} else if (next == '*') {
				isize start = p->offset;
				p->offset += 2;
				for (;;) {
					if (p->offset+1 >= p->text.len) {
						p->offset = start;
						json_error(p, "unterminated comment");
						p->offset = p->text.len;
						return;
					}
					if (p->text[p->offset] == '*' && p->text[p->offset+1] == '/') {
						p->offset += 2;
						break;
					}
					p->offset += 1;
				}
				continue;
			}
			break;
		}
		return;
	}
}

gb_internal bool json_peek(JsonParser *p, char c) {
	json_skip_whitespace(p);
	return p->offset < p->text.len && p->text[p->offset] == c;
}

gb_internal bool json_allow(JsonParser *p, char c) {
	if (json_peek(p, c)) {
		p->offset += 1;
		return true;
	}
	return false;
}

gb_internal bool json_parse_hex4(JsonParser *p, Rune *r) {
	if (p->offset+4 > p->text.len) {
		return json_error(p, "expected 4 hexadecimal digits after \\u");
	}
	Rune x = 0;
	for (isize i = 0; i < 4; i++) {
		u8 c = p->text[p->offset+i];
		Rune d = 0;
		if ('0' <= c && c <= '9') {
			d = c - '0';
		} else if ('a' <= c && c <= 'f') {
			d = c - 'a' + 10;
		} else if ('A' <= c && c <= 'F') {
			d = c - 'A' + 10;
		} else {
			return json_error(p, "expected 4 hexadecimal digits after \\u");
		}
		x = x*16 + d;
	}
	p->offset += 4;
	*r = x;
	return true;
}

gb_internal bool json_parse_string(JsonParser *p, String *out) {
	json_skip_whitespace(p);
	if (p->offset >= p->text.len || p->text[p->offset] != '"') {
		return json_error(p, "expected a string");
	}
	p->offset += 1;

	isize start = p->offset;
	u8 *buf = gb_alloc_array(p->allocator, u8, p->text.len - start);
	isize n = 0;
	for (;;) {
		if (p->offset >= p->text.len) {
			p->offset = start-1;
			return json_error(p, "unterminated string");
		}
		u8 c = p->text[p->offset];
		if (c == '"') {
			p->offset += 1;
			break;
		}
		if (c < ' ') {
			return json_error(p, "control character in string");
		}
		if (c != '\\') {
			buf[n++] = c;
			p->offset += 1;
			continue;
		}

		p->offset += 1;
		if (p->offset >= p->text.len) {
			return json_error(p, "unterminated escape");
		}
		u8 e = p->text[p->offset];
		p->offset += 1;
		switch (e) {
		case '"':  buf[n++] = '"';  break;
		case '\\': buf[n++] = '\\'; break;
		case '/':  buf[n++] = '/';  break;
		case 'b':  buf[n++] = '\b'; break;
		case 'f':  buf[n++] = '\f'; break;
		case 'n':  buf[n++] = '\n'; break;
		case 'r':  buf[n++] = '\r'; break;
		case 't':  buf[n++] = '\t'; break;
		case 'u': {
			Rune r = 0;
			if (!json_parse_hex4(p, &r)) {
				return false;
			}
			if (0xd800 <= r && r < 0xdc00) {
				Rune low = 0;
				if (p->offset+2 <= p->text.len && p->text[p->offset] == '\\' && p->text[p->offset+1] == 'u') {
					p->offset += 2;
					if (!json_parse_hex4(p, &low)) {
						return false;
					}
				}
				if (0xdc00 <= low && low < 0xe000) {
					r = 0x10000 + ((r - 0xd800) << 10) + (low - 0xdc00);
				} else {
					r = GB_RUNE_INVALID;
				}
			} else if (0xdc00 <= r && r < 0xe000) {
				r = GB_RUNE_INVALID;
			}
			u8 utf8[4] = {};
			isize w = gb_utf8_encode_rune(utf8, r);
			gb_memmove(buf+n, utf8, w);
			n += w;
			break;
		}
		default:
			p->offset -= 1;
			return json_error(p, "invalid escape in string");
		}
	}
	*out = make_string(buf, n);
	return true;
}

gb_internal bool json_parse_value(JsonParser *p, JsonValue **out);

gb_internal bool json_parse_array(JsonParser *p, JsonValue *v) {
	auto elems = array_make<JsonValue *>(heap_allocator());
	defer (array_free(&elems));
	while (!json_peek(p, ']')) {
		JsonValue *elem = nullptr;
		if (!json_parse_value(p, &elem)) {
			return false;
		}
		array_add(&elems, elem);
		if (!json_allow(p, ',')) {
			break;
		}
	}
	if (!json_allow(p, ']')) {
		return json_error(p, "expected ',' or ']' in array");
	}
	v->kind  = Json_Array;
	v->array = slice_make<JsonValue *>(p->allocator, elems.count);
	slice_copy(&v->array, slice_from_array(elems));
	return true;
}

gb_internal bool json_parse_object(JsonParser *p, JsonValue *v) {
	auto entries = array_make<JsonObjectEntry>(heap_allocator());
	defer (array_free(&entries));
	while (!json_peek(p, '}')) {
		JsonObjectEntry entry = {};
		if (!json_parse_string(p, &entry.key)) {
			return false;
		}
		if (!json_allow(p, ':')) {
			return json_error(p, "expected ':' after an object key");
		}
		if (!json_parse_value(p, &entry.value)) {
			return false;
		}
		array_add(&entries, entry);
		if (!json_allow(p, ',')) {
			break;
		}
	}
	if (!json_allow(p, '}')) {
		return json_error(p, "expected ',' or '}' in object");
	}
	v->kind   = Json_Object;
	v->object = slice_make<JsonObjectEntry>(p->allocator, entries.count);
	slice_copy(&v->object, slice_from_array(entries));
	return true;
}

gb_internal isize json_skip_digits(JsonParser *p) {
	isize start = p->offset;
	while (p->offset < p->text.len && gb_char_is_digit(p->text[p->offset])) {
		p->offset += 1;
	}
	return p->offset - start;
}

gb_internal bool json_parse_number(JsonParser *p, JsonValue *v) {
	isize start = p->offset;
	if (p->offset < p->text.len && p->text[p->offset] == '-') {
		p->offset += 1;
	}
	if (json_skip_digits(p) == 0) {
		p->offset = start;
		return json_error(p, "expected a value");
	}
	if (p->offset < p->text.len && p->text[p->offset] == '.') {
		p->offset += 1;
		if (json_skip_digits(p) == 0) {
			return json_error(p, "expected digits after '.'");
		}
	}
	if (p->offset < p->text.len && (p->text[p->offset] == 'e' || p->text[p->offset] == 'E')) {
		p->offset += 1;
		if (p->offset < p->text.len && (p->text[p->offset] == '+' || p->text[p->offset] == '-')) {
			p->offset += 1;
		}
		if (json_skip_digits(p) == 0) {
			return json_error(p, "expected digits in the exponent");
		}
	}

	v->kind   = Json_Number;
	v->number = gb_str_to_f64(alloc_cstring(temporary_allocator(), substring(p->text, start, p->offset)), nullptr);
	return true;
}

gb_internal bool json_parse_literal(JsonParser *p, String word) {
	if (string_starts_with(substring(p->text, p->offset, p->text.len), word)) {
		p->offset += word.len;
		return true;
	}
	return false;
}

gb_internal bool json_parse_value(JsonParser *p, JsonValue **out) {
	json_skip_whitespace(p);
	if (p->offset >= p->text.len) {
		return json_error(p, "expected a value");
	}
	if (p->depth >= JSON_MAX_DEPTH) {
		return json_error(p, "values nested too deeply");
	}

	JsonValue *v = gb_alloc_item(p->allocator, JsonValue);
	*out = v;

	p->depth += 1;
	defer (p->depth -= 1);

	switch (p->text[p->offset]) {
	case '{':
		p->offset += 1;
		return json_parse_object(p, v);
	case '[':
		p->offset += 1;
		return json_parse_array(p, v);
	case '"':
		v->kind = Json_String;
		return json_parse_string(p, &v->string);
	}

	if (json_parse_literal(p, str_lit("null"))) {
		v->kind = Json_Null;
		return true;
	}
	if (json_parse_literal(p, str_lit("true"))) {
		v->kind = Json_Boolean;
		v->boolean = true;
		return true;
	}
	if (json_parse_literal(p, str_lit("false"))) {
		v->kind = Json_Boolean;
		v->boolean = false;
		return true;
	}
	return json_parse_number(p, v);
}

gb_internal bool json_parse(gbAllocator allocator, String text, JsonValue **out, JsonError *error) {
	JsonParser p = {};
	p.allocator = allocator;
	p.text = text;

	bool ok = json_parse_value(&p, out);
	if (ok) {
		json_skip_whitespace(&p);
		if (p.offset < p.text.len) {
			ok = json_error(&p, "unexpected text after the value");
		}
	}
	if (p.error.message != nullptr) {
		ok = false;
	}
	*error = p.error;
	return ok;
}
