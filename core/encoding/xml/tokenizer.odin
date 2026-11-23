package encoding_xml

/*
	An XML 1.0 / 1.1 parser

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	A from-scratch XML implementation, loosely modeled on the [spec](https://www.w3.org/TR/2006/REC-xml11-20060816).

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/


import "core:fmt"
import "core:unicode/utf8"
import "core:strings"

Error_Handler :: #type proc(pos: Pos, fmt: string, args: ..any)

Token :: struct {
	kind: Token_Kind,
	text: string,
	pos:  Pos,
}

Pos :: struct {
	file:   string,
	offset: int, // starting at 0
	line:   int, // starting at 1
	column: int, // starting at 1
}

Token_Kind :: enum {
	Invalid,

	Ident,
	Literal,
	Rune,
	String,

	Double_Quote,  // "
	Single_Quote,  // '
	Colon,         // :

	Eq,            // =
	Lt,            // <
	Gt,            // >
	Exclaim,       // !
	Question,      // ?
	Hash,          // #
	Slash,         // /
	Dash,          // -

	Open_Bracket,  // [
	Close_Bracket, // ]

	EOF,
}

CDATA_START   :: "<![CDATA["
CDATA_END     :: "]]>"

COMMENT_START :: "<!--"
COMMENT_END   :: "-->"

Tokenizer :: struct {
	// Immutable data
	path: string,
	src:  string,
	err:  Error_Handler,

	// Tokenizing state
	ch:          rune,
	offset:      int,
	read_offset: int,
	line_offset: int,
	line_count:  int,

	clean_offset:      int,
	clean_line_offset: int,

	// Mutable data
	error_count: int,
}

init :: proc(t: ^Tokenizer, src: string, path: string, err: Error_Handler = default_error_handler) {
	t.src = src
	t.err = err
	t.ch = ' '
	t.offset = 0
	t.read_offset = 0
	t.line_offset = 0
	t.line_count = len(src) > 0 ? 1 : 0
	t.clean_offset = 0
	t.clean_line_offset = 0
	t.error_count = 0
	t.path = path

	advance_rune(t)
	if t.ch == utf8.RUNE_BOM {
		advance_rune(t)
	}
}

@(private)
normalize_input :: proc(buf: []u8) -> (length: int, illegal: rune, ok: bool) {
	w, r := 0, 0
	n := len(buf)
	#no_bounds_check for r < n {
		c := buf[r]
		switch {
		case c >= 0x20 && c < utf8.RUNE_SELF, c == '\n', c == '\t':
			if w != r {
				buf[w] = c
			}
			r += 1
			w += 1
		case c == '\r':
			buf[w] = '\n'
			r += 1
			w += 1
			if r < n && buf[r] == '\n' {
				r += 1
			}
		case c < 0x20:
			return w, rune(c), false
		case:
			ch, size := utf8.decode_rune(buf[r:])
			if ch == utf8.RUNE_ERROR && size == 1 || ch == 0xfffe || ch == 0xffff {
				return w, ch, false
			}
			if w != r {
				copy(buf[w:], buf[r:][:size])
			}
			r += size
			w += size
		}
	}
	return w, 0, true
}

@(private)
report_illegal_input :: proc(handler: Error_Handler, path: string, normalized: []u8, illegal: rune) {
	if handler == nil {
		return
	}
	text := string(normalized)
	line_start := strings.last_index_byte(text, '\n') + 1
	pos := Pos{
		file   = path,
		offset = len(text),
		line   = strings.count(text, "\n") + 1,
		column = len(text) - line_start + 1,
	}
	if illegal == utf8.RUNE_ERROR {
		handler(pos, "Invalid UTF-8 encoding\n")
	} else {
		handler(pos, "Illegal character U+%04X\n", u32(illegal))
	}
}

@(private)
offset_to_pos :: proc(t: ^Tokenizer, offset: int) -> Pos {
	line := t.line_count
	line_offset := t.line_offset
	if offset < line_offset {
		line -= strings.count(t.src[offset:line_offset], "\n")
		if offset < t.clean_offset {
			line_offset = strings.last_index_byte(t.src[:offset], '\n') + 1
		} else if nl := strings.last_index_byte(t.src[t.clean_offset:offset], '\n'); nl >= 0 {
			line_offset = t.clean_offset + nl + 1
		} else {
			line_offset = t.clean_line_offset
		}
	}
	column := offset - line_offset + 1

	return Pos {
		file = t.path,
		offset = offset,
		line = line,
		column = column,
	}
}

default_error_handler :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

error :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
	pos := offset_to_pos(t, offset)
	if t.err != nil {
		t.err(pos=pos, fmt=msg, args=args)
	}
	t.error_count += 1
}

@(optimization_mode="favor_size")
advance_rune :: proc(t: ^Tokenizer) {
	#no_bounds_check {
		/*
			Already bounds-checked here.
		*/
		if t.read_offset < len(t.src) {
			t.offset = t.read_offset
			if t.ch == '\n' {
				t.line_offset = t.offset
				t.line_count += 1
			}
			r, w := rune(t.src[t.read_offset]), 1
			switch {
			case r == 0:
				error(t, t.offset, "illegal character NUL")
			case r >= utf8.RUNE_SELF:
				r, w = #force_inline utf8.decode_rune_in_string(t.src[t.read_offset:])
				if r == utf8.RUNE_ERROR && w == 1 {
					error(t, t.offset, "illegal UTF-8 encoding")
				}
			}
			t.read_offset += w
			t.ch = r
		} else {
			t.offset = len(t.src)
			if t.ch == '\n' {
				t.line_offset = t.offset
				t.line_count += 1
			}
			t.ch = -1
		}
	}
}

