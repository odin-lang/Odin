// Procedures to manipulate UTF-8 encoded strings
// Procedures to manipulate UTF-8 encoded strings
package strings

import "core:io"
import "core:mem"
import "core:unicode"
import "core:unicode/utf8"

// Clones a string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to be cloned
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// Returns: A cloned string
clone :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> string {
	c := make([]byte, len(s), allocator, loc)
	copy(c, s)
	return string(c[:len(s)])
}
// Clones a string safely (returns early with an allocation error on failure)
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to be cloned
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// Returns:
// - str: A cloned string
// - err: A mem.Allocator_Error if an error occurs during allocation
clone_safe :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (str: string, err: mem.Allocator_Error) {
	c := make([]byte, len(s), allocator, loc) or_return
	copy(c, s)
	return string(c[:len(s)]), nil
}
// Clones a string and appends a nul byte to make it a cstring
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to be cloned
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// Returns: A cloned cstring with an appended nul byte
clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> cstring {
	c := make([]byte, len(s)+1, allocator, loc)
	copy(c, s)
	c[len(s)] = 0
	return cstring(&c[0])
}
// Transmutes a raw pointer into a string. Non-allocating.
//
// Inputs:
// - ptr: A pointer to the start of the byte sequence
// - len: The length of the byte sequence
//
// NOTE: The created string is only valid as long as the pointer and length are valid.
//
// Returns: A string created from the byte pointer and length
// Transmutes a raw pointer into a string. Non-allocating.
//
// Inputs:
// - ptr: A pointer to the start of the byte sequence
// - len: The length of the byte sequence
//
// NOTE: The created string is only valid as long as the pointer and length are valid.
//
// Returns: A string created from the byte pointer and length
string_from_ptr :: proc(ptr: ^byte, len: int) -> string {
	return transmute(string)mem.Raw_String{ptr, len}
}
// Transmutes a raw pointer (nul-terminated) into a string. Non-allocating. Searches for a nul byte from 0..<len, otherwhise `len` will be the end size
//
// NOTE: The created string is only valid as long as the pointer and length are valid.
//       The string is truncated at the first nul byte encountered.
//
// Inputs:
// - ptr: A pointer to the start of the nul-terminated byte sequence
// - len: The length of the byte sequence
//
// Returns: A string created from the nul-terminated byte pointer and length
// Transmutes a raw pointer (nul-terminated) into a string. Non-allocating. Searches for a nul byte from 0..<len, otherwhise `len` will be the end size
//
// NOTE: The created string is only valid as long as the pointer and length are valid.
//       The string is truncated at the first nul byte encountered.
//
// Inputs:
// - ptr: A pointer to the start of the nul-terminated byte sequence
// - len: The length of the byte sequence
//
// Returns: A string created from the nul-terminated byte pointer and length
string_from_nul_terminated_ptr :: proc(ptr: ^byte, len: int) -> string {
	s := transmute(string)mem.Raw_String{ptr, len}
	s = truncate_to_byte(s, 0)
	return s
}
// Gets the raw byte pointer for the start of a string `str`
//
// Inputs:
// - str: The input string
//
// Returns: A pointer to the start of the string's bytes
// Gets the raw byte pointer for the start of a string `str`
//
// Inputs:
// - str: The input string
//
// Returns: A pointer to the start of the string's bytes
ptr_from_string :: proc(str: string) -> ^byte {
	d := transmute(mem.Raw_String)str
	return d.data
}
// Converts a string `str` to a cstring
//
// Inputs:
// - str: The input string
//
// WARNING: This is unsafe because the original string may not contain a nul byte.
//
// Returns: The converted cstring
// Converts a string `str` to a cstring
//
// Inputs:
// - str: The input string
//
// WARNING: This is unsafe because the original string may not contain a nul byte.
//
// Returns: The converted cstring
unsafe_string_to_cstring :: proc(str: string) -> cstring {
	d := transmute(mem.Raw_String)str
	return cstring(d.data)
}
// Truncates a string `str` at the first occurrence of char/byte `b`
//
// Inputs:
// - str: The input string
// - b: The byte to truncate the string at
//
// NOTE: Failure to find the byte results in returning the entire string.
//
// Returns: The truncated string
// Truncates a string `str` at the first occurrence of char/byte `b`
//
// Inputs:
// - str: The input string
// - b: The byte to truncate the string at
//
// NOTE: Failure to find the byte results in returning the entire string.
//
// Returns: The truncated string
truncate_to_byte :: proc(str: string, b: byte) -> string {
	n := index_byte(str, b)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}
// Truncates a string str at the first occurrence of rune r as a slice of the original, entire string if not found
//
// Inputs:
// - str: The input string
// - r: The rune to truncate the string at
//
// Returns: The truncated string 
// Truncates a string str at the first occurrence of rune r as a slice of the original, entire string if not found
//
// Inputs:
// - str: The input string
// - r: The rune to truncate the string at
//
// Returns: The truncated string 
truncate_to_rune :: proc(str: string, r: rune) -> string {
	n := index_rune(str, r)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}
