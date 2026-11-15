package diff

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

// How text is split into tokens.
Token :: enum u8 {
	Line, // up to and including "\n"; the last line may have no "\n"
	Word, // a run of letters, digits, and '_', a run of whitespace, or any other single rune
	Rune, // one rune; each byte of invalid UTF-8 is a rune of its own
}

/*
	What to ignore when comparing tokens. Each flag applies to every token's text. A final "\n" is never
	ignored: a last line without one still differs from the same line with one.
*/
Text_Flag :: enum u8 {
	Ignore_CR,             // "a\r\n" equals "a\n"
	Ignore_Trailing_Space, // whitespace at the end, before any final "\n"
	Ignore_All_Space,      // all whitespace, apart from a final "\n"
	Ignore_Case,           // simple per-rune case folding
}
Text_Flags :: bit_set[Text_Flag; u8]

// A diff of two strings. It owns only `changes`. `a` and `b` must outlive it.
Text_Diff :: struct {
	a, b:    string,
	token:   Token,
	changes: Changes,
}

// A run of whole tokens as one substring. `.Equal` and `.Delete` spans come from `a`. `.Insert` spans come from `b`.
Span :: struct {
	op:   Op,
	text: string,
}

Span_Iterator :: struct {
	d:            Text_Diff,
	edits:        Edit_Iterator,
	a_pos, b_pos: int, // byte offset of the next token on each side
}


// Returns the number of tokens in `s`: the `n` or `m` used to size `Changes` and scratch.
@(require_results)
token_count :: proc(s: string, token: Token) -> (count: int) {
	if token == .Line {
		count = strings.count(s, "\n")
		if len(s) > 0 && s[len(s) - 1] != '\n' {
			count += 1
		}
		return
	}
	if token == .Rune {
		// NOTE(bill): Count each byte of an invalid UTF-8 as a rune
		return utf8.rune_count_in_string(s)
	}
	for pos := 0; pos < len(s); pos = _token_end(s, pos, token) {
		count += 1
	}
	return
}

/*
	Returns the scratch bytes `diff_text_buffer` needs for `n` and `m` tokens.

	The token IDs, and each line's indent with `.Indent_Heuristic`, last the whole diff. The token starts and
	the interning table share the rest with the algorithm, one after the other.
*/
@(require_results)
scratch_size_text :: proc "contextless" (n, m: int, opts := Options{}) -> int {
	tokens := n + m
	kept   := scratch_bytes(i32, tokens)
	if .Indent_Heuristic in opts.flags {
		kept += scratch_bytes(u8, tokens)
	}
	interning := scratch_bytes(i32, n + 1) + scratch_bytes(i32, m + 1) + intern_scratch_size(tokens)
	return SCRATCH_ALIGN + kept + max(interning, algorithm_scratch_size(n, m, tokens, opts))
}

// Diffs `a` and `b` into `changes`, sized for `token_count(a, token)` and `token_count(b, token)`. Never allocates.
@(require_results)
diff_text_buffer :: proc(
	a, b:    string,
	changes: Changes,
	scratch: []byte,
	token := Token.Line,
	flags := Text_Flags{},
	opts  := Options{},
	loc   := #caller_location,
) -> Text_Diff {
	@(require_results)
	text_equal_exact :: proc(x, y: string, _: rawptr) -> bool {
		return x == y
	}

	@(require_results)
	text_hash_exact :: proc(x: string, _: rawptr) -> u64 {
		x := x
		return u64(intrinsics.type_hasher_proc(string)(&x, 0))
	}


	n, m := changes.n, changes.m

	assert(len(a) < int(max(i32)), "text too long to diff", loc)
	assert(len(b) < int(max(i32)), "text too long to diff", loc)
	assert(n + m < int(max(i32)), "too many tokens to intern", loc)

	s := Scratch{buf = scratch}
	ids := scratch_take(&s, i32, n + m, loc)

	indents: []u8
	if .Indent_Heuristic in opts.flags {
		assert(token == .Line, ".Indent_Heuristic needs a line diff", loc)
		indents = scratch_take(&s, u8, n + m, loc)
	}

	interning_start := s.pos
	a_tokens := Text_Tokens{a, scratch_take(&s, i32, n + 1, loc)}
	b_tokens := Text_Tokens{b, scratch_take(&s, i32, m + 1, loc)}

	_token_starts(a, token, a_tokens.starts, loc)
	_token_starts(b, token, b_tokens.starts, loc)
	if indents != nil {
		for k in 0..<n {
			indents[k] = line_indent(token_at(a_tokens, k))
		}
		for k in 0..<m {
			indents[n + k] = line_indent(token_at(b_tokens, k))
		}
	}
	table := scratch_take(&s, Intern_Slot, intern_table_len(n + m), loc)

	flags := flags
	id_count: int
	if flags == {} {
		id_count = intern(a_tokens, b_tokens, string, text_equal_exact, text_hash_exact, nil, ids, table)
	} else {
		id_count = intern(a_tokens, b_tokens, string, _text_equal, _text_hash, &flags, ids, table)
	}
	s.pos = interning_start

	diff_interned_scratch(ids[:n], ids[n:], indents, id_count, changes, &s, opts, loc)
	return {a, b, token, changes}
}

