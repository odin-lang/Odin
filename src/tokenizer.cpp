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
	TOKEN_KIND(Token_Increment, "++"), \
	TOKEN_KIND(Token_Decrement, "--"), \
	TOKEN_KIND(Token_ArrowRight,"->"), \
	TOKEN_KIND(Token_Undef,     "---"), \
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
	TOKEN_KIND(Token_RangeFull,     "..="), \
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
	TOKEN_KIND(Token_bit_set,     "bit_set"),     \
	TOKEN_KIND(Token_map,         "map"),         \
	TOKEN_KIND(Token_dynamic,     "dynamic"),     \
	TOKEN_KIND(Token_auto_cast,   "auto_cast"),   \
	TOKEN_KIND(Token_cast,        "cast"),        \
	TOKEN_KIND(Token_transmute,   "transmute"),   \
	TOKEN_KIND(Token_distinct,    "distinct"),    \
	TOKEN_KIND(Token_using,       "using"),       \
	TOKEN_KIND(Token_context,     "context"),     \
	TOKEN_KIND(Token_or_else,     "or_else"),     \
	TOKEN_KIND(Token_or_return,   "or_return"),   \
	TOKEN_KIND(Token_asm,         "asm"),         \
	TOKEN_KIND(Token_matrix,      "matrix"),      \
TOKEN_KIND(Token__KeywordEnd, ""), \
	TOKEN_KIND(Token_Count, "")

enum TokenKind : u8 {
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
}
void add_keyword_hash_entry(String const &s, TokenKind kind) {
	max_keyword_size = gb_max(max_keyword_size, s.len);

	keyword_indices[s.len] = true;

	u32 hash = keyword_hash(s.text, s.len);

	// NOTE(bill): This is a bit of an empirical hack in order to speed things up
	u32 index = hash & KEYWORD_HASH_TABLE_MASK;
	KeywordHashEntry *entry = &keyword_hash_table[index];
	GB_ASSERT_MSG(entry->kind == Token_Invalid, "Keyword hash table initialtion collision: %.*s %.*s 0x%08x 0x%08x", LIT(s), LIT(token_strings[entry->kind]), hash, entry->hash);
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

gb_global Array<String>           global_file_path_strings; // index is file id
gb_global Array<struct AstFile *> global_files; // index is file id

String   get_file_path_string(i32 index);
struct AstFile *thread_safe_get_ast_file_from_id(i32 index);

struct TokenPos {
	i32 file_id;
	i32 offset; // starting at 0
	i32 line;   // starting at 1
	i32 column; // starting at 1
};

// temporary
char *token_pos_to_string(TokenPos const &pos) {
	gbString s = gb_string_make_reserve(temporary_allocator(), 128);
	String file = get_file_path_string(pos.file_id);
	s = gb_string_append_fmt(s, "%.*s(%d:%d)", LIT(file), pos.line, pos.column);
	return s;
}

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
	return string_compare(get_file_path_string(a.file_id), get_file_path_string(b.file_id));
}

bool operator==(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) == 0; }
bool operator!=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) != 0; }
bool operator< (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <  0; }
bool operator<=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) <= 0; }
bool operator> (TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >  0; }
bool operator>=(TokenPos const &a, TokenPos const &b) { return token_pos_cmp(a, b) >= 0; }


TokenPos token_pos_add_column(TokenPos pos) {
	pos.column += 1;
	pos.offset += 1;
	return pos;
}

enum TokenFlag : u8 {
	TokenFlag_Remove  = 1<<1,
	TokenFlag_Replace = 1<<2,
};

struct Token {
	TokenKind kind;
	u8        flags;
	String    string;
	TokenPos  pos;
};

Token empty_token = {Token_Invalid};
Token blank_token = {Token_Ident, 0, {cast(u8 *)"_", 1}};

Token make_token_ident(String s) {
	Token t = {Token_Ident, 0, s};
	return t;
}
Token make_token_ident(char const *s) {
	Token t = {Token_Ident, 0, make_string_c(s)};
	return t;
}

bool token_is_newline(Token const &tok) {
	return tok.kind == Token_Semicolon && tok.string == "\n";
}


