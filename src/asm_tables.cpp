enum AsmRegClass : u8 {
	AsmRegClass_Unknown,
	AsmRegClass_Integer,
	AsmRegClass_Float,
	AsmRegClass_Vector,
	AsmRegClass_Mask,
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

void init_asm_tables() {
	g_asm_amd64.init();
}