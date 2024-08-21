package regex_tokenizer

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "core:text/regex/common"
import "core:unicode/utf8"

Token_Kind :: enum {
	Invalid,
	EOF,

	Rune,
	Wildcard,

	Alternate,

	Concatenate,

	Repeat_Zero,
	Repeat_Zero_Non_Greedy,
	Repeat_One,
	Repeat_One_Non_Greedy,

	Repeat_N,

	Optional,
	Optional_Non_Greedy,

	Rune_Class,

	Open_Paren,
	Open_Paren_Non_Capture,
	Close_Paren,

	Anchor_Start,
	Anchor_End,

	Word_Boundary,
	Non_Word_Boundary,
}

Token :: struct {
	kind: Token_Kind,
	text: string,
	pos: int,
}

Tokenizer :: struct {
	flags: common.Flags,
	src: string,

	ch: rune,
	offset: int,
	read_offset: int,

	last_token_kind: Token_Kind,
	held_token: Token,
	error_state: Error,
	paren_depth: int,
}

Error :: enum {
	None,
	Illegal_Null_Character,
	Illegal_Codepoint,
	Illegal_Byte_Order_Mark,
}

init :: proc(t: ^Tokenizer, str: string, flags: common.Flags) {
	t.src = str
	t.flags = flags
	t.error_state = advance_rune(t)
}

peek_byte :: proc(t: ^Tokenizer, offset := 0) -> byte {
	if t.read_offset+offset < len(t.src) {
		return t.src[t.read_offset+offset]
	}
	return 0
}

advance_rune :: proc(t: ^Tokenizer) -> (err: Error) {
	if t.error_state != nil {
		return t.error_state
	}

	if t.read_offset < len(t.src) {
		t.offset = t.read_offset
		r, w := rune(t.src[t.read_offset]), 1
		switch {
		case r == 0:
			err = .Illegal_Null_Character
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune(t.src[t.read_offset:])
			if r == utf8.RUNE_ERROR && w == 1 {
				err = .Illegal_Codepoint
			} else if r == utf8.RUNE_BOM && t.offset > 0 {
				err = .Illegal_Byte_Order_Mark
			}
		}
		t.read_offset += w
		t.ch = r
	} else {
		t.offset = len(t.src)
		t.ch = -1
	}

	t.error_state = err

	return
}

@require_results
scan_class :: proc(t: ^Tokenizer) -> (str: string, ok: bool) {
	start := t.read_offset

	for {
		advance_rune(t)
		if t.ch == -1 || t.error_state != nil {
			return "", false
		}

		if t.ch == '\\' {
			advance_rune(t)
			continue
		}

		if t.ch == ']' {
			return t.src[start:t.offset], true
		}
	}

	unreachable()
}

@require_results
scan_repeat :: proc(t: ^Tokenizer) -> (str: string, ok: bool) {
	start := t.read_offset

	for {
		advance_rune(t)
		if t.ch == -1 {
			return "", false
		}
		if t.ch == '}' {
			return t.src[start:t.offset], true
		}
	}

	unreachable()
}

@require_results
scan_non_greedy :: proc(t: ^Tokenizer) -> bool {
	if peek_byte(t) == '?' {
		advance_rune(t)
		return true
	}

	return false
}

scan_comment :: proc(t: ^Tokenizer) {
	for {
		advance_rune(t)
		switch t.ch {
		case -1:
			return
		case '\n':
			// UNIX newline.
			advance_rune(t)
			return
		case '\r':
			// Mac newline.
			advance_rune(t)
			if t.ch == '\n' {
				// Windows newline.
				advance_rune(t)
			}
			return
		}
	}
}

@require_results
scan_non_capture_group :: proc(t: ^Tokenizer) -> bool {
	if peek_byte(t) == '?' && peek_byte(t, 1) == ':' {
		advance_rune(t)
		advance_rune(t)
		return true
	}

	return false
}

