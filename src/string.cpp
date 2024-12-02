gb_global BlockingMutex string_buffer_mutex = {};

// NOTE(bill): Used for UTF-8 strings
struct String {
	u8 *  text;
	isize len;

	u8 const &operator[](isize i) const {
		GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
		return text[i];
	}
};
struct String_Iterator {
	String const &str;
	isize  pos;
};
// NOTE(bill): used for printf style arguments
#define LIT(x) ((int)(x).len), (x).text
#if defined(GB_COMPILER_MSVC) && _MSC_VER < 1700
	#define STR_LIT(c_str) make_string(cast(u8 *)c_str, gb_size_of(c_str)-1)
#else
	#define STR_LIT(c_str) String{cast(u8 *)c_str, gb_size_of(c_str)-1}
#endif

#define str_lit(c_str) STR_LIT(c_str)

// NOTE(bill): String16 is only used for Windows due to its file directories
struct String16 {
	wchar_t *text;
	isize    len;
	wchar_t const &operator[](isize i) const {
		GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
		return text[i];
	}
};


gb_internal gb_inline String make_string(u8 const *text, isize len) {
	String s;
	s.text = cast(u8 *)text;
	if (len < 0) {
		len = gb_strlen(cast(char const *)text);
	}
	s.len = len;
	return s;
}


gb_internal gb_inline String16 make_string16(wchar_t const *text, isize len) {
	String16 s;
	s.text = cast(wchar_t *)text;
	s.len = len;
	return s;
}

gb_internal isize string16_len(wchar_t const *s) {
	if (s == nullptr) {
		return 0;
	}
	wchar_t const *p = s;
	while (*p) {
		p++;
	}
	return p - s;
}


gb_internal gb_inline String make_string_c(char const *text) {
	return make_string(cast(u8 *)cast(void *)text, gb_strlen(text));
}

gb_internal gb_inline String16 make_string16_c(wchar_t const *text) {
	return make_string16(text, string16_len(text));
}

gb_internal String substring(String const &s, isize lo, isize hi) {
	isize max = s.len;
	GB_ASSERT_MSG(lo <= hi && hi <= max, "%td..%td..%td", lo, hi, max);

	return make_string(s.text+lo, hi-lo);
}


gb_internal char *alloc_cstring(gbAllocator a, String s) {
	char *c_str = gb_alloc_array(a, char, s.len+1);
	gb_memmove(c_str, s.text, s.len);
	c_str[s.len] = '\0';
	return c_str;
}

gb_internal wchar_t *alloc_wstring(gbAllocator a, String16 s) {
	wchar_t *c_str = gb_alloc_array(a, wchar_t, s.len+1);
	gb_memmove(c_str, s.text, s.len*2);
	c_str[s.len] = '\0';
	return c_str;
}


gb_internal gb_inline bool str_eq_ignore_case(String const &a, String const &b) {
	if (a.len == b.len) {
		for (isize i = 0; i < a.len; i++) {
			char x = cast(char)a[i];
			char y = cast(char)b[i];
			if (gb_char_to_lower(x) != gb_char_to_lower(y)) {
				return false;
			}
		}
		return true;
	}
	return false;
}

template <isize N>
gb_internal gb_inline bool str_eq_ignore_case(String const &a, char const (&b_)[N]) {
	if (a.len != N-1) {
		return false;
	}
	String b = {cast(u8 *)b_, N-1};
	return str_eq_ignore_case(a, b);
}


gb_internal void string_to_lower(String *s) {
	for (isize i = 0; i < s->len; i++) {
		s->text[i] = gb_char_to_lower(s->text[i]);
	}
}

gb_internal int string_compare(String const &a, String const &b) {
	if (a.text == b.text) {
		return cast(int)(a.len - b.len);
	}
	if (a.text == nullptr) {
		return -1;
	}
	if (b.text == nullptr) {
		return +1;
	}

	uintptr n = gb_min(a.len, b.len);
	int res = memcmp(a.text, b.text, n);
	if (res == 0) {
		res = cast(int)(a.len - b.len);
	}
	return res;
}

gb_internal isize string_index_byte(String const &s, u8 x) {
	for (isize i = 0; i < s.len; i++) {
		if (s.text[i] == x) {
			return i;
		}
	}
	return -1;
}

