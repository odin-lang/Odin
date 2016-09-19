#define TOKEN_KINDS \
	TOKEN_KIND(Token_Invalid, "Invalid"), \
	TOKEN_KIND(Token_EOF, "EOF"), \
\
TOKEN_KIND(Token__LiteralBegin, "_LiteralBegin"), \
	TOKEN_KIND(Token_Identifier, "Identifier"), \
	TOKEN_KIND(Token_Integer, "Integer"), \
	TOKEN_KIND(Token_Float, "Float"), \
	TOKEN_KIND(Token_Rune, "Rune"), \
	TOKEN_KIND(Token_String, "String"), \
TOKEN_KIND(Token__LiteralEnd, "_LiteralEnd"), \
\
TOKEN_KIND(Token__OperatorBegin, "_OperatorBegin"), \
	TOKEN_KIND(Token_Eq, "="), \
	TOKEN_KIND(Token_Not, "!"), \
	TOKEN_KIND(Token_Hash, "#"), \
	TOKEN_KIND(Token_At, "@"), \
	TOKEN_KIND(Token_Pointer, "^"), \
	TOKEN_KIND(Token_Add, "+"), \
	TOKEN_KIND(Token_Sub, "-"), \
	TOKEN_KIND(Token_Mul, "*"), \
	TOKEN_KIND(Token_Quo, "/"), \
	TOKEN_KIND(Token_Mod, "%"), \
	TOKEN_KIND(Token_And, "&"), \
	TOKEN_KIND(Token_Or, "|"), \
	TOKEN_KIND(Token_Xor, "~"), \
	TOKEN_KIND(Token_AndNot, "&~"), \
	TOKEN_KIND(Token_Shl, "<<"), \
	TOKEN_KIND(Token_Shr, ">>"), \
\
	TOKEN_KIND(Token_as, "as"), \
	TOKEN_KIND(Token_transmute, "transmute"), \
	TOKEN_KIND(Token_down_cast, "down_cast"), \
\
	TOKEN_KIND(Token_Prime, "'"), \
	TOKEN_KIND(Token_DoublePrime, "''"), \
\
TOKEN_KIND(Token__AssignOpBegin, "_AssignOpBegin"), \
	TOKEN_KIND(Token_AddEq, "+="), \
	TOKEN_KIND(Token_SubEq, "-="), \
	TOKEN_KIND(Token_MulEq, "*="), \
	TOKEN_KIND(Token_QuoEq, "/="), \
	TOKEN_KIND(Token_ModEq, "%="), \
	TOKEN_KIND(Token_AndEq, "&="), \
	TOKEN_KIND(Token_OrEq, "|="), \
	TOKEN_KIND(Token_XorEq, "~="), \
	TOKEN_KIND(Token_AndNotEq, "&~="), \
	TOKEN_KIND(Token_ShlEq, "<<="), \
	TOKEN_KIND(Token_ShrEq, ">>="), \
TOKEN_KIND(Token__AssignOpEnd, "_AssignOpEnd"), \
	TOKEN_KIND(Token_Increment, "++"), \
	TOKEN_KIND(Token_Decrement, "--"), \
	TOKEN_KIND(Token_ArrowRight, "->"), \
	TOKEN_KIND(Token_ArrowLeft, "<-"), \
\
	TOKEN_KIND(Token_CmpAnd, "&&"), \
	TOKEN_KIND(Token_CmpOr, "||"), \
	TOKEN_KIND(Token_CmpAndEq, "&&="), \
	TOKEN_KIND(Token_CmpOrEq, "||="), \
\
TOKEN_KIND(Token__ComparisonBegin, "_ComparisonBegin"), \
	TOKEN_KIND(Token_CmpEq, "=="), \
	TOKEN_KIND(Token_NotEq, "!="), \
	TOKEN_KIND(Token_Lt, "<"), \
	TOKEN_KIND(Token_Gt, ">"), \
	TOKEN_KIND(Token_LtEq, "<="), \
	TOKEN_KIND(Token_GtEq, ">="), \
