
// NOTE(bill): Used for UTF-8 strings
typedef struct String {
	u8 *text;
	isize len;
} String;
// NOTE(bill): used for printf style arguments
#define LIT(x) (x).len, (x).text




gb_inline String make_string(u8 *text, isize len) {
	String s;
	s.text = text;
	if (len < 0)
		len = gb_strlen(cast(char *)text);
	s.len = len;
	return s;
}

gb_inline String make_string(char *text) {
	return make_string(cast(u8 *)cast(void *)text, gb_strlen(text));
}

gb_inline b32 are_strings_equal(String a, String b) {
	if (a.len == b.len) {
		return gb_memcompare(a.text, b.text, a.len) == 0;
	}
	return false;
}

gb_inline b32 are_strings_equal_ignore_case(String a, String b) {
	if (a.len == b.len) {
		for (isize i = 0; i < a.len; i++) {
			char x = cast(char)a.text[i];
			char y = cast(char)b.text[i];
			if (gb_char_to_lower(x) != gb_char_to_lower(y))
				return false;
		}
		return true;
	}
	return false;
}


gb_inline isize string_extension_position(String str) {
	isize dot_pos = -1;
	isize i = str.len;
	b32 seen_dot = false;
	while (i --> 0) {
		if (str.text[i] == GB_PATH_SEPARATOR)
			break;
		if (str.text[i] == '.') {
			dot_pos = i;
			break;
		}
	}

	return dot_pos;
}

gb_inline b32 string_has_extension(String str, String ext) {
	if (str.len > ext.len+1) {
		u8 *s = str.text+str.len - ext.len-1;
		if (s[0] == '.') {
			s++;
			return gb_memcompare(s, ext.text, ext.len) == 0;
		}
		return false;
	}
	return false;
}

b32 string_contains_char(String s, u8 c) {
	for (isize i = 0; i < s.len; i++) {
		if (s.text[i] == c)
			return true;
	}
	return false;
}

b32 unquote_char(String s, u8 quote, Rune *rune, b32 *multi, String *tail_string) {
	if (s.text[0] == quote &&
	    (quote == '\'' || quote == '"')) {
		return false;
	} else if (s.text[0] >= 0x80) {
		Rune r = -1;
		isize size = gb_utf8_decode(s.text, s.len, &r);
		*rune = r;
		*tail_string = make_string(s.text+size, s.len-size);
		return true;
	} else if (s.text[0] != '\\') {
		*rune = s.text[0];
		*tail_string = make_string(s.text+1, s.len-1);
		return true;
	}

	if (s.len <= 1) {
		return false;
	}
	u8 c = s.text[1];
	s = make_string(s.text+2, s.len-2);

	switch (c) {
	default: return false;

	case 'a':  *rune = '\a'; break;
	case 'b':  *rune = '\b'; break;
	case 'f':  *rune = '\f'; break;
	case 'n':  *rune = '\n'; break;
	case 'r':  *rune = '\r'; break;
	case 't':  *rune = '\t'; break;
	case 'v':  *rune = '\v'; break;
	case '\\': *rune = '\\'; break;


	case '\'':
	case '"':
		if (c != quote) {
			return false;
		}
		*rune = c;
		break;

	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7': {
		i32 r = c - '0';
		if (s.len < 2) {
			return false;
		}
		for (isize i = 0; i < 2; i++) {
			i32 d = s.text[i] - '0';
			if (d < 0 || d > 7) {
				return false;
			}
			r = (r<<3) | d;
		}
		s = make_string(s.text+2, s.len-2);
		if (r > 0xff) {
			return false;
		}
		*rune = r;
	} break;

	case 'x':
	case 'u':
	case 'U': {
		isize n = 0;
		switch (c) {
		case 'x': n = 2; break;
		case 'u': n = 4; break;
		case 'U': n = 8; break;
		}

		Rune r = 0;
		if (s.len < n) {
			return false;
		}
		for (isize i = 0; i < n; i++) {
			i32 d = gb_hex_digit_to_int(s.text[i]);
			if (d < 0) {
				return false;
			}
			r = (r<<4) | d;
		}
		s = make_string(s.text+n, s.len-n);
		if (c == 'x') {
			*rune = r;
			break;
		}
		if (r > GB_RUNE_MAX) {
			return false;
		}
		*rune = r;
		*multi = true;
	} break;
	}
	*tail_string = s;
	return true;
}


// 0 == failure
// 1 == original memory
// 2 == new allocation
i32 unquote_string(gbAllocator a, String *s_) {
	GB_ASSERT(s_ != NULL);
	String s = *s_;
	isize n = s.len;
	if (n < 2)
		return 0;
	u8 quote = s.text[0];
	if (quote != s.text[n-1])
		return 0;
	s.text += 1;
	s.len -= 2;

	if (quote == '`') {
		if (string_contains_char(s, '`')) {
			return 0;
		}
		*s_ = s;
		return 1;
	}
	if (quote != '"' && quote != '\'')
		return 0;

	if (string_contains_char(s, '\n'))
		return 0;

	if (!string_contains_char(s, '\\') && !string_contains_char(s, quote)) {
		if (quote == '"') {
			*s_ = s;
			return 1;
		} else if (quote == '\'') {
			Rune r = GB_RUNE_INVALID;
			isize size = gb_utf8_decode(s.text, s.len, &r);
			if ((size == s.len) && (r != -1 || size != 1)) {
				*s_ = s;
				return 1;
			}
		}
	}

	u8 rune_temp[4] = {};
	isize buf_len = 3*s.len / 2;
	u8 *buf = gb_alloc_array(a, u8, buf_len);
	isize len = 0;
	while (s.len > 0) {
		String tail_string = {};
		Rune r = 0;
		b32 multi = false;
		b32 success = unquote_char(s, quote, &r, &multi, &tail_string);
		if (!success) {
			gb_free(a, buf);
			return 0;
		}
		s = tail_string;

		if (r < 0x80 || !multi) {
			buf[len++] = cast(u8)r;
		} else {
			isize size = gb_utf8_encode_rune(rune_temp, r);
			gb_memcopy(buf+len, rune_temp, size);
			len += size;
		}

		if (quote == '\'' && s.len != 0) {
			gb_free(a, buf);
			return 0;
		}
	}
	*s_ = make_string(buf, len);
	return 2;
}
