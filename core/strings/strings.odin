// simple procedures to manipulate UTF-8 encoded strings
package strings

import "core:io"
import "core:mem"
import "core:slice"
import "core:unicode"
import "core:unicode/utf8"

// returns a clone of the string `s` allocated using the `allocator`
clone :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> string {
	c := make([]byte, len(s), allocator, loc)
	copy(c, s)
	return string(c[:len(s)])
}

// returns a clone of the string `s` allocated using the `allocator`
clone_safe :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (str: string, err: mem.Allocator_Error) {
	c := make([]byte, len(s), allocator, loc) or_return
	copy(c, s)
	return string(c[:len(s)]), nil
}

// returns a clone of the string `s` allocated using the `allocator` as a cstring
// a nul byte is appended to the clone, to make the cstring safe
clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> cstring {
	c := make([]byte, len(s)+1, allocator, loc)
	copy(c, s)
	c[len(s)] = 0
	return cstring(&c[0])
}

// returns a string from a byte pointer `ptr` and byte length `len`
// the string is valid as long as the parameters stay alive
string_from_ptr :: proc(ptr: ^byte, len: int) -> string {
	return transmute(string)mem.Raw_String{ptr, len}
}

// returns a string from a byte pointer `ptr and byte length `len`
// searches for a nul byte from 0..<len, otherwhise `len` will be the end size
string_from_nul_terminated_ptr :: proc(ptr: ^byte, len: int) -> string {
	s := transmute(string)mem.Raw_String{ptr, len}
	s = truncate_to_byte(s, 0)
	return s
}

// returns the raw ^byte start of the string `str`
ptr_from_string :: proc(str: string) -> ^byte {
	d := transmute(mem.Raw_String)str
	return d.data
}

// returns the transmute of string `str` to a cstring
// not safe since the origin string may not contain a nul byte
unsafe_string_to_cstring :: proc(str: string) -> cstring {
	d := transmute(mem.Raw_String)str
	return cstring(d.data)
}

// returns a string truncated to the first time it finds the byte `b`
// uses the `len` of the string `str` when it couldn't find the input
truncate_to_byte :: proc(str: string, b: byte) -> string {
	n := index_byte(str, b)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}

// returns a string truncated to the first time it finds the rune `r`
// uses the `len` of the string `str` when it couldn't find the input
truncate_to_rune :: proc(str: string, r: rune) -> string {
	n := index_rune(str, r)
	if n < 0 {
		n = len(str)
	}
	return str[:n]
}

// returns a cloned string of the byte array `s` using the `allocator`
// appends a leading nul byte
clone_from_bytes :: proc(s: []byte, allocator := context.allocator, loc := #caller_location) -> string {
	c := make([]byte, len(s)+1, allocator, loc)
	copy(c, s)
	c[len(s)] = 0
	return string(c[:len(s)])
}

// returns a clone of the cstring `s` using the `allocator` as a string
clone_from_cstring :: proc(s: cstring, allocator := context.allocator, loc := #caller_location) -> string {
	return clone(string(s), allocator, loc)
}

// returns a cloned string from the pointer `ptr` and a byte length `len` using the `allocator`
// same to `string_from_ptr` but allocates
clone_from_ptr :: proc(ptr: ^byte, len: int, allocator := context.allocator, loc := #caller_location) -> string {
	s := string_from_ptr(ptr, len)
	return clone(s, allocator, loc)
}

// overload to clone from a `string`, `[]byte`, `cstring` or a `^byte + length` to a string
clone_from :: proc{
	clone,
	clone_from_bytes,
	clone_from_cstring,
	clone_from_ptr,
}

// returns a cloned string from the cstring `ptr` and a byte length `len` using the `allocator`
// truncates till the first nul byte it finds or the byte len
clone_from_cstring_bounded :: proc(ptr: cstring, len: int, allocator := context.allocator, loc := #caller_location) -> string {
	s := string_from_ptr((^u8)(ptr), len)
	s = truncate_to_byte(s, 0)
	return clone(s, allocator, loc)
}

// Compares two strings, returning a value representing which one comes first lexiographically.
// -1 for `lhs`; 1 for `rhs`, or 0 if they are equal.
compare :: proc(lhs, rhs: string) -> int {
	return mem.compare(transmute([]byte)lhs, transmute([]byte)rhs)
}