TOKEN_KIND(Token__ComparisonEnd, "_ComparisonEnd"), \
\
	TOKEN_KIND(Token_OpenParen, "("), \
	TOKEN_KIND(Token_CloseParen, ")"), \
	TOKEN_KIND(Token_OpenBracket, "["), \
	TOKEN_KIND(Token_CloseBracket, "]"), \
	TOKEN_KIND(Token_OpenBrace, "{"), \
	TOKEN_KIND(Token_CloseBrace, "}"), \
	TOKEN_KIND(Token_Colon, ":"), \
	TOKEN_KIND(Token_Semicolon, ";"), \
	TOKEN_KIND(Token_Period, "."), \
	TOKEN_KIND(Token_Comma, ","), \
	TOKEN_KIND(Token_Ellipsis, ".."), \
	TOKEN_KIND(Token_RangeExclusive, "..<"), \
TOKEN_KIND(Token__OperatorEnd, "_OperatorEnd"), \
\
TOKEN_KIND(Token__KeywordBegin, "_KeywordBegin"), \
	TOKEN_KIND(Token_type,        "type"), \
	TOKEN_KIND(Token_proc,        "proc"), \
	TOKEN_KIND(Token_match,       "match"), \
	TOKEN_KIND(Token_break,       "break"), \
	TOKEN_KIND(Token_continue,    "continue"), \
	TOKEN_KIND(Token_fallthrough, "fallthrough"), \
	TOKEN_KIND(Token_case,        "case"), \
	TOKEN_KIND(Token_default,     "default"), \
	TOKEN_KIND(Token_then,        "then"), \
	TOKEN_KIND(Token_if,          "if"), \
	TOKEN_KIND(Token_else,        "else"), \
	TOKEN_KIND(Token_for,         "for"), \
	TOKEN_KIND(Token_range,       "range"), \
	TOKEN_KIND(Token_defer,       "defer"), \
	TOKEN_KIND(Token_return,      "return"), \
	TOKEN_KIND(Token_struct,      "struct"), \
	TOKEN_KIND(Token_union,       "union"), \
	TOKEN_KIND(Token_raw_union,   "raw_union"), \
	TOKEN_KIND(Token_enum,        "enum"), \
	TOKEN_KIND(Token_using,       "using"), \
	TOKEN_KIND(Token_asm,         "asm"), \
	TOKEN_KIND(Token_volatile,    "volatile"), \
	TOKEN_KIND(Token_atomic,      "atomic"), \
TOKEN_KIND(Token__KeywordEnd, "_KeywordEnd"), \
	TOKEN_KIND(Token_Count, "")

enum TokenKind {
#define TOKEN_KIND(e, s) e
	TOKEN_KINDS
#undef TOKEN_KIND
};

String const token_strings[] = {
#define TOKEN_KIND(e, s) {cast(u8 *)s, gb_size_of(s)-1}
	TOKEN_KINDS
#undef TOKEN_KIND
};


struct TokenPos {
	String file;
	isize line, column;
};

i32 token_pos_cmp(TokenPos a, TokenPos b) {
	if (a.line == b.line) {
		if (a.column == b.column) {
			isize min_len = gb_min(a.file.len, b.file.len);
			return gb_memcompare(a.file.text, b.file.text, min_len);
		}
		return (a.column < b.column) ? -1 : +1;
	}

	return (a.line < b.line) ? -1 : +1;
}

b32 token_pos_are_equal(TokenPos a, TokenPos b) {
	return token_pos_cmp(a, b) == 0;
}

// NOTE(bill): Text is UTF-8, thus why u8 and not char
struct Token {
	TokenKind kind;
	String string;
	TokenPos pos;
};

Token empty_token = {Token_Invalid};


struct ErrorCollector {
	TokenPos prev;
	i64 count;
	i64 warning_count;
};

gb_global ErrorCollector global_error_collector;


