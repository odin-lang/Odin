#ifndef TB_X64_H
#define TB_X64_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    // uses xmm registers for the reg array
    TB_X86_INSTR_XMMREG = (1u << 0u),

    // r/m is a memory operand
    TB_X86_INSTR_USE_MEMOP = (1u << 1u),

    // r/m is a rip-relative address (TB_X86_INSTR_USE_MEMOP is always set when this is set)
    TB_X86_INSTR_USE_RIPMEM = (1u << 2u),

    // LOCK prefix is present
    TB_X86_INSTR_LOCK = (1u << 3u),

    // uses a signed immediate
    TB_X86_INSTR_IMMEDIATE = (1u << 4u),

    // absolute means it's using the 64bit immediate (cannot be applied while a memory operand is active)
    TB_X86_INSTR_ABSOLUTE = (1u << 5u),

    // set if the r/m can be found on the right hand side
    TB_X86_INSTR_DIRECTION = (1u << 6u),

    // uses the second data type because the instruction is weird like MOVSX or MOVZX
    TB_X86_INSTR_TWO_DATA_TYPES = (1u << 7u),

    // REP prefix is present
    TB_X86_INSTR_REP = (1u << 8u),

    // REPNE prefix is present
    TB_X86_INSTR_REPNE = (1u << 9u),
} TB_X86_InstFlags;

typedef enum {
    TB_X86_RAX, TB_X86_RCX, TB_X86_RDX, TB_X86_RBX, TB_X86_RSP, TB_X86_RBP, TB_X86_RSI, TB_X86_RDI,
    TB_X86_R8,  TB_X86_R9,  TB_X86_R10, TB_X86_R11, TB_X86_R12, TB_X86_R13, TB_X86_R14, TB_X86_R15,
} TB_X86_GPR;

typedef enum {
    TB_X86_SEGMENT_DEFAULT = 0,

    TB_X86_SEGMENT_ES, TB_X86_SEGMENT_CS,
    TB_X86_SEGMENT_SS, TB_X86_SEGMENT_DS,
    TB_X86_SEGMENT_GS, TB_X86_SEGMENT_FS,
} TB_X86_Segment;

typedef enum {
    TB_X86_TYPE_NONE = 0,

    TB_X86_TYPE_BYTE,    // 1
    TB_X86_TYPE_WORD,    // 2
    TB_X86_TYPE_DWORD,   // 4
    TB_X86_TYPE_QWORD,   // 8

    TB_X86_TYPE_PBYTE,   // int8 x 16 = 16
    TB_X86_TYPE_PWORD,   // int16 x 8 = 16
    TB_X86_TYPE_PDWORD,  // int32 x 4 = 16
    TB_X86_TYPE_PQWORD,  // int64 x 2 = 16

    TB_X86_TYPE_SSE_SS,  // float32 x 1 = 4
    TB_X86_TYPE_SSE_SD,  // float64 x 1 = 8
    TB_X86_TYPE_SSE_PS,  // float32 x 4 = 16
    TB_X86_TYPE_SSE_PD,  // float64 x 2 = 16

    TB_X86_TYPE_XMMWORD, // the generic idea of them
} TB_X86_DataType;

typedef struct {
    int32_t opcode;

    // registers (there's 4 max taking up 8bit slots each)
    int8_t regs[4];
    uint16_t flags;

    // bitpacking amirite
    TB_X86_DataType data_type  : 8;
    TB_X86_DataType data_type2 : 8;
    TB_X86_Segment segment     : 4;
    uint8_t length             : 4;

    // memory operand
    //   X86_INSTR_USE_MEMOP
    uint8_t base, index, scale;
    int32_t disp;

    // immediate operand
    //   imm for INSTR_IMMEDIATE
    //   abs for INSTR_ABSOLUTE
    union {
        int32_t  imm;
        uint64_t abs;
    };
} TB_X86_Inst;

bool tb_x86_disasm(TB_X86_Inst* restrict inst, size_t length, const uint8_t* data);
const char* tb_x86_reg_name(int8_t reg, TB_X86_DataType dt);
const char* tb_x86_type_name(TB_X86_DataType dt);
const char* tb_x86_mnemonic(TB_X86_Inst* inst);

#endif /* TB_X64_H */
