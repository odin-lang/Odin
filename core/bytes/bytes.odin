package bytes

import "core:mem"
import "core:unicode"
import "core:unicode/utf8"

clone :: proc(s: []byte, allocator := context.allocator, loc := #caller_location) -> []byte {
	c := make([]byte, len(s)+1, allocator, loc);
	copy(c, s);
	c[len(s)] = 0;
	return c[:len(s)];
}

ptr_from_slice :: proc(str: []byte) -> ^byte {
	d := transmute(mem.Raw_String)str;
	return d.data;
}

// Compares two strings, returning a value representing which one comes first lexiographically.
// -1 for `a`; 1 for `b`, or 0 if they are equal.
compare :: proc(lhs, rhs: []byte) -> int {
	return mem.compare(lhs, rhs);
}

contains_rune :: proc(s: []byte, r: rune) -> int {
	for c, offset in string(s) {
		if c == r {
			return offset;
		}
	}
	return -1;
}

contains :: proc(s, substr: []byte) -> bool {
	return index(s, substr) >= 0;
}

contains_any :: proc(s, chars: []byte) -> bool {
	return index_any(s, chars) >= 0;
}


rune_count :: proc(s: []byte) -> int {
	return utf8.rune_count(s);
}


equal :: proc(a, b: []byte) -> bool {
	return string(a) == string(b);
}

equal_fold :: proc(u, v: []byte) -> bool {
	s, t := string(u), string(v);
	loop: for s != "" && t != "" {
		sr, tr: rune;
		if s[0] < utf8.RUNE_SELF {
			sr, s = rune(s[0]), s[1:];
		} else {
			r, size := utf8.decode_rune_in_string(s);
			sr, s = r, s[size:];
		}
		if t[0] < utf8.RUNE_SELF {
			tr, t = rune(t[0]), t[1:];
		} else {
			r, size := utf8.decode_rune_in_string(t);
			tr, t = r, t[size:];
		}

		if tr == sr { // easy case
			continue loop;
		}

		if tr < sr {
			tr, sr = sr, tr;
		}

		if tr < utf8.RUNE_SELF {
			switch sr {
			case 'A'..'Z':
				if tr == (sr+'a')-'A' {
					continue loop;
				}
			}
			return false;
		}

		// TODO(bill): Unicode folding

		return false;
	}

	return s == t;
}

has_prefix :: proc(s, prefix: []byte) -> bool {
	return len(s) >= len(prefix) && string(s[0:len(prefix)]) == string(prefix);
}

has_suffix :: proc(s, suffix: []byte) -> bool {
	return len(s) >= len(suffix) && string(s[len(s)-len(suffix):]) == string(suffix);
}


join :: proc(a: [][]byte, sep: []byte, allocator := context.allocator) -> []byte {
	if len(a) == 0 {
		return nil;
	}

	n := len(sep) * (len(a) - 1);
	for s in a {
		n += len(s);
	}

	b := make([]byte, n, allocator);
	i := copy(b, a[0]);
	for s in a[1:] {
		i += copy(b[i:], sep);
		i += copy(b[i:], s);
	}
	return b;
}

concatenate :: proc(a: [][]byte, allocator := context.allocator) -> []byte {
	if len(a) == 0 {
		return nil;
	}

	n := 0;
	for s in a {
		n += len(s);
	}
	b := make([]byte, n, allocator);
	i := 0;
	for s in a {
		i += copy(b[i:], s);
	}
	return b;
}

@private
_split :: proc(s, sep: []byte, sep_save, n: int, allocator := context.allocator) -> [][]byte {
	s, n := s, n;

	if n == 0 {
		return nil;
	}

	if sep == nil {
		l := utf8.rune_count(s);
		if n < 0 || n > l {
			n = l;
		}

		res := make([dynamic][]byte, n, allocator);
		for i := 0; i < n-1; i += 1 {
			_, w := utf8.decode_rune(s);
			res[i] = s[:w];
			s = s[w:];
		}
		if n > 0 {
			res[n-1] = s;
		}
		return res[:];
	}

	if n < 0 {
		n = count(s, sep) + 1;
	}

	res := make([dynamic][]byte, n, allocator);

	n -= 1;

	i := 0;
	for ; i < n; i += 1 {
		m := index(s, sep);
		if m < 0 {
			break;
		}
		res[i] = s[:m+sep_save];
		s = s[m+len(sep):];
	}
	res[i] = s;

	return res[:i+1];
}