@(require_results)
diff_text :: proc(
	a, b:                string,
	allocator:           runtime.Allocator,
	transient_allocator: runtime.Allocator,
	token := Token.Line,
	flags := Text_Flags{},
	opts  := Options{},
	loc   := #caller_location,
) -> (d: Text_Diff, err: runtime.Allocator_Error) {
	n := token_count(a, token)
	m := token_count(b, token)
	c, scratch := _changes_and_scratch_make(
		n,
		m,
		scratch_size_text(n, m, opts),
		allocator,
		transient_allocator,
		loc,
	) or_return
	d = diff_text_buffer(a, b, c, scratch, token, flags, opts, loc)
	delete(scratch, transient_allocator, loc)
	return
}

// Frees `d` with the allocator it was made with. The texts it refers to are not its own.
text_diff_destroy :: proc(d: Text_Diff, allocator: runtime.Allocator, loc := #caller_location) {
	changes_destroy(d.changes, allocator, loc)
}


@(require_results)
span_iterator_make :: proc "contextless" (d: Text_Diff) -> Span_Iterator {
	return {d = d, edits = edit_iterator_make(d.changes)}
}

/*
	Iterates over spans in order. Never allocates.

	Usage:
		it := diff.span_iterator_make(d)
		for s in diff.span_iterate(&it) {
			...
		}
*/
@(require_results)
span_iterate :: proc(it: ^Span_Iterator) -> (s: Span, ok: bool) {
	e := edit_iterate(&it.edits) or_return
	d := it.d

	a_start := it.a_pos
	b_start := it.b_pos
	it.a_pos = _skip_tokens(d.a, it.a_pos, e.a_hi - e.a_lo, d.token)
	it.b_pos = _skip_tokens(d.b, it.b_pos, e.b_hi - e.b_lo, d.token)

	switch e.op {
	case .Equal, .Delete:
		s = {e.op, d.a[a_start:it.a_pos]}
	case .Insert:
		s = {e.op, d.b[b_start:it.b_pos]}
	}
	return s, true
}


// Returns where the token starting at `s[pos]` ends.
@(require_results)
_token_end :: proc(s: string, pos: int, token: Token) -> int {
	Word_Class :: enum u8 {
		Other,
		Word,
		Space,
	}

	@(require_results)
	word_class :: #force_inline proc(r: rune) -> Word_Class {
		switch r {
		case '_', 'a'..='z', 'A'..='Z', '0'..='9':
			return .Word
		case '\t', '\n', '\v', '\f', '\r', ' ':
			return .Space
		}
		switch {
		case r < utf8.RUNE_SELF:
			return .Other
		case unicode.is_letter(r) || unicode.is_digit(r):
			return .Word
		case unicode.is_space(r):
			return .Space
		}
		return .Other
	}


	switch token {
	case .Line:
		if i := strings.index_byte(s[pos:], '\n'); i >= 0 {
			return pos + i + 1
		}
		return len(s)

	case .Rune:
		if s[pos] < utf8.RUNE_SELF {
			return pos + 1
		}
		_, width := utf8.decode_rune_in_string(s[pos:])
		return pos + width

	case .Word:
		// NOTE(bill): ASCII without decoding because most text will be mostly ASCII in practice with what gets diffed
		r, width := rune(s[pos]), 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s[pos:])
		}
		class := word_class(r)
		end   := pos + width
		if class == .Other {
			return end
		}
		for end < len(s) {
			next, next_width := rune(s[end]), 1
			if next >= utf8.RUNE_SELF {
				next, next_width = utf8.decode_rune_in_string(s[end:])
			}
			if word_class(next) != class {
				break
			}
			end += next_width
		}
		return end
	}
	return len(s)
}

