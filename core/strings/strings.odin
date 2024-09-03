// Procedures to manipulate UTF-8 encoded strings
package strings

import "base:intrinsics"
import "core:bytes"
import "core:io"
import "core:mem"
import "core:unicode"
import "core:unicode/utf8"

/*
Clones a string

*Allocates Using Provided Allocator*

Inputs:
- s: The string to be cloned
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The cloned string
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	c := make([]byte, len(s), allocator, loc) or_return
	copy(c, s)
	return string(c[:len(s)]), nil
}
/*
Clones a string safely (returns early with an allocation error on failure)

*Allocates Using Provided Allocator*

Inputs:
- s: The string to be cloned
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The cloned string
- err: An allocator error if one occured, `nil` otherwise
*/
@(deprecated="Prefer clone. It now returns an optional allocator error")
clone_safe :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
	return clone(s, allocator, loc)
}
/*
Clones a string and appends a null-byte to make it a cstring

*Allocates Using Provided Allocator*

Inputs:
- s: The string to be cloned
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: A cloned cstring with an appended null-byte
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: cstring, err: mem.Allocator_Error) #optional_allocator_error {
	c := make([]byte, len(s)+1, allocator, loc) or_return
	copy(c, s)
	c[len(s)] = 0
	return cstring(&c[0]), nil
}
/*
Transmutes a raw pointer into a string. Non-allocating.

Inputs:
- ptr: A pointer to the start of the byte sequence
- len: The length of the byte sequence

NOTE: The created string is only valid as long as the pointer and length are valid.

Returns:
- res: A string created from the byte pointer and length
*/
string_from_ptr :: proc(ptr: ^byte, len: int) -> (res: string) {
	return transmute(string)mem.Raw_String{ptr, len}
}
/*
Transmutes a raw pointer (null-terminated) into a string. Non-allocating. Searches for a null-byte from `0..<len`, otherwise `len` will be the end size

NOTE: The created string is only valid as long as the pointer and length are valid.
	  The string is truncated at the first null-byte encountered.

Inputs:
- ptr: A pointer to the start of the null-terminated byte sequence
- len: The length of the byte sequence

Returns:
- res: A string created from the null-terminated byte pointer and length
*/
string_from_null_terminated_ptr :: proc(ptr: [^]byte, len: int) -> (res: string) {
	s := string(ptr[:len])
	s = truncate_to_byte(s, 0)
	return s
}
/*
Gets the raw byte pointer for the start of a string `str`

Inputs:
- str: The input string

Returns:
- res: A pointer to the start of the string's bytes
*/
@(deprecated="Prefer the builtin raw_data.")
ptr_from_string :: proc(str: string) -> (res: ^byte) {
	d := transmute(mem.Raw_String)str
	return d.data
}
/*
Converts a string `str` to a cstring

Inputs:
- str: The input string

WARNING: This is unsafe because the original string may not contain a null-byte.

Returns:
- res: The converted cstring
*/
unsafe_string_to_cstring :: proc(str: string) -> (res: cstring) {
	d := transmute(mem.Raw_String)str
	return cstring(d.data)
}
/*
Truncates a string `str` at the first occurrence of char/byte `b`

Inputs:
- str: The input string
- b: The byte to truncate the string at

NOTE: Failure to find the byte results in returning the entire string.

Returns:
- res: The truncated string
*/
truncate_to_byte :: proc(str: string, b: byte) -> (res: string) {
	n := index_byte(str, b)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}
/*
Truncates a string `str` at the first occurrence of rune `r` as a slice of the original, entire string if not found

Inputs:
- str: The input string
- r: The rune to truncate the string at

Returns:
- res: The truncated string
*/
truncate_to_rune :: proc(str: string, r: rune) -> (res: string) {
	n := index_rune(str, r)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}
/*
Clones a byte array `s` and appends a null-byte

*Allocates Using Provided Allocator*

Inputs:
- s: The byte array to be cloned
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The cloned string from the byte array with a null-byte
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone_from_bytes :: proc(s: []byte, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	c := make([]byte, len(s)+1, allocator, loc) or_return
	copy(c, s)
	c[len(s)] = 0
	return string(c[:len(s)]), nil
}
/*
Clones a cstring `s` as a string

*Allocates Using Provided Allocator*

Inputs:
- s: The cstring to be cloned
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The cloned string from the cstring
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone_from_cstring :: proc(s: cstring, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	return clone(string(s), allocator, loc)
}
/*
Clones a string from a byte pointer `ptr` and a byte length `len`

*Allocates Using Provided Allocator*

Inputs:
- ptr: A pointer to the start of the byte sequence
- len: The length of the byte sequence
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

NOTE: Same as `string_from_ptr`, but perform an additional `clone` operation

Returns:
- res: The cloned string from the byte pointer and length
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone_from_ptr :: proc(ptr: ^byte, len: int, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	s := string_from_ptr(ptr, len)
	return clone(s, allocator, loc)
}
// Overloaded procedure to clone from a string, `[]byte`, `cstring` or a `^byte` + length
clone_from :: proc{
	clone,
	clone_from_bytes,
	clone_from_cstring,
	clone_from_ptr,
}
/*
Clones a string from a null-terminated cstring `ptr` and a byte length `len`

*Allocates Using Provided Allocator*

Inputs:
- ptr: A pointer to the start of the null-terminated cstring
- len: The byte length of the cstring
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

NOTE: Truncates at the first null-byte encountered or the byte length.

Returns:
- res: The cloned string from the null-terminated cstring and byte length
- err: An optional allocator error if one occured, `nil` otherwise
*/
clone_from_cstring_bounded :: proc(ptr: cstring, len: int, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	s := string_from_ptr((^u8)(ptr), len)
	s = truncate_to_byte(s, 0)
	return clone(s, allocator, loc)
}
/*
Compares two strings, returning a value representing which one comes first lexicographically.
-1 for `lhs`; 1 for `rhs`, or 0 if they are equal.

Inputs:
- lhs: First string for comparison
- rhs: Second string for comparison

Returns:
- result: `-1` if `lhs` comes first, `1` if `rhs` comes first, or `0` if they are equal
*/
compare :: proc(lhs, rhs: string) -> (result: int) {
	return mem.compare(transmute([]byte)lhs, transmute([]byte)rhs)
}
/*
Checks if rune `r` in the string `s`

Inputs:
- s: The input string
- r: The rune to search for

Returns:
- result: `true` if the rune `r` in the string `s`, `false` otherwise
*/
contains_rune :: proc(s: string, r: rune) -> (result: bool) {
	for c in s {
		if c == r {
			return true
		}
	}
	return false
}
/*
Returns true when the string `substr` is contained inside the string `s`

Inputs:
- s: The input string
- substr: The substring to search for

Returns:
- res: `true` if `substr` is contained inside the string `s`, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	contains_example :: proc() {
		fmt.println(strings.contains("testing", "test"))
		fmt.println(strings.contains("testing", "ing"))
		fmt.println(strings.contains("testing", "text"))
	}

Output:

	true
	true
	false

*/
contains :: proc(s, substr: string) -> (res: bool) {
	return index(s, substr) >= 0
}
/*
Returns `true` when the string `s` contains any of the characters inside the string `chars`

Inputs:
- s: The input string
- chars: The characters to search for

Returns:
- res: `true` if the string `s` contains any of the characters in `chars`, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	contains_any_example :: proc() {
		fmt.println(strings.contains_any("test", "test"))
		fmt.println(strings.contains_any("test", "ts"))
		fmt.println(strings.contains_any("test", "et"))
		fmt.println(strings.contains_any("test", "a"))
	}

Output:

	true
	true
	true
	false

*/
contains_any :: proc(s, chars: string) -> (res: bool) {
	return index_any(s, chars) >= 0
}


