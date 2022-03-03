package text_template_scan

import "core:fmt"
import "core:unicode"
import "core:unicode/utf8"
import "core:strings"

Pos :: distinct int

Token_Kind :: enum {
	Error,
	EOF,
	
	Comment,
	Space,
	
	Left_Delim,
	Right_Delim,	
	
	Identifier,	
	Field,
	Left_Paren,
	Right_Paren,
		
	Bool,
	Char,
	Number,
	Pipe,
	Raw_String,
	String,
	Text,
	Variable,
	Operator,

	Declare, // :=
	Assign,  // -
	
	_Keyword,
	Dot,
	Block,
	Break,
	Continue,
	Define,
	Else,
	End,
	For,
	If,
	Include,
	Nil,
	With,
}


keywords := map[string]Token_Kind {
	"."        = .Dot,
	"block"    = .Block,
	"break"    = .Break,
	"continue" = .Continue,
	"define"   = .Define,
	"else"     = .Else,
	"end"      = .End,
	"for"      = .For,
	"if"       = .If,
	"include"  = .Include,
	"nil"      = .Nil,
	"with"     = .With,
}

Token :: struct {
	kind:  Token_Kind,
	value: string,
	pos:   Pos,
	line:  int,
}

token_to_string :: proc(using tok: Token, allocator := context.temp_allocator) -> string {
	context.allocator = allocator
	switch {
	case kind == .EOF:
		return fmt.tprint("EOF")
	case kind == .Error:
		return fmt.tprint(value)
	case kind > ._Keyword:
		return fmt.tprintf("<%s>", value)
	case len(value) > 10:
		return fmt.tprintf("%.10q...", value)
	}
	return fmt.tprintf("%q", value)
}

Scanner :: struct {
	name:          string,
	input:         string,
	left_delim:    string,
	right_delim:   string,
	pos:           Pos,
	start:         Pos,
	width:         Pos,
	tokens:        [dynamic]Token,
	paren_depth:   int,
	line:          int,
	start_line:    int,
	emit_comments: bool,
}

next :: proc(s: ^Scanner) -> rune {
	if int(s.pos) >= len(s.input) {
		s.width = 0
		return utf8.RUNE_EOF
	}
	r, w := utf8.decode_rune_in_string(s.input[s.pos:])
	s.width = Pos(w)
	s.pos += s.width
	if r == '\n' {
		s.line += 1
	}
	return r
}

backup :: proc(s: ^Scanner) {
	s.pos -= s.width
	if s.width == 1 && s.input[s.pos] == '\n' {
		s.line -= 1
	}
}

peek :: proc(s: ^Scanner) -> rune {
	r := next(s)
	backup(s)
	return r
}

emit :: proc(s: ^Scanner, kind: Token_Kind) {
	append(&s.tokens, Token{
		kind = kind,
		pos = s.start,
		line = s.start_line,
		value = s.input[s.start:s.pos],
	})
	s.start = s.pos
	s.start_line = s.line
}

ignore :: proc(s: ^Scanner) {
	s.line += strings.count(s.input[s.start:s.pos], "\n")
	s.start = s.pos
	s.start_line = s.line
}

accept :: proc(s: ^Scanner, valid: string) -> bool {
	if strings.contains_rune(valid, next(s)) >= 0 {
		return true
	}
	backup(s)
	return false
}
accept_run :: proc(s: ^Scanner, valid: string) {
	for strings.contains_rune(valid, next(s)) >= 0 {
		// Okay
	}
	backup(s)
}


// State procedures

DEFAULT_LEFT_DELIM :: "{{"
DEFAULT_RIGHT_DELIM :: "}}"

LEFT_COMMENT  :: "/*"
RIGHT_COMMENT :: "*/"


init :: proc(s: ^Scanner, name, input: string, left: string = "", right: string = "",
             emit_comments: bool = false) -> ^Scanner {
	s.name          = name
	s.input         = input
	s.left_delim    = left  if left  != "" else DEFAULT_LEFT_DELIM
	s.right_delim   = right if right != "" else DEFAULT_RIGHT_DELIM
	s.emit_comments = emit_comments
	reset(s)
	return s
}

destroy :: proc(s: ^Scanner) {
	delete(s.tokens)
	s.tokens = {}
}


reset :: proc(s: ^Scanner) {
	clear(&s.tokens)
	s.pos   = 0
	s.start = 0
	s.width = 0
	s.paren_depth = 0
	s.line        = 1
	s.start_line  = 1
}


// Finite State Machine Scanning

Scan_State :: enum {
	None,

	Comment,
	Space,

	Identifier,
	Field,
	Left_Delim,
	Right_Delim,

	Char,
	Number,
	Raw_String,
	String,
	Text,
	Variable,

	Inside_Action,
}

