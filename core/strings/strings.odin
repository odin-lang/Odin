package strings

import "core:mem"
import "core:unicode/utf8"

clone :: proc(s: string, allocator := context.allocator) -> string {
	c := make([]byte, len(s)+1, allocator);
	copy(c, s);
	c[len(s)] = 0;
	return string(c[:len(s)]);
}

clone_to_cstring :: proc(s: string, allocator := context.allocator) -> cstring {
	c := make([]byte, len(s)+1, allocator);
	copy(c, s);
	c[len(s)] = 0;
	return cstring(&c[0]);
}

@(deprecated="Please use 'strings.clone'")
new_string :: proc(s: string, allocator := context.allocator) -> string {
	c := make([]byte, len(s)+1, allocator);
	copy(c, s);
	c[len(s)] = 0;
	return string(c[:len(s)]);
}

@(deprecated="Please use 'strings.clone_to_cstring'")
new_cstring :: proc(s: string, allocator := context.allocator) -> cstring {
	c := make([]byte, len(s)+1, allocator);
	copy(c, s);
	c[len(s)] = 0;
	return cstring(&c[0]);
}

@(deprecated="Please use a standard cast for cstring to string")
to_odin_string :: proc(str: cstring) -> string {
	return string(str);
}

string_from_ptr :: proc(ptr: ^byte, len: int) -> string {
	return transmute(string)mem.Raw_String{ptr, len};
}

ptr_from_string :: proc(str: string) -> ^byte {
	d := transmute(mem.Raw_String)str;
	return d.data;
}

unsafe_string_to_cstring :: proc(str: string) -> cstring {
	d := transmute(mem.Raw_String)str;
	return cstring(d.data);
}

compare :: proc(lhs, rhs: string) -> int {
	return mem.compare(transmute([]byte)lhs, transmute([]byte)rhs);
}

contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r do return offset;
	}
	return -1;
}

contains :: proc(s, substr: string) -> bool {
	return index(s, substr) >= 0;
}

contains_any :: proc(s, chars: string) -> bool {
	return index_any(s, chars) >= 0;
}


rune_count :: proc(s: string) -> int {
	return utf8.rune_count_in_string(s);
}


equal_fold :: proc(u, v: string) -> bool {
	s, t := u, v;
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

has_prefix :: proc(s, prefix: string) -> bool {
	return len(s) >= len(prefix) && s[0:len(prefix)] == prefix;
}

has_suffix :: proc(s, suffix: string) -> bool {
	return len(s) >= len(suffix) && s[len(s)-len(suffix):] == suffix;
}


join :: proc(a: []string, sep: string, allocator := context.allocator) -> string {
	if len(a) == 0 {
		return "";
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
	return string(b);
}

concatenate :: proc(a: []string, allocator := context.allocator) -> string {
	if len(a) == 0 {
		return "";
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
	return string(b);
}

@private
_split :: proc(s_, sep: string, sep_save, n_: int, allocator := context.allocator) -> []string {
	s, n := s_, n_;

	if n == 0 {
		return nil;
	}

	if sep == "" {
		l := utf8.rune_count_in_string(s);
		if n < 0 || n > l {
			n = l;
		}

		res := make([dynamic]string, n, allocator);
		for i := 0; i < n-1; i += 1 {
			_, w := utf8.decode_rune_in_string(s);
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

	res := make([dynamic]string, n, allocator);

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

split :: inline proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, -1, allocator);
}

split_n :: inline proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, 0, n, allocator);
}

split_after :: inline proc(s, sep: string, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), -1, allocator);
}

split_after_n :: inline proc(s, sep: string, n: int, allocator := context.allocator) -> []string {
	return _split(s, sep, len(sep), n, allocator);
}




index_byte :: proc(s: string, c: byte) -> int {
	for i := 0; i < len(s); i += 1 {
		if s[i] == c do return i;
	}
	return -1;
}

// Returns i1 if c is not present
last_index_byte :: proc(s: string, c: byte) -> int {
	for i := len(s)-1; i >= 0; i -= 1 {
		if s[i] == c do return i;
	}
	return -1;
}



@private PRIME_RABIN_KARP :: 16777619;

