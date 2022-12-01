package strlib

import "core:unicode"
import "core:unicode/utf8"
import "core:strings"

MAXCAPTURES :: 32

Capture :: struct {
	init: int,
	len: int,
}

Match :: struct {
	byte_start, byte_end: int,
}

Error :: enum {
	OK,
	OOB,
	Invalid_Capture_Index,
	Invalid_Pattern_Capture,
	Unfinished_Capture,
	Malformed_Pattern,
	Rune_Error,
}

L_ESC :: '%'
CAP_POSITION :: -2
CAP_UNFINISHED :: -1
INVALID :: -1

MatchState :: struct {
	src: string,
	pattern: string,
	level: int,
	capture: [MAXCAPTURES]Capture,
}

match_class :: proc(c: rune, cl: rune) -> (res: bool) {
	switch unicode.to_lower(cl) {
		case 'a': res = isalpha(c)
		case 'c': res = iscntrl(c)
		case 'd': res = isdigit(c)
		case 'g': res = isgraph(c)
		case 'l': res = islower(c)
		case 'p': res = ispunct(c)
		case 's': res = isspace(c)
		case 'u': res = isupper(c)
		case 'w': res = isalnum(c)
		case 'x': res = isxdigit(c)
		case: return cl == c
	}

	return islower(cl) ? res : !res
}

isalpha :: proc(c: rune) -> bool {
	return unicode.is_alpha(c)
}

isdigit :: proc(c: rune) -> bool {
	return unicode.is_digit(c)
}

isalnum :: proc(c: rune) -> bool {
	return unicode.is_alpha(c) || unicode.is_digit(c)
}

iscntrl :: proc(c: rune) -> bool {
	return unicode.is_control(c)
}

islower :: proc(c: rune) -> bool {
	return unicode.is_lower(c)
}

isupper :: proc(c: rune) -> bool {
	return unicode.is_upper(c)
}

