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
    TB_X86_INSTR_TWO_DATA_TYPES = (1u << 7u)
} TB_X86_InstFlags;

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
    int16_t type;

    // registers (there's 4 max taking up 4bit slots each)
    uint16_t regs;
    uint8_t flags;

    // bitpacking amirite
    TB_X86_DataType data_type  : 4;
    TB_X86_DataType data_type2 : 4;
    TB_X86_Segment segment     : 4;
    uint8_t length             : 4;

    // memory operand
    //   X86_INSTR_USE_MEMOP
    int32_t disp;

    // immediate operand
    //   imm for INSTR_IMMEDIATE
    //   abs for INSTR_ABSOLUTE
    union {
        int32_t  imm;
        uint64_t abs;
    };
} TB_X86_Inst;

TB_X86_Inst tb_x86_disasm(size_t length, const uint8_t data[length]);

#endif /* TB_X64_H */