// returns the byte offset of the rune `r` in the string `s`, -1 when not found
contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r {
			return offset
		}
	}
	return -1
}

/*
	returns true when the string `substr` is contained inside the string `s`

	strings.contains("testing", "test") -> true
	strings.contains("testing", "ing") -> true
	strings.contains("testing", "text") -> false
*/
contains :: proc(s, substr: string) -> bool {
	return index(s, substr) >= 0
}

/*
	returns true when the string `s` contains any of the characters inside the string `chars`
	
	strings.contains_any("test", "test") -> true
	strings.contains_any("test", "ts") -> true
	strings.contains_any("test", "et") -> true
	strings.contains_any("test", "a") -> false
*/
contains_any :: proc(s, chars: string) -> bool {
	return index_any(s, chars) >= 0
}

/*
	returns the utf8 rune count of the string `s`

	strings.rune_count("test") -> 4
	strings.rune_count("testö") -> 5, where len("testö") -> 6
*/
rune_count :: proc(s: string) -> int {
	return utf8.rune_count_in_string(s)
}

/*
	returns wether the strings `u` and `v` are the same alpha characters
	works with utf8 string content and ignores different casings

	strings.equal_fold("test", "test") -> true
	strings.equal_fold("Test", "test") -> true
	strings.equal_fold("Test", "tEsT") -> true
	strings.equal_fold("test", "tes") -> false
*/
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

/*
	return the prefix length common between strings `a` and `b`.

	strings.prefix_length("testing", "test") -> 4
	strings.prefix_length("testing", "te") -> 2
	strings.prefix_length("telephone", "te") -> 2
	strings.prefix_length("testing", "est") -> 0
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
	return true when the string `prefix` is contained at the start of the string `s`

	strings.has_prefix("testing", "test") -> true
	strings.has_prefix("testing", "te") -> true
	strings.has_prefix("telephone", "te") -> true
	strings.has_prefix("testing", "est") -> false
*/
has_prefix :: proc(s, prefix: string) -> bool {
	return len(s) >= len(prefix) && s[0:len(prefix)] == prefix
}

/*
	returns true when the string `suffix` is contained at the end of the string `s`
	good example to use this is for file extensions

	strings.has_suffix("todo.txt", ".txt") -> true
	strings.has_suffix("todo.doc", ".txt") -> false
	strings.has_suffix("todo.doc.txt", ".txt") -> true
*/
has_suffix :: proc(s, suffix: string) -> bool {
	return len(s) >= len(suffix) && s[len(s)-len(suffix):] == suffix
}

/*
	returns a combined string from the slice of strings `a` seperated with the `sep` string
	allocates the string using the `allocator`

	a := [?]string { "a", "b", "c" }
	b := strings.join(a[:], " ") -> "a b c"
	c := strings.join(a[:], "-") -> "a-b-c"
	d := strings.join(a[:], "...") -> "a...b...c"
*/
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

/*
	returns a combined string from the slice of strings `a` without a seperator
	allocates the string using the `allocator`
	

	a := [?]string { "a", "b", "c" }
	b := strings.concatenate(a[:]) -> "abc"
*/
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

/*
	`rune_offset` and `rune_length` are in runes, not bytes.
	If `rune_length` <= 0, then it'll return the remainder of the string starting at `rune_offset`.

	strings.cut("some example text", 0, 4) -> "some"
	strings.cut("some example text", 2, 2) -> "me"
	strings.cut("some example text", 5, 7) -> "example"
*/
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

/*
	Splits a string into parts, based on a separator.
	Returned strings are substrings of 's'.
	```
	s := "aaa.bbb.ccc.ddd.eee" // 5 parts
	ss := split(s, ".")
	fmt.println(ss)            // [aaa, bbb, ccc, ddd, eee]
	```
*/
split :: proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, -1, allocator)
}

/*
	Splits a string into a total of 'n' parts, based on a separator.
	Returns fewer parts if there wasn't enough occurrences of the separator.
	Returned strings are substrings of 's'.
	```
	s := "aaa.bbb.ccc.ddd.eee" // 5 parts present
	ss := split_n(s, ".", 3)   // total of 3 wanted
	fmt.println(ss)            // [aaa, bbb, ccc.ddd.eee]
	```
*/
split_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, n, allocator)
}