split :: inline proc(s, sep: []byte, allocator := context.allocator) -> [][]byte {
	return _split(s, sep, 0, -1, allocator);
}

split_n :: inline proc(s, sep: []byte, n: int, allocator := context.allocator) -> [][]byte {
	return _split(s, sep, 0, n, allocator);
}

split_after :: inline proc(s, sep: []byte, allocator := context.allocator) -> [][]byte {
	return _split(s, sep, len(sep), -1, allocator);
}

split_after_n :: inline proc(s, sep: []byte, n: int, allocator := context.allocator) -> [][]byte {
	return _split(s, sep, len(sep), n, allocator);
}




index_byte :: proc(s: []byte, c: byte) -> int {
	for i := 0; i < len(s); i += 1 {
		if s[i] == c {
			return i;
		}
	}
	return -1;
}

// Returns -1 if c is not present
last_index_byte :: proc(s: []byte, c: byte) -> int {
	for i := len(s)-1; i >= 0; i -= 1 {
		if s[i] == c {
			return i;
		}
	}
	return -1;
}



@private PRIME_RABIN_KARP :: 16777619;

index :: proc(s, substr: []byte) -> int {
	hash_str_rabin_karp :: proc(s: []byte) -> (hash: u32 = 0, pow: u32 = 1) {
		for i := 0; i < len(s); i += 1 {
			hash = hash*PRIME_RABIN_KARP + u32(s[i]);
		}
		sq := u32(PRIME_RABIN_KARP);
		for i := len(s); i > 0; i >>= 1 {
			if (i & 1) != 0 {
				pow *= sq;
			}
			sq *= sq;
		}
		return;
	}

	n := len(substr);
	switch {
	case n == 0:
		return 0;
	case n == 1:
		return index_byte(s, substr[0]);
	case n == len(s):
		if string(s) == string(substr) {
			return 0;
		}
		return -1;
	case n > len(s):
		return -1;
	}

	hash, pow := hash_str_rabin_karp(substr);
	h: u32;
	for i := 0; i < n; i += 1 {
		h = h*PRIME_RABIN_KARP + u32(s[i]);
	}
	if h == hash && string(s[:n]) == string(substr) {
		return 0;
	}
	for i := n; i < len(s); /**/ {
		h *= PRIME_RABIN_KARP;
		h += u32(s[i]);
		h -= pow * u32(s[i-n]);
		i += 1;
		if h == hash && string(s[i-n:i]) == string(substr) {
			return i - n;
		}
	}
	return -1;
}

last_index :: proc(s, substr: []byte) -> int {
	hash_str_rabin_karp_reverse :: proc(s: []byte) -> (hash: u32 = 0, pow: u32 = 1) {
		for i := len(s) - 1; i >= 0; i -= 1 {
			hash = hash*PRIME_RABIN_KARP + u32(s[i]);
		}
		sq := u32(PRIME_RABIN_KARP);
		for i := len(s); i > 0; i >>= 1 {
			if (i & 1) != 0 {
				pow *= sq;
			}
			sq *= sq;
		}
		return;
	}

	n := len(substr);
	switch {
	case n == 0:
		return len(s);
	case n == 1:
		return last_index_byte(s, substr[0]);
	case n == len(s):
		return 0 if string(substr) == string(s) else -1;
	case n > len(s):
		return -1;
	}

	hash, pow := hash_str_rabin_karp_reverse(substr);
	last := len(s) - n;
	h: u32;
	for i := len(s)-1; i >= last; i -= 1 {
		h = h*PRIME_RABIN_KARP + u32(s[i]);
	}
	if h == hash && string(s[last:]) == string(substr) {
		return last;
	}

	for i := last-1; i >= 0; i -= 1 {
		h *= PRIME_RABIN_KARP;
		h += u32(s[i]);
		h -= pow * u32(s[i+n]);
		if h == hash && string(s[i:i+n]) == string(substr) {
			return i;
		}
	}
	return -1;
}

