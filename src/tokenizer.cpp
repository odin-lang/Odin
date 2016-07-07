// TODO(bill): Unicode support
b32 rune_is_letter(Rune r) {
	if (r < 0x80 && gb_char_is_alpha(cast(char)r) || r == '_') {
		return true;
	}
	return false;
}

b32 rune_is_digit(Rune r) {
	if (r < 0x80 && gb_is_between(r, '0', '9'))
		return true;
	return false;
}

b32 rune_is_whitespace(Rune r) {
	switch (r) {
	case ' ':
	case '\t':
	case '\n':
	case '\r':
	case '\f':
	case '\v':
		return true;
	}
	return false;
}

typedef enum TokenKind TokenKind;
enum TokenKind {
	Token_Invalid,
	Token_EOF,

Token__LiteralBegin,
	Token_Identifier,
	Token_Integer,
	Token_Float,
	Token_Rune,
	Token_String,
Token__LiteralEnd,

Token__OperatorBegin,
	Token_Eq, // =

	Token_Not,     // ! (Unary Boolean)
	Token_Hash,    // #
	Token_At,      // @ // TODO(bill): Remove
	Token_Pointer, // ^

	Token_Add, // +
	Token_Sub, // -
	Token_Mul, // *
	Token_Quo, // /
	Token_Mod, // %

	Token_AddEq, // +=
	Token_SubEq, // -=
	Token_MulEq, // *=
	Token_QuoEq, // /=
	Token_ModEq, // %=

	Token_And,        // &
	Token_Or,         // |
	Token_Xor,        // ~
	Token_AndNot,     // &~

	Token_AndEq,    // &=
	Token_OrEq,     // |=
	Token_XorEq,    // ~=
	Token_AndNotEq, // &~=

	Token_Increment,  // ++
	Token_Decrement,  // --
	Token_ArrowRight, // ->
	Token_ArrowLeft,  // <-

	Token_CmpAnd,   // &&
	Token_CmpOr,    // ||
Token__ComparisonBegin,
	Token_CmpEq,    // ==
	Token_Lt,       // <
	Token_Gt,       // >
	Token_NotEq,    // !=
	Token_LtEq,     // <=
	Token_GtEq,     // >=
Token__ComparisonEnd,
	Token_CmpAndEq, // &&=
	Token_CmpOrEq,  // ||=

	Token_OpenParen,    // (
	Token_CloseParen,   // )
	Token_OpenBracket,  // [
	Token_CloseBracket, // ]
	Token_OpenBrace,    // {
	Token_CloseBrace,   // }

	Token_Colon,      // :
	Token_Semicolon,  // ;
	Token_Period,     // .
	Token_Comma,      // ,
	Token_Ellipsis,   // ...
Token__OperatorEnd,

Token__KeywordBegin,
	Token_type,
	Token_proc,

	Token_match, // TODO(bill): switch vs match?
	Token_break,
	Token_continue,
	Token_fallthrough,
	Token_case,
	Token_default,

	Token_if,
	Token_else,
	Token_for,
	Token_defer,
	Token_return,
	Token_import,
	Token_cast,

	Token_struct,
	Token_union,
	Token_enum,

	Token_inline,
	Token_no_inline,
Token__KeywordEnd,

	Token_Count,
};

char const *TOKEN_STRINGS[] = {
	"Invalid",
	"EOF",
"_LiteralBegin",
	"Identifier",
	"Integer",
	"Float",
	"Rune",
	"String",
"_LiteralEnd",
"_OperatorBegin",
	"=",
	"!",
	"#",
	"@",
	"^",
	"+",
	"-",
	"*",
	"/",
	"%",
	"+=",
	"-=",
	"*=",
	"/=",
	"%=",
	"&",
	"|",
	"~",
	"&~",
	"&=",
	"|=",
	"~=",
	"&~=",
	"++",
	"--",
	"->",
	"<-",
	"&&",
	"||",
"_ComparisonBegin",
	"==",
	"<",
	">",
	"!=",
	"<=",
	">=",
"_ComparisonEnd",
	"&&=",
	"||=",
	"(",
	")",
	"[",
	"]",
	"{",
	"}",
	":",
	";",
	".",
	",",
	"...",
"_OperatorEnd",
"_KeywordBegin",
	"type",
	"proc",
	"switch",
	"break",
	"continue",
	"fallthrough",
	"case",
	"default",
	"if",
	"else",
	"for",
	"defer",
	"return",
	"import",
	"cast",
	"struct",
	"union",
	"enum",
	"inline",
	"no_inline",
	"import",
"_KeywordEnd",
};