/*
	splits the string `s` after the seperator string `sep` appears
	returns the slice of split strings allocated using `allocator`

	a := "aaa.bbb.ccc.ddd.eee"
	aa := strings.split_after(a, ".")
	fmt.eprintln(aa) // [aaa., bbb., ccc., ddd., eee]
*/
split_after :: proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), -1, allocator)
}

/*
	splits the string `s` after the seperator string `sep` appears into a total of `n` parts
	returns the slice of split strings allocated using `allocator`

	a := "aaa.bbb.ccc.ddd.eee"
	aa := strings.split_after(a, ".")
	fmt.eprintln(aa) // [aaa., bbb., ccc., ddd., eee]
*/
split_after_n :: proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), n, allocator)
}

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

/*
	split the ^string `s` by the byte seperator `sep` in an iterator fashion
	consumes the original string till the end, leaving the string `s` with len == 0

	text := "a.b.c.d.e"
	for str in strings.split_by_byte_iterator(&text, '.') {
		fmt.eprintln(str) // every loop -> a b c d e
	}
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
	split the ^string `s` by the seperator string `sep` in an iterator fashion
	consumes the original string till the end

	text := "a.b.c.d.e"
	for str in strings.split_iterator(&text, ".") {
		fmt.eprintln(str) // every loop -> a b c d e
	}
*/
split_iterator :: proc(s: ^string, sep: string) -> (string, bool) {
	return _split_iterator(s, sep, 0)
}

/*
	split the ^string `s` after every seperator string `sep` in an iterator fashion
	consumes the original string till the end

	text := "a.b.c.d.e"
	for str in strings.split_after_iterator(&text, ".") {
		fmt.eprintln(str) // every loop -> a. b. c. d. e
	}
*/
split_after_iterator :: proc(s: ^string, sep: string) -> (string, bool) {
	return _split_iterator(s, sep, len(sep))
}


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

/*
	split the string `s` at every line break '\n'
	return an allocated slice of strings

	a := "a\nb\nc\nd\ne"
	b := strings.split_lines(a)
	fmt.eprintln(b) // [a, b, c, d, e]
*/
split_lines :: proc(s: string, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, 0, -1, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}

/*
	split the string `s` at every line break '\n' for `n` parts
	return an allocated slice of strings

	a := "a\nb\nc\nd\ne"
	b := strings.split_lines_n(a, 3)
	fmt.eprintln(b) // [a, b, c, d\ne\n]
*/
split_lines_n :: proc(s: string, n: int, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, 0, n, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}

/*
	split the string `s` at every line break '\n' leaving the '\n' in the resulting strings
	return an allocated slice of strings

	a := "a\nb\nc\nd\ne"
	b := strings.split_lines_after(a)
	fmt.eprintln(b) // [a\n, b\n, c\n, d\n, e\n]
*/
split_lines_after :: proc(s: string, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, len(sep), -1, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}

/*
	split the string `s` at every line break '\n' leaving the '\n' in the resulting strings
	only runs for `n` parts
	return an allocated slice of strings

	a := "a\nb\nc\nd\ne"
	b := strings.split_lines_after_n(a, 3)
	fmt.eprintln(b) // [a\n, b\n, c\n, d\ne\n]
*/
split_lines_after_n :: proc(s: string, n: int, allocator := context.allocator) -> []string {
	sep :: "\n"
	lines := _split(s, sep, len(sep), n, allocator)
	for line in &lines {
		line = _trim_cr(line)
	}
	return lines
}

/*
	split the string `s` at every line break '\n'
	returns the current split string every iteration till the string is consumed

	text := "a\nb\nc\nd\ne"
	for str in strings.split_lines_iterator(&text) {
		fmt.eprintln(text) // every loop -> a b c d e	
	}
*/
split_lines_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, 0) or_return
	return _trim_cr(line), true
}