// Returns where the `count` tokens from `s[pos]` end.
@(require_results)
_skip_tokens :: proc(s: string, pos, count: int, token: Token) -> int {
	pos := pos
	for _ in 0..<count {
		pos = _token_end(s, pos, token)
	}
	return pos
}

// Fills `starts` with where each token of `s` starts, then `len(s)`. `starts` must hold exactly one more than the tokens.
_token_starts :: proc(s: string, token: Token, starts: []i32, loc := #caller_location) {
	k := 0
	for pos := 0; pos < len(s); pos = _token_end(s, pos, token) {
		assert(k < len(starts) - 1, "changes sized for different inputs", loc)
		starts[k] = i32(pos)
		k += 1
	}
	assert(k == len(starts) - 1, "changes sized for different inputs", loc)
	starts[k] = i32(len(s))
}


// Compares the runes `Text_Reader` gives, with `user_data` pointing at the `Text_Flags`.
@(require_results)
_text_equal :: proc(x, y: string, user_data: rawptr) -> bool {
	flags := (^Text_Flags)(user_data)^
	rx := text_reader_make(x, flags)
	ry := text_reader_make(y, flags)
	for {
		cx, ok_x := text_reader_next(&rx)
		cy, ok_y := text_reader_next(&ry)
		if ok_x != ok_y || cx != cy {
			return false
		}
		if !ok_x {
			return true
		}
	}
}

// FNV-1a over the runes `Text_Reader` gives, with `user_data` pointing at the `Text_Flags`.
@(require_results)
_text_hash :: proc(x: string, user_data: rawptr) -> u64 {
	flags := (^Text_Flags)(user_data)^
	r := text_reader_make(x, flags)
	h := u64(0xcbf29ce484222325)
	for c in text_reader_next(&r) {
		h = (h ~ u64(c)) * 0x100000001b3
	}
	return h
}

// Reads a token's runes with `Text_Flags` applied: whitespace and carriage returns dropped, case folded.
@(private)
Text_Reader :: struct {
	s:       string,
	pos:     int,
	end:     int,  // where the runes to read stop, before any final "\n" and whatever is ignored before it
	newline: bool, // a final "\n" is still to be read
	flags:   Text_Flags,
}

@(private, require_results)
text_reader_make :: proc(s: string, flags: Text_Flags) -> (r: Text_Reader) {
	r.s, r.flags, r.end = s, flags, len(s)
	if r.end > 0 && s[r.end - 1] == '\n' {
		r.newline = true
		r.end -= 1
	}
	if .Ignore_CR in flags && r.newline && r.end > 0 && s[r.end - 1] == '\r' {
		r.end -= 1
	}
	if flags & {.Ignore_Trailing_Space, .Ignore_All_Space} != nil {
		for r.end > 0 {
			c, width := utf8.decode_last_rune_in_string(s[:r.end])
			if !unicode.is_space(c) {
				break
			}
			r.end -= width
		}
	}
	return
}

@(private, require_results)
text_reader_next :: proc(r: ^Text_Reader) -> (c: rune, ok: bool) {
	// The smallest rune that `c` equals under simple case folding. Runes that fold together fold to the same one
	@(require_results)
	fold_rune :: proc(c: rune) -> rune {
		if c < utf8.RUNE_SELF {
			if 'a' <= c && c <= 'z' {
				return c - ('a' - 'A')
			}
			return c
		}
		smallest := c
		for f := unicode.simple_fold(c); f != c; f = unicode.simple_fold(f) {
			smallest = min(smallest, f)
		}
		return smallest
	}


	for r.pos < r.end {
		width: int
		c, width = utf8.decode_rune_in_string(r.s[r.pos:r.end])
		r.pos += width
		if .Ignore_All_Space in r.flags && unicode.is_space(c) {
			continue
		}
		if .Ignore_Case in r.flags {
			c = fold_rune(c)
		}
		return c, true
	}
	if r.newline {
		r.newline = false
		return '\n', true
	}
	return
}
