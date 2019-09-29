#pragma warning(push)
#pragma warning(disable: 4245)

extern "C" {
#include "utf8proc/utf8proc.c"
}
#pragma warning(pop)


bool rune_is_letter(Rune r) {
	if (r < 0x80) {
		if (r == '_') {
			return true;
		}
		return gb_char_is_alpha(cast(char)r) != 0;
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

bool rune_is_digit(Rune r) {
	if (r < 0x80) {
		return gb_is_between(r, '0', '9');
	}
	return utf8proc_category(r) == UTF8PROC_CATEGORY_ND;
}

bool rune_is_whitespace(Rune r) {
	switch (r) {
	case ' ':
	case '\t':
	case '\n':
	case '\r':
		return true;
	}
	return false;
}
