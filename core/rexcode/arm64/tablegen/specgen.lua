#!/usr/bin/env luajit
-- rexcode  ·  Brendan Punsky (dotbmp@github), original author
--
-- Encode-form spec generator (arm64). Expands compact per-instruction specs
-- into ENCODING_TABLE entries, deriving `bits` from llvm-mc (the oracle) and
-- `mask` empirically: assemble each form with operand registers at 0 and at 31;
-- the differing bits are operand-driven, so mask = ~(bits0 ^ bits31). Per-form
-- assembly makes it robust: an arrangement llvm-mc rejects is reported, skipped.
--
-- Output replaces the SPECGEN:BEGIN..SPECGEN:END region of encoding_table.odin
-- in place; the hand-written core is untouched. Every bit pattern is therefore
-- reproducible and llvm-mc-backed.
--
-- Two spec kinds:
--   * uniform — every operand shares one arrangement T (iterate ALL_ARR).
--   * diff    — operands have different arrangements (long/wide/narrow/XTN);
--               each item lists the arrangement TUPLE per size-variant.
--
--   Run: luajit tablegen/specgen.lua   (from arm64/, or with a full path)

local bit  = require("bit")
local LLVM = "llvm-mc --assemble --arch=aarch64 --mattr=+fullfp16 --show-encoding"
local DIR   = (arg[0]:match("^(.*)/[^/]*$")) or "."
local TABLE = DIR .. "/encoding_table.odin"

local ARR = {
	["8B"]={vt="V_8B",asm="8b"}, ["16B"]={vt="V_16B",asm="16b"},
	["4H"]={vt="V_4H",asm="4h"}, ["8H"] ={vt="V_8H", asm="8h"},
	["2S"]={vt="V_2S",asm="2s"}, ["4S"] ={vt="V_4S", asm="4s"},
	["1D"]={vt="V_1D",asm="1d"}, ["2D"] ={vt="V_2D", asm="2d"},
	-- half-precision FP arrangements (distinct operand type + FP16 feature)
	["4HF"]={vt="V_4H_FP16",asm="4h",feat="FP16"}, ["8HF"]={vt="V_8H_FP16",asm="8h",feat="FP16"},
}
local ALL_ARR = {"8B","16B","4H","8H","2S","4S","2D"}

-- scalar SIMD register destinations (across-lanes reductions): token -> reg
local SCAL = { B={vt="B_REG",asm="b"}, H={vt="H_REG",asm="h"}, S={vt="S_REG",asm="s"}, D={vt="D_REG",asm="d"} }
-- a tuple token is either a vector arrangement (in ARR) or a scalar size (in SCAL)
local function tok_asm(t, r) if ARR[t] then return "v"..r.."."..ARR[t].asm else return SCAL[t].asm..r end end
local function tok_vt(t)     if ARR[t] then return ARR[t].vt      else return SCAL[t].vt end end

local function word(line)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | %s 2>/dev/null", line, LLVM))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b4..b3..b2..b1, 16)
end

local function padded(tokens, n)
	local t = {}
	for i = 1, 4 do t[i] = tokens[i] or ".NONE" end
	return "{" .. table.concat(t, ", ") .. "}"
end

local sections, skips, n_forms, n_mnem = {}, {}, 0, 0