void warning(Token token, char *fmt, ...) {
	global_error_collector.warning_count++;
	// NOTE(bill): Duplicate error, skip it
	if (!token_pos_are_equal(global_error_collector.prev, token.pos)) {
		va_list va;

		global_error_collector.prev = token.pos;

		va_start(va, fmt);
		gb_printf_err("%.*s(%td:%td) Warning: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);
	}
}

void error(Token token, char *fmt, ...) {
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (!token_pos_are_equal(global_error_collector.prev, token.pos)) {
		va_list va;

		global_error_collector.prev = token.pos;

		va_start(va, fmt);
		gb_printf_err("%.*s(%td:%td) %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);
	}
}

void syntax_error(Token token, char *fmt, ...) {
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (!token_pos_are_equal(global_error_collector.prev, token.pos)) {
		va_list va;

		global_error_collector.prev = token.pos;

		va_start(va, fmt);
		gb_printf_err("%.*s(%td:%td) Syntax Error: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);
	}
}


void compiler_error(char *fmt, ...) {
	va_list va;

	va_start(va, fmt);
	gb_printf_err("Internal Compiler Error: %s\n",
	              gb_bprintf_va(fmt, va));
	va_end(va);
	gb_exit(1);
}



// NOTE(bill): result == priority
i32 token_precedence(Token t) {
	switch (t.kind) {
	case Token_CmpOr:
		return 1;
	case Token_CmpAnd:
		return 2;
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
	case Token_Shl:
	case Token_Shr:
		return 5;
	case Token_DoublePrime:
		return 6;
	case Token_as:
	case Token_transmute:
	case Token_down_cast:
		return 7;
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
gb_inline b32 token_is_shift(Token t) {
	return t.kind == Token_Shl || t.kind == Token_Shr;
}

gb_inline void print_token(Token t) { gb_printf("%.*s\n", LIT(t.string)); }


enum TokenizerInitError {
	TokenizerInit_None,

	TokenizerInit_Invalid,
	TokenizerInit_NotExists,
	TokenizerInit_Permission,
	TokenizerInit_Empty,

	TokenizerInit_Count,
};


struct Tokenizer {
	String fullpath;
	u8 *start;
	u8 *end;

	Rune  curr_rune;   // current character
	u8 *  curr;        // character pos
	u8 *  read_curr;   // pos from start
	u8 *  line;        // current line pos
	isize line_count;

	isize error_count;
	gbArray(String) allocated_strings;
};


#define tokenizer_err(t, msg, ...) tokenizer_err_(t, __FUNCTION__, msg, ##__VA_ARGS__)
void tokenizer_err_(Tokenizer *t, char *function, char *msg, ...) {
	va_list va;
	isize column = t->read_curr - t->line+1;
	if (column < 1)
		column = 1;

	gb_printf_err("%.*s(%td:%td) Syntax error: ", LIT(t->fullpath), t->line_count, column);

	va_start(va, msg);
	gb_printf_err_va(msg, va);
	va_end(va);

	gb_printf_err("\n");

	t->error_count++;
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
			tokenizer_err(t, "Illegal character NUL");
		} else if (rune >= 0x80) { // not ASCII
			width = gb_utf8_decode(t->read_curr, t->end-t->read_curr, &rune);
			if (rune == GB_RUNE_INVALID && width == 1)
				tokenizer_err(t, "Illegal UTF-8 encoding");
			else if (rune == GB_RUNE_BOM && t->curr-t->start > 0)
				tokenizer_err(t, "Illegal byte order mark");
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

TokenizerInitError init_tokenizer(Tokenizer *t, String fullpath) {
	char *c_str = gb_alloc_array(gb_heap_allocator(), char, fullpath.len+1);
	memcpy(c_str, fullpath.text, fullpath.len);
	c_str[fullpath.len] = '\0';

	defer (gb_free(gb_heap_allocator(), c_str));


	gbFileContents fc = gb_file_read_contents(gb_heap_allocator(), true, c_str);
	gb_zero_item(t);
	if (fc.data != NULL) {
		t->start = cast(u8 *)fc.data;
		t->line = t->read_curr = t->curr = t->start;
		t->end = t->start + fc.size;

		t->fullpath = fullpath;

		t->line_count = 1;

		advance_to_next_rune(t);
		if (t->curr_rune == GB_RUNE_BOM)
			advance_to_next_rune(t); // Ignore BOM at file beginning

		gb_array_init(t->allocated_strings, gb_heap_allocator());

		return TokenizerInit_None;
	}

	gbFile f = {};
	gbFileError err = gb_file_open(&f, c_str);
	defer (gb_file_close(&f));

	switch (err) {
	case gbFileError_Invalid:
		return TokenizerInit_Invalid;
	case gbFileError_NotExists:
		return TokenizerInit_NotExists;
	case gbFileError_Permission:
		return TokenizerInit_Permission;
	}

	if (gb_file_size(&f) == 0)
		return TokenizerInit_Empty;


	return TokenizerInit_None;
}

gb_inline void destroy_tokenizer(Tokenizer *t) {
	if (t->start != NULL) {
		gb_free(gb_heap_allocator(), t->start);
	}
	if (t->allocated_strings != NULL) {
		gb_for_array(i, t->allocated_strings) {
			gb_free(gb_heap_allocator(), t->allocated_strings[i].text);
		}
		gb_array_free(t->allocated_strings);
	}
}

void tokenizer_skip_whitespace(Tokenizer *t) {
	for (;;) {
		if (rune_is_whitespace(t->curr_rune)) {
			advance_to_next_rune(t);
		} else if (t->curr_rune == '/') {
			if (t->read_curr[0] == '/') { // Line comment //
				while (t->curr_rune != '\n') {
					advance_to_next_rune(t);
				}
			} else if (t->read_curr[0] == '*') { // (Nested) Block comment /**/
				advance_to_next_rune(t);
				advance_to_next_rune(t);
				isize comment_scope = 1;
				while (comment_scope > 0) {
					if (t->curr_rune == '/') {
						advance_to_next_rune(t);
						if (t->curr_rune == '*') {
							advance_to_next_rune(t);
							comment_scope++;
						}
					} else if (t->curr_rune == '*') {
						advance_to_next_rune(t);
						if (t->curr_rune == '/') {
							advance_to_next_rune(t);
							comment_scope--;
						}
					} else {
						advance_to_next_rune(t);
					}
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
	token.pos.file = t->fullpath;
	token.pos.line = t->line_count;
	token.pos.column = t->curr-t->line+1;

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

		token.string.len = t->curr - token.string.text;
		return token;
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

	token.string.len = t->curr - token.string.text;
	return token;
}

// Quote == " for string
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
			tokenizer_err(t, "Escape sequence was not terminated");
		else
			tokenizer_err(t, "Unknown escape sequence");
		return false;
	}

	while (len --> 0) {
		u32 d = cast(u32)digit_value(t->curr_rune);
		if (d >= base) {
			if (t->curr_rune < 0)
				tokenizer_err(t, "Escape sequence was not terminated");
			else
				tokenizer_err(t, "Illegal character %d in escape sequence", t->curr_rune);
			return false;
		}

		x = x*base + d;
		advance_to_next_rune(t);
	}

	return true;
}

gb_inline TokenKind token_kind_variant2(Tokenizer *t, TokenKind a, TokenKind b) {
	if (t->curr_rune == '=') {
		advance_to_next_rune(t);
		return b;
	}
	return a;
}


gb_inline TokenKind token_kind_variant3(Tokenizer *t, TokenKind a, TokenKind b, Rune ch_c, TokenKind c) {
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

gb_inline TokenKind token_kind_variant4(Tokenizer *t, TokenKind a, TokenKind b, Rune ch_c, TokenKind c, Rune ch_d, TokenKind d) {
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


gb_inline TokenKind token_kind_dub_eq(Tokenizer *t, Rune sing_rune, TokenKind sing, TokenKind sing_eq, TokenKind dub, TokenKind dub_eq) {
	if (t->curr_rune == '=') {
		advance_to_next_rune(t);
		return sing_eq;
	} else if (t->curr_rune == sing_rune) {
		advance_to_next_rune(t);
		if (t->curr_rune == '=') {
			advance_to_next_rune(t);
			return dub_eq;
		}
		return dub;
	}
	return sing;
}

Token tokenizer_get_token(Tokenizer *t) {
	Token token = {};
	Rune curr_rune;

	tokenizer_skip_whitespace(t);
	token.string = make_string(t->curr, 1);
	token.pos.file = t->fullpath;
	token.pos.line = t->line_count;
	token.pos.column = t->curr - t->line + 1;

	curr_rune = t->curr_rune;
	if (rune_is_letter(curr_rune)) {
		token.kind = Token_Identifier;
		while (rune_is_letter(t->curr_rune) || rune_is_digit(t->curr_rune))
			advance_to_next_rune(t);

		token.string.len = t->curr - token.string.text;

		// NOTE(bill): All keywords are > 1
		if (token.string.len > 1) {
			if (token.string == token_strings[Token_as]) {
				token.kind = Token_as;
			} else if (token.string == token_strings[Token_transmute]) {
				token.kind = Token_transmute;
			} else if (token.string == token_strings[Token_down_cast]) {
				token.kind = Token_down_cast;
			} else {
				for (i32 k = Token__KeywordBegin+1; k < Token__KeywordEnd; k++) {
					if (token.string == token_strings[k]) {
						token.kind = cast(TokenKind)k;
						break;
					}
				}
			}
		}

	} else if (gb_is_between(curr_rune, '0', '9')) {
		token = scan_number_to_token(t, false);
	} else {
		advance_to_next_rune(t);
		switch (curr_rune) {
		case GB_RUNE_EOF:
			token.kind = Token_EOF;
			break;

		case '\'':
			token.kind = Token_Prime;
			if (t->curr_rune == '\'') {
				advance_to_next_rune(t);
				token.kind = Token_DoublePrime;
			}
			break;

		case '`': // Raw String Literal
		case '"': // String Literal
		{
			Rune quote = curr_rune;
			token.kind = Token_String;
			if (curr_rune == '"') {
				for (;;) {
					Rune r = t->curr_rune;
					if (r == '\n' || r < 0) {
						tokenizer_err(t, "String literal not terminated");
						break;
					}
					advance_to_next_rune(t);
					if (r == quote)
						break;
					if (r == '\\')
						scan_escape(t, '"');
				}
			} else {
				for (;;) {
					Rune r = t->curr_rune;
					if (r < 0) {
						tokenizer_err(t, "String literal not terminated");
						break;
					}
					advance_to_next_rune(t);
					if (r == quote)
						break;
				}
			}
			token.string.len = t->curr - token.string.text;
			i32 success = unquote_string(gb_heap_allocator(), &token.string);
			if (success > 0) {
				if (success == 2) {
					gb_array_append(t->allocated_strings, token.string);
				}
				return token;
			} else {
				tokenizer_err(t, "Invalid string literal");
			}
		} break;

		case '.':
			token.kind = Token_Period; // Default
			if (gb_is_between(t->curr_rune, '0', '9')) { // Might be a number
				token = scan_number_to_token(t, true);
			} else if (t->curr_rune == '.') { // Could be an ellipsis
				advance_to_next_rune(t);
				token.kind = Token_Ellipsis;
				if (t->curr_rune == '<') {
					advance_to_next_rune(t);
					token.kind = Token_RangeExclusive;
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

		case '*': token.kind = token_kind_variant2(t, Token_Mul,   Token_MulEq);     break;
		case '/': token.kind = token_kind_variant2(t, Token_Quo,   Token_QuoEq);     break;
		case '%': token.kind = token_kind_variant2(t, Token_Mod,   Token_ModEq);     break;
		case '=': token.kind = token_kind_variant2(t, Token_Eq,    Token_CmpEq);     break;
		case '~': token.kind = token_kind_variant2(t, Token_Xor,   Token_XorEq);     break;
		case '!': token.kind = token_kind_variant2(t, Token_Not,   Token_NotEq);     break;
		case '+': token.kind = token_kind_variant3(t, Token_Add,   Token_AddEq, '+', Token_Increment); break;
		case '-': token.kind = token_kind_variant4(t, Token_Sub,   Token_SubEq, '-', Token_Decrement, '>', Token_ArrowRight); break;

		case '<':
			if (t->curr_rune == '-') {
				token.kind = Token_ArrowLeft;
			} else {
				token.kind = token_kind_dub_eq(t, '<', Token_Lt, Token_LtEq, Token_Shl, Token_ShlEq);
			}
			break;
		case '>':
			token.kind = token_kind_dub_eq(t, '>', Token_Gt, Token_GtEq, Token_Shr, Token_ShrEq);
			break;

		case '&':
			token.kind = Token_And;
			if (t->curr_rune == '~') {
				token.kind = Token_AndNot;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token.kind = Token_AndNotEq;
					advance_to_next_rune(t);
				}
			} else {
				token.kind = token_kind_dub_eq(t, '&', Token_And, Token_AndEq, Token_CmpAnd, Token_CmpAndEq);
			}
			break;

		case '|': token.kind = token_kind_dub_eq(t, '|', Token_Or, Token_OrEq, Token_CmpOr, Token_CmpOrEq); break;

		default:
			if (curr_rune != GB_RUNE_BOM) {
				u8 str[4] = {};
				int len = cast(int)gb_utf8_encode_rune(str, curr_rune);
				tokenizer_err(t, "Illegal character: %.*s (%d) ", len, str, curr_rune);
			}
			token.kind = Token_Invalid;
			break;
		}
	}

	token.string.len = t->curr - token.string.text;
	return token;
}