// NOTE(bill): Text is UTF-8, thus why u8 and not char
typedef struct Token Token;
struct Token {
	TokenKind kind;
	String string;
	isize line, column;
};



char const *token_kind_to_string(TokenKind kind) {
	return TOKEN_STRINGS[kind];
}

i32 token_precedence(Token t) {
	switch (t.kind) {
	case Token_CmpOr:  return 1;
	case Token_CmpAnd: return 2;

	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_Gt:
	case Token_LtEq:
	case Token_GtEq:
		return 3;

	case Token_Add:
	case Token_Sub:
	case Token_Or:
	case Token_Xor:
		return 4;

	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_And:
	case Token_AndNot:
		return 5;
	}

	return 0;
}


gb_inline b32 token_is_literal(Token t) {
	return gb_is_between(t.kind, Token__LiteralBegin+1, Token__LiteralEnd-1);
}
gb_inline b32 token_is_operator(Token t) {
	return gb_is_between(t.kind, Token__OperatorBegin+1, Token__OperatorEnd-1);
}
gb_inline b32 token_is_keyword(Token t) {
	return gb_is_between(t.kind, Token__KeywordBegin+1, Token__KeywordEnd-1);
}
gb_inline b32 token_is_comparison(Token t) {
	return gb_is_between(t.kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1);
}

gb_inline void print_token(Token t) { gb_printf("%.*s\n", LIT(t.string)); }

typedef struct Tokenizer Tokenizer;
struct Tokenizer {
	char *fullpath;
	u8 *start;
	u8 *end;

	Rune  curr_rune;   // current character
	u8 *  curr;        // character pos
	u8 *  read_curr;   // pos from start
	u8 *  line;        // current line pos
	isize line_count;
};


#define tokenizer_error(t, msg, ...) tokenizer_error_(t, __FUNCTION__, msg, ##__VA_ARGS__)
void tokenizer_error_(Tokenizer *t, char *function, char *msg, ...) {
	va_list va;
	isize column = t->read_curr - t->line+1;
	if (column < 1)
		column = 1;

	gb_printf_err("%s()\n", function);
	gb_printf_err("%s(%td:%td) ", t->fullpath, t->line_count, column);

	va_start(va, msg);
	gb_printf_err_va(msg, va);
	va_end(va);

	gb_printf_err("\n");

	gb_exit(1);
}

void advance_to_next_rune(Tokenizer *t) {
	if (t->read_curr < t->end) {
		Rune rune;
		isize width = 1;

		t->curr = t->read_curr;
		if (t->curr_rune == '\n') {
			t->line = t->curr;
			t->line_count++;
		}
		rune = *t->read_curr;
		if (rune == 0) {
			tokenizer_error(t, "Illegal character NUL");
		} else if (rune >= 0x80) { // not ASCII
			width = gb_utf8_decode(t->read_curr, t->end-t->read_curr, &rune);
			if (rune == GB_RUNE_INVALID && width == 1)
				tokenizer_error(t, "Illegal UTF-8 encoding");
			else if (rune == GB_RUNE_BOM && t->curr-t->start > 0)
				tokenizer_error(t, "Illegal byte order mark");
		}
		t->read_curr += width;
		t->curr_rune = rune;
	} else {
		t->curr = t->end;
		if (t->curr_rune == '\n') {
			t->line = t->curr;
			t->line_count++;
		}
		t->curr_rune = GB_RUNE_EOF;
	}
}

b32 init_tokenizer(Tokenizer *t, char *filename) {
	gbFileContents fc = gb_file_read_contents(gb_heap_allocator(), true, filename);
	gb_zero_item(t);
	if (fc.data) {
		t->start = cast(u8 *)fc.data;
		t->line = t->read_curr = t->curr = t->start;
		t->end = t->start + fc.size;

		t->fullpath = gb_path_get_full_name(gb_heap_allocator(), filename);

		t->line_count = 1;

		advance_to_next_rune(t);
		if (t->curr_rune == GB_RUNE_BOM)
			advance_to_next_rune(t); // Ignore BOM at file beginning
		return true;
	}
	return false;
}

gb_inline void destroy_tokenizer(Tokenizer *t) {
	gb_free(gb_heap_allocator(), t->start);
}

