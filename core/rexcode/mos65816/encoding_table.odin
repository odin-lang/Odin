package rexcode_mos65816

// =============================================================================
// W65C816S ENCODING_TABLE
// =============================================================================
//
// Covers every defined opcode in the W65C816S official opcode matrix.
// Where the operand width is mode-dependent (M for ALU/STA-family;
// X for LDX/LDY/CPX/CPY), two forms share the same opcode -- one with
// IMM_M8 / IMM_X8 (length=2) and one with IMM_M16 / IMM_X16 (length=3).
// The encoder picks by `op.size`; the decoder picks by `Assumed_State`.
//
// ALU-family opcode bit pattern (ORA/AND/EOR/ADC/STA/LDA/CMP/SBC):
//
//      column   addressing mode             example (ORA at +0)
//      $01      (dp,X)                      $01 ORA (dp,X)
//      $03      sr,S                        $03 ORA $nn,S
//      $05      dp                          $05 ORA $nn
//      $07      [dp]                        $07 ORA [$nn]
//      $09      #imm                        $09 ORA #imm  (M-dep)
//      $0D      abs                         $0D ORA $nnnn
//      $0F      long                        $0F ORA $nnnnnn
//      $11      (dp),Y                      $11 ORA ($nn),Y
//      $12      (dp)                        $12 ORA ($nn)
//      $13      (sr,S),Y                    $13 ORA ($nn,S),Y
//      $15      dp,X                        $15 ORA $nn,X
//      $17      [dp],Y                      $17 ORA [$nn],Y
//      $19      abs,Y                       $19 ORA $nnnn,Y
//      $1D      abs,X                       $1D ORA $nnnn,X
//      $1F      long,X                      $1F ORA $nnnnnn,X
//
//   Add $20 (AND), $40 (EOR), $60 (ADC), $80 (STA: no #imm),
//       $A0 (LDA), $C0 (CMP), $E0 (SBC) to get the per-mnemonic base.

