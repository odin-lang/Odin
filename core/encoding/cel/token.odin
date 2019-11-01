package cel

import "core:fmt"
import "core:unicode/utf8"

using Kind :: enum {
	Illegal,
	EOF,
	Comment,

	_literal_start,
		Ident,
		Integer,
		Float,
		Char,
		String,
	_literal_end,

	_keyword_start,
		True,  // true
		False, // false
		Nil,   // nil
	_keyword_end,


	_operator_start,
		Question, // ?

		And,   // and
		Or,    // or

		Add,   // +
		Sub,   // -
		Mul,   // *
		Quo,   // /
		Rem,   // %

		Not,   // !

		Eq,    // ==
		NotEq, // !=
		Lt,    // <
		Gt,    // >
		LtEq,  // <=
		GtEq,  // >=

		At,    // @
	_operator_end,

	_punc_start,
		Assign, // =

		Open_Paren,    // (
		Close_Paren,   // )
		Open_Bracket,  // [
		Close_Bracket, // ]
		Open_Brace,    // {
		Close_Brace,   // }

		Colon,     // :
		Semicolon, // ;
		Comma,     // ,
		Period,    // .
	_punc_end,
}


Pos :: struct {
	file:   string,
	line:   int,
	column: int,
}

Token :: struct {
	kind:      Kind,
	using pos: Pos,
	lit:       string,
}

Tokenizer :: struct {
	src:         []byte,

	file:        string, // May not be used

	curr_rune:   rune,
	offset:      int,
	read_offset: int,
	line_offset: int,
	line_count:  int,

	insert_semi: bool,

	error_count: int,
}


keywords := map[string]Kind{
	"true"  = True,
	"false" = False,
	"nil"   = Nil,
	"and"   = And,
	"or"    = Or,
};

kind_to_string := [len(Kind)]string{
	"illegal",
	"EOF",
	"comment",

	"",
	"identifier",
	"integer",
	"float",
	"character",
	"string",
	"",

	"",
	"true", "false", "nil",
	"",

	"",
	"?", "and", "or",
	"+", "-", "*", "/", "%",
	"!",
	"==", "!=", "<", ">", "<=", ">=",
	"@",
	"",

	"",
	"=",
	"(", ")",
	"[", "]",
	"{", "}",
	":", ";", ",", ".",
	"",
};

precedence :: proc(op: Kind) -> int {
	switch op {
	case Question:
		return 1;
	case Or:
		return 2;
	case And:
		return 3;
	case Eq, NotEq, Lt, Gt, LtEq, GtEq:
		return 4;
	case Add, Sub:
		return 5;
	case Mul, Quo, Rem:
		return 6;
	}
	return 0;
}


token_lookup :: proc(ident: string) -> Kind {
	if tok, is_keyword := keywords[ident]; is_keyword {
		return tok;
	}
	return Ident;
}

is_literal  :: proc(tok: Kind) -> bool do return _literal_start  < tok && tok < _literal_end;
is_operator :: proc(tok: Kind) -> bool do return _operator_start < tok && tok < _operator_end;
is_keyword  :: proc(tok: Kind) -> bool do return _keyword_start  < tok && tok < _keyword_end;


tokenizer_init :: proc(t: ^Tokenizer, src: []byte, file := "") {
	t.src = src;
	t.file = file;
	t.curr_rune   = ' ';
	t.offset      = 0;
	t.read_offset = 0;
	t.line_offset = 0;
	t.line_count  = 1;

	advance_to_next_rune(t);
	if t.curr_rune == utf8.RUNE_BOM {
		advance_to_next_rune(t);
	}
}

token_error :: proc(t: ^Tokenizer, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) Error: ", t.file, t.line_count, t.read_offset-t.line_offset+1);
	fmt.eprintf(msg, ..args);
	fmt.eprintln();
	t.error_count += 1;
}

