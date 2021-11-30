package xml

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

CDATA_START :: "<![CDATA["
CDATA_END   :: "]]>"

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

advance_rune :: proc(using t: ^Tokenizer) {
	if read_offset < len(src) {
		offset = read_offset
		if ch == '\n' {
			line_offset = offset
			line_count += 1
		}
		r, w := rune(src[read_offset]), 1
		switch {
		case r == 0:
			error(t, t.offset, "illegal character NUL")
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune_in_string(src[read_offset:])
			if r == utf8.RUNE_ERROR && w == 1 {
				error(t, t.offset, "illegal UTF-8 encoding")
			} else if r == utf8.RUNE_BOM && offset > 0 {
				error(t, t.offset, "illegal byte order mark")
			}
		}
		read_offset += w
		ch = r
	} else {
		offset = len(src)
		if ch == '\n' {
			line_offset = offset
			line_count += 1
		}
		ch = -1
	}
}

peek_byte :: proc(t: ^Tokenizer, offset := 0) -> byte {
	if t.read_offset+offset < len(t.src) {
		return t.src[t.read_offset+offset]
	}
	return 0
}

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
		case '0'..'9':             return true
		}
	}

	if unicode.is_digit(r) || unicode.is_letter(r) {
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
			/*
				A namespaced attr can have at most two parts, `namespace:ident`.
			*/
			if namespaced {
				break	
			}
			namespaced = true
		}
	}
	return string(t.src[offset : t.offset])
}

scan_string :: proc(t: ^Tokenizer, offset: int, close: rune = '<', consume_close := false) -> (value: string, err: Error) {
	err = .None
	in_cdata := false

	loop: for {
		ch := t.ch

		switch ch {
		case -1:
			error(t, t.offset, "[scan_string] Premature end of file.\n")
			return "", .Premature_EOF

		case '<':
			/*
				Might be the start of a CDATA tag.
			*/
			if t.read_offset + len(CDATA_START) < len(t.src) {
				if string(t.src[t.offset:][:len(CDATA_START)]) == CDATA_START {
					in_cdata = true
				}
			}

		case ']':
			/*
				Might be the end of a CDATA tag.
			*/
			if t.read_offset + len(CDATA_END) < len(t.src) {
				if string(t.src[t.offset:][:len(CDATA_END)]) == CDATA_END {
					in_cdata = false
				}
			}

		case '\n':
			if !in_cdata {
				error(t, offset, string(t.src[offset : t.offset]))
				error(t, offset, "[scan_string] Not terminated\n")
				err = .Invalid_Tag_Value
				break loop	
			}
		}

		if ch == close && !in_cdata {
			/*
				If it's not a CDATA tag, it's the end of this body.
			*/
			break loop
		}

		advance_rune(t)
	}

	lit := string(t.src[offset : t.offset])
	if consume_close {
		advance_rune(t)
	}

	/*
		TODO: Handle decoding escape characters and unboxing CDATA.
	*/

	return lit, err
}

peek :: proc(t: ^Tokenizer) -> (token: Token) {
	old  := t^
	token = scan(t)
	t^ = old
	return token
}

scan :: proc(t: ^Tokenizer) -> Token {
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
			lit, err = scan_string(t, t.offset, ch, true)
			if err == .None {
				kind = .String
			} else {
				kind = .Invalid
			}

		case '\n':
			lit = "\n"

		case '\\':
			token := scan(t)
			if token.pos.line == pos.line {
				error(t, token.pos.offset, "expected a newline after \\")
			}
			return token

		case:
			if ch != utf8.RUNE_BOM {
				// error(t, t.offset, "illegal character '%r': %d", ch, ch)
			}
			kind = .Invalid
		}
	}

	if lit == "" {
		lit = string(t.src[offset : t.offset])
	}
	return Token{kind, lit, pos}
}