package odin_token

import "core:strings"

Token :: struct {
	kind: Kind,
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
		return (lhs.offset < rhs.offset) ? -1 : +1;
	}
	if lhs.line != rhs.line {
		return (lhs.line < rhs.line) ? -1 : +1;
	}
	if lhs.column != rhs.column {
		return (lhs.column < rhs.column) ? -1 : +1;
	}
	return strings.compare(lhs.file, rhs.file);
}

using Kind :: enum u16 {
	Invalid,
	EOF,
	Comment,

	B_Literal_Begin,
		Ident,
		Integer,
		Float,
		Imag,
		Rune,
		String,
	B_Literal_End,

	B_Operator_Begin,
		Eq,
		Not,
		Hash,
		At,
		Dollar,
		Pointer,
		Question,
		Add,
		Sub,
		Mul,
		Quo,
		Mod,
		Mod_Mod,
		And,
		Or,
		Xor,
		And_Not,
		Shl,
		Shr,

		Cmp_And,
		Cmp_Or,

	B_Assign_Op_Begin,
		Add_Eq,
		Sub_Eq,
		Mul_Eq,
		Quo_Eq,
		Mod_Eq,
		Mod_Mod_Eq,
		And_Eq,
		Or_Eq,
		Xor_Eq,
		And_Not_Eq,
		Shl_Eq,
		Shr_Eq,
		Cmp_And_Eq,
		Cmp_Or_Eq,
	B_Assign_Op_End,

		Arrow_Right,
		Arrow_Left,
		Double_Arrow_Right,
		Undef,

	B_Comparison_Begin,
		Cmp_Eq,
		Not_Eq,
		Lt,
		Gt,
		Lt_Eq,
		Gt_Eq,
	B_Comparison_End,

		Open_Paren,
		Close_Paren,
		Open_Bracket,
		Close_Bracket,
		Open_Brace,
		Close_Brace,
		Colon,
		Semicolon,
		Period,
		Comma,
		Ellipsis,
		Back_Slash,
	B_Operator_End,

	B_Keyword_Begin,
		Import,
		Export,
		Foreign,
		Package,
		Typeid,
		When,
		If,
		Else,
		For,
		Switch,
		In,
		Notin,
		Do,
		Case,
		Break,
		Continue,
		Fallthrough,
		Defer,
		Return,
		Proc,
		Macro,
		Struct,
		Union,
		Enum,
		Bit_Field,
		Bit_Set,
		Map,
		Dynamic,
		Auto_Cast,
		Cast,
		Transmute,
		Distinct,
		Opaque,
		Using,
		Inline,
		No_Inline,
		Context,
		Size_Of,
		Align_Of,
		Offset_Of,
		Type_Of,
		Const,
		Asm,
		Yield,
		Await,
	B_Keyword_End,

	COUNT,
};

tokens := [Kind.COUNT]string {
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

	"->",
	"<-",
	"=>",
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
	"\\",
	"",

	"",
	"import",
	"export",
	"foreign",
	"package",
	"typeid",
	"when",
	"if",
	"else",
	"for",
	"switch",
	"in",
	"notin",
	"do",
	"case",
	"break",
	"continue",
	"fallthrough",
	"defer",
	"return",
	"proc",
	"macro",
	"struct",
	"union",
	"enum",
	"bit_field",
	"bit_set",
	"map",
	"dynamic",
	"auto_cast",
	"cast",
	"transmute",
	"distinct",
	"opaque",
	"using",
	"inline",
	"no_inline",
	"context",
	"size_of",
	"align_of",
	"offset_of",
	"type_of",
	"const",
	"asm",
	"yield",
	"await",
	"",
};

to_string :: proc(kind: Kind) -> string {
	if min(Kind) <= kind && kind <= max(Kind) {
		return tokens[kind];
	}
	return "Invalid";
}

is_literal  :: proc(kind: Kind) -> bool { return B_Literal_Begin  < kind && kind < B_Literal_End;  }
is_operator :: proc(kind: Kind) -> bool {
	switch kind {
	case B_Operator_Begin..B_Operator_End:
		return true;
	case In, Notin:
		return true;
	}
	return false;
}
is_assignment_operator :: proc(kind: Kind) -> bool {
	return B_Assign_Op_Begin < kind && kind < B_Assign_Op_End || kind == Eq;
}
is_keyword :: proc(kind: Kind) -> bool { return B_Keyword_Begin  < kind && kind < B_Keyword_End;  }
