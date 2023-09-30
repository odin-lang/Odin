package slashpath

import "core:strings"
import "core:unicode/utf8"

Match_Error :: enum {
	None,
	Syntax_Error,
}

// match states whether "name" matches the shell pattern
// Pattern syntax is:
//	pattern:
//		{term}
//	term:
//		'*'	        matches any sequence of non-/ characters
//		'?'             matches any single non-/ character
//		'[' ['^']  { character-range } ']'
//		                character classification (cannot be empty)
//		c               matches character c (c != '*', '?', '\\', '[')
//		'\\' c          matches character c
//
//	character-range
//		c               matches character c (c != '\\', '-', ']')
//		'\\' c          matches character c
//		lo '-' hi       matches character c for lo <= c <= hi
//
// match requires that the pattern matches the entirety of the name, not just a substring
// The only possible error returned is .Syntax_Error
//
match :: proc(pattern, name: string) -> (matched: bool, err: Match_Error) {
	pattern, name := pattern, name
	pattern_loop: for len(pattern) > 0 {
		star: bool
		chunk: string
		star, chunk, pattern = scan_chunk(pattern)
		if star && chunk == "" {
			return !strings.contains(name, "/"), .None
		}

		t: string
		ok: bool
		t, ok, err = match_chunk(chunk, name)

		if ok && (len(t) == 0 || len(pattern) > 0) {
			name = t
			continue
		}
		if err != .None {
			return
		}
		if star {
			for i := 0; i < len(name) && name[i] != '/'; i += 1 {
				t, ok, err = match_chunk(chunk, name[i+1:])
				if ok {
					if len(pattern) == 0 && len(t) > 0 {
						continue
					}
					name = t
					continue pattern_loop
				}
				if err != .None {
					return
				}
			}
		}

		return false, .None
	}

	return len(name) == 0, .None
}


@(private="file")
scan_chunk :: proc(pattern: string) -> (star: bool, chunk, rest: string) {
	pattern := pattern
	for len(pattern) > 0 && pattern[0] == '*' {
		pattern = pattern[1:]
		star = true
	}
	in_range := false
	i: int

	scan_loop: for i = 0; i < len(pattern); i += 1 {
		switch pattern[i] {
		case '\\':
			if i+1 < len(pattern) {
				i += 1
			}
		case '[':
			in_range = true
		case ']':
			in_range = false
		case '*':
			in_range or_break scan_loop
		}
	}
	return star, pattern[:i], pattern[i:]
}

@(private="file")
match_chunk :: proc(chunk, s: string) -> (rest: string, ok: bool, err: Match_Error) {
	chunk, s := chunk, s
	for len(chunk) > 0 {
		if len(s) == 0 {
			return
		}
		switch chunk[0] {
		case '[':
			r, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]
			is_negated := false
			if len(chunk) > 0 && chunk[0] == '^' {
				is_negated = true
				chunk = chunk[1:]
			}
			match := false
			range_count := 0
			for {
				if len(chunk) > 0 && chunk[0] == ']' && range_count > 0 {
					chunk = chunk[1:]
					break
				}
				lo, hi: rune
				if lo, chunk, err = get_escape(chunk); err != .None {
					return
				}
				hi = lo
				if chunk[0] == '-' {
					if hi, chunk, err = get_escape(chunk[1:]); err != .None {
						return
					}
				}

				if lo <= r && r <= hi {
					match = true
				}
				range_count += 1
			}
			if match == is_negated {
				return
			}

		case '?':
			if s[0] == '/' {
				return
			}
			_, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]

		case '\\':
			chunk = chunk[1:]
			if len(chunk) == 0 {
				err = .Syntax_Error
				return
			}
			fallthrough
		case:
			if chunk[0] != s[0] {
				return
			}
			s = s[1:]
			chunk = chunk[1:]

		}
	}
	return s, true, .None
}

@(private="file")
get_escape :: proc(chunk: string) -> (r: rune, next_chunk: string, err: Match_Error) {
	if len(chunk) == 0 || chunk[0] == '-' || chunk[0] == ']' {
		err = .Syntax_Error
		return
	}
	chunk := chunk
	if chunk[0] == '\\' {
		chunk = chunk[1:]
		if len(chunk) == 0 {
			err = .Syntax_Error
			return
		}
	}

	w: int
	r, w = utf8.decode_rune_in_string(chunk)
	if r == utf8.RUNE_ERROR && w == 1 {
		err = .Syntax_Error
	}

	next_chunk = chunk[w:]
	if len(next_chunk) == 0 {
		err = .Syntax_Error
	}

	return
}
