package strings

import "core:unicode/utf8"

/*
Ascii_Set is designed to store ASCII characters efficiently as a bit-array
Each bit in the array corresponds to a specific ASCII character, where the value of the bit (0 or 1) 
indicates if the character is present in the set or not.
*/
Ascii_Set :: distinct [8]u32
/*
Creates an Ascii_Set with unique characters from the input string.

Inputs:
- chars: A string containing characters to include in the Ascii_Set.

Returns:
- as: An Ascii_Set with unique characters from the input string.
- ok: false if any character in the input string is not a valid ASCII character.
*/
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
/*
Determines if a given char is contained within an Ascii_Set.

Inputs:
- as: The Ascii_Set to search.
- c: The char to check for in the Ascii_Set.

Returns:
- res: A boolean indicating if the byte is contained in the Ascii_Set (true) or not (false).
*/
ascii_set_contains :: proc(as: Ascii_Set, c: byte) -> (res: bool) #no_bounds_check {
	return as[c>>5] & (1<<(c&31)) != 0
}
