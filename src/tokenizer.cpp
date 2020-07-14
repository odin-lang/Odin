#define TOKEN_KINDS \
	TOKEN_KIND(Token_Invalid, "Invalid"), \
	TOKEN_KIND(Token_EOF,     "EOF"), \
	TOKEN_KIND(Token_Comment, "Comment"), \
\
TOKEN_KIND(Token__LiteralBegin, ""), \
	TOKEN_KIND(Token_Ident,     "identifier"), \
	TOKEN_KIND(Token_Integer,   "integer"), \
	TOKEN_KIND(Token_Float,     "float"), \
	TOKEN_KIND(Token_Imag,      "imaginary"), \
	TOKEN_KIND(Token_Rune,      "rune"), \
	TOKEN_KIND(Token_String,    "string"), \
TOKEN_KIND(Token__LiteralEnd,   ""), \
\
TOKEN_KIND(Token__OperatorBegin, ""), \
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
	TOKEN_KIND(Token_CmpAnd,   "&&"), \
	TOKEN_KIND(Token_CmpOr,    "||"), \
\
TOKEN_KIND(Token__AssignOpBegin, ""), \
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
TOKEN_KIND(Token__AssignOpEnd, ""), \
	TOKEN_KIND(Token_ArrowRight,       "->"), \
	TOKEN_KIND(Token_ArrowLeft,        "<-"), \
	TOKEN_KIND(Token_DoubleArrowRight, "=>"), \
	TOKEN_KIND(Token_Undef,            "---"), \
\
TOKEN_KIND(Token__ComparisonBegin, ""), \
	TOKEN_KIND(Token_CmpEq, "=="), \
	TOKEN_KIND(Token_NotEq, "!="), \
	TOKEN_KIND(Token_Lt,    "<"), \
	TOKEN_KIND(Token_Gt,    ">"), \
	TOKEN_KIND(Token_LtEq,  "<="), \
	TOKEN_KIND(Token_GtEq,  ">="), \
TOKEN_KIND(Token__ComparisonEnd, ""), \
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
	TOKEN_KIND(Token_Ellipsis,      ".."),  \
	TOKEN_KIND(Token_RangeHalf,     "..<"), \
	TOKEN_KIND(Token_BackSlash,     "\\"),  \
TOKEN_KIND(Token__OperatorEnd, ""), \
\
TOKEN_KIND(Token__KeywordBegin, ""), \
	TOKEN_KIND(Token_import,      "import"),      \
	TOKEN_KIND(Token_foreign,     "foreign"),     \
	TOKEN_KIND(Token_package,     "package"),     \
	TOKEN_KIND(Token_typeid,      "typeid"),      \
	TOKEN_KIND(Token_when,        "when"),        \
	TOKEN_KIND(Token_where,       "where"),       \
	TOKEN_KIND(Token_if,          "if"),          \
	TOKEN_KIND(Token_else,        "else"),        \
	TOKEN_KIND(Token_for,         "for"),         \
	TOKEN_KIND(Token_switch,      "switch"),      \
	TOKEN_KIND(Token_in,          "in"),          \
	TOKEN_KIND(Token_not_in,      "not_in"),      \
	TOKEN_KIND(Token_do,          "do"),          \
	TOKEN_KIND(Token_case,        "case"),        \
	TOKEN_KIND(Token_break,       "break"),       \
	TOKEN_KIND(Token_continue,    "continue"),    \
	TOKEN_KIND(Token_fallthrough, "fallthrough"), \
	TOKEN_KIND(Token_defer,       "defer"),       \
	TOKEN_KIND(Token_return,      "return"),      \
	TOKEN_KIND(Token_proc,        "proc"),        \
	TOKEN_KIND(Token_struct,      "struct"),      \
	TOKEN_KIND(Token_union,       "union"),       \
	TOKEN_KIND(Token_enum,        "enum"),        \
	TOKEN_KIND(Token_bit_field,   "bit_field"),   \
	TOKEN_KIND(Token_bit_set,     "bit_set"),     \
	TOKEN_KIND(Token_map,         "map"),         \
	TOKEN_KIND(Token_dynamic,     "dynamic"),     \
	TOKEN_KIND(Token_auto_cast,   "auto_cast"),   \
	TOKEN_KIND(Token_cast,        "cast"),        \
	TOKEN_KIND(Token_transmute,   "transmute"),   \
	TOKEN_KIND(Token_distinct,    "distinct"),    \
	TOKEN_KIND(Token_opaque,      "opaque"),      \
	TOKEN_KIND(Token_using,       "using"),       \
	TOKEN_KIND(Token_inline,      "inline"),      \
	TOKEN_KIND(Token_no_inline,   "no_inline"),   \
	TOKEN_KIND(Token_context,     "context"),     \
	TOKEN_KIND(Token_macro,       "macro"),       \
	TOKEN_KIND(Token_const,       "const"),       \