/*
	split the string `s` at every line break '\n'
	returns the current split string every iteration till the string is consumed

	text := "a\nb\nc\nd\ne"
	for str in strings.split_lines_after_iterator(&text) {
		fmt.eprintln(text) // every loop -> a\n b\n c\n d\n e\n	
	}
*/
split_lines_after_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = _split_iterator(s, sep, len(sep)) or_return
	return _trim_cr(line), true
}

/*
	returns the byte offset of the first byte `c` in the string `s` it finds, -1 when not found
	can't find utf8 based runes

	strings.index_byte("test", 't') -> 0
	strings.index_byte("test", 'e') -> 1
	strings.index_byte("test", 'x') -> -1
	strings.index_byte("teäst", 'ä') -> -1
*/
index_byte :: proc(s: string, c: byte) -> int {
	for i := 0; i < len(s); i += 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}

/*
	returns the byte offset of the last byte `c` in the string `s` it finds, -1 when not found
	can't find utf8 based runes

	strings.index_byte("test", 't') -> 3
	strings.index_byte("test", 'e') -> 1
	strings.index_byte("test", 'x') -> -1
	strings.index_byte("teäst", 'ä') -> -1
*/
last_index_byte :: proc(s: string, c: byte) -> int {
	for i := len(s)-1; i >= 0; i -= 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}


/*
	returns the byte offset of the first rune `r` in the string `s` it finds, -1 when not found
	avoids invalid runes

	strings.index_rune("abcädef", 'x') -> -1
	strings.index_rune("abcädef", 'a') -> 0
	strings.index_rune("abcädef", 'b') -> 1	
	strings.index_rune("abcädef", 'c') -> 2	
	strings.index_rune("abcädef", 'ä') -> 3	
	strings.index_rune("abcädef", 'd') -> 5	
	strings.index_rune("abcädef", 'e') -> 6
	strings.index_rune("abcädef", 'f') -> 7	
*/
index_rune :: proc(s: string, r: rune) -> int {
	switch {
	case 0 <= r && r < utf8.RUNE_SELF:
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
	returns the byte offset of the string `substr` in the string `s`, -1 when not found
	
	strings.index("test", "t") -> 0
	strings.index("test", "te") -> 0
	strings.index("test", "st") -> 2
	strings.index("test", "tt") -> -1
*/
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

/*
	returns the last byte offset of the string `substr` in the string `s`, -1 when not found
	
	strings.index("test", "t") -> 3
	strings.index("test", "te") -> 0
	strings.index("test", "st") -> 2
	strings.index("test", "tt") -> -1
*/
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

/*
	returns the index of any first char of `chars` found in `s`, -1 if not found
	
	strings.index_any("test", "s") -> 2
	strings.index_any("test", "se") -> 1
	strings.index_any("test", "et") -> 0
	strings.index_any("test", "set") -> 0
	strings.index_any("test", "x") -> -1
*/
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

/*
	returns the index of any first char of `chars` found in `s`, -1 if not found
	iterates the string in reverse

	strings.index_any("test", "s") -> 2
	strings.index_any("test", "se") -> 2
	strings.index_any("test", "et") -> 1
	strings.index_any("test", "set") -> 3
	strings.index_any("test", "x") -> -1
*/
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

/*
	returns the count of the string `substr` found in the string `s`
	returns the rune_count + 1 of the string `s` on empty `substr`

	strings.count("abbccc", "a") -> 1
	strings.count("abbccc", "b") -> 2
	strings.count("abbccc", "c") -> 3
	strings.count("abbccc", "ab") -> 1
	strings.count("abbccc", " ") -> 0
*/
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

/*
	repeats the string `s` multiple `count` times and returns the allocated string
	panics when `count` is below 0

	strings.repeat("abc", 2) -> "abcabc"
*/
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

/*
	replaces all instances of `old` in the string `s`	with the `new` string
	returns the `output` string and true when an a allocation through a replace happened

	strings.replace_all("xyzxyz", "xyz", "abc") -> "abcabc", true
	strings.replace_all("xyzxyz", "abc", "xyz") -> "xyzxyz", false
	strings.replace_all("xyzxyz", "xy", "z") -> "zzzz", true
*/
replace_all :: proc(s, old, new: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, old, new, -1, allocator)
}

/*
	replaces `n` instances of `old` in the string `s`	with the `new` string
	if n < 0, no limit on the number of replacements
	returns the `output` string and true when an a allocation through a replace happened

	strings.replace("xyzxyz", "xyz", "abc", 2) -> "abcabc", true
	strings.replace("xyzxyz", "xyz", "abc", 1) -> "abcxyz", true
	strings.replace("xyzxyz", "abc", "xyz", -1) -> "xyzxyz", false
	strings.replace("xyzxyz", "xy", "z", -1) -> "zzzz", true
*/
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

/*
	removes the `key` string `n` times from the `s` string
	if n < 0, no limit on the number of removes
	returns the `output` string and true when an a allocation through a remove happened

	strings.remove("abcabc", "abc", 1) -> "abc", true
	strings.remove("abcabc", "abc", -1) -> "", true
	strings.remove("abcabc", "a", -1) -> "bcbc", true
	strings.remove("abcabc", "x", -1) -> "abcabc", false
*/
remove :: proc(s, key: string, n: int, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, key, "", n, allocator)
}