@(private)
jump_to :: proc(t: ^Tokenizer, offset: int) {
	skipped := t.src[t.offset:offset]
	if lines := strings.count(skipped, "\n"); lines > 0 {
		t.line_count += lines
		t.line_offset = t.offset + strings.last_index_byte(skipped, '\n') + 1
	}
	t.read_offset = offset
	t.ch = 0
	advance_rune(t)
}

peek_byte :: proc(t: ^Tokenizer, offset := 0) -> byte {
	if t.read_offset+offset < len(t.src) {
		#no_bounds_check return t.src[t.read_offset+offset]
	}
	return 0
}

@(private)
is_space :: #force_inline proc(r: rune) -> bool {
	return r == ' ' || r == '\t' || r == '\n' || r == '\r'
}

@(private)
expect_no_space :: proc(t: ^Tokenizer) -> (err: Error) {
	if is_space(t.ch) {
		error(t, t.offset, "Unexpected whitespace\n")
		return .Unexpected_Token
	}
	return .None
}

@(optimization_mode="favor_size")
skip_whitespace :: proc(t: ^Tokenizer) {
	for {
		switch t.ch {
		case ' ', '\t', '\r', '\n':
			advance_rune(t)
		case:
			return
		}
	}
}

@(optimization_mode="favor_size")
is_letter :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		switch r {
		case 'A'..='Z', 'a'..='z', '_', ':':
			return true
		}
		return false
	}
	switch r {
	case 0xc0..=0xd6, 0xd8..=0xf6, 0xf8..=0x2ff, 0x370..=0x37d, 0x37f..=0x1fff, 0x200c..=0x200d,
	     0x2070..=0x218f, 0x2c00..=0x2fef, 0x3001..=0xd7ff, 0xf900..=0xfdcf, 0xfdf0..=0xfffd, 0x10000..=0xeffff:
		return true
	}
	return false
}

is_valid_identifier_rune :: proc(r: rune) -> bool {
	switch r {
	case '-', '.', '0'..='9', 0xb7, 0x300..=0x36f, 0x203f..=0x2040:
		return true
	}
	return is_letter(r)
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
	offset := t.offset

	for is_valid_identifier_rune(t.ch) {
		advance_rune(t)
	}
	return string(t.src[offset : t.offset])
}

/*
	A comment ends when we see -->, preceded by a character that's not a dash.
	"For compatibility, the string "--" (double-hyphen) must not occur within comments."

	See: https://www.w3.org/TR/2006/REC-xml11-20060816/#dt-comment

	Thanks to the length (4) of the comment start, we also have enough lookback,
	and the peek at the next byte asserts that there's at least one more character
	that's a `>`.
*/
scan_comment :: proc(t: ^Tokenizer) -> (comment: string, err: Error) {
	offset := t.offset

	for {
		advance_rune(t)
		ch := t.ch

		if ch < 0 {
			error(t, offset, "[parse] Comment was not terminated\n")
			return "", .Unclosed_Comment
		}

		if string(t.src[t.offset - 1:][:2]) == "--" {
			if peek_byte(t) == '>' {
				break
			} else {
				error(t, t.offset - 1, "Invalid -- sequence in comment.\n")
				return "", .Invalid_Sequence_In_Comment
			}
		}
	}

	expect(t, .Dash)
	expect(t, .Gt)

	return string(t.src[offset : t.offset - 3]), .None
}