// Clones a byte array s and appends a nul byte
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The byte array to be cloned
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// Returns: A cloned string from the byte array with a nul byte
clone_from_bytes :: proc(s: []byte, allocator := context.allocator, loc := #caller_location) -> string {
	c := make([]byte, len(s)+1, allocator, loc)
	copy(c, s)
	c[len(s)] = 0
	return string(c[:len(s)])
}
// Clones a cstring s as a string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The cstring to be cloned
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// Returns: A cloned string from the cstring
clone_from_cstring :: proc(s: cstring, allocator := context.allocator, loc := #caller_location) -> string {
	return clone(string(s), allocator, loc)
}
// Clones a string from a byte pointer ptr and a byte length len
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - ptr: A pointer to the start of the byte sequence
// - len: The length of the byte sequence
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// NOTE: Same as `string_from_ptr`, but perform an additional `clone` operation
//
// Returns: A cloned string from the byte pointer and length
clone_from_ptr :: proc(ptr: ^byte, len: int, allocator := context.allocator, loc := #caller_location) -> string {
	s := string_from_ptr(ptr, len)
	return clone(s, allocator, loc)
}
// Overloaded procedure to clone from a string, []byte, cstring or a ^byte + length 
// Overloaded procedure to clone from a string, []byte, cstring or a ^byte + length 
clone_from :: proc{
	clone,
	clone_from_bytes,
	clone_from_cstring,
	clone_from_ptr,
}
// Clones a string from a nul-terminated cstring ptr and a byte length len
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - ptr: A pointer to the start of the nul-terminated cstring
// - len: The byte length of the cstring
// - allocator: (default: context.allocator)
// - loc: The caller location for debugging purposes (default: #caller_location)
//
// NOTE: Truncates at the first nul byte encountered or the byte length.
//
// Returns: A cloned string from the nul-terminated cstring and byte length
clone_from_cstring_bounded :: proc(ptr: cstring, len: int, allocator := context.allocator, loc := #caller_location) -> string {
	s := string_from_ptr((^u8)(ptr), len)
	s = truncate_to_byte(s, 0)
	return clone(s, allocator, loc)
}
// Compares two strings, returning a value representing which one comes first lexicographically.
// -1 for lhs; 1 for rhs, or 0 if they are equal.
//
// Inputs:
// - lhs: First string for comparison
// - rhs: Second string for comparison
//
// Returns: -1 if lhs comes first, 1 if rhs comes first, or 0 if they are equal
// Compares two strings, returning a value representing which one comes first lexicographically.
// -1 for lhs; 1 for rhs, or 0 if they are equal.
//
// Inputs:
// - lhs: First string for comparison
// - rhs: Second string for comparison
//
// Returns: -1 if lhs comes first, 1 if rhs comes first, or 0 if they are equal
compare :: proc(lhs, rhs: string) -> int {
	return mem.compare(transmute([]byte)lhs, transmute([]byte)rhs)
}
// Returns the byte offset of the rune r in the string s, -1 when not found
//
// Inputs:
// - s: The input string
// - r: The rune to search for
//
// Returns: The byte offset of the rune r in the string s, or -1 if not found
// Returns the byte offset of the rune r in the string s, -1 when not found
//
// Inputs:
// - s: The input string
// - r: The rune to search for
//
// Returns: The byte offset of the rune r in the string s, or -1 if not found
contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r {
			return offset
		}
	}
	return -1
}
// Returns true when the string substr is contained inside the string s
//
// Inputs:
// - s: The input string
// - substr: The substring to search for
//
// Usage:
// ```odin
// strings.contains("testing", "test") // -> true
// strings.contains("testing", "ing")  // -> true
// strings.contains("testing", "text") // -> false
// ```
//
// Returns: true if substr is contained inside the string s, false otherwise
contains :: proc(s, substr: string) -> bool {
	return index(s, substr) >= 0
}
// Returns true when the string s contains any of the characters inside the string chars
//
// Inputs:
// - s: The input string
// - chars: The characters to search for
//
// Usage:
// ```odin
// strings.contains_any("test", "test") -> true
// strings.contains_any("test", "ts") -> true
// strings.contains_any("test", "et") -> true
// strings.contains_any("test", "a") -> false
// ```
//
// Returns: True if the string s contains any of the characters in chars, false otherwise
// Returns true when the string s contains any of the characters inside the string chars
//
// Inputs:
// - s: The input string
// - chars: The characters to search for
//
// Usage:
// ```odin
// strings.contains_any("test", "test") -> true
// strings.contains_any("test", "ts") -> true
// strings.contains_any("test", "et") -> true
// strings.contains_any("test", "a") -> false
// ```
//
// Returns: True if the string s contains any of the characters in chars, false otherwise
contains_any :: proc(s, chars: string) -> bool {
	return index_any(s, chars) >= 0
}
// Returns the UTF-8 rune count of the string s
//
// Inputs:
// - s: The input string
//
// Usage:
// ```odin
// strings.rune_count("test")     // -> 4
// strings.rune_count("testö") // -> 5, where len("testö") -> 6
// ```
//
// Returns: The UTF-8 rune count of the string s
// Returns the UTF-8 rune count of the string s
//
// Inputs:
// - s: The input string
//
// Usage:
// ```odin
// strings.rune_count("test")     // -> 4
// strings.rune_count("testö") // -> 5, where len("testö") -> 6
// ```
//
// Returns: The UTF-8 rune count of the string s
rune_count :: proc(s: string) -> int {
	return utf8.rune_count_in_string(s)
}
// Returns whether the strings u and v are the same alpha characters, ignoring different casings
// Works with UTF-8 string content
//
// Inputs:
// - u: The first string for comparison
// - v: The second string for comparison
//
// Usage:
// ```odin
// strings.equal_fold("test", "test") // -> true
// strings.equal_fold("Test", "test") // -> true
// strings.equal_fold("Test", "tEsT") // -> true
// strings.equal_fold("test", "tes")  // -> false
// ```
//
// Returns: True if the strings u and v are the same alpha characters (ignoring case), false 
// Returns whether the strings u and v are the same alpha characters, ignoring different casings
// Works with UTF-8 string content
//
// Inputs:
// - u: The first string for comparison
// - v: The second string for comparison
//
// Usage:
// ```odin
// strings.equal_fold("test", "test") // -> true
// strings.equal_fold("Test", "test") // -> true
// strings.equal_fold("Test", "tEsT") // -> true
// strings.equal_fold("test", "tes")  // -> false
// ```
//
// Returns: True if the strings u and v are the same alpha characters (ignoring case), false 
equal_fold :: proc(u, v: string) -> bool {
	s, t := u, v
	loop: for s != "" && t != "" {
		sr, tr: rune
		if s[0] < utf8.RUNE_SELF {
			sr, s = rune(s[0]), s[1:]
		} else {
			r, size := utf8.decode_rune_in_string(s)
			sr, s = r, s[size:]
		}
		if t[0] < utf8.RUNE_SELF {
			tr, t = rune(t[0]), t[1:]
		} else {
			r, size := utf8.decode_rune_in_string(t)
			tr, t = r, t[size:]
		}

		if tr == sr { // easy case
			continue loop
		}

		if tr < sr {
			tr, sr = sr, tr
		}

		if tr < utf8.RUNE_SELF {
			switch sr {
			case 'A'..='Z':
				if tr == (sr+'a')-'A' {
					continue loop
				}
			}
			return false
		}

		// TODO(bill): Unicode folding

		return false
	}

	return s == t
}
// Returns the prefix length common between strings a and b
//
// Inputs:
// - a: The first input string
// - b: The second input string
//
// Usage:
// ```odin
// strings.prefix_length("testing", "test") // -> 4
// strings.prefix_length("testing", "te")   // -> 2
// strings.prefix_length("telephone", "te") // -> 2
// strings.prefix_length("testing", "est")  // -> 0
// ```
//
// Returns: The prefix length common between strings a and b
// Returns the prefix length common between strings a and b
//
// Inputs:
// - a: The first input string
// - b: The second input string
//
// Usage:
// ```odin
// strings.prefix_length("testing", "test") // -> 4
// strings.prefix_length("testing", "te")   // -> 2
// strings.prefix_length("telephone", "te") // -> 2
// strings.prefix_length("testing", "est")  // -> 0
// ```
//
// Returns: The prefix length common between strings a and b
prefix_length :: proc(a, b: string) -> (n: int) {
	_len := min(len(a), len(b))

	// Scan for matches including partial codepoints.
	#no_bounds_check for n < _len && a[n] == b[n] {
		n += 1
	}

	// Now scan to ignore partial codepoints.
	if n > 0 {
		s := a[:n]
		n = 0
		for {
			r0, w := utf8.decode_rune(s[n:])
			if r0 != utf8.RUNE_ERROR {
				n += w
			} else {
				break
			}
		}
	}
	return
}
// Determines if a string s starts with a given prefix
//
// Usage:
// ```odin
// strings.has_prefix("testing", "test") -> true
// strings.has_prefix("testing", "te") -> true
// strings.has_prefix("telephone", "te") -> true
// strings.has_prefix("testing", "est") -> false
// ```
// Inputs:
// - s: The string to check for the prefix
// - prefix: The prefix to look for
//
// Returns: true if the string s starts with the prefix, otherwise false
// Determines if a string s starts with a given prefix
//
// Usage:
// ```odin
// strings.has_prefix("testing", "test") -> true
// strings.has_prefix("testing", "te") -> true
// strings.has_prefix("telephone", "te") -> true
// strings.has_prefix("testing", "est") -> false
// ```
// Inputs:
// - s: The string to check for the prefix
// - prefix: The prefix to look for
//
// Returns: true if the string s starts with the prefix, otherwise false
has_prefix :: proc(s, prefix: string) -> bool {
	return len(s) >= len(prefix) && s[0:len(prefix)] == prefix
}
// Determines if a string s ends with a given suffix
//
// Usage:
// ```odin
// strings.has_suffix("todo.txt", ".txt") -> true
// strings.has_suffix("todo.doc", ".txt") -> false
// strings.has_suffix("todo.doc.txt", ".txt") -> true
// ```
// Inputs:
// - s: The string to check for the suffix
// - suffix: The suffix to look for
//
// Returns: true if the string s ends with the suffix, otherwise false
// Determines if a string s ends with a given suffix
//
// Usage:
// ```odin
// strings.has_suffix("todo.txt", ".txt") -> true
// strings.has_suffix("todo.doc", ".txt") -> false
// strings.has_suffix("todo.doc.txt", ".txt") -> true
// ```
// Inputs:
// - s: The string to check for the suffix
// - suffix: The suffix to look for
//
// Returns: true if the string s ends with the suffix, otherwise false
has_suffix :: proc(s, suffix: string) -> bool {
	return len(s) >= len(suffix) && s[len(s)-len(suffix):] == suffix
}
// Joins a slice of strings a with a sep string
//
// *Allocates Using Provided Allocator*
//
// Usage:
// ```odin
// a := [?]string { "a", "b", "c" }
// b := strings.join(a[:], " ")   // -> "a b c"
// c := strings.join(a[:], "-")   // -> "a-b-c"
// d := strings.join(a[:], "...") // -> "a...b...c"
// ```
// Inputs:
// - a: A slice of strings to join
// - sep: The separator string
// - allocator: (default is context.allocator)
//
// Returns: A combined string from the slice of strings a separated with the sep string
join :: proc(a: []string, sep: string, allocator := context.allocator) -> string {
	if len(a) == 0 {
		return ""
	}

	n := len(sep) * (len(a) - 1)
	for s in a {
		n += len(s)
	}

	b := make([]byte, n, allocator)
	i := copy(b, a[0])
	for s in a[1:] {
		i += copy(b[i:], sep)
		i += copy(b[i:], s)
	}
	return string(b)
}
// Joins a slice of strings a with a sep string, returns an error on allocation failure
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - a: A slice of strings to join
// - sep: The separator string
// - allocator: (default is context.allocator)
//
// Returns:
// - str: A combined string from the slice of strings a separated with the sep string
// - err: An error if allocation failed, otherwise nil
join_safe :: proc(a: []string, sep: string, allocator := context.allocator) -> (str: string, err: mem.Allocator_Error) {
	if len(a) == 0 {
		return "", nil
	}

	n := len(sep) * (len(a) - 1)
	for s in a {
		n += len(s)
	}

	b := make([]byte, n, allocator) or_return
	i := copy(b, a[0])
	for s in a[1:] {
		i += copy(b[i:], sep)
		i += copy(b[i:], s)
	}
	return string(b), nil
}
// Returns a combined string from the slice of strings `a` without a separator
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - a: A slice of strings to concatenate
// - allocator: An optional custom allocator (default is context.allocator)
//
// Usage:
// ```odin
// a := [?]string { "a", "b", "c" }
// b := strings.concatenate(a[:]) // -> "abc"
// ```
// Returns: The concatenated string
// Returns a combined string from the slice of strings `a` without a separator
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - a: A slice of strings to concatenate
// - allocator: An optional custom allocator (default is context.allocator)
//
// Usage:
// ```odin
// a := [?]string { "a", "b", "c" }
// b := strings.concatenate(a[:]) // -> "abc"
// ```
// Returns: The concatenated string
concatenate :: proc(a: []string, allocator := context.allocator) -> string {
	if len(a) == 0 {
		return ""
	}

	n := 0
	for s in a {
		n += len(s)
	}
	b := make([]byte, n, allocator)
	i := 0
	for s in a {
		i += copy(b[i:], s)
	}
	return string(b)
}
// Returns a combined string from the slice of strings `a` without a separator, or an error if allocation fails
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - a: A slice of strings to concatenate
// - allocator: An optional custom allocator (default is context.allocator)
//
// Returns: The concatenated string, and an error if allocation fails
// Returns a combined string from the slice of strings `a` without a separator, or an error if allocation fails
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - a: A slice of strings to concatenate
// - allocator: An optional custom allocator (default is context.allocator)
//
// Returns: The concatenated string, and an error if allocation fails
concatenate_safe :: proc(a: []string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) {
	if len(a) == 0 {
		return "", nil
	}

	n := 0
	for s in a {
		n += len(s)
	}
	b := make([]byte, n, allocator) or_return
	i := 0
	for s in a {
		i += copy(b[i:], s)
	}
	return string(b), nil
}
// Returns a substring of the input string `s` with the specified rune offset and length
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to cut
// - rune_offset: The starting rune index (default is 0). In runes, not bytes.
// - rune_length: The number of runes to include in the substring (default is 0, which returns the remainder of the string).  In runes, not bytes.
// - allocator: An optional custom allocator (default is context.allocator)
//
// Usage:
// ```odin
// strings.cut("some example text", 0, 4) -> "some"
// strings.cut("some example text", 2, 2) -> "me"
// strings.cut("some example text", 5, 7) -> "example"
// ```
// Returns: The substring
// Returns a substring of the input string `s` with the specified rune offset and length
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to cut
// - rune_offset: The starting rune index (default is 0). In runes, not bytes.
// - rune_length: The number of runes to include in the substring (default is 0, which returns the remainder of the string).  In runes, not bytes.
// - allocator: An optional custom allocator (default is context.allocator)
//
// Usage:
// ```odin
// strings.cut("some example text", 0, 4) -> "some"
// strings.cut("some example text", 2, 2) -> "me"
// strings.cut("some example text", 5, 7) -> "example"
// ```
// Returns: The substring
cut :: proc(s: string, rune_offset := int(0), rune_length := int(0), allocator := context.allocator) -> (res: string) {
	s := s; rune_length := rune_length
	context.allocator = allocator

	// If we signal that we want the entire remainder (length <= 0) *and*
	// the offset is zero, then we can early out by cloning the input
	if rune_offset == 0 && rune_length <= 0 {
		return clone(s)
	}

	// We need to know if we have enough runes to cover offset + length.
	rune_count := utf8.rune_count_in_string(s)

	// We're asking for a substring starting after the end of the input string.
	// That's just an empty string.
	if rune_offset >= rune_count {
		return ""
	}

	// If we don't specify the length of the substring, use the remainder.
	if rune_length <= 0 {
		rune_length = rune_count - rune_offset
	}

	// We don't yet know how many bytes we need exactly.
	// But we do know it's bounded by the number of runes * 4 bytes,
	// and can be no more than the size of the input string.
	bytes_needed := min(rune_length * 4, len(s))
	buf := make([]u8, bytes_needed)

	byte_offset := 0
	for i := 0; i < rune_count; i += 1 {
		_, w := utf8.decode_rune_in_string(s)

		// If the rune is part of the substring, copy it to the output buffer.
		if i >= rune_offset {
			for j := 0; j < w; j += 1 {
				buf[byte_offset+j] = s[j]
			}
			byte_offset += w
		}

		// We're done if we reach the end of the input string, *or*
		// if we've reached a specified length in runes.
		if rune_length > 0 {
			if i == rune_offset + rune_length - 1 { break }
		}
		s = s[w:]
	}
	return string(buf[:byte_offset])
}
// Splits the input string `s` into a slice of substrings separated by the specified `sep` string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split
// - sep: The separator string
// - sep_save: A flag determining if the separator should be saved in the resulting substrings
// - n: The maximum number of substrings to return, returns nil without alloc when n=0
// - allocator: An optional custom allocator (default is context.allocator)
//
// Returns: A slice of substrings
// Splits the input string `s` into a slice of substrings separated by the specified `sep` string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split
// - sep: The separator string
// - sep_save: A flag determining if the separator should be saved in the resulting substrings
// - n: The maximum number of substrings to return, returns nil without alloc when n=0
// - allocator: An optional custom allocator (default is context.allocator)
//
// Returns: A slice of substrings
@private
_split :: proc(s_, sep: string, sep_save, n_: int, allocator := context.allocator) -> []string {
	s, n := s_, n_

	if n == 0 {
		return nil
	}

	if sep == "" {
		l := utf8.rune_count_in_string(s)
		if n < 0 || n > l {
			n = l
		}

		res := make([dynamic]string, n, allocator)
		for i := 0; i < n-1; i += 1 {
			_, w := utf8.decode_rune_in_string(s)
			res[i] = s[:w]
			s = s[w:]
		}
		if n > 0 {
			res[n-1] = s
		}
		return res[:]
	}

	if n < 0 {
		n = count(s, sep) + 1
	}

	res := make([dynamic]string, n, allocator)

	n -= 1

	i := 0
	for ; i < n; i += 1 {
		m := index(s, sep)
		if m < 0 {
			break
		}
		res[i] = s[:m+sep_save]
		s = s[m+len(sep):]
	}
	res[i] = s

	return res[:i+1]
}
// Splits a string into parts based on a separator.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (default is context.allocator).
//
// Usage:
// ```odin
// s := "aaa.bbb.ccc.ddd.eee"    // 5 parts
// ss := strings.split(s, ".")
// fmt.println(ss)               // [aaa, bbb, ccc, ddd, eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string.
// Splits a string into parts based on a separator.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (default is context.allocator).
//
// Usage:
// ```odin
// s := "aaa.bbb.ccc.ddd.eee"    // 5 parts
// ss := strings.split(s, ".")
// fmt.println(ss)               // [aaa, bbb, ccc, ddd, eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string.
split :: proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, -1, allocator)
}
// Splits a string into parts based on a separator. if n < count of seperators, the remainder of the string is returned in the last entry.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// s := "aaa.bbb.ccc.ddd.eee"  // 5 parts present
// ss := strings.split(s, ".") // total of 3 wanted
// fmt.println(ss)             // [aaa, bbb, ccc.ddd.eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string.
// Splits a string into parts based on a separator. if n < count of seperators, the remainder of the string is returned in the last entry.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// s := "aaa.bbb.ccc.ddd.eee"  // 5 parts present
// ss := strings.split(s, ".") // total of 3 wanted
// fmt.println(ss)             // [aaa, bbb, ccc.ddd.eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string.
split_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, n, allocator)
}
// Splits a string into parts after the separator, retaining it in the substrings.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (Optional) The allocator used for allocation (default is context.allocator).
//
// Usage:
// ```odin
// a := "aaa.bbb.ccc.ddd.eee"         // 5 parts
// aa := strings.split_after(a, ".")
// fmt.println(aa)                    // [aaa., bbb., ccc., ddd., eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string after the separator.
// Splits a string into parts after the separator, retaining it in the substrings.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - allocator: (Optional) The allocator used for allocation (default is context.allocator).
//
// Usage:
// ```odin
// a := "aaa.bbb.ccc.ddd.eee"         // 5 parts
// aa := strings.split_after(a, ".")
// fmt.println(aa)                    // [aaa., bbb., ccc., ddd., eee]
// ```
//
// Returns: A slice of strings, each representing a part of the split string after the separator.
split_after :: proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), -1, allocator)
}
// Splits a string into a total of 'n' parts after the separator.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - n: The maximum number of parts to split the string into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "aaa.bbb.ccc.ddd.eee"
// aa := strings.split_after_n(a, ".", 3)
// fmt.println(aa)                         // [aaa., bbb., ccc.ddd.eee]
// ```
//
// Returns: A slice of strings with 'n' parts or fewer if there weren't
// Splits a string into a total of 'n' parts after the separator.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to split.
// - sep: The separator string used to split the input string.
// - n: The maximum number of parts to split the string into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "aaa.bbb.ccc.ddd.eee"
// aa := strings.split_after_n(a, ".", 3)
// fmt.println(aa)                         // [aaa., bbb., ccc.ddd.eee]
// ```
//
// Returns: A slice of strings with 'n' parts or fewer if there weren't
split_after_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), n, allocator)
}
// Searches for the first occurrence of 'sep' in the given string and returns the substring
// up to (but not including) the separator, as well as a boolean indicating success.
//
// *Used Internally - Private Function*
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
// - sep_save: Number of characters from the separator to include in the result.
//
// NOTE: Destructively consumes the string
//
// Returns: A tuple containing the resulting substring and a boolean indicating success.
// Searches for the first occurrence of 'sep' in the given string and returns the substring
// up to (but not including) the separator, as well as a boolean indicating success.
//
// *Used Internally - Private Function*
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
// - sep_save: Number of characters from the separator to include in the result.
//
// NOTE: Destructively consumes the string
//
// Returns: A tuple containing the resulting substring and a boolean indicating success.
@private
_split_iterator :: proc(s: ^string, sep: string, sep_save: int) -> (res: string, ok: bool) {
	// stop once the string is empty or nil
	if s == nil || len(s^) == 0 {
		return
	}

	if sep == "" {
		res = s[:]
		ok = true
		s^ = s[len(s):]
		return
	}

	m := index(s^, sep)
	if m < 0 {
		// not found
		res = s[:]
		ok = res != ""
		s^ = s[len(s):]
	} else {
		res = s[:m+sep_save]
		ok = true
		s^ = s[m+len(sep):]
	}
	return
}
// Splits the input string by the byte separator in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The byte separator to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_by_byte_iterator(&text, '.') {
//     fmt.println(str) // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
// Splits the input string by the byte separator in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The byte separator to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_by_byte_iterator(&text, '.') {
//     fmt.println(str) // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
split_by_byte_iterator :: proc(s: ^string, sep: u8) -> (res: string, ok: bool) {
	m := index_byte(s^, sep)
	if m < 0 {
		// not found
		res = s[:]
		ok = res != ""
		s^ = {}
	} else {
		res = s[:m]
		ok = true
		s^ = s[m+1:]
	}
	return
}
// Splits the input string by the separator string in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_iterator(&text, ".") {
//     fmt.println(str) // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
// Splits the input string by the separator string in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_iterator(&text, ".") {
//     fmt.println(str) // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
split_iterator :: proc(s: ^string, sep: string) -> (string, bool) {
	return _split_iterator(s, sep, 0)
}
// Splits the input string after every separator string in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_after_iterator(&text, ".") {
//     fmt.println(str) // every loop -> a. b. c. d. e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
// Splits the input string after every separator string in an iterator fashion.
// Destructively consumes the original string until the end.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
// - sep: The separator string to search for.
//
// Usage:
// ```odin
// text := "a.b.c.d.e"
// for str in strings.split_after_iterator(&text, ".") {
//     fmt.println(str) // every loop -> a. b. c. d. e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
split_after_iterator :: proc(s: ^string, sep: string) -> (string, bool) {
	return _split_iterator(s, sep, len(sep))
}
// Trims the carriage return character from the end of the input string.
//
// *Used Internally - Private Function*
//
// Inputs:
// - s: The input string to trim.
//
// Returns: The trimmed string as a slice.
// Trims the carriage return character from the end of the input string.
//
// *Used Internally - Private Function*
//
// Inputs:
// - s: The input string to trim.
//
// Returns: The trimmed string as a slice.
@(private)
_trim_cr :: proc(s: string) -> string {
	n := len(s)
	if n > 0 {
		if s[n-1] == '\r' {
			return s[:n-1]
		}
	}
	return s
}
// Splits the input string at every line break '\n'.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines(a)
// fmt.eprintln(b) // [a, b, c, d, e]
// ```
// Returns: An allocated slice of strings split by line breaks.
// Splits the input string at every line break '\n'.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines(a)
// fmt.eprintln(b) // [a, b, c, d, e]
// ```
// Returns: An allocated slice of strings split by line breaks.
split_lines :: proc(s: string, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, 0, -1, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}
// Splits the input string at every line break '\n' for n parts.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - n: The number of parts to split into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_n(a, 3)
// fmt.println(b)                    // [a, b, c, d\ne\n]
// ```
// Returns: An allocated array of strings split by line breaks.
// Splits the input string at every line break '\n' for n parts.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - n: The number of parts to split into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_n(a, 3)
// fmt.println(b)                    // [a, b, c, d\ne\n]
// ```
// Returns: An allocated array of strings split by line breaks.
split_lines_n :: proc(s: string, n: int, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, 0, n, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}
// Splits the input string at every line break '\n' leaving the '\n' in the resulting strings.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_after(a)
// fmt.println(b) // [a\n, b\n, c\n, d\n, e\n]
// ```
// Returns: An allocated slice of strings split by line breaks with line breaks included.
// Splits the input string at every line break '\n' leaving the '\n' in the resulting strings.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_after(a)
// fmt.println(b) // [a\n, b\n, c\n, d\n, e\n]
// ```
// Returns: An allocated slice of strings split by line breaks with line breaks included.
split_lines_after :: proc(s: string, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, len(sep), -1, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}
// Splits the input string at every line break '\n' leaving the '\n' in the resulting strings.
// Only runs for n parts.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - n: The number of parts to split into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_after_n(a, 3)
// fmt.println(b)                          // [a\n, b\n, c\n, d\ne\n]
// ```
// Returns: An allocated slice of strings split by line breaks with line breaks included.
// Splits the input string at every line break '\n' leaving the '\n' in the resulting strings.
// Only runs for n parts.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string to split.
// - n: The number of parts to split into.
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "a\nb\nc\nd\ne"
// b := strings.split_lines_after_n(a, 3)
// fmt.println(b)                          // [a\n, b\n, c\n, d\ne\n]
// ```
// Returns: An allocated slice of strings split by line breaks with line breaks included.
split_lines_after_n :: proc(s: string, n: int, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, len(sep), n, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}
// Splits the input string at every line break '\n'.
// Returns the current split string every iteration until the string is consumed.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
//
// Usage:
// ```odin
// text := "a\nb\nc\nd\ne"
// for str in strings.split_lines_iterator(&text) {
//     fmt.println(str)    // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
// Splits the input string at every line break '\n'.
// Returns the current split string every iteration until the string is consumed.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
//
// Usage:
// ```odin
// text := "a\nb\nc\nd\ne"
// for str in strings.split_lines_iterator(&text) {
//     fmt.println(str)    // every loop -> a b c d e
// }
// ```
// Returns: A tuple containing the resulting substring and a boolean indicating success.
split_lines_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, 0) or_return
	return _trim_cr(line), true
}
// Splits the input string at every line break '\n'.
// Returns the current split string with line breaks included every iteration until the string is consumed.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
//
// Usage:
// ```odin
// text := "a\nb\nc\nd\ne"
// for str in strings.split_lines_after_iterator(&text) {
//     fmt.println(str) // every loop -> a\n b\n c\n d\n e\n
// }
// ```
// Returns: A tuple containing the resulting substring with line breaks included and a boolean indicating success.
// Splits the input string at every line break '\n'.
// Returns the current split string with line breaks included every iteration until the string is consumed.
//
// Inputs:
// - s: Pointer to the input string, which is modified during the search.
//
// Usage:
// ```odin
// text := "a\nb\nc\nd\ne"
// for str in strings.split_lines_after_iterator(&text) {
//     fmt.println(str) // every loop -> a\n b\n c\n d\n e\n
// }
// ```
// Returns: A tuple containing the resulting substring with line breaks included and a boolean indicating success.
split_lines_after_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, len(sep)) or_return
	return _trim_cr(line), true
}
// Returns the byte offset of the first byte c in the string s it finds, -1 when not found.
// NOTE: Can't find UTF-8 based runes.
//
// Inputs:
// - s: The input string to search in.
// - c: The byte to search for.
//
// Usage:
// ```odin
// strings.index_byte("test", 't')       // -> 0
// strings.index_byte("test", 'e')       // -> 1
// strings.index_byte("test", 'x')       // -> -1
// strings.index_byte("teäst", 'ä') // -> -1
// ```
// Returns: The byte offset of the first occurrence of c in s, or -1 if not found.
// Returns the byte offset of the first byte c in the string s it finds, -1 when not found.
// NOTE: Can't find UTF-8 based runes.
//
// Inputs:
// - s: The input string to search in.
// - c: The byte to search for.
//
// Usage:
// ```odin
// strings.index_byte("test", 't')       // -> 0
// strings.index_byte("test", 'e')       // -> 1
// strings.index_byte("test", 'x')       // -> -1
// strings.index_byte("teäst", 'ä') // -> -1
// ```
// Returns: The byte offset of the first occurrence of c in s, or -1 if not found.
index_byte :: proc(s: string, c: byte) -> int {
	for i := 0; i < len(s); i += 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}