/*
	removes all the `key` string instanes from the `s` string
	returns the `output` string and true when an a allocation through a remove happened

	strings.remove("abcabc", "abc") -> "", true
	strings.remove("abcabc", "a") -> "bcbc", true
	strings.remove("abcabc", "x") -> "abcabc", false
*/
remove_all :: proc(s, key: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return remove(s, key, -1, allocator)
}

@(private) _ascii_space := [256]bool{'\t' = true, '\n' = true, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

// return true when the `r` rune is '\t', '\n', '\v', '\f', '\r' or ' '
is_ascii_space :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		return _ascii_space[u8(r)]
	}
	return false
}

// returns true when the `r` rune is any asci or utf8 based whitespace
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

// returns true when the `r` rune is a nul byte
is_null :: proc(r: rune) -> bool {
	return r == 0x0000
}

/*
	runs trough the `s` string linearly and watches wether the `p` procedure matches the `truth` bool
	returns the rune offset or -1 when no match was found

	call :: proc(r: rune) -> bool {
		return r == 'a'
	}
	strings.index_proc("abcabc", call) -> 0
	strings.index_proc("cbacba", call) -> 2
	strings.index_proc("cbacba", call, false) -> 0
	strings.index_proc("abcabc", call, false) -> 1
	strings.index_proc("xyz", call) -> -1
*/
index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> int {
	for r, i in s {
		if p(r) == truth {
			return i
		}
	}
	return -1
}

// same as `index_proc` but with a `p` procedure taking a rawptr for state
index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	for r, i in s {
		if p(state, r) == truth {
			return i
		}
	}
	return -1
}

// same as `index_proc` but runs through the string in reverse
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

// same as `index_proc_with_state` but runs through the string in reverse
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
	
/*
	trims the input string `s` until the procedure `p` returns false
	does not allocate - only returns a cut variant of the input string
	returns an empty string when no match was found at all

	find :: proc(r: rune) -> bool {
		return r != 'i'
	}
	strings.trim_left_proc("testing", find) -> "ing"
*/
trim_left_proc :: proc(s: string, p: proc(rune) -> bool) -> string {
	i := index_proc(s, p, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}

/*
	trims the input string `s` until the procedure `p` with state returns false
	returns an empty string when no match was found at all
*/
trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> string {
	i := index_proc_with_state(s, p, state, false)
	if i == -1 {
		return ""
	}
	return s[i:]
}

/*
	trims the input string `s` from the right until the procedure `p` returns false
	does not allocate - only returns a cut variant of the input string
	returns an empty string when no match was found at all

	find :: proc(r: rune) -> bool {
		return r != 't'
	}
	strings.trim_left_proc("testing", find) -> "test"
*/
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

/*
	trims the input string `s` from the right until the procedure `p` with state returns false
	returns an empty string when no match was found at all
*/
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

// procedure for `trim_*_proc` variants, which has a string rawptr cast + rune comparison
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

// trims the `cutset` string from the `s` string
trim_left :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_left_proc_with_state(s, is_in_cutset, &state)
}

// trims the `cutset` string from the `s` string from the right
trim_right :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s
	}
	state := cutset
	return trim_right_proc_with_state(s, is_in_cutset, &state)
}