gb_internal gb_inline bool str_eq(String const &a, String const &b) {
	if (a.len != b.len) return false;
	if (a.len == 0) return true;
	return memcmp(a.text, b.text, a.len) == 0;
}
gb_internal gb_inline bool str_ne(String const &a, String const &b) { return !str_eq(a, b);                }
gb_internal gb_inline bool str_lt(String const &a, String const &b) { return string_compare(a, b) < 0;     }
gb_internal gb_inline bool str_gt(String const &a, String const &b) { return string_compare(a, b) > 0;     }
gb_internal gb_inline bool str_le(String const &a, String const &b) { return string_compare(a, b) <= 0;    }
gb_internal gb_inline bool str_ge(String const &a, String const &b) { return string_compare(a, b) >= 0;    }

gb_internal gb_inline bool operator == (String const &a, String const &b) { return str_eq(a, b); }
gb_internal gb_inline bool operator != (String const &a, String const &b) { return str_ne(a, b); }
gb_internal gb_inline bool operator <  (String const &a, String const &b) { return str_lt(a, b); }
gb_internal gb_inline bool operator >  (String const &a, String const &b) { return str_gt(a, b); }
gb_internal gb_inline bool operator <= (String const &a, String const &b) { return str_le(a, b); }
gb_internal gb_inline bool operator >= (String const &a, String const &b) { return str_ge(a, b); }