struct ErrorCollector {
	TokenPos prev;
	std::atomic<i64>  count;
	std::atomic<i64>  warning_count;
	std::atomic<bool> in_block;
	BlockingMutex     mutex;
	BlockingMutex     error_out_mutex;
	BlockingMutex     string_mutex;
	RecursiveMutex    block_mutex;

	Array<u8> error_buffer;
	Array<String> errors;
};

gb_global ErrorCollector global_error_collector;

#define MAX_ERROR_COLLECTOR_COUNT (36)


bool any_errors(void) {
	return global_error_collector.count.load() != 0;
}

void init_global_error_collector(void) {
	mutex_init(&global_error_collector.mutex);
	mutex_init(&global_error_collector.block_mutex);
	mutex_init(&global_error_collector.error_out_mutex);
	mutex_init(&global_error_collector.string_mutex);
	array_init(&global_error_collector.errors, heap_allocator());
	array_init(&global_error_collector.error_buffer, heap_allocator());
	array_init(&global_file_path_strings, heap_allocator(), 1, 4096);
	array_init(&global_files,             heap_allocator(), 1, 4096);
}


bool set_file_path_string(i32 index, String const &path) {
	bool ok = false;
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	if (index >= global_file_path_strings.count) {
		array_resize(&global_file_path_strings, index+1);
	}
	String prev = global_file_path_strings[index];
	if (prev.len == 0) {
		global_file_path_strings[index] = path;
		ok = true;
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return ok;
}

bool thread_safe_set_ast_file_from_id(i32 index, AstFile *file) {
	bool ok = false;
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	if (index >= global_files.count) {
		array_resize(&global_files, index+1);
	}
	AstFile *prev = global_files[index];
	if (prev == nullptr) {
		global_files[index] = file;
		ok = true;
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return ok;
}

String get_file_path_string(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	String path = {};
	if (index < global_file_path_strings.count) {
		path = global_file_path_strings[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return path;
}

AstFile *thread_safe_get_ast_file_from_id(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	AstFile *file = nullptr;
	if (index < global_files.count) {
		file = global_files[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return file;
}



void begin_error_block(void) {
	mutex_lock(&global_error_collector.block_mutex);
	global_error_collector.in_block.store(true);
}

void end_error_block(void) {
	if (global_error_collector.error_buffer.count > 0) {
		isize n = global_error_collector.error_buffer.count;
		u8 *text = gb_alloc_array(permanent_allocator(), u8, n+1);
		gb_memmove(text, global_error_collector.error_buffer.data, n);
		text[n] = 0;
		String s = {text, n};
		array_add(&global_error_collector.errors, s);
		global_error_collector.error_buffer.count = 0;
	}

	global_error_collector.in_block.store(false);
	mutex_unlock(&global_error_collector.block_mutex);
}

#define ERROR_BLOCK() begin_error_block(); defer (end_error_block())


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
		mutex_lock(&global_error_collector.error_out_mutex);
		{
			u8 *text = gb_alloc_array(permanent_allocator(), u8, n+1);
			gb_memmove(text, buf, n);
			text[n] = 0;
			array_add(&global_error_collector.errors, make_string(text, n));
		}
		mutex_unlock(&global_error_collector.error_out_mutex);

	}
	gb_file_write(f, buf, n);
}


ErrorOutProc *error_out_va = default_error_out_va;

// NOTE: defined in build_settings.cpp
bool global_warnings_as_errors(void);
bool global_ignore_warnings(void);
bool show_error_line(void);
gbString get_file_line_as_string(TokenPos const &pos, i32 *offset);

void error_out(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_out_va(fmt, va);
	va_end(va);
}


bool show_error_on_line(TokenPos const &pos, TokenPos end) {
	if (!show_error_line()) {
		return false;
	}

	i32 offset = 0;
	gbString the_line = get_file_line_as_string(pos, &offset);
	defer (gb_string_free(the_line));

	if (the_line != nullptr) {
		String line = make_string(cast(u8 const *)the_line, gb_string_length(the_line));

		// TODO(bill): This assumes ASCII

		enum {
			MAX_LINE_LENGTH  = 76,
			MAX_TAB_WIDTH    = 8,
			ELLIPSIS_PADDING = 8
		};

		error_out("\n\t");
		if (line.len+MAX_TAB_WIDTH+ELLIPSIS_PADDING > MAX_LINE_LENGTH) {
			i32 const half_width = MAX_LINE_LENGTH/2;
			i32 left  = cast(i32)(offset);
			i32 right = cast(i32)(line.len - offset);
			left  = gb_min(left, half_width);
			right = gb_min(right, half_width);

			line.text += offset-left;
			line.len  -= offset+right-left;

			line = string_trim_whitespace(line);

			offset = left + ELLIPSIS_PADDING/2;

			error_out("... %.*s ...", LIT(line));
		} else {
			error_out("%.*s", LIT(line));
		}
		error_out("\n\t");

		for (i32 i = 0; i < offset; i++) {
			error_out(" ");
		}
		error_out("^");
		if (end.file_id == pos.file_id) {
			if (end.line > pos.line) {
				for (i32 i = offset; i < line.len; i++) {
					error_out("~");
				}
			} else if (end.line == pos.line && end.column > pos.column) {
				i32 length = gb_min(end.offset - pos.offset, cast(i32)(line.len-offset));
				for (i32 i = 1; i < length-1; i++) {
					error_out("~");
				}
				if (length > 1) {
					error_out("^");
				}
			}
		}

		error_out("\n\n");
		return true;
	}
	return false;
}

void error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);

	mutex_lock(&global_error_collector.mutex);
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out("Error: %s\n", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s %s\n",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
		show_error_on_line(pos, end);
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		error_va(pos, end, fmt, va);
		return;
	}
	global_error_collector.warning_count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (!global_ignore_warnings()) {
		// NOTE(bill): Duplicate error, skip it
		if (pos.line == 0) {
			error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
		} else if (global_error_collector.prev != pos) {
			global_error_collector.prev = pos;
			error_out("%s Warning: %s\n",
			          token_pos_to_string(pos),
			          gb_bprintf_va(fmt, va));
			show_error_on_line(pos, end);
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}


void error_line_va(char const *fmt, va_list va) {
	error_out_va(fmt, va);
}

void error_no_newline_va(TokenPos const &pos, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out("Error: %s", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s %s",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}


void syntax_error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s Syntax Error: %s\n",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
		show_error_on_line(pos, end);
	} else if (pos.line == 0) {
		error_out("Syntax Error: %s\n", gb_bprintf_va(fmt, va));
	}

	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void syntax_warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		syntax_error_va(pos, end, fmt, va);
		return;
	}
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	if (!global_ignore_warnings()) {
		// NOTE(bill): Duplicate error, skip it
		if (global_error_collector.prev != pos) {
			global_error_collector.prev = pos;
			error_out("%s Syntax Warning: %s\n",
			          token_pos_to_string(pos),
			          gb_bprintf_va(fmt, va));
			show_error_on_line(pos, end);
		} else if (pos.line == 0) {
			error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}



void warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(token.pos, {}, fmt, va);
	va_end(va);
}

void error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(token.pos, {}, fmt, va);
	va_end(va);
}

void error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	Token token = {};
	token.pos = pos;
	error_va(pos, {}, fmt, va);
	va_end(va);
}

void error_line(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_line_va(fmt, va);
	va_end(va);
}


void syntax_error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token.pos, {}, fmt, va);
	va_end(va);
}