step :: proc(s: ^Scanner, state: Scan_State) -> Scan_State {
	scan_error :: proc(s: ^Scanner, value: string) -> Scan_State {
		append(&s.tokens, Token{
			kind = .Error,
			pos = s.start,
			line = s.start_line,
			value = value,
		})
		return nil
	}
	scan_variable_or_field :: proc(s: ^Scanner, kind: Token_Kind) -> Scan_State {
		if at_terminator(s) {
			if kind == .Variable {
				emit(s, kind)
			} else {
				emit(s, .Dot)
			}
			return .Inside_Action
		}
		for {
			r := next(s)
			if !is_alpha_numeric(r) {
				backup(s)
				break
			}
		}
		if !at_terminator(s) {
			return scan_error(s, "bad character")
		}
		emit(s, kind)
		return .Inside_Action
	}

	switch state {
	case .None:
		return nil

	case .Comment:
		s.pos += Pos(len(LEFT_COMMENT))
		i := strings.index(s.input[s.pos:], RIGHT_COMMENT)
		if i < 0 {
			return scan_error(s, "unclosed comment")
		}
		s.pos += Pos(i + len(RIGHT_COMMENT))
		delim, trim_space := at_right_delim(s)
		if !delim {
			return scan_error(s, "comment ends before closing delimiter")
		}
		if s.emit_comments {
			emit(s, .Comment)
		}
		if trim_space {
			s.pos += TRIM_MARKER_LEN
		}
		s.pos += Pos(len(s.right_delim))
		if trim_space {
			s.pos += left_trim_length(s.input[s.pos:])
		}
		ignore(s)
		return .Text

	case .Space:
		space_count: int
		for {
			r := peek(s)
			if !is_space(r) {
				break
			}
			next(s)
			space_count += 1
		}

		if has_right_trim_marker(s.input[s.pos-1:]) && strings.has_prefix(s.input[s.pos-1+TRIM_MARKER_LEN:], s.right_delim) {
			backup(s)
			if space_count == 1 {
				return .Right_Delim
			}
		}
		emit(s, .Space)
		return .Inside_Action

	case .Identifier:
		identifier_loop: for {
			r := next(s)
			if is_alpha_numeric(r) {
				// Okay
			} else {
				backup(s)
				word := s.input[s.start:s.pos]
				if !at_terminator(s) {
					return scan_error(s, "bad character")
				}

				if kw := keywords[word]; kw > ._Keyword {
					emit(s, kw)
				} else if word == "true" || word == "false" {
					emit(s, .Bool)
				} else {
					emit(s, .Identifier)
				}
				break identifier_loop
			}
		}
		return .Inside_Action
	case .Field:
		return scan_variable_or_field(s, .Field)

	case .Left_Delim:
		s.pos += Pos(len(s.left_delim))
		trim_space := has_left_trim_marker(s.input[s.pos:])
		after_marker := TRIM_MARKER_LEN if trim_space else 0
		if strings.has_prefix(s.input[s.pos+after_marker:], LEFT_COMMENT) {
			s.pos += after_marker
			ignore(s)
			return .Comment
		}
		emit(s, .Left_Delim)
		s.pos += after_marker
		ignore(s)
		s.paren_depth = 0
		return .Inside_Action

	case .Right_Delim:
		trim_space := has_right_trim_marker(s.input[s.pos:])
		if trim_space {
			s.pos += TRIM_MARKER_LEN
			ignore(s)
		}
		s.pos += Pos(len(s.right_delim))
		emit(s, .Right_Delim)
		if trim_space {
			s.pos += left_trim_length(s.input[s.pos:])
			ignore(s)
		}
		return .Text

	case .Char:
		char_loop: for {
			switch next(s) {
			case '\\':
				if r := next(s); r != utf8.RUNE_EOF && r != '\n' {
					break
				}
				fallthrough
			case utf8.RUNE_EOF, '\n':
				return scan_error(s, "unterminated character constant")
			case '\'':
				break char_loop
			}
		}
		emit(s, .Char)
		return .Inside_Action

	case .Number:
		accept(s, "+-")
		digits := "0123456789_"
		if accept(s, "0") {
			switch {
			case accept(s, "bB"):
				digits = "01_"
			case accept(s, "oO"):
				digits = "01234567_"
			case accept(s, "xX"):
				digits = "0123456789ABCDEFabcdef_"
			}
		}
		accept_run(s, digits)
		if accept(s, ".") {
			accept_run(s, digits)
		}
		if len(digits) == 10+1 && accept(s, "eE") {
			accept(s, "+-")
			accept_run(s, digits)
		}
		if is_alpha_numeric(peek(s)) {
			next(s)
			return scan_error(s, "bad number syntax")
		}
		emit(s, .Number)
		return .Inside_Action

	case .Raw_String:
		raw_string_loop: for {
			switch next(s) {
			case utf8.RUNE_EOF:
				return scan_error(s, "unterminated raw quoted string")
			case '`':
				break raw_string_loop
			}
		}
		emit(s, .Raw_String)
		return .Inside_Action

	case .String:
		string_loop: for {
			switch next(s) {
			case '\\':
				if r := next(s); r != utf8.RUNE_EOF && r != '\n' {
					break
				}
				fallthrough
			case utf8.RUNE_EOF, '\n':
				return scan_error(s, "unterminated quoted string")
			case '"':
				break string_loop
			}
		}
		emit(s, .String)
		return .Inside_Action

	case .Text:
		s.width = 0
		if x := strings.index(s.input[s.pos:], s.left_delim); x >= 0 {
			ldn := Pos(len(s.left_delim))
			s.pos += Pos(x)
			trim_length := Pos(0)
			if has_left_trim_marker(s.input[s.pos+ldn:]) {
				trim_length = right_trim_length(s.input[s.start:s.pos])
			}
			s.pos -= trim_length
			if s.pos > s.start {
				s.line += strings.count(s.input[s.start:s.pos], "\n")
				emit(s, .Text)
			}
			s.pos += trim_length
			ignore(s)
			return .Left_Delim
		}
		s.pos = Pos(len(s.input))
		// EOF
		if s.pos > s.start {
			s.line += strings.count(s.input[s.start:s.pos], "\n")
			emit(s, .Text)
		}
		emit(s, .EOF)

	case .Variable:
		if at_terminator(s) {
			emit(s, .Variable)
			return .Inside_Action
		}
		return scan_variable_or_field(s, .Variable)

	case .Inside_Action:
		if delim, _ := at_right_delim(s); delim {
			if s.paren_depth == 0 {
				return .Right_Delim
			}
			return scan_error(s, "unclosed left paren")
		}

		rp := peek(s)
		switch r := next(s); {
		case r == utf8.RUNE_EOF:
			return scan_error(s, "unclosed action")
		case is_space(r):
			backup(s) // Just in case of " -}}"
			return .Space
		case r == '.':
			// Look for a '.field'
			if s.pos < Pos(len(s.input)) {
				if r := s.input[s.pos]; r < '0' || r > '9' {
					return .Field
				}
			}
			// it's a number
			fallthrough

		case (r == '+' || r == '-') && ('0' <= rp && rp <= '9'):
			fallthrough
		case '0' <= r && r <= '9':
			backup(s)
			return .Number
		case r == '+', r == '-', r == '*', r == '/':
			emit(s, .Operator)
		case is_alpha_numeric(r):
			backup(s)
			return .Identifier
		case r == '|':
			emit(s, .Pipe)
		case r == '"':
			return .String
		case r == '`':
			return .Raw_String
		case r == '\'':
			return .Char
		case r == '(':
			emit(s, .Left_Paren)
			s.paren_depth += 1
		case r == ')':
			emit(s, .Right_Paren)
			s.paren_depth -= 1
			if s.paren_depth < 0 {
				return scan_error(s, "unexpected right parenthesis ')'")
			}
		case r == '$':
			return .Variable
		case r == ':':
			if next(s) != '=' {
				return scan_error(s, "expected :=")
			}
			emit(s, .Declare)
		case r == '=':
			emit(s, .Assign)
		case r <= unicode.MAX_ASCII && unicode.is_print(r):
			emit(s, .Char)
		case:
			return scan_error(s, "unrecognized character in action")
		}

		return .Inside_Action
	}
	return nil
}