contains_space :: proc(s: string) -> (res: bool) {
	for c in s {
		if is_space(c) {
			return true
		}
	}
	return false
}

/*
Returns the UTF-8 rune count of the string `s`

Inputs:
- s: The input string

Returns:
- res: The UTF-8 rune count of the string `s`

Example:

	import "core:fmt"
	import "core:strings"

	rune_count_example :: proc() {
		fmt.println(strings.rune_count("test"))
		fmt.println(strings.rune_count("testö")) // where len("testö") == 6
	}

Output:

	4
	5

*/
rune_count :: proc(s: string) -> (res: int) {
	return utf8.rune_count_in_string(s)
}
/*
Returns whether the strings `u` and `v` are the same alpha characters, ignoring different casings
Works with UTF-8 string content

Inputs:
- u: The first string for comparison
- v: The second string for comparison

Returns:
- res: `true` if the strings `u` and `v` are the same alpha characters (ignoring case)

Example:

	import "core:fmt"
	import "core:strings"

	equal_fold_example :: proc() {
		fmt.println(strings.equal_fold("test", "test"))
		fmt.println(strings.equal_fold("Test", "test"))
		fmt.println(strings.equal_fold("Test", "tEsT"))
		fmt.println(strings.equal_fold("test", "tes"))
	}

Output:

	true
	true
	true
	false

*/
equal_fold :: proc(u, v: string) -> (res: bool) {
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
/*
Returns the prefix length common between strings `a` and `b`

Inputs:
- a: The first input string
- b: The second input string

Returns:
- n: The prefix length common between strings `a` and `b`

Example:

	import "core:fmt"
	import "core:strings"

	prefix_length_example :: proc() {
		fmt.println(strings.prefix_length("testing", "test"))
		fmt.println(strings.prefix_length("testing", "te"))
		fmt.println(strings.prefix_length("telephone", "te"))
		fmt.println(strings.prefix_length("testing", "est"))
	}

Output:

	4
	2
	2
	0

*/
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
/*
Determines if a string `s` starts with a given `prefix`

Inputs:
- s: The string to check for the `prefix`
- prefix: The prefix to look for

Returns:
- result: `true` if the string `s` starts with the `prefix`, otherwise `false`

Example:

	import "core:fmt"
	import "core:strings"

	has_prefix_example :: proc() {
		fmt.println(strings.has_prefix("testing", "test"))
		fmt.println(strings.has_prefix("testing", "te"))
		fmt.println(strings.has_prefix("telephone", "te"))
		fmt.println(strings.has_prefix("testing", "est"))
	}

Output:

	true
	true
	true
	false

*/
has_prefix :: proc(s, prefix: string) -> (result: bool) {
	return len(s) >= len(prefix) && s[0:len(prefix)] == prefix
}

starts_with :: has_prefix

/*
Determines if a string `s` ends with a given `suffix`

Inputs:
- s: The string to check for the `suffix`
- suffix: The suffix to look for

Returns:
- result: `true` if the string `s` ends with the `suffix`, otherwise `false`

Example:

	import "core:fmt"
	import "core:strings"

	has_suffix_example :: proc() {
		fmt.println(strings.has_suffix("todo.txt", ".txt"))
		fmt.println(strings.has_suffix("todo.doc", ".txt"))
		fmt.println(strings.has_suffix("todo.doc.txt", ".txt"))
	}

Output:

	true
	false
	true

*/
has_suffix :: proc(s, suffix: string) -> (result: bool) {
	return len(s) >= len(suffix) && s[len(s)-len(suffix):] == suffix
}

ends_with :: has_suffix

/*
Joins a slice of strings `a` with a `sep` string

*Allocates Using Provided Allocator*

Inputs:
- a: A slice of strings to join
- sep: The separator string
- allocator: (default is context.allocator)

Returns:
- res: A combined string from the slice of strings `a` separated with the `sep` string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	join_example :: proc() {
		a := [?]string { "a", "b", "c" }
		fmt.println(strings.join(a[:], " "))
		fmt.println(strings.join(a[:], "-"))
		fmt.println(strings.join(a[:], "..."))
	}

Output:

	a b c
	a-b-c
	a...b...c

*/
join :: proc(a: []string, sep: string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	if len(a) == 0 {
		return "", nil
	}

	n := len(sep) * (len(a) - 1)
	for s in a {
		n += len(s)
	}

	b := make([]byte, n, allocator, loc) or_return
	i := copy(b, a[0])
	for s in a[1:] {
		i += copy(b[i:], sep)
		i += copy(b[i:], s)
	}
	return string(b), nil
}
/*
Joins a slice of strings `a` with a `sep` string, returns an error on allocation failure

*Allocates Using Provided Allocator*

Inputs:
- a: A slice of strings to join
- sep: The separator string
- allocator: (default is context.allocator)

Returns:
- str: A combined string from the slice of strings `a` separated with the `sep` string
- err: An allocator error if one occured, `nil` otherwise
*/
@(deprecated="Prefer join. It now returns an optional allocator error")
join_safe :: proc(a: []string, sep: string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) {
	return join(a, sep, allocator)
}
/*
Returns a combined string from the slice of strings `a` without a separator

*Allocates Using Provided Allocator*

Inputs:
- a: A slice of strings to concatenate
- allocator: (default is context.allocator)

Returns:
- res: The concatenated string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	concatenate_example :: proc() {
		a := [?]string { "a", "b", "c" }
		fmt.println(strings.concatenate(a[:]))
	}

Output:

	abc

*/
concatenate :: proc(a: []string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	if len(a) == 0 {
		return "", nil
	}

	n := 0
	for s in a {
		n += len(s)
	}
	b := make([]byte, n, allocator, loc) or_return
	i := 0
	for s in a {
		i += copy(b[i:], s)
	}
	return string(b), nil
}
/*
Returns a combined string from the slice of strings `a` without a separator, or an error if allocation fails

*Allocates Using Provided Allocator*

Inputs:
- a: A slice of strings to concatenate
- allocator: (default is context.allocator)

Returns:
The concatenated string, and an error if allocation fails
*/
@(deprecated="Prefer concatenate. It now returns an optional allocator error")
concatenate_safe :: proc(a: []string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) {
	return concatenate(a, allocator)
}

/*
Returns a substring of the input string `s` with the specified rune offset and length

Inputs:
- s: The input string to cut
- rune_offset: The starting rune index (default is 0). In runes, not bytes.
- rune_length: The number of runes to include in the substring (default is 0, which returns the remainder of the string).  In runes, not bytes.

Returns:
- res: The substring

Example:

	import "core:fmt"
	import "core:strings"

	cut_example :: proc() {
		fmt.println(strings.cut("some example text", 0, 4)) // -> "some"
		fmt.println(strings.cut("some example text", 2, 2)) // -> "me"
		fmt.println(strings.cut("some example text", 5, 7)) // -> "example"
	}

Output:

	some
	me
	example

*/
cut :: proc(s: string, rune_offset := int(0), rune_length := int(0)) -> (res: string) {
	s := s; rune_length := rune_length

	count := 0
	for _, offset in s {
		if count == rune_offset {
			s = s[offset:]
			break
		}
		count += 1
	}

	if rune_length <= 1 {
		return s
	}

	count = 0
	for _, offset in s {
		if count == rune_length {
			s = s[:offset]
			break
		}
		count += 1
	}
	return s
}

/*
Returns a substring of the input string `s` with the specified rune offset and length

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to cut
- rune_offset: The starting rune index (default is 0). In runes, not bytes.
- rune_length: The number of runes to include in the substring (default is 0, which returns the remainder of the string).  In runes, not bytes.
- allocator: (default is context.allocator)

Returns:
- res: The substring
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	cut_example :: proc() {
		fmt.println(strings.cut_clone("some example text", 0, 4)) // -> "some"
		fmt.println(strings.cut_clone("some example text", 2, 2)) // -> "me"
		fmt.println(strings.cut_clone("some example text", 5, 7)) // -> "example"
	}

Output:

	some
	me
	example

*/
cut_clone :: proc(s: string, rune_offset := int(0), rune_length := int(0), allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	res = cut(s, rune_offset, rune_length)
	return clone(res, allocator, loc)
}

/*
Splits the input string `s` into a slice of substrings separated by the specified `sep` string

*Allocates Using Provided Allocator*

*Used Internally - Private Function*

Inputs:
- s: The input string to split
- sep: The separator string
- sep_save: A flag determining if the separator should be saved in the resulting substrings
- n: The maximum number of substrings to return, returns `nil` without alloc when `n=0`
- allocator: (default is context.allocator)

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Returns:
- res: The slice of substrings
- err: An optional allocator error if one occured, `nil` otherwise
*/
@private
_split :: proc(s_, sep: string, sep_save, n_: int, allocator := context.allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) {
	s, n := s_, n_

	if n == 0 {
		return nil, nil
	}

	if sep == "" {
		l := utf8.rune_count_in_string(s)
		if n < 0 || n > l {
			n = l
		}

		res = make([]string, n, allocator, loc) or_return
		for i := 0; i < n-1; i += 1 {
			_, w := utf8.decode_rune_in_string(s)
			res[i] = s[:w]
			s = s[w:]
		}
		if n > 0 {
			res[n-1] = s
		}
		return res[:], nil
	}

	if n < 0 {
		n = count(s, sep) + 1
	}

	res = make([]string, n, allocator, loc) or_return

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

	return res[:i+1], nil
}
/*
Splits a string into parts based on a separator.

*Allocates Using Provided Allocator*

Inputs:
- s: The string to split.
- sep: The separator string used to split the input string.
- allocator: (default is context.allocator).

Returns:
- res: The slice of strings, each representing a part of the split string.
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_example :: proc() {
		s := "aaa.bbb.ccc.ddd.eee"    // 5 parts
		ss := strings.split(s, ".")
		fmt.println(ss)
	}

Output:

	["aaa", "bbb", "ccc", "ddd", "eee"]

*/
split :: proc(s, sep: string, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	return _split(s, sep, 0, -1, allocator)
}
/*
Splits a string into parts based on a separator. If n < count of seperators, the remainder of the string is returned in the last entry.

*Allocates Using Provided Allocator*

Inputs:
- s: The string to split.
- sep: The separator string used to split the input string.
- n: The maximum amount of parts to split the string into.
- allocator: (default is context.allocator)

Returns:
- res: The slice of strings, each representing a part of the split string.
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_n_example :: proc() {
		s := "aaa.bbb.ccc.ddd.eee"  // 5 parts present
		ss := strings.split_n(s, ".",3) // total of 3 wanted
		fmt.println(ss)
	}

Output:

	["aaa", "bbb", "ccc.ddd.eee"]

*/
split_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	return _split(s, sep, 0, n, allocator)
}
/*
Splits a string into parts after the separator, retaining it in the substrings.

*Allocates Using Provided Allocator*

Inputs:
- s: The string to split.
- sep: The separator string used to split the input string.
- allocator: (default is context.allocator).

Returns:
- res: The slice of strings, each representing a part of the split string after the separator
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_after_example :: proc() {
		a := "aaa.bbb.ccc.ddd.eee"         // 5 parts
		aa := strings.split_after(a, ".")
		fmt.println(aa)
	}

Output:

	["aaa.", "bbb.", "ccc.", "ddd.", "eee"]

*/
split_after :: proc(s, sep: string, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	return _split(s, sep, len(sep), -1, allocator)
}
/*
Splits a string into a total of `n` parts after the separator.

*Allocates Using Provided Allocator*

Inputs:
- s: The string to split.
- sep: The separator string used to split the input string.
- n: The maximum number of parts to split the string into.
- allocator: (default is context.allocator)

Returns:
- res: The slice of strings with `n` parts or fewer if there weren't
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_after_n_example :: proc() {
		a := "aaa.bbb.ccc.ddd.eee"
		aa := strings.split_after_n(a, ".", 3)
		fmt.println(aa)
	}

Output:

	["aaa.", "bbb.", "ccc.ddd.eee"]

*/
split_after_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	return _split(s, sep, len(sep), n, allocator)
}
/*
Searches for the first occurrence of `sep` in the given string and returns the substring
up to (but not including) the separator, as well as a boolean indicating success.

*Used Internally - Private Function*

Inputs:
- s: Pointer to the input string, which is modified during the search.
- sep: The separator string to search for.
- sep_save: Number of characters from the separator to include in the result.

Returns:
- res: The resulting substring
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end
*/
@private
_split_iterator :: proc(s: ^string, sep: string, sep_save: int) -> (res: string, ok: bool) {
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
/*
Splits the input string by the byte separator in an iterator fashion.

Inputs:
- s: Pointer to the input string, which is modified during the search.
- sep: The byte separator to search for.

Returns:
- res: The resulting substring
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_by_byte_iterator_example :: proc() {
		text := "a.b.c.d.e"
		for str in strings.split_by_byte_iterator(&text, '.') {
			fmt.println(str) // every loop -> a b c d e
		}
	}

Output:

	a
	b
	c
	d
	e

*/
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
/*
Splits the input string by the separator string in an iterator fashion.

Inputs:
- s: Pointer to the input string, which is modified during the search.
- sep: The separator string to search for.

Returns:
- res: The resulting substring
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_iterator_example :: proc() {
		text := "a.b.c.d.e"
		for str in strings.split_iterator(&text, ".") {
			fmt.println(str)
		}
	}

Output:

	a
	b
	c
	d
	e

*/
split_iterator :: proc(s: ^string, sep: string) -> (res: string, ok: bool) {
	return _split_iterator(s, sep, 0)
}
/*
Splits the input string after every separator string in an iterator fashion.

Inputs:
- s: Pointer to the input string, which is modified during the search.
- sep: The separator string to search for.

Returns:
- res: The resulting substring
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_after_iterator_example :: proc() {
		text := "a.b.c.d.e"
		for str in strings.split_after_iterator(&text, ".") {
			fmt.println(str)
		}
	}

Output:

	a.
	b.
	c.
	d.
	e

*/
split_after_iterator :: proc(s: ^string, sep: string) -> (res: string, ok: bool) {
	return _split_iterator(s, sep, len(sep))
}
/*
Trims the carriage return character from the end of the input string.

*Used Internally - Private Function*

Inputs:
- s: The input string to trim.

Returns:
- res: The trimmed string as a slice of the original.
*/
@(private)
_trim_cr :: proc(s: string) -> (res: string) {
	n := len(s)
	if n > 0 {
		if s[n-1] == '\r' {
			return s[:n-1]
		}
	}
	return s
}
/*
Splits the input string at every line break `\n`.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to split.
- allocator: (default is context.allocator)

Returns:
- res: The slice (allocated) of the split string (slices into original string)
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_example :: proc() {
		a := "a\nb\nc\nd\ne"
		b := strings.split_lines(a)
		fmt.println(b)
	}

Output:

	["a", "b", "c", "d", "e"]

*/
split_lines :: proc(s: string, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	sep :: "\n"
	lines := _split(s, sep, 0, -1, allocator) or_return
	for &line in lines {
		line = _trim_cr(line)
	}
	return lines, nil
}
/*
Splits the input string at every line break `\n` for `n` parts.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to split.
- n: The number of parts to split into.
- allocator: (default is context.allocator)

Returns:
- res: The slice (allocated) of the split string (slices into original string)
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_n_example :: proc() {
		a := "a\nb\nc\nd\ne"
		b := strings.split_lines_n(a, 3)
		fmt.println(b)
	}

Output:

	["a", "b", "c\nd\ne"]

*/
split_lines_n :: proc(s: string, n: int, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	sep :: "\n"
	lines := _split(s, sep, 0, n, allocator) or_return
	for &line in lines {
		line = _trim_cr(line)
	}
	return lines, nil
}
/*
Splits the input string at every line break `\n` leaving the `\n` in the resulting strings.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to split.
- allocator: (default is context.allocator)

Returns:
- res: The slice (allocated) of the split string (slices into original string), with `\n` included
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_after_example :: proc() {
		a := "a\nb\nc\nd\ne"
		b := strings.split_lines_after(a)
		fmt.println(b)
	}

Output:

	["a\n", "b\n", "c\n", "d\n", "e"]

*/
split_lines_after :: proc(s: string, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	sep :: "\n"
	lines := _split(s, sep, len(sep), -1, allocator) or_return
	for &line in lines {
		line = _trim_cr(line)
	}
	return lines, nil
}
/*
Splits the input string at every line break `\n` leaving the `\n` in the resulting strings.
Only runs for n parts.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to split.
- n: The number of parts to split into.
- allocator: (default is context.allocator)

Returns:
- res: The slice (allocated) of the split string (slices into original string), with `\n` included
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_after_n_example :: proc() {
		a := "a\nb\nc\nd\ne"
		b := strings.split_lines_after_n(a, 3)
		fmt.println(b)
	}

Output:

	["a\n", "b\n", "c\nd\ne"]

*/
split_lines_after_n :: proc(s: string, n: int, allocator := context.allocator) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error {
	sep :: "\n"
	lines := _split(s, sep, len(sep), n, allocator) or_return
	for &line in lines {
		line = _trim_cr(line)
	}
	return lines, nil
}
/*
Splits the input string at every line break `\n`.
Returns the current split string every iteration until the string is consumed.

Inputs:
- s: Pointer to the input string, which is modified during the search.

Returns:
- line: The resulting substring
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_iterator_example :: proc() {
		text := "a\nb\nc\nd\ne"
		for str in strings.split_lines_iterator(&text) {
			fmt.print(str)    // every loop -> a b c d e
		}
		fmt.print("\n")
	}

Output:

	abcde

*/
split_lines_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, 0) or_return
	return _trim_cr(line), true
}
/*
Splits the input string at every line break `\n`.
Returns the current split string with line breaks included every iteration until the string is consumed.

Inputs:
- s: Pointer to the input string, which is modified during the search.

Returns:
- line: The resulting substring with line breaks included
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_lines_after_iterator_example :: proc() {
		text := "a\nb\nc\nd\ne\n"
		for str in strings.split_lines_after_iterator(&text) {
			fmt.print(str) // every loop -> a\n b\n c\n d\n e\n
		}
	}

Output:

	a
	b
	c
	d
	e

*/
split_lines_after_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, len(sep)) or_return
	return _trim_cr(line), true
}
/*
Returns the byte offset of the first byte `c` in the string s it finds, -1 when not found.
NOTE: Can't find UTF-8 based runes.

Inputs:
- s: The input string to search in.
- c: The byte to search for.

Returns:
- res: The byte offset of the first occurrence of `c` in `s`, or -1 if not found.

Example:

	import "core:fmt"
	import "core:strings"

	index_byte_example :: proc() {
		fmt.println(strings.index_byte("test", 't'))
		fmt.println(strings.index_byte("test", 'e'))
		fmt.println(strings.index_byte("test", 'x'))
		fmt.println(strings.index_byte("teäst", 'ä'))
	}

Output:

	0
	1
	-1
	-1

*/
index_byte :: proc(s: string, c: byte) -> (res: int) {
	return #force_inline bytes.index_byte(transmute([]u8)s, c)
}
/*
Returns the byte offset of the last byte `c` in the string `s`, -1 when not found.

Inputs:
- s: The input string to search in.
- c: The byte to search for.

Returns:
- res: The byte offset of the last occurrence of `c` in `s`, or -1 if not found.

NOTE: Can't find UTF-8 based runes.

Example:

	import "core:fmt"
	import "core:strings"

	last_index_byte_example :: proc() {
		fmt.println(strings.last_index_byte("test", 't'))
		fmt.println(strings.last_index_byte("test", 'e'))
		fmt.println(strings.last_index_byte("test", 'x'))
		fmt.println(strings.last_index_byte("teäst", 'ä'))
	}

Output:

	3
	1
	-1
	-1

*/
last_index_byte :: proc(s: string, c: byte) -> (res: int) {
	return #force_inline bytes.last_index_byte(transmute([]u8)s, c)
}
/*
Returns the byte offset of the first rune `r` in the string `s` it finds, -1 when not found.
Invalid runes return -1

Inputs:
- s: The input string to search in.
- r: The rune to search for.

Returns:
- res: The byte offset of the first occurrence of `r` in `s`, or -1 if not found.

Example:

	import "core:fmt"
	import "core:strings"

	index_rune_example :: proc() {
		fmt.println(strings.index_rune("abcädef", 'x'))
		fmt.println(strings.index_rune("abcädef", 'a'))
		fmt.println(strings.index_rune("abcädef", 'b'))
		fmt.println(strings.index_rune("abcädef", 'c'))
		fmt.println(strings.index_rune("abcädef", 'ä'))
		fmt.println(strings.index_rune("abcädef", 'd'))
		fmt.println(strings.index_rune("abcädef", 'e'))
		fmt.println(strings.index_rune("abcädef", 'f'))
	}

Output:

	-1
	0
	1
	2
	3
	5
	6
	7

*/
index_rune :: proc(s: string, r: rune) -> (res: int) {
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
/*
Returns the byte offset of the string `substr` in the string `s`, -1 when not found.

Inputs:
- s: The input string to search in.
- substr: The substring to search for.

Returns:
- res: The byte offset of the first occurrence of `substr` in `s`, or -1 if not found.

Example:

	import "core:fmt"
	import "core:strings"

	index_example :: proc() {
		fmt.println(strings.index("test", "t"))
		fmt.println(strings.index("test", "te"))
		fmt.println(strings.index("test", "st"))
		fmt.println(strings.index("test", "tt"))
	}

Output:

	0
	0
	2
	-1

*/
index :: proc(s, substr: string) -> (res: int) {
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
/*
Returns the last byte offset of the string `substr` in the string `s`, -1 when not found.

Inputs:
- s: The input string to search in.
- substr: The substring to search for.

Returns:
- res: The byte offset of the last occurrence of `substr` in `s`, or -1 if not found.

Example:

	import "core:fmt"
	import "core:strings"

	last_index_example :: proc() {
		fmt.println(strings.last_index("test", "t"))
		fmt.println(strings.last_index("test", "te"))
		fmt.println(strings.last_index("test", "st"))
		fmt.println(strings.last_index("test", "tt"))
	}

Output:

	3
	0
	2
	-1

*/
last_index :: proc(s, substr: string) -> (res: int) {
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
/*
Returns the index of any first char of `chars` found in `s`, -1 if not found.

Inputs:
- s: The input string to search in.
- chars: The characters to look for

Returns:
- res: The index of the first character of `chars` found in `s`, or -1 if not found.

Example:

	import "core:fmt"
	import "core:strings"

	index_any_example :: proc() {
		fmt.println(strings.index_any("test", "s"))
		fmt.println(strings.index_any("test", "se"))
		fmt.println(strings.index_any("test", "et"))
		fmt.println(strings.index_any("test", "set"))
		fmt.println(strings.index_any("test", "x"))
	}

Output:

	2
	1
	0
	0
	-1

*/
index_any :: proc(s, chars: string) -> (res: int) {
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
/*
Finds the last occurrence of any character in `chars` within `s`. Iterates in reverse.

Inputs:
- s: The string to search in
- chars: The characters to look for

Returns:
- res: The index of the last matching character, or -1 if not found

Example:

	import "core:fmt"
	import "core:strings"

	last_index_any_example :: proc() {
		fmt.println(strings.last_index_any("test", "s"))
		fmt.println(strings.last_index_any("test", "se"))
		fmt.println(strings.last_index_any("test", "et"))
		fmt.println(strings.last_index_any("test", "set"))
		fmt.println(strings.last_index_any("test", "x"))
	}

Output:

	2
	2
	3
	3
	-1

*/
last_index_any :: proc(s, chars: string) -> (res: int) {
	if chars == "" {
		return -1
	}
	
	if len(s) == 1 {
		r := rune(s[0])
		if r >= utf8.RUNE_SELF {
			r = utf8.RUNE_ERROR
		}
		i := index_rune(chars, r)
		return i if i < 0 else 0
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
/*
Finds the first occurrence of any substring in `substrs` within `s`

Inputs:
- s: The string to search in
- substrs: The substrings to look for

Returns:
- idx: the index of the first matching substring
- width: the length of the found substring
*/
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
/*
Counts the number of non-overlapping occurrences of `substr` in `s`

Inputs:
- s: The string to search in
- substr: The substring to count

Returns:
- res: The number of occurrences of `substr` in `s`, returns the rune_count + 1 of the string `s` on empty `substr`

Example:

	import "core:fmt"
	import "core:strings"

	count_example :: proc() {
		fmt.println(strings.count("abbccc", "a"))
		fmt.println(strings.count("abbccc", "b"))
		fmt.println(strings.count("abbccc", "c"))
		fmt.println(strings.count("abbccc", "ab"))
		fmt.println(strings.count("abbccc", " "))
	}

Output:

	1
	2
	3
	1
	0

*/
count :: proc(s, substr: string) -> (res: int) {
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
/*
Repeats the string `s` `count` times, concatenating the result

*Allocates Using Provided Allocator*

Inputs:
- s: The string to repeat
- count: The number of times to repeat `s`
- allocator: (default is context.allocator)

Returns:
- res: The concatenated repeated string
- err: An optional allocator error if one occured, `nil` otherwise

WARNING: Panics if count < 0

Example:

	import "core:fmt"
	import "core:strings"

	repeat_example :: proc() {
		fmt.println(strings.repeat("abc", 2))
	}

Output:

	abcabc

*/
repeat :: proc(s: string, count: int, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	if count < 0 {
		panic("strings: negative repeat count")
	} else if count > 0 && (len(s)*count)/count != len(s) {
		panic("strings: repeat count will cause an overflow")
	}

	b := make([]byte, len(s)*count, allocator, loc) or_return
	i := copy(b, s)
	for i < len(b) { // 2^N trick to reduce the need to copy
		copy(b[i:], b[:i])
		i *= 2
	}
	return string(b), nil
}
/*
Replaces all occurrences of `old` in `s` with `new`

*Allocates Using Provided Allocator*

Inputs:
- s: The string to modify
- old: The substring to replace
- new: The substring to replace `old` with
- allocator: The allocator to use for the new string (default is context.allocator)

Returns:
- output: The modified string
- was_allocation: `true` if an allocation occurred during the replacement, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	replace_all_example :: proc() {
		fmt.println(strings.replace_all("xyzxyz", "xyz", "abc"))
		fmt.println(strings.replace_all("xyzxyz", "abc", "xyz"))
		fmt.println(strings.replace_all("xyzxyz", "xy", "z"))
	}

Output:

	abcabc true
	xyzxyz false
	zzzz true

*/
replace_all :: proc(s, old, new: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, old, new, -1, allocator)
}
/*
Replaces n instances of old in the string s with the new string

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- old: The substring to be replaced
- new: The replacement string
- n: The number of instances to replace (if `n < 0`, no limit on the number of replacements)
- allocator: (default: context.allocator)

Returns:
- output: The modified string
- was_allocation: `true` if an allocation occurred during the replacement, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	replace_example :: proc() {
		fmt.println(strings.replace("xyzxyz", "xyz", "abc", 2))
		fmt.println(strings.replace("xyzxyz", "xyz", "abc", 1))
		fmt.println(strings.replace("xyzxyz", "abc", "xyz", -1))
		fmt.println(strings.replace("xyzxyz", "xy", "z", -1))
	}

Output:

	abcabc true
	abcxyz true
	xyzxyz false
	zzzz true

*/
replace :: proc(s, old, new: string, n: int, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool) {
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


	t, err := make([]byte, len(s) + byte_count*(len(new) - len(old)), allocator, loc)
	if err != nil {
		return
	}
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
/*
Removes the key string `n` times from the `s` string

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- key: The substring to be removed
- n: The number of instances to remove (if `n < 0`, no limit on the number of removes)
- allocator: (default: context.allocator)

Returns:
- output: The modified string
- was_allocation: `true` if an allocation occurred during the replacement, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	remove_example :: proc() {
		fmt.println(strings.remove("abcabc", "abc", 1))
		fmt.println(strings.remove("abcabc", "abc", -1))
		fmt.println(strings.remove("abcabc", "a", -1))
		fmt.println(strings.remove("abcabc", "x", -1))
	}

Output:

	abc true
	 true
	bcbc true
	abcabc false

*/
remove :: proc(s, key: string, n: int, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, key, "", n, allocator)
}
/*
Removes all the `key` string instances from the `s` string

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- key: The substring to be removed
- allocator: (default: context.allocator)

Returns:
- output: The modified string
- was_allocation: `true` if an allocation occurred during the replacement, `false` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	remove_all_example :: proc() {
		fmt.println(strings.remove_all("abcabc", "abc"))
		fmt.println(strings.remove_all("abcabc", "a"))
		fmt.println(strings.remove_all("abcabc", "x"))
	}

Output:

	 true
	bcbc true
	abcabc false

*/
remove_all :: proc(s, key: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return remove(s, key, -1, allocator)
}
// Returns true if is an ASCII space character ('\t', '\n', '\v', '\f', '\r', ' ')
@(private) _ascii_space := [256]bool{'\t' = true, '\n' = true, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

/*
Returns true when the `r` rune is an ASCII whitespace character.

Inputs:
- r: the rune to test

Returns:
-res: `true` if `r` is a whitespace character, `false` if otherwise
*/
is_ascii_space :: proc(r: rune) -> (res: bool) {
	if r < utf8.RUNE_SELF {
		return _ascii_space[u8(r)]
	}
	return false
}

/*
Returns true when the `r` rune is an ASCII or UTF-8 whitespace character.

Inputs:
- r: the rune to test

Returns:
-res: `true` if `r` is a whitespace character, `false` if otherwise
*/
is_space :: proc(r: rune) -> (res: bool) {
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

/*
Returns true when the `r` rune is `0x0`

Inputs:
- r: the rune to test

Returns:
-res: `true` if `r` is `0x0`, `false` if otherwise
*/
is_null :: proc(r: rune) -> (res: bool) {
	return r == 0x0000
}

/*
Find the index of the first rune `r` in string `s` for which procedure `p` returns the same as truth, or -1 if no such rune appears.

Inputs:
- s: The input string
- p: A procedure that takes a rune and returns a boolean
- truth: The boolean value to be matched (default: `true`)

Returns:
- res: The index of the first matching rune, or -1 if no match was found

Example:

	import "core:fmt"
	import "core:strings"

	index_proc_example :: proc() {
		call :: proc(r: rune) -> bool {
			return r == 'a'
		}
		fmt.println(strings.index_proc("abcabc", call))
		fmt.println(strings.index_proc("cbacba", call))
		fmt.println(strings.index_proc("cbacba", call, false))
		fmt.println(strings.index_proc("abcabc", call, false))
		fmt.println(strings.index_proc("xyz", call))
	}

Output:

	0
	2
	0
	1
	-1

*/
index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: int) {
	for r, i in s {
		if p(r) == truth {
			return i
		}
	}
	return -1
}
// Same as `index_proc`, but the procedure p takes a raw pointer for state
index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: int) {
	for r, i in s {
		if p(state, r) == truth {
			return i
		}
	}
	return -1
}
// Finds the index of the *last* rune in the string s for which the procedure p returns the same value as truth
last_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: int) {
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
last_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: int) {
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
/*
Trims the input string `s` from the left until the procedure `p` returns false

Inputs:
- s: The input string
- p: A procedure that takes a rune and returns a boolean

Returns:
- res: The trimmed string as a slice of the original

Example:

	import "core:fmt"
	import "core:strings"

	trim_left_proc_example :: proc() {
		find :: proc(r: rune) -> bool {
			return r == 'x'
		}
		fmt.println(strings.trim_left_proc("xxxxxxtesting", find))
	}

Output:

	testing

*/
trim_left_proc :: proc(s: string, p: proc(rune) -> bool) -> (res: string) {
	i := index_proc(s, p, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}
/*
Trims the input string `s` from the left until the procedure `p` with state returns false

Inputs:
- s: The input string
- p: A procedure that takes a raw pointer and a rune and returns a boolean
- state: The raw pointer to be passed to the procedure `p`

Returns:
- res: The trimmed string as a slice of the original
*/
trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> (res: string) {
	i := index_proc_with_state(s, p, state, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}
/*
Trims the input string `s` from the right until the procedure `p` returns `false`

Inputs:
- s: The input string
- p: A procedure that takes a rune and returns a boolean

Returns:
- res: The trimmed string as a slice of the original

Example:

	import "core:fmt"
	import "core:strings"

	trim_right_proc_example :: proc() {
		find :: proc(r: rune) -> bool {
			return r != 't'
		}
		fmt.println(strings.trim_right_proc("testing", find))
	}

Output:

	test

*/
trim_right_proc :: proc(s: string, p: proc(rune) -> bool) -> (res: string) {
	i := last_index_proc(s, p, false)
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune_in_string(s[i:])
		i += w
	} else {
		i += 1
	}
	return s[0:i]
}
/*
Trims the input string `s` from the right until the procedure `p` with state returns `false`

Inputs:
- s: The input string
- p: A procedure that takes a raw pointer and a rune and returns a boolean
- state: The raw pointer to be passed to the procedure `p`

Returns:
- res: The trimmed string as a slice of the original, empty when no match
*/
trim_right_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> (res: string) {
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
is_in_cutset :: proc(state: rawptr, r: rune) -> (res: bool) {
	cutset := (^string)(state)^
	for c in cutset {
		if r == c {
			return true
		}
	}
	return false
}
/*
Trims the cutset string from the `s` string

Inputs:
- s: The input string
- cutset: The set of characters to be trimmed from the left of the input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_left :: proc(s: string, cutset: string) -> (res: string) {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_left_proc_with_state(s, is_in_cutset, &state)
}
/*
Trims the cutset string from the `s` string from the right

Inputs:
- s: The input string
- cutset: The set of characters to be trimmed from the right of the input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_right :: proc(s: string, cutset: string) -> (res: string) {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_right_proc_with_state(s, is_in_cutset, &state)
}
/*
Trims the cutset string from the `s` string, both from left and right

Inputs:
- s: The input string
- cutset: The set of characters to be trimmed from both sides of the input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim :: proc(s: string, cutset: string) -> (res: string) {
	return trim_right(trim_left(s, cutset), cutset)
}
/*
Trims until a valid non-space rune from the left, "\t\txyz\t\t" -> "xyz\t\t"

Inputs:
- s: The input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_left_space :: proc(s: string) -> (res: string) {
	return trim_left_proc(s, is_space)
}
/*
Trims from the right until a valid non-space rune, "\t\txyz\t\t" -> "\t\txyz"

Inputs:
- s: The input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_right_space :: proc(s: string) -> (res: string) {
	return trim_right_proc(s, is_space)
}
/*
Trims from both sides until a valid non-space rune, "\t\txyz\t\t" -> "xyz"

Inputs:
- s: The input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_space :: proc(s: string) -> (res: string) {
	return trim_right_space(trim_left_space(s))
}
/*
Trims null runes from the left, "\x00\x00testing\x00\x00" -> "testing\x00\x00"

Inputs:
- s: The input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_left_null :: proc(s: string) -> (res: string) {
	return trim_left_proc(s, is_null)
}
/*
Trims null runes from the right, "\x00\x00testing\x00\x00" -> "\x00\x00testing"

Inputs:
- s: The input string

Returns:
- res: The trimmed string as a slice of the original
*/
trim_right_null :: proc(s: string) -> (res: string) {
	return trim_right_proc(s, is_null)
}
/*
Trims null runes from both sides, "\x00\x00testing\x00\x00" -> "testing"

Inputs:
- s: The input string
Returns:
- res: The trimmed string as a slice of the original
*/
trim_null :: proc(s: string) -> (res: string) {
	return trim_right_null(trim_left_null(s))
}
/*
Trims a `prefix` string from the start of the `s` string and returns the trimmed string

Inputs:
- s: The input string
- prefix: The prefix string to be removed

Returns:
- res: The trimmed string as a slice of original, or the input string if no prefix was found

Example:

	import "core:fmt"
	import "core:strings"

	trim_prefix_example :: proc() {
		fmt.println(strings.trim_prefix("testing", "test"))
		fmt.println(strings.trim_prefix("testing", "abc"))
	}

Output:

	ing
	testing

*/
trim_prefix :: proc(s, prefix: string) -> (res: string) {
	if has_prefix(s, prefix) {
		return s[len(prefix):]
	}
	return s
}
/*
Trims a `suffix` string from the end of the `s` string and returns the trimmed string

Inputs:
- s: The input string
- suffix: The suffix string to be removed

Returns:
- res: The trimmed string as a slice of original, or the input string if no suffix was found

Example:

	import "core:fmt"
	import "core:strings"

	trim_suffix_example :: proc() {
		fmt.println(strings.trim_suffix("todo.txt", ".txt"))
		fmt.println(strings.trim_suffix("todo.doc", ".txt"))
	}

Output:

	todo
	todo.doc

*/
trim_suffix :: proc(s, suffix: string) -> (res: string) {
	if has_suffix(s, suffix) {
		return s[:len(s)-len(suffix)]
	}
	return s
}
/*
Splits the input string `s` by all possible `substrs` and returns an allocated array of strings

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- substrs: An array of substrings used for splitting
- allocator: (default is context.allocator)

Returns:
- res: An array of strings, or nil on empty substring or no matches
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:

	import "core:fmt"
	import "core:strings"

	split_multi_example :: proc() {
		splits := [?]string { "---", "~~~", ".", "_", "," }
		res := strings.split_multi("testing,this.out_nice---done~~~last", splits[:])
		fmt.println(res) // -> [testing, this, out, nice, done, last]
	}

Output:

	["testing", "this", "out", "nice", "done", "last"]

*/
split_multi :: proc(s: string, substrs: []string, allocator := context.allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error #no_bounds_check {
	if s == "" || len(substrs) <= 0 {
		return nil, nil
	}

	// disallow "" substr
	for substr in substrs {
		if len(substr) == 0 {
			return nil, nil
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

	results := make([dynamic]string, 0, n, allocator, loc) or_return
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
	return results[:], nil
}
/*
Splits the input string `s` by all possible `substrs` in an iterator fashion. The full string is returned if no match.

Inputs:
- it: A pointer to the input string
- substrs: An array of substrings used for splitting

Returns:
- res: The split string
- ok: `true` if an iteration result was returned, `false` if the iterator has reached the end

Example:

	import "core:fmt"
	import "core:strings"

	split_multi_iterate_example :: proc() {
		it := "testing,this.out_nice---done~~~last"
		splits := [?]string { "---", "~~~", ".", "_", "," }
		for str in strings.split_multi_iterate(&it, splits[:]) {
			fmt.println(str)
		}
	}

Output:

	testing
	this
	out
	nice
	done
	last

*/
split_multi_iterate :: proc(it: ^string, substrs: []string) -> (res: string, ok: bool) #no_bounds_check {
	if len(it) == 0 || len(substrs) <= 0 {
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
/*
Replaces invalid UTF-8 characters in the input string with a specified replacement string. Adjacent invalid bytes are only replaced once.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- replacement: The string used to replace invalid UTF-8 characters
- allocator: (default is context.allocator)

Returns:
- res: A new string with invalid UTF-8 characters replaced
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	scrub_example :: proc() {
		text := "Hello\xC0\x80World"
		fmt.println(strings.scrub(text, "?")) // -> "Hello?World"
	}

Output:

	Hello?

*/
scrub :: proc(s: string, replacement: string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	str := s
	b: Builder
	builder_init(&b, 0, len(s), allocator) or_return

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

	return to_string(b), nil
}
/*
Reverses the input string `s`

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- allocator: (default is context.allocator)

Returns:
- res: A reversed version of the input string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

	import "core:fmt"
	import "core:strings"

	reverse_example :: proc() {
		a := "abcxyz"
		b := strings.reverse(a)
		fmt.println(a, b)
	}

Output:

	abcxyz zyxcba

*/
reverse :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	str := s
	n := len(str)
	buf := make([]byte, n, allocator, loc) or_return
	i := n

	for len(str) > 0 {
		_, w := utf8.decode_rune_in_string(str)
		i -= w
		copy(buf[i:], str[:w])
		str = str[w:]
	}
	return string(buf), nil
}
/*
Expands the input string by replacing tab characters with spaces to align to a specified tab size

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- tab_size: The number of spaces to use for each tab character
- allocator: (default is context.allocator)

Returns:
- res: A new string with tab characters expanded to the specified tab size
- err: An optional allocator error if one occured, `nil` otherwise

WARNING: Panics if tab_size <= 0

Example:

	import "core:fmt"
	import "core:strings"

	expand_tabs_example :: proc() {
		text := "abc1\tabc2\tabc3"
		fmt.println(strings.expand_tabs(text, 4))
	}

Output:

	abc1    abc2    abc3

*/
expand_tabs :: proc(s: string, tab_size: int, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	if tab_size <= 0 {
		panic("tab size must be positive")
	}

	if s == "" {
		return "", nil
	}

	b: Builder
	builder_init(&b, allocator) or_return
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

	return to_string(b), nil
}
/*
Splits the input string `str` by the separator `sep` string and returns 3 parts. The values are slices of the original string.

Inputs:
- str: The input string
- sep: The separator string

Returns:
- head: the string before the split
- match: the seperator string
- tail: the string after the split

Example:

	import "core:fmt"
	import "core:strings"

	partition_example :: proc() {
		text := "testing this out"
		head, match, tail := strings.partition(text, " this ") // -> head: "testing", match: " this ", tail: "out"
		fmt.println(head, match, tail)
		head, match, tail = strings.partition(text, "hi") // -> head: "testing t", match: "hi", tail: "s out"
		fmt.println(head, match, tail)
		head, match, tail = strings.partition(text, "xyz")    // -> head: "testing this out", match: "", tail: ""
		fmt.println(head)
		fmt.println(match == "")
		fmt.println(tail == "")
	}

Output:

	testing  this  out
	testing t hi s out
	testing this out
	true
	true

*/
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
center_justify :: centre_justify // NOTE(bill): Because Americans exist
/*
Centers the input string within a field of specified length by adding pad string on both sides, if its length is less than the target length.

*Allocates Using Provided Allocator*

Inputs:
- str: The input string
- length: The desired length of the centered string, in runes
- pad: The string used for padding on both sides
- allocator: (default is context.allocator)

Returns:
- res: A new string centered within a field of the specified length
- err: An optional allocator error if one occured, `nil` otherwise
*/
centre_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

	w := to_writer(&b)

	write_pad_string(w, pad, pad_len, remains/2)
	io.write_string(w, str)
	write_pad_string(w, pad, pad_len, (remains+1)/2)

	return to_string(b), nil
}
/*
Left-justifies the input string within a field of specified length by adding pad string on the right side, if its length is less than the target length.

*Allocates Using Provided Allocator*

Inputs:
- str: The input string
- length: The desired length of the left-justified string
- pad: The string used for padding on the right side
- allocator: (default is context.allocator)

Returns:
- res: A new string left-justified within a field of the specified length
- err: An optional allocator error if one occured, `nil` otherwise
*/
left_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, allocator)
	builder_init(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

	w := to_writer(&b)

	io.write_string(w, str)
	write_pad_string(w, pad, pad_len, remains)

	return to_string(b), nil
}
/*
Right-justifies the input string within a field of specified length by adding pad string on the left side, if its length is less than the target length.

*Allocates Using Provided Allocator*

Inputs:
- str: The input string
- length: The desired length of the right-justified string
- pad: The string used for padding on the left side
- allocator: (default is context.allocator)

Returns:
- res: A new string right-justified within a field of the specified length
- err: An optional allocator error if one occured, `nil` otherwise
*/
right_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> (res: string, err: mem.Allocator_Error) #optional_allocator_error {
	n := rune_count(str)
	if n >= length || pad == "" {
		return clone(str, allocator)
	}

	remains := length-n
	pad_len := rune_count(pad)

	b: Builder
	builder_init(&b, allocator)
	builder_init(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

	w := to_writer(&b)

	write_pad_string(w, pad, pad_len, remains)
	io.write_string(w, str)

	return to_string(b), nil
}
/*
Writes a given pad string a specified number of times to an `io.Writer`

Inputs:
- w: The io.Writer to write the pad string to
- pad: The pad string to be written
- pad_len: The length of the pad string, in runes
- remains: The number of times to write the pad string, in runes
*/
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
/*
Splits a string into a slice of substrings at each instance of one or more consecutive white space characters, as defined by `unicode.is_space`

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- allocator: (default is context.allocator)

Returns:
- res: A slice of substrings of the input string, or an empty slice if the input string only contains white space
- err: An optional allocator error if one occured, `nil` otherwise
*/
fields :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error #no_bounds_check {
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
		return nil, nil
	}

	a := make([]string, n, allocator, loc) or_return
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
	return a, nil
}
/*
Splits a string into a slice of substrings at each run of unicode code points `r` satisfying the predicate `f(r)`

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- f: A predicate function to determine the split points
- allocator: (default is context.allocator)

NOTE: fields_proc makes no guarantee about the order in which it calls `f(r)`, it assumes that `f` always returns the same value for a given `r`

Returns:
- res: A slice of substrings of the input string, or an empty slice if all code points in the input string satisfy the predicate or if the input string is empty
- err: An optional allocator error if one occured, `nil` otherwise
*/
fields_proc :: proc(s: string, f: proc(rune) -> bool, allocator := context.allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #optional_allocator_error #no_bounds_check {
	substrings := make([dynamic]string, 0, 32, allocator, loc) or_return

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

	return substrings[:], nil
}
/*
Retrieves the first non-space substring from a mutable string reference and advances the reference. `s` is advanced from any space after the substring, or be an empty string if the substring was the remaining characters

Inputs:
- s: A mutable string reference to be iterated

Returns:
- field: The first non-space substring found
- ok: A boolean indicating if a non-space substring was found
*/
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
/*
Computes the Levenshtein edit distance between two strings

*Allocates Using Provided Allocator (deletion occurs internal to proc)*

NOTE: Does not perform internal allocation if length of string `b`, in runes, is smaller than 64

Inputs:
- a, b: The two strings to compare
- allocator: (default is context.allocator)

Returns:
- res: The Levenshtein edit distance between the two strings
- err: An optional allocator error if one occured, `nil` otherwise

NOTE: This implementation is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
*/
levenshtein_distance :: proc(a, b: string, allocator := context.allocator, loc := #caller_location) -> (res: int, err: mem.Allocator_Error) #optional_allocator_error {
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
		return n, nil
	}
	if n == 0 {
		return m, nil
	}

	costs: []int

	if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
		costs = make([]int, n + 1, allocator, loc) or_return
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

	return costs[n], nil
}

@(private)
internal_substring :: proc(s: string, rune_start: int, rune_end: int) -> (sub: string, ok: bool) {
	sub = s
	ok  = true

	rune_i: int

	if rune_start > 0 {
		ok = false
		for _, i in sub {
			if rune_start == rune_i {
				ok = true
				sub = sub[i:]
				break
			}
			rune_i += 1
		}
		if !ok { return }
	}

	if rune_end >= rune_start {
		ok = false
		for _, i in sub {
			if rune_end == rune_i {
				ok = true
				sub = sub[:i]
				break
			}
			rune_i += 1
		}

		if rune_end == rune_i {
			ok = true
		}
	}

	return
}

/*
Returns a substring of `s` that starts at rune index `rune_start` and goes up to `rune_end`.

Think of it as slicing `s[rune_start:rune_end]` but rune-wise.

Inputs:
- s: the string to substring
- rune_start: the start (inclusive) rune
- rune_end: the end (exclusive) rune

Returns:
- sub: the substring
- ok: whether the rune indexes where in bounds of the original string
*/
substring :: proc(s: string, rune_start: int, rune_end: int) -> (sub: string, ok: bool) {
	if rune_start < 0 || rune_end < 0 || rune_end < rune_start {
		return
	}

	return internal_substring(s, rune_start, rune_end)
}

/*
Returns a substring of `s` that starts at rune index `rune_start` and goes up to the end of the string.

Think of it as slicing `s[rune_start:]` but rune-wise.

Inputs:
- s: the string to substring
- rune_start: the start (inclusive) rune

Returns:
- sub: the substring
- ok: whether the rune indexes where in bounds of the original string
*/
substring_from :: proc(s: string, rune_start: int) -> (sub: string, ok: bool) {
	if rune_start < 0 {
		return
	}

	return internal_substring(s, rune_start, -1)
}

/*
Returns a substring of `s` that goes up to rune index `rune_end`.

Think of it as slicing `s[:rune_end]` but rune-wise.

Inputs:
- s: the string to substring
- rune_end: the end (exclusive) rune

Returns:
- sub: the substring
- ok: whether the rune indexes where in bounds of the original string
*/
substring_to :: proc(s: string, rune_end: int) -> (sub: string, ok: bool) {
	if rune_end < 0 {
		return
	}

	return internal_substring(s, -1, rune_end)
}
