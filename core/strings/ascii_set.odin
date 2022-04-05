//+private
package strings

import "core:unicode/utf8"

Ascii_Set :: distinct [8]u32

// create an ascii set of all unique characters in the string
ascii_set_make :: proc(chars: string) -> (as: Ascii_Set, ok: bool) #no_bounds_check {
	for i in 0..<len(chars) {
		c := chars[i]
		if c >= utf8.RUNE_SELF {
			return
		}
		as[c>>5] |= 1 << uint(c&31)
	}
	ok = true
	return
}

// returns true when the `c` byte is contained in the `as` ascii set
ascii_set_contains :: proc(as: Ascii_Set, c: byte) -> bool #no_bounds_check {
	return as[c>>5] & (1<<(c&31)) != 0
}