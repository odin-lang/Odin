gb_global gbArena string_buffer_arena = {0};
gb_global gbAllocator string_buffer_allocator = {0};

void init_string_buffer_memory(void) {
	// NOTE(bill): This should be enough memory for file systems
	gb_arena_init_from_allocator(&string_buffer_arena, heap_allocator(), gb_megabytes(1));
	string_buffer_allocator = gb_arena_allocator(&string_buffer_arena);
}


// NOTE(bill): Used for UTF-8 strings
typedef struct String {
	u8 *  text;
	isize len;
} String;
// NOTE(bill): used for printf style arguments
#define LIT(x) ((int)(x).len), (x).text


typedef struct String16 {
	wchar_t *text;
	isize    len;
} String16;


gb_inline String make_string(u8 *text, isize len) {
	String s;
	s.text = text;
	if (len < 0) {
		len = gb_strlen(cast(char *)text);
	}
	s.len = len;
	return s;
}


gb_inline String16 make_string16(wchar_t *text, isize len) {
	String16 s;
	s.text = text;
	s.len = len;
	return s;
}


gb_inline String make_string_c(char *text) {
	return make_string(cast(u8 *)cast(void *)text, gb_strlen(text));
}

#define str_lit(c_str) make_string(cast(u8 *)c_str, gb_size_of(c_str)-1)


gb_inline b32 are_strings_equal(String a, String b) {
	if (a.len == b.len) {
		return gb_memcompare(a.text, b.text, a.len) == 0;
	}
	return false;
}

gb_inline b32 str_eq_ignore_case(String a, String b) {
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

int string_compare(String x, String y) {
	if (x.len == y.len &&
	    x.text == y.text) {
		return 0;
	}

	isize n = gb_min(x.len, y.len);

	isize fast = n/gb_size_of(isize) + 1;
	isize offset = (fast-1)*gb_size_of(isize);
	isize curr_block = 0;
	if (n <= gb_size_of(isize)) {
		fast = 0;
	}

	isize *la = cast(isize *)x.text;
	isize *lb = cast(isize *)y.text;

	for (; curr_block < fast; curr_block++) {
		if (la[curr_block] ^ lb[curr_block]) {
			for (isize pos = curr_block*gb_size_of(isize); pos < n; pos++) {
				if (x.text[pos] ^ y.text[pos]) {
					return cast(int)x.text[pos] - cast(int)y.text[pos];
				}
			}
		}
	}

	for (; offset < n; offset++) {
		if (x.text[offset] ^ y.text[offset]) {
			return cast(int)x.text[offset] - cast(int)y.text[offset];
		}
	}

	return 0;
}

GB_COMPARE_PROC(string_cmp_proc) {
	String x = *(String *)a;
	String y = *(String *)b;
	return string_compare(x, y);
}


// gb_inline bool operator ==(String a, String b) { return are_strings_equal(a, b) != 0; }
// gb_inline bool operator !=(String a, String b) { return !operator==(a, b); }
// gb_inline bool operator < (String a, String b) { return string_compare(a, b) < 0; }
// gb_inline bool operator > (String a, String b) { return string_compare(a, b) > 0; }
// gb_inline bool operator <=(String a, String b) { return string_compare(a, b) <= 0; }
// gb_inline bool operator >=(String a, String b) { return string_compare(a, b) >= 0; }

// template <size_t N> gb_inline bool operator ==(String a, char const (&b)[N]) { return a == make_string(cast(u8 *)b, N-1); }
// template <size_t N> gb_inline bool operator !=(String a, char const (&b)[N]) { return a != make_string(cast(u8 *)b, N-1); }
// template <size_t N> gb_inline bool operator ==(char const (&a)[N], String b) { return make_string(cast(u8 *)a, N-1) == b; }
// template <size_t N> gb_inline bool operator !=(char const (&a)[N], String b) { return make_string(cast(u8 *)a, N-1) != b; }

gb_inline bool str_eq(String a, String b) { return are_strings_equal(a, b) != 0; }
gb_inline bool str_ne(String a, String b) { return !str_eq(a, b);                }
gb_inline bool str_lt(String a, String b) { return string_compare(a, b) < 0;     }
gb_inline bool str_gt(String a, String b) { return string_compare(a, b) > 0;     }
gb_inline bool str_le(String a, String b) { return string_compare(a, b) <= 0;    }
gb_inline bool str_ge(String a, String b) { return string_compare(a, b) >= 0;    }



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

// TODO(bill): Make this non-windows specific
String16 string_to_string16(gbAllocator a, String s) {
	if (s.len < 1) {
		return make_string16(NULL, 0);
	}

	int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
	                              cast(char *)s.text, s.len, NULL, 0);
	if (len == 0) {
		return make_string16(NULL, 0);
	}

	wchar_t *text = gb_alloc_array(a, wchar_t, len+1);

	int len1 = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
	                               cast(char *)s.text, s.len, text, len);
	if (len1 == 0) {
		gb_free(a, text);
		return make_string16(NULL, 0);
	}
	text[len] = 0;

	return make_string16(text, len-1);
}

