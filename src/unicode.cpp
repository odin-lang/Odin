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
		return ((cast(u32)r | 0x20) - 0x61) < 26;
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
		return (cast(u32)r - '0') < 10;
	}
	return utf8proc_category(r) == UTF8PROC_CATEGORY_ND;
}

bool rune_is_letter_or_digit(Rune r) {
	if (r < 0x80) {
		if (r == '_') {
			return true;
		}
		if (((cast(u32)r | 0x20) - 0x61) < 26) {
			return true;
		}
		return (cast(u32)r - '0') < 10;
	}
	switch (utf8proc_category(r)) {
	case UTF8PROC_CATEGORY_LU:
	case UTF8PROC_CATEGORY_LL:
	case UTF8PROC_CATEGORY_LT:
	case UTF8PROC_CATEGORY_LM:
	case UTF8PROC_CATEGORY_LO:
		return true;
	case UTF8PROC_CATEGORY_ND:
		return true;
	}
	return false;
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
