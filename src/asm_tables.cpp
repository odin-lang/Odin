enum AsmOperandKind : u8 {
	AsmOperand_Invalid,
	AsmOperand_Register,
	AsmOperand_Memory,
	AsmOperand_Register_Or_Memory,
	AsmOperand_Immediate,
	AsmOperand_Label,
};

#include "asm_tables_amd64.cpp"