package strings

import "core:mem"
import "core:unicode/utf8"

new_string :: proc(s: string, allocator := context.allocator) -> string {
	c := make([]byte, len(s)+1, allocator);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return string(c[:len(s)]);
}

new_cstring :: proc(s: string, allocator := context.allocator) -> cstring {
	c := make([]byte, len(s)+1, allocator);
	copy(c, cast([]byte)s);
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

compare :: proc(lhs, rhs: string) -> int {
	return mem.compare(cast([]byte)lhs, cast([]byte)rhs);
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



equal_fold :: proc(s, t: string) -> bool {
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
	i := copy(b, cast([]byte)a[0]);
	for s in a[1:] {
		i += copy(b[i:], cast([]byte)sep);
		i += copy(b[i:], cast([]byte)s);
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
		i += copy(b[i:], cast([]byte)s);
	}
	return string(b);
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

index :: proc(s, substr: string) -> int {
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

	for i := 0; i < len(s)-n+1; i += 1 {
		x := s[i:i+n];
		if x == substr {
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
		return utf8.rune_count_in_string(s) + 1;
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
	for {
		i := index(s, substr);
		if i == -1 {
			return n;
		}
		n += 1;
		s = s[i+len(substr):];
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
	i := copy(b, cast([]byte)s);
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

	if m := count(s, old); m == 0 {
		was_allocation = false;
		output = s;
		return;
	} else if n < 0 || m < n {
		n = m;
	}


	t := make([]byte, len(s) + n*(len(new) - len(old)), allocator);
	was_allocation = true;

	w := 0;
	start := 0;
	for i := 0; i < n; i += 1 {
		j := start;
		if len(old) == 0 {
			if i > 0 {
				_, width := utf8.decode_rune_in_string(s[start:]);
				j += width;
			}
		} else {
			j += index(s[start:], old);
		}
		w += copy(t[w:], cast([]byte)s[start:j]);
		w += copy(t[w:], cast([]byte)new);
		start = j + len(old);
	}
	w += copy(t[w:], cast([]byte)s[start:]);
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
	return trim_left_proc_with_state(s, is_in_cutset, &cutset);
}

trim_right :: proc(s: string, cutset: string) -> string {
	if s == "" || cutset == "" {
		return s;
	}
	return trim_right_proc_with_state(s, is_in_cutset, &cutset);
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


// returns a slice of sub-strings into `s`
// `allocator` is used only for the slice
// `skip_empty=true` does not return zero-length substrings
split :: proc{split_single, split_multi};

split_single :: proc(s, substr: string, skip_empty := false, allocator := context.temp_allocator) -> []string #no_bounds_check {
    if s == "" || substr == "" do return nil;

    sublen := len(substr);
    shared := len(s) - sublen;

    if shared <= 0 {
        return nil;
    }

    // number, index, last
    n, i, l := 0, 0, 0;

    // count results
	first_pass: for i <= shared {
        if s[i:i+sublen] == substr {
            if !skip_empty || i - l > 0 {
                n += 1;
            }

            i += sublen;
            l  = i;
        } else {
            _, skip := utf8.decode_rune_in_string(s[i:]);
            i += skip;
        }
    }

    if !skip_empty || len(s) - l > 0 { 
        n += 1;
    }

    if n < 1 {
    	// no results
        return nil;
    }

    buf := make([]string, n, allocator);

    n, i, l = 0, 0, 0;

    // slice results
    second_pass: for i <= shared {
        if s[i:i+sublen] == substr {
            if !skip_empty || i - l > 0 {
                buf[n] = s[l:i];
                n += 1;
            }

            i += sublen;
            l  = i;
        } else {
            _, skip := utf8.decode_rune_in_string(s[i:]);
            i += skip;
        }
    }

    if !skip_empty || len(s) - l > 0 {
        buf[n] = s[l:];
    }

    return buf;
}

split_multi :: proc(s: string, substrs: []string, skip_empty := false, allocator := context.temp_allocator) -> []string #no_bounds_check {
    if s == "" || len(substrs) <= 0 {
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
		    if s[i:i+sublen] == substr {
		        if !skip_empty || i - l > 0 {
		            n += 1;
		        }

		        i += sublen;
		        l  = i;

		        continue first_pass;
		    }
    	}
	    
	    _, skip := utf8.decode_rune_in_string(s[i:]);
        i += skip;
    }

    if !skip_empty || len(s) - l > 0 { 
        n += 1;
    }

    if n < 1 {
    	// no results
        return nil;
    }

    buf := make([]string, n, allocator);

    n, i, l = 0, 0, 0;

    // slice results
    second_pass: for i <= shared {
    	for substr in substrs {
		    if s[i:i+sublen] == substr {
		        if !skip_empty || i - l > 0 {
		            buf[n] = s[l:i];
		            n += 1;
		        }

		        i += sublen;
		        l  = i;

		        continue second_pass;
		    }
    	}

	    _, skip := utf8.decode_rune_in_string(s[i:]);
	    i += skip;
    }

    if !skip_empty || len(s) - l > 0 {
        buf[n] = s[l:];
    }

    return buf;
}
