gb_global gbArena     string_buffer_arena = {};
gb_global gbAllocator string_buffer_allocator = {};
gb_global gbMutex     string_buffer_mutex = {};

void init_string_buffer_memory(void) {
	// NOTE(bill): This should be enough memory for file systems
	gb_arena_init_from_allocator(&string_buffer_arena, heap_allocator(), gb_megabytes(1));
	string_buffer_allocator = gb_arena_allocator(&string_buffer_arena);
	gb_mutex_init(&string_buffer_mutex);
}


// NOTE(bill): Used for UTF-8 strings
struct String {
	u8 *  text;
	isize len;

	// u8 &operator[](isize i) {
	// 	GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
	// 	return text[i];
	// }
	u8 const &operator[](isize i) const {
		GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
		return text[i];
	}
};
// NOTE(bill): used for printf style arguments
#define LIT(x) ((int)(x).len), (x).text
#define STR_LIT(c_str) {cast(u8 *)c_str, gb_size_of(c_str)-1}
#if defined(GB_COMPILER_MSVC) && _MSC_VER < 1700
	#define str_lit(c_str) make_string(cast(u8 *)c_str, gb_size_of(c_str)-1)
#else
	#define str_lit(c_str) String{cast(u8 *)c_str, gb_size_of(c_str)-1}
#endif

// NOTE(bill): String16 is only used for Windows due to its file directories
struct String16 {
	wchar_t *text;
	isize    len;
	wchar_t &operator[](isize i) {
		GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
		return text[i];
	}
	wchar_t const &operator[](isize i) const {
		GB_ASSERT_MSG(0 <= i && i < len, "[%td]", i);
		return text[i];
	}
};


gb_inline String make_string(u8 const *text, isize len) {
	String s;
	s.text = cast(u8 *)text;
	if (len < 0) {
		len = gb_strlen(cast(char const *)text);
	}
	s.len = len;
	return s;
}


gb_inline String16 make_string16(wchar_t const *text, isize len) {
	String16 s;
	s.text = cast(wchar_t *)text;
	s.len = len;
	return s;
}

isize string16_len(wchar_t const *s) {
	if (s == nullptr) {
		return 0;
	}
	wchar_t const *p = s;
	while (*p) {
		p++;
	}
	return p - s;
}


gb_inline String make_string_c(char const *text) {
	return make_string(cast(u8 *)cast(void *)text, gb_strlen(text));
}

gb_inline String16 make_string16_c(wchar_t const *text) {
	return make_string16(text, string16_len(text));
}

String substring(String const &s, isize lo, isize hi) {
	isize max = s.len;
	GB_ASSERT_MSG(lo <= hi && hi <= max, "%td..%td..%td", lo, hi, max);

	return make_string(s.text+lo, hi-lo);
}


char *alloc_cstring(gbAllocator a, String s) {
	char *c_str = gb_alloc_array(a, char, s.len+1);
	gb_memmove(c_str, s.text, s.len);
	c_str[s.len] = '\0';
	return c_str;
}