TOKEN_KIND(Token__KeywordEnd, ""), \
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


struct KeywordHashEntry {
	u32       hash;
	TokenKind kind;
	String    text;
};

enum {
	KEYWORD_HASH_TABLE_COUNT = 1<<9,
	KEYWORD_HASH_TABLE_MASK = KEYWORD_HASH_TABLE_COUNT-1,
};
gb_global KeywordHashEntry keyword_hash_table[KEYWORD_HASH_TABLE_COUNT] = {};
GB_STATIC_ASSERT(Token__KeywordEnd-Token__KeywordBegin <= gb_count_of(keyword_hash_table));
gb_global isize const min_keyword_size = 2;
gb_global isize max_keyword_size = 11;
gb_global bool keyword_indices[16] = {};


gb_inline u32 keyword_hash(u8 const *text, isize len) {
	return fnv32a(text, len);
	// return murmur3_32(text, len, 0x6f64696e);
}
void add_keyword_hash_entry(String const &s, TokenKind kind) {
	max_keyword_size = gb_max(max_keyword_size, s.len);

	keyword_indices[s.len] = true;

	u32 hash = keyword_hash(s.text, s.len);

	// NOTE(bill): This is a bit of an empirical hack in order to speed things up
	u32 index = hash & KEYWORD_HASH_TABLE_MASK;
	KeywordHashEntry *entry = &keyword_hash_table[index];
	GB_ASSERT_MSG(entry->kind == Token_Invalid, "Keyword hash table initialtion collision: %.*s %.*s %08x %08x", LIT(s), LIT(token_strings[entry->kind]), hash, entry->hash);
	entry->hash = hash;
	entry->kind = kind;
	entry->text = s;
}
void init_keyword_hash_table(void) {
	for (i32 kind = Token__KeywordBegin+1; kind < Token__KeywordEnd; kind++) {
		add_keyword_hash_entry(token_strings[kind], cast(TokenKind)kind);
	}

	static struct {
		String s;
		TokenKind kind;
	} const legacy_keywords[] = {
		{str_lit("notin"), Token_not_in},
	};

	for (i32 i = 0; i < gb_count_of(legacy_keywords); i++) {
		add_keyword_hash_entry(legacy_keywords[i].s, legacy_keywords[i].kind);
	}

	GB_ASSERT(max_keyword_size < 16);
}


struct TokenPos {
	String file;
	isize  offset; // starting at 0
	isize  line;   // starting at 1
	isize  column; // starting at 1
};

i32 token_pos_cmp(TokenPos const &a, TokenPos const &b) {
	if (a.offset != b.offset) {
		return (a.offset < b.offset) ? -1 : +1;
	}
	if (a.line != b.line) {
		return (a.line < b.line) ? -1 : +1;
	}
	if (a.column != b.column) {
		return (a.column < b.column) ? -1 : +1;
	}
	return string_compare(a.file, b.file);
}

bool operator==(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) == 0; }
bool operator!=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) != 0; }
bool operator< (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <  0; }
bool operator<=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <= 0; }
bool operator> (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >  0; }
bool operator>=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >= 0; }

