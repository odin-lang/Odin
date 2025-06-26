package text_match

import "base:runtime"
import "core:unicode"
import "core:unicode/utf8"
import "core:strings"

MAX_CAPTURES :: 32

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
	Match_Invalid,
}

L_ESC :: '%'
CAP_POSITION :: -2
CAP_UNFINISHED :: -1
INVALID :: -1

Match_State :: struct {
	src: string,
	pattern: string,
	level: int,
	capture: [MAX_CAPTURES]Capture,
}

match_class :: proc(c: rune, cl: rune) -> (res: bool) {
	switch unicode.to_lower(cl) {
	case 'a': res = is_alpha(c)
	case 'c': res = is_cntrl(c)
	case 'd': res = is_digit(c)
	case 'g': res = is_graph(c)
	case 'l': res = is_lower(c)
	case 'p': res = is_punct(c)
	case 's': res = is_space(c)
	case 'u': res = is_upper(c)
	case 'w': res = is_alnum(c)
	case 'x': res = is_xdigit(c)
	case: return cl == c
	}

	return is_lower(cl) ? res : !res
}

is_alpha :: unicode.is_alpha
is_digit :: unicode.is_digit
is_lower :: unicode.is_lower
is_upper :: unicode.is_upper
is_punct :: unicode.is_punct
is_space :: unicode.is_space
is_cntrl :: unicode.is_control

is_alnum :: proc(c: rune) -> bool {
	return unicode.is_alpha(c) || unicode.is_digit(c)
}

is_graph :: proc(c: rune) -> bool {
	return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') || unicode.is_digit(c)
}

is_xdigit :: proc(c: rune) -> bool {
	return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') || unicode.is_digit(c)
}

// find the first utf8 charater and its size, return an error if the character is an error
utf8_peek :: proc(bytes: string) -> (c: rune, size: int, err: Error) {
	c, size = utf8.decode_rune_in_string(bytes)

	if c == utf8.RUNE_ERROR {
		err = .Rune_Error
	}

	return
}

// find the first utf8 charater and its size and advance the index
// return an error if the character is an error
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

check_capture :: proc(ms: ^Match_State, l: rune) -> (int, Error) {
	l := int(l - '1')
	
	if l < 0 || l >= ms.level || ms.capture[l].len == CAP_UNFINISHED {
		return 0, .Invalid_Capture_Index
	}

	return l, .OK
}

capture_to_close :: proc(ms: ^Match_State) -> (int, Error) {
	level := ms.level - 1

	for level >= 0 {
		if ms.capture[level].len == CAP_UNFINISHED {
			return level, .OK
		}

		level -= 1
	}

	return 0, .Invalid_Pattern_Capture
}