gb_inline bool str_eq_ignore_case(String const &a, String const &b) {
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

int string_compare(String const &x, String const &y) {
	if (x.len != y.len || x.text != y.text) {
		isize n, fast, offset, curr_block;
		isize *la, *lb;
		isize pos;

		n = gb_min(x.len, y.len);

		fast = n/gb_size_of(isize) + 1;
		offset = (fast-1)*gb_size_of(isize);
		curr_block = 0;
		if (n <= gb_size_of(isize)) {
			fast = 0;
		}

		la = cast(isize *)x.text;
		lb = cast(isize *)y.text;

		for (; curr_block < fast; curr_block++) {
			if (la[curr_block] ^ lb[curr_block]) {
				for (pos = curr_block*gb_size_of(isize); pos < n; pos++) {
					if (x[pos] ^ y[pos]) {
						return cast(int)x[pos] - cast(int)y[pos];
					}
				}
			}
		}

		for (; offset < n; offset++) {
			if (x[offset] ^ y[offset]) {
				return cast(int)x[offset] - cast(int)y[offset];
			}
		}
	}
	return 0;
}

GB_COMPARE_PROC(string_cmp_proc) {
	String x = *(String *)a;
	String y = *(String *)b;
	return string_compare(x, y);
}

gb_inline bool str_eq(String const &a, String const &b) {
	if (a.len != b.len) return false;
	for (isize i = 0; i < a.len; i++) {
		if (a.text[i] != b.text[i]) {
			return false;
		}
	}
	return true;
}
gb_inline bool str_ne(String const &a, String const &b) { return !str_eq(a, b);                }
gb_inline bool str_lt(String const &a, String const &b) { return string_compare(a, b) < 0;     }
gb_inline bool str_gt(String const &a, String const &b) { return string_compare(a, b) > 0;     }
gb_inline bool str_le(String const &a, String const &b) { return string_compare(a, b) <= 0;    }
gb_inline bool str_ge(String const &a, String const &b) { return string_compare(a, b) >= 0;    }

gb_inline bool operator == (String const &a, String const &b) { return str_eq(a, b); }
gb_inline bool operator != (String const &a, String const &b) { return str_ne(a, b); }
gb_inline bool operator <  (String const &a, String const &b) { return str_lt(a, b); }
gb_inline bool operator >  (String const &a, String const &b) { return str_gt(a, b); }
gb_inline bool operator <= (String const &a, String const &b) { return str_le(a, b); }
gb_inline bool operator >= (String const &a, String const &b) { return str_ge(a, b); }

template <isize N> bool operator == (String const &a, char const (&b)[N]) { return str_eq(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> bool operator != (String const &a, char const (&b)[N]) { return str_ne(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> bool operator <  (String const &a, char const (&b)[N]) { return str_lt(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> bool operator >  (String const &a, char const (&b)[N]) { return str_gt(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> bool operator <= (String const &a, char const (&b)[N]) { return str_le(a, make_string(cast(u8 *)b, N-1)); }
template <isize N> bool operator >= (String const &a, char const (&b)[N]) { return str_ge(a, make_string(cast(u8 *)b, N-1)); }



gb_inline bool string_starts_with(String const &s, String const &prefix) {
	if (prefix.len > s.len) {
		return false;
	}

	return substring(s, 0, prefix.len) == prefix;
}

gb_inline bool string_ends_with(String const &s, String const &suffix) {
	if (suffix.len > s.len) {
		return false;
	}

	return substring(s, s.len-suffix.len, s.len) == suffix;
}

gb_inline bool string_starts_with(String const &s, u8 prefix) {
	if (1 > s.len) {
		return false;
	}

	return s[0] == prefix;
}


gb_inline bool string_ends_with(String const &s, u8 suffix) {
	if (1 > s.len) {
		return false;
	}

	return s[s.len-1] == suffix;
}

gb_inline isize string_extension_position(String const &str) {
	isize dot_pos = -1;
	isize i = str.len;
	while (i --> 0) {
		if (str[i] == GB_PATH_SEPARATOR)
			break;
		if (str[i] == '.') {
			dot_pos = i;
			break;
		}
	}

	return dot_pos;
}

String path_extension(String const &str) {
	isize pos = string_extension_position(str);
	if (pos < 0) {
		return make_string(nullptr, 0);
	}
	return substring(str, pos, str.len);
}


String string_trim_whitespace(String str) {
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

bool string_contains_char(String const &s, u8 c) {
	isize i;
	for (i = 0; i < s.len; i++) {
		if (s[i] == c)
			return true;
	}
	return false;
}

String filename_from_path(String s) {
	isize i = string_extension_position(s);
	if (i >= 0) {
		s = substring(s, 0, i);
		return s;
	}
	if (i > 0) {
		isize j = 0;
		for (j = s.len-1; j >= 0; j--) {
			if (s[j] == '/' ||
				s[j] == '\\') {
				break;
			}
		}
		return substring(s, j+1, s.len);
	}
	return make_string(nullptr, 0);
}

String remove_extension_from_path(String const &s) {
	for (isize i = s.len-1; i >= 0; i--) {
		if (s[i] == '.') {
			return substring(s, 0, i);
		}
	}
	return s;
}

String remove_directory_from_path(String const &s) {
	isize len = 0;
	for (isize i = s.len-1; i >= 0; i--) {
		if (s[i] == '/' ||
		    s[i] == '\\') {
			break;
		}
		len += 1;
	}
	return substring(s, s.len-len, s.len);
}

String directory_from_path(String const &s) {
	isize i = s.len-1;
	for (; i >= 0; i--) {
		if (s[i] == '/' ||
		    s[i] == '\\') {
			break;
		}
	}
	return substring(s, 0, i);
}

String concatenate_strings(gbAllocator a, String const &x, String const &y) {
	isize len = x.len+y.len;
	u8 *data = gb_alloc_array(a, u8, len+1);
	gb_memmove(data,       x.text, x.len);
	gb_memmove(data+x.len, y.text, y.len);
	data[len] = 0;
	return make_string(data, len);
}

String string_join_and_quote(gbAllocator a, Array<String> strings) {
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
		s = gb_string_append_fmt(s, "\"%.*s\" ", LIT(strings[i]));
	}

	return make_string(cast(u8 *) s, gb_string_length(s));
}

String copy_string(gbAllocator a, String const &s) {
	u8 *data = gb_alloc_array(a, u8, s.len+1);
	gb_memmove(data, s.text, s.len);
	data[s.len] = 0;
	return make_string(data, s.len);
}




#if defined(GB_SYSTEM_WINDOWS)
	int convert_multibyte_to_widechar(char const *multibyte_input, int input_length, wchar_t *output, int output_size) {
		return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, multibyte_input, input_length, output, output_size);
	}
	int convert_widechar_to_multibyte(wchar_t const *widechar_input, int input_length, char *output, int output_size) {
		return WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, widechar_input, input_length, output, output_size, nullptr, nullptr);
	}
#elif defined(GB_SYSTEM_UNIX) || defined(GB_SYSTEM_OSX)

	#include <iconv.h>

	int convert_multibyte_to_widechar(char const *multibyte_input, usize input_length, wchar_t *output, usize output_size) {
		iconv_t conv = iconv_open("WCHAR_T", "UTF-8");
		size_t result = iconv(conv, cast(char **)&multibyte_input, &input_length, cast(char **)&output, &output_size);
		iconv_close(conv);

		return cast(int)result;
	}

	int convert_widechar_to_multibyte(wchar_t const *widechar_input, usize input_length, char* output, usize output_size) {
		iconv_t conv = iconv_open("UTF-8", "WCHAR_T");
		size_t result = iconv(conv, cast(char**) &widechar_input, &input_length, cast(char **)&output, &output_size);
		iconv_close(conv);

		return cast(int)result;
	}
#else
#error Implement system
#endif




// TODO(bill): Make this non-windows specific
String16 string_to_string16(gbAllocator a, String s) {
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


String string16_to_string(gbAllocator a, String16 s) {
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







bool is_printable(Rune r) {
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

String quote_to_ascii(gbAllocator a, String str, u8 quote='"') {
	u8 *s = str.text;
	isize n = str.len;
	auto buf = array_make<u8>(a, 0, n);
	array_add(&buf, quote);
	for (isize width = 0; n > 0; s += width, n -= width) {
		Rune r = cast(Rune)s[0];
		width = 1;
		if (r >= 0x80) {
			width = gb_utf8_decode(s, n, &r);
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
				u8 b = cast(u8)r;
				array_add(&buf, cast(u8)'\\');
				array_add(&buf, cast(u8)'u');
				for (isize i = 12; i >= 0; i -= 4) {
					array_add(&buf, cast(u8)lower_hex[(r>>i)&0xf]);
				}
			} else {
				u8 b = cast(u8)r;
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




bool unquote_char(String s, u8 quote, Rune *rune, bool *multiple_bytes, String *tail_string) {
	u8 c;

	if (s[0] == quote &&
	    (quote == '\'' || quote == '"')) {
		return false;
	} else if (s[0] >= 0x80) {
		Rune r = -1;
		isize size = gb_utf8_decode(s.text, s.len, &r);
		*rune = r;
		*multiple_bytes = true;
		*tail_string = make_string(s.text+size, s.len-size);
		return true;
	} else if (s[0] != '\\') {
		*rune = s[0];
		*tail_string = make_string(s.text+1, s.len-1);
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
		*multiple_bytes = true;
	} break;
	}
	*tail_string = s;
	return true;
}


// 0 == failure
// 1 == original memory
// 2 == new allocation
i32 unquote_string(gbAllocator a, String *s_, u8 quote=0) {
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
			isize size = gb_utf8_decode(s.text, s.len, &r);
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
