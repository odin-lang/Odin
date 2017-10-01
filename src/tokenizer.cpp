#define TOKEN_KINDS \
	TOKEN_KIND(Token_Invalid, "Invalid"), \
	TOKEN_KIND(Token_EOF,     "EOF"), \
	TOKEN_KIND(Token_Comment, "Comment"), \
\
TOKEN_KIND(Token__LiteralBegin, "_LiteralBegin"), \
	TOKEN_KIND(Token_Ident,     "identifier"), \
	TOKEN_KIND(Token_Integer,   "integer"), \
	TOKEN_KIND(Token_Float,     "float"), \
	TOKEN_KIND(Token_Imag,      "imaginary"), \
	TOKEN_KIND(Token_Rune,      "rune"), \
	TOKEN_KIND(Token_String,    "string"), \
TOKEN_KIND(Token__LiteralEnd,   "_LiteralEnd"), \
\
TOKEN_KIND(Token__OperatorBegin, "_OperatorBegin"), \
	TOKEN_KIND(Token_Eq,       "="), \
	TOKEN_KIND(Token_Not,      "!"), \
	TOKEN_KIND(Token_Hash,     "#"), \
	TOKEN_KIND(Token_At,       "@"), \
	TOKEN_KIND(Token_Dollar,   "$"), \
	TOKEN_KIND(Token_Pointer,  "^"), \
	TOKEN_KIND(Token_Question, "?"), \
	TOKEN_KIND(Token_Add,      "+"), \
	TOKEN_KIND(Token_Sub,      "-"), \
	TOKEN_KIND(Token_Mul,      "*"), \
	TOKEN_KIND(Token_Quo,      "/"), \
	TOKEN_KIND(Token_Mod,      "%"), \
	TOKEN_KIND(Token_ModMod,   "%%"), \
	TOKEN_KIND(Token_And,      "&"), \
	TOKEN_KIND(Token_Or,       "|"), \
	TOKEN_KIND(Token_Xor,      "~"), \
	TOKEN_KIND(Token_AndNot,   "&~"), \
	TOKEN_KIND(Token_Shl,      "<<"), \
	TOKEN_KIND(Token_Shr,      ">>"), \
\
	TOKEN_KIND(Token_CmpAnd, "&&"), \
	TOKEN_KIND(Token_CmpOr,  "||"), \
\
TOKEN_KIND(Token__AssignOpBegin, "_AssignOpBegin"), \
	TOKEN_KIND(Token_AddEq,    "+="), \
	TOKEN_KIND(Token_SubEq,    "-="), \
	TOKEN_KIND(Token_MulEq,    "*="), \
	TOKEN_KIND(Token_QuoEq,    "/="), \
	TOKEN_KIND(Token_ModEq,    "%="), \
	TOKEN_KIND(Token_ModModEq, "%%="), \
	TOKEN_KIND(Token_AndEq,    "&="), \
	TOKEN_KIND(Token_OrEq,     "|="), \
	TOKEN_KIND(Token_XorEq,    "~="), \
	TOKEN_KIND(Token_AndNotEq, "&~="), \
	TOKEN_KIND(Token_ShlEq,    "<<="), \
	TOKEN_KIND(Token_ShrEq,    ">>="), \
	TOKEN_KIND(Token_CmpAndEq, "&&="), \
	TOKEN_KIND(Token_CmpOrEq,  "||="), \
TOKEN_KIND(Token__AssignOpEnd, "_AssignOpEnd"), \
	TOKEN_KIND(Token_ArrowRight,       "->"), \
	TOKEN_KIND(Token_ArrowLeft,        "<-"), \
	TOKEN_KIND(Token_DoubleArrowRight, "=>"), \
/* 	TOKEN_KIND(Token_Inc,              "++"), */ \
/* 	TOKEN_KIND(Token_Dec,              "--"), */ \
	TOKEN_KIND(Token_Undef,            "---"), \
\
TOKEN_KIND(Token__ComparisonBegin, "_ComparisonBegin"), \
	TOKEN_KIND(Token_CmpEq, "=="), \
	TOKEN_KIND(Token_NotEq, "!="), \
	TOKEN_KIND(Token_Lt,    "<"), \
	TOKEN_KIND(Token_Gt,    ">"), \
	TOKEN_KIND(Token_LtEq,  "<="), \
	TOKEN_KIND(Token_GtEq,  ">="), \