// Returns the byte offset of the last byte `c` in the string `s`, -1 when not found.
// NOTE: Can't find UTF-8 based runes.
//
// Usage:
// ```odin
// strings.last_index_byte("test", 't')       // -> 3
// strings.last_index_byte("test", 'e')       // -> 1
// strings.last_index_byte("test", 'x')       // -> -1
// strings.last_index_byte("teäst", 'ä') // -> -1
// ```
// Returns: The byte offset of the last occurrence of `c` in `s`, or -1 if not found.
// Returns the byte offset of the last byte `c` in the string `s`, -1 when not found.
// NOTE: Can't find UTF-8 based runes.
//
// Usage:
// ```odin
// strings.last_index_byte("test", 't')       // -> 3
// strings.last_index_byte("test", 'e')       // -> 1
// strings.last_index_byte("test", 'x')       // -> -1
// strings.last_index_byte("teäst", 'ä') // -> -1
// ```
// Returns: The byte offset of the last occurrence of `c` in `s`, or -1 if not found.
last_index_byte :: proc(s: string, c: byte) -> int {
	for i := len(s)-1; i >= 0; i -= 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}
// Returns the byte offset of the first rune `r` in the string `s` it finds, -1 when not found.
// Invalid runes return -1
//
// Usage:
// ```odin
// strings.index_rune("abcädef", 'x')   // -> -1
// strings.index_rune("abcädef", 'a')   // -> 0
// strings.index_rune("abcädef", 'b')   // -> 1
// strings.index_rune("abcädef", 'c')   // -> 2
// strings.index_rune("abcädef", 'ä') // -> 3
// strings.index_rune("abcädef", 'd')   // -> 5
// strings.index_rune("abcädef", 'e')   // -> 6
// strings.index_rune("abcädef", 'f')   // -> 7
// ```
// Returns: The byte offset of the first occurrence of `r` in `s`, or -1 if not found.
// Returns the byte offset of the first rune `r` in the string `s` it finds, -1 when not found.
// Invalid runes return -1
//
// Usage:
// ```odin
// strings.index_rune("abcädef", 'x')   // -> -1
// strings.index_rune("abcädef", 'a')   // -> 0
// strings.index_rune("abcädef", 'b')   // -> 1
// strings.index_rune("abcädef", 'c')   // -> 2
// strings.index_rune("abcädef", 'ä') // -> 3
// strings.index_rune("abcädef", 'd')   // -> 5
// strings.index_rune("abcädef", 'e')   // -> 6
// strings.index_rune("abcädef", 'f')   // -> 7
// ```
// Returns: The byte offset of the first occurrence of `r` in `s`, or -1 if not found.
index_rune :: proc(s: string, r: rune) -> int {
	switch {
	case u32(r) < utf8.RUNE_SELF:
		return index_byte(s, byte(r))

	case r == utf8.RUNE_ERROR:
		for c, i in s {
			if c == utf8.RUNE_ERROR {
				return i
			}
		}
		return -1

	case !utf8.valid_rune(r):
		return -1
	}

	b, w := utf8.encode_rune(r)
	return index(s, string(b[:w]))
}