struct Token {
	TokenKind kind;
	String    string;
	TokenPos  pos;
};

Token empty_token = {Token_Invalid};
Token blank_token = {Token_Ident, {cast(u8 *)"_", 1}};

Token make_token_ident(String s) {
	Token t = {Token_Ident, s};
	return t;
}
Token make_token_ident(char const *s) {
	Token t = {Token_Ident, make_string_c(s)};
	return t;
}


struct ErrorCollector {
	TokenPos prev;
	i64     count;
	i64     warning_count;
	bool    in_block;
	gbMutex mutex;

	Array<u8> error_buffer;
	Array<String> errors;
};

gb_global ErrorCollector global_error_collector;

#define MAX_ERROR_COLLECTOR_COUNT (36)


void init_global_error_collector(void) {
	gb_mutex_init(&global_error_collector.mutex);
	array_init(&global_error_collector.errors, heap_allocator());
	array_init(&global_error_collector.error_buffer, heap_allocator());
}


void begin_error_block(void) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.in_block = true;
}

void end_error_block(void) {
	if (global_error_collector.error_buffer.count > 0) {
		isize n = global_error_collector.error_buffer.count;
		u8 *text = gb_alloc_array(heap_allocator(), u8, n+1);
		gb_memmove(text, global_error_collector.error_buffer.data, n);
		text[n] = 0;
		String s = {text, n};
		array_add(&global_error_collector.errors, s);
		global_error_collector.error_buffer.count = 0;

		// gbFile *f = gb_file_get_standard(gbFileStandard_Error);
		// gb_file_write(f, text, n);
	}

	global_error_collector.in_block = false;
	gb_mutex_unlock(&global_error_collector.mutex);
}


#define ERROR_OUT_PROC(name) void name(char const *fmt, va_list va)
typedef ERROR_OUT_PROC(ErrorOutProc);

ERROR_OUT_PROC(default_error_out_va) {
	gbFile *f = gb_file_get_standard(gbFileStandard_Error);

	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	isize n = len-1;
	if (global_error_collector.in_block) {
		isize cap = global_error_collector.error_buffer.count + n;
		array_reserve(&global_error_collector.error_buffer, cap);
		u8 *data = global_error_collector.error_buffer.data + global_error_collector.error_buffer.count;
		gb_memmove(data, buf, n);
		global_error_collector.error_buffer.count += n;
	} else {
		gb_mutex_lock(&global_error_collector.mutex);
		{
			u8 *text = gb_alloc_array(heap_allocator(), u8, n+1);
			gb_memmove(text, buf, n);
			text[n] = 0;
			array_add(&global_error_collector.errors, make_string(text, n));
		}
		gb_mutex_unlock(&global_error_collector.mutex);

	}
	gb_file_write(f, buf, n);
}


ErrorOutProc *error_out_va = default_error_out_va;

void error_out(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_out_va(fmt, va);
	va_end(va);
}