index_any :: proc(s, chars: []byte) -> int {
	if chars == nil {
		return -1;
	}

	// TODO(bill): Optimize
	for r, i in s {
		for c in chars {
			if r == c {
				return i;
			}
		}
	}
	return -1;
}

last_index_any :: proc(s, chars: []byte) -> int {
	if chars == nil {
		return -1;
	}

	for i := len(s); i > 0;  {
		r, w := utf8.decode_last_rune(s[:i]);
		i -= w;
		for c in string(chars) {
			if r == c {
				return i;
			}
		}
	}
	return -1;
}

count :: proc(s, substr: []byte) -> int {
	if len(substr) == 0 { // special case
		return rune_count(s) + 1;
	}
	if len(substr) == 1 {
		c := substr[0];
		switch len(s) {
		case 0:
			return 0;
		case 1:
			return int(s[0] == c);
		}
		n := 0;
		for i := 0; i < len(s); i += 1 {
			if s[i] == c {
				n += 1;
			}
		}
		return n;
	}

	// TODO(bill): Use a non-brute for approach
	n := 0;
	str := s;
	for {
		i := index(str, substr);
		if i == -1 {
			return n;
		}
		n += 1;
		str = str[i+len(substr):];
	}
	return n;
}


repeat :: proc(s: []byte, count: int, allocator := context.allocator) -> []byte {
	if count < 0 {
		panic("bytes: negative repeat count");
	} else if count > 0 && (len(s)*count)/count != len(s) {
		panic("bytes: repeat count will cause an overflow");
	}

	b := make([]byte, len(s)*count, allocator);
	i := copy(b, s);
	for i < len(b) { // 2^N trick to reduce the need to copy
		copy(b[i:], b[:i]);
		i *= 2;
	}
	return b;
}

replace_all :: proc(s, old, new: []byte, allocator := context.allocator) -> (output: []byte, was_allocation: bool) {
	return replace(s, old, new, -1, allocator);
}

// if n < 0, no limit on the number of replacements
replace :: proc(s, old, new: []byte, n: int, allocator := context.allocator) -> (output: []byte, was_allocation: bool) {
	if string(old) == string(new) || n == 0 {
		was_allocation = false;
		output = s;
		return;
	}
	byte_count := n;
	if m := count(s, old); m == 0 {
		was_allocation = false;
		output = s;
		return;
	} else if n < 0 || m < n {
		byte_count = m;
	}


	t := make([]byte, len(s) + byte_count*(len(new) - len(old)), allocator);
	was_allocation = true;

	w := 0;
	start := 0;
	for i := 0; i < byte_count; i += 1 {
		j := start;
		if len(old) == 0 {
			if i > 0 {
				_, width := utf8.decode_rune(s[start:]);
				j += width;
			}
		} else {
			j += index(s[start:], old);
		}
		w += copy(t[w:], s[start:j]);
		w += copy(t[w:], new);
		start = j + len(old);
	}
	w += copy(t[w:], s[start:]);
	output = t[0:w];
	return;
}

@(private) _ascii_space := [256]u8{'\t' = 1, '\n' = 1, '\v' = 1, '\f' = 1, '\r' = 1, ' ' = 1};


is_ascii_space :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		return _ascii_space[u8(r)] != 0;
	}
	return false;
}

is_space :: proc(r: rune) -> bool {
	if r < 0x2000 {
		switch r {
		case '\t', '\n', '\v', '\f', '\r', ' ', 0x85, 0xa0, 0x1680:
			return true;
		}
	} else {
		if r <= 0x200a {
			return true;
		}
		switch r {
		case 0x2028, 0x2029, 0x202f, 0x205f, 0x3000:
			return true;
		}
	}
	return false;
}