// trims the `cutset` string from the `s` string, both from left and right
trim :: proc(s: string, cutset: string) -> string {
	return trim_right(trim_left(s, cutset), cutset)
}

// trims until a valid non space rune: "\t\txyz\t\t" -> "xyz\t\t"
trim_left_space :: proc(s: string) -> string {
	return trim_left_proc(s, is_space)
}

// trims from the right until a valid non space rune: "\t\txyz\t\t" -> "\t\txyz"
trim_right_space :: proc(s: string) -> string {
	return trim_right_proc(s, is_space)
}

// trims from both sides until a valid non space rune: "\t\txyz\t\t" -> "xyz"
trim_space :: proc(s: string) -> string {
	return trim_right_space(trim_left_space(s))
}

// trims nul runes from the left: "\x00\x00testing\x00\x00" -> "testing\x00\x00"
trim_left_null :: proc(s: string) -> string {
	return trim_left_proc(s, is_null)
}

// trims nul runes from the right: "\x00\x00testing\x00\x00" -> "\x00\x00testing"
trim_right_null :: proc(s: string) -> string {
	return trim_right_proc(s, is_null)
}

// trims nul runes from both sides: "\x00\x00testing\x00\x00" -> "testing"
trim_null :: proc(s: string) -> string {
	return trim_right_null(trim_left_null(s))
}

/*
	trims a `prefix` string from the start of the `s` string and returns the trimmed string
	returns the input string `s` when no prefix was found

	strings.trim_prefix("testing", "test") -> "ing"
	strings.trim_prefix("testing", "abc") -> "testing"
*/
trim_prefix :: proc(s, prefix: string) -> string {
	if has_prefix(s, prefix) {
		return s[len(prefix):]
	}
	return s
}

/*
	trims a `suffix` string from the end of the `s` string and returns the trimmed string
	returns the input string `s` when no suffix was found

	strings.trim_suffix("todo.txt", ".txt") -> "todo"
	strings.trim_suffix("todo.doc", ".txt") -> "todo.doc"
*/
trim_suffix :: proc(s, suffix: string) -> string {
	if has_suffix(s, suffix) {
		return s[:len(s)-len(suffix)]
	}
	return s
}

/*
	splits the input string `s` by all possible `substrs` []string
	returns the allocated []string, nil on any empty substring or no matches

	splits := [?]string { "---", "~~~", ".", "_", "," }
	res := strings.split_multi("testing,this.out_nice---done~~~last", splits[:])
	fmt.eprintln(res) // -> [testing, this, out, nice, done, last]
*/
split_multi :: proc(s: string, substrs: []string, allocator := context.allocator) -> (buf: []string) #no_bounds_check {
	if s == "" || len(substrs) <= 0 {
		return
	}

	// disallow "" substr
	for substr in substrs {
		if len(substr) == 0 {
			return
		}
	}

	// TODO maybe remove duplicate substrs
	// sort substrings by string size, largest to smallest
	temp_substrs := slice.clone(substrs, context.temp_allocator)
	slice.sort_by(temp_substrs, proc(a, b: string) -> bool {
		return len(a) > len(b)	
	})

	substrings_found: int
	temp := s

	// count substr results found in string
	first_pass: for len(temp) > 0 {
		for substr in temp_substrs {
			size := len(substr)

			// check range and compare string to substr
			if size <= len(temp) && temp[:size] == substr {
				substrings_found += 1
				temp = temp[size:]
				continue first_pass
			}
		}

		// step through string
		_, skip := utf8.decode_rune_in_string(temp[:])
		temp = temp[skip:]
	}

	// skip when no results
	if substrings_found < 1 {
		return
	}

	buf = make([]string, substrings_found + 1, allocator)
	buf_index: int
	temp = s
	temp_old := temp

	// gather results in the same fashion
	second_pass: for len(temp) > 0 {
		for substr in temp_substrs {
			size := len(substr)

			// check range and compare string to substr
			if size <= len(temp) && temp[:size] == substr {
				buf[buf_index] = temp_old[:len(temp_old) - len(temp)]
				buf_index += 1
				temp = temp[size:]
				temp_old = temp
				continue second_pass
			}
		}

		// step through string
		_, skip := utf8.decode_rune_in_string(temp[:])
		temp = temp[skip:]
	}

	buf[buf_index] = temp_old[:]

	return buf
}