TOKEN_KIND(Token__ComparisonEnd, "_ComparisonEnd"), \
\
	TOKEN_KIND(Token_OpenParen,     "("),   \
	TOKEN_KIND(Token_CloseParen,    ")"),   \
	TOKEN_KIND(Token_OpenBracket,   "["),   \
	TOKEN_KIND(Token_CloseBracket,  "]"),   \
	TOKEN_KIND(Token_OpenBrace,     "{"),   \
	TOKEN_KIND(Token_CloseBrace,    "}"),   \
	TOKEN_KIND(Token_Colon,         ":"),   \
	TOKEN_KIND(Token_Semicolon,     ";"),   \
	TOKEN_KIND(Token_Period,        "."),   \
	TOKEN_KIND(Token_Comma,         ","),   \
	TOKEN_KIND(Token_Ellipsis,      "..."), \
	TOKEN_KIND(Token_HalfClosed,    ".."),  \
	TOKEN_KIND(Token_BackSlash,     "\\"),  \
TOKEN_KIND(Token__OperatorEnd, "_OperatorEnd"), \
\
TOKEN_KIND(Token__KeywordBegin, "_KeywordBegin"), \
	TOKEN_KIND(Token_import,                 "import"),                 \
	TOKEN_KIND(Token_export,                 "export"),                 \
	TOKEN_KIND(Token_foreign,                "foreign"),                \
	TOKEN_KIND(Token_foreign_library,        "foreign_library"),        \
	TOKEN_KIND(Token_foreign_system_library, "foreign_system_library"), \
	TOKEN_KIND(Token_type,                   "type"),                   \
	TOKEN_KIND(Token_when,                   "when"),                   \
	TOKEN_KIND(Token_if,                     "if"),                     \
	TOKEN_KIND(Token_else,                   "else"),                   \
	TOKEN_KIND(Token_for,                    "for"),                    \
	TOKEN_KIND(Token_switch,                 "switch"),                 \
	TOKEN_KIND(Token_in,                     "in"),                     \
	TOKEN_KIND(Token_do,                     "do"),                     \
	TOKEN_KIND(Token_case,                   "case"),                   \
	TOKEN_KIND(Token_break,                  "break"),                  \
	TOKEN_KIND(Token_continue,               "continue"),               \
	TOKEN_KIND(Token_fallthrough,            "fallthrough"),            \
	TOKEN_KIND(Token_defer,                  "defer"),                  \
	TOKEN_KIND(Token_return,                 "return"),                 \
	TOKEN_KIND(Token_proc,                   "proc"),                   \
	TOKEN_KIND(Token_macro,                  "macro"),                  \
	TOKEN_KIND(Token_struct,                 "struct"),                 \
	TOKEN_KIND(Token_union,                  "union"),                  \
	TOKEN_KIND(Token_enum,                   "enum"),                   \
	TOKEN_KIND(Token_bit_field,              "bit_field"),              \
	TOKEN_KIND(Token_vector,                 "vector"),                 \
	TOKEN_KIND(Token_map,                    "map"),                    \
	TOKEN_KIND(Token_static,                 "static"),                 \
	TOKEN_KIND(Token_dynamic,                "dynamic"),                \
	TOKEN_KIND(Token_cast,                   "cast"),                   \
	TOKEN_KIND(Token_transmute,              "transmute"),              \
	TOKEN_KIND(Token_using,                  "using"),                  \
	TOKEN_KIND(Token_context,                "context"),                \
	TOKEN_KIND(Token_push_context,           "push_context"),           \
	TOKEN_KIND(Token_push_allocator,         "push_allocator"),         \
	TOKEN_KIND(Token_size_of,                "size_of"),                \
	TOKEN_KIND(Token_align_of,               "align_of"),               \
	TOKEN_KIND(Token_offset_of,              "offset_of"),              \
	TOKEN_KIND(Token_type_of,                "type_of"),                \
	TOKEN_KIND(Token_type_info_of,           "type_info_of"),           \
	TOKEN_KIND(Token_asm,                    "asm"),                    \
	TOKEN_KIND(Token_yield,                  "yield"),                  \
	TOKEN_KIND(Token_await,                  "await"),                  \
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
	isize  line;
	isize  column;
};

TokenPos token_pos(String file, isize line, isize column) {
	TokenPos pos = {file, line, column};
	return pos;
}