template <isize N> gb_internal bool operator == (String const &a, char const (&b)[N]) { return str_eq(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> gb_internal bool operator != (String const &a, char const (&b)[N]) { return str_ne(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> gb_internal bool operator <  (String const &a, char const (&b)[N]) { return str_lt(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> gb_internal bool operator >  (String const &a, char const (&b)[N]) { return str_gt(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> gb_internal bool operator <= (String const &a, char const (&b)[N]) { return str_le(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> gb_internal bool operator >= (String const &a, char const (&b)[N]) { return str_ge(a, make_string(cast(u8 *)b, N-1)); }

template <> bool operator == (String const &a, char const (&b)[1]) { return a.len == 0; }
template <> bool operator != (String const &a, char const (&b)[1]) { return a.len != 0; }

gb_internal gb_inline bool string_starts_with(String const &s, String const &prefix) {
	if (prefix.len > s.len) {
		return false;
	}

	return substring(s, 0, prefix.len) == prefix;
}

gb_internal gb_inline bool string_ends_with(String const &s, String const &suffix) {
	if (suffix.len > s.len) {
		return false;
	}

	return substring(s, s.len-suffix.len, s.len) == suffix;
}

gb_internal gb_inline bool string_starts_with(String const &s, u8 prefix) {
	if (1 > s.len) {
		return false;
	}

	return s[0] == prefix;
}


gb_internal gb_inline bool string_ends_with(String const &s, u8 suffix) {
	if (1 > s.len) {
		return false;
	}

	return s[s.len-1] == suffix;
}



gb_internal gb_inline String string_trim_starts_with(String const &s, String const &prefix) {
	if (string_starts_with(s, prefix)) {
		return substring(s, prefix.len, s.len);
	}
	return s;
}


gb_internal String string_split_iterator(String_Iterator *it, const char sep) {
	isize start = it->pos;
	isize end   = it->str.len;

	if (start == end) {
		return str_lit("");
	}

	isize i = start;
	for (; i < it->str.len; i++) {
		if (it->str[i] == sep) {
			String res = substring(it->str, start, i);
			it->pos += res.len + 1;
			return res;
		}
	}
	it->pos = end;
	return substring(it->str, start, end);
}

gb_internal gb_inline bool is_separator(u8 const &ch) {
	return (ch == '/' || ch == '\\');
}


gb_internal gb_inline isize string_extension_position(String const &str) {
	isize dot_pos = -1;
	isize i = str.len;
	while (i --> 0) {
		if (is_separator(str[i]))
			break;
		if (str[i] == '.') {
			dot_pos = i;
			break;
		}
	}

	return dot_pos;
}

gb_internal String path_extension(String const &str, bool include_dot = true) {
	isize pos = string_extension_position(str);
	if (pos < 0) {
		return make_string(nullptr, 0);
	}
	return substring(str, include_dot ? pos : pos + 1, str.len);
}

gb_internal String string_trim_whitespace(String str) {
	while (str.len > 0 && rune_is_whitespace(str[str.len-1])) {
		str.len--;
	}

	while (str.len > 0 && str[str.len-1] == 0) {
		str.len--;
	}

	while (str.len > 0 && rune_is_whitespace(str[0])) {
		str.text++;
		str.len--;
	}

	return str;
}
gb_internal String string_trim_trailing_whitespace(String str) {
	while (str.len > 0)  {
		u8 c = str[str.len-1];
		if (rune_is_whitespace(c) || c == 0) {
			str.len -= 1;
		} else {
			break;
		}
	}
	return str;
}

gb_internal String split_lines_first_line_from_array(Array<u8> const &array, gbAllocator allocator) {
	String_Iterator it = {{array.data, array.count}, 0};

	String line = string_split_iterator(&it, '\n');
	line = string_trim_trailing_whitespace(line);
	return line;
}

gb_internal Array<String> split_lines_from_array(Array<u8> const &array, gbAllocator allocator) {
	Array<String> lines = {};
	lines.allocator = allocator;

	String_Iterator it = {{array.data, array.count}, 0};

	for (;;) {
		String line = string_split_iterator(&it, '\n');
		if (line.len == 0) {
			break;
		}
		line = string_trim_trailing_whitespace(line);
		array_add(&lines, line);
	}

	return lines;
}

gb_internal bool string_contains_char(String const &s, u8 c) {
	isize i;
	for (i = 0; i < s.len; i++) {
		if (s[i] == c)
			return true;
	}
	return false;
}

gb_internal bool string_contains_string(String const &haystack, String const &needle) {
	if (needle.len == 0) return true;
	if (needle.len > haystack.len) return false;

	for (isize i = 0; i <= haystack.len - needle.len; i++) {
		bool found = true;
		for (isize j = 0; j < needle.len; j++) {
			if (haystack[i + j] != needle[j]) {
				found = false;
				break;
			}
		}
		if (found) {
			return true;
		}
	}
	return false;
}

gb_internal String filename_from_path(String s) {
	isize i = string_extension_position(s);
	if (i >= 0) {
		s = substring(s, 0, i);
		return s;
	}
	if (i > 0) {
		isize j = 0;
		for (j = s.len-1; j >= 0; j--) {
			if (is_separator(s[j])) {
				break;
			}
		}
		return substring(s, j+1, s.len);
	}
	return make_string(nullptr, 0);
}


gb_internal String filename_without_directory(String s) {
	isize j = 0;
	for (j = s.len-1; j >= 0; j--) {
		if (is_separator(s[j])) {
			break;
		}
	}
	return substring(s, gb_max(j+1, 0), s.len);
}

gb_internal String concatenate_strings(gbAllocator a, String const &x, String const &y) {
	isize len = x.len+y.len;
	u8 *data = gb_alloc_array(a, u8, len+1);
	gb_memmove(data,       x.text, x.len);
	gb_memmove(data+x.len, y.text, y.len);
	data[len] = 0;
	return make_string(data, len);
}
gb_internal String concatenate3_strings(gbAllocator a, String const &x, String const &y, String const &z) {
	isize len = x.len+y.len+z.len;
	u8 *data = gb_alloc_array(a, u8, len+1);
	gb_memmove(data,             x.text, x.len);
	gb_memmove(data+x.len,       y.text, y.len);
	gb_memmove(data+x.len+y.len, z.text, z.len);
	data[len] = 0;
	return make_string(data, len);
}
gb_internal String concatenate4_strings(gbAllocator a, String const &x, String const &y, String const &z, String const &w) {
	isize len = x.len+y.len+z.len+w.len;
	u8 *data = gb_alloc_array(a, u8, len+1);
	gb_memmove(data,                   x.text, x.len);
	gb_memmove(data+x.len,             y.text, y.len);
	gb_memmove(data+x.len+y.len,       z.text, z.len);
	gb_memmove(data+x.len+y.len+z.len, w.text, w.len);
	data[len] = 0;
	return make_string(data, len);
}

#if defined(GB_SYSTEM_WINDOWS)
gb_internal String escape_char(gbAllocator a, String s, char cte) {
	isize buf_len = s.len;
	isize cte_count = 0;
	for (isize j = 0; j < s.len; j++) {
		if (s.text[j] == cte) {
			cte_count++;
		}
	}

	u8 *buf = gb_alloc_array(a, u8, buf_len+cte_count);
	isize i = 0;
	for (isize j = 0; j < s.len; j++) {
		u8 c = s.text[j];

		if (c == cte) {
			buf[i++] = '\\';
			buf[i++] = c;
		} else {
			buf[i++] = c;
		}
	}
	return make_string(buf, i);
}
#endif

gb_internal String string_join_and_quote(gbAllocator a, Array<String> strings) {
	if (!strings.count) {
		return make_string(nullptr, 0);
	}

	isize str_len = 0;
	for (isize i = 0; i < strings.count; i++) {
		str_len += strings[i].len;
	}

	gbString s = gb_string_make_reserve(a, str_len+strings.count); // +strings.count for spaces after args.
	for (isize i = 0; i < strings.count; i++) {
		if (i > 0) {
			s = gb_string_append_fmt(s, " ");
		}
#if defined(GB_SYSTEM_WINDOWS)
		s = gb_string_append_fmt(s, "\"%.*s\" ", LIT(escape_char(a, strings[i], '\\')));
#else
		s = gb_string_append_fmt(s, "\"%.*s\" ", LIT(strings[i]));
#endif
	}

	return make_string(cast(u8 *) s, gb_string_length(s));
}

gb_internal String copy_string(gbAllocator a, String const &s) {
	u8 *data = gb_alloc_array(a, u8, s.len+1);
	gb_memmove(data, s.text, s.len);
	data[s.len] = 0;
	return make_string(data, s.len);
}

gb_internal String normalize_path(gbAllocator a, String const &path, String const &sep) {
	String s;
	if (sep.len < 1) {
		return path;
	}
	if (path.len < 1) {
		s = STR_LIT("");
	} else if (is_separator(path[path.len-1])) {
		s = copy_string(a, path);
	} else {
		s = concatenate_strings(a, path, sep);
	}
	isize i;
	for (i = 0; i < s.len; i++) {
		if (is_separator(s.text[i])) {
			s.text[i] = sep.text[0];
		}
	}
	return s;
}


#if defined(GB_SYSTEM_WINDOWS)
	gb_internal int convert_multibyte_to_widechar(char const *multibyte_input, int input_length, wchar_t *output, int output_size) {
		return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, multibyte_input, input_length, output, output_size);
	}
	gb_internal int convert_widechar_to_multibyte(wchar_t const *widechar_input, int input_length, char *output, int output_size) {
		return WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, widechar_input, input_length, output, output_size, nullptr, nullptr);
	}
#elif defined(GB_SYSTEM_UNIX) || defined(GB_SYSTEM_OSX)

	#include <iconv.h>

	gb_internal int convert_multibyte_to_widechar(char const *multibyte_input, usize input_length, wchar_t *output, usize output_size) {
		iconv_t conv = iconv_open("WCHAR_T", "UTF-8");
		size_t result = iconv(conv, cast(char **)&multibyte_input, &input_length, cast(char **)&output, &output_size);
		iconv_close(conv);

		return cast(int)result;
	}

	gb_internal int convert_widechar_to_multibyte(wchar_t const *widechar_input, usize input_length, char* output, usize output_size) {
		iconv_t conv = iconv_open("UTF-8", "WCHAR_T");
		size_t result = iconv(conv, cast(char**) &widechar_input, &input_length, cast(char **)&output, &output_size);
		iconv_close(conv);

		return cast(int)result;
	}
#else
#error Implement system
#endif




// TODO(bill): Make this non-windows specific
gb_internal String16 string_to_string16(gbAllocator a, String s) {
	int len, len1;
	wchar_t *text;

	if (s.len < 1) {
		return make_string16(nullptr, 0);
	}

	len = convert_multibyte_to_widechar(cast(char *)s.text, cast(int)s.len, nullptr, 0);
	if (len == 0) {
		return make_string16(nullptr, 0);
	}

	text = gb_alloc_array(a, wchar_t, len+1);

	len1 = convert_multibyte_to_widechar(cast(char *)s.text, cast(int)s.len, text, cast(int)len);
	if (len1 == 0) {
		gb_free(a, text);
		return make_string16(nullptr, 0);
	}
	text[len] = 0;

	return make_string16(text, len);
}


gb_internal String string16_to_string(gbAllocator a, String16 s) {
	int len, len1;
	u8 *text;

	if (s.len < 1) {
		return make_string(nullptr, 0);
	}

	len = convert_widechar_to_multibyte(s.text, cast(int)s.len, nullptr, 0);
	if (len == 0) {
		return make_string(nullptr, 0);
	}
	len += 1; // NOTE(bill): It needs an extra 1 for some reason

	text = gb_alloc_array(a, u8, len+1);

	len1 = convert_widechar_to_multibyte(s.text, cast(int)s.len, cast(char *)text, cast(int)len);
	if (len1 == 0) {
		gb_free(a, text);
		return make_string(nullptr, 0);
	}
	text[len] = 0;

	return make_string(text, len-1);
}




gb_internal String temporary_directory(gbAllocator allocator) {
#if defined(GB_SYSTEM_WINDOWS)
	DWORD n = GetTempPathW(0, nullptr);
	if (n == 0) {
		return String{0};
	}
	DWORD len = gb_max(MAX_PATH, n);
	wchar_t *b = gb_alloc_array(heap_allocator(), wchar_t, len+1);
	defer (gb_free(heap_allocator(), b));
	n = GetTempPathW(len, b);
	if (n == 3 && b[1] == ':' && b[2] == '\\') {

	} else if (n > 0 && b[n-1] == '\\') {
		n -= 1;
	}
	b[n] = 0;
	String16 s = make_string16(b, n);
	return string16_to_string(allocator, s);
#else
	char const *tmp_env = gb_get_env("TMPDIR", allocator);
	if (tmp_env) {
		return make_string_c(tmp_env);
	}

#if defined(P_tmpdir)
	String tmp_macro = make_string_c(P_tmpdir);
	if (tmp_macro.len != 0) {
		return copy_string(allocator, tmp_macro);
	}
#endif

	return copy_string(allocator, str_lit("/tmp"));
#endif
}



gb_internal bool is_printable(Rune r) {
	if (r <= 0xff) {
		if (0x20 <= r && r <= 0x7e) {
			return true;
		}
		if (0xa1 <= r && r <= 0xff) {
			return r != 0xad;
		}
		return false;
	}
	return false;
}

gb_global char const lower_hex[] = "0123456789abcdef";

gb_internal String quote_to_ascii(gbAllocator a, String str, u8 quote='"') {
	u8 *s = str.text;
	isize n = str.len;
	auto buf = array_make<u8>(a, 0, n);
	array_add(&buf, quote);
	for (isize width = 0; n > 0; s += width, n -= width) {
		Rune r = cast(Rune)s[0];
		width = 1;
		if (r >= 0x80) {
			width = utf8_decode(s, n, &r);
		}
		if (width == 1 && r == GB_RUNE_INVALID) {
			array_add(&buf, cast(u8)'\\');
			array_add(&buf, cast(u8)'x');
			array_add(&buf, cast(u8)lower_hex[s[0]>>4]);
			array_add(&buf, cast(u8)lower_hex[s[0]&0xf]);
			continue;
		}

		if (r == quote || r == '\\') {
			array_add(&buf, cast(u8)'\\');
			array_add(&buf, u8(r));
			continue;
		}
		if (r < 0x80 && is_printable(r)) {
			array_add(&buf, u8(r));
			continue;
		}
		switch (r) {
		case '\a':
		case '\b':
		case '\f':
		case '\n':
		case '\r':
		case '\t':
		case '\v':
		default:
			if (r < ' ') {
				u8 b = cast(u8)r;
				array_add(&buf, cast(u8)'\\');
				array_add(&buf, cast(u8)'x');
				array_add(&buf, cast(u8)lower_hex[b>>4]);
				array_add(&buf, cast(u8)lower_hex[b&0xf]);
			}
			if (r > GB_RUNE_MAX) {
				r = 0XFFFD;
			}
			if (r < 0x10000) {
				array_add(&buf, cast(u8)'\\');
				array_add(&buf, cast(u8)'u');
				for (isize i = 12; i >= 0; i -= 4) {
					array_add(&buf, cast(u8)lower_hex[(r>>i)&0xf]);
				}
			} else {
				array_add(&buf, cast(u8)'\\');
				array_add(&buf, cast(u8)'U');
				for (isize i = 28; i >= 0; i -= 4) {
					array_add(&buf, cast(u8)lower_hex[(r>>i)&0xf]);
				}
			}
		}
	}



	array_add(&buf, quote);
	String res = {};
	res.text = buf.data;
	res.len = buf.count;
	return res;
}




gb_internal bool unquote_char(String s, u8 quote, Rune *rune, bool *multiple_bytes, String *tail_string) {
	u8 c;

	if (s[0] == quote &&
	    (quote == '\'' || quote == '"')) {
		return false;
	} else if (s[0] >= 0x80) {
		Rune r = -1;
		isize size = utf8_decode(s.text, s.len, &r);
		*rune = r;
		if (multiple_bytes) *multiple_bytes = true;
		if (tail_string) *tail_string = make_string(s.text+size, s.len-size);
		return true;
	} else if (s[0] != '\\') {
		*rune = s[0];
		if (tail_string) *tail_string = make_string(s.text+1, s.len-1);
		return true;
	}

	if (s.len <= 1) {
		return false;
	}
	c = s[1];
	s = make_string(s.text+2, s.len-2);

	switch (c) {
	default: return false;

	case 'a':  *rune = '\a'; break;
	case 'b':  *rune = '\b'; break;
	case 'e':  *rune = 0x1b; break;
	case 'f':  *rune = '\f'; break;
	case 'n':  *rune = '\n'; break;
	case 'r':  *rune = '\r'; break;
	case 't':  *rune = '\t'; break;
	case 'v':  *rune = '\v'; break;
	case '\\': *rune = '\\'; break;


	case '\'':
	case '"':
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
		isize i;
		i32 r = gb_digit_to_int(c);
		if (s.len < 2) {
			return false;
		}
		for (i = 0; i < 2; i++) {
			i32 d = gb_digit_to_int(s[i]);
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
		Rune r = 0;
		isize i, count = 0;
		switch (c) {
		case 'x': count = 2; break;
		case 'u': count = 4; break;
		case 'U': count = 8; break;
		}

		if (s.len < count) {
			return false;
		}
		for (i = 0; i < count; i++) {
			i32 d = gb_hex_digit_to_int(s[i]);
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
		if (multiple_bytes) *multiple_bytes = true;
	} break;
	}
	if (tail_string) *tail_string = s;
	return true;
}


gb_internal String strip_carriage_return(gbAllocator a, String s) {
	isize buf_len = s.len;
	u8 *buf = gb_alloc_array(a, u8, buf_len);
	isize i = 0;
	for (isize j = 0; j < s.len; j++) {
		u8 c = s.text[j];

		if (c != '\r') {
			buf[i++] = c;
		}
	}
	return make_string(buf, i);
}


// 0 == failure
// 1 == original memory
// 2 == new allocation
gb_internal i32 unquote_string(gbAllocator a, String *s_, u8 quote=0, bool has_carriage_return=false) {
	String s = *s_;
	isize n = s.len;
	if (quote == 0) {
		if (n < 2) {
			return 0;
		}
		quote = s[0];
		if (quote != s[n-1]) {
			return 0;
		}
		s.text += 1;
		s.len -= 2;
	}

	if (quote == '`') {
		if (string_contains_char(s, '`')) {
			return 0;
		}

		if (has_carriage_return) {
			*s_ = strip_carriage_return(a, s);
			return 2;
		}
		*s_ = s;
		return 1;
	}
	if (quote != '"' && quote != '\'') {
		return 0;
	}

	if (string_contains_char(s, '\n')) {
		return 0;
	}

	if (!string_contains_char(s, '\\') && !string_contains_char(s, quote)) {
		if (quote == '"') {
			*s_ = s;
			return 1;
		} else if (quote == '\'') {
			Rune r = GB_RUNE_INVALID;
			isize size = utf8_decode(s.text, s.len, &r);
			if ((size == s.len) && (r != -1 || size != 1)) {
				*s_ = s;
				return 1;
			}
		}
	}


	{
		u8 rune_temp[4] = {};
		isize buf_len = 3*s.len / 2;
		u8 *buf = gb_alloc_array(a, u8, buf_len);
		isize offset = 0;
		while (s.len > 0) {
			String tail_string = {};
			Rune r = 0;
			bool multiple_bytes = false;
			bool success = unquote_char(s, quote, &r, &multiple_bytes, &tail_string);
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

			if (quote == '\'' && s.len != 0) {
				gb_free(a, buf);
				return 0;
			}
		}
		*s_ = make_string(buf, offset);
	}
	return 2;
}



gb_internal bool string_is_valid_identifier(String str) {
	if (str.len <= 0) return false;

	isize rune_count = 0;

	isize w = 0;
	isize offset = 0;
	while (offset < str.len) {
		Rune r = 0;
		w = utf8_decode(str.text, str.len, &r);
		if (r == GB_RUNE_INVALID) {
			return false;
		}

		if (rune_count == 0) {
			if (!rune_is_letter(r)) {
				return false;
			}
		} else {
			if (!rune_is_letter(r) && !rune_is_digit(r)) {
				return false;
			}
		}
		rune_count += 1;
		offset += w;
	}

	return true;
}
