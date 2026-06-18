#!/usr/bin/env luajit
-- rexcode  ·  Brendan Punsky (dotbmp@github), original author
--
-- Encode-form spec generator (MIPS / MSA). Expands compact per-family specs
-- into ENCODING_TABLE entries, deriving `bits` from llvm-mc (the oracle) and
-- `mask` empirically: assemble each form all-zero, then one variant per operand
-- field at its max register, and mask = ~(union of the deltas). MIPS words are
-- big-endian. Each MSA element format (.B/.H/.W/.D) is a distinct mnemonic
-- (e.g. FADD_W / FADD_D), so the data-format suffix is part of the name.
--
-- Output replaces the SPECGEN:BEGIN..SPECGEN:END region of encoding_table.odin.
--
--   Run: luajit tablegen/specgen.lua   (from mips/, or with a full path)

local bit  = require("bit")
local LLVM = "llvm-mc --assemble --triple=mips --mattr=+msa,+dsp,+dspr2,+mips32r2,+fp64 --show-encoding"
local DIR   = (arg[0]:match("^(.*)/[^/]*$")) or "."
local TABLE = DIR .. "/encoding_table.odin"

local function word(line)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | %s 2>/dev/null", line, LLVM))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b1..b2..b3..b4, 16)   -- big-endian: first byte is MSB
end
local function mask_of(base, variants)
	local x = 0
	for _, w in ipairs(variants) do x = bit.bor(x, bit.bxor(base, w)) end
	return bit.band(bit.bnot(x), 0xFFFFFFFF)
end

local sections, skips, n_forms = {}, {}, 0