isgraph :: proc(c: rune) -> bool {
	return unicode.is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

ispunct :: proc(c: rune) -> bool {
	return unicode.is_punct(c)
}

isxdigit :: proc(c: rune) -> bool {
	return unicode.is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

isspace :: proc(c: rune) -> bool {
	return unicode.is_space(c)
}

utf8_peek :: proc(bytes: string) -> (c: rune, size: int, err: Error) {
	c, size = utf8.decode_rune_in_string(bytes)

	if c == utf8.RUNE_ERROR {
		err = .Rune_Error
	}

	return
}

utf8_advance :: proc(bytes: string, index: ^int) -> (c: rune, err: Error) {
	size: int
	c, size = utf8.decode_rune_in_string(bytes[index^:])

	if c == utf8.RUNE_ERROR {
		err = .Rune_Error
	}

	index^ += size
	return
}

// continuation byte?
is_cont :: proc(b: byte) -> bool {
	return b & 0xc0 == 0x80
}

utf8_prev :: proc(bytes: string, a, b: int) -> int {
	b := b

	for a < b && is_cont(bytes[b - 1]) {
		b -= 1
	}

	return a < b ? b - 1 : a
}

utf8_next :: proc(bytes: string, a: int) -> int {
	a := a
	b := len(bytes)

	for a < b - 1 && is_cont(bytes[a + 1]) {
		a += 1
	}

	return a < b ? a + 1 : b
}

check_capture :: proc(ms: ^MatchState, l: rune) -> (int, Error) {
	l := int(l - '1')
	
	if l < 0 || l >= ms.level || ms.capture[l].len == CAP_UNFINISHED {
		return 0, .Invalid_Capture_Index
	}

	return l, .OK
}

capture_to_close :: proc(ms: ^MatchState) -> (int, Error) {
	level := ms.level - 1

	for level >= 0 {
		if ms.capture[level].len == CAP_UNFINISHED {
			return level, .OK
		}

		level -= 1
	}

	return 0, .Invalid_Pattern_Capture
}

classend :: proc(ms: ^MatchState, p: int) -> (step: int, err: Error) {
	step = p
	ch := utf8_advance(ms.pattern, &step) or_return

	switch ch {
		case L_ESC: {
			if step == len(ms.pattern) {
				err = .Malformed_Pattern
				return
			}

			utf8_advance(ms.pattern, &step) or_return
		}

		case '[': {
			// fine with step by 1
			if ms.pattern[step] == '^' {
				step += 1
			}

			// run till end is reached
			for ms.pattern[step] != ']' {
				if step == len(ms.pattern) {
					err = .Malformed_Pattern
					return
				}

				// dont care about utf8 here
				step += 1

				if step < len(ms.pattern) && ms.pattern[step] == L_ESC {
					// skip escapes like '%'
					step += 1
				}
			}

			// advance last time
			step += 1
		}
	}

	return
}

matchbracketclass :: proc(ms: ^MatchState, c: rune, p, ec: int) -> (sig: bool, err: Error) {
	sig = true
	p := p

	if ms.pattern[p + 1] == '^' {
		p += 1
		sig = false
	}

	// while inside of class range
	for p < ec {
		char := utf8_advance(ms.pattern, &p) or_return

		// e.g. %a
		if char == L_ESC { 
			next := utf8_advance(ms.pattern, &p) or_return

			if match_class(c, next) {
				return
			}
		} else {
			next, next_size := utf8_peek(ms.pattern[p:]) or_return

			// TODO test case for [a-???] where ??? is missing
			if next == '-' && p + next_size < len(ms.pattern) {
				// advance 2 codepoints
				p += next_size
				last := utf8_advance(ms.pattern, &p) or_return

				if char <= c && c <= last {
					return
				}
			} else if char == c {
				return
			}
		}
	}

	sig = !sig
	return
}

singlematch :: proc(ms: ^MatchState, s, p, ep: int) -> (matched: bool, schar_size: int, err: Error) {
	if s >= len(ms.src) {
		return
	}

	pchar, psize := utf8_peek(ms.pattern[p:]) or_return
	schar, ssize := utf8_peek(ms.src[s:]) or_return
	schar_size = ssize

	switch pchar {
		case '.': matched = true
		case L_ESC: {
			pchar_next, _ := utf8_peek(ms.pattern[p + psize:]) or_return
			matched = match_class(schar, pchar_next)
		}
		case '[': {
			matched = matchbracketclass(ms, schar, p, ep - 1) or_return
		}
		case: {
			matched = schar == pchar
		}
	}

	return
}

matchbalance :: proc(ms: ^MatchState, s, p: int) -> (unused: int, err: Error) {
	if p >= len(ms.pattern) - 1 {
		return INVALID, .Invalid_Pattern_Capture
	}

	schar, ssize := utf8_peek(ms.src[s:]) or_return
	pchar, psize := utf8_peek(ms.pattern[p:]) or_return

	// skip until the src and pattern match
	if schar != pchar {
		return INVALID, .OK
	}

	s_begin := s
	cont := 1
	s := s + ssize
	begin := pchar
	end, _ := utf8_peek(ms.pattern[p + psize:]) or_return

	for s < len(ms.src) {
		ch := utf8_advance(ms.src, &s) or_return

		if ch == end {
			cont -= 1

			if cont == 0 {
				return s, .OK
			}
		} else if ch == begin {
			cont += 1
		}
	}

	return INVALID, .OK
}

max_expand :: proc(ms: ^MatchState, s, p, ep: int) -> (res: int, err: Error) {
	m := s

	// count up matches
	for {
		matched, size := singlematch(ms, m, p, ep) or_return
		
		if !matched {
			break
		}

		m += size
	}

	for s <= m {
		result := match(ms, m, ep + 1) or_return

		if result != INVALID {
			return result, .OK
		}

		if s == m {
			break
		}

		m = utf8_prev(ms.src, s, m)
	}

	return INVALID, .OK
}

min_expand :: proc(ms: ^MatchState, s, p, ep: int) -> (res: int, err: Error) {
	s := s

	for {
		result := match(ms, s, ep + 1) or_return

		if result != INVALID {
			return result, .OK
		} else {
			// TODO receive next step maybe?
			matched, rune_size := singlematch(ms, s, p, ep) or_return

			if matched {
				s += rune_size
			} else {
				return INVALID, .OK
			}
		}
	}
}

start_capture :: proc(ms: ^MatchState, s, p, what: int) -> (res: int, err: Error) {
	level := ms.level

	ms.capture[level].init = s
	ms.capture[level].len = what
	ms.level += 1

	res = match(ms, s, p) or_return
	if res == INVALID {
		ms.level -= 1
	}
	return
}

end_capture :: proc(ms: ^MatchState, s, p: int) -> (res: int, err: Error) {
	l := capture_to_close(ms) or_return
	
	// TODO double check, could do string as int index
	ms.capture[l].len = s - ms.capture[l].init

	res = match(ms, s, p) or_return
	if res == INVALID {
		ms.capture[l].len = CAP_UNFINISHED
	}
	return
}

match_capture :: proc(ms: ^MatchState, s: int, char: rune) -> (res: int, err: Error) {
	index := check_capture(ms, char) or_return
	length := ms.capture[index].len

	if len(ms.src) - s >= length {
		return s + length, .OK
	}

	return INVALID, .OK
}

match :: proc(ms: ^MatchState, s, p: int) -> (unused: int, err: Error) {
	s := s
	p := p

	if p == len(ms.pattern) {
		return s, .OK
	}

	// NOTE we can walk by ascii steps if we know the characters are ascii
	char, _ := utf8_peek(ms.pattern[p:]) or_return
	switch char {
		case '(': {
			if ms.pattern[p + 1] == ')' {
				s = start_capture(ms, s, p + 2, CAP_POSITION) or_return
			} else {
				s = start_capture(ms, s, p + 1, CAP_UNFINISHED) or_return
			}
		}

		case ')': {
			s = end_capture(ms, s, p + 1) or_return
		}

		case '$': {
			if p + 1 != len(ms.pattern) {
				return match_default(ms, s, p)
			} 

			if len(ms.src) != s {
				s = INVALID
			}
		}

		case L_ESC: {
			// stop short patterns like "%" only
			if p + 1 >= len(ms.pattern) {
				err = .OOB
				return
			}

			switch ms.pattern[p + 1] {
				// balanced string
				case 'b': {
					s = matchbalance(ms, s, p + 2) or_return

					if s != INVALID {
						// eg after %b()
						return match(ms, s, p + 4)
					}
				}

				// frontier
				case 'f': {
					p += 2
					
					if ms.pattern[p] != '[' {
						return INVALID, .Invalid_Pattern_Capture
					}

					ep := classend(ms, p) or_return
					previous, current: rune

					// get previous
					if s != 0 {
						temp := utf8_prev(ms.src, 0, s)
						previous, _ = utf8_peek(ms.src[temp:]) or_return
					}

					// get current
					if s != len(ms.src) {
						current, _ = utf8_peek(ms.src[s:]) or_return
					}

					m1 := matchbracketclass(ms, previous, p, ep - 1) or_return
					m2 := matchbracketclass(ms, current, p, ep - 1) or_return

					if !m1 && m2 {
						return match(ms, s, ep)
					}

					s = INVALID
				}

				// capture group
				case '0'..<'9': {
					s = match_capture(ms, s, rune(ms.pattern[p + 1])) or_return

					if s != INVALID {
						return match(ms, s, p + 2)
					}
				}

				case: {
					return match_default(ms, s, p)
				}
			}
		}

		case: {
			return match_default(ms, s, p)
		}
	}

	return s, .OK
}

match_default :: proc(ms: ^MatchState, s, p: int) -> (unused: int, err: Error) {
	s := s
	ep := classend(ms, p) or_return
	single_matched, ssize := singlematch(ms, s, p, ep) or_return

	if !single_matched {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0

		if epc == '*' || epc == '?' || epc == '-' {
			return match(ms, s, ep + 1)
		} else {
			s = INVALID
		}
	} else {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0

		switch epc {
			case '?': {
				result := match(ms, s + ssize, ep + 1) or_return
				
				if result != INVALID {
					s = result
				} else {
					return match(ms, s, ep + 1)
				}
			}

			case '+': {
				s = max_expand(ms, s + ssize, p, ep) or_return
			}

			case '*': {
				s = max_expand(ms, s, p, ep) or_return
			}

			case '-': {
				s = min_expand(ms, s, p, ep) or_return
			}

			case: {
				return match(ms, s + ssize, ep)
			}
		}
	}

	return s, .OK
}

push_onecapture :: proc(
	ms: ^MatchState, 
	i: int, 
	s: int,
	e: int,
	matches: []Match,
) -> (err: Error) {
	if i >= ms.level {
		if i == 0 {
			matches[0] = { 0, e - s }
		} else {
			err = .Invalid_Capture_Index
		}
	} else {
		init := ms.capture[i].init 
		length := ms.capture[i].len

		switch length {
			case CAP_UNFINISHED: {
				err = .Unfinished_Capture
			}

			case CAP_POSITION: {
				matches[i] = { init - 1, init - 1 }
			}

			case: {
				matches[i] = { init, init + length }
			}
		}
	}

	return
}

push_captures :: proc(
	ms: ^MatchState,
	s: int,
	e: int,
	matches: []Match,
) -> (nlevels: int, err: Error) {
	nlevels = 1 if ms.level == 0 && s != -1 else ms.level

	for i in 0..<nlevels {
		push_onecapture(ms, i, s, e, matches) or_return
	}

	return
}

// SPECIALS := "^$*+?.([%-"
// all special characters inside a small ascii array
SPECIALS_TABLE := [256]u8 { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

// helper call to quick search for special characters
index_special :: proc(text: string) -> int {
	for i in 0..<len(text) {
		// TODO utf8
		if SPECIALS_TABLE[text[i]] == 1 {
			return i
		}
	}

	return -1
}

lmemfind :: proc(s1, s2: string) -> int {
	l1 := len(s1)
	l2 := len(s2)

	if l2 == 0 {
		return 0
	} else if l2 > l1 {
		return -1
	} else {
		init := strings.index_byte(s1, s2[0])
		end := init + l2

		for end <= l1 && init != -1 {
			init += 1

			if s1[init - 1:end] == s2 {
				return init - 1
			} else {
				next := strings.index_byte(s1[init:], s2[0])

				if next == -1 {
					return -1
				} else {
					init = init + next
					end = init + l2
				}
			}
		}
	}

	return -1
}

// find a pattern with in a haystack with an offset
// allow_memfind will speed up simple searches
find_aux :: proc(
	haystack: string, 
	pattern: string, 
	offset: int,
	allow_memfind: bool,
	matches: ^[MAXCAPTURES]Match,
) -> (captures: int, err: Error) {
	s := offset
	p := 0

	specials_idx := index_special(pattern)
	if allow_memfind && specials_idx == -1 {
		if index := lmemfind(haystack[s:], pattern); index != -1 {
			matches[0] = { index + s, index + s + len(pattern) }
			captures = 1
			return
		} else {
			return
		}
	}

	pattern := pattern
	anchor: bool
	if len(pattern) > 0 && pattern[0] == '^' {
		anchor = true
		pattern = pattern[1:]
	}

	ms := MatchState {
		src = haystack,
		pattern = pattern,
	}

	for {
		res := match(&ms, s, p) or_return

		if res != INVALID {
			// NOTE(Skytrias): first result is reserved for a full match
			matches[0] = { s, res }
			// rest are the actual captures
			captures = push_captures(&ms, -1, -1, matches[1:]) or_return
			captures += 1

			return
		}

		s += 1

		if !(s < len(ms.src) && !anchor) {
			break
		}
	}

	return
}

// iterative matching which returns the 0th/1st match
// rest has to be used from captures
gmatch :: proc(
	haystack: ^string,
	pattern: string,
	captures: ^[MAXCAPTURES]Match,
) -> (res: string, ok: bool) {
	if len(haystack) > 0 {
		length, err := find_aux(haystack^, pattern, 0, false, captures)

		if length != 0 && err == .OK {
			ok = true
			first := length > 1 ? 1 : 0
			cap := captures[first]
			res = haystack[cap.byte_start:cap.byte_end]
			haystack^ = haystack[cap.byte_end:]
		}
	} 

	return
}

// gsub with builder, replace patterns found with the replace content
gsub_builder :: proc(
	builder: ^strings.Builder,
	haystack: string,
	pattern: string,
	replace: string,
) -> string {
	// find matches
	captures: [MAXCAPTURES]Match
	haystack := haystack

	for {
		length, err := find_aux(haystack, pattern, 0, false, &captures)

		// done
		if length == 0 {
			break
		}

		if err != .OK {
			return {}
		}

		cap := captures[0]

		// write front till capture
		strings.write_string(builder, haystack[:cap.byte_start])

		// write replacements
		strings.write_string(builder, replace)

		// advance string till end
		haystack = haystack[cap.byte_end:]
	}

	strings.write_string(builder, haystack[:])
	return strings.to_string(builder^)
}

// uses temp builder to build initial string - then allocates the result
gsub_allocator :: proc(
	haystack: string,
	pattern: string,
	replace: string,
	allocator := context.allocator,
) -> string {
	builder := strings.builder_make(0, 256, context.temp_allocator)
	return gsub_builder(&builder, haystack, pattern, replace)
}

// call a procedure on every match in the haystack
gsub_with :: proc(
	haystack: string,
	pattern: string,
	data: rawptr,
	call: proc(data: rawptr, word: string),
) {
	// find matches
	captures: [MAXCAPTURES]Match
	haystack := haystack

	for {
		length, err := find_aux(haystack, pattern, 0, false, &captures)

		// done
		if length == 0 || err != .OK {
			break
		}

		cap := captures[0]

		word := haystack[cap.byte_start:cap.byte_end]
		call(data, word)

		// advance string till end
		haystack = haystack[cap.byte_end:]
	}
}

gsub :: proc { gsub_builder, gsub_allocator }

// iterative find with zeroth capture only
gfind :: proc(
	haystack: ^string,
	pattern: string,
	captures: ^[MAXCAPTURES]Match,
) -> (res: string, ok: bool) {
	if len(haystack) > 0 {
		length, err := find_aux(haystack^, pattern, 0, true, captures)

		if length != 0 && err == .OK {
			ok = true
			cap := captures[0]
			res = haystack[cap.byte_start:cap.byte_end]
			haystack^ = haystack[cap.byte_end:]
		}
	} 

	return
}