package strlib

import "core:strings"

MAXCAPTURES :: 32

Capture :: struct {
	init: int,
	len: int,
}

Match :: struct {
	start, end: int,
}

Error :: enum {
	OK,
	OOB,
	Invalid_Capture_Index,
	Invalid_Pattern_Capture,
	Unfinished_Capture,
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

match_class :: proc(c: u8, cl: u8) -> (res: bool) {
	switch tolower(cl) {
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

isalpha :: proc(c: u8) -> bool {
	return ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z')
}

isdigit :: proc(c: u8) -> bool {
	return '0' <= c && c <= '9'
}

isalnum :: proc(c: u8) -> bool {
	return isalpha(c) || isdigit(c)
}

iscntrl :: proc(c: u8) -> bool {
	return c <= '\007' || (c >= '\010' && c <= '\017') || (c >= '\020' && c <= '\027') || (c >= '\030' && c <= '\037') || c == '\177'	
}

islower :: proc(c: u8) -> bool {
	return c >= 'a' && c <= 'z'
}

isupper :: proc(c: u8) -> bool {
	return c >= 'A' && c <= 'Z'
}

isgraph :: proc(c: u8) -> bool {
	return isdigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

ispunct :: proc(c: u8) -> bool {
	return (c >= '{' && c <= '~') || (c == '`') || (c >= '[' && c <= '_') || (c == '@') || (c >= ':' && c <= '?') || (c >= '(' && c <= '/') || (c >= '!' && c <= '\'')
}

isxdigit :: proc(c: u8) -> bool {
	return isdigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

isspace :: proc(c: u8) -> bool {
	return c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r' || c == ' '
}

// ascii safe
tolower :: proc(c: u8) -> u8 {
	if c >= 65 && c <= 90 { // upper case
		return c + 32
	}

	return c
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

classend :: proc(ms: ^MatchState, p: int) -> (int, Error) {
	ch := ms.pattern[p]
	p := p + 1

	switch ch {
		case L_ESC: {
			// if  > 0 {
			// 	fmt.eprintln("ERR classend: not enough pattern length")
			// 	return nil
			// }

			return p + 1, .OK
		}

		case '[': {
			if ms.pattern[p] == '^' {
				p += 1
			}

			// TODO double check
			for {
				ch := ms.pattern[p]

				if ch == L_ESC && p <= len(ms.pattern) {
					// skip escapes like '%'
					p += 1
				}

				if ms.pattern[p] == ']' {
					break
				}

				p += 1
			}

			return p + 1, .OK
		}

		case: {
			return p, .OK
		}
	}
}

matchbracketclass :: proc(ms: ^MatchState, c: u8, p, ec: int) -> bool {
	sig := true
	p := p

	if ms.pattern[p + 1] == '^' {
		p += 1
		sig = false
	}

	p += 1

	// while inside of class range
	for p < ec {
		ch := ms.pattern[p]

		if ms.pattern[p] == L_ESC {
			p += 1

			if match_class(c, ms.pattern[p]) {
				return sig
			}
		} else if ms.pattern[p + 1] == '-' && p + 2 < len(ms.pattern) {
			// e.g. [a-z] check
			if ms.pattern[p] <= c && c <= ms.pattern[p + 2] {
				return sig
			}

			p += 2 
		} else if ms.pattern[p] == c {
			return sig
		}

		p += 1
	}

	return !sig
}

singlematch :: proc(ms: ^MatchState, s, p, ep: int) -> bool {
	if s >= len(ms.src) {
		return false
	}

	switch ms.pattern[p] {
		case '.': return true
		case L_ESC: return match_class(ms.src[s], ms.pattern[p + 1])
		case '[': return matchbracketclass(ms, ms.src[s], p, ep - 1)
		case: return ms.src[s] == ms.pattern[p]
	}
}

// matchbalance :: proc(ms: ^MatchState, s, p: int) -> (int, Error) {
// 	s_begin := s
// 	s := s + 1
// 	cont := 0

// 	begin := ms.pattern[p]
// 	end := ms.pattern[p + 1]
// 	print("BALANCED between", rune(begin), "AND", rune(end))

// 	for s < len(ms.src) {
// 		ch := ms.src[s]
// 		print("\t", rune(ch))

// 		if ch == end {
// 			cont -= 1
// 			print("END", cont)

// 			if cont == 0 {
// 				print("BALANCED RET", s + 1, len(ms.src), ms.src[s_begin:s + 1])
// 				return s + 1
// 			}
// 		} else if ch == begin {
// 			cont += 1
// 			print("BEGIN", cont)
// 		}

// 		s += 1
// 	}

// 	print("OUT OF BALANCE", cont)
// 	// out of balance
// 	return 0, .
// }

max_expand :: proc(ms: ^MatchState, s, p, ep: int) -> (res: int, err: Error) {
	i := 0
	for singlematch(ms, s + i, p, ep) {
		i += 1
	}

	for i >= 0 {
		result := match(ms, s + i, ep + 1) or_return

		if result != INVALID {
			// print("SET", result)
			return result, .OK
		}

		i -= 1
	}

	return INVALID, .OK
}

min_expand :: proc(ms: ^MatchState, s, p, ep: int) -> (res: int, err: Error) {
	s := s

	for {
		result := match(ms, s, ep + 1) or_return

		if result != INVALID {
			return result, .OK
		} else if singlematch(ms, s, p, ep) {
			s += 1
		} else {
			return INVALID, .OK
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

	switch ms.pattern[p] {
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
					// res := matchbalance(ms, s, p + 2)

					// if data, ok := res.?; ok {
					// 	// s = data
					// 	// eg after %b()
					// 	// print("SUCCESS")
					// 	return patt_match(ms, s, p + 4)
					// }

				}

				// frontier
				case 'f': {
					// p += 2
					
					// if ms.pattern[p] != '[' {
					// 	print("missing '[' after %f in pattern")
					// 	return nil
					// }

					// ep := classend(ms, p).?
					// previous := 0 if s == 0 else s - 1

					// if !matchbracketclass(ms, ms.src[previous], p, ep - 1) && 
					// 	matchbracketclass(ms, ms.src[s], p, ep) {
					// 	return patt_match(ms, s, ep)
					// }

					// return nil
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
			// print("PATT DEF", rune(ms.src[s]), rune(ms.pattern[p]))
		}
	}

	return s, .OK
}

match_default :: proc(ms: ^MatchState, s, p: int) -> (unused: int, err: Error) {
	s := s
	ep := classend(ms, p) or_return
	// ch := s < len(ms.src) ? rune(ms.src[s]) : 0

	if !singlematch(ms, s, p, ep) {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0
		// print("+++", rune(epc))

		if epc == '*' || epc == '?' || epc == '-' {
			return match(ms, s, ep + 1)
		} else {
			s = INVALID
		}
	} else {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0
		// print("~~~", ch, rune(epc))

		switch epc {
			case '?': {
				result := match(ms, s + 1, ep + 1) or_return
				
				if result != INVALID {
					s = result
				} else {
					return match(ms, s, ep + 1)
				}
			}

			case '+': {
				s = max_expand(ms, s + 1, p, ep) or_return
			}

			case '*': {
				s = max_expand(ms, s, p, ep) or_return
			}

			case '-': {
				s = min_expand(ms, s, p, ep) or_return
			}

			case: {
				return match(ms, s + 1, ep)
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
			res = haystack[cap.start:cap.end]
			haystack^ = haystack[cap.end:]
		}
	} 

	return
}

// gsub with builder
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
		strings.write_string(builder, haystack[:cap.start])

		// write replacements
		strings.write_string(builder, replace)

		// advance string till end
		haystack = haystack[cap.end:]
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

gsub :: proc { gsub_builder, gsub_allocator }

// iterative find with first capture only
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
			res = haystack[cap.start:cap.end]
			haystack^ = haystack[cap.end:]
		}
	} 

	return
}