advance_to_next_rune :: proc(t: ^Tokenizer) {
	if t.read_offset < len(t.src) {
		t.offset = t.read_offset;
		if t.curr_rune == '\n' {
			t.line_offset = t.offset;
			t.line_count += 1;
		}
		r, w := rune(t.src[t.read_offset]), 1;
		switch {
		case r == 0:
			token_error(t, "Illegal character NUL");
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune(t.src[t.read_offset:]);
			if r == utf8.RUNE_ERROR && w == 1 {
				token_error(t, "Illegal utf-8 encoding");
			} else if r == utf8.RUNE_BOM && t.offset > 0 {
				token_error(t, "Illegal byte order mark");
			}
		}

		t.read_offset += w;
		t.curr_rune = r;
	} else {
		t.offset = len(t.src);
		if t.curr_rune == '\n' {
			t.line_offset = t.offset;
			t.line_count += 1;
		}
		t.curr_rune = utf8.RUNE_EOF;
	}
}


get_pos :: proc(t: ^Tokenizer) -> Pos {
	return Pos {
		file   = t.file,
		line   = t.line_count,
		column = t.offset - t.line_offset + 1,
	};
}

is_letter :: proc(r: rune) -> bool {
	switch r {
	case 'a'..'z', 'A'..'Z', '_':
		return true;
	}
	return false;
}

is_digit :: proc(r: rune) -> bool {
	switch r {
	case '0'..'9':
		return true;
	}
	return false;
}

skip_whitespace :: proc(t: ^Tokenizer) {
	loop: for {
		switch t.curr_rune {
		case '\n':
			if t.insert_semi {
				break loop;
			}
			fallthrough;
		case ' ', '\t', '\r', '\v', '\f':
			advance_to_next_rune(t);

		case:
			break loop;
		}
	}
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
	offset := t.offset;
	for is_letter(t.curr_rune) || is_digit(t.curr_rune) {
		advance_to_next_rune(t);
	}
	return string(t.src[offset : t.offset]);
}

digit_value :: proc(r: rune) -> int {
	switch r {
	case '0'..'9': return int(r - '0');
	case 'a'..'f': return int(r - 'a' + 10);
	case 'A'..'F': return int(r - 'A' + 10);
	}
	return 16;
}

scan_number :: proc(t: ^Tokenizer, seen_decimal_point: bool) -> (Kind, string) {
	scan_mantissa :: proc(t: ^Tokenizer, base: int) {
		for digit_value(t.curr_rune) < base || t.curr_rune == '_' {
			advance_to_next_rune(t);
		}
	}
	scan_exponent :: proc(t: ^Tokenizer, tok: Kind, offset: int) -> (kind: Kind, text: string) {
		kind = tok;
		if t.curr_rune == 'e' || t.curr_rune == 'E' {
			kind = Float;
			advance_to_next_rune(t);
			if t.curr_rune == '-' || t.curr_rune == '+' {
				advance_to_next_rune(t);
			}
			if digit_value(t.curr_rune) < 10 {
				scan_mantissa(t, 10);
			} else {
				token_error(t, "Illegal floating point exponent");
			}
		}
		text = string(t.src[offset : t.offset]);
		return;
	}
	scan_fraction :: proc(t: ^Tokenizer, tok: Kind, offset: int) -> (kind: Kind, text: string)  {
		kind = tok;
		if t.curr_rune == '.' {
			kind = Float;
			advance_to_next_rune(t);
			scan_mantissa(t, 10);
		}

		return scan_exponent(t, kind, offset);
	}

	offset := t.offset;
	tok := Integer;

	if seen_decimal_point {
		offset -= 1;
		tok = Float;
		scan_mantissa(t, 10);
		return scan_exponent(t, tok, offset);
	}

	if t.curr_rune == '0' {
		offset = t.offset;
		advance_to_next_rune(t);
		switch t.curr_rune {
		case 'b', 'B':
			advance_to_next_rune(t);
			scan_mantissa(t, 2);
			if t.offset - offset <= 2 {
				token_error(t, "Illegal binary number");
			}
		case 'o', 'O':
			advance_to_next_rune(t);
			scan_mantissa(t, 8);
			if t.offset - offset <= 2 {
				token_error(t, "Illegal octal number");
			}
		case 'x', 'X':
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if t.offset - offset <= 2 {
				token_error(t, "Illegal hexadecimal number");
			}
		case:
			scan_mantissa(t, 10);
			switch t.curr_rune {
			case '.', 'e', 'E':
				return scan_fraction(t, tok, offset);
			}
		}

		return tok, string(t.src[offset:t.offset]);
	}

	scan_mantissa(t, 10);

	return scan_fraction(t, tok, offset);
}