@private PRIME_RABIN_KARP :: 16777619
// Returns the byte offset of the string `substr` in the string `s`, -1 when not found.
//
// Usage:
// ```odin
// strings.index("test", "t")  // -> 0
// strings.index("test", "te") // -> 0
// strings.index("test", "st") // -> 2
// strings.index("test", "tt") // -> -1
// ```
// Returns: The byte offset of the first occurrence of `substr` in `s`, or -1 if not found.
// Returns the byte offset of the string `substr` in the string `s`, -1 when not found.
//
// Usage:
// ```odin
// strings.index("test", "t")  // -> 0
// strings.index("test", "te") // -> 0
// strings.index("test", "st") // -> 2
// strings.index("test", "tt") // -> -1
// ```
// Returns: The byte offset of the first occurrence of `substr` in `s`, or -1 if not found.
index :: proc(s, substr: string) -> int {
	hash_str_rabin_karp :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
		for i := 0; i < len(s); i += 1 {
			hash = hash*PRIME_RABIN_KARP + u32(s[i])
		}
		sq := u32(PRIME_RABIN_KARP)
		for i := len(s); i > 0; i >>= 1 {
			if (i & 1) != 0 {
				pow *= sq
			}
			sq *= sq
		}
		return
	}

	n := len(substr)
	switch {
	case n == 0:
		return 0
	case n == 1:
		return index_byte(s, substr[0])
	case n == len(s):
		if s == substr {
			return 0
		}
		return -1
	case n > len(s):
		return -1
	}

	hash, pow := hash_str_rabin_karp(substr)
	h: u32
	for i := 0; i < n; i += 1 {
		h = h*PRIME_RABIN_KARP + u32(s[i])
	}
	if h == hash && s[:n] == substr {
		return 0
	}
	for i := n; i < len(s); /**/ {
		h *= PRIME_RABIN_KARP
		h += u32(s[i])
		h -= pow * u32(s[i-n])
		i += 1
		if h == hash && s[i-n:i] == substr {
			return i - n
		}
	}
	return -1
}
// Returns the last byte offset of the string `substr` in the string `s`, -1 when not found.
//
// Usage:
// ```odin
// strings.last_index("test", "t")  // -> 3
// strings.last_index("test", "te") // -> 0
// strings.last_index("test", "st") // -> 2
// strings.last_index("test", "tt") // -> -1
// ```
// Returns: The byte offset of the last occurrence of `substr` in `s`, or -1 if not found.
// Returns the last byte offset of the string `substr` in the string `s`, -1 when not found.
//
// Usage:
// ```odin
// strings.last_index("test", "t")  // -> 3
// strings.last_index("test", "te") // -> 0
// strings.last_index("test", "st") // -> 2
// strings.last_index("test", "tt") // -> -1
// ```
// Returns: The byte offset of the last occurrence of `substr` in `s`, or -1 if not found.
last_index :: proc(s, substr: string) -> int {
	hash_str_rabin_karp_reverse :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
		for i := len(s) - 1; i >= 0; i -= 1 {
			hash = hash*PRIME_RABIN_KARP + u32(s[i])
		}
		sq := u32(PRIME_RABIN_KARP)
		for i := len(s); i > 0; i >>= 1 {
			if (i & 1) != 0 {
				pow *= sq
			}
			sq *= sq
		}
		return
	}

	n := len(substr)
	switch {
	case n == 0:
		return len(s)
	case n == 1:
		return last_index_byte(s, substr[0])
	case n == len(s):
		return 0 if substr == s else -1
	case n > len(s):
		return -1
	}

	hash, pow := hash_str_rabin_karp_reverse(substr)
	last := len(s) - n
	h: u32
	for i := len(s)-1; i >= last; i -= 1 {
		h = h*PRIME_RABIN_KARP + u32(s[i])
	}
	if h == hash && s[last:] == substr {
		return last
	}

	for i := last-1; i >= 0; i -= 1 {
		h *= PRIME_RABIN_KARP
		h += u32(s[i])
		h -= pow * u32(s[i+n])
		if h == hash && s[i:i+n] == substr {
			return i
		}
	}
	return -1
}
// Returns the index of any first char of `chars` found in `s`, -1 if not found.
//
// Usage:
// ```odin
// strings.index_any("test", "s")   // -> 2
// strings.index_any("test", "se")  // -> 1
// strings.index_any("test", "et")  // -> 0
// strings.index_any("test", "set") // -> 0
// strings.index_any("test", "x")   // -> -1
// ```
// Returns: The index of the first character of `chars` found in `s`, or -1 if not found.
// Returns the index of any first char of `chars` found in `s`, -1 if not found.
//
// Usage:
// ```odin
// strings.index_any("test", "s")   // -> 2
// strings.index_any("test", "se")  // -> 1
// strings.index_any("test", "et")  // -> 0
// strings.index_any("test", "set") // -> 0
// strings.index_any("test", "x")   // -> -1
// ```
// Returns: The index of the first character of `chars` found in `s`, or -1 if not found.
index_any :: proc(s, chars: string) -> int {
	if chars == "" {
		return -1
	}
	
	if len(chars) == 1 {
		r := rune(chars[0])
		if r >= utf8.RUNE_SELF {
			r = utf8.RUNE_ERROR
		}
		return index_rune(s, r)
	}
	
	if len(s) > 8 {
		if as, ok := ascii_set_make(chars); ok {
			for i in 0..<len(s) {
				if ascii_set_contains(as, s[i]) {
					return i
				}
			}
			return -1
		}
	}

	for c, i in s {
		if index_rune(chars, c) >= 0 {
			return i
		}
	}
	return -1
}
// Finds the last occurrence of any character in 'chars' within 's'. Iterates in reverse.
//
// Inputs:
// - s: The string to search in
// - chars: The characters to look for
//
// Usage:
// ```odin
// strings.last_index_any("test", "s")   // -> 2
// strings.last_index_any("test", "se")  // -> 2
// strings.last_index_any("test", "et")  // -> 3
// strings.last_index_any("test", "set") // -> 3
// strings.last_index_any("test", "x")   // -> -1
// ```
// Returns: The index of the last matching character, or -1 if not found
// Finds the last occurrence of any character in 'chars' within 's'. Iterates in reverse.
//
// Inputs:
// - s: The string to search in
// - chars: The characters to look for
//
// Usage:
// ```odin
// strings.last_index_any("test", "s")   // -> 2
// strings.last_index_any("test", "se")  // -> 2
// strings.last_index_any("test", "et")  // -> 3
// strings.last_index_any("test", "set") // -> 3
// strings.last_index_any("test", "x")   // -> -1
// ```
// Returns: The index of the last matching character, or -1 if not found
last_index_any :: proc(s, chars: string) -> int {
	if chars == "" {
		return -1
	}
	
	if len(s) == 1 {
		r := rune(s[0])
		if r >= utf8.RUNE_SELF {
			r = utf8.RUNE_ERROR
		}
		return index_rune(chars, r)
	}
	
	if len(s) > 8 {
		if as, ok := ascii_set_make(chars); ok {
			for i := len(s)-1; i >= 0; i -= 1 {
				if ascii_set_contains(as, s[i]) {
					return i
				}
			}
			return -1
		}
	}
	
	if len(chars) == 1 {
		r := rune(chars[0])
		if r >= utf8.RUNE_SELF {
			r = utf8.RUNE_ERROR
		}
		for i := len(s); i > 0; /**/ {
			c, w := utf8.decode_last_rune_in_string(s[:i])
			i -= w
			if c == r {
				return i
			}
		}
		return -1
	}

	for i := len(s); i > 0; /**/ {
		r, w := utf8.decode_last_rune_in_string(s[:i])
		i -= w
		if index_rune(chars, r) >= 0 {
			return i
		}
	}
	return -1
}
// Finds the first occurrence of any substring in 'substrs' within 's'
//
// Inputs:
// - s: The string to search in
// - substrs: The substrings to look for
//
// Returns: A tuple containing the index of the first matching substring, and its length (width)
// Finds the first occurrence of any substring in 'substrs' within 's'
//
// Inputs:
// - s: The string to search in
// - substrs: The substrings to look for
//
// Returns: A tuple containing the index of the first matching substring, and its length (width)
index_multi :: proc(s: string, substrs: []string) -> (idx: int, width: int) {
	idx = -1
	if s == "" || len(substrs) <= 0 {
		return
	}
	// disallow "" substr
	for substr in substrs {
		if len(substr) == 0 {
			return
		}
	}

	lowest_index := len(s)
	found := false
	for substr in substrs {
		if i := index(s, substr); i >= 0 {
			if i < lowest_index {
				lowest_index = i
				width = len(substr)
				found = true
			}
		}
	}

	if found {
		idx = lowest_index
	}
	return
}
// Counts the number of non-overlapping occurrences of 'substr' in 's'
//
// Inputs:
// - s: The string to search in
// - substr: The substring to count
//
// Usage:
// ```odin
// strings.count("abbccc", "a")  // -> 1
// strings.count("abbccc", "b")  // -> 2
// strings.count("abbccc", "c")  // -> 3
// strings.count("abbccc", "ab") // -> 1
// strings.count("abbccc", " ")  // -> 0
// ```
// Returns: The number of occurrences of 'substr' in 's', returns the rune_count + 1 of the string `s` on empty `substr`
// Counts the number of non-overlapping occurrences of 'substr' in 's'
//
// Inputs:
// - s: The string to search in
// - substr: The substring to count
//
// Usage:
// ```odin
// strings.count("abbccc", "a")  // -> 1
// strings.count("abbccc", "b")  // -> 2
// strings.count("abbccc", "c")  // -> 3
// strings.count("abbccc", "ab") // -> 1
// strings.count("abbccc", " ")  // -> 0
// ```
// Returns: The number of occurrences of 'substr' in 's', returns the rune_count + 1 of the string `s` on empty `substr`
count :: proc(s, substr: string) -> int {
	if len(substr) == 0 { // special case
		return rune_count(s) + 1
	}
	if len(substr) == 1 {
		c := substr[0]
		switch len(s) {
		case 0:
			return 0
		case 1:
			return int(s[0] == c)
		}
		n := 0
		for i := 0; i < len(s); i += 1 {
			if s[i] == c {
				n += 1
			}
		}
		return n
	}

	// TODO(bill): Use a non-brute for approach
	n := 0
	str := s
	for {
		i := index(str, substr)
		if i == -1 {
			return n
		}
		n += 1
		str = str[i+len(substr):]
	}
	return n
}
// Repeats the string 's' 'count' times, concatenating the result
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to repeat
// - count: The number of times to repeat 's'
// - allocator: (default is context.allocator)
//
// WARNING: Panics if count < 0
//
// Usage:
// ```odin
// strings.repeat("abc", 2) // -> "abcabc"
// ```
// Returns: The concatenated repeated string
// Repeats the string 's' 'count' times, concatenating the result
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to repeat
// - count: The number of times to repeat 's'
// - allocator: (default is context.allocator)
//
// WARNING: Panics if count < 0
//
// Usage:
// ```odin
// strings.repeat("abc", 2) // -> "abcabc"
// ```
// Returns: The concatenated repeated string
repeat :: proc(s: string, count: int, allocator := context.allocator) -> string {
	if count < 0 {
		panic("strings: negative repeat count")
	} else if count > 0 && (len(s)*count)/count != len(s) {
		panic("strings: repeat count will cause an overflow")
	}

	b := make([]byte, len(s)*count, allocator)
	i := copy(b, s)
	for i < len(b) { // 2^N trick to reduce the need to copy
		copy(b[i:], b[:i])
		i *= 2
	}
	return string(b)
}
// Replaces all occurrences of 'old' in 's' with 'new'
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to modify
// - old: The substring to replace
// - new: The substring to replace 'old' with
// - allocator: The allocator to use for the new string (default is context.allocator)
//
// Usage:
// ```odin
// strings.replace_all("xyzxyz", "xyz", "abc") // -> "abcabc", true
// strings.replace_all("xyzxyz", "abc", "xyz") // -> "xyzxyz", false
// strings.replace_all("xyzxyz", "xy", "z")    // -> "zzzz", true
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the replacement
// Replaces all occurrences of 'old' in 's' with 'new'
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The string to modify
// - old: The substring to replace
// - new: The substring to replace 'old' with
// - allocator: The allocator to use for the new string (default is context.allocator)
//
// Usage:
// ```odin
// strings.replace_all("xyzxyz", "xyz", "abc") // -> "abcabc", true
// strings.replace_all("xyzxyz", "abc", "xyz") // -> "xyzxyz", false
// strings.replace_all("xyzxyz", "xy", "z")    // -> "zzzz", true
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the replacement
replace_all :: proc(s, old, new: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, old, new, -1, allocator)
}
// Replaces n instances of old in the string s with the new string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - old: The substring to be replaced
// - new: The replacement string
// - n: The number of instances to replace (if n < 0, no limit on the number of replacements)
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.replace("xyzxyz", "xyz", "abc", 2)  // -> "abcabc", true
// strings.replace("xyzxyz", "xyz", "abc", 1)  // -> "abcxyz", true
// strings.replace("xyzxyz", "abc", "xyz", -1) // -> "xyzxyz", false
// strings.replace("xyzxyz", "xy", "z", -1)    // -> "zzzz", true
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the replacement
// Replaces n instances of old in the string s with the new string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - old: The substring to be replaced
// - new: The replacement string
// - n: The number of instances to replace (if n < 0, no limit on the number of replacements)
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.replace("xyzxyz", "xyz", "abc", 2)  // -> "abcabc", true
// strings.replace("xyzxyz", "xyz", "abc", 1)  // -> "abcxyz", true
// strings.replace("xyzxyz", "abc", "xyz", -1) // -> "xyzxyz", false
// strings.replace("xyzxyz", "xy", "z", -1)    // -> "zzzz", true
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the replacement
replace :: proc(s, old, new: string, n: int, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	if old == new || n == 0 {
		was_allocation = false
		output = s
		return
	}
	byte_count := n
	if m := count(s, old); m == 0 {
		was_allocation = false
		output = s
		return
	} else if n < 0 || m < n {
		byte_count = m
	}


	t := make([]byte, len(s) + byte_count*(len(new) - len(old)), allocator)
	was_allocation = true

	w := 0
	start := 0
	for i := 0; i < byte_count; i += 1 {
		j := start
		if len(old) == 0 {
			if i > 0 {
				_, width := utf8.decode_rune_in_string(s[start:])
				j += width
			}
		} else {
			j += index(s[start:], old)
		}
		w += copy(t[w:], s[start:j])
		w += copy(t[w:], new)
		start = j + len(old)
	}
	w += copy(t[w:], s[start:])
	output = string(t[0:w])
	return
}
// Removes the key string n times from the s string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - key: The substring to be removed
// - n: The number of instances to remove (if n < 0, no limit on the number of removes)
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.remove("abcabc", "abc", 1)  // -> "abc", true
// strings.remove("abcabc", "abc", -1) // -> "", true
// strings.remove("abcabc", "a", -1)   // -> "bcbc", true
// strings.remove("abcabc", "x", -1)   // -> "abcabc", false
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the removal
// Removes the key string n times from the s string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - key: The substring to be removed
// - n: The number of instances to remove (if n < 0, no limit on the number of removes)
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.remove("abcabc", "abc", 1)  // -> "abc", true
// strings.remove("abcabc", "abc", -1) // -> "", true
// strings.remove("abcabc", "a", -1)   // -> "bcbc", true
// strings.remove("abcabc", "x", -1)   // -> "abcabc", false
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the removal
remove :: proc(s, key: string, n: int, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, key, "", n, allocator)
}
// Removes all the key string instances from the s string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - key: The substring to be removed
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.remove_all("abcabc", "abc") // -> "", true
// strings.remove_all("abcabc", "a")   // -> "bcbc", true
// strings.remove_all("abcabc", "x")   // -> "abcabc", false
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the removal
// Removes all the key string instances from the s string
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - key: The substring to be removed
// - allocator: (default: context.allocator)
//
// Usage:
// ```odin
// strings.remove_all("abcabc", "abc") // -> "", true
// strings.remove_all("abcabc", "a")   // -> "bcbc", true
// strings.remove_all("abcabc", "x")   // -> "abcabc", false
// ```
// Returns: A tuple containing the modified string and a boolean indicating if an allocation occurred during the removal
remove_all :: proc(s, key: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return remove(s, key, -1, allocator)
}
// Returns true if the r rune is an ASCII space character ('\t', '\n', '\v', '\f', '\r', ' ')
// Returns true if the r rune is an ASCII space character ('\t', '\n', '\v', '\f', '\r', ' ')
@(private) _ascii_space := [256]bool{'\t' = true, '\n' = true, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

// Returns true when the `r` rune is '\t', '\n', '\v', '\f', '\r' or ' '
// Returns true when the `r` rune is '\t', '\n', '\v', '\f', '\r' or ' '
is_ascii_space :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		return _ascii_space[u8(r)]
	}
	return false
}
// Returns true if the r rune is any ASCII or UTF-8 based whitespace character
// Returns true if the r rune is any ASCII or UTF-8 based whitespace character
is_space :: proc(r: rune) -> bool {
	if r < 0x2000 {
		switch r {
		case '\t', '\n', '\v', '\f', '\r', ' ', 0x85, 0xa0, 0x1680:
			return true
		}
	} else {
		if r <= 0x200a {
			return true
		}
		switch r {
		case 0x2028, 0x2029, 0x202f, 0x205f, 0x3000:
			return true
		}
	}
	return false
}
// Returns true if the `r` rune is a null byte (0x0)
// Returns true if the `r` rune is a null byte (0x0)
is_null :: proc(r: rune) -> bool {
	return r == 0x0000
}
// Finds the index of the first rune in the string s for which the procedure p returns the same value as truth
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
// - truth: The boolean value to be matched (default: true)
//
// Usage:
// ```odin
// call :: proc(r: rune) -> bool {
//     return r == 'a'
// }
// strings.index_proc("abcabc", call)        // -> 0
// strings.index_proc("cbacba", call)        // -> 2
// strings.index_proc("cbacba", call, false) // -> 0
// strings.index_proc("abcabc", call, false) // -> 1
// strings.index_proc("xyz", call)           // -> -1
// ```
// Returns: The index of the first matching rune, or -1 if no match was found
// Finds the index of the first rune in the string s for which the procedure p returns the same value as truth
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
// - truth: The boolean value to be matched (default: true)
//
// Usage:
// ```odin
// call :: proc(r: rune) -> bool {
//     return r == 'a'
// }
// strings.index_proc("abcabc", call)        // -> 0
// strings.index_proc("cbacba", call)        // -> 2
// strings.index_proc("cbacba", call, false) // -> 0
// strings.index_proc("abcabc", call, false) // -> 1
// strings.index_proc("xyz", call)           // -> -1
// ```
// Returns: The index of the first matching rune, or -1 if no match was found
index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> int {
	for r, i in s {
		if p(r) == truth {
			return i
		}
	}
	return -1
}
// Same as `index_proc`, but the procedure p takes a raw pointer for state
// Same as `index_proc`, but the procedure p takes a raw pointer for state
index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	for r, i in s {
		if p(state, r) == truth {
			return i
		}
	}
	return -1
}
// Finds the index of the *last* rune in the string s for which the procedure p returns the same value as truth
// Finds the index of the *last* rune in the string s for which the procedure p returns the same value as truth
last_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune_in_string(s[:i])
		i -= size
		if p(r) == truth {
			return i
		}
	}
	return -1
}