void syntax_error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(pos, {}, fmt, va);
	va_end(va);
}

void syntax_warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_warning_va(token.pos, {}, fmt, va);
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
	TokenizerInit_FileTooLarge,

	TokenizerInit_Count,
};

struct Tokenizer {
	i32 curr_file_id;
	String fullpath;
	u8 *start;
	u8 *end;

	Rune  curr_rune;   // current character
	u8 *  curr;        // character pos
	u8 *  read_curr;   // pos from start
	i32   column_minus_one;
	i32   line_count;

	i32 error_count;

	bool insert_semicolon;
	
	LoadedFile loaded_file;
};


void tokenizer_err(Tokenizer *t, char const *msg, ...) {
	va_list va;
	i32 column = t->column_minus_one+1;
	if (column < 1) {
		column = 1;
	}
	TokenPos pos = {};
	pos.file_id = t->curr_file_id;
	pos.line = t->line_count;
	pos.column = cast(i32)column;
	pos.offset = cast(i32)(t->read_curr - t->start);

	va_start(va, msg);
	syntax_error_va(pos, {}, msg, va);
	va_end(va);

	t->error_count++;
}

void tokenizer_err(Tokenizer *t, TokenPos const &pos, char const *msg, ...) {
	va_list va;
	i32 column = t->column_minus_one+1;
	if (column < 1) {
		column = 1;
	}

	va_start(va, msg);
	syntax_error_va(pos, {}, msg, va);
	va_end(va);

	t->error_count++;
}