// state for the split multi iterator
Split_Multi :: struct {
	temp: string,
	temp_old: string,
	substrs: []string,
}

// returns split multi state with sorted `substrs`
split_multi_init :: proc(s: string, substrs: []string) -> Split_Multi {
	// sort substrings, largest to smallest
	temp_substrs := slice.clone(substrs, context.temp_allocator)
	slice.sort_by(temp_substrs, proc(a, b: string) -> bool {
		return len(a) > len(b)	
	})	

	return {
		temp = s,
		temp_old = s,
		substrs = temp_substrs,
	}
}

/*
	splits the input string `s` by all possible `substrs` []string in an iterator fashion
	returns the split string every iteration, the full string on no match

	splits := [?]string { "---", "~~~", ".", "_", "," }
	state := strings.split_multi_init("testing,this.out_nice---done~~~last", splits[:])
	for str in strings.split_multi_iterate(&state) {
		fmt.eprintln(str) // every iteration -> [testing, this, out, nice, done, last]
	}
*/
split_multi_iterate :: proc(using sm: ^Split_Multi) -> (res: string, ok: bool) #no_bounds_check {
	pass: for len(temp) > 0 {
		for substr in substrs {
			size := len(substr)

			// check range and compare string to substr
			if size <= len(temp) && temp[:size] == substr {
				res = temp_old[:len(temp_old) - len(temp)]
				temp = temp[size:]
				temp_old = temp
				ok = true
				return 	
			}
		}

		// step through string
		_, skip := utf8.decode_rune_in_string(temp[:])
		temp = temp[skip:]
	}

	// allow last iteration
	if temp_old != "" {
		res = temp_old[:]	
		ok = true
		temp_old = ""
	}

	return
}

// scrub scruvs invalid utf-8 characters and replaces them with the replacement string
// Adjacent invalid bytes are only replaced once
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

/*
	returns a reversed version of the `s` string

	a := "abcxyz"
	b := strings.reverse(a)
	fmt.eprintln(a, b) // abcxyz zyxcba
*/
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

/*
	expands the string to a grid spaced by `tab_size` whenever a `\t` character appears
	returns the tabbed string, panics on tab_size <= 0

	strings.expand_tabs("abc1\tabc2\tabc3", 4) -> abc1    abc2    abc3
	strings.expand_tabs("abc1\tabc2\tabc3", 5) -> abc1 abc2 abc3
	strings.expand_tabs("abc1\tabc2\tabc3", 6) -> abc1  abc2  abc3
*/
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

/*
	splits the `str` string by the seperator `sep` string and returns 3 parts
	`head`: before the split, `match`: the seperator, `tail`: the end of the split
	returns the input string when the `sep` was not found

	text := "testing this out"
	strings.partition(text, " this ") -> head: "testing", match: " this ", tail: "out"
	strings.partition(text, "hi") -> head: "testing t", match: "hi", tail: "s out"
	strings.partition(text, "xyz") -> head: "testing this out", match: "", tail: ""
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

center_justify :: centre_justify // NOTE(bill): Because Americans exist

// centre_justify returns a string with a pad string at boths sides if the str's rune length is smaller than length
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

// left_justify returns a string with a pad string at right side if the str's rune length is smaller than length
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

// right_justify returns a string with a pad string at left side if the str's rune length is smaller than length
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


// fields splits the string s around each instance of one or more consecutive white space character, defined by unicode.is_space
// returning a slice of substrings of s or an empty slice if s only contains white space
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


// fields_proc splits the string s at each run of unicode code points `ch` satisfying f(ch)
// returns a slice of substrings of s
// If all code points in s satisfy f(ch) or string is empty, an empty slice is returned
//
// fields_proc makes no guarantee about the order in which it calls f(ch)
// it assumes that `f` always returns the same value for a given ch
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


// `fields_iterator` returns the first run of characters in `s` that does not contain white space, defined by `unicode.is_space`
// `s` will then start from any space after the substring, or be an empty string if the substring was the remaining characters
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

// `levenshtein_distance` returns the Levenshtein edit distance between 2 strings.
// This is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
// Note: allocator isn't used if the length of string b in runes is smaller than 64.
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
