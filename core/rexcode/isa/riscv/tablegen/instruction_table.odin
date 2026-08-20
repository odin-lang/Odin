package rexcode_riscv_tablegen

// Form couples one encoding shape with its architectural effects.
// `using encoding` keeps existing field access (form.opcode, form.ops,
// form.flags, ...) working unchanged when code moves from []Encoding to []Form.
Form :: struct {
	using encoding: Encoding,
	clobber:        Clobber,
}

@(rodata)
INSTRUCTION_TABLE := [Mnemonic][]Form{
	.INVALID = {},

	// =========================================================================
	// §1 RV32I / RV64I base
	// =========================================================================

	//  Upper-immediate
	.LUI = {
		{{.LUI,   {.GPR,.IMM20,.NONE,.NONE}, {.RD,.IMM_U,.NONE,.NONE}, 0x00000037, MASK_U, .I, {}},                                                            {written={0}}},
	},
	.AUIPC = {
		{{.AUIPC, {.GPR,.IMM20,.NONE,.NONE}, {.RD,.IMM_U,.NONE,.NONE}, 0x00000017, MASK_U, .I, {}},                                                            {written={0}}},
	},

	//  Jumps
	.JAL = {
		{{.JAL,  {.GPR,.REL21,.NONE,.NONE},  {.RD,.IMM_J,.NONE,.NONE}, 0x0000006F, MASK_J, .I, {branch=true}},                                                 {written={0}, side_effects={.CONTROL}}},
	},
	.JALR = {
		{{.JALR, {.GPR,.GPR,.IMM12,.NONE},   {.RD,.RS1,.IMM_I,.NONE},  0x00000067, MASK_OPCODE | MASK_FUNCT3, .I, {branch=true}},                              {written={0}, read={1}, side_effects={.CONTROL}}},
	},

	//  Branches (B-type)
	.BEQ = {
		{{.BEQ,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00000063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},
	.BNE = {
		{{.BNE,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00001063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},
	.BLT = {
		{{.BLT,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00004063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},
	.BGE = {
		{{.BGE,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00005063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},
	.BLTU = {
		{{.BLTU, {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00006063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},
	.BGEU = {
		{{.BGEU, {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00007063, MASK_B, .I, {branch=true}},                                                   {read={0, 1}, side_effects={.CONTROL}}},
	},

	//  Loads (I-type)
	.LB = {
		{{.LB,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00000003, MASK_I, .I, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.LH = {
		{{.LH,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00001003, MASK_I, .I, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.LW = {
		{{.LW,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00002003, MASK_I, .I, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.LBU = {
		{{.LBU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00004003, MASK_I, .I, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.LHU = {
		{{.LHU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00005003, MASK_I, .I, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.LWU = {
		{{.LWU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00006003, MASK_I, .I, {rv64_only=true}},                                          {written={0}, read={1}, reads_mem=true}},
	},
	.LD = {
		{{.LD,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00003003, MASK_I, .I, {rv64_only=true}},                                          {written={0}, read={1}, reads_mem=true}},
	},

	//  Stores (S-type)
	.SB = {
		{{.SB, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00000023, MASK_S, .I, {}},                                                        {read={0, 1}, writes_mem=true}},
	},
	.SH = {
		{{.SH, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00001023, MASK_S, .I, {}},                                                        {read={0, 1}, writes_mem=true}},
	},
	.SW = {
		{{.SW, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00002023, MASK_S, .I, {}},                                                        {read={0, 1}, writes_mem=true}},
	},
	.SD = {
		{{.SD, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00003023, MASK_S, .I, {rv64_only=true}},                                          {read={0, 1}, writes_mem=true}},
	},

	//  Integer reg-imm (I-type ALU)
	.ADDI = {
		{{.ADDI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00000013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},
	.SLTI = {
		{{.SLTI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00002013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},
	.SLTIU = {
		{{.SLTIU, {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00003013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},
	.XORI = {
		{{.XORI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00004013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},
	.ORI = {
		{{.ORI,   {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00006013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},
	.ANDI = {
		{{.ANDI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00007013, MASK_I, .I, {}},                                                              {written={0}, read={1}}},
	},

	.SLLI = {
		{{.SLLI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x00001013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}},                               {written={0}, read={1}}},
	},
	.SRLI = {
		{{.SRLI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x00005013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}},                               {written={0}, read={1}}},
	},
	.SRAI = {
		{{.SRAI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x40005013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}},                               {written={0}, read={1}}},
	},

	.ADDIW = {
		{{.ADDIW, {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE},  0x0000001B, MASK_I, .I, {rv64_only=true}},                                               {written={0}, read={1}}},
	},
	.SLLIW = {
		{{.SLLIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x0000101B, MASK_R, .I, {rv64_only=true}},                                               {written={0}, read={1}}},
	},
	.SRLIW = {
		{{.SRLIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x0000501B, MASK_R, .I, {rv64_only=true}},                                               {written={0}, read={1}}},
	},
	.SRAIW = {
		{{.SRAIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x4000501B, MASK_R, .I, {rv64_only=true}},                                               {written={0}, read={1}}},
	},

	//  Integer reg-reg (R-type)
	.ADD = {
		{{.ADD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00000033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SUB = {
		{{.SUB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x40000033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SLL = {
		{{.SLL,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00001033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SLT = {
		{{.SLT,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00002033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SLTU = {
		{{.SLTU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00003033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.XOR = {
		{{.XOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00004033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SRL = {
		{{.SRL,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00005033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.SRA = {
		{{.SRA,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x40005033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.OR = {
		{{.OR,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00006033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},
	.AND = {
		{{.AND,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00007033, MASK_R, .I, {}},                                                                   {written={0}, read={1, 2}}},
	},

	.ADDW = {
		{{.ADDW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000003B, MASK_R, .I, {rv64_only=true}},                                                     {written={0}, read={1, 2}}},
	},
	.SUBW = {
		{{.SUBW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x4000003B, MASK_R, .I, {rv64_only=true}},                                                     {written={0}, read={1, 2}}},
	},
	.SLLW = {
		{{.SLLW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000103B, MASK_R, .I, {rv64_only=true}},                                                     {written={0}, read={1, 2}}},
	},
	.SRLW = {
		{{.SRLW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000503B, MASK_R, .I, {rv64_only=true}},                                                     {written={0}, read={1, 2}}},
	},
	.SRAW = {
		{{.SRAW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x4000503B, MASK_R, .I, {rv64_only=true}},                                                     {written={0}, read={1, 2}}},
	},

	//  Memory ordering
	.FENCE = {
		{{.FENCE,   {.FENCE_FLAGS,.FENCE_FLAGS,.NONE,.NONE}, {.FENCE_PRED,.FENCE_SUCC,.NONE,.NONE}, 0x0000000F, MASK_I, .I, {}},                               {side_effects={.FENCE}}},
	},
	.FENCE_I = {
		{{.FENCE_I, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0000100F, 0xFFFFFFFF, .ZIFENCEI, {}},                                              {side_effects={.IFENCE}}},
	},

	//  System
	.ECALL = {
		{{.ECALL,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000073, 0xFFFFFFFF, .I, {branch=true}},                                           {side_effects={.TRAP, .CONTROL}}},
	},
	.EBREAK = {
		{{.EBREAK, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00100073, 0xFFFFFFFF, .I, {branch=true}},                                           {side_effects={.TRAP, .CONTROL}}},
	},

	// =========================================================================
	// §2 Zicsr (CSR access) — csr operand (slot 1) marked r+w conservatively
	// =========================================================================
	.CSRRW = {
		{{.CSRRW,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00001073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1, 2}}},
	},
	.CSRRS = {
		{{.CSRRS,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00002073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1, 2}}},
	},
	.CSRRC = {
		{{.CSRRC,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00003073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1, 2}}},
	},
	.CSRRWI = {
		{{.CSRRWI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00005073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1}}},
	},
	.CSRRSI = {
		{{.CSRRSI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00006073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1}}},
	},
	.CSRRCI = {
		{{.CSRRCI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00007073, MASK_I, .ZICSR, {}},                                              {written={0, 1}, read={1}}},
	},

	// =========================================================================
	// §3 M extension — pure dataflow; no trap, no flags (incl. DIV/REM by 0)
	// =========================================================================
	.MUL = {
		{{.MUL,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02000033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.MULH = {
		{{.MULH,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02001033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.MULHSU = {
		{{.MULHSU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02002033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.MULHU = {
		{{.MULHU,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02003033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.DIV = {
		{{.DIV,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02004033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.DIVU = {
		{{.DIVU,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02005033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.REM = {
		{{.REM,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02006033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},
	.REMU = {
		{{.REMU,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02007033, MASK_R, .M, {}},                                                                 {written={0}, read={1, 2}}},
	},

	.MULW = {
		{{.MULW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200003B, MASK_R, .M, {rv64_only=true}},                                                   {written={0}, read={1, 2}}},
	},
	.DIVW = {
		{{.DIVW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200403B, MASK_R, .M, {rv64_only=true}},                                                   {written={0}, read={1, 2}}},
	},
	.DIVUW = {
		{{.DIVUW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200503B, MASK_R, .M, {rv64_only=true}},                                                   {written={0}, read={1, 2}}},
	},
	.REMW = {
		{{.REMW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200603B, MASK_R, .M, {rv64_only=true}},                                                   {written={0}, read={1, 2}}},
	},
	.REMUW = {
		{{.REMUW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200703B, MASK_R, .M, {rv64_only=true}},                                                   {written={0}, read={1, 2}}},
	},

	// =========================================================================
	// §4 A extension (atomics)
	// =========================================================================
	.LR_W = {
		{{.LR_W,      {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_A,.NONE,.NONE}, 0x1000202F, 0xF9F0707F, .A, {}},                                              {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.SC_W = {
		{{.SC_W,      {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x1800202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.AMOSWAP_W = {
		{{.AMOSWAP_W, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x0800202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOADD_W = {
		{{.AMOADD_W,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x0000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOXOR_W = {
		{{.AMOXOR_W,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x2000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOAND_W = {
		{{.AMOAND_W,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x6000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOOR_W = {
		{{.AMOOR_W,   {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x4000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMIN_W = {
		{{.AMOMIN_W,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x8000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMAX_W = {
		{{.AMOMAX_W,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xA000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMINU_W = {
		{{.AMOMINU_W, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xC000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMAXU_W = {
		{{.AMOMAXU_W, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xE000202F, 0xF800707F, .A, {}},                                              {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},

	.LR_D = {
		{{.LR_D,      {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_A,.NONE,.NONE}, 0x1000302F, 0xF9F0707F, .A, {rv64_only=true}},                                {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.SC_D = {
		{{.SC_D,      {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x1800302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.AMOSWAP_D = {
		{{.AMOSWAP_D, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x0800302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOADD_D = {
		{{.AMOADD_D,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x0000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOXOR_D = {
		{{.AMOXOR_D,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x2000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOAND_D = {
		{{.AMOAND_D,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x6000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOOR_D = {
		{{.AMOOR_D,   {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x4000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMIN_D = {
		{{.AMOMIN_D,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0x8000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMAX_D = {
		{{.AMOMAX_D,  {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xA000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMINU_D = {
		{{.AMOMINU_D, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xC000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},
	.AMOMAXU_D = {
		{{.AMOMAXU_D, {.GPR,.GPR,.MEM,.NONE},  {.RD,.RS2,.OFFSET_BASE_A,.NONE},  0xE000302F, 0xF800707F, .A, {rv64_only=true}},                                {written={0}, read={1, 2}, reads_mem=true, writes_mem=true, side_effects={.ATOMIC}}},
	},

	// =========================================================================
	// §5 F extension (single-precision) — reads_frm == encoding fp_round
	// =========================================================================
	.FLW = {
		{{.FLW, {.FPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00002007, MASK_I, .F, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.FSW = {
		{{.FSW, {.FPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00002027, MASK_S, .F, {}},                                                       {read={0, 1}, writes_mem=true}},
	},

	.FMADD_S = {
		{{.FMADD_S,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x00000043, 0x0600007F, .F, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FMSUB_S = {
		{{.FMSUB_S,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x00000047, 0x0600007F, .F, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FNMSUB_S = {
		{{.FNMSUB_S, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0000004B, 0x0600007F, .F, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FNMADD_S = {
		{{.FNMADD_S, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0000004F, 0x0600007F, .F, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},

	.FADD_S = {
		{{.FADD_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FSUB_S = {
		{{.FSUB_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x08000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FMUL_S = {
		{{.FMUL_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x10000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FDIV_S = {
		{{.FDIV_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x18000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .DZ, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FSQRT_S = {
		{{.FSQRT_S, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x58000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}},                   {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},

	.FSGNJ_S = {
		{{.FSGNJ_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20000053, MASK_R, .F, {}},                                                               {written={0}, read={1, 2}}},
	},
	.FSGNJN_S = {
		{{.FSGNJN_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20001053, MASK_R, .F, {}},                                                               {written={0}, read={1, 2}}},
	},
	.FSGNJX_S = {
		{{.FSGNJX_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20002053, MASK_R, .F, {}},                                                               {written={0}, read={1, 2}}},
	},

	.FMIN_S = {
		{{.FMIN_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x28000053, MASK_R, .F, {}},                                                                 {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FMAX_S = {
		{{.FMAX_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x28001053, MASK_R, .F, {}},                                                                 {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},

	.FCVT_W_S = {
		{{.FCVT_W_S,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_WU_S = {
		{{.FCVT_WU_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_L_S = {
		{{.FCVT_L_S,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_LU_S = {
		{{.FCVT_LU_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},

	.FCVT_S_W = {
		{{.FCVT_S_W,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},
	.FCVT_S_WU = {
		{{.FCVT_S_WU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},
	.FCVT_S_L = {
		{{.FCVT_S_L,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},
	.FCVT_S_LU = {
		{{.FCVT_S_LU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},

	.FMV_X_W = {
		{{.FMV_X_W,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}},                 {written={0}, read={1}}},
	},
	.FMV_W_X = {
		{{.FMV_W_X,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xF0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}},                 {written={0}, read={1}}},
	},
	.FCLASS_S = {
		{{.FCLASS_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE0001053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}},                 {written={0}, read={1}}},
	},

	.FEQ_S = {
		{{.FEQ_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0002053, MASK_R, .F, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FLT_S = {
		{{.FLT_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0001053, MASK_R, .F, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FLE_S = {
		{{.FLE_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0000053, MASK_R, .F, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},

	// =========================================================================
	// §6 D extension (double-precision)
	// =========================================================================
	.FLD = {
		{{.FLD, {.FPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00003007, MASK_I, .D, {}},                                                        {written={0}, read={1}, reads_mem=true}},
	},
	.FSD = {
		{{.FSD, {.FPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00003027, MASK_S, .D, {}},                                                       {read={0, 1}, writes_mem=true}},
	},

	.FMADD_D = {
		{{.FMADD_D,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x02000043, 0x0600007F, .D, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FMSUB_D = {
		{{.FMSUB_D,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x02000047, 0x0600007F, .D, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FNMSUB_D = {
		{{.FNMSUB_D, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0200004B, 0x0600007F, .D, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FNMADD_D = {
		{{.FNMADD_D, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0200004F, 0x0600007F, .D, {fp_round=true}},                                                {written={0}, read={1, 2, 3}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},

	.FADD_D = {
		{{.FADD_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FSUB_D = {
		{{.FSUB_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0A000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FMUL_D = {
		{{.FMUL_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x12000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FDIV_D = {
		{{.FDIV_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x1A000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}},                                {written={0}, read={1, 2}, fflags_wr={.NV, .DZ, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FSQRT_D = {
		{{.FSQRT_D, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x5A000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                   {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},

	.FSGNJ_D = {
		{{.FSGNJ_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22000053, MASK_R, .D, {}},                                                               {written={0}, read={1, 2}}},
	},
	.FSGNJN_D = {
		{{.FSGNJN_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22001053, MASK_R, .D, {}},                                                               {written={0}, read={1, 2}}},
	},
	.FSGNJX_D = {
		{{.FSGNJX_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22002053, MASK_R, .D, {}},                                                               {written={0}, read={1, 2}}},
	},

	.FMIN_D = {
		{{.FMIN_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x2A000053, MASK_R, .D, {}},                                                                 {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FMAX_D = {
		{{.FMAX_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x2A001053, MASK_R, .D, {}},                                                                 {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},

	.FCVT_S_D = {
		{{.FCVT_S_D, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x40100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                  {written={0}, read={1}, fflags_wr={.NV, .OF, .UF, .NX}, reads_frm=true}},
	},
	.FCVT_D_S = {
		{{.FCVT_D_S, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x42000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                  {written={0}, read={1}, fflags_wr={.NV}, reads_frm=true}},
	},

	.FCVT_W_D = {
		{{.FCVT_W_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_WU_D = {
		{{.FCVT_WU_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                 {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_L_D = {
		{{.FCVT_L_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},
	.FCVT_LU_D = {
		{{.FCVT_LU_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NV, .NX}, reads_frm=true}},
	},

	// FCVT_D_W / FCVT_D_WU are always exact (32-bit int fits a double), so no
	// fflags — but reads_frm follows the fp_round flag for class-uniformity.
	.FCVT_D_W = {
		{{.FCVT_D_W,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                 {written={0}, read={1}, reads_frm=true}},
	},
	.FCVT_D_WU = {
		{{.FCVT_D_WU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}},                 {written={0}, read={1}, reads_frm=true}},
	},
	.FCVT_D_L = {
		{{.FCVT_D_L,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},
	.FCVT_D_LU = {
		{{.FCVT_D_LU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}}, {written={0}, read={1}, fflags_wr={.NX}, reads_frm=true}},
	},

	.FMV_X_D = {
		{{.FMV_X_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {rv64_only=true}},   {written={0}, read={1}}},
	},
	.FMV_D_X = {
		{{.FMV_D_X,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xF2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {rv64_only=true}},   {written={0}, read={1}}},
	},
	.FCLASS_D = {
		{{.FCLASS_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE2001053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {}},                 {written={0}, read={1}}},
	},

	.FEQ_D = {
		{{.FEQ_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2002053, MASK_R, .D, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FLT_D = {
		{{.FLT_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2001053, MASK_R, .D, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},
	.FLE_D = {
		{{.FLE_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2000053, MASK_R, .D, {}},                                                                  {written={0}, read={1, 2}, fflags_wr={.NV}}},
	},

	// =========================================================================
	// C extension: Quadrant 0 (op = 00)
	// =========================================================================
	.C_ADDI4SPN = {
		{{.C_ADDI4SPN, {.GPR_C, .GPR_SP, .IMM_C8U, .NONE}, {.C_RD_PRIMED, .NONE, .C_IMM_CIW, .NONE}, 0x0000, 0xE003, .C, {}},                                  {written={0}, read={1}}},
	},
	.C_FLD = {
		{{.C_FLD, {.FPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0x2000, 0xE003, .D, {}},                                   {written={0}, read={1}, reads_mem=true}},
	},
	.C_LW = {
		{{.C_LW,  {.GPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_W, .NONE, .NONE}, 0x4000, 0xE003, .C, {}},                                   {written={0}, read={1}, reads_mem=true}},
	},
	.C_LD = {
		{{.C_LD,  {.GPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0x6000, 0xE003, .C, {rv64_only=true}},                     {written={0}, read={1}, reads_mem=true}},
	},
	.C_FSD = {
		{{.C_FSD, {.FPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0xA000, 0xE003, .D, {}},                                  {read={0, 1}, writes_mem=true}},
	},
	.C_SW = {
		{{.C_SW,  {.GPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_W, .NONE, .NONE}, 0xC000, 0xE003, .C, {}},                                  {read={0, 1}, writes_mem=true}},
	},
	.C_SD = {
		{{.C_SD,  {.GPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0xE000, 0xE003, .C, {rv64_only=true}},                    {read={0, 1}, writes_mem=true}},
	},

	// C.FLW / C.FSW — RV32-only, share the C.LD / C.SD slots
	.C_FLW = {
		{{.C_FLW, {.FPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RD_PRIMED,  .C_OFFSET_BASE_W, .NONE, .NONE}, 0x6000, 0xE003, .F, {rv32_only=true}},                    {written={0}, read={1}, reads_mem=true}},
	},
	.C_FSW = {
		{{.C_FSW, {.FPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_W, .NONE, .NONE}, 0xE000, 0xE003, .F, {rv32_only=true}},                    {read={0, 1}, writes_mem=true}},
	},

	// =========================================================================
	// C extension: Quadrant 1 (op = 01)
	// =========================================================================
	.C_NOP = {
		{{.C_NOP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0001, 0xFFFF, .C, {}},                                                               {}},
	},
	.C_ADDI = {
		{{.C_ADDI, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x0001, 0xE003, .C, {}},                                    {written={0}, read={0}}},
	},
	.C_JAL = {
		{{.C_JAL, {.REL12, .NONE, .NONE, .NONE}, {.C_BRANCH12, .NONE, .NONE, .NONE}, 0x2001, 0xE003, .C, {rv32_only=true, branch=true}},                       {implicit_wr={.RA}, side_effects={.CONTROL}}},
	},
	.C_ADDIW = {
		{{.C_ADDIW, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x2001, 0xE003, .C, {rv64_only=true}},                     {written={0}, read={0}}},
	},
	.C_LI = {
		{{.C_LI, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x4001, 0xE003, .C, {}},                                      {written={0}}},
	},
	.C_ADDI16SP = {
		{{.C_ADDI16SP, {.GPR_SP, .IMM_C10S, .NONE, .NONE}, {.NONE, .C_IMM_ADDI16SP, .NONE, .NONE}, 0x6101, 0xEF83, .C, {}},                                    {written={0}, read={0}}},
	},
	.C_LUI = {
		{{.C_LUI, {.GPR_NONZERO, .IMM_C18S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_LUI, .NONE, .NONE}, 0x6001, 0xE003, .C, {}},                                     {written={0}}},
	},
	.C_SRLI = {
		{{.C_SRLI, {.GPR_C, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_U, .NONE, .NONE}, 0x8001, 0xEC03, .C, {}},                                   {written={0}, read={0}}},
	},
	.C_SRAI = {
		{{.C_SRAI, {.GPR_C, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_U, .NONE, .NONE}, 0x8401, 0xEC03, .C, {}},                                   {written={0}, read={0}}},
	},
	.C_ANDI = {
		{{.C_ANDI, {.GPR_C, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_S, .NONE, .NONE}, 0x8801, 0xEC03, .C, {}},                                   {written={0}, read={0}}},
	},
	.C_SUB = {
		{{.C_SUB,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C01, 0xFC63, .C, {}},                                   {written={0}, read={0, 1}}},
	},
	.C_XOR = {
		{{.C_XOR,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C21, 0xFC63, .C, {}},                                   {written={0}, read={0, 1}}},
	},
	.C_OR = {
		{{.C_OR,   {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C41, 0xFC63, .C, {}},                                   {written={0}, read={0, 1}}},
	},
	.C_AND = {
		{{.C_AND,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C61, 0xFC63, .C, {}},                                   {written={0}, read={0, 1}}},
	},
	.C_SUBW = {
		{{.C_SUBW, {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x9C01, 0xFC63, .C, {rv64_only=true}},                     {written={0}, read={0, 1}}},
	},
	.C_ADDW = {
		{{.C_ADDW, {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x9C21, 0xFC63, .C, {rv64_only=true}},                     {written={0}, read={0, 1}}},
	},
	.C_J = {
		{{.C_J, {.REL12, .NONE, .NONE, .NONE}, {.C_BRANCH12, .NONE, .NONE, .NONE}, 0xA001, 0xE003, .C, {branch=true}},                                         {side_effects={.CONTROL}}},
	},
	.C_BEQZ = {
		{{.C_BEQZ, {.GPR_C, .REL9, .NONE, .NONE}, {.C_RS1_PRIMED, .C_BRANCH9, .NONE, .NONE}, 0xC001, 0xE003, .C, {branch=true}},                               {read={0}, side_effects={.CONTROL}}},
	},
	.C_BNEZ = {
		{{.C_BNEZ, {.GPR_C, .REL9, .NONE, .NONE}, {.C_RS1_PRIMED, .C_BRANCH9, .NONE, .NONE}, 0xE001, 0xE003, .C, {branch=true}},                               {read={0}, side_effects={.CONTROL}}},
	},

	// =========================================================================
	// C extension: Quadrant 2 (op = 10)
	// =========================================================================
	.C_SLLI = {
		{{.C_SLLI, {.GPR_NONZERO, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_U, .NONE, .NONE}, 0x0002, 0xE003, .C, {}},                                    {written={0}, read={0}}},
	},
	.C_FLDSP = {
		{{.C_FLDSP, {.FPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_D, .NONE, .NONE}, 0x2002, 0xE003, .D, {}},                                     {written={0}, implicit_rd={.SP}, reads_mem=true}},
	},
	.C_LWSP = {
		{{.C_LWSP, {.GPR_NONZERO, .MEM_C_SP_W, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_W, .NONE, .NONE}, 0x4002, 0xE003, .C, {}},                              {written={0}, implicit_rd={.SP}, reads_mem=true}},
	},
	.C_LDSP = {
		{{.C_LDSP, {.GPR_NONZERO, .MEM_C_SP_D, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_D, .NONE, .NONE}, 0x6002, 0xE003, .C, {rv64_only=true}},                {written={0}, implicit_rd={.SP}, reads_mem=true}},
	},
	.C_JR = {
		{{.C_JR,   {.GPR_NONZERO, .NONE, .NONE, .NONE}, {.C_RD_RS1, .NONE, .NONE, .NONE}, 0x8002, 0xF07F, .C, {branch=true}},                                  {read={0}, side_effects={.CONTROL}}},
	},
	.C_MV = {
		{{.C_MV,   {.GPR_NONZERO, .GPR_NONZERO, .NONE, .NONE}, {.C_RD_RS1, .C_RS2, .NONE, .NONE}, 0x8002, 0xF003, .C, {}},                                     {written={0}, read={1}}},
	},
	.C_EBREAK = {
		{{.C_EBREAK, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x9002, 0xFFFF, .C, {}},                                                            {side_effects={.TRAP, .CONTROL}}},
	},
	.C_JALR = {
		{{.C_JALR,   {.GPR_NONZERO, .NONE, .NONE, .NONE}, {.C_RD_RS1, .NONE, .NONE, .NONE}, 0x9002, 0xF07F, .C, {branch=true}},                                {read={0}, implicit_wr={.RA}, side_effects={.CONTROL}}},
	},
	.C_ADD = {
		{{.C_ADD,    {.GPR_NONZERO, .GPR_NONZERO, .NONE, .NONE}, {.C_RD_RS1, .C_RS2, .NONE, .NONE}, 0x9002, 0xF003, .C, {}},                                   {written={0}, read={0, 1}}},
	},
	.C_FSDSP = {
		{{.C_FSDSP, {.FPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_D, .NONE, .NONE}, 0xA002, 0xE003, .D, {}},                                          {read={0}, implicit_rd={.SP}, writes_mem=true}},
	},
	.C_SWSP = {
		{{.C_SWSP, {.GPR, .MEM_C_SP_W, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_W, .NONE, .NONE}, 0xC002, 0xE003, .C, {}},                                           {read={0}, implicit_rd={.SP}, writes_mem=true}},
	},
	.C_SDSP = {
		{{.C_SDSP, {.GPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_D, .NONE, .NONE}, 0xE002, 0xE003, .C, {rv64_only=true}},                             {read={0}, implicit_rd={.SP}, writes_mem=true}},
	},

	// C.FLWSP / C.FSWSP — RV32-only, share the C.LDSP / C.SDSP slots
	.C_FLWSP = {
		{{.C_FLWSP, {.FPR, .MEM_C_SP_W, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_W, .NONE, .NONE}, 0x6002, 0xE003, .F, {rv32_only=true}},                       {written={0}, implicit_rd={.SP}, reads_mem=true}},
	},
	.C_FSWSP = {
		{{.C_FSWSP, {.FPR, .MEM_C_SP_W, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_W, .NONE, .NONE}, 0xE002, 0xE003, .F, {rv32_only=true}},                            {read={0}, implicit_rd={.SP}, writes_mem=true}},
	},
}
