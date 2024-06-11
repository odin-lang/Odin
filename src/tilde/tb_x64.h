#ifndef TB_X64_H
#define TB_X64_H

#include <stdint.h>
#include <stdbool.h>

#ifndef TB_API
#  ifdef __cplusplus
#    define TB_EXTERN extern "C"
#  else
#    define TB_EXTERN
#  endif
#  ifdef TB_DLL
#    ifdef TB_IMPORT_DLL
#      define TB_API TB_EXTERN __declspec(dllimport)
#    else
#      define TB_API TB_EXTERN __declspec(dllexport)
#    endif
#  else
#    define TB_API TB_EXTERN
#  endif
#endif

typedef enum {
    // r/m is a memory operand
    TB_X86_INSTR_INDIRECT = (1u << 0u),

    // LOCK prefix is present
    TB_X86_INSTR_LOCK = (1u << 1u),

    // uses an immediate
    TB_X86_INSTR_IMMEDIATE = (1u << 2u),

    // set if the r/m can be found on the right hand side
    TB_X86_INSTR_DIRECTION = (1u << 3u),

    // REP prefix is present
    TB_X86_INSTR_REP = (1u << 5u),

    // REPNE prefix is present
    TB_X86_INSTR_REPNE = (1u << 6u),
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
    TB_X86_NONE = 0,

    TB_X86_BYTE,    // 1
    TB_X86_WORD,    // 2
    TB_X86_DWORD,   // 4
    TB_X86_QWORD,   // 8

    TB_X86_XMMWORD, // the generic idea of them

    TB_X86_F32x1,   // ss
    TB_X86_F64x1,   // sd
    TB_X86_F32x4,   // ps
    TB_X86_F64x2,   // pd

    TB_X86_PBYTE,   // int8 x 16 = 16
    TB_X86_PWORD,   // int16 x 8 = 16
    TB_X86_PDWORD,  // int32 x 4 = 16
    TB_X86_PQWORD,  // int64 x 2 = 16
} TB_X86_DataType;

typedef struct {
    uint16_t opcode;

    // packed 16bits
    uint16_t scale  : 2;
    uint16_t flags  : 6;
    uint16_t dt     : 4;
    uint16_t dt2    : 4;

    // each 8bits are a different reg (lowest bits to higher):
    //   base, index, rx, extra
    uint32_t regs;
    int32_t disp;

    // bitpacking amirite
    TB_X86_Segment segment     : 4;
    uint8_t length             : 4;
    uint8_t disp_pos           : 4;

    // immediate operand
    int64_t imm;
} TB_X86_Inst;

TB_API void tb_x86_print_inst(FILE* fp, TB_X86_Inst* inst);
TB_API bool tb_x86_disasm(TB_X86_Inst* restrict inst, size_t length, const uint8_t* data);
TB_API const char* tb_x86_reg_name(int8_t reg, TB_X86_DataType dt);
TB_API const char* tb_x86_type_name(TB_X86_DataType dt);
TB_API const char* tb_x86_mnemonic(TB_X86_Inst* inst);

#endif /* TB_X64_H */