void warning_va(Token token, char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	// NOTE(bill): Duplicate error, skip it
	if (token.pos.line == 0) {
		error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		error_out("%.*s(%td:%td) Warning: %s\n",
		          LIT(token.pos.file), token.pos.line, token.pos.column,
		          gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}


void error_va(Token token, char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (token.pos.line == 0) {
		error_out("Error: %s\n", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		error_out("%.*s(%td:%td) %s\n",
		          LIT(token.pos.file), token.pos.line, token.pos.column,
		          gb_bprintf_va(fmt, va));
	}
	gb_mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void error_line_va(char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	error_out_va(fmt, va);
	gb_mutex_unlock(&global_error_collector.mutex);
}

void error_no_newline_va(Token token, char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (token.pos.line == 0) {
		error_out("Error: %s", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		error_out("%.*s(%td:%td) %s",
		          LIT(token.pos.file), token.pos.line, token.pos.column,
		          gb_bprintf_va(fmt, va));
	}
	gb_mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}


void syntax_error_va(Token token, char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		error_out("%.*s(%td:%td) Syntax Error: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
	} else if (token.pos.line == 0) {
		error_out("Syntax Error: %s\n", gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void syntax_warning_va(Token token, char const *fmt, va_list va) {
	gb_mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != token.pos) {
		global_error_collector.prev = token.pos;
		error_out("%.*s(%td:%td) Syntax Warning: %s\n",
		          LIT(token.pos.file), token.pos.line, token.pos.column,
		          gb_bprintf_va(fmt, va));
	} else if (token.pos.line == 0) {
		error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
	}

	gb_mutex_unlock(&global_error_collector.mutex);
}



void warning(Token token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(token, fmt, va);
	va_end(va);
}

void error(Token token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(token, fmt, va);
	va_end(va);
}

void error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	Token token = {};
	token.pos = pos;
	error_va(token, fmt, va);
	va_end(va);
}

void error_line(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_line_va(fmt, va);
	va_end(va);
}


void syntax_error(Token token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token, fmt, va);
	va_end(va);
}

void syntax_error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	Token token = {};
	token.pos = pos;
	syntax_error_va(token, fmt, va);
	va_end(va);
}

void syntax_warning(Token token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_warning_va(token, fmt, va);
	va_end(va);
}


void compiler_error(char const *fmt, ...) {
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


void tokenizer_err(Tokenizer *t, char const *msg, ...) {
	va_list va;
	isize column = t->read_curr - t->line+1;
	if (column < 1) {
		column = 1;
	}
	Token token = {};
	token.pos.file = t->fullpath;
	token.pos.line = t->line_count;
	token.pos.column = column;

	va_start(va, msg);
	syntax_error_va(token, msg, va);
	va_end(va);

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
			if (rune == GB_RUNE_INVALID && width == 1) {
				tokenizer_err(t, "Illegal UTF-8 encoding");
			} else if (rune == GB_RUNE_BOM && t->curr-t->start > 0){
				tokenizer_err(t, "Illegal byte order mark");
			}
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

	char *c_str = alloc_cstring(heap_allocator(), fullpath);
	defer (gb_free(heap_allocator(), c_str));

	// TODO(bill): Memory map rather than copy contents
	gbFileContents fc = gb_file_read_contents(heap_allocator(), true, c_str);
	gb_zero_item(t);

	t->fullpath = fullpath;
	t->line_count = 1;

	if (fc.data != nullptr) {
		t->start = cast(u8 *)fc.data;
		t->line = t->read_curr = t->curr = t->start;
		t->end = t->start + fc.size;

		advance_to_next_rune(t);
		if (t->curr_rune == GB_RUNE_BOM) {
			advance_to_next_rune(t); // Ignore BOM at file beginning
		}

		array_init(&t->allocated_strings, heap_allocator());
	} else {
		gbFile f = {};
		gbFileError file_err = gb_file_open(&f, c_str);
		defer (gb_file_close(&f));

		switch (file_err) {
		case gbFileError_Invalid:    err = TokenizerInit_Invalid;    break;
		case gbFileError_NotExists:  err = TokenizerInit_NotExists;  break;
		case gbFileError_Permission: err = TokenizerInit_Permission; break;
		}

		if (err == TokenizerInit_None && gb_file_size(&f) == 0) {
			err = TokenizerInit_Empty;
		}
	}

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

gb_inline i32 digit_value(Rune r) {
	switch (r) {
	case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
		return r - '0';
	case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
		return r - 'a' + 10;
	case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
		return r - 'A' + 10;
	}
	return 16; // NOTE(bill): Larger than highest possible
}

gb_inline void scan_mantissa(Tokenizer *t, i32 base) {
	while (digit_value(t->curr_rune) < base || t->curr_rune == '_') {
		advance_to_next_rune(t);
	}
}

u8 peek_byte(Tokenizer *t, isize offset=0) {
	if (t->read_curr+offset < t->end) {
		return t->read_curr[offset];
	}
	return 0;
}

void scan_number_to_token(Tokenizer *t, Token *token, bool seen_decimal_point) {
	token->kind = Token_Integer;
	token->string = {t->curr, 1};
	token->pos.file = t->fullpath;
	token->pos.line = t->line_count;
	token->pos.column = t->curr-t->line+1;

	if (seen_decimal_point) {
		token->string.text -= 1;
		token->string.len  += 1;
		token->pos.column -= 1;
		token->kind = Token_Float;
		scan_mantissa(t, 10);
		goto exponent;
	}

	if (t->curr_rune == '0') {
		u8 *prev = t->curr;
		advance_to_next_rune(t);
		switch (t->curr_rune) {
		case 'b': // Binary
			advance_to_next_rune(t);
			scan_mantissa(t, 2);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			}
			goto end;
		case 'o': // Octal
			advance_to_next_rune(t);
			scan_mantissa(t, 8);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			}
			goto end;
		case 'd': // Decimal
			advance_to_next_rune(t);
			scan_mantissa(t, 10);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			}
			goto end;
		case 'z': // Dozenal
			advance_to_next_rune(t);
			scan_mantissa(t, 12);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			}
			goto end;
		case 'x': // Hexadecimal
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			}
			goto end;
		case 'h': // Hexadecimal Float
			token->kind = Token_Float;
			advance_to_next_rune(t);
			scan_mantissa(t, 16);
			if (t->curr - prev <= 2) {
				token->kind = Token_Invalid;
			} else {
				u8 *start = prev+2;
				isize n = t->curr - start;
				isize digit_count = 0;
				for (isize i = 0; i < n; i++) {
					if (start[i] != '_') {
						digit_count += 1;
					}
				}
				switch (digit_count) {
				case 8:
				case 16:
					break;
				default:
					tokenizer_err(t, "Invalid hexadecimal float, expected 8 or 16 digits, got %td", digit_count);
					break;
				}
			}
			goto end;
		default:
			scan_mantissa(t, 10);
			goto fraction;
		}
	}

	scan_mantissa(t, 10);


fraction:
	if (t->curr_rune == '.') {
		if (peek_byte(t) == '.') {
			// NOTE(bill): this is kind of ellipsis
			goto end;
		}
		advance_to_next_rune(t);

		token->kind = Token_Float;
		scan_mantissa(t, 10);
	}

exponent:
	if (t->curr_rune == 'e' || t->curr_rune == 'E') {
		token->kind = Token_Float;
		advance_to_next_rune(t);
		if (t->curr_rune == '-' || t->curr_rune == '+') {
			advance_to_next_rune(t);
		}
		scan_mantissa(t, 10);
	}

	switch (t->curr_rune) {
	case 'i': case 'j': case 'k':
		token->kind = Token_Imag;
		advance_to_next_rune(t);
		break;
	}

end:
	token->string.len = t->curr - token->string.text;
	return;
}


bool scan_escape(Tokenizer *t) {
	isize len = 0;
	u32 base = 0, max = 0, x = 0;

	Rune r = t->curr_rune;
	switch (r) {
	case 'a':
	case 'b':
	case 'e':
	case 'f':
	case 'n':
	case 'r':
	case 't':
	case 'v':
	case '\\':
	case '\'':
	case '\"':
		advance_to_next_rune(t);
		return true;

	case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7':
		len = 3; base = 8; max = 255;
		break;

	case 'x':
		advance_to_next_rune(t);
		len = 2; base = 16; max = 255;
		break;

	case 'u':
		advance_to_next_rune(t);
		len = 4; base = 16; max = GB_RUNE_MAX;
		break;

	case 'U':
		advance_to_next_rune(t);
		len = 8; base = 16; max = GB_RUNE_MAX;
		break;

	default:
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


void tokenizer_get_token(Tokenizer *t, Token *token) {
	// Skip whitespace
	for (;;) {
		switch (t->curr_rune) {
		case ' ':
		case '\t':
		case '\n':
		case '\r':
			advance_to_next_rune(t);
			continue;
		}
		break;
	}

	token->kind = Token_Invalid;
	token->string.text = t->curr;
	token->string.len  = 1;
	token->pos.file.text = t->fullpath.text;
	token->pos.file.len  = t->fullpath.len;
	token->pos.line = t->line_count;
	token->pos.offset = t->curr - t->start;
	token->pos.column = t->curr - t->line + 1;

	Rune curr_rune = t->curr_rune;
	if (rune_is_letter(curr_rune)) {
		token->kind = Token_Ident;
		while (rune_is_letter_or_digit(t->curr_rune)) {
			advance_to_next_rune(t);
		}

		token->string.len = t->curr - token->string.text;

		// NOTE(bill): Heavily optimize to make it faster to find keywords
		if (1 < token->string.len && token->string.len <= max_keyword_size && keyword_indices[token->string.len]) {
			u32 hash = keyword_hash(token->string.text, token->string.len);
			u32 index = hash & KEYWORD_HASH_TABLE_MASK;
			KeywordHashEntry *entry = &keyword_hash_table[index];
			if (entry->kind != Token_Invalid && entry->hash == hash) {
				if (str_eq(entry->text, token->string)) {
					token->kind = entry->kind;
					if (token->kind == Token_not_in && entry->text == "notin") {
						syntax_warning(*token, "'notin' is deprecated in favour of 'not_in'");
					}
				}
			}
		}
		return;

	} else if (gb_is_between(curr_rune, '0', '9')) {
		scan_number_to_token(t, token, false);
	} else {
		advance_to_next_rune(t);
		switch (curr_rune) {
		case GB_RUNE_EOF:
			token->kind = Token_EOF;
			break;

		case '\'': // Rune Literal
		{
			token->kind = Token_Rune;
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
					if (!scan_escape(t)) {
						valid = false;
					}
				}
			}

			// TODO(bill): Better Error Handling
			if (valid && n != 1) {
				tokenizer_err(t, "Invalid rune literal");
			}
			token->string.len = t->curr - token->string.text;
			success = unquote_string(heap_allocator(), &token->string, 0);
			if (success > 0) {
				if (success == 2) {
					array_add(&t->allocated_strings, token->string);
				}
			} else {
				tokenizer_err(t, "Invalid rune literal");
			}
			return;
		} break;

		case '`': // Raw String Literal
		case '"': // String Literal
		{
			bool has_carriage_return = false;
			i32 success;
			Rune quote = curr_rune;
			token->kind = Token_String;
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
						scan_escape(t);
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
					if (r == '\r') {
						has_carriage_return = true;
					}
				}
			}
			token->string.len = t->curr - token->string.text;
			success = unquote_string(heap_allocator(), &token->string, 0, has_carriage_return);
			if (success > 0) {
				if (success == 2) {
					array_add(&t->allocated_strings, token->string);
				}
			} else {
				tokenizer_err(t, "Invalid string literal");
			}
			return;
		} break;

		case '.':
			if (t->curr_rune == '.') {
				advance_to_next_rune(t);
				token->kind = Token_Ellipsis;
				if (t->curr_rune == '<') {
					advance_to_next_rune(t);
					token->kind = Token_RangeHalf;
				}
			} else if ('0' <= t->curr_rune && t->curr_rune <= '9') {
				scan_number_to_token(t, token, true);
			} else {
				token->kind = Token_Period;
			}
			break;

		case '@':  token->kind = Token_At;           break;
		case '$':  token->kind = Token_Dollar;       break;
		case '?':  token->kind = Token_Question;     break;
		case '^':  token->kind = Token_Pointer;      break;
		case ';':  token->kind = Token_Semicolon;    break;
		case ',':  token->kind = Token_Comma;        break;
		case ':':  token->kind = Token_Colon;        break;
		case '(':  token->kind = Token_OpenParen;    break;
		case ')':  token->kind = Token_CloseParen;   break;
		case '[':  token->kind = Token_OpenBracket;  break;
		case ']':  token->kind = Token_CloseBracket; break;
		case '{':  token->kind = Token_OpenBrace;    break;
		case '}':  token->kind = Token_CloseBrace;   break;
		case '\\': token->kind = Token_BackSlash;    break;

		case '%':
			token->kind = Token_Mod;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_ModEq;
			} else if (t->curr_rune == '%') {
				token->kind = Token_ModMod;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ModModEq;
					advance_to_next_rune(t);
				}
			}
			break;

		case '*':
			token->kind = Token_Mul;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_MulEq;
			}
			break;
		case '=':
			token->kind = Token_Eq;
			if (t->curr_rune == '>') {
				advance_to_next_rune(t);
				token->kind = Token_DoubleArrowRight;
			} else if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_CmpEq;
			}
			break;
		case '~':
			token->kind = Token_Xor;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_XorEq;
			}
			break;
		case '!':
			token->kind = Token_Not;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_NotEq;
			}
			break;
		case '+':
			token->kind = Token_Add;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_AddEq;
			}
			break;
		case '-':
			token->kind = Token_Sub;
			if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_SubEq;
			} else if (t->curr_rune == '-' && peek_byte(t) == '-') {
				advance_to_next_rune(t);
				advance_to_next_rune(t);
				token->kind = Token_Undef;
			} else if (t->curr_rune == '>') {
				advance_to_next_rune(t);
				token->kind = Token_ArrowRight;
			}
			break;

		case '#':
			if (t->curr_rune == '!') {
				while (t->curr_rune != '\n' && t->curr_rune != GB_RUNE_EOF) {
					advance_to_next_rune(t);
				}
				token->kind = Token_Comment;
			} else {
				token->kind = Token_Hash;
			}
			break;


		case '/': {
			token->kind = Token_Quo;
			if (t->curr_rune == '/') {
				token->kind = Token_Comment;

				while (t->curr_rune != '\n' && t->curr_rune != GB_RUNE_EOF) {
					advance_to_next_rune(t);
				}
			} else if (t->curr_rune == '*') {
				token->kind = Token_Comment;

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
			} else if (t->curr_rune == '=') {
				advance_to_next_rune(t);
				token->kind = Token_QuoEq;
			}
		} break;

		case '<':
			token->kind = Token_Lt;
			if (t->curr_rune == '-') {
				advance_to_next_rune(t);
				token->kind = Token_ArrowLeft;
			} else if (t->curr_rune == '=') {
				token->kind = Token_LtEq;
				advance_to_next_rune(t);
			} else if (t->curr_rune == '<') {
				token->kind = Token_Shl;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ShlEq;
					advance_to_next_rune(t);
				}
			}
			break;

		case '>':
			token->kind = Token_Gt;
			if (t->curr_rune == '=') {
				token->kind = Token_GtEq;
				advance_to_next_rune(t);
			} else if (t->curr_rune == '>') {
				token->kind = Token_Shr;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ShrEq;
					advance_to_next_rune(t);
				}
			}
			break;

		case '&':
			token->kind = Token_And;
			if (t->curr_rune == '~') {
				token->kind = Token_AndNot;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_AndNotEq;
					advance_to_next_rune(t);
				}
			} else if (t->curr_rune == '=') {
				token->kind = Token_AndEq;
				advance_to_next_rune(t);
			} else if (t->curr_rune == '&') {
				token->kind = Token_CmpAnd;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_CmpAndEq;
					advance_to_next_rune(t);
				}
			}
			break;

		case '|':
			token->kind = Token_Or;
			if (t->curr_rune == '=') {
				token->kind = Token_OrEq;
				advance_to_next_rune(t);
			} else if (t->curr_rune == '|') {
				token->kind = Token_CmpOr;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_CmpOrEq;
					advance_to_next_rune(t);
				}
			}
			break;

		default:
			if (curr_rune != GB_RUNE_BOM) {
				u8 str[4] = {};
				int len = cast(int)gb_utf8_encode_rune(str, curr_rune);
				tokenizer_err(t, "Illegal character: %.*s (%d) ", len, str, curr_rune);
			}
			token->kind = Token_Invalid;
			break;
		}
	}

	token->string.len = t->curr - token->string.text;
	return;
}