i32 token_pos_cmp(TokenPos const &a, TokenPos const &b) {
	if (a.line == b.line) {
		if (a.column == b.column) {
			isize min_len = gb_min(a.file.len, b.file.len);
			return gb_memcompare(a.file.text, b.file.text, min_len);
		}
		return (a.column < b.column) ? -1 : +1;
	}
	return (a.line < b.line) ? -1 : +1;
}

bool operator==(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) == 0; }
bool operator!=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) != 0; }
bool operator< (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <  0; }
bool operator<=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <= 0; }
bool operator> (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >  0; }
bool operator>=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >= 0; }

struct Token {
	TokenKind kind;
	String string;
	TokenPos pos;
};

Token empty_token = {Token_Invalid};
Token blank_token = {Token_Ident, {cast(u8 *)"_", 1}};

Token make_token_ident(String s) {
	Token t = {Token_Ident, s};
	return t;
}


struct ErrorCollector {
	TokenPos prev;
	i64     count;
	i64     warning_count;
	gbMutex mutex;
};

gb_global ErrorCollector global_error_collector;

void init_global_error_collector(void) {
	gb_mutex_init(&global_error_collector.mutex);
}

void warning_va(Token token, char *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		gb_printf_err("%.*s(%td:%td) Warning: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}

void error_va(Token token, char *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		gb_printf_err("%.*s(%td:%td) %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
	} else if (token.pos.line == 0) {
		gb_printf_err("Error: %s\n", gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}

void syntax_error_va(Token token, char *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		gb_printf_err("%.*s(%td:%td) Syntax Error: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
	} else if (token.pos.line == 0) {
		gb_printf_err("Error: %s\n", gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}

void syntax_warning_va(Token token, char *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		gb_printf_err("%.*s(%td:%td) Syntax Warning: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
	} else if (token.pos.line == 0) {
		gb_printf_err("Warning: %s\n", gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}



void warning(Token token, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(token, fmt, va);
	va_end(va);
}

void error(Token token, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(token, fmt, va);
	va_end(va);
}

void syntax_error(Token token, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token, fmt, va);
	va_end(va);
}

void syntax_warning(Token token, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_warning_va(token, fmt, va);
	va_end(va);
}


void compiler_error(char *fmt, ...) {
	va_list va;

	va_start(va, fmt);
	gb_printf_err("Internal Compiler Error: %s\n",
	              gb_bprintf_va(fmt, va));
	va_end(va);
	gb_exit(1);
}





gb_inline bool token_is_literal(TokenKind t) {
	return gb_is_between(t, Token__LiteralBegin+1, Token__LiteralEnd-1);
}
gb_inline bool token_is_operator(TokenKind t) {
	return gb_is_between(t, Token__OperatorBegin+1, Token__OperatorEnd-1);
}
gb_inline bool token_is_keyword(TokenKind t) {
	return gb_is_between(t, Token__KeywordBegin+1, Token__KeywordEnd-1);
}
gb_inline bool token_is_comparison(TokenKind t) {
	return gb_is_between(t, Token__ComparisonBegin+1, Token__ComparisonEnd-1);
}
gb_inline bool token_is_shift(TokenKind t) {
	return t == Token_Shl || t == Token_Shr;
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


struct TokenizerState {
	Rune  curr_rune;   // current character
	u8 *  curr;        // character pos
	u8 *  read_curr;   // pos from start
	u8 *  line;        // current line pos
	isize line_count;
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
	Array<String> allocated_strings;
};


TokenizerState save_tokenizer_state(Tokenizer *t) {
	TokenizerState state = {};
	state.curr_rune  = t->curr_rune;
	state.curr       = t->curr;
	state.read_curr  = t->read_curr;
	state.line       = t->line;
	state.line_count = t->line_count;
	return state;
}

void restore_tokenizer_state(Tokenizer *t, TokenizerState *state) {
	 t->curr_rune  = state->curr_rune;
	 t->curr       = state->curr;
	 t->read_curr  = state->read_curr;
	 t->line       = state->line;
	 t->line_count = state->line_count;
}


void tokenizer_err(Tokenizer *t, char *msg, ...) {
	va_list va;
	isize column = t->read_curr - t->line+1;
	if (column < 1) {
		column = 1;
	}

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
	TokenizerInitError err = TokenizerInit_None;

	char *c_str = gb_alloc_array(heap_allocator(), char, fullpath.len+1);
	gb_memcopy(c_str, fullpath.text, fullpath.len);
	c_str[fullpath.len] = '\0';

	// TODO(bill): Memory map rather than copy contents
	gbFileContents fc = gb_file_read_contents(heap_allocator(), true, c_str);
	gb_zero_item(t);
	if (fc.data != nullptr) {
		t->start = cast(u8 *)fc.data;
		t->line = t->read_curr = t->curr = t->start;
		t->end = t->start + fc.size;
		t->fullpath = fullpath;
		t->line_count = 1;

		advance_to_next_rune(t);
		if (t->curr_rune == GB_RUNE_BOM) {
			advance_to_next_rune(t); // Ignore BOM at file beginning
		}

		array_init(&t->allocated_strings, heap_allocator());
	} else {
		gbFile f = {};
		gbFileError file_err = gb_file_open(&f, c_str);

		switch (file_err) {
		case gbFileError_Invalid:    err = TokenizerInit_Invalid;    break;
		case gbFileError_NotExists:  err = TokenizerInit_NotExists;  break;
		case gbFileError_Permission: err = TokenizerInit_Permission; break;
		}

		if (err == TokenizerInit_None && gb_file_size(&f) == 0) {
			err = TokenizerInit_Empty;
		}

		gb_file_close(&f);
	}

	gb_free(heap_allocator(), c_str);
	return err;
}

gb_inline void destroy_tokenizer(Tokenizer *t) {
	if (t->start != nullptr) {
		gb_free(heap_allocator(), t->start);
	}
	for_array(i, t->allocated_strings) {
		gb_free(heap_allocator(), t->allocated_strings[i].text);
	}
	array_free(&t->allocated_strings);
}

void tokenizer_skip_whitespace(Tokenizer *t) {
	while (t->curr_rune == ' ' ||
	       t->curr_rune == '\t' ||
	       t->curr_rune == '\n' ||
	       t->curr_rune == '\r') {
		advance_to_next_rune(t);
	}
}

gb_inline i32 digit_value(Rune r) {
	if (gb_char_is_digit(cast(char)r)) {
		return r - '0';
	} else if (gb_is_between(cast(char)r, 'a', 'f')) {
		return r - 'a' + 10;
	} else if (gb_is_between(cast(char)r, 'A', 'F')) {
		return r - 'A' + 10;
	}
	return 16; // NOTE(bill): Larger than highest possible
}

gb_inline void scan_mantissa(Tokenizer *t, i32 base) {
	while (digit_value(t->curr_rune) < base || t->curr_rune == '_') {
		advance_to_next_rune(t);
	}
}

Token scan_number_to_token(Tokenizer *t, bool seen_decimal_point) {
	Token token = {};
	token.kind = Token_Integer;
	token.string = make_string(t->curr, 1);
	token.pos.file = t->fullpath;
	token.pos.line = t->line_count;
	token.pos.column = t->curr-t->line+1;

	if (seen_decimal_point) {
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
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} else if (t->curr_rune == 'o') { // Octal
			advance_to_next_rune(t);
			scan_mantissa(t, 8);
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} else if (t->curr_rune == 'd') { // Decimal
			advance_to_next_rune(t);
			scan_mantissa(t, 10);
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} else if (t->curr_rune == 'z') { // Dozenal
			advance_to_next_rune(t);
			scan_mantissa(t, 12);
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} else if (t->curr_rune == 'x') { // Hexadecimal
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} /* else if (t->curr_rune == 'h') { // Hexadecimal Float
			token.kind = Token_Float;
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if (t->curr - prev <= 2) {
				token.kind = Token_Invalid;
			}
		} */ else {
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
		// HACK(bill): This may be inefficient
		TokenizerState state = save_tokenizer_state(t);
		advance_to_next_rune(t);
		if (t->curr_rune == '.') {
			// TODO(bill): Clean up this shit
			restore_tokenizer_state(t, &state);
			goto end;
		}
		token.kind = Token_Float;
		scan_mantissa(t, 10);
	}

exponent:
	if (t->curr_rune == 'e' || t->curr_rune == 'E') {
		token.kind = Token_Float;
		advance_to_next_rune(t);
		if (t->curr_rune == '-' || t->curr_rune == '+') {
			advance_to_next_rune(t);
		}
		scan_mantissa(t, 10);
	}

	if (t->curr_rune == 'i') {
		token.kind = Token_Imag;
		advance_to_next_rune(t);
	}

end:
	token.string.len = t->curr - token.string.text;
	return token;
}

// Quote == " for string
bool scan_escape(Tokenizer *t, Rune quote) {
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
		if (t->curr_rune < 0) {
			tokenizer_err(t, "Escape sequence was not terminated");
		} else {
			tokenizer_err(t, "Unknown escape sequence");
		}
		return false;
	}

	while (len --> 0) {
		u32 d = cast(u32)digit_value(t->curr_rune);
		if (d >= base) {
			if (t->curr_rune < 0) {
				tokenizer_err(t, "Escape sequence was not terminated");
			} else {
				tokenizer_err(t, "Illegal character %d in escape sequence", t->curr_rune);
			}
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

void tokenizer__fle_update(Tokenizer *t) {
	t->curr_rune = '/';
	t->curr      = t->curr-1;
	t->read_curr = t->curr+1;
	advance_to_next_rune(t);
}

// NOTE(bill): needed if comment is straight after a "semicolon"
bool tokenizer_find_line_end(Tokenizer *t) {
	while (t->curr_rune == '/' || t->curr_rune == '*') {
		if (t->curr_rune == '/') {
			tokenizer__fle_update(t);
			return true;
		}

		advance_to_next_rune(t);
		while (t->curr_rune >= 0) {
			Rune r = t->curr_rune;
			if (r == '\n') {
				tokenizer__fle_update(t);
				return true;
			}
			advance_to_next_rune(t);
			if (r == '*' && t->curr_rune == '/') {
				advance_to_next_rune(t);
				break;
			}
		}

		tokenizer_skip_whitespace(t);
		if (t->curr_rune < 0 || t->curr_rune == '\n') {
			tokenizer__fle_update(t);
			return true;
		}
		if (t->curr_rune != '/') {
			tokenizer__fle_update(t);
			return false;
		}
		advance_to_next_rune(t);
	}

	tokenizer__fle_update(t);
	return false;
}

Token tokenizer_get_token(Tokenizer *t) {
	tokenizer_skip_whitespace(t);

	Token token = {};
	token.string = make_string(t->curr, 1);
	token.pos.file = t->fullpath;
	token.pos.line = t->line_count;
	token.pos.column = t->curr - t->line + 1;

	Rune curr_rune = t->curr_rune;
	if (rune_is_letter(curr_rune)) {
		token.kind = Token_Ident;
		while (rune_is_letter(t->curr_rune) || rune_is_digit(t->curr_rune)) {
			advance_to_next_rune(t);
		}

		token.string.len = t->curr - token.string.text;

		// NOTE(bill): All keywords are > 1
		if (token.string.len > 1) {
			for (i32 k = Token__KeywordBegin+1; k < Token__KeywordEnd; k++) {
				if (token.string == token_strings[k]) {
					token.kind = cast(TokenKind)k;
					break;
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

		case '\'': // Rune Literal
		{
			token.kind = Token_Rune;
			Rune quote = curr_rune;
			bool valid = true;
			i32 n = 0, success;
			for (;;) {
				Rune r = t->curr_rune;
				if (r == '\n' || r < 0) {
					tokenizer_err(t, "Rune literal not terminated");
					break;
				}
				advance_to_next_rune(t);
				if (r == quote) {
					break;
				}
				n++;
				if (r == '\\') {
					if (!scan_escape(t, quote)) {
						valid = false;
					}
				}
			}

			// TODO(bill): Better Error Handling
			if (valid && n != 1) {
				tokenizer_err(t, "Invalid rune literal");
			}
			token.string.len = t->curr - token.string.text;
			success = unquote_string(heap_allocator(), &token.string);
			if (success > 0) {
				if (success == 2) {
					array_add(&t->allocated_strings, token.string);
				}
				return token;
			} else {
				tokenizer_err(t, "Invalid rune literal");
			}
		} break;

		case '`': // Raw String Literal
		case '"': // String Literal
		{
			i32 success;
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
					if (r == quote) {
						break;
					}
					if (r == '\\') {
						scan_escape(t, quote);
					}
				}
			} else {
				for (;;) {
					Rune r = t->curr_rune;
					if (r < 0) {
						tokenizer_err(t, "String literal not terminated");
						break;
					}
					advance_to_next_rune(t);
					if (r == quote) {
						break;
					}
				}
			}
			token.string.len = t->curr - token.string.text;
			success = unquote_string(heap_allocator(), &token.string);
			if (success > 0) {
				if (success == 2) {
					array_add(&t->allocated_strings, token.string);
				}
				return token;
			} else {
				tokenizer_err(t, "Invalid string literal");
			}
		} break;

		case '.':
			token.kind = Token_Period; // Default
			if (t->curr_rune == '.') { // Could be an ellipsis
				advance_to_next_rune(t);
				token.kind = Token_HalfClosed;
				if (t->curr_rune == '.') {
					advance_to_next_rune(t);
					token.kind = Token_Ellipsis;
				}
			}
			break;

		case '#':  token.kind = Token_Hash;         break;
		case '@':  token.kind = Token_At;           break;
		case '$':  token.kind = Token_Dollar;       break;
		case '?':  token.kind = Token_Question;     break;
		case '^':  token.kind = Token_Pointer;      break;
		case ';':  token.kind = Token_Semicolon;    break;
		case ',':  token.kind = Token_Comma;        break;
		case ':':  token.kind = Token_Colon;        break;
		case '(':  token.kind = Token_OpenParen;    break;
		case ')':  token.kind = Token_CloseParen;   break;
		case '[':  token.kind = Token_OpenBracket;  break;
		case ']':  token.kind = Token_CloseBracket; break;
		case '{':  token.kind = Token_OpenBrace;    break;
		case '}':  token.kind = Token_CloseBrace;   break;
		case '\\': token.kind = Token_BackSlash;    break;

		case 0x2260:  token.kind = Token_NotEq; break; // '≠'
		case 0x2264:  token.kind = Token_LtEq;  break; // '≤'
		case 0x2265:  token.kind = Token_GtEq;  break; // '≥'

		case '%': token.kind = token_kind_dub_eq(t, '%', Token_Mod, Token_ModEq, Token_ModMod, Token_ModModEq);      break;

		case '*': token.kind = token_kind_variant2(t, Token_Mul, Token_MulEq);                                        break;
		case '=':
			token.kind = Token_Eq;
			if (t->curr_rune == '>') {
				advance_to_next_rune(t);
				token.kind = Token_DoubleArrowRight;
			} else if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token.kind = Token_CmpEq;
			}
			break;
		case '~': token.kind = token_kind_variant2(t, Token_Xor, Token_XorEq);                                        break;
		case '!': token.kind = token_kind_variant2(t, Token_Not, Token_NotEq);                                        break;
		// case '+': token.kind = token_kind_variant3(t, Token_Add, Token_AddEq, '+', Token_Inc);                        break;
		case '+': token.kind = token_kind_variant2(t, Token_Add, Token_AddEq);                                        break;
		case '-':
			token.kind = Token_Sub;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token.kind = Token_SubEq;
			} else if (t->curr_rune == '-') {
				advance_to_next_rune(t);
				token.kind = Token_Invalid;
				if (t->curr_rune == '-') {
					advance_to_next_rune(t);
					token.kind = Token_Undef;
				}
			} else if (t->curr_rune == '>') {
				advance_to_next_rune(t);
				token.kind = Token_ArrowRight;
			}
			break;

		case '/': {
			if (t->curr_rune == '/') {
				while (t->curr_rune != '\n' && t->curr_rune != GB_RUNE_EOF) {
					advance_to_next_rune(t);
				}
				token.kind = Token_Comment;
			} else if (t->curr_rune == '*') {
				isize comment_scope = 1;
				advance_to_next_rune(t);
				while (comment_scope > 0) {
					if (t->curr_rune == GB_RUNE_EOF) {
						break;
					} else if (t->curr_rune == '/') {
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
				token.kind = Token_Comment;
			} else {
				token.kind = token_kind_variant2(t, Token_Quo, Token_QuoEq);
			}
		} break;

		case '<':
			if (t->curr_rune == '-') {
				advance_to_next_rune(t);
				token.kind = Token_ArrowLeft;
			} else {
				token.kind = token_kind_dub_eq(t, '<', Token_Lt, Token_LtEq, Token_Shl, Token_ShlEq);
			}
			break;
		case '>': token.kind = token_kind_dub_eq(t, '>', Token_Gt, Token_GtEq, Token_Shr, Token_ShrEq); break;

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