index :: proc(s, substr: string) -> int {
	hash_str_rabin_karp :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
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
		if s == substr {
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
	if h == hash && s[:n] == substr {
		return 0;
	}
	for i := n; i < len(s); /**/ {
		h *= PRIME_RABIN_KARP;
		h += u32(s[i]);
		h -= pow * u32(s[i-n]);
		i += 1;
		if h == hash && s[i-n:i] == substr {
			return i - n;
		}
	}
	return -1;
}

last_index :: proc(s, substr: string) -> int {
	hash_str_rabin_karp_reverse :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
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
		return substr == s ? 0 : -1;
	case n > len(s):
		return -1;
	}

	hash, pow := hash_str_rabin_karp_reverse(substr);
	last := len(s) - n;
	h: u32;
	for i := len(s)-1; i >= last; i -= 1 {
		h = h*PRIME_RABIN_KARP + u32(s[i]);
	}
	if h == hash && s[last:] == substr {
		return last;
	}

	for i := last-1; i >= 0; i -= 1 {
		h *= PRIME_RABIN_KARP;
		h += u32(s[i]);
		h -= pow * u32(s[i+n]);
		if h == hash && s[i:i+n] == substr {
			return i;
		}
	}
	return -1;
}

index_any :: proc(s, chars: string) -> int {
	if chars == "" {
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

last_index_any :: proc(s, chars: string) -> int {
	if chars == "" {
		return -1;
	}

	for i := len(s); i > 0;  {
		r, w := utf8.decode_last_rune_in_string(s[:i]);
		i -= w;
		for c in chars {
			if r == c {
				return i;
			}
		}
	}
	return -1;
}

count :: proc(s, substr: string) -> int {
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


repeat :: proc(s: string, count: int, allocator := context.allocator) -> string {
	if count < 0 {
		panic("strings: negative repeat count");
	} else if count > 0 && (len(s)*count)/count != len(s) {
		panic("strings: repeat count will cause an overflow");
	}

	b := make([]byte, len(s)*count, allocator);
	i := copy(b, s);
	for i < len(b) { // 2^N trick to reduce the need to copy
		copy(b[i:], b[:i]);
		i *= 2;
	}
	return string(b);
}

replace_all :: proc(s, old, new: string, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	return replace(s, old, new, -1, allocator);
}

// if n < 0, no limit on the number of replacements
replace :: proc(s, old, new: string, n: int, allocator := context.allocator) -> (output: string, was_allocation: bool) {
	if old == new || n == 0 {
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
				_, width := utf8.decode_rune_in_string(s[start:]);
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
	output = string(t[0:w]);
	return;
}

is_ascii_space :: proc(r: rune) -> bool {
	switch r {
	case '\t', '\n', '\v', '\f', '\r', ' ':
		return true;
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

index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> int {
	for r, i in s {
		if p(r) == truth {
			return i;
		}
	}
	return -1;
}

index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	for r, i in s {
		if p(state, r) == truth {
			return i;
		}
	}
	return -1;
}

last_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune_in_string(s[:i]);
		i -= size;
		if p(r) == truth {
			return i;
		}
	}
	return -1;
}

last_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> int {
	// TODO(bill): Probably use Rabin-Karp Search
	for i := len(s); i > 0; {
		r, size := utf8.decode_last_rune_in_string(s[:i]);
		i -= size;
		if p(state, r) == truth {
			return i;
		}
	}
	return -1;
}

trim_left_proc :: proc(s: string, p: proc(rune) -> bool) -> string {
	i := index_proc(s, p, false);
	if i == -1 {
		return "";
	}
	return s[i:];
}


index_rune :: proc(s: string, r: rune) -> int {
	switch {
	case 0 <= r && r < utf8.RUNE_SELF:
		return index_byte(s, byte(r));

	case r == utf8.RUNE_ERROR:
		for c, i in s {
			if c == utf8.RUNE_ERROR {
				return i;
			}
		}
		return -1;

	case !utf8.valid_rune(r):
		return -1;
	}

	b, w := utf8.encode_rune(r);
	return index(s, string(b[:w]));
}


trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> string {
	i := index_proc_with_state(s, p, state, false);
	if i == -1 {
		return "";
	}
	return s[i:];
}

trim_right_proc :: proc(s: string, p: proc(rune) -> bool) -> string {
	i := last_index_proc(s, p, false);
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune_in_string(s[i:]);
		i += w;
	} else {
		i += 1;
	}
	return s[0:i];
}

trim_right_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> string {
	i := last_index_proc_with_state(s, p, state, false);
	if i >= 0 && s[i] >= utf8.RUNE_SELF {
		_, w := utf8.decode_rune_in_string(s[i:]);
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


trim_left :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s;
	}
	state := cutset;
	return trim_left_proc_with_state(s, is_in_cutset, &state);
}

trim_right :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s;
	}
	state := cutset;
	return trim_right_proc_with_state(s, is_in_cutset, &state);
}