// Same as `index_proc_with_state`, runs through the string in reverse
// Same as `index_proc_with_state`, runs through the string in reverse
last_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune_in_string(s[:i])
		i -= size
		if p(state, r) == truth {
			return i
		}
	}
	return -1
}
// Trims the input string s from the left until the procedure p returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
//
// Usage:
// ```odin
// find :: proc(r: rune) -> bool {
//     return r != 'i'
// }
// strings.trim_left_proc("testing", find) // -> "ing"
// ```
// Returns: The trimmed string as a slice of the original
// Trims the input string s from the left until the procedure p returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
//
// Usage:
// ```odin
// find :: proc(r: rune) -> bool {
//     return r != 'i'
// }
// strings.trim_left_proc("testing", find) // -> "ing"
// ```
// Returns: The trimmed string as a slice of the original
trim_left_proc :: proc(s: string, p: proc(rune) -> bool) -> string {
	i := index_proc(s, p, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}
// Trims the input string s from the left until the procedure p with state returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a raw pointer and a rune and returns a boolean
// - state: The raw pointer to be passed to the procedure p
//
// Returns: The trimmed string as a slice of the original
// Trims the input string s from the left until the procedure p with state returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a raw pointer and a rune and returns a boolean
// - state: The raw pointer to be passed to the procedure p
//
// Returns: The trimmed string as a slice of the original
trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> string {
	i := index_proc_with_state(s, p, state, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}
// Trims the input string s from the right until the procedure p returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
//
// Usage:
// ```odin
// find :: proc(r: rune) -> bool {
//     return r != 't'
// }
// strings.trim_right_proc("testing", find) -> "test"
// ```
// Returns: The trimmed string as a slice of the original
// Trims the input string s from the right until the procedure p returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a rune and returns a boolean
//
// Usage:
// ```odin
// find :: proc(r: rune) -> bool {
//     return r != 't'
// }
// strings.trim_right_proc("testing", find) -> "test"
// ```
// Returns: The trimmed string as a slice of the original
trim_right_proc :: proc(s: string, p: proc(rune) -> bool) -> string {
	i := last_index_proc(s, p, false)
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune_in_string(s[i:])
		i += w
	} else {
		i += 1
	}
	return s[0:i]
}
// Trims the input string s from the right until the procedure p with state returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a raw pointer and a rune and returns a boolean
// - state: The raw pointer to be passed to the procedure p
//
// Returns: The trimmed string as a slice of the original, empty when no match
// Trims the input string s from the right until the procedure p with state returns false
//
// Inputs:
// - s: The input string
// - p: A procedure that takes a raw pointer and a rune and returns a boolean
// - state: The raw pointer to be passed to the procedure p
//
// Returns: The trimmed string as a slice of the original, empty when no match
trim_right_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> string {
	i := last_index_proc_with_state(s, p, state, false)
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune_in_string(s[i:])
		i += w
	} else {
		i += 1
	}
	return s[0:i]
}
// Procedure for `trim_*_proc` variants, which has a string rawptr cast + rune comparison
// Procedure for `trim_*_proc` variants, which has a string rawptr cast + rune comparison
is_in_cutset :: proc(state: rawptr, r: rune) -> bool {
	if state == nil {
		return false
	}
	cutset := (^string)(state)^
	for c in cutset {
		if r == c {
			return true
		}
	}
	return false
}
// Trims the cutset string from the s string
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from the left of the input string
//
// Returns: The trimmed string as a slice of the original
// Trims the cutset string from the s string
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from the left of the input string
//
// Returns: The trimmed string as a slice of the original
trim_left :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_left_proc_with_state(s, is_in_cutset, &state)
}
// Trims the cutset string from the s string from the right
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from the right of the input string
//
// Returns: The trimmed string as a slice of the original
// Trims the cutset string from the s string from the right
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from the right of the input string
//
// Returns: The trimmed string as a slice of the original
trim_right :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_right_proc_with_state(s, is_in_cutset, &state)
}
// Trims the cutset string from the s string, both from left and right
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from both sides of the input string
//
// Returns: The trimmed string as a slice of the original
// Trims the cutset string from the s string, both from left and right
//
// Inputs:
// - s: The input string
// - cutset: The set of characters to be trimmed from both sides of the input string
//
// Returns: The trimmed string as a slice of the original
trim :: proc(s: string, cutset: string) -> string {
	return trim_right(trim_left(s, cutset), cutset)
}
// Trims until a valid non-space rune from the left, "\t\txyz\t\t" -> "xyz\t\t"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
// Trims until a valid non-space rune from the left, "\t\txyz\t\t" -> "xyz\t\t"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
trim_left_space :: proc(s: string) -> string {
	return trim_left_proc(s, is_space)
}
// Trims from the right until a valid non-space rune, "\t\txyz\t\t" -> "\t\txyz"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
// Trims from the right until a valid non-space rune, "\t\txyz\t\t" -> "\t\txyz"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
trim_right_space :: proc(s: string) -> string {
	return trim_right_proc(s, is_space)
}
// Trims from both sides until a valid non-space rune, "\t\txyz\t\t" -> "xyz"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
// Trims from both sides until a valid non-space rune, "\t\txyz\t\t" -> "xyz"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
trim_space :: proc(s: string) -> string {
	return trim_right_space(trim_left_space(s))
}
// Trims null runes from the left, "\x00\x00testing\x00\x00" -> "testing\x00\x00"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
// Trims null runes from the left, "\x00\x00testing\x00\x00" -> "testing\x00\x00"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
trim_left_null :: proc(s: string) -> string {
	return trim_left_proc(s, is_null)
}
// Trims null runes from the right, "\x00\x00testing\x00\x00" -> "\x00\x00testing"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
// Trims null runes from the right, "\x00\x00testing\x00\x00" -> "\x00\x00testing"
//
// Inputs:
// - s: The input string
//
// Returns: The trimmed string as a slice of the original
trim_right_null :: proc(s: string) -> string {
	return trim_right_proc(s, is_null)
}
// Trims null runes from both sides, "\x00\x00testing\x00\x00" -> "testing"
//
// Inputs:
// - s: The input string
// Returns: The trimmed string as a slice of the original
// Trims null runes from both sides, "\x00\x00testing\x00\x00" -> "testing"
//
// Inputs:
// - s: The input string
// Returns: The trimmed string as a slice of the original
trim_null :: proc(s: string) -> string {
	return trim_right_null(trim_left_null(s))
}
// Trims a prefix string from the start of the s string and returns the trimmed string
//
// Inputs:
// - s: The input string
// - prefix: The prefix string to be removed
//
// Usage:
// ```odin
// strings.trim_prefix("testing", "test") // -> "ing"
// strings.trim_prefix("testing", "abc")  // -> "testing"
// ```
// Returns: The trimmed string as a slice of original, or the input string if no prefix was found
// Trims a prefix string from the start of the s string and returns the trimmed string
//
// Inputs:
// - s: The input string
// - prefix: The prefix string to be removed
//
// Usage:
// ```odin
// strings.trim_prefix("testing", "test") // -> "ing"
// strings.trim_prefix("testing", "abc")  // -> "testing"
// ```
// Returns: The trimmed string as a slice of original, or the input string if no prefix was found
trim_prefix :: proc(s, prefix: string) -> string {
	if has_prefix(s, prefix) {
		return s[len(prefix):]
	}
	return s
}
// Trims a suffix string from the end of the s string and returns the trimmed string
//
// Inputs:
// - s: The input string
// - suffix: The suffix string to be removed
//
// Usage:
// ```odin
// strings.trim_suffix("todo.txt", ".txt") // -> "todo"
// strings.trim_suffix("todo.doc", ".txt") // -> "todo.doc"
// ```
// Returns: The trimmed string as a slice of original, or the input string if no suffix was found
// Trims a suffix string from the end of the s string and returns the trimmed string
//
// Inputs:
// - s: The input string
// - suffix: The suffix string to be removed
//
// Usage:
// ```odin
// strings.trim_suffix("todo.txt", ".txt") // -> "todo"
// strings.trim_suffix("todo.doc", ".txt") // -> "todo.doc"
// ```
// Returns: The trimmed string as a slice of original, or the input string if no suffix was found
trim_suffix :: proc(s, suffix: string) -> string {
	if has_suffix(s, suffix) {
		return s[:len(s)-len(suffix)]
	}
	return s
}
// Splits the input string s by all possible substrs and returns an allocated array of strings
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - substrs: An array of substrings used for splitting
// - allocator: (default is context.allocator)
//
// NOTE: Allocation occurs for the array, the splits are all slices of the original string.
//
// Usage:
// ```odin
// splits := [?]string { "---", "~~~", ".", "_", "," }
// res := strings.split_multi("testing,this.out_nice---done~~~last", splits[:])
// fmt.println(res) // -> [testing, this, out, nice, done, last]
// ```
// Returns: An array of strings, or nil on empty substring or no matches
// Splits the input string s by all possible substrs and returns an allocated array of strings
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - substrs: An array of substrings used for splitting
// - allocator: (default is context.allocator)
//
// NOTE: Allocation occurs for the array, the splits are all slices of the original string.
//
// Usage:
// ```odin
// splits := [?]string { "---", "~~~", ".", "_", "," }
// res := strings.split_multi("testing,this.out_nice---done~~~last", splits[:])
// fmt.println(res) // -> [testing, this, out, nice, done, last]
// ```
// Returns: An array of strings, or nil on empty substring or no matches
split_multi :: proc(s: string, substrs: []string, allocator := context.allocator) -> []string #no_bounds_check {
	if s == "" || len(substrs) <= 0 {
		return nil
	}

	// disallow "" substr
	for substr in substrs {
		if len(substr) == 0 {
			return nil
		}
	}

	// calculate the needed len of `results`
	n := 1
	for it := s; len(it) > 0; {
		i, w := index_multi(it, substrs)
		if i < 0 {
			break
		}
		n += 1
		it = it[i+w:]
	}

	results := make([dynamic]string, 0, n, allocator)
	{
		it := s
		for len(it) > 0 {
			i, w := index_multi(it, substrs)
			if i < 0 {
				break
			}
			part := it[:i]
			append(&results, part)
			it = it[i+w:]
		}
		append(&results, it)
	}
	assert(len(results) == n)
	return results[:]
}
// Splits the input string s by all possible substrs in an iterator fashion. The full string is returned if no match.
//
// Inputs:
// - it: A pointer to the input string
// - substrs: An array of substrings used for splitting
//
// Usage:
// ```odin
// it := "testing,this.out_nice---done~~~last"
// for str in strings.split_multi_iterate(&it, splits[:]) {
//     fmt.println(str) // every iteration // -> [testing, this, out, nice, done, last]
// }
// ```
// Returns: A tuple containing the split string and a boolean indicating success or failure
// Splits the input string s by all possible substrs in an iterator fashion. The full string is returned if no match.
//
// Inputs:
// - it: A pointer to the input string
// - substrs: An array of substrings used for splitting
//
// Usage:
// ```odin
// it := "testing,this.out_nice---done~~~last"
// for str in strings.split_multi_iterate(&it, splits[:]) {
//     fmt.println(str) // every iteration // -> [testing, this, out, nice, done, last]
// }
// ```
// Returns: A tuple containing the split string and a boolean indicating success or failure
split_multi_iterate :: proc(it: ^string, substrs: []string) -> (res: string, ok: bool) #no_bounds_check {
	if it == nil || len(it) == 0 || len(substrs) <= 0 {
		return
	}

	// disallow "" substr
	for substr in substrs {
		if len(substr) == 0 {
			return
		}
	}

	// calculate the needed len of `results`
	i, w := index_multi(it^, substrs)
	if i >= 0 {
		res = it[:i]
		it^ = it[i+w:]
	} else {
		// last value
		res = it^
		it^ = it[len(it):]
	}
	ok = true
	return
}
// Replaces invalid UTF-8 characters in the input string with a specified replacement string. Adjacent invalid bytes are only replaced once.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - replacement: The string used to replace invalid UTF-8 characters
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// text := "Hello\xC0\x80World"
// result := strings.scrub(text, "?")
// fmt.println(result) // -> "Hello?World"
// ```
// Returns: A new string with invalid UTF-8 characters replaced
// Replaces invalid UTF-8 characters in the input string with a specified replacement string. Adjacent invalid bytes are only replaced once.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - replacement: The string used to replace invalid UTF-8 characters
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// text := "Hello\xC0\x80World"
// result := strings.scrub(text, "?")
// fmt.println(result) // -> "Hello?World"
// ```
// Returns: A new string with invalid UTF-8 characters replaced
scrub :: proc(s: string, replacement: string, allocator := context.allocator) -> string {
	str := s
	b: Builder
	builder_init(&b, 0, len(s), allocator)

	has_error := false
	cursor := 0
	origin := str

	for len(str) > 0 {
		r, w := utf8.decode_rune_in_string(str)

		if r == utf8.RUNE_ERROR {
			if !has_error {
				has_error = true
				write_string(&b, origin[:cursor])
			}
		} else if has_error {
			has_error = false
			write_string(&b, replacement)

			origin = origin[cursor:]
			cursor = 0
		}

		cursor += w
		str = str[w:]
	}

	return to_string(b)
}
// Reverses the input string s
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "abcxyz"
// b := strings.reverse(a)
// fmt.println(a, b) // -> abcxyz zyxcba
// ```
// Returns: A reversed version of the input string
// Reverses the input string s
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// a := "abcxyz"
// b := strings.reverse(a)
// fmt.println(a, b) // -> abcxyz zyxcba
// ```
// Returns: A reversed version of the input string
reverse :: proc(s: string, allocator := context.allocator) -> string {
	str := s
	n := len(str)
	buf := make([]byte, n)
	i := n

	for len(str) > 0 {
		_, w := utf8.decode_rune_in_string(str)
		i -= w
		copy(buf[i:], str[:w])
		str = str[w:]
	}
	return string(buf)
}
// Expands the input string by replacing tab characters with spaces to align to a specified tab size
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - tab_size: The number of spaces to use for each tab character
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// text := "abc1\tabc2\tabc3"
// result := strings.expand_tabs(text, 4)
// fmt.println(result) // -> "abc1    abc2    abc3"
// ```
// WARNING: Panics if tab_size <= 0
//
// Returns: A new string with tab characters expanded to the specified tab size
// Expands the input string by replacing tab characters with spaces to align to a specified tab size
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - tab_size: The number of spaces to use for each tab character
// - allocator: (default is context.allocator)
//
// Usage:
// ```odin
// text := "abc1\tabc2\tabc3"
// result := strings.expand_tabs(text, 4)
// fmt.println(result) // -> "abc1    abc2    abc3"
// ```
// WARNING: Panics if tab_size <= 0
//
// Returns: A new string with tab characters expanded to the specified tab size
expand_tabs :: proc(s: string, tab_size: int, allocator := context.allocator) -> string {
	if tab_size <= 0 {
		panic("tab size must be positive")
	}

	if s == "" {
		return ""
	}

	b: Builder
	builder_init(&b, allocator)
	writer := to_writer(&b)
	str := s
	column: int

	for len(str) > 0 {
		r, w := utf8.decode_rune_in_string(str)

		if r == '\t' {
			expand := tab_size - column%tab_size

			for i := 0; i < expand; i += 1 {
				io.write_byte(writer, ' ')
			}

			column += expand
		} else {
			if r == '\n' {
				column = 0
			} else {
				column += w
			}

			io.write_rune(writer, r)
		}

		str = str[w:]
	}

	return to_string(b)
}
// Splits the input string str by the separator sep string and returns 3 parts. The values are slices of the original string.
//
// Inputs:
// - str: The input string
// - sep: The separator string
//
// Usage:
// ```odin
// text := "testing this out"
// strings.partition(text, " this ") // -> head: "testing", match: " this ", tail: "out"
// strings.partition(text, "hi")     // -> head: "testing t", match: "hi", tail: "s out"
// strings.partition(text, "xyz")    // -> head: "testing this out", match: "", tail: ""
// ```
// Returns: A tuple with head (before the split), match (the separator), and tail (the end of the split) strings
// Splits the input string str by the separator sep string and returns 3 parts. The values are slices of the original string.
//
// Inputs:
// - str: The input string
// - sep: The separator string
//
// Usage:
// ```odin
// text := "testing this out"
// strings.partition(text, " this ") // -> head: "testing", match: " this ", tail: "out"
// strings.partition(text, "hi")     // -> head: "testing t", match: "hi", tail: "s out"
// strings.partition(text, "xyz")    // -> head: "testing this out", match: "", tail: ""
// ```
// Returns: A tuple with head (before the split), match (the separator), and tail (the end of the split) strings
partition :: proc(str, sep: string) -> (head, match, tail: string) {
	i := index(str, sep)
	if i == -1 {
		head = str
		return
	}

	head = str[:i]
	match = str[i:i+len(sep)]
	tail = str[i+len(sep):]
	return
}
// Alias for centre_justify
// Alias for centre_justify
center_justify :: centre_justify // NOTE(bill): Because Americans exist
// Centers the input string within a field of specified length by adding pad string on both sides, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the centered string
// - pad: The string used for padding on both sides
// - allocator: (default is context.allocator)
//
// Returns: A new string centered within a field of the specified length
// Centers the input string within a field of specified length by adding pad string on both sides, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the centered string
// - pad: The string used for padding on both sides
// - allocator: (default is context.allocator)
//
// Returns: A new string centered within a field of the specified length
centre_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, allocator)
	builder_grow(&b, len(str) + (remains/pad_len + 1)*len(pad))

	w := to_writer(&b)

	write_pad_string(w, pad, pad_len, remains/2)
	io.write_string(w, str)
	write_pad_string(w, pad, pad_len, (remains+1)/2)

	return to_string(b)
}
// Left-justifies the input string within a field of specified length by adding pad string on the right side, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the left-justified string
// - pad: The string used for padding on the right side
// - allocator: (default is context.allocator)
//
// Returns: A new string left-justified within a field of the specified length
// Left-justifies the input string within a field of specified length by adding pad string on the right side, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the left-justified string
// - pad: The string used for padding on the right side
// - allocator: (default is context.allocator)
//
// Returns: A new string left-justified within a field of the specified length
left_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, allocator)
	builder_grow(&b, len(str) + (remains/pad_len + 1)*len(pad))

	w := to_writer(&b)

	io.write_string(w, str)
	write_pad_string(w, pad, pad_len, remains)

	return to_string(b)
}
// Right-justifies the input string within a field of specified length by adding pad string on the left side, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the right-justified string
// - pad: The string used for padding on the left side
// - allocator: (default is context.allocator)
//
// Returns: A new string right-justified within a field of the specified length
// Right-justifies the input string within a field of specified length by adding pad string on the left side, if its length is less than the target length.
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - str: The input string
// - length: The desired length of the right-justified string
// - pad: The string used for padding on the left side
// - allocator: (default is context.allocator)
//
// Returns: A new string right-justified within a field of the specified length
right_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, allocator)
	builder_grow(&b, len(str) + (remains/pad_len + 1)*len(pad))

	w := to_writer(&b)

	write_pad_string(w, pad, pad_len, remains)
	io.write_string(w, str)

	return to_string(b)
}
// Writes a given pad string a specified number of times to an io.Writer
//
// Inputs:
// - w: The io.Writer to write the pad string to
// - pad: The pad string to be written
// - pad_len: The length of the pad string
// - remains: The number of times to write the pad string
// Writes a given pad string a specified number of times to an io.Writer
//
// Inputs:
// - w: The io.Writer to write the pad string to
// - pad: The pad string to be written
// - pad_len: The length of the pad string
// - remains: The number of times to write the pad string
@private
write_pad_string :: proc(w: io.Writer, pad: string, pad_len, remains: int) {
	repeats := remains / pad_len

	for i := 0; i < repeats; i += 1 {
		io.write_string(w, pad)
	}

	n := remains % pad_len
	p := pad

	for i := 0; i < n; i += 1 {
		r, width := utf8.decode_rune_in_string(p)
		io.write_rune(w, r)
		p = p[width:]
	}
}
// Splits a string into a slice of substrings at each instance of one or more consecutive white space characters, as defined by unicode.is_space
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - allocator: (default is context.allocator)
//
// Returns: A slice of substrings of the input string, or an empty slice if the input string only contains white space
// Splits a string into a slice of substrings at each instance of one or more consecutive white space characters, as defined by unicode.is_space
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - allocator: (default is context.allocator)
//
// Returns: A slice of substrings of the input string, or an empty slice if the input string only contains white space
fields :: proc(s: string, allocator := context.allocator) -> []string #no_bounds_check {
	n := 0
	was_space := 1
	set_bits := u8(0)

	// check to see
	for i in 0..<len(s) {
		r := s[i]
		set_bits |= r
		is_space := int(_ascii_space[r])
		n += was_space & ~is_space
		was_space = is_space
	}

	if set_bits >= utf8.RUNE_SELF {
		return fields_proc(s, unicode.is_space, allocator)
	}

	if n == 0 {
		return nil
	}

	a := make([]string, n, allocator)
	na := 0
	field_start := 0
	i := 0
	for i < len(s) && _ascii_space[s[i]] {
		i += 1
	}
	field_start = i
	for i < len(s) {
		if !_ascii_space[s[i]] {
			i += 1
			continue
		}
		a[na] = s[field_start : i]
		na += 1
		i += 1
		for i < len(s) && _ascii_space[s[i]] {
			i += 1
		}
		field_start = i
	}
	if field_start < len(s) {
		a[na] = s[field_start:]
	}
	return a
}
// Splits a string into a slice of substrings at each run of unicode code points `ch` satisfying the predicate f(ch)
// Splits a string into a slice of substrings at each run of unicode code points `ch` satisfying the predicate f(ch)
//
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - f: A predicate function to determine the split points
// - allocator: (default is context.allocator)
//
// NOTE: fields_proc makes no guarantee about the order in which it calls f(ch), it assumes that `f` always returns the same value for a given ch
//
// Returns: A slice of substrings of the input string, or an empty slice if all code points in the input string satisfy the predicate or if the input string is empty
// *Allocates Using Provided Allocator*
//
// Inputs:
// - s: The input string
// - f: A predicate function to determine the split points
// - allocator: (default is context.allocator)
//
// NOTE: fields_proc makes no guarantee about the order in which it calls f(ch), it assumes that `f` always returns the same value for a given ch
//
// Returns: A slice of substrings of the input string, or an empty slice if all code points in the input string satisfy the predicate or if the input string is empty
fields_proc :: proc(s: string, f: proc(rune) -> bool, allocator := context.allocator) -> []string #no_bounds_check {
	substrings := make([dynamic]string, 0, 32, allocator)

	start, end := -1, -1
	for r, offset in s {
		end = offset
		if f(r) {
			if start >= 0 {
				append(&substrings, s[start : end])
				// -1 could be used, but just speed it up through bitwise not
				// gotta love 2's complement
				start = ~start
			}
		} else {
			if start < 0 {
				start = end
			}
		}
	}

	if start >= 0 {
		append(&substrings, s[start : len(s)])
	}

	return substrings[:]
}
// Retrieves the first non-space substring from a mutable string reference and advances the reference. s is advanced from any space after the substring, or be an empty string if the substring was the remaining characters
//
// Inputs:
// - s: A mutable string reference to be iterated
//
// Returns:
// - field: The first non-space substring found
// - ok: A boolean indicating if a non-space substring was found
// Retrieves the first non-space substring from a mutable string reference and advances the reference. s is advanced from any space after the substring, or be an empty string if the substring was the remaining characters
//
// Inputs:
// - s: A mutable string reference to be iterated
//
// Returns:
// - field: The first non-space substring found
// - ok: A boolean indicating if a non-space substring was found
fields_iterator :: proc(s: ^string) -> (field: string, ok: bool) {
	start, end := -1, -1
	for r, offset in s {
		end = offset
		if unicode.is_space(r) {
			if start >= 0 {
				field = s[start : end]
				ok = true
				s^ = s[end:]
				return
			}
		} else {
			if start < 0 {
				start = end
			}
		}
	}

	// if either of these are true, the string did not contain any characters
	if end < 0 || start < 0 {
		return "", false
	}

	field = s[start:]
	ok = true
	s^ = s[len(s):]
	return
}
// Computes the Levenshtein edit distance between two strings
//
// *Allocates Using Provided Allocator (deletion occurs internal to proc)*
//
// NOTE: Does not perform internal allocation if Length of String b in Runes is Smaller Than 64
//
// Inputs:
// - a, b: The two strings to compare
// - allocator: (default is context.allocator)
//
// Returns: The Levenshtein edit distance between the two strings
//
// NOTE: This implementation is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
// Computes the Levenshtein edit distance between two strings
//
// *Allocates Using Provided Allocator (deletion occurs internal to proc)*
//
// NOTE: Does not perform internal allocation if Length of String b in Runes is Smaller Than 64
//
// Inputs:
// - a, b: The two strings to compare
// - allocator: (default is context.allocator)
//
// Returns: The Levenshtein edit distance between the two strings
//
// NOTE: This implementation is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
levenshtein_distance :: proc(a, b: string, allocator := context.allocator) -> int {
	LEVENSHTEIN_DEFAULT_COSTS: []int : {
		0,   1,   2,   3,   4,   5,   6,   7,   8,   9,
		10,  11,  12,  13,  14,  15,  16,  17,  18,  19,
		20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
		30,  31,  32,  33,  34,  35,  36,  37,  38,  39,
		40,  41,  42,  43,  44,  45,  46,  47,  48,  49,
		50,  51,  52,  53,  54,  55,  56,  57,  58,  59,
		60,  61,  62,  63,
	}

	m, n := utf8.rune_count_in_string(a), utf8.rune_count_in_string(b)

	if m == 0 {
		return n
	}
	if n == 0 {
		return m
	}

	costs: []int

	if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
		costs = make([]int, n + 1, allocator)
		for k in 0..=n {
			costs[k] = k
		}
	} else {
		costs = LEVENSHTEIN_DEFAULT_COSTS
	}

	defer if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
		delete(costs, allocator)
	}

	i: int
	for c1 in a {
		costs[0] = i + 1
		corner := i
		j: int
		for c2 in b {
			upper := costs[j + 1]
			if c1 == c2 {
				costs[j + 1] = corner
			} else {
				t := upper if upper < corner else corner
				costs[j + 1] = (costs[j] if costs[j] < t else t) + 1
			}

			corner = upper
			j += 1
		}

		i += 1
	}

	return costs[n]
}
