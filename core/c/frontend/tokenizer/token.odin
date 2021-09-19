package c_frontend_tokenizer


Pos :: struct {
	file:   string,
	line:   int,
	column: int,
	offset: int,
}

Token_Kind :: enum {
	Invalid,
	Ident,
	Punct,
	Keyword,
	Char,
	String,
	Number,
	PP_Number,
	Comment,
	EOF,
}

File :: struct {
	name: string,
	id:   int,
	src:  []byte,

	display_name: string,
	line_delta:   int,
}


Token_Type_Hint :: enum u8 {
	None,

	Int,
	Long,
	Long_Long,

	Unsigned_Int,
	Unsigned_Long,
	Unsigned_Long_Long,

	Float,
	Double,
	Long_Double,

	UTF_8,
	UTF_16,
	UTF_32,
	UTF_Wide,
}

Token_Value :: union {
	i64,
	f64,
	string,
	[]u16,
	[]u32,
}

Token :: struct {
	kind: Token_Kind,
	next: ^Token,
	lit: string,

	pos:   Pos,
	file:  ^File,
	line_delta: int,
	at_bol:     bool,
	has_space:  bool,

	type_hint: Token_Type_Hint,
	val: Token_Value,
	prefix: string,

	// Preprocessor values
	hide_set: ^Hide_Set,
	origin:   ^Token,
}

Is_Keyword_Proc :: #type proc(tok: ^Token) -> bool

copy_token :: proc(tok: ^Token) -> ^Token {
	t, _ := new_clone(tok^)
	t.next = nil
	return t
}

new_eof :: proc(tok: ^Token) -> ^Token {
	t, _ := new_clone(tok^)
	t.kind = .EOF
	t.lit = ""
	return t
}

default_is_keyword :: proc(tok: ^Token) -> bool {
	if tok.kind == .Keyword {
		return true
	}
	if len(tok.lit) > 0 {
		return default_keyword_set[tok.lit]
	}
	return false
}


token_name := [Token_Kind]string {
	.Invalid   = "invalid",
	.Ident     = "ident",
	.Punct     = "punct",
	.Keyword   = "keyword",
	.Char      = "char",
	.String    = "string",
	.Number    = "number",
	.PP_Number = "preprocessor number",
	.Comment   = "comment",
	.EOF       = "eof",
}

default_keyword_set := map[string]bool{
	"auto"          = true,
	"break"         = true,
	"case"          = true,
	"char"          = true,
	"const"         = true,
	"continue"      = true,
	"default"       = true,
	"do"            = true,
	"double"        = true,
	"else"          = true,
	"enum"          = true,
	"extern"        = true,
	"float"         = true,
	"for"           = true,
	"goto"          = true,
	"if"            = true,
	"int"           = true,
	"long"          = true,
	"register"      = true,
	"restrict"      = true,
	"return"        = true,
	"short"         = true,
	"signed"        = true,
	"sizeof"        = true,
	"static"        = true,
	"struct"        = true,
	"switch"        = true,
	"typedef"       = true,
	"union"         = true,
	"unsigned"      = true,
	"void"          = true,
	"volatile"      = true,
	"while"         = true,
	"_Alignas"      = true,
	"_Alignof"      = true,
	"_Atomic"       = true,
	"_Bool"         = true,
	"_Generic"      = true,
	"_Noreturn"     = true,
	"_Thread_local" = true,
	"__restrict"    = true,
	"typeof"        = true,
	"asm"           = true,
	"__restrict__"  = true,
	"__thread"      = true,
	"__attribute__" = true,
}