class_end :: proc(ms: ^Match_State, p: int) -> (step: int, err: Error) {
	step = p
	ch := utf8_advance(ms.pattern, &step) or_return

	switch ch {
	case L_ESC: 
		if step == len(ms.pattern) {
			err = .Malformed_Pattern
			return
		}

		utf8_advance(ms.pattern, &step) or_return

	case '[': 
		// fine with step by 1
		if step + 1 < len(ms.pattern) && ms.pattern[step] == '^' {
			step += 1
		}

		// run till end is reached
		for {
			if step == len(ms.pattern) {
				err = .Malformed_Pattern
				return
			}

			if ms.pattern[step] == ']' {
				break
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

	return
}

match_bracket_class :: proc(ms: ^Match_State, c: rune, p, ec: int) -> (sig: bool, err: Error) {
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

single_match :: proc(ms: ^Match_State, s, p, ep: int) -> (matched: bool, schar_size: int, err: Error) {
	if s >= len(ms.src) {
		return
	}

	pchar, psize := utf8_peek(ms.pattern[p:]) or_return
	schar, ssize := utf8_peek(ms.src[s:]) or_return
	schar_size = ssize

	switch pchar {
	case '.': matched = true
	case L_ESC: 
		pchar_next, _ := utf8_peek(ms.pattern[p + psize:]) or_return
		matched = match_class(schar, pchar_next)
	case '[': matched = match_bracket_class(ms, schar, p, ep - 1) or_return
	case: matched = schar == pchar
	}

	return
}

match_balance :: proc(ms: ^Match_State, s, p: int) -> (unused: int, err: Error) {
	if p >= len(ms.pattern) - 1 {
		return INVALID, .Invalid_Pattern_Capture
	}


	schar, ssize := utf8_peek(ms.src[s:]) or_return
	pchar, psize := utf8_peek(ms.pattern[p:]) or_return

	// skip until the src and pattern match
	if schar != pchar {
		return INVALID, .OK
	}

	cont := 1
	s := s
	s += ssize
	begin := pchar
	end, _ := utf8_peek(ms.pattern[p + psize:]) or_return

	for s < len(ms.src) {
		ch := utf8_advance(ms.src, &s) or_return

		switch ch{
		case end:
			cont -= 1

			if cont == 0 {
				return s, .OK
			}

		case begin:
			cont += 1
		}
	}

	return INVALID, .OK
}

max_expand :: proc(ms: ^Match_State, s, p, ep: int) -> (res: int, err: Error) {
	m := s

	// count up matches
	for {
		matched, size := single_match(ms, m, p, ep) or_return
		
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

min_expand :: proc(ms: ^Match_State, s, p, ep: int) -> (res: int, err: Error) {
	s := s

	for {
		result := match(ms, s, ep + 1) or_return

		if result != INVALID {
			return result, .OK
		} else {
			// TODO receive next step maybe?
			matched, rune_size := single_match(ms, s, p, ep) or_return

			if matched {
				s += rune_size
			} else {
				return INVALID, .OK
			}
		}
	}
}

start_capture :: proc(ms: ^Match_State, s, p, what: int) -> (res: int, err: Error) {
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

end_capture :: proc(ms: ^Match_State, s, p: int) -> (res: int, err: Error) {
	l := capture_to_close(ms) or_return
	
	// TODO double check, could do string as int index
	ms.capture[l].len = s - ms.capture[l].init

	res = match(ms, s, p) or_return
	if res == INVALID {
		ms.capture[l].len = CAP_UNFINISHED
	}
	return
}

match_capture :: proc(ms: ^Match_State, s: int, char: rune) -> (res: int, err: Error) {
	index := check_capture(ms, char) or_return
	length := ms.capture[index].len

	if len(ms.src) - s >= length {
		return s + length, .OK
	}

	return INVALID, .OK
}

match :: proc(ms: ^Match_State, s, p: int) -> (unused: int, err: Error) {
	s := s
	p := p

	if p == len(ms.pattern) {
		return s, .OK
	}

	// NOTE we can walk by ascii steps if we know the characters are ascii
	char, _ := utf8_peek(ms.pattern[p:]) or_return
	switch char {
	case '(': 
		if p + 1 < len(ms.pattern) && ms.pattern[p + 1] == ')' {
			s = start_capture(ms, s, p + 2, CAP_POSITION) or_return
		} else {
			s = start_capture(ms, s, p + 1, CAP_UNFINISHED) or_return
		}

	case ')': 
		s = end_capture(ms, s, p + 1) or_return

	case '$': 
		if p + 1 != len(ms.pattern) {
			return match_default(ms, s, p)
		} 

		if len(ms.src) != s {
			s = INVALID
		}

	case L_ESC: 
		// stop short patterns like "%" only
		if p + 1 >= len(ms.pattern) {
			err = .OOB
			return
		}

		switch ms.pattern[p + 1] {
		// balanced string
		case 'b': 
			s = match_balance(ms, s, p + 2) or_return

			if s != INVALID {
				// eg after %b()
				return match(ms, s, p + 4)
			}

		// frontier
		case 'f':
			p += 2
			
			if ms.pattern[p] != '[' {
				return INVALID, .Invalid_Pattern_Capture
			}

			ep := class_end(ms, p) or_return
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

			m1 := match_bracket_class(ms, previous, p, ep - 1) or_return
			m2 := match_bracket_class(ms, current, p, ep - 1) or_return

			if !m1 && m2 {
				return match(ms, s, ep)
			}

			s = INVALID

		// capture group
		case '0'..<'9':
			s = match_capture(ms, s, rune(ms.pattern[p + 1])) or_return

			if s != INVALID {
				return match(ms, s, p + 2)
			}

		case: return match_default(ms, s, p)
	}

	case: 
		return match_default(ms, s, p)
	}

	return s, .OK
}

match_default :: proc(ms: ^Match_State, s, p: int) -> (unused: int, err: Error) {
	s := s
	ep := class_end(ms, p) or_return
	single_matched, ssize := single_match(ms, s, p, ep) or_return

	if !single_matched {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0

		switch epc {
		case '*', '?', '-': return match(ms, s, ep + 1)
		case: s = INVALID
		}
	} else {
		epc := ep < len(ms.pattern) ? ms.pattern[ep] : 0

		switch epc {
		case '?':
			result := match(ms, s + ssize, ep + 1) or_return
			
			if result != INVALID {
				s = result
			} else {
				return match(ms, s, ep + 1)
			}

		case '+': s = max_expand(ms, s + ssize, p, ep) or_return
		case '*': s = max_expand(ms, s, p, ep) or_return
		case '-': s = min_expand(ms, s, p, ep) or_return
		case: return match(ms, s + ssize, ep)
		}
	}

	return s, .OK
}

push_onecapture :: proc(ms: ^Match_State,  i: int,  s: int, e: int, matches: []Match) -> (err: Error) {
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
		case CAP_UNFINISHED: err = .Unfinished_Capture
		case CAP_POSITION: matches[i] = { init, init + 1 }
		case: matches[i] = { init, init + length }
		}
	}

	return
}

push_captures :: proc(
	ms: ^Match_State,
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
SPECIALS_TABLE := [256]bool {
	'^' = true,
	'$' = true,
	'*' = true,
	'+' = true,
	'?' = true,
	'.' = true,
	'(' = true,
	'[' = true,
	'%' = true,
	'-' = true,
}

// helper call to quick search for special characters
index_special :: proc(text: string) -> int {
	for i in 0..<len(text) {
		if SPECIALS_TABLE[text[i]] {
			return i
		}
	}

	return -1
}

lmem_find :: proc(s1, s2: string) -> int {
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
	matches: ^[MAX_CAPTURES]Match,
) -> (captures: int, err: Error) {
	s := offset
	p := 0

	specials_idx := index_special(pattern)
	if allow_memfind && specials_idx == -1 {
		if index := lmem_find(haystack[s:], pattern); index != -1 {
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

	ms := Match_State {
		src = haystack,
		pattern = pattern,
	}

	for {
		res := match(&ms, s, p) or_return

		if res != INVALID {
			// disallow non advancing match
			if s == res {
				err = .Match_Invalid
			} 
			
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
// assumes captures is zeroed on first iteration
// resets captures to zero on last iteration
gmatch :: proc(
	haystack: ^string,
	pattern: string,
	captures: ^[MAX_CAPTURES]Match,
) -> (res: string, ok: bool) {
	haystack^ = haystack[captures[0].byte_end:]
	if len(haystack) > 0 {
		length, err := find_aux(haystack^, pattern, 0, false, captures)

		if length != 0 && err == .OK {
			ok = true
			first := length > 1 ? 1 : 0
			cap := captures[first]
			res = haystack[cap.byte_start:cap.byte_end]
		}
	} 
	if !ok {
		captures^ = {}
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
	captures: [MAX_CAPTURES]Match
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

Gsub_Proc :: proc(
	// optional passed data
	data: rawptr, 
	// word match found
	word: string, 
	// current haystack for found captures
	haystack: string, 
	// found captures - empty for no captures
	captures: []Match,
)

// call a procedure on every match in the haystack
gsub_with :: proc(
	haystack: string,
	pattern: string,
	data: rawptr,
	call: Gsub_Proc,
) {
	// find matches
	captures: [MAX_CAPTURES]Match
	haystack := haystack

	for {
		length := find_aux(haystack, pattern, 0, false, &captures) or_break
		// done
		if length == 0 {
			break
		}

		cap := captures[0]

		word := haystack[cap.byte_start:cap.byte_end]
		call(data, word, haystack, captures[1:length])

		// advance string till end
		haystack = haystack[cap.byte_end:]
	}
}

gsub :: proc { gsub_builder, gsub_allocator }

// iterative find with zeroth capture only
// assumes captures is zeroed on first iteration
// resets captures to zero on last iteration
gfind :: proc(
	haystack: ^string,
	pattern: string,
	captures: ^[MAX_CAPTURES]Match,
) -> (res: string, ok: bool) {
	haystack^ = haystack[captures[0].byte_end:]
	if len(haystack) > 0 {
		length, err := find_aux(haystack^, pattern, 0, true, captures)

		if length != 0 && err == .OK {
			ok = true
			cap := captures[0]
			res = haystack[cap.byte_start:cap.byte_end]
		}
	} 
	if !ok {
		captures^ = {}
	}
	return
}

// rebuilds a pattern into a case insensitive pattern
pattern_case_insensitive_builder :: proc(
	builder: ^strings.Builder, 
	pattern: string,
) -> (res: string) {
	p := pattern
	last_percent: bool

	for len(p) > 0 {
		char, size := utf8.decode_rune_in_string(p)

		if unicode.is_alpha(char) && !last_percent {
			// write character class in manually
			strings.write_byte(builder, '[')
			strings.write_rune(builder, unicode.to_lower(char))
			strings.write_rune(builder, unicode.to_upper(char))
			strings.write_byte(builder, ']')
		} else {
			strings.write_rune(builder, char)
		}

		last_percent = char == L_ESC 
		p = p[size:]
	}

	return strings.to_string(builder^)
}

pattern_case_insensitive_allocator :: proc(
	pattern: string, 
	cap: int = 256,
	allocator := context.allocator,
) -> (res: string) {
	builder := strings.builder_make(0, cap, context.temp_allocator)
	return pattern_case_insensitive_builder(&builder, pattern)	
}

pattern_case_insensitive :: proc { pattern_case_insensitive_builder, pattern_case_insensitive_allocator }

// Matcher helper struct that stores optional data you might want to use or not
// as lua is far more dynamic this helps dealing with too much data
// this also allows use of find/match/gmatch at through one struct
Matcher :: struct {
	haystack: string,
	pattern: string,
	captures: [MAX_CAPTURES]Match,
	captures_length: int,
	offset: int,
	err: Error,

	// changing content for iterators
	iter: string,
	iter_index: int,
}

// init using haystack & pattern and an optional byte offset
matcher_init :: proc(haystack, pattern: string, offset: int = 0) -> (res: Matcher) {
	res.haystack = haystack
	res.pattern = pattern
	res.offset = offset
	res.iter = haystack
	return
}

// find the first match and return the byte start / end position in the string, true on success
matcher_find :: proc(matcher: ^Matcher) -> (start, end: int, ok: bool) #no_bounds_check {
	matcher.captures_length, matcher.err = find_aux(
		matcher.haystack, 
		matcher.pattern, 
		matcher.offset, 
		true, 
		&matcher.captures,
	)
	ok = matcher.captures_length > 0 && matcher.err == .OK
	match := matcher.captures[0]
	start = match.byte_start
	end = match.byte_end
	return
}

// find the first match and return the matched word, true on success
matcher_match :: proc(matcher: ^Matcher) -> (word: string, ok: bool) #no_bounds_check {
	matcher.captures_length, matcher.err = find_aux(
		matcher.haystack, 
		matcher.pattern, 
		matcher.offset, 
		false, 
		&matcher.captures,
	)
	ok = matcher.captures_length > 0 && matcher.err == .OK
	match := matcher.captures[0]
	word = matcher.haystack[match.byte_start:match.byte_end]
	return
}

// get the capture at the "correct" spot, as spot 0 is reserved for the first match
matcher_capture :: proc(matcher: ^Matcher, index: int, loc := #caller_location) -> string #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index + 1, MAX_CAPTURES - 1)
	cap := matcher.captures[index + 1]
	return matcher.haystack[cap.byte_start:cap.byte_end]
}

// get the raw match out of the captures, skipping spot 0
matcher_capture_raw :: proc(matcher: ^Matcher, index: int, loc := #caller_location) -> Match #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index + 1, MAX_CAPTURES - 1)
	return matcher.captures[index + 1]
}

// alias
matcher_gmatch :: matcher_match_iter

// iteratively match the haystack till it cant find any matches
matcher_match_iter :: proc(matcher: ^Matcher) -> (res: string, index: int, ok: bool) {
	if len(matcher.iter) > 0 {
		matcher.captures_length, matcher.err = find_aux(
			matcher.iter, 
			matcher.pattern, 
			matcher.offset, 
			false, 
			&matcher.captures,
		)

		if matcher.captures_length != 0 && matcher.err == .OK {
			ok = true
			first := matcher.captures_length > 1 ? 1 : 0
			match := matcher.captures[first]
			
			// output
			res = matcher.iter[match.byte_start:match.byte_end]
			index = matcher.iter_index
			
			// advance
			matcher.iter_index += 1
			matcher.iter = matcher.iter[match.byte_end:]
		}
	}

	return
}

// get a slice of all valid captures above the first match
matcher_captures_slice :: proc(matcher: ^Matcher) -> []Match {
	return matcher.captures[1:matcher.captures_length]
}
