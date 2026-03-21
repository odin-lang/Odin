package odin_libc

@(require, linkage="strong", link_name="isdigit")
isdigit :: proc "c" (c: i32) -> b32 {
	switch c {
	case '0'..='9': return true
	case:           return false
	}
}

@(require, linkage="strong", link_name="isblank")
isblank :: proc "c" (c: i32) -> b32 {
	switch c {
	case '\t', ' ': return true
	case:           return false
	}
}

@(require, linkage="strong", link_name="isspace")
isspace :: proc "c" (c: i32) -> b32 {
	switch c {
	case '\t', ' ', '\n', '\v', '\f', '\r': return true
	case:                                   return false
	}
}

@(require, linkage="strong", link_name="toupper")
toupper :: proc "c" (c: i32) -> i32 {
	if c >= 'a' && c <= 'z' {
		return c - ('a' - 'A')
	}
	return c
}