-- Emit one mnemonic's single-form entry from an asm builder + per-field maxes.
-- ops/enc are the prebuilt "{.A,.B,.C,.NONE}" text. asm(vals) returns the asm
-- (vals[i] = register number for field i); maxes[i] = max register for field i.
local function entry(mnem, ops, enc, feat, asm, maxes)
	local zero = {}; for i=1,#maxes do zero[i]=0 end
	local b0 = word(asm(zero))
	if not b0 then skips[#skips+1]=mnem; return nil end
	local vs = {}
	for i=1,#maxes do
		local v={}; for j=1,#maxes do v[j]=0 end; v[i]=maxes[i]
		local w=word(asm(v)); if not w then skips[#skips+1]=mnem; return nil end; vs[#vs+1]=w
	end
	n_forms = n_forms + 1
	return string.format("    .%s = { {.%s, %s, %s, 0x%s, 0x%s, .%s, {}} },",
		mnem, mnem, ops, enc, bit.tohex(b0):upper(), bit.tohex(mask_of(b0,vs)):upper(), feat)
end

-- A vector 3-register family: Wd, Ws, Wt (each a .B/.H/.W/.D variant).
local OPS3 = "{.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}"
local ENC3 = "{.WD,.WS,.WT,.NONE}"
local OPS2 = "{.MSA_VEC,.MSA_VEC,.NONE,.NONE}"
local ENC2 = "{.WD,.WS,.NONE,.NONE}"

-- emit a family across data-format suffixes.
--   base  = uppercase stem (FADD); low = lowercase asm stem (fadd)
--   dfs   = list of {SUFFIX, asm_token}  (e.g. {"W","w"})
--   three = 3-register (else 2-register)
local function family(base, low, dfs, three)
	local rows = {}
	local ops = three and OPS3 or ENC3 and (three and OPS3 or OPS2)
	for _, d in ipairs(dfs) do
		local mnem = base .. "_" .. d[1]
		local function asm(v)
			if three then return string.format("%s.%s $w%d,$w%d,$w%d", low, d[2], v[1], v[2], v[3]) end
			return string.format("%s.%s $w%d,$w%d", low, d[2], v[1], v[2])
		end
		local r = entry(mnem, three and OPS3 or OPS2, three and ENC3 or ENC2, "MSA", asm, three and {31,31,31} or {31,31})
		if r then rows[#rows+1] = r end
	end
	for _, r in ipairs(rows) do sections[#sections+1] = r end
end

local WD = {{"W","w"},{"D","d"}}                -- 3RF / 2RF data formats
local HWD = {{"H","h"},{"W","w"},{"D","d"}}     -- 3R (no byte) data formats
local BHWD = {{"B","b"},{"H","h"},{"W","w"},{"D","d"}}

-- ---- 3RF: vector floating-point arithmetic / compare (Wd, Ws, Wt; .W/.D) ----
for _, b in ipairs({
	{"FADD","fadd"},{"FSUB","fsub"},{"FMUL","fmul"},{"FDIV","fdiv"},
	{"FMAX","fmax"},{"FMIN","fmin"},
	{"FCEQ","fceq"},{"FCLE","fcle"},{"FCLT","fclt"},{"FCNE","fcne"},
}) do family(b[1], b[2], WD, true) end

-- ---- 3R: signed/unsigned dot product (Wd, Ws, Wt; .H/.W/.D) -----------------
for _, b in ipairs({{"DOTP_S","dotp_s"},{"DOTP_U","dotp_u"}}) do family(b[1], b[2], HWD, true) end

-- ---- VEC: bit-select (no data format) --------------------------------------
for _, b in ipairs({{"BMNZ_V","bmnz.v"},{"BMZ_V","bmz.v"},{"BSEL_V","bsel.v"}}) do
	local r = entry(b[1], OPS3, ENC3, "MSA", function(v) return string.format("%s $w%d,$w%d,$w%d", b[2], v[1], v[2], v[3]) end, {31,31,31})
	if r then sections[#sections+1] = r end
end

-- ---- 2R: count leading ones/zeros, popcount (Wd, Ws; .B/.H/.W/.D) -----------
for _, b in ipairs({{"NLOC","nloc"},{"NLZC","nlzc"},{"PCNT","pcnt"}}) do family(b[1], b[2], BHWD, false) end

-- ---- 2RF: vector floating-point one-source (Wd, Ws; .W/.D) ------------------
for _, b in ipairs({
	{"FSQRT","fsqrt"},{"FRSQRT","frsqrt"},{"FRCP","frcp"},{"FRINT","frint"},
	{"FTRUNC_S","ftrunc_s"},{"FTRUNC_U","ftrunc_u"},{"FFINT_S","ffint_s"},{"FFINT_U","ffint_u"},
}) do family(b[1], b[2], WD, false) end

-- ---- BIT: shift by immediate (Wd, Ws, m) -- marker per df in `bits` --------
local BIT_SH = {b=7, h=15, w=31, d=63}
for _, base in ipairs({{"SLLI","slli"},{"SRAI","srai"},{"SRLI","srli"}}) do
	for _, d in ipairs(BHWD) do
		local r = entry(base[1].."_"..d[1], "{.MSA_VEC,.MSA_VEC,.IMM5,.NONE}", "{.WD,.WS,.MSA_BIT_SHIFT,.NONE}", "MSA",
			function(v) return string.format("%s.%s $w%d,$w%d,%d", base[2], d[2], v[1], v[2], v[3]) end, {31,31,BIT_SH[d[2]]})
		if r then sections[#sections+1]=r end
	end
end

-- ---- ELM: element broadcast/insert by immediate index (Wd, Ws[idx]) --------
local ELM_IDX = {b=15, h=7, w=3, d=1}
for _, base in ipairs({{"SPLATI","splati"},{"SLDI","sldi"}}) do
	for _, d in ipairs(BHWD) do
		local r = entry(base[1].."_"..d[1], "{.MSA_VEC,.MSA_VEC,.IMM5,.NONE}", "{.WD,.WS,.MSA_ELM_IDX,.NONE}", "MSA",
			function(v) return string.format("%s.%s $w%d,$w%d[%d]", base[2], d[2], v[1], v[2], v[3]) end, {31,31,ELM_IDX[d[2]]})
		if r then sections[#sections+1]=r end
	end
end

-- ---- VSHF (3R vector shuffle) ----------------------------------------------
for _, d in ipairs(BHWD) do
	local r = entry("VSHF_"..d[1], OPS3, ENC3, "MSA",
		function(v) return string.format("vshf.%s $w%d,$w%d,$w%d", d[2], v[1], v[2], v[3]) end, {31,31,31})
	if r then sections[#sections+1]=r end
end

-- ---- SPLAT / SLD (element broadcast/slide by GPR index) --------------------
for _, base in ipairs({{"SPLAT","splat"},{"SLD","sld"}}) do
	for _, d in ipairs(BHWD) do
		local r = entry(base[1].."_"..d[1], "{.MSA_VEC,.MSA_VEC,.GPR,.NONE}", "{.WD,.WS,.RT,.NONE}", "MSA",
			function(v) return string.format("%s.%s $w%d,$w%d[$%d]", base[2], d[2], v[1], v[2], v[3]) end, {31,31,31})
		if r then sections[#sections+1]=r end
	end
end

-- ---- I8: 8-bit-immediate logical / shuffle ---------------------------------
for _, base in ipairs({{"ANDI_B","andi.b"},{"ORI_B","ori.b"},{"XORI_B","xori.b"},{"NORI_B","nori.b"},
	{"BMNZI_B","bmnzi.b"},{"BMZI_B","bmzi.b"},{"BSELI_B","bseli.b"}}) do
	local r = entry(base[1], "{.MSA_VEC,.MSA_VEC,.IMM5,.NONE}", "{.WD,.WS,.MSA_I8,.NONE}", "MSA",
		function(v) return string.format("%s $w%d,$w%d,%d", base[2], v[1], v[2], v[3]) end, {31,31,255})
	if r then sections[#sections+1]=r end
end
for _, d in ipairs({{"B","b"},{"H","h"},{"W","w"}}) do
	local r = entry("SHF_"..d[1], "{.MSA_VEC,.MSA_VEC,.IMM5,.NONE}", "{.WD,.WS,.MSA_I8,.NONE}", "MSA",
		function(v) return string.format("shf.%s $w%d,$w%d,%d", d[2], v[1], v[2], v[3]) end, {31,31,255})
	if r then sections[#sections+1]=r end
end

-- ---- INSVE: element insert from Ws[0] into Wd[idx] -------------------------
for _, d in ipairs(BHWD) do
	local r = entry("INSVE_"..d[1], "{.MSA_VEC,.MSA_VEC,.IMM5,.NONE}", "{.WD,.WS,.MSA_ELM_IDX,.NONE}", "MSA",
		function(v) return string.format("insve.%s $w%d[%d],$w%d[0]", d[2], v[1], v[3], v[2]) end, {31,31,ELM_IDX[d[2]]})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE three-register (Rd, Rs, Rt) -----------------------------------
local GPR3 = "{.GPR,.GPR,.GPR,.NONE}"
local ENC_RDST = "{.RD,.RS,.RT,.NONE}"
for _, b in ipairs({
	{"ADDU_PH","addu.ph"},{"ADDU_S_PH","addu_s.ph"},{"SUBU_PH","subu.ph"},{"SUBU_S_PH","subu_s.ph"},
	{"MULEQ_S_W_PHL","muleq_s.w.phl"},{"MULEQ_S_W_PHR","muleq_s.w.phr"},
	{"MULEU_S_PH_QBL","muleu_s.ph.qbl"},{"MULEU_S_PH_QBR","muleu_s.ph.qbr"},
	{"MULQ_RS_PH","mulq_rs.ph"},{"MULQ_S_PH","mulq_s.ph"},
	{"PRECRQ_PH_W","precrq.ph.w"},{"PRECRQ_QB_PH","precrq.qb.ph"},
	{"PRECRQ_RS_PH_W","precrq_rs.ph.w"},{"PRECRQU_S_QB_PH","precrqu_s.qb.ph"},
	{"PICK_PH","pick.ph"},{"PICK_QB","pick.qb"},
	{"CMPGU_EQ_QB","cmpgu.eq.qb"},{"CMPGU_LE_QB","cmpgu.le.qb"},{"CMPGU_LT_QB","cmpgu.lt.qb"},
}) do
	local r = entry(b[1], GPR3, ENC_RDST, "DSP_R2", function(v) return string.format("%s $%d,$%d,$%d", b[2], v[1], v[2], v[3]) end, {31,31,31})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE variable shifts: Rd, Rt (value), Rs (shift) -> enc {RD,RT,RS} --
for _, b in ipairs({
	{"SHLLV_PH","shllv.ph"},{"SHLLV_S_PH","shllv_s.ph"},{"SHLLV_S_W","shllv_s.w"},
	{"SHRAV_PH","shrav.ph"},{"SHRAV_QB","shrav.qb"},{"SHRAV_R_PH","shrav_r.ph"},
	{"SHRAV_R_QB","shrav_r.qb"},{"SHRAV_R_W","shrav_r.w"},{"SHRLV_PH","shrlv.ph"},
}) do
	local r = entry(b[1], GPR3, "{.RD,.RT,.RS,.NONE}", "DSP_R2", function(v) return string.format("%s $%d,$%d,$%d", b[2], v[1], v[2], v[3]) end, {31,31,31})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE compare (Rs, Rt -> DSP flags) ---------------------------------
for _, b in ipairs({
	{"CMP_EQ_PH","cmp.eq.ph"},{"CMP_LE_PH","cmp.le.ph"},{"CMP_LT_PH","cmp.lt.ph"},
	{"CMPU_EQ_QB","cmpu.eq.qb"},{"CMPU_LE_QB","cmpu.le.qb"},{"CMPU_LT_QB","cmpu.lt.qb"},
}) do
	local r = entry(b[1], "{.GPR,.GPR,.NONE,.NONE}", "{.RS,.RT,.NONE,.NONE}", "DSP_R2",
		function(v) return string.format("%s $%d,$%d", b[2], v[1], v[2]) end, {31,31})
	if r then sections[#sections+1]=r end
end

-- ---- FPU conditional move (S/D) -------------------------------------------
for _, b in ipairs({{"MOVN","movn"},{"MOVZ","movz"}}) do
	for _, f in ipairs({{"S","s","FPR_S"},{"D","d","FPR_D"}}) do
		local r = entry(b[1].."_"..f[1], "{."..f[3]..",."..f[3]..",.GPR,.NONE}", "{.FD,.FS,.RT,.NONE}", "FPU",
			function(v) return string.format("%s.%s $f%d,$f%d,$%d", b[2], f[2], v[1], v[2], v[3]) end, {31,31,31})
		if r then sections[#sections+1]=r end
	end
end
for _, b in ipairs({{"MOVF","movf"},{"MOVT","movt"}}) do
	for _, f in ipairs({{"S","s","FPR_S"},{"D","d","FPR_D"}}) do
		local r = entry(b[1].."_"..f[1], "{."..f[3]..",."..f[3]..",.FCC,.NONE}", "{.FD,.FS,.FCC_BC,.NONE}", "FPU",
			function(v) return string.format("%s.%s $f%d,$f%d,$fcc%d", b[2], f[2], v[1], v[2], v[3]) end, {31,31,7})
		if r then sections[#sections+1]=r end
	end
end

-- ---- FPU convert to FP (FCVT_x_y = cvt.x.y) --------------------------------
for _, b in ipairs({{"FCVT_D_W","cvt.d.w","FPR_D","FPR_W"},{"FCVT_S_D","cvt.s.d","FPR_S","FPR_D"},{"FCVT_S_W","cvt.s.w","FPR_S","FPR_W"}}) do
	local r = entry(b[1], "{."..b[3]..",."..b[4]..",.NONE,.NONE}", "{.FD,.FS,.NONE,.NONE}", "FPU",
		function(v) return string.format("%s $f%d,$f%d", b[2], v[1], v[2]) end, {31,31})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE two-register (Rd, Rt) ----------------------------------------
for _, b in ipairs({
	{"PRECEQU_PH_QBLA","precequ.ph.qbla"},{"PRECEQU_PH_QBRA","precequ.ph.qbra"},
	{"PRECEU_PH_QBLA","preceu.ph.qbla"},{"PRECEU_PH_QBRA","preceu.ph.qbra"},
	{"REPLV_PH","replv.ph"},{"REPLV_QB","replv.qb"},
}) do
	local r = entry(b[1], "{.GPR,.GPR,.NONE,.NONE}", "{.RD,.RT,.NONE,.NONE}", "DSP_R2",
		function(v) return string.format("%s $%d,$%d", b[2], v[1], v[2]) end, {31,31})
	if r then sections[#sections+1]=r end
end

-- ---- FPU fused multiply-add (COP1X 4-register: fd, fr, fs, ft) -------------
for _, b in ipairs({{"MADD","madd"},{"MSUB","msub"},{"NMADD","nmadd"},{"NMSUB","nmsub"}}) do
	for _, f in ipairs({{"S","s","FPR_S"},{"D","d","FPR_D"}}) do
		local r = entry(b[1].."_"..f[1], "{."..f[3]..",."..f[3]..",."..f[3]..",."..f[3].."}", "{.FD,.FR,.FS,.FT}", "FPU",
			function(v) return string.format("%s.%s $f%d,$f%d,$f%d,$f%d", b[2], f[2], v[1], v[2], v[3], v[4]) end, {31,31,31,31})
		if r then sections[#sections+1]=r end
	end
end

-- ---- MSA COPY (vector lane -> GPR) and INSERT (GPR -> vector lane) ----------
for _, b in ipairs({{"COPY_S","copy_s"},{"COPY_U","copy_u"}}) do
	for _, d in ipairs({{"B","b",15},{"H","h",7},{"W","w",3}}) do
		local r = entry(b[1].."_"..d[1], "{.GPR,.MSA_VEC,.IMM5,.NONE}", "{.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}", "MSA",
			function(v) return string.format("%s.%s $%d,$w%d[%d]", b[2], d[2], v[1], v[2], v[3]) end, {31,31,d[3]})
		if r then sections[#sections+1]=r end
	end
end
for _, d in ipairs({{"B","b",15},{"H","h",7},{"W","w",3}}) do
	local r = entry("INSERT_"..d[1], "{.MSA_VEC,.GPR,.IMM5,.NONE}", "{.WD,.GPR_AT_11,.MSA_ELM_IDX,.NONE}", "MSA",
		function(v) return string.format("insert.%s $w%d[%d],$%d", d[2], v[1], v[3], v[2]) end, {31,31,d[3]})
	if r then sections[#sections+1]=r end
end

-- ---- Misc control: DI/EI (rt), RDHWR (rt, rd) ------------------------------
for _, b in ipairs({{"DI","di"},{"EI","ei"}}) do
	local r = entry(b[1], "{.GPR,.NONE,.NONE,.NONE}", "{.RT,.NONE,.NONE,.NONE}", "MIPS32_R2",
		function(v) return string.format("%s $%d", b[2], v[1]) end, {31})
	if r then sections[#sections+1]=r end
end
do
	local r = entry("RDHWR", "{.GPR,.GPR,.NONE,.NONE}", "{.RT,.RD,.NONE,.NONE}", "MIPS32_R2",
		function(v) return string.format("rdhwr $%d,$%d", v[1], v[2]) end, {31,31})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE shift by immediate (Rd, Rt, sa) ------------------------------
for _, b in ipairs({{"SHRA_QB","shra.qb",7},{"SHRA_R_QB","shra_r.qb",7},{"SHRA_R_PH","shra_r.ph",15},{"SHRL_PH","shrl.ph",15}}) do
	local r = entry(b[1], "{.GPR,.GPR,.IMM5,.NONE}", "{.RD,.RT,.DSP_SA,.NONE}", "DSP_R2",
		function(v) return string.format("%s $%d,$%d,%d", b[2], v[1], v[2], v[3]) end, {31,31,b[3]})
	if r then sections[#sections+1]=r end
end

-- ---- DSP ASE accumulator ops (ac0..ac3 at bits 12:11, modeled as imm) ------
for _, b in ipairs({
	{"DPA_W_PH","dpa.w.ph"},{"DPAX_W_PH","dpax.w.ph"},{"DPS_W_PH","dps.w.ph"},{"DPSX_W_PH","dpsx.w.ph"},
	{"MAQ_S_W_PHL","maq_s.w.phl"},{"MAQ_S_W_PHR","maq_s.w.phr"},{"MAQ_SA_W_PHL","maq_sa.w.phl"},{"MAQ_SA_W_PHR","maq_sa.w.phr"},
}) do
	local r = entry(b[1], "{.IMM5,.GPR,.GPR,.NONE}", "{.AC_NUM,.RS,.RT,.NONE}", "DSP_R2",
		function(v) return string.format("%s $ac%d,$%d,$%d", b[2], v[1], v[2], v[3]) end, {3,31,31})
	if r then sections[#sections+1]=r end
end
do
	local r = entry("MTHLIP", "{.GPR,.IMM5,.NONE,.NONE}", "{.RS,.AC_NUM,.NONE,.NONE}", "DSP_R2",
		function(v) return string.format("mthlip $%d,$ac%d", v[1], v[2]) end, {31,3})
	if r then sections[#sections+1]=r end
	r = entry("SHILOV", "{.IMM5,.GPR,.NONE,.NONE}", "{.AC_NUM,.RS,.NONE,.NONE}", "DSP_R2",
		function(v) return string.format("shilov $ac%d,$%d", v[1], v[2]) end, {3,31})
	if r then sections[#sections+1]=r end
	-- SHILO immediate is signed 6-bit; vary to -1 so all six field bits toggle.
	r = entry("SHILO", "{.IMM5,.IMM5,.NONE,.NONE}", "{.AC_NUM,.SHILO_IMM,.NONE,.NONE}", "DSP_R2",
		function(v) return string.format("shilo $ac%d,%d", v[1], v[2]) end, {3,-1})
	if r then sections[#sections+1]=r end
end

-- ---- Branches: derive bits/regs, then mark the PC-relative offset variable.
-- Compact (R6) branches need the r6 ISA, so each family passes its own mattr.
local function bword(line, mattr)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | llvm-mc --assemble --triple=mips --mattr=%s --show-encoding 2>/dev/null", line, mattr))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b1..b2..b3..b4, 16)
end
local function branch_block(mnem, ops, enc, feat, asm, maxes, offbits, mattr)
	local zero={}; for i=1,#maxes do zero[i]=0 end
	local b0 = bword(asm(zero), mattr)
	if not b0 then skips[#skips+1]=mnem; return end
	local vs={}
	for i=1,#maxes do
		local v={}; for j=1,#maxes do v[j]=0 end; v[i]=maxes[i]
		local w=bword(asm(v), mattr); if not w then skips[#skips+1]=mnem; return end; vs[#vs+1]=w
	end
	local m = bit.band(mask_of(b0,vs), bit.bnot((2^offbits)-1))  -- offset field = variable
	n_forms=n_forms+1
	sections[#sections+1]=string.format("    .%s = { {.%s, %s, %s, 0x%s, 0x%s, .%s, {}} },",
		mnem, mnem, ops, enc, bit.tohex(b0):upper(), bit.tohex(m):upper(), feat)
end

-- NOTE: the R6 two-/one-register compact branches (BEQC/BNEC/BLTC/BGEC/BLTUC/
-- BGEUC/BLEZC/BGTZC/BGEZC/BLTZC) are intentionally NOT generated here. They
-- pack into shared "POP" major opcodes (e.g. BGEC/BLTC/BLEZC/BGEZC all live in
-- 0x58/0x5C) and are disambiguated only by the rs/rt *relationship* (rs==rt,
-- rs==0, rs<rt) -- which the opcode+mask decode model cannot express without
-- operand-aware logic. Deferred until the decoder grows POP-branch handling.
for _, b in ipairs({{"BZ","bz"},{"BNZ","bnz"}}) do
	for _, d in ipairs({{"B","b"},{"H","h"},{"W","w"},{"D","d"},{"V","v"}}) do
		branch_block(b[1].."_"..d[1], "{.MSA_VEC,.REL16,.NONE,.NONE}", "{.WT,.BRANCH_16,.NONE,.NONE}", "MSA",
			function(v) return string.format("%s.%s $w%d,0", b[2], d[2], v[1]) end, {31}, 16, "+msa")
	end
end

-- ---- splice into the SoT ---------------------------------------------------
local region = "    // SPECGEN:BEGIN\n" .. table.concat(sections, "\n") .. "\n    // SPECGEN:END"
local fh = assert(io.open(TABLE, "r")); local src = fh:read("*a"); fh:close()
local new, n = src:gsub("    // SPECGEN:BEGIN.-    // SPECGEN:END", (region:gsub("%%", "%%%%")))
if n ~= 1 then io.stderr:write("FATAL: expected one SPECGEN region, found "..n.."\n"); os.exit(1) end
local wh = assert(io.open(TABLE, "w")); wh:write(new); wh:close()
io.write(string.format("specgen(mips): wrote %d forms\n", n_forms))
if #skips > 0 then io.write("  skipped "..#skips.." form(s): "..table.concat(skips, " ").."\n") end