is_null :: proc(r: rune) -> bool {
	return r == 0x0000;
}

index_proc :: proc(s: []byte, p: proc(rune) -> bool, truth := true) -> int {
	for r, i in string(s) {
		if p(r) == truth {
			return i;
		}
	}
	return -1;
}

index_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	for r, i in string(s) {
		if p(state, r) == truth {
			return i;
		}
	}
	return -1;
}

last_index_proc :: proc(s: []byte, p: proc(rune) -> bool, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune(s[:i]);
		i -= size;
		if p(r) == truth {
			return i;
		}
	}
	return -1;
}

last_index_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune(s[:i]);
		i -= size;
		if p(state, r) == truth {
			return i;
		}
	}
	return -1;
}

trim_left_proc :: proc(s: []byte, p: proc(rune) -> bool) -> []byte {
	i := index_proc(s, p, false);
	if i == -1 {
		return nil;
	}
	return s[i:];
}


index_rune :: proc(s: []byte, r: rune) -> int {
	switch {
	case 0 <= r && r < utf8.RUNE_SELF:
		return index_byte(s, byte(r));

	case r == utf8.RUNE_ERROR:
		for c, i in string(s) {
			if c == utf8.RUNE_ERROR {
				return i;
			}
		}
		return -1;

	case !utf8.valid_rune(r):
		return -1;
	}

	b, w := utf8.encode_rune(r);
	return index(s, b[:w]);
}


trim_left_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr) -> []byte {
	i := index_proc_with_state(s, p, state, false);
	if i == -1 {
		return nil;
	}
	return s[i:];
}

trim_right_proc :: proc(s: []byte, p: proc(rune) -> bool) -> []byte {
	i := last_index_proc(s, p, false);
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune(s[i:]);
		i += w;
	} else {
		i += 1;
	}
	return s[0:i];
}

trim_right_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr) -> []byte {
	i := last_index_proc_with_state(s, p, state, false);
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune(s[i:]);
		i += w;
	} else {
		i += 1;
	}
	return s[0:i];
}


is_in_cutset :: proc(state: rawptr, r: rune) -> bool {
	if state == nil {
		return false;
	}
	cutset := (^string)(state)^;
	for c in cutset {
		if r == c {
			return true;
		}
	}
	return false;
}


trim_left :: proc(s: []byte, cutset: []byte) -> []byte {
	if s == nil || cutset == nil {
		return s;
	}
	state := cutset;
	return trim_left_proc_with_state(s, is_in_cutset, &state);
}

trim_right :: proc(s: []byte, cutset: []byte) -> []byte {
	if s == nil || cutset == nil {
		return s;
	}
	state := cutset;
	return trim_right_proc_with_state(s, is_in_cutset, &state);
}

trim :: proc(s: []byte, cutset: []byte) -> []byte {
	return trim_right(trim_left(s, cutset), cutset);
}

trim_left_space :: proc(s: []byte) -> []byte {
	return trim_left_proc(s, is_space);
}

trim_right_space :: proc(s: []byte) -> []byte {
	return trim_right_proc(s, is_space);
}

trim_space :: proc(s: []byte) -> []byte {
	return trim_right_space(trim_left_space(s));
}


trim_left_null :: proc(s: []byte) -> []byte {
	return trim_left_proc(s, is_null);
}

trim_right_null :: proc(s: []byte) -> []byte {
	return trim_right_proc(s, is_null);
}

trim_null :: proc(s: []byte) -> []byte {
	return trim_right_null(trim_left_null(s));
}

trim_prefix :: proc(s, prefix: []byte) -> []byte {
	if has_prefix(s, prefix) {
		return s[len(prefix):];
	}
	return s;
}

trim_suffix :: proc(s, suffix: []byte) -> []byte {
	if has_suffix(s, suffix) {
		return s[:len(s)-len(suffix)];
	}
	return s;
}