void advance_to_next_rune(Tokenizer *t) {
	if (t->curr_rune == '\n') {
		t->column_minus_one = -1;
		t->line_count++;
	}
	if (t->read_curr < t->end) {
		t->curr = t->read_curr;
		Rune rune = *t->read_curr;
		if (rune == 0) {
			tokenizer_err(t, "Illegal character NUL");
			t->read_curr++;
		} else if (rune & 0x80) { // not ASCII
			isize width = utf8_decode(t->read_curr, t->end-t->read_curr, &rune);
			t->read_curr += width;
			if (rune == GB_RUNE_INVALID && width == 1) {
				tokenizer_err(t, "Illegal UTF-8 encoding");
			} else if (rune == GB_RUNE_BOM && t->curr-t->start > 0){
				tokenizer_err(t, "Illegal byte order mark");
			}
		} else {
			t->read_curr++;
		}
		t->curr_rune = rune;
		t->column_minus_one++;
	} else {
		t->curr = t->end;
		t->curr_rune = GB_RUNE_EOF;
	}
}

void init_tokenizer_with_data(Tokenizer *t, String const &fullpath, void const *data, isize size) {
	t->fullpath = fullpath;
	t->line_count = 1;

	t->start = cast(u8 *)data;
	t->read_curr = t->curr = t->start;
	t->end = t->start + size;

	advance_to_next_rune(t);
	if (t->curr_rune == GB_RUNE_BOM) {
		advance_to_next_rune(t); // Ignore BOM at file beginning
	}
}

TokenizerInitError loaded_file_error_map_to_tokenizer[LoadedFile_COUNT] = {
	TokenizerInit_None,         /*LoadedFile_None*/
	TokenizerInit_Empty,        /*LoadedFile_Empty*/
	TokenizerInit_FileTooLarge, /*LoadedFile_FileTooLarge*/
	TokenizerInit_Invalid,      /*LoadedFile_Invalid*/
	TokenizerInit_NotExists,    /*LoadedFile_NotExists*/
	TokenizerInit_Permission,   /*LoadedFile_Permission*/
};