scan :: proc(t: ^Tokenizer) -> Token {
	skip_whitespace(t);

	offset := t.offset;

	tok: Kind;
	pos := get_pos(t);
	lit: string;

	insert_semi := false;


	switch r := t.curr_rune; {
	case is_letter(r):
		insert_semi = true;
		lit = scan_identifier(t);
		tok = Ident;
		if len(lit) > 1 {
			tok = token_lookup(lit);
		}

	case '0' <= r && r <= '9':
		insert_semi = true;
		tok, lit = scan_number(t, false);

	case:
		advance_to_next_rune(t);
		switch r {
		case -1:
			if t.insert_semi {
				t.insert_semi = false;
				return Token{Semicolon, pos, "\n"};
			}
			return Token{EOF, pos, "\n"};

		case '\n':
			t.insert_semi = false;
			return Token{Semicolon, pos, "\n"};

		case '"':
			insert_semi = true;
			quote := r;
			tok = String;
			for {
				this_r := t.curr_rune;
				if this_r == '\n' || r < 0 {
					token_error(t, "String literal not terminated");
					break;
				}
				advance_to_next_rune(t);
				if this_r == quote {
					break;
				}
				// TODO(bill); Handle properly
				if this_r == '\\' && t.curr_rune == quote {
					advance_to_next_rune(t);
				}
			}

			lit = string(t.src[offset+1:t.offset-1]);


		case '#':
			for t.curr_rune != '\n' && t.curr_rune >= 0 {
				advance_to_next_rune(t);
			}
			if t.insert_semi {
				t.insert_semi = false;
				return Token{Semicolon, pos, "\n"};
			}
			// Recursive!
			return scan(t);

		case '?': tok = Question;
		case ':': tok = Colon;
		case '@': tok = At;

		case ';':
			tok = Semicolon;
			lit = ";";
		case ',': tok = Comma;

		case '(':
			tok = Open_Paren;
		case ')':
			insert_semi = true;
			tok = Close_Paren;

		case '[':
			tok = Open_Bracket;
		case ']':
			insert_semi = true;
			tok = Close_Bracket;

		case '{':
			tok = Open_Brace;
		case '}':
			insert_semi = true;
			tok = Close_Brace;

		case '+': tok = Add;
		case '-': tok = Sub;
		case '*': tok = Mul;
		case '/': tok = Quo;
		case '%': tok = Rem;

		case '!':
			tok = Not;
			if t.curr_rune == '=' {
				advance_to_next_rune(t);
				tok = NotEq;
			}

		case '=':
			tok = Assign;
			if t.curr_rune == '=' {
				advance_to_next_rune(t);
				tok = Eq;
			}

		case '<':
			tok = Lt;
			if t.curr_rune == '=' {
				advance_to_next_rune(t);
				tok = LtEq;
			}

		case '>':
			tok = Gt;
			if t.curr_rune == '=' {
				advance_to_next_rune(t);
				tok = GtEq;
			}

		case '.':
			if '0' <= t.curr_rune && t.curr_rune <= '9' {
				insert_semi = true;
				tok, lit = scan_number(t, true);
			} else {
				tok = Period;
			}

		case:
			if r != utf8.RUNE_BOM {
				token_error(t, "Illegal character '%r'", r);
			}
			insert_semi = t.insert_semi;
			tok = Illegal;
		}
	}

	t.insert_semi = insert_semi;

	if lit == "" {
		lit = string(t.src[offset:t.offset]);
	}

	return Token{tok, pos, lit};
}