split_multi :: proc(s: []byte, substrs: [][]byte, skip_empty := false, allocator := context.allocator) -> [][]byte #no_bounds_check {
	if s == nil || len(substrs) <= 0 {
		return nil;
	}

	sublen := len(substrs[0]);

	for substr in substrs[1:] {
		sublen = min(sublen, len(substr));
	}

	shared := len(s) - sublen;

	if shared <= 0 {
		return nil;
	}

	// number, index, last
	n, i, l := 0, 0, 0;

	// count results
	first_pass: for i <= shared {
		for substr in substrs {
			if string(s[i:i+sublen]) == string(substr) {
				if !skip_empty || i - l > 0 {
					n += 1;
				}

				i += sublen;
				l  = i;

				continue first_pass;
			}
		}

		_, skip := utf8.decode_rune(s[i:]);
		i += skip;
	}

	if !skip_empty || len(s) - l > 0 {
		n += 1;
	}

	if n < 1 {
		// no results
		return nil;
	}

	buf := make([][]byte, n, allocator);

	n, i, l = 0, 0, 0;

	// slice results
	second_pass: for i <= shared {
		for substr in substrs {
			if string(s[i:i+sublen]) == string(substr) {
				if !skip_empty || i - l > 0 {
					buf[n] = s[l:i];
					n += 1;
				}

				i += sublen;
				l  = i;

				continue second_pass;
			}
		}

		_, skip := utf8.decode_rune(s[i:]);
		i += skip;
	}

	if !skip_empty || len(s) - l > 0 {
		buf[n] = s[l:];
	}

	return buf;
}

// scrub scruvs invalid utf-8 characters and replaces them with the replacement string
// Adjacent invalid bytes are only replaced once
scrub :: proc(s: []byte, replacement: []byte, allocator := context.allocator) -> []byte {
	str := s;
	b: Buffer;
	buffer_init_allocator(&b, 0, len(s), allocator);

	has_error := false;
	cursor := 0;
	origin := str;

	for len(str) > 0 {
		r, w := utf8.decode_rune(str);

		if r == utf8.RUNE_ERROR {
			if !has_error {
				has_error = true;
				buffer_write(&b, origin[:cursor]);
			}
		} else if has_error {
			has_error = false;
			buffer_write(&b, replacement);

			origin = origin[cursor:];
			cursor = 0;
		}

		cursor += w;
		str = str[w:];
	}

	return buffer_to_bytes(&b);
}


reverse :: proc(s: []byte, allocator := context.allocator) -> []byte {
	str := s;
	n := len(str);
	buf := make([]byte, n);
	i := n;

	for len(str) > 0 {
		_, w := utf8.decode_rune(str);
		i -= w;
		copy(buf[i:], str[:w]);
		str = str[w:];
	}
	return buf;
}

expand_tabs :: proc(s: []byte, tab_size: int, allocator := context.allocator) -> []byte {
	if tab_size <= 0 {
		panic("tab size must be positive");
	}


	if s == nil {
		return nil;
	}

	b: Buffer;
	buffer_init_allocator(&b, 0, len(s), allocator);

	str := s;
	column: int;

	for len(str) > 0 {
		r, w := utf8.decode_rune(str);

		if r == '\t' {
			expand := tab_size - column%tab_size;

			for i := 0; i < expand; i += 1 {
				buffer_write_byte(&b, ' ');
			}

			column += expand;
		} else {
			if r == '\n' {
				column = 0;
			} else {
				column += w;
			}

			buffer_write_rune(&b, r);
		}

		str = str[w:];
	}

	return buffer_to_bytes(&b);
}

partition :: proc(str, sep: []byte) -> (head, match, tail: []byte) {
	i := index(str, sep);
	if i == -1 {
		head = str;
		return;
	}

	head = str[:i];
	match = str[i:i+len(sep)];
	tail = str[i+len(sep):];
	return;
}

center_justify :: centre_justify; // NOTE(bill): Because Americans exist

