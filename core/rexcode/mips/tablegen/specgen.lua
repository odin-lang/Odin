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
local LLVM = "llvm-mc --assemble --triple=mips --mattr=+msa --show-encoding"
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

-- ---- splice into the SoT ---------------------------------------------------
local region = "    // SPECGEN:BEGIN\n" .. table.concat(sections, "\n") .. "\n    // SPECGEN:END"
local fh = assert(io.open(TABLE, "r")); local src = fh:read("*a"); fh:close()
local new, n = src:gsub("    // SPECGEN:BEGIN.-    // SPECGEN:END", (region:gsub("%%", "%%%%")))
if n ~= 1 then io.stderr:write("FATAL: expected one SPECGEN region, found "..n.."\n"); os.exit(1) end
local wh = assert(io.open(TABLE, "w")); wh:write(new); wh:close()
io.write(string.format("specgen(mips): wrote %d forms\n", n_forms))
if #skips > 0 then io.write("  skipped "..#skips.." form(s): "..table.concat(skips, " ").."\n") end