void tokenizer_skip_whitespace(Tokenizer *t) {
	for (;;) {
		if (rune_is_whitespace(t->curr_rune)) {
			advance_to_next_rune(t);
		} else if (t->curr_rune == '/') {
			if (t->read_curr[0] == '/') { // Line comment //
				while (t->curr_rune != '\n')
					advance_to_next_rune(t);
			} else if (t->read_curr[0] == '*') { // (Nested) Block comment /**/
				isize comment_scope = 1;
				for (;;) {
					advance_to_next_rune(t);
					if (t->curr_rune == '/') {
						advance_to_next_rune(t);
						if (t->curr_rune == '*') {
							advance_to_next_rune(t);
							comment_scope++;
						}
					}
					if (t->curr_rune == '*') {
						advance_to_next_rune(t);
						if (t->curr_rune == '/') {
							advance_to_next_rune(t);
							comment_scope--;
						}
					}
					if (comment_scope == 0)
						break;
				}
			} else {
				break;
			}
		} else {
			break;
		}
	}
}

gb_inline i32 digit_value(Rune r) {
	if (gb_char_is_digit(cast(char)r))
		return r - '0';
	if (gb_is_between(cast(char)r, 'a', 'f'))
		return r - 'a' + 10;
	if (gb_is_between(cast(char)r, 'A', 'F'))
		return r - 'A' + 10;
	return 16; // NOTE(bill): Larger than highest possible
}

gb_inline void scan_mantissa(Tokenizer *t, i32 base) {
	// TODO(bill): Allow for underscores in numbers as a number separator
	// TODO(bill): Is this a good idea?
	// while (digit_value(t->curr_rune) < base || t->curr_rune == '_')
	while (digit_value(t->curr_rune) < base)
		advance_to_next_rune(t);
}


Token scan_number_to_token(Tokenizer *t, b32 seen_decimal_point) {
	Token token = {};
	u8 *start_curr = t->curr;
	token.kind = Token_Integer;
	token.string = make_string(start_curr, 1);
	token.line = t->line_count;
	token.column = t->curr-t->line+1;

	if (seen_decimal_point) {
		start_curr--;
		token.kind = Token_Float;
		scan_mantissa(t, 10);
		goto exponent;
	}

	if (t->curr_rune == '0') {
		u8 *prev = t->curr;
		advance_to_next_rune(t);
		if (t->curr_rune == 'b') { // Binary
			advance_to_next_rune(t);
			scan_mantissa(t, 2);
			if (t->curr - prev <= 2)
				token.kind = Token_Invalid;
		} else if (t->curr_rune == 'o') { // Octal
			advance_to_next_rune(t);
			scan_mantissa(t, 8);
			if (t->curr - prev <= 2)
				token.kind = Token_Invalid;
		} else if (t->curr_rune == 'd') { // Decimal
			advance_to_next_rune(t);
			scan_mantissa(t, 10);
			if (t->curr - prev <= 2)
				token.kind = Token_Invalid;
		} else if (t->curr_rune == 'x') { // Hexadecimal
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if (t->curr - prev <= 2)
				token.kind = Token_Invalid;
		} else {
			seen_decimal_point = false;
			scan_mantissa(t, 10);

			if (t->curr_rune == '.' || t->curr_rune == 'e' || t->curr_rune == 'E') {
				seen_decimal_point = true;
				goto fraction;
			}
		}
		goto end;
	}

	scan_mantissa(t, 10);

fraction:
	if (t->curr_rune == '.') {
		token.kind = Token_Float;
		advance_to_next_rune(t);
		scan_mantissa(t, 10);
	}

exponent:
	if (t->curr_rune == 'e' || t->curr_rune == 'E') {
		token.kind = Token_Float;
		advance_to_next_rune(t);
		if (t->curr_rune == '-' || t->curr_rune == '+')
			advance_to_next_rune(t);
		scan_mantissa(t, 10);
	}

end:
	token.string.len = t->curr - token.string.text;
	return token;
}

