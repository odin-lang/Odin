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
--   Run: luajit tablegen/specgen.lua   (from arm64/, or with a full path)

local bit  = require("bit")
local LLVM = "llvm-mc --assemble --arch=aarch64 --show-encoding"
local DIR   = (arg[0]:match("^(.*)/[^/]*$")) or "."
local TABLE = DIR .. "/encoding_table.odin"

local ARR = {
	["8B"]={vt="V_8B",asm="8b"}, ["16B"]={vt="V_16B",asm="16b"},
	["4H"]={vt="V_4H",asm="4h"}, ["8H"] ={vt="V_8H", asm="8h"},
	["2S"]={vt="V_2S",asm="2s"}, ["4S"] ={vt="V_4S", asm="4s"},
	["1D"]={vt="V_1D",asm="1d"}, ["2D"] ={vt="V_2D", asm="2d"},
}
-- llvm-mc decides which arrangements are legal per instruction; over-specify and
-- the invalid ones are reported + skipped.
local ALL_ARR = {"8B","16B","4H","8H","2S","4S","2D"}

-- Advanced SIMD THREE_SAME (Vd.T, Vn.T, Vm.T): {enum, llvm}.
local THREE_SAME = {
	{"SHADD","shadd"},  {"UHADD","uhadd"},  {"SHSUB","shsub"},  {"UHSUB","uhsub"},
	{"SRHADD","srhadd"},{"URHADD","urhadd"},
	{"SQADD","sqadd"},  {"UQADD","uqadd"},  {"SQSUB","sqsub"},  {"UQSUB","uqsub"},
	{"SMAX","smax"},    {"UMAX","umax"},    {"SMIN","smin"},    {"UMIN","umin"},
	{"SABD","sabd"},    {"UABD","uabd"},    {"SABA","saba"},    {"UABA","uaba"},
	{"MLA_V","mla"},    {"MLS_V","mls"},
	{"CMGE","cmge"},    {"CMHS","cmhs"},    {"CMTST","cmtst"},
	{"SQDMULH","sqdmulh"}, {"SQRDMULH","sqrdmulh"},
}

local function word(line)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | %s 2>/dev/null", line, LLVM))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b4..b3..b2..b1, 16)
end

local blocks, skips, n_forms = {}, {}, 0
for _, e in ipairs(THREE_SAME) do
	local mnem, llvm = e[1], e[2]
	local rows = {}
	for _, a in ipairs(ALL_ARR) do
		local s = ARR[a].asm
		local w0  = word(string.format("%s v0.%s, v0.%s, v0.%s",    llvm, s, s, s))
		local w31 = word(string.format("%s v31.%s, v31.%s, v31.%s", llvm, s, s, s))
		if w0 and w31 then
			local mask = bit.band(bit.bnot(bit.bxor(w0, w31)), 0xFFFFFFFF)
			local vt = ARR[a].vt
			rows[#rows+1] = string.format(
				"\t\t{.%s, {.%s, .%s, .%s, .NONE}, {.VD, .VN, .VM, .NONE}, 0x%s, 0x%s, .NEON, {}},",
				mnem, vt, vt, vt, bit.tohex(w0):upper(), bit.tohex(mask):upper())
			n_forms = n_forms + 1
		else
			skips[#skips+1] = mnem.." ."..a
		end
	end
	if #rows > 0 then
		blocks[#blocks+1] = string.format("\t.%s = {\n%s\n\t},", mnem, table.concat(rows, "\n"))
	end
end

local region = "\t// SPECGEN:BEGIN\n" ..
	"\t// Advanced SIMD three-same (integer).\n" ..
	table.concat(blocks, "\n") .. "\n\t// SPECGEN:END"

local fh = assert(io.open(TABLE, "r")); local src = fh:read("*a"); fh:close()
local repl = region:gsub("%%", "%%%%")
local new, n = src:gsub("\t// SPECGEN:BEGIN.-\t// SPECGEN:END", repl)
if n ~= 1 then
	io.stderr:write("FATAL: expected exactly one SPECGEN:BEGIN..END region, found "..n.."\n")
	os.exit(1)
end
local wh = assert(io.open(TABLE, "w")); wh:write(new); wh:close()

io.write(string.format("specgen: wrote %d mnemonics / %d forms into %s\n", #blocks, n_forms, TABLE))
if #skips > 0 then
	io.write("  skipped "..#skips.." invalid arrangement(s): "..table.concat(skips, ", ").."\n")
end