TokenizerInitError init_tokenizer_from_fullpath(Tokenizer *t, String const &fullpath, bool copy_file_contents) {
	LoadedFileError file_err = load_file_32(
		alloc_cstring(temporary_allocator(), fullpath), 
		&t->loaded_file,
		copy_file_contents
	);
	
	TokenizerInitError err = loaded_file_error_map_to_tokenizer[file_err];
	switch (file_err) {
	case LoadedFile_None:
		init_tokenizer_with_data(t, fullpath, t->loaded_file.data, cast(isize)t->loaded_file.size);
		break;
	case LoadedFile_FileTooLarge:
	case LoadedFile_Empty:
		t->fullpath = fullpath;
		t->line_count = 1;
		break;
	}	
	return err;
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
	token->pos.file_id = t->curr_file_id;
	token->pos.line = t->line_count;
	token->pos.column = t->column_minus_one+1;

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
				case 4:
				case 8:
				case 16:
					break;
				default:
					tokenizer_err(t, "Invalid hexadecimal float, expected 4, 8, or 16 digits, got %td", digit_count);
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


gb_inline void tokenizer_skip_line(Tokenizer *t) {
	while (t->curr_rune != '\n' && t->curr_rune != GB_RUNE_EOF) {
		advance_to_next_rune(t);
	}
}

gb_inline void tokenizer_skip_whitespace(Tokenizer *t, bool on_newline) {
	if (on_newline) {
		for (;;) {
			switch (t->curr_rune) {
			case ' ':
			case '\t':
			case '\r':
				advance_to_next_rune(t);
				continue;
			}
			break;
		}
	} else {
		for (;;) {
			switch (t->curr_rune) {
			case '\n':
			case ' ':
			case '\t':
			case '\r':
				advance_to_next_rune(t);
				continue;
			}
			break;
		}
	}
}

void tokenizer_get_token(Tokenizer *t, Token *token, int repeat=0) {
	tokenizer_skip_whitespace(t, t->insert_semicolon);

	token->kind = Token_Invalid;
	token->string.text = t->curr;
	token->string.len  = 1;
	token->pos.file_id = t->curr_file_id;
	token->pos.line = t->line_count;
	token->pos.offset = cast(i32)(t->curr - t->start);
	token->pos.column = t->column_minus_one+1;

	TokenPos current_pos = token->pos;

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

		goto semicolon_check;
	} else {
		switch (curr_rune) {
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			scan_number_to_token(t, token, false);
			goto semicolon_check;
		}

		advance_to_next_rune(t);
		switch (curr_rune) {
		case GB_RUNE_EOF:
			token->kind = Token_EOF;
			if (t->insert_semicolon) {
				t->insert_semicolon = false; // EOF consumed
				token->string = str_lit("\n");
				token->kind = Token_Semicolon;
				return;
			}
			break;

		case '\n':
			t->insert_semicolon = false;
			token->string = str_lit("\n");
			token->kind = Token_Semicolon;
			return;

		case '\\':
			t->insert_semicolon = false;
			tokenizer_get_token(t, token);
			if (token->pos.line == current_pos.line) {
				tokenizer_err(t, token_pos_add_column(current_pos), "Expected a newline after \\");
			}
			// NOTE(bill): tokenizer_get_token has been called already, return early
			return;

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
			goto semicolon_check;
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
			goto semicolon_check;
		} break;

		case '.':
			token->kind = Token_Period;
			switch (t->curr_rune) {
			case '.':
				advance_to_next_rune(t);
				token->kind = Token_Ellipsis;
				if (t->curr_rune == '<') {
					advance_to_next_rune(t);
					token->kind = Token_RangeHalf;
				} else if (t->curr_rune == '=') {
					advance_to_next_rune(t);
					token->kind = Token_RangeFull;
				}
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				scan_number_to_token(t, token, true);
				break;
			}
			break;
		case '@': token->kind = Token_At;           break;
		case '$': token->kind = Token_Dollar;       break;
		case '?': token->kind = Token_Question;     break;
		case '^': token->kind = Token_Pointer;      break;
		case ';': token->kind = Token_Semicolon;    break;
		case ',': token->kind = Token_Comma;        break;
		case ':': token->kind = Token_Colon;        break;
		case '(': token->kind = Token_OpenParen;    break;
		case ')': token->kind = Token_CloseParen;   break;
		case '[': token->kind = Token_OpenBracket;  break;
		case ']': token->kind = Token_CloseBracket; break;
		case '{': token->kind = Token_OpenBrace;    break;
		case '}': token->kind = Token_CloseBrace;   break;
		case '%':
			token->kind = Token_Mod;
			switch (t->curr_rune) {
			case '=':
				advance_to_next_rune(t);
				token->kind = Token_ModEq;
				break;
			case '%':
				token->kind = Token_ModMod;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ModModEq;
					advance_to_next_rune(t);
				}
				break;
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
			if (t->curr_rune == '=') {
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
			switch (t->curr_rune) {
			case '=':
				advance_to_next_rune(t);
				token->kind = Token_AddEq;
				break;
			case '+':
				advance_to_next_rune(t);
				token->kind = Token_Increment;
				break;
			}
			break;
		case '-':
			token->kind = Token_Sub;
			switch (t->curr_rune) {
			case '=':
				advance_to_next_rune(t);
				token->kind = Token_SubEq;
				break;
			case '-':
				advance_to_next_rune(t);
				token->kind = Token_Decrement;
				if (t->curr_rune == '-') {
					advance_to_next_rune(t);
					token->kind = Token_Undef;
				}
				break;
			case '>':
				advance_to_next_rune(t);
				token->kind = Token_ArrowRight;
				break;
			}
			break;
		case '#':
			token->kind = Token_Hash;
			if (t->curr_rune == '!') {
				token->kind = Token_Comment;
				tokenizer_skip_line(t);
			}
			break;
		case '/':
			token->kind = Token_Quo;
			switch (t->curr_rune) {
			case '/':
				token->kind = Token_Comment;
				tokenizer_skip_line(t);
				break;
			case '*':
				token->kind = Token_Comment;
				advance_to_next_rune(t);
				for (isize comment_scope = 1; comment_scope > 0; /**/) {
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
				break;
			case '=':
				advance_to_next_rune(t);
				token->kind = Token_QuoEq;
				break;
			}
			break;
		case '<':
			token->kind = Token_Lt;
			switch (t->curr_rune) {
			case '=':
				token->kind = Token_LtEq;
				advance_to_next_rune(t);
				break;
			case '<':
				token->kind = Token_Shl;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ShlEq;
					advance_to_next_rune(t);
				}
				break;
			}
			break;
		case '>':
			token->kind = Token_Gt;
			switch (t->curr_rune) {
			case '=':
				token->kind = Token_GtEq;
				advance_to_next_rune(t);
				break;
			case '>':
				token->kind = Token_Shr;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_ShrEq;
					advance_to_next_rune(t);
				}
				break;
			}
			break;
		case '&':
			token->kind = Token_And;
			switch (t->curr_rune) {
			case '~':
				token->kind = Token_AndNot;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_AndNotEq;
					advance_to_next_rune(t);
				}
				break;
			case '=':
				token->kind = Token_AndEq;
				advance_to_next_rune(t);
				break;
			case '&':
				token->kind = Token_CmpAnd;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_CmpAndEq;
					advance_to_next_rune(t);
				}
				break;
			}
			break;
		case '|':
			token->kind = Token_Or;
			switch (t->curr_rune) {
			case '=':
				token->kind = Token_OrEq;
				advance_to_next_rune(t);
				break;
			case '|':
				token->kind = Token_CmpOr;
				advance_to_next_rune(t);
				if (t->curr_rune == '=') {
					token->kind = Token_CmpOrEq;
					advance_to_next_rune(t);
				}
				break;
			}
			break;
		default:
			token->kind = Token_Invalid;
			if (curr_rune != GB_RUNE_BOM) {
				u8 str[4] = {};
				int len = cast(int)gb_utf8_encode_rune(str, curr_rune);
				tokenizer_err(t, "Illegal character: %.*s (%d) ", len, str, curr_rune);
			}
			break;
		}
	}

	token->string.len = t->curr - token->string.text;

semicolon_check:;
	switch (token->kind) {
	case Token_Invalid:
	case Token_Comment:
		// Preserve insert_semicolon info
		break;
	case Token_Ident:
	case Token_context:
	case Token_typeid:
	case Token_break:
	case Token_continue:
	case Token_fallthrough:
	case Token_return:
	case Token_or_return:
		/*fallthrough*/
	case Token_Integer:
	case Token_Float:
	case Token_Imag:
	case Token_Rune:
	case Token_String:
	case Token_Undef:
		/*fallthrough*/
	case Token_Question:
	case Token_Pointer:
	case Token_CloseParen:
	case Token_CloseBracket:
	case Token_CloseBrace:
		/*fallthrough*/
	case Token_Increment:
	case Token_Decrement:
		/*fallthrough*/
		t->insert_semicolon = true;
		break;
	default:
		t->insert_semicolon = false;
		break;
	}

	return;
}