// Quote == " for string and ' for char
b32 scan_escape(Tokenizer *t, Rune quote) {
	isize len = 0;
	u32 base = 0, max = 0, x = 0;

	Rune r = t->curr_rune;
	if (r == 'a'  ||
	    r == 'b'  ||
	    r == 'f'  ||
	    r == 'n'  ||
	    r == 'r'  ||
	    r == 't'  ||
	    r == 'v'  ||
	    r == '\\' ||
	    r == quote) {
		advance_to_next_rune(t);
		return true;
	} else if (gb_is_between(r, '0', '7')) {
		len = 3; base = 8; max = 255;
	} else if (r == 'x') {
		advance_to_next_rune(t);
		len = 2; base = 16; max = 255;
	} else if (r == 'u') {
		advance_to_next_rune(t);
		len = 4; base = 16; max = GB_RUNE_MAX;
	} else if (r == 'U') {
		advance_to_next_rune(t);
		len = 8; base = 16; max = GB_RUNE_MAX;
	} else {
		if (t->curr_rune < 0)
			tokenizer_error(t, "Escape sequence was not terminated");
		else
			tokenizer_error(t, "Unknown escape sequence");
		return false;
	}

	while (len --> 0) {
		u32 d = cast(u32)digit_value(t->curr_rune);
		if (d >= base) {
			if (t->curr_rune < 0)
				tokenizer_error(t, "Escape sequence was not terminated");
			else
				tokenizer_error(t, "Illegal character %d in escape sequence", t->curr_rune);
			return false;
		}

		x = x*base + d;
		advance_to_next_rune(t);
	}

	return true;
}

gb_inline TokenKind token_type_variant2(Tokenizer *t, TokenKind a, TokenKind b) {
	if (t->curr_rune == '=') {
		advance_to_next_rune(t);
		return b;
	}
	return a;
}


gb_inline TokenKind token_type_variant3(Tokenizer *t, TokenKind a, TokenKind b, Rune ch_c, TokenKind c) {
	if (t->curr_rune == '=') {
		advance_to_next_rune(t);
		return b;
	}
	if (t->curr_rune == ch_c) {
		advance_to_next_rune(t);
		return c;
	}
	return a;
}

gb_inline TokenKind token_type_variant4(Tokenizer *t, TokenKind a, TokenKind b, Rune ch_c, TokenKind c, Rune ch_d, TokenKind d) {
	if (t->curr_rune == '=') {
		advance_to_next_rune(t);
		return b;
	} else if (t->curr_rune == ch_c) {
		advance_to_next_rune(t);
		return c;
	} else if (t->curr_rune == ch_d) {
		advance_to_next_rune(t);
		return d;
	}
	return a;
}