trim :: proc(s: string, cutset: string) -> string {
	return trim_right(trim_left(s, cutset), cutset);
}

trim_left_space :: proc(s: string) -> string {
	return trim_left_proc(s, is_space);
}

trim_right_space :: proc(s: string) -> string {
	return trim_right_proc(s, is_space);
}

trim_space :: proc(s: string) -> string {
	return trim_right_space(trim_left_space(s));
}

trim_left_null :: proc(s: string) -> string {
	return trim_left_proc(s, is_null);
}

trim_right_null :: proc(s: string) -> string {
	return trim_right_proc(s, is_null);
}

trim_null :: proc(s: string) -> string {
	return trim_right_null(trim_left_null(s));
}

// scrub scruvs invalid utf-8 characters and replaces them with the replacement string
// Adjacent invalid bytes are only replaced once
scrub :: proc(s: string, replacement: string, allocator := context.allocator) -> string {
	str := s;
	b := make_builder(allocator);;
	grow_builder(&b, len(str));

	has_error := false;
	cursor := 0;
	origin := str;

	for len(str) > 0 {
		r, w := utf8.decode_rune_in_string(str);

		if r == utf8.RUNE_ERROR {
			if !has_error {
				has_error = true;
				write_string(&b, origin[:cursor]);
			}
		} else if has_error {
			has_error = false;
			write_string(&b, replacement);

			origin = origin[cursor:];
			cursor = 0;
		}

		cursor += w;
		str = str[w:];
	}

	return to_string(b);
}


reverse :: proc(s: string, allocator := context.allocator) -> string {
	str := s;
	n := len(str);
	buf := make([]byte, n);
	i := n;

	for len(str) > 0 {
		_, w := utf8.decode_rune_in_string(str);
		i -= w;
		copy(buf[i:], str[:w]);
		str = str[w:];
	}
	return string(buf);
}

expand_tabs :: proc(s: string, tab_size: int, allocator := context.allocator) -> string {
	if tab_size <= 0 {
		panic("tab size must be positive");
	}


	if s == "" {
		return "";
	}

	b := make_builder(allocator);
	str := s;
	column: int;

	for len(str) > 0 {
		r, w := utf8.decode_rune_in_string(str);

		if r == '\t' {
			expand := tab_size - column%tab_size;

			for i := 0; i < expand; i += 1 {
				write_byte(&b, ' ');
			}

			column += expand;
		} else {
			if r == '\n' {
				column = 0;
			} else {
				column += w;
			}

			write_rune(&b, r);
		}

		str = str[w:];
	}

	return to_string(b);
}


partition :: proc(str, sep: string) -> (head, match, tail: string) {
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

// centre_justify returns a string with a pad string at boths sides if the str's rune length is smaller than length
centre_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str);
	if n >= length || pad == "" {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b := make_builder(allocator);
	grow_builder(&b, len(str) + (remains/pad_len + 1)*len(pad));

	write_pad_string(&b, pad, pad_len, remains/2);
	write_string(&b, str);
	write_pad_string(&b, pad, pad_len, (remains+1)/2);

	return to_string(b);
}

// left_justify returns a string with a pad string at left side if the str's rune length is smaller than length
left_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str);
	if n >= length || pad == "" {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b := make_builder(allocator);
	grow_builder(&b, len(str) + (remains/pad_len + 1)*len(pad));

	write_string(&b, str);
	write_pad_string(&b, pad, pad_len, remains);

	return to_string(b);
}

// right_justify returns a string with a pad string at right side if the str's rune length is smaller than length
right_justify :: proc(str: string, length: int, pad: string, allocator := context.allocator) -> string {
	n := rune_count(str);
	if n >= length || pad == "" {
		return clone(str, allocator);
	}

	remains := length-1;
	pad_len := rune_count(pad);

	b := make_builder(allocator);
	grow_builder(&b, len(str) + (remains/pad_len + 1)*len(pad));

	write_pad_string(&b, pad, pad_len, remains);
	write_string(&b, str);

	return to_string(b);
}


@private
write_pad_string :: proc(b: ^Builder, pad: string, pad_len, remains: int) {
	repeats := remains / pad_len;

	for i := 0; i < repeats; i += 1 {
		write_string(b, pad);
	}

	n := remains % pad_len;
	p := pad;

	for i := 0; i < n; i += 1 {
		r, w := utf8.decode_rune_in_string(p);
		write_rune(b, r);
		p = p[w:];
	}
}