@require_results
scan :: proc(t: ^Tokenizer) -> (token: Token) {
	kind: Token_Kind
	lit: string
	pos := t.offset

	defer {
		t.last_token_kind = token.kind
	}

	if t.error_state != nil {
		t.error_state = nil
		return { .Invalid, "", pos }
	}

	if t.held_token != {} {
		popped := t.held_token
		t.held_token = {}
		
		return popped
	}

	ch_loop: for {
		switch t.ch {
		case -1:
			return { .EOF, "", pos }

		case '\\':
			advance_rune(t)

			if t.ch == -1 {
				return { .EOF, "", pos }
			}

			pos = t.offset

			// @MetaCharacter
			// NOTE: These must be kept in sync with the compiler.
			DIGIT_CLASS :: "0-9"
			SPACE_CLASS :: "\t\n\f\r "
			WORD_CLASS  :: "0-9A-Z_a-z"

			switch t.ch {
			case 'b': kind = .Word_Boundary
			case 'B': kind = .Non_Word_Boundary

			case 'f': kind = .Rune; lit = "\f"
			case 'n': kind = .Rune; lit = "\n"
			case 'r': kind = .Rune; lit = "\r"
			case 't': kind = .Rune; lit = "\t"

			case 'd': kind = .Rune_Class; lit = DIGIT_CLASS
			case 's': kind = .Rune_Class; lit = SPACE_CLASS
			case 'w': kind = .Rune_Class; lit = WORD_CLASS
			case 'D': kind = .Rune_Class; lit = "^" + DIGIT_CLASS
			case 'S': kind = .Rune_Class; lit = "^" + SPACE_CLASS
			case 'W': kind = .Rune_Class; lit = "^" + WORD_CLASS
			case:
				kind = .Rune
				lit = t.src[t.offset:t.read_offset]
			}

		case '.':
			kind = .Wildcard

		case '|': kind = .Alternate

		case '*': kind = .Repeat_Zero_Non_Greedy if scan_non_greedy(t) else .Repeat_Zero
		case '+': kind = .Repeat_One_Non_Greedy  if scan_non_greedy(t) else .Repeat_One
		case '?': kind = .Optional_Non_Greedy    if scan_non_greedy(t) else .Optional

		case '[':
			if text, ok := scan_class(t); ok {
				kind = .Rune_Class
				lit = text
			} else {
				kind = .EOF
			}

		case '{':
			if text, ok := scan_repeat(t); ok {
				kind = .Repeat_N
				lit = text
			} else {
				kind = .EOF
			}

		case '(':
			kind = .Open_Paren_Non_Capture if scan_non_capture_group(t) else .Open_Paren
			t.paren_depth += 1
		case ')':
			kind = .Close_Paren
			t.paren_depth -= 1

		case '^': kind = .Anchor_Start
		case '$':
			kind = .Anchor_End

		case:
			if .Ignore_Whitespace in t.flags {
				switch t.ch {
				case ' ', '\r', '\n', '\t', '\f':
					advance_rune(t)
					continue ch_loop
				case:
					break
				}
			}
			if t.ch == '#' && t.paren_depth == 0 {
				scan_comment(t)
				continue ch_loop
			}

			kind = .Rune
			lit = t.src[t.offset:t.read_offset]
		}

		break ch_loop
	}

	if t.error_state != nil {
		t.error_state = nil
		return { .Invalid, "", pos }
	}

	advance_rune(t)

	// The following set of rules dictate where Concatenate tokens are
	// automatically inserted.
	#partial switch kind {
	case
	.Close_Paren,
	.Alternate,
	.Optional,    .Optional_Non_Greedy,
	.Repeat_Zero, .Repeat_Zero_Non_Greedy,
	.Repeat_One,  .Repeat_One_Non_Greedy,
	.Repeat_N:
		// Never prepend a Concatenate before these tokens.
		break
	case:
		#partial switch t.last_token_kind {
		case
		.Invalid,
		.Open_Paren, .Open_Paren_Non_Capture,
		.Alternate:
			// Never prepend a Concatenate token when the _last token_ was one
			// of these.
			break
		case:
			t.held_token = { kind, lit, pos }
			return { .Concatenate, "", pos }
		}
	}

	return { kind, lit, pos }
}