// Skip CDATA
skip_cdata :: proc(t: ^Tokenizer) -> (err: Error) {
	if s := string(t.src[t.offset:]); !strings.has_prefix(s, CDATA_START) {
		return .None
	}

	offset := t.offset
	end    := strings.index(t.src[offset + len(CDATA_START):], CDATA_END)
	if end < 0 {
		error(t, offset, "[skip_cdata] CDATA was not terminated\n")
		return .Premature_EOF
	}
	jump_to(t, offset + len(CDATA_START) + end + len(CDATA_END))
	return .None
}

@(optimization_mode="favor_size")
scan_string :: proc(t: ^Tokenizer, offset: int, close: rune = '<', consume_close := false, multiline := true, stop_at_comments := false) -> (value: string, err: Error) {
	err = .None

	loop: for {
		ch := t.ch

		switch ch {
		case -1:
			error(t, t.offset, "[scan_string] Premature end of file.\n")
			return "", .Premature_EOF

		case '<':
			rest := t.src[t.offset:]
			if strings.has_prefix(rest, CDATA_START) {
				// Might be the start of a CDATA tag.
				skip_cdata(t) or_return
				continue loop
			} else if !stop_at_comments && strings.has_prefix(rest, COMMENT_START) {
				// Comment start. Eat comment.
				jump_to(t, t.offset + len(COMMENT_START))
				_ = scan_comment(t) or_return
				continue loop
			}

		case ']':
			if close == '<' && strings.has_prefix(t.src[t.offset:], CDATA_END) {
				error(t, t.offset, "[scan_string] `]]>` is not allowed in text\n")
				return "", .Unexpected_Token
			}

		case '\n':
			if !multiline {
				error(t, offset, "[scan_string] Not terminated: %q\n", t.src[offset : t.offset])
				err = .Invalid_Tag_Value
				break loop	
			}
		}

		if t.ch == close {
			// If it's not a CDATA or comment, it's the end of this body.
			break loop
		}
		advance_rune(t)
	}

	// Strip trailing whitespace.
	lit := string(t.src[offset : t.offset])

	end := len(lit)
	eat: for ; end > 0; end -= 1 {
		ch := lit[end - 1]
		switch ch {
		case ' ', '\t', '\r', '\n':
		case:
			break eat
		}
	}
	lit = lit[:end]

	if consume_close {
		advance_rune(t)
	}
	return lit, err
}

peek :: #force_inline proc(t: ^Tokenizer) -> (token: Token) {
	tmp := t^
	return scan(&tmp)
}

scan :: proc(t: ^Tokenizer, multiline_string := false) -> Token {
	skip_whitespace(t)

	offset := t.offset

	kind: Token_Kind
	err:  Error
	lit:  string
	pos := #force_inline offset_to_pos(t, offset)

	switch ch := t.ch; true {
	case #force_inline is_letter(ch):
		lit = scan_identifier(t)
		kind = .Ident

	case:
		advance_rune(t)
		switch ch {
		case -1:
			kind = .EOF

		case '<': kind = .Lt
		case '>': kind = .Gt
		case '!': kind = .Exclaim
		case '?': kind = .Question
		case '=': kind = .Eq
		case '#': kind = .Hash
		case '/': kind = .Slash
		case '-': kind = .Dash
		case ':': kind = .Colon
		case '[': kind = .Open_Bracket
		case ']': kind = .Close_Bracket

		case '"', '\'':
			kind = .Invalid

			lit, err = scan_string(t, t.offset, ch, true, multiline_string)
			if err == .None {
				kind = .String
			}

		case '\n':
			lit = "\n"

		case:
			kind = .Invalid
		}
	}

	if kind != .String && lit == "" {
		lit = string(t.src[offset : t.offset])
	}

	return Token{kind, lit, pos}
}
