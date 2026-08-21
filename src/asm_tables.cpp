enum AsmRegClass : u8 {
	AsmRegClass_Unknown,
	AsmRegClass_Integer,
	AsmRegClass_Float,
	AsmRegClass_Vector,
	AsmRegClass_Mask,

	AsmRegClass_COUNT
};

gb_global String const asm_reg_class_strings[AsmRegClass_COUNT] = {
	str_lit("unknown"),
	str_lit("integer"),
	str_lit("float"),
	str_lit("vector"),
	str_lit("mask"),
};

gb_global String const asm_reg_class_strings_with_article[AsmRegClass_COUNT] = {
	str_lit("an unknown"),
	str_lit("an integer"),
	str_lit("a float"),
	str_lit("a vector"),
	str_lit("a mask"),
};

enum AsmOperandKind : u8 {
	AsmOperand_Invalid,
	AsmOperand_Register,
	AsmOperand_Memory,
	AsmOperand_Register_Or_Memory,
	AsmOperand_Immediate,
	AsmOperand_Label,

	AsmOperand_COUNT
};

gb_global String const asm_operand_kind_strings[AsmOperand_COUNT] = {
	str_lit(""),
	str_lit("register"),
	str_lit("memory"),
	str_lit("register or memory"),
	str_lit("immediate"),
	str_lit("label"),
};

gb_global String const asm_operand_kind_expected_strings[AsmOperand_COUNT] = {
	str_lit(""),
	str_lit("a register"),
	str_lit("a memory"),
	str_lit("a register or memory"),
	str_lit("an immediate"),
	str_lit("a label"),
};

#include "asm_tables_amd64.cpp"
#include "asm_tables_riscv.cpp"

void init_asm_tables(i64 word_size_bytes) {
	g_asm_amd64.init(word_size_bytes*8);
	g_asm_riscv.init(word_size_bytes*8);
}