Token tokenizer_get_token(Tokenizer *t) {
	Token token = {};
	Rune curr_rune;

	tokenizer_skip_whitespace(t);
	token.string = make_string(t->curr, 1);
	token.line = t->line_count;
	token.column = t->curr - t->line + 1;

	curr_rune = t->curr_rune;
	if (rune_is_letter(curr_rune)) {
		token.kind = Token_Identifier;
		while (rune_is_letter(t->curr_rune) || rune_is_digit(t->curr_rune))
			advance_to_next_rune(t);

		token.string.len = t->curr - token.string.text;

		// NOTE(bill): ALL identifiers are > 1
		if (token.string.len > 1) {
		#define KWB if (0) {}
		#define KWT(keyword, token_type) else if ((gb_size_of(keyword)-1) == token.string.len && gb_strncmp((char *)token.string.text, keyword, token.string.len) == 0) token.kind = token_type
		#define KWE else {}

			KWB
			KWT("type",        Token_type);
			KWT("proc",        Token_proc);
			KWT("match",       Token_match);
			KWT("break",       Token_break);
			KWT("continue",    Token_continue);
			KWT("fallthrough", Token_fallthrough);
			KWT("case",        Token_case);
			KWT("default",     Token_default);
			KWT("if",          Token_if);
			KWT("else",        Token_else);
			KWT("for",         Token_for);
			KWT("defer",       Token_defer);
			KWT("return",      Token_return);
			KWT("import",      Token_import);
			KWT("cast",        Token_cast);
			KWT("struct",      Token_struct);
			KWT("union",       Token_union);
			KWT("enum",        Token_enum);
			KWT("inline",      Token_inline);
			KWT("no_inline",   Token_no_inline);
			KWE

		#undef KWB
		#undef KWT
		#undef KWE
		}

	} else if (gb_is_between(curr_rune, '0', '9')) {
		token = scan_number_to_token(t, false);
	} else {
		advance_to_next_rune(t);
		switch (curr_rune) {
		case GB_RUNE_EOF:
			token.kind = Token_EOF;
			break;
		case '"': // String Literal
			token.kind = Token_String;
			for (;;) {
				Rune r = t->curr_rune;
				if (r == '\n' || r < 0) {
					tokenizer_error(t, "String literal not terminated");
					break;
				}
				advance_to_next_rune(t);
				if (r == '"')
					break;
				if (r == '\\')
					scan_escape(t, '"');
			}
			break;

		case '\'': { // Rune Literal
			b32 valid = true;
			isize len = 0;
			token.kind = Token_Rune;
			for (;;) {
				Rune r = t->curr_rune;
				if (r == '\n' || r < 0) {
					if (valid)
						tokenizer_error(t, "Rune literal not terminated");
					break;
				}
				advance_to_next_rune(t);
				if (r == '\'')
					break;
				len++;
				if (r == '\\') {
					if (!scan_escape(t, '\''))
						valid = false;
				}
			}

			if (valid && len != 1)
				tokenizer_error(t, "Illegal rune literal");
		} break;

		case '.':
			token.kind = Token_Period; // Default
			if (gb_is_between(t->curr_rune, '0', '9')) { // Might be a number
				token = scan_number_to_token(t, true);
			} else if (t->curr_rune == '.') { // Could be an ellipsis
				advance_to_next_rune(t);
				if (t->curr_rune == '.') {
					advance_to_next_rune(t);
					token.kind = Token_Ellipsis;
				}
			}
			break;

		case '#': token.kind = Token_Hash;         break;
		case '@': token.kind = Token_At;           break;
		case '^': token.kind = Token_Pointer;      break;
		case ';': token.kind = Token_Semicolon;    break;
		case ',': token.kind = Token_Comma;        break;
		case '(': token.kind = Token_OpenParen;    break;
		case ')': token.kind = Token_CloseParen;   break;
		case '[': token.kind = Token_OpenBracket;  break;
		case ']': token.kind = Token_CloseBracket; break;
		case '{': token.kind = Token_OpenBrace;    break;
		case '}': token.kind = Token_CloseBrace;   break;
		case ':': token.kind = Token_Colon;        break;

		case '*': token.kind = token_type_variant2(t, Token_Mul,   Token_MulEq);     break;
		case '/': token.kind = token_type_variant2(t, Token_Quo,   Token_QuoEq);     break;
		case '%': token.kind = token_type_variant2(t, Token_Mod,   Token_ModEq);     break;
		case '=': token.kind = token_type_variant2(t, Token_Eq,    Token_CmpEq);     break;
		case '~': token.kind = token_type_variant2(t, Token_Xor,   Token_XorEq);     break;
		case '!': token.kind = token_type_variant2(t, Token_Not,   Token_NotEq);     break;
		case '>': token.kind = token_type_variant2(t, Token_Gt,    Token_GtEq);      break;
		case '<': token.kind = token_type_variant3(t, Token_Lt,    Token_LtEq,  '-', Token_ArrowLeft); break;
		case '+': token.kind = token_type_variant3(t, Token_Add,   Token_AddEq, '+', Token_Increment); break;
		case '-': token.kind = token_type_variant4(t, Token_Sub,   Token_SubEq, '-', Token_Decrement, '>', Token_ArrowRight); break;

		case '&':
			token.kind = Token_And;
			if (t->curr_rune == '~') {
				advance_to_next_rune(t);
				token.kind = token_type_variant2(t, Token_AndNot, Token_AndNotEq);
			} else {
				advance_to_next_rune(t);
				token.kind = token_type_variant3(t, Token_And, Token_AndEq, '&', Token_CmpAnd);
				if (t->curr_rune == '=') {
					token.kind = Token_CmpAndEq;
					advance_to_next_rune(t);
				}
			}
			break;

		case '|':
			token.kind = Token_Or;
			advance_to_next_rune(t);
			token.kind = token_type_variant3(t, Token_Or, Token_OrEq, '|', Token_CmpOr);
			if (t->curr_rune == '=')  {
				token.kind = Token_CmpOrEq;
				advance_to_next_rune(t);
			}
			break;

		default:
			if (curr_rune != GB_RUNE_BOM)
				tokenizer_error(t, "Illegal character: %c (%d) ", cast(char)curr_rune, curr_rune);
			token.kind = Token_Invalid;
			break;
		}
	}

	token.string.len = t->curr - token.string.text;
	return token;
}