run :: proc(s: ^Scanner) {
	state := Scan_State.Text
	for state != nil {
		state = step(s, state)
	}
}

@private TRIM_MARKER :: '-'
@private TRIM_MARKER_LEN :: Pos(2) // includes space

is_space :: proc(r: rune) -> bool {
	switch r {
	case ' ', '\t', '\r', '\n':
		return true
	}
	return false
}

is_alpha_numeric :: proc(r: rune) -> bool {
	return r == '_' || unicode.is_letter(r) || unicode.is_digit(r)
}

left_trim_length :: proc(s: string) -> Pos {
	return Pos(len(s) - len(strings.trim_left_proc(s, is_space)))
}
right_trim_length :: proc(s: string) -> Pos {
	return Pos(len(s) - len(strings.trim_right_proc(s, is_space)))
}

has_left_trim_marker :: proc(s: string) -> bool {
	return len(s) >= 2 && s[0] == TRIM_MARKER && is_space(rune(s[1]))
}

has_right_trim_marker :: proc(s: string) -> bool {
	return len(s) >= 2 && is_space(rune(s[0])) && s[1] == TRIM_MARKER
}

at_right_delim :: proc(s: ^Scanner) -> (delim, trim_spaces: bool) {
	if has_right_trim_marker(s.input[s.pos:]) && strings.has_prefix(s.input[s.pos+TRIM_MARKER_LEN:], s.right_delim) {
		delim = true
		trim_spaces = true
		return
	}
	if strings.has_prefix(s.input[s.pos:], s.right_delim) {
		delim = true
		trim_spaces = false
		return
	}
	delim = false
	trim_spaces = false
	return
}

at_terminator :: proc(s: ^Scanner) -> bool {
	r := peek(s)
	if is_space(r) {
		return true
	}
	
	switch r {
	case utf8.RUNE_EOF, '.', ',', '(', ')', '|', ':':
		return true
	}
	
	rd, _ := utf8.decode_rune_in_string(s.right_delim)
	return rd == r
}