String string16_to_string(gbAllocator a, String16 s) {
	if (s.len < 1) {
		return make_string(NULL, 0);
	}

	int len = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
	                              s.text, s.len, NULL, 0,
	                              NULL, NULL);
	if (len == 0) {
		return make_string(NULL, 0);
	}

	u8 *text = gb_alloc_array(a, u8, len+1);

	int len1 = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
	                               s.text, s.len, cast(char *)text, len,
	                               NULL, NULL);
	if (len1 == 0) {
		gb_free(a, text);
		return make_string(NULL, 0);
	}
	text[len] = 0;

	return make_string(text, len-1);
}


















b32 unquote_char(String s, u8 quote, Rune *rune, b32 *multiple_bytes, String *tail_string) {
	if (s.text[0] == quote &&
	    (quote == '$' || quote == '"')) {
		return false;
	} else if (s.text[0] >= 0x80) {
		Rune r = -1;
		isize size = gb_utf8_decode(s.text, s.len, &r);
		*rune = r;
		*multiple_bytes = true;
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


	case '$':
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
		i32 r = gb_digit_to_int(c);
		if (s.len < 2) {
			return false;
		}
		for (isize i = 0; i < 2; i++) {
			i32 d = gb_digit_to_int(s.text[i]);
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
		isize count = 0;
		switch (c) {
		case 'x': count = 2; break;
		case 'u': count = 4; break;
		case 'U': count = 8; break;
		}

		Rune r = 0;
		if (s.len < count) {
			return false;
		}
		for (isize i = 0; i < count; i++) {
			i32 d = gb_hex_digit_to_int(s.text[i]);
			if (d < 0) {
				return false;
			}
			r = (r<<4) | d;
		}
		s = make_string(s.text+count, s.len-count);
		if (c == 'x') {
			*rune = r;
			break;
		}
		if (r > GB_RUNE_MAX) {
			return false;
		}
		*rune = r;
		*multiple_bytes = true;
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
	if (quote != '"' && quote != '$')
		return 0;

	if (string_contains_char(s, '\n'))
		return 0;

	if (!string_contains_char(s, '\\') && !string_contains_char(s, quote)) {
		if (quote == '"') {
			*s_ = s;
			return 1;
		} else if (quote == '$') {
			Rune r = GB_RUNE_INVALID;
			isize size = gb_utf8_decode(s.text, s.len, &r);
			if ((size == s.len) && (r != -1 || size != 1)) {
				*s_ = s;
				return 1;
			}
		}
	}


	u8 rune_temp[4] = {0};
	isize buf_len = 3*s.len / 2;
	u8 *buf = gb_alloc_array(a, u8, buf_len);
	isize offset = 0;
	while (s.len > 0) {
		String tail_string = {0};
		Rune r = 0;
		b32 multiple_bytes = false;
		b32 success = unquote_char(s, quote, &r, &multiple_bytes, &tail_string);
		if (!success) {
			gb_free(a, buf);
			return 0;
		}
		s = tail_string;

		if (r < 0x80 || !multiple_bytes) {
			buf[offset++] = cast(u8)r;
		} else {
			isize size = gb_utf8_encode_rune(rune_temp, r);
			gb_memmove(buf+offset, rune_temp, size);
			offset += size;
		}

		if (quote == '$' && s.len != 0) {
			gb_free(a, buf);
			return 0;
		}
	}
	*s_ = make_string(buf, offset);
	return 2;
}
