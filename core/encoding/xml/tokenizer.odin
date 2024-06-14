package encoding_xml

/*
	An XML 1.0 / 1.1 parser

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A from-scratch XML implementation, loosely modeled on the [spec](https://www.w3.org/TR/2006/REC-xml11-20060816).

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/


import "core:fmt"
import "core:unicode"
import "core:unicode/utf8"

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
	t.error_count = 0
	t.path = path

	advance_rune(t)
	if t.ch == utf8.RUNE_BOM {
		advance_rune(t)
	}
}

@(private)
offset_to_pos :: proc(t: ^Tokenizer, offset: int) -> Pos {
	line := t.line_count
	column := offset - t.line_offset + 1

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
		t.err(pos, msg, ..args)
	}
	t.error_count += 1
}

@(optimization_mode="speed")
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
				} else if r == utf8.RUNE_BOM && t.offset > 0 {
					error(t, t.offset, "illegal byte order mark")
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

peek_byte :: proc(t: ^Tokenizer, offset := 0) -> byte {
	if t.read_offset+offset < len(t.src) {
		#no_bounds_check return t.src[t.read_offset+offset]
	}
	return 0
}

@(optimization_mode="speed")
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

@(optimization_mode="speed")
is_letter :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		switch r {
		case '_':
			return true
		case 'A'..='Z', 'a'..='z':
			return true
		}
	}
	return unicode.is_letter(r)
}

is_valid_identifier_rune :: proc(r: rune) -> bool {
	if r < utf8.RUNE_SELF {
		switch r {
		case '_', '-', ':':        return true
		case 'A'..='Z', 'a'..='z': return true
		case '0'..='9':            return true
		case -1:                   return false
		}
	}

	if unicode.is_letter(r) || unicode.is_digit(r) {
		return true
	}
	return false
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
	offset     := t.offset
	namespaced := false

	for is_valid_identifier_rune(t.ch) {
		advance_rune(t)
		if t.ch == ':' {
			// A namespaced attr can have at most two parts, `namespace:ident`.
			if namespaced {
				break	
			}
			namespaced = true
		}
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

	return string(t.src[offset : t.offset - 1]), .None
}

// Skip CDATA
skip_cdata :: proc(t: ^Tokenizer) -> (err: Error) {
	if t.read_offset + len(CDATA_START) >= len(t.src) {
		// Can't be the start of a CDATA tag.
		return .None
	}

	if string(t.src[t.offset:][:len(CDATA_START)]) == CDATA_START {
		t.read_offset += len(CDATA_START)
		offset := t.offset

		cdata_scan: for {
			advance_rune(t)
			if t.ch < 0 {
				error(t, offset, "[scan_string] CDATA was not terminated\n")
				return .Premature_EOF
			}

			// Scan until the end of a CDATA tag.
			if t.read_offset + len(CDATA_END) < len(t.src) {
				if string(t.src[t.offset:][:len(CDATA_END)]) == CDATA_END {
					t.read_offset += len(CDATA_END)
					break cdata_scan
				}
			}
		}
	}
	return
}

@(optimization_mode="speed")
scan_string :: proc(t: ^Tokenizer, offset: int, close: rune = '<', consume_close := false, multiline := true) -> (value: string, err: Error) {
	err = .None

	loop: for {
		ch := t.ch

		switch ch {
		case -1:
			error(t, t.offset, "[scan_string] Premature end of file.\n")
			return "", .Premature_EOF

		case '<':
			if peek_byte(t) == '!' {
				if peek_byte(t, 1) == '[' {
					// Might be the start of a CDATA tag.
					skip_cdata(t) or_return
				} else if peek_byte(t, 1) == '-' && peek_byte(t, 2) == '-' {
					// Comment start. Eat comment.
					t.read_offset += 3
					_ = scan_comment(t) or_return
				}
			}

		case '\n':
			if !multiline {
				error(t, offset, string(t.src[offset : t.offset]))
				error(t, offset, "[scan_string] Not terminated\n")
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

peek :: proc(t: ^Tokenizer) -> (token: Token) {
	old  := t^
	token = scan(t)
	t^ = old
	return token
}

scan :: proc(t: ^Tokenizer, multiline_string := false) -> Token {
	skip_whitespace(t)

	offset := t.offset

	kind: Token_Kind
	err:  Error
	lit:  string
	pos := offset_to_pos(t, offset)

	switch ch := t.ch; true {
	case is_letter(ch):
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