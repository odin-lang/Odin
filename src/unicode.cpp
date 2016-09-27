#pragma warning(push)
#pragma warning(disable: 4245)

// #include "utf8proc/utf8proc.h"
#include "utf8proc/utf8proc.c"

#pragma warning(pop)

// TODO(bill): Unicode support
b32 rune_is_letter(Rune r) {
	if ((r < 0x80 && gb_char_is_alpha(cast(char)r)) ||
	    r == '_') {
		return true;
	}
	switch (utf8proc_category(r)) {
	case UTF8PROC_CATEGORY_LU:
	case UTF8PROC_CATEGORY_LL:
	case UTF8PROC_CATEGORY_LT:
	case UTF8PROC_CATEGORY_LM:
	case UTF8PROC_CATEGORY_LO:
		return true;
	}
	return false;
}

b32 rune_is_digit(Rune r) {
	if (r < 0x80 && gb_is_between(r, '0', '9'))
		return true;
	return utf8proc_category(r) == UTF8PROC_CATEGORY_ND;
}

b32 rune_is_whitespace(Rune r) {
	switch (r) {
	case ' ':
	case '\t':
	case '\n':
	case '\r':
		return true;
	}
	return false;
}


b32 is_string_an_identifier(String s) {
	if (s.len < 1) {
		return false;
	}
	isize offset = 0;
	while (offset < s.len) {
		b32 ok = false;
		Rune r = -1;
		isize size = gb_utf8_decode(s.text+offset, s.len-offset, &r);
		if (offset == 0) {
			ok = rune_is_letter(r);
		} else {
			ok = rune_is_letter(r) || rune_is_digit(r);
		}

		if (!ok) {
			return false;
		}
		offset += size;
	}

	return offset == s.len;
}
