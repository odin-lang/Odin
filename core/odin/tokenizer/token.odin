package odin_tokenizer

import "core:strings"

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

pos_compare :: proc(lhs, rhs: Pos) -> int {
	if lhs.offset != rhs.offset {
		return -1 if (lhs.offset < rhs.offset) else +1
	}
	if lhs.line != rhs.line {
		return -1 if (lhs.line < rhs.line) else +1
	}
	if lhs.column != rhs.column {
		return -1 if (lhs.column < rhs.column) else +1
	}
	return strings.compare(lhs.file, rhs.file)
}

Token_Kind :: enum u32 {
	Invalid,
	EOF,
	Comment,

	B_Literal_Begin,
		Ident,   // main
		Integer, // 12345
		Float,   // 123.45
		Imag,    // 123.45i
		Rune,    // 'a'
		String,  // "abc"
	B_Literal_End,

	B_Operator_Begin,
		Eq,       // =
		Not,      // !
		Hash,     // #
		At,       // @
		Dollar,   // $
		Pointer,  // ^
		Question, // ?
		Add,      // +
		Sub,      // -
		Mul,      // *
		Quo,      // /
		Mod,      // %
		Mod_Mod,  // %%
		And,      // &
		Or,       // |
		Xor,      // ~
		And_Not,  // &~
		Shl,      // <<
		Shr,      // >>

		Cmp_And,  // &&
		Cmp_Or,   // ||

	B_Assign_Op_Begin,
		Add_Eq,     // +=
		Sub_Eq,     // -=
		Mul_Eq,     // *=
		Quo_Eq,     // /=
		Mod_Eq,     // %=
		Mod_Mod_Eq, // %%=
		And_Eq,     // &=
		Or_Eq,      // |=
		Xor_Eq,     // ~=
		And_Not_Eq, // &~=
		Shl_Eq,     // <<=
		Shr_Eq,     // >>=
		Cmp_And_Eq, // &&=
		Cmp_Or_Eq,  // ||=
	B_Assign_Op_End,

		Increment,          // ++
		Decrement,          // --
		Arrow_Right,        // ->
		Undef,              // ---

	B_Comparison_Begin,
		Cmp_Eq, // ==
		Not_Eq, // !=
		Lt,     // <
		Gt,     // >
		Lt_Eq,  // <=
		Gt_Eq,  // >=
	B_Comparison_End,

		Open_Paren,    // (
		Close_Paren,   // )
		Open_Bracket,  // [
		Close_Bracket, // ]
		Open_Brace,    // {
		Close_Brace,   // }
		Colon,         // :
		Semicolon,     // ;
		Period,        // .
		Comma,         // ,
		Ellipsis,      // ..
		Range_Half,    // ..<
		Range_Full,    // ..=
	B_Operator_End,

	B_Keyword_Begin,
		Import,      // import
		Foreign,     // foreign
		Package,     // package
		Typeid,      // typeid
		When,        // when
		Where,       // where
		If,          // if
		Else,        // else
		For,         // for
		Switch,      // switch
		In,          // in
		Not_In,      // not_in
		Do,          // do
		Case,        // case
		Break,       // break
		Continue,    // continue
		Fallthrough, // fallthrough
		Defer,       // defer
		Return,      // return
		Proc,        // proc
		Struct,      // struct
		Union,       // union
		Enum,        // enum
		Bit_Set,     // bit_set
		Bit_Field,   // bit_field
		Map,         // map
		Dynamic,     // dynamic
		Auto_Cast,   // auto_cast
		Cast,        // cast
		Transmute,   // transmute
		Distinct,    // distinct
		Using,       // using
		Context,     // context
		Or_Else,     // or_else
		Or_Return,   // or_return
		Or_Break,    // or_break
		Or_Continue, // or_continue
		Asm,         // asm
		Inline,      // inline
		No_Inline,   // no_inline
		Matrix,      // matrix
	B_Keyword_End,

	COUNT,

	B_Custom_Keyword_Begin = COUNT+1,
	// ... Custom keywords
}

tokens := [Token_Kind.COUNT]string {
	"Invalid",
	"EOF",
	"Comment",

	"",
	"identifier",
	"integer",
	"float",
	"imaginary",
	"rune",
	"string",
	"",

	"",
	"=",
	"!",
	"#",
	"@",
	"$",
	"^",
	"?",
	"+",
	"-",
	"*",
	"/",
	"%",
	"%%",
	"&",
	"|",
	"~",
	"&~",
	"<<",
	">>",

	"&&",
	"||",

	"",
	"+=",
	"-=",
	"*=",
	"/=",
	"%=",
	"%%=",
	"&=",
	"|=",
	"~=",
	"&~=",
	"<<=",
	">>=",
	"&&=",
	"||=",
	"",

	"++",
	"--",
	"->",
	"---",

	"",
	"==",
	"!=",
	"<",
	">",
	"<=",
	">=",
	"",

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
	"..",
	"..<",
	"..=",
	"",

	"",
	"import",
	"foreign",
	"package",
	"typeid",
	"when",
	"where",
	"if",
	"else",
	"for",
	"switch",
	"in",
	"not_in",
	"do",
	"case",
	"break",
	"continue",
	"fallthrough",
	"defer",
	"return",
	"proc",
	"struct",
	"union",
	"enum",
	"bit_set",
	"bit_field",
	"map",
	"dynamic",
	"auto_cast",
	"cast",
	"transmute",
	"distinct",
	"using",
	"context",
	"or_else",
	"or_return",
	"or_break",
	"or_continue",
	"asm",
	"inline",
	"no_inline",
	"matrix",
	"",
}

custom_keyword_tokens: []string


is_newline :: proc(tok: Token) -> bool {
	return tok.kind == .Semicolon && tok.text == "\n"
}


token_to_string :: proc(tok: Token) -> string {
	if is_newline(tok) {
		return "newline"
	}
	return to_string(tok.kind)
}

to_string :: proc(kind: Token_Kind) -> string {
	if .Invalid <= kind && kind < .COUNT {
		return tokens[kind]
	}
	if .B_Custom_Keyword_Begin < kind {
		n := int(u16(kind)-u16(Token_Kind.B_Custom_Keyword_Begin))
		if n < len(custom_keyword_tokens) {
			return custom_keyword_tokens[n]
		}
	}

	return "Invalid"
}

is_literal  :: proc(kind: Token_Kind) -> bool {
	return .B_Literal_Begin  < kind && kind < .B_Literal_End
}
is_operator :: proc(kind: Token_Kind) -> bool {
	#partial switch kind {
	case .B_Operator_Begin ..= .B_Operator_End:
		return true
	case .In, .Not_In:
		return true
	case .If:
		return true
	}
	return false
}
is_assignment_operator :: proc(kind: Token_Kind) -> bool {
	return .B_Assign_Op_Begin < kind && kind < .B_Assign_Op_End || kind == .Eq
}
is_keyword :: proc(kind: Token_Kind) -> bool {
	switch {
	case .B_Keyword_Begin < kind && kind < .B_Keyword_End:
		return true
	case .B_Custom_Keyword_Begin < kind:
		return true
	}
	return false
}