-- Emit one mnemonic's block from a list of arrangement tuples (operand order).
-- enc_str is the prebuilt "{.VD, .VN, .VM, .NONE}" enc array text.
local function emit(mnem, llvm, enc_str, feature, variants)
	local rows = {}
	for _, tup in ipairs(variants) do
		local function mk(r)
			local parts = {}
			for i, t in ipairs(tup) do parts[i] = tok_asm(t, r) end
			return llvm.." "..table.concat(parts, ", ")
		end
		local w0, w31 = word(mk(0)), word(mk(31))
		if w0 and w31 then
			local mask = bit.band(bit.bnot(bit.bxor(w0, w31)), 0xFFFFFFFF)
			local ops = {}
			for i, t in ipairs(tup) do ops[i] = "."..tok_vt(t) end
			local f = feature
			for _, tk in ipairs(tup) do if ARR[tk] and ARR[tk].feat then f = ARR[tk].feat end end
			rows[#rows+1] = string.format("\t\t{.%s, %s, %s, 0x%s, 0x%s, .%s, {}},",
				mnem, padded(ops, #tup), enc_str, bit.tohex(w0):upper(), bit.tohex(mask):upper(), f)
			n_forms = n_forms + 1
		else
			skips[#skips+1] = mnem.." "..table.concat(tup, "/")
		end
	end
	if #rows == 0 then return nil end
	n_mnem = n_mnem + 1
	return string.format("\t.%s = {\n%s\n\t},", mnem, table.concat(rows, "\n"))
end

-- ---- Uniform shapes (all operands share one arrangement) -------------------
local VD_VN_VM = padded({".VD",".VN",".VM"}, 3)
local VD_VN    = padded({".VD",".VN"}, 2)

local UNIFORM = {
	{ title="three-same (integer)", enc=VD_VN_VM, nreg=3, items={
		{"SHADD","shadd"},{"UHADD","uhadd"},{"SHSUB","shsub"},{"UHSUB","uhsub"},
		{"SRHADD","srhadd"},{"URHADD","urhadd"},
		{"SQADD","sqadd"},{"UQADD","uqadd"},{"SQSUB","sqsub"},{"UQSUB","uqsub"},
		{"SMAX","smax"},{"UMAX","umax"},{"SMIN","smin"},{"UMIN","umin"},
		{"SABD","sabd"},{"UABD","uabd"},{"SABA","saba"},{"UABA","uaba"},
		{"MLA_V","mla"},{"MLS_V","mls"},
		{"CMGE","cmge"},{"CMHS","cmhs"},{"CMTST","cmtst"},
		{"SQDMULH","sqdmulh"},{"SQRDMULH","sqrdmulh"},
		{"ADDP_V","addp"},{"SMAXP","smaxp"},{"SMINP","sminp"},{"UMAXP","umaxp"},{"UMINP","uminp"},
		{"SSHL","sshl"},{"USHL","ushl"},{"SRSHL","srshl"},{"URSHL","urshl"},
	}},
	{ title="two-register misc", enc=VD_VN, nreg=2, items={
		{"NOT_V","not"},{"RBIT_V","rbit"},
		{"REV16_V","rev16"},{"REV32_V","rev32"},{"REV64","rev64"},
		{"CLS_V","cls"},{"CLZ_V","clz"},{"CNT","cnt"},
		{"URECPE_V","urecpe"},{"URSQRTE_V","ursqrte"},
	}},
	{ title="floating-point three-same", enc=VD_VN_VM, nreg=3, arr={"2S","4S","2D","4HF","8HF"}, items={
		{"FMAX_V","fmax"},{"FMIN_V","fmin"},{"FMAXNM_V","fmaxnm"},{"FMINNM_V","fminnm"},
		{"FMULX","fmulx"},{"FRECPS","frecps"},{"FRSQRTS","frsqrts"},
		{"FACGE","facge"},{"FACGT","facgt"},
		{"FCMEQ","fcmeq"},{"FCMGE","fcmge"},{"FCMGT","fcmgt"},
		{"FADDP_V","faddp"},{"FMAXP_V","fmaxp"},{"FMINP_V","fminp"},
		{"FMAXNMP","fmaxnmp"},{"FMINNMP","fminnmp"},
	}},
	{ title="floating-point two-register", enc=VD_VN, nreg=2, arr={"2S","4S","2D","4HF","8HF"}, items={
		{"FABS_V","fabs"},{"FNEG_V","fneg"},{"FSQRT_V","fsqrt"},
		{"FRINTA_V","frinta"},{"FRINTI_V","frinti"},{"FRINTM_V","frintm"},{"FRINTN_V","frintn"},
		{"FRINTP_V","frintp"},{"FRINTX_V","frintx"},{"FRINTZ_V","frintz"},
		{"FRECPE","frecpe"},{"FRSQRTE","frsqrte"},
	}},
}
for _, fam in ipairs(UNIFORM) do
	local blk = {}
	for _, it in ipairs(fam.items) do
		local variants = {}
		for _, a in ipairs(fam.arr or ALL_ARR) do
			local tup = {}; for i = 1, fam.nreg do tup[i] = a end
			variants[#variants+1] = tup
		end
		local b = emit(it[1], it[2], fam.enc, "NEON", variants)
		if b then blk[#blk+1] = b end
	end
	sections[#sections+1] = "\t// Advanced SIMD "..fam.title..".\n" .. table.concat(blk, "\n")
end

-- ---- Mixed-arrangement shapes (long / wide / narrow / XTN) ------------------
-- arrangement tuples per size-variant (operand order: dst, n, [m]). Base
-- mnemonics take the low-half source, the "2" variants the high half.
local LONG_LO = {{"8H","8B","8B"},{"4S","4H","4H"},{"2D","2S","2S"}}
local LONG_HI = {{"8H","16B","16B"},{"4S","8H","8H"},{"2D","4S","4S"}}
local WIDE_LO = {{"8H","8H","8B"},{"4S","4S","4H"},{"2D","2D","2S"}}
local WIDE_HI = {{"8H","8H","16B"},{"4S","4S","8H"},{"2D","2D","4S"}}
local NARR_LO = {{"8B","8H","8H"},{"4H","4S","4S"},{"2S","2D","2D"}}
local NARR_HI = {{"16B","8H","8H"},{"8H","4S","4S"},{"4S","2D","2D"}}
local XTN_LO  = {{"8B","8H"},{"4H","4S"},{"2S","2D"}}
local XTN_HI  = {{"16B","8H"},{"8H","4S"},{"4S","2D"}}
-- pairwise-long: Vd.<wide>, Vn.<narrow> (half the lanes, double the element size)
local PLONG   = {{"4H","8B"},{"8H","16B"},{"2S","4H"},{"4S","8H"},{"1D","2S"},{"2D","4S"}}
-- across-lanes: scalar dst of the element size, Vn.<T>
local ACROSS  = {{"B","8B"},{"B","16B"},{"H","4H"},{"H","8H"},{"S","4S"}}
-- across-lanes long: scalar dst of 2x the element size, Vn.<T>
local ACROSSL = {{"H","8B"},{"H","16B"},{"S","4H"},{"S","8H"},{"D","4S"}}
-- FP across-lanes: scalar dst (S for .4S, H for the FP16 forms), Vn.<T>
local ACROSSF = {{"S","4S"},{"H","4HF"},{"H","8HF"}}

local DIFF = {
	{ title="three-different (long)", enc=VD_VN_VM, items={
		{"SADDL","saddl",LONG_LO},{"SADDL2","saddl2",LONG_HI},
		{"UADDL","uaddl",LONG_LO},{"UADDL2","uaddl2",LONG_HI},
		{"SSUBL","ssubl",LONG_LO},{"SSUBL2","ssubl2",LONG_HI},
		{"USUBL","usubl",LONG_LO},{"USUBL2","usubl2",LONG_HI},
		{"SMULL_V","smull",LONG_LO},{"SMULL2_V","smull2",LONG_HI},
		{"UMULL_V","umull",LONG_LO},{"UMULL2_V","umull2",LONG_HI},
		{"SMLAL","smlal",LONG_LO},{"SMLAL2","smlal2",LONG_HI},
		{"UMLAL","umlal",LONG_LO},{"UMLAL2","umlal2",LONG_HI},
		{"SMLSL","smlsl",LONG_LO},{"SMLSL2","smlsl2",LONG_HI},
		{"UMLSL","umlsl",LONG_LO},{"UMLSL2","umlsl2",LONG_HI},
		{"SQDMULL","sqdmull",LONG_LO},{"SQDMULL2","sqdmull2",LONG_HI},
		{"SQDMLAL","sqdmlal",LONG_LO},{"SQDMLAL2","sqdmlal2",LONG_HI},
		{"SQDMLSL","sqdmlsl",LONG_LO},{"SQDMLSL2","sqdmlsl2",LONG_HI},
	}},
	{ title="three-different (wide)", enc=VD_VN_VM, items={
		{"SADDW","saddw",WIDE_LO},{"SADDW2","saddw2",WIDE_HI},
		{"UADDW","uaddw",WIDE_LO},{"UADDW2","uaddw2",WIDE_HI},
		{"SSUBW","ssubw",WIDE_LO},{"SSUBW2","ssubw2",WIDE_HI},
		{"USUBW","usubw",WIDE_LO},{"USUBW2","usubw2",WIDE_HI},
	}},
	{ title="three-different (narrow, halving)", enc=VD_VN_VM, items={
		{"ADDHN","addhn",NARR_LO},{"ADDHN2","addhn2",NARR_HI},
		{"SUBHN","subhn",NARR_LO},{"SUBHN2","subhn2",NARR_HI},
		{"RADDHN","raddhn",NARR_LO},{"RADDHN2","raddhn2",NARR_HI},
		{"RSUBHN","rsubhn",NARR_LO},{"RSUBHN2","rsubhn2",NARR_HI},
	}},
	{ title="two-register narrowing (XTN)", enc=VD_VN, items={
		{"XTN","xtn",XTN_LO},{"XTN2","xtn2",XTN_HI},
		{"SQXTN","sqxtn",XTN_LO},{"SQXTN2","sqxtn2",XTN_HI},
		{"UQXTN","uqxtn",XTN_LO},{"UQXTN2","uqxtn2",XTN_HI},
		{"SQXTUN","sqxtun",XTN_LO},{"SQXTUN2","sqxtun2",XTN_HI},
	}},
	{ title="two-register pairwise long", enc=VD_VN, items={
		{"SADDLP","saddlp",PLONG},{"UADDLP","uaddlp",PLONG},
		{"SADALP","sadalp",PLONG},{"UADALP","uadalp",PLONG},
	}},
	{ title="across lanes", enc=VD_VN, items={
		{"ADDV","addv",ACROSS},{"SMAXV","smaxv",ACROSS},{"SMINV","sminv",ACROSS},
		{"UMAXV","umaxv",ACROSS},{"UMINV","uminv",ACROSS},
		{"SADDLV","saddlv",ACROSSL},{"UADDLV","uaddlv",ACROSSL},
	}},
	{ title="floating-point across lanes", enc=VD_VN, items={
		{"FMAXV_V","fmaxv",ACROSSF},{"FMINV_V","fminv",ACROSSF},
		{"FMAXNMV","fmaxnmv",ACROSSF},{"FMINNMV","fminnmv",ACROSSF},
	}},
}
for _, fam in ipairs(DIFF) do
	local blk = {}
	for _, it in ipairs(fam.items) do
		local b = emit(it[1], it[2], fam.enc, "NEON", it[3])
		if b then blk[#blk+1] = b end
	end
	sections[#sections+1] = "\t// Advanced SIMD "..fam.title..".\n" .. table.concat(blk, "\n")
end

-- ---- splice into the SoT ---------------------------------------------------
local region = "\t// SPECGEN:BEGIN\n" .. table.concat(sections, "\n\n") .. "\n\t// SPECGEN:END"
local fh = assert(io.open(TABLE, "r")); local src = fh:read("*a"); fh:close()
local new, n = src:gsub("\t// SPECGEN:BEGIN.-\t// SPECGEN:END", (region:gsub("%%", "%%%%")))
if n ~= 1 then
	io.stderr:write("FATAL: expected exactly one SPECGEN:BEGIN..END region, found "..n.."\n")
	os.exit(1)
end
local wh = assert(io.open(TABLE, "w")); wh:write(new); wh:close()

io.write(string.format("specgen: wrote %d mnemonics / %d forms into %s\n", n_mnem, n_forms, TABLE))
if #skips > 0 then
	io.write("  skipped "..#skips.." invalid arrangement(s)\n")
end