// centre_justify returns a byte slice with a pad byte slice at boths sides if the str's rune length is smaller than length
centre_justify :: proc(str: []byte, length: int, pad: []byte, allocator := context.allocator) -> []byte {
	n := rune_count(str);
	if n >= length || pad == nil {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b: Buffer;
	buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator);

	write_pad_string(&b, pad, pad_len, remains/2);
	buffer_write(&b, str);
	write_pad_string(&b, pad, pad_len, (remains+1)/2);

	return buffer_to_bytes(&b);
}

// left_justify returns a byte slice with a pad byte slice at left side if the str's rune length is smaller than length
left_justify :: proc(str: []byte, length: int, pad: []byte, allocator := context.allocator) -> []byte {
	n := rune_count(str);
	if n >= length || pad == nil {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b: Buffer;
	buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator);

	buffer_write(&b, str);
	write_pad_string(&b, pad, pad_len, remains);

	return buffer_to_bytes(&b);
}

// right_justify returns a byte slice with a pad byte slice at right side if the str's rune length is smaller than length
right_justify :: proc(str: []byte, length: int, pad: []byte, allocator := context.allocator) -> []byte {
	n := rune_count(str);
	if n >= length || pad == nil {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b: Buffer;
	buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator);

	write_pad_string(&b, pad, pad_len, remains);
	buffer_write(&b, str);

	return buffer_to_bytes(&b);
}




@private
write_pad_string :: proc(b: ^Buffer, pad: []byte, pad_len, remains: int) {
	repeats := remains / pad_len;

	for i := 0; i < repeats; i += 1 {
		buffer_write(b, pad);
	}

	n := remains % pad_len;
	p := pad;

	for i := 0; i < n; i += 1 {
		r, width := utf8.decode_rune(p);
		buffer_write_rune(b, r);
		p = p[width:];
	}
}


// fields splits the byte slice s around each instance of one or more consecutive white space character, defined by unicode.is_space
// returning a slice of subslices of s or an empty slice if s only contains white space
fields :: proc(s: []byte, allocator := context.allocator) -> [][]byte #no_bounds_check {
	n := 0;
	was_space := 1;
	set_bits := u8(0);

	// check to see
	for i in 0..<len(s) {
		r := s[i];
		set_bits |= r;
		is_space := int(_ascii_space[r]);
		n += was_space & ~is_space;
		was_space = is_space;
	}

	if set_bits >= utf8.RUNE_SELF {
		return fields_proc(s, unicode.is_space, allocator);
	}

	if n == 0 {
		return nil;
	}

	a := make([][]byte, n, allocator);
	na := 0;
	field_start := 0;
	i := 0;
	for i < len(s) && _ascii_space[s[i]] != 0 {
		i += 1;
	}
	field_start = i;
	for i < len(s) {
		if _ascii_space[s[i]] == 0 {
			i += 1;
			continue;
		}
		a[na] = s[field_start : i];
		na += 1;
		i += 1;
		for i < len(s) && _ascii_space[s[i]] != 0 {
			i += 1;
		}
		field_start = i;
	}
	if field_start < len(s) {
		a[na] = s[field_start:];
	}
	return a;
}


// fields_proc splits the byte slice s at each run of unicode code points `ch` satisfying f(ch)
// returns a slice of subslices of s
// If all code points in s satisfy f(ch) or string is empty, an empty slice is returned
//
// fields_proc makes no guarantee about the order in which it calls f(ch)
// it assumes that `f` always returns the same value for a given ch
fields_proc :: proc(s: []byte, f: proc(rune) -> bool, allocator := context.allocator) -> [][]byte #no_bounds_check {
	subslices := make([dynamic][]byte, 0, 32, allocator);

	start, end := -1, -1;
	for r, offset in string(s) {
		end = offset;
		if f(r) {
			if start >= 0 {
				append(&subslices, s[start : end]);
				// -1 could be used, but just speed it up through bitwise not
				// gotta love 2's complement
				start = ~start;
			}
		} else {
			if start < 0 {
				start = end;
			}
		}
	}

	if start >= 0 {
		append(&subslices, s[start : end]);
	}

	return subslices[:];
}