@(rodata)
ENCODING_TABLE: [Mnemonic][]Encoding = #partial {
    .INVALID = {},

    // =========================================================================
    // ALU families: ORA / AND / EOR / ADC / STA / LDA / CMP / SBC
    // =========================================================================

    .ORA = {
        {.ORA, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x01, 2, {}},
        {.ORA, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x03, 2, {}},
        {.ORA, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x05, 2, {}},
        {.ORA, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x07, 2, {}},
        {.ORA, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x09, 2, {}},
        {.ORA, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0x09, 3, {}},
        {.ORA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0D, 3, {}},
        {.ORA, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x0F, 4, {}},
        {.ORA, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x11, 2, {page_cross=true}},
        {.ORA, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x12, 2, {}},
        {.ORA, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x13, 2, {}},
        {.ORA, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x15, 2, {}},
        {.ORA, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x17, 2, {}},
        {.ORA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x19, 3, {page_cross=true}},
        {.ORA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1D, 3, {page_cross=true}},
        {.ORA, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x1F, 4, {}},
    },
    .AND = {
        {.AND, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x21, 2, {}},
        {.AND, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x23, 2, {}},
        {.AND, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x25, 2, {}},
        {.AND, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x27, 2, {}},
        {.AND, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x29, 2, {}},
        {.AND, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0x29, 3, {}},
        {.AND, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2D, 3, {}},
        {.AND, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x2F, 4, {}},
        {.AND, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x31, 2, {page_cross=true}},
        {.AND, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x32, 2, {}},
        {.AND, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x33, 2, {}},
        {.AND, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x35, 2, {}},
        {.AND, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x37, 2, {}},
        {.AND, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x39, 3, {page_cross=true}},
        {.AND, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3D, 3, {page_cross=true}},
        {.AND, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x3F, 4, {}},
    },
    .EOR = {
        {.EOR, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x41, 2, {}},
        {.EOR, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x43, 2, {}},
        {.EOR, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x45, 2, {}},
        {.EOR, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x47, 2, {}},
        {.EOR, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x49, 2, {}},
        {.EOR, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0x49, 3, {}},
        {.EOR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4D, 3, {}},
        {.EOR, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x4F, 4, {}},
        {.EOR, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x51, 2, {page_cross=true}},
        {.EOR, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x52, 2, {}},
        {.EOR, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x53, 2, {}},
        {.EOR, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x55, 2, {}},
        {.EOR, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x57, 2, {}},
        {.EOR, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x59, 3, {page_cross=true}},
        {.EOR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5D, 3, {page_cross=true}},
        {.EOR, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x5F, 4, {}},
    },
    .ADC = {
        {.ADC, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x61, 2, {}},
        {.ADC, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x63, 2, {}},
        {.ADC, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x65, 2, {}},
        {.ADC, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x67, 2, {}},
        {.ADC, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x69, 2, {}},
        {.ADC, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0x69, 3, {}},
        {.ADC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6D, 3, {}},
        {.ADC, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x6F, 4, {}},
        {.ADC, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x71, 2, {page_cross=true}},
        {.ADC, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x72, 2, {}},
        {.ADC, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x73, 2, {}},
        {.ADC, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x75, 2, {}},
        {.ADC, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x77, 2, {}},
        {.ADC, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x79, 3, {page_cross=true}},
        {.ADC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7D, 3, {page_cross=true}},
        {.ADC, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x7F, 4, {}},
    },
    .STA = {
        {.STA, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x81, 2, {}},
        {.STA, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x83, 2, {}},
        {.STA, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x85, 2, {}},
        {.STA, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x87, 2, {}},
        {.STA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8D, 3, {}},
        {.STA, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x8F, 4, {}},
        {.STA, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x91, 2, {}},
        {.STA, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x92, 2, {}},
        {.STA, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x93, 2, {}},
        {.STA, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x95, 2, {}},
        {.STA, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x97, 2, {}},
        {.STA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x99, 3, {}},
        {.STA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9D, 3, {}},
        {.STA, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x9F, 4, {}},
    },
    .LDA = {
        {.LDA, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA1, 2, {}},
        {.LDA, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA3, 2, {}},
        {.LDA, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA5, 2, {}},
        {.LDA, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA7, 2, {}},
        {.LDA, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA9, 2, {}},
        {.LDA, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xA9, 3, {}},
        {.LDA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAD, 3, {}},
        {.LDA, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xAF, 4, {}},
        {.LDA, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB1, 2, {page_cross=true}},
        {.LDA, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB2, 2, {}},
        {.LDA, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB3, 2, {}},
        {.LDA, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB5, 2, {}},
        {.LDA, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB7, 2, {}},
        {.LDA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xB9, 3, {page_cross=true}},
        {.LDA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBD, 3, {page_cross=true}},
        {.LDA, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xBF, 4, {}},
    },
    .CMP = {
        {.CMP, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC1, 2, {}},
        {.CMP, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC3, 2, {}},
        {.CMP, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC5, 2, {}},
        {.CMP, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC7, 2, {}},
        {.CMP, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xC9, 2, {}},
        {.CMP, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xC9, 3, {}},
        {.CMP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCD, 3, {}},
        {.CMP, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xCF, 4, {}},
        {.CMP, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD1, 2, {page_cross=true}},
        {.CMP, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD2, 2, {}},
        {.CMP, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD3, 2, {}},
        {.CMP, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD5, 2, {}},
        {.CMP, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD7, 2, {}},
        {.CMP, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xD9, 3, {page_cross=true}},
        {.CMP, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDD, 3, {page_cross=true}},
        {.CMP, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xDF, 4, {}},
    },
    .SBC = {
        {.SBC, {.MEM_DP_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE1, 2, {}},
        {.SBC, {.MEM_SR, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE3, 2, {}},
        {.SBC, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE5, 2, {}},
        {.SBC, {.MEM_DP_IND_LONG, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE7, 2, {}},
        {.SBC, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xE9, 2, {}},
        {.SBC, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xE9, 3, {}},
        {.SBC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xED, 3, {}},
        {.SBC, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xEF, 4, {}},
        {.SBC, {.MEM_DP_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF1, 2, {page_cross=true}},
        {.SBC, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF2, 2, {}},
        {.SBC, {.MEM_SR_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF3, 2, {}},
        {.SBC, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF5, 2, {}},
        {.SBC, {.MEM_DP_IND_LONG_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF7, 2, {}},
        {.SBC, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xF9, 3, {page_cross=true}},
        {.SBC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFD, 3, {page_cross=true}},
        {.SBC, {.MEM_LONG_X, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0xFF, 4, {}},
    },

    // =========================================================================
    // Shifts / rotates (A or memory)
    // =========================================================================

    .ASL = {
        {.ASL, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x0A, 1, {}},
        {.ASL, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x06, 2, {}},
        {.ASL, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x16, 2, {}},
        {.ASL, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0E, 3, {}},
        {.ASL, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1E, 3, {}},
    },
    .LSR = {
        {.LSR, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x4A, 1, {}},
        {.LSR, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x46, 2, {}},
        {.LSR, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x56, 2, {}},
        {.LSR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4E, 3, {}},
        {.LSR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5E, 3, {}},
    },
    .ROL = {
        {.ROL, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x2A, 1, {}},
        {.ROL, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x26, 2, {}},
        {.ROL, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x36, 2, {}},
        {.ROL, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2E, 3, {}},
        {.ROL, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3E, 3, {}},
    },
    .ROR = {
        {.ROR, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x6A, 1, {}},
        {.ROR, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x66, 2, {}},
        {.ROR, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x76, 2, {}},
        {.ROR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6E, 3, {}},
        {.ROR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7E, 3, {}},
    },

    // =========================================================================
    // INC / DEC (memory + 65C02 implied A)
    // =========================================================================

    .INC = {
        {.INC, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x1A, 1, {}},
        {.INC, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE6, 2, {}},
        {.INC, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF6, 2, {}},
        {.INC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xEE, 3, {}},
        {.INC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFE, 3, {}},
    },
    .DEC = {
        {.DEC, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x3A, 1, {}},
        {.DEC, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC6, 2, {}},
        {.DEC, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD6, 2, {}},
        {.DEC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCE, 3, {}},
        {.DEC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDE, 3, {}},
    },
    .INX = { {.INX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xE8, 1, {}} },
    .INY = { {.INY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC8, 1, {}} },
    .DEX = { {.DEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCA, 1, {}} },
    .DEY = { {.DEY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x88, 1, {}} },

    // =========================================================================
    // BIT / TRB / TSB / STZ
    // =========================================================================

    .BIT = {
        {.BIT, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x24, 2, {}},
        {.BIT, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x34, 2, {}},
        {.BIT, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2C, 3, {}},
        {.BIT, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3C, 3, {page_cross=true}},
        {.BIT, {.IMM_M8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x89, 2, {}},
        {.BIT, {.IMM_M16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0x89, 3, {}},
    },
    .TRB = {
        {.TRB, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x14, 2, {}},
        {.TRB, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1C, 3, {}},
    },
    .TSB = {
        {.TSB, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x04, 2, {}},
        {.TSB, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0C, 3, {}},
    },
    .STZ = {
        {.STZ, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x64, 2, {}},
        {.STZ, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x74, 2, {}},
        {.STZ, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9C, 3, {}},
        {.STZ, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9E, 3, {}},
    },

    // =========================================================================
    // Compares (X/Y are X-flag-dependent)
    // =========================================================================

    .CPX = {
        {.CPX, {.IMM_X8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xE0, 2, {}},
        {.CPX, {.IMM_X16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xE0, 3, {}},
        {.CPX, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE4, 2, {}},
        {.CPX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xEC, 3, {}},
    },
    .CPY = {
        {.CPY, {.IMM_X8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xC0, 2, {}},
        {.CPY, {.IMM_X16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xC0, 3, {}},
        {.CPY, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC4, 2, {}},
        {.CPY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCC, 3, {}},
    },

    // =========================================================================
    // Load / store X / Y (X-flag-dependent)
    // =========================================================================

    .LDX = {
        {.LDX, {.IMM_X8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA2, 2, {}},
        {.LDX, {.IMM_X16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xA2, 3, {}},
        {.LDX, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA6, 2, {}},
        {.LDX, {.MEM_DP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB6, 2, {}},
        {.LDX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAE, 3, {}},
        {.LDX, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBE, 3, {page_cross=true}},
    },
    .LDY = {
        {.LDY, {.IMM_X8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA0, 2, {}},
        {.LDY, {.IMM_X16, .NONE, .NONE, .NONE}, {.WORD_1_IMM, .NONE, .NONE, .NONE}, 0xA0, 3, {}},
        {.LDY, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA4, 2, {}},
        {.LDY, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB4, 2, {}},
        {.LDY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAC, 3, {}},
        {.LDY, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBC, 3, {page_cross=true}},
    },
    .STX = {
        {.STX, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x86, 2, {}},
        {.STX, {.MEM_DP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x96, 2, {}},
        {.STX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8E, 3, {}},
    },
    .STY = {
        {.STY, {.MEM_DP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x84, 2, {}},
        {.STY, {.MEM_DP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x94, 2, {}},
        {.STY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8C, 3, {}},
    },

    // =========================================================================
    // Branches
    // =========================================================================

    .BCC = { {.BCC, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x90, 2, {cond_branch=true}} },
    .BCS = { {.BCS, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xB0, 2, {cond_branch=true}} },
    .BEQ = { {.BEQ, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xF0, 2, {cond_branch=true}} },
    .BMI = { {.BMI, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x30, 2, {cond_branch=true}} },
    .BNE = { {.BNE, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xD0, 2, {cond_branch=true}} },
    .BPL = { {.BPL, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x10, 2, {cond_branch=true}} },
    .BVC = { {.BVC, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x50, 2, {cond_branch=true}} },
    .BVS = { {.BVS, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x70, 2, {cond_branch=true}} },
    .BRA = { {.BRA, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x80, 2, {branch=true}} },
    .BRL = { {.BRL, {.REL_LONG, .NONE, .NONE, .NONE}, {.WORD_1_REL, .NONE, .NONE, .NONE}, 0x82, 3, {branch=true}} },

    // =========================================================================
    // Jumps / subroutines / returns / interrupts
    // =========================================================================

    .JMP = {
        {.JMP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4C, 3, {branch=true}},
        {.JMP, {.MEM_ABS_IND, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6C, 3, {branch=true}},
        {.JMP, {.MEM_ABS_IND_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7C, 3, {branch=true}},
    },
    .JML = {
        {.JML, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x5C, 4, {branch=true}},
        {.JML, {.MEM_ABS_IND_LONG, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDC, 3, {branch=true}},
    },
    .JSR = {
        {.JSR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x20, 3, {branch=true}},
        {.JSR, {.MEM_ABS_IND_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFC, 3, {branch=true}},
    },
    .JSL = { {.JSL, {.MEM_LONG, .NONE, .NONE, .NONE}, {.LONG_1_ADDR, .NONE, .NONE, .NONE}, 0x22, 4, {branch=true}} },

    .RTS = { {.RTS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x60, 1, {branch=true}} },
    .RTL = { {.RTL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x6B, 1, {branch=true}} },
    .RTI = { {.RTI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x40, 1, {branch=true}} },

    .BRK = { {.BRK, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x00, 2, {branch=true}} },
    .COP = { {.COP, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x02, 2, {branch=true}} },
    .WDM = { {.WDM, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x42, 2, {}} },

    .NOP = { {.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xEA, 1, {}} },
    .STP = { {.STP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 1, {}} },
    .WAI = { {.WAI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCB, 1, {}} },

    // =========================================================================
    // Flag ops
    // =========================================================================

    .CLC = { {.CLC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x18, 1, {}} },
    .CLD = { {.CLD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 1, {}} },
    .CLI = { {.CLI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x58, 1, {}} },
    .CLV = { {.CLV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xB8, 1, {}} },
    .SEC = { {.SEC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x38, 1, {}} },
    .SED = { {.SED, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF8, 1, {}} },
    .SEI = { {.SEI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x78, 1, {}} },
    .REP = { {.REP, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xC2, 2, {}} },
    .SEP = { {.SEP, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xE2, 2, {}} },
    .XCE = { {.XCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFB, 1, {}} },

    // =========================================================================
    // Stack ops
    // =========================================================================

    .PHA = { {.PHA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x48, 1, {}} },
    .PHP = { {.PHP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x08, 1, {}} },
    .PHX = { {.PHX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDA, 1, {}} },
    .PHY = { {.PHY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x5A, 1, {}} },
    .PHB = { {.PHB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x8B, 1, {}} },
    .PHD = { {.PHD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0B, 1, {}} },
    .PHK = { {.PHK, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x4B, 1, {}} },
    .PLA = { {.PLA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x68, 1, {}} },
    .PLP = { {.PLP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x28, 1, {}} },
    .PLX = { {.PLX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFA, 1, {}} },
    .PLY = { {.PLY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x7A, 1, {}} },
    .PLB = { {.PLB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 1, {}} },
    .PLD = { {.PLD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x2B, 1, {}} },

    // Push-effective ------------------------------------------------------
    .PEA = { {.PEA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xF4, 3, {}} },
    .PEI = { {.PEI, {.MEM_DP_IND, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD4, 2, {}} },
    .PER = { {.PER, {.REL_LONG, .NONE, .NONE, .NONE}, {.WORD_1_REL, .NONE, .NONE, .NONE}, 0x62, 3, {}} },

    // =========================================================================
    // Transfers
    // =========================================================================

    .TAX = { {.TAX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 1, {}} },
    .TAY = { {.TAY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA8, 1, {}} },
    .TSX = { {.TSX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xBA, 1, {}} },
    .TXA = { {.TXA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x8A, 1, {}} },
    .TXS = { {.TXS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9A, 1, {}} },
    .TYA = { {.TYA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 1, {}} },
    // 65816 transfers
    .TCD = { {.TCD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x5B, 1, {}} },
    .TDC = { {.TDC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x7B, 1, {}} },
    .TCS = { {.TCS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x1B, 1, {}} },
    .TSC = { {.TSC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x3B, 1, {}} },
    .TXY = { {.TXY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9B, 1, {}} },
    .TYX = { {.TYX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xBB, 1, {}} },
    .XBA = { {.XBA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xEB, 1, {}} },

    // =========================================================================
    // Block move (src, dst banks; bytes encoded as opcode | dst | src)
    // =========================================================================

    .MVN = { {.MVN, {.BANK_SRC, .BANK_DST, .NONE, .NONE}, {.BYTE_2_BANK, .BYTE_1_BANK, .NONE, .NONE}, 0x54, 3, {}} },
    .MVP = { {.MVP, {.BANK_SRC, .BANK_DST, .NONE, .NONE}, {.BYTE_2_BANK, .BYTE_1_BANK, .NONE, .NONE}, 0x44, 3, {}} },
}
