#!/usr/bin/env luajit
-- rexcode  ·  Brendan Punsky (dotbmp@github), original author
--
-- Encode-form spec generator (arm64). Expands compact per-instruction specs
-- into ENCODING_TABLE entries, deriving `bits` from llvm-mc (the oracle) and
-- `mask` empirically: assemble each form with operand registers at 0 and at 31;
-- the differing bits are operand-driven, so mask = ~(bits0 ^ bits31). Per-form
-- assembly makes it robust: an arrangement llvm-mc rejects (e.g. SQADD .1D) is
-- reported and skipped, never misaligned.
--
-- The generated entries replace the SPECGEN:BEGIN..SPECGEN:END region of
-- encoding_table.odin in place (the hand-written core is left untouched). Every
-- bit pattern is therefore reproducible and llvm-mc-backed.
--
-- Adding a family: pick a SHAPE (operand layout) and list {enum, llvm} pairs.
--
--   Run: luajit tablegen/specgen.lua   (from arm64/, or with a full path)

local bit  = require("bit")
local LLVM = "llvm-mc --assemble --arch=aarch64 --show-encoding"
local DIR   = (arg[0]:match("^(.*)/[^/]*$")) or "."
local TABLE = DIR .. "/encoding_table.odin"

-- arrangement token -> { vt = Operand_Type, asm = llvm suffix }
local ARR = {
	["8B"]={vt="V_8B",asm="8b"}, ["16B"]={vt="V_16B",asm="16b"},
	["4H"]={vt="V_4H",asm="4h"}, ["8H"] ={vt="V_8H", asm="8h"},
	["2S"]={vt="V_2S",asm="2s"}, ["4S"] ={vt="V_4S", asm="4s"},
	["1D"]={vt="V_1D",asm="1d"}, ["2D"] ={vt="V_2D", asm="2d"},
}
-- over-specify; llvm-mc decides which arrangements are legal per instruction.
local ALL_ARR = {"8B","16B","4H","8H","2S","4S","2D"}

-- Vector shapes (all operands share one arrangement T). enc lists the register
-- slots, in operand order. The encoder packs each into its 5-bit field.
local SHAPE = {
	THREE_SAME = { nreg=3, enc={"VD","VN","VM"} },  -- Vd.T, Vn.T, Vm.T
	TWO_SAME   = { nreg=2, enc={"VD","VN"} },        -- Vd.T, Vn.T
}

-- Families: { shape, feature, items = {{enum, llvm}, ...} }
local FAMILIES = {
	{ shape="THREE_SAME", feature="NEON", title="Advanced SIMD three-same (integer)", items = {
		{"SHADD","shadd"},  {"UHADD","uhadd"},  {"SHSUB","shsub"},  {"UHSUB","uhsub"},
		{"SRHADD","srhadd"},{"URHADD","urhadd"},
		{"SQADD","sqadd"},  {"UQADD","uqadd"},  {"SQSUB","sqsub"},  {"UQSUB","uqsub"},
		{"SMAX","smax"},    {"UMAX","umax"},    {"SMIN","smin"},    {"UMIN","umin"},
		{"SABD","sabd"},    {"UABD","uabd"},    {"SABA","saba"},    {"UABA","uaba"},
		{"MLA_V","mla"},    {"MLS_V","mls"},
		{"CMGE","cmge"},    {"CMHS","cmhs"},    {"CMTST","cmtst"},
		{"SQDMULH","sqdmulh"}, {"SQRDMULH","sqrdmulh"},
	}},
	{ shape="TWO_SAME", feature="NEON", title="Advanced SIMD two-register misc", items = {
		{"NOT_V","not"},    {"RBIT_V","rbit"},
		{"REV16_V","rev16"},{"REV32_V","rev32"},{"REV64","rev64"},
		{"CLS_V","cls"},    {"CLZ_V","clz"},    {"CNT","cnt"},
		{"URECPE_V","urecpe"}, {"URSQRTE_V","ursqrte"},
	}},
}

local function word(line)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | %s 2>/dev/null", line, LLVM))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b4..b3..b2..b1, 16)
end

local function padded(prefix_tokens, n)
	local t = {}
	for i = 1, 4 do t[i] = prefix_tokens[i] or ".NONE" end
	return "{" .. table.concat(t, ", ") .. "}"
end

local sections, skips, n_forms, n_mnem = {}, {}, 0, 0
for _, fam in ipairs(FAMILIES) do
	local sh = SHAPE[fam.shape]
	local enc_tokens = {}; for i, e in ipairs(sh.enc) do enc_tokens[i] = "."..e end
	local enc_str = padded(enc_tokens, sh.nreg)
	local blocks = {}
	for _, it in ipairs(fam.items) do
		local mnem, llvm = it[1], it[2]
		local rows = {}
		for _, a in ipairs(ALL_ARR) do
			local s = ARR[a].asm
			local function mk(reg)
				local parts = {}; for i = 1, sh.nreg do parts[i] = "v"..reg.."."..s end
				return llvm.." "..table.concat(parts, ", ")
			end
			local w0, w31 = word(mk(0)), word(mk(31))
			if w0 and w31 then
				local mask = bit.band(bit.bnot(bit.bxor(w0, w31)), 0xFFFFFFFF)
				local op_tokens = {}; for i = 1, sh.nreg do op_tokens[i] = "."..ARR[a].vt end
				rows[#rows+1] = string.format("\t\t{.%s, %s, %s, 0x%s, 0x%s, .%s, {}},",
					mnem, padded(op_tokens, sh.nreg), enc_str,
					bit.tohex(w0):upper(), bit.tohex(mask):upper(), fam.feature)
				n_forms = n_forms + 1
			else
				skips[#skips+1] = mnem.." ."..a
			end
		end
		if #rows > 0 then
			blocks[#blocks+1] = string.format("\t.%s = {\n%s\n\t},", mnem, table.concat(rows, "\n"))
			n_mnem = n_mnem + 1
		end
	end
	sections[#sections+1] = string.format("\t// %s.\n%s", fam.title, table.concat(blocks, "\n"))
end

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
	io.write("  skipped "..#skips.." invalid arrangement(s): "..table.concat(skips, ", ").."\n")
end
