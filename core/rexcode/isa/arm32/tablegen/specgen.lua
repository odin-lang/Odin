#!/usr/bin/env luajit
-- rexcode  ·  Brendan Punsky (dotbmp@github), original author
--
-- Encode-form spec generator (arm32 / A32 NEON). Expands compact per-family
-- specs into ENCODING_TABLE entries, deriving `bits` from llvm-mc (the oracle)
-- and `mask` empirically: assemble each form all-zero, then one variant per
-- operand field at its max register, and mask = ~(union of the deltas). The
-- data-type suffix (.s8/.u16/.f32/...) selects the U and size bits, so each
-- type is assembled separately and llvm produces the right `bits`.
--
-- Output replaces the SPECGEN:BEGIN..SPECGEN:END region of encoding_table.odin
-- in place; the hand-written core is untouched.
--
--   Run: luajit tablegen/specgen.lua   (from arm32/, or with a full path)

local bit  = require("bit")
local LLVM = "llvm-mc --assemble --triple=armv8a --mattr=+neon,+fullfp16 --show-encoding"
local DIR   = (arg[0]:match("^(.*)/[^/]*$")) or "."
local TABLE = DIR .. "/encoding_table.odin"

local function word(line)
	local p = io.popen(string.format("printf '%%s\\n' '%s' | %s 2>/dev/null", line, LLVM))
	local out = p:read("*a"); p:close()
	local b1,b2,b3,b4 = out:match("0x(%x%x),0x(%x%x),0x(%x%x),0x(%x%x)")
	if not b1 then return nil end
	return tonumber(b4..b3..b2..b1, 16)
end
local function mask_of(base, variants)
	local x = 0
	for _, w in ipairs(variants) do x = bit.bor(x, bit.bxor(base, w)) end
	return bit.band(bit.bnot(x), 0xFFFFFFFF)
end

local sections, skips, n_forms, n_mnem = {}, {}, 0, 0

-- Emit a mnemonic block. `forms` is a list of {ops, enc, feat, asm, maxes}:
--   ops/enc  prebuilt "{.A, .B, .C, .NONE}" text
--   asm      function(vals) -> asm string (vals[i] = register number for field i)
--   maxes    list of per-field max register numbers (D up to 31, Q up to 15)
local function block(mnem, forms)
	local rows = {}
	for _, f in ipairs(forms) do
		local zero = {}; for i=1,#f.maxes do zero[i]=0 end
		local b0 = word(f.asm(zero))
		if b0 then
			local vs, ok = {}, true
			for i=1,#f.maxes do
				local v={}; for j=1,#f.maxes do v[j]=0 end; v[i]=f.maxes[i]
				local w=word(f.asm(v)); if w then vs[#vs+1]=w else ok=false end
			end
			if ok then
				rows[#rows+1]=string.format("\t\t{.%s, %s, %s, 0x%s, 0x%s, .%s, .A32, {cond_in_28=false}},",
					mnem, f.ops, f.enc, bit.tohex(b0):upper(), bit.tohex(mask_of(b0,vs)):upper(), f.feat or "NEON")
				n_forms=n_forms+1
			else skips[#skips+1]=mnem end
		else skips[#skips+1]=mnem end
	end
	if #rows>0 then sections[#sections+1]=string.format("\t.%s = {\n%s\n\t},", mnem, table.concat(rows,"\n")); n_mnem=n_mnem+1 end
end

local INT_TYPES = {"s8","s16","s32","u8","u16","u32"}
local SHIFT_TYPES = {"s8","s16","s32","s64","u8","u16","u32","u64"}

-- Build the forms for a family across a type list, given a shape descriptor.
-- shape.ops/enc are text; shape.asm(t, v) builds asm for type t and regs v;
-- shape.maxes is the per-field max list.
local function family(mnem, llvm, types, shape)
	local forms = {}
	for _, t in ipairs(types) do
		forms[#forms+1] = {
			ops = shape.ops, enc = shape.enc, feat = shape.feat,
			maxes = shape.maxes,
			asm = function(v) return shape.asm(llvm, t, v) end,
		}
	end
	block(mnem, forms)
end

-- ---- Three-register long: Qd, Dn, Dm ---------------------------------------
local LONG = {
	ops = "{.QPR, .DPR, .DPR, .NONE}", enc = "{.VD_Q, .VN_D, .VM_D, .NONE}", maxes = {15,31,31},
	asm = function(op,t,v) return string.format("%s.%s q%d, d%d, d%d", op, t, v[1], v[2], v[3]) end,
}
-- ---- Three-register wide: Qd, Qn, Dm ---------------------------------------
local WIDE = {
	ops = "{.QPR, .QPR, .DPR, .NONE}", enc = "{.VD_Q, .VN_Q, .VM_D, .NONE}", maxes = {15,15,31},
	asm = function(op,t,v) return string.format("%s.%s q%d, q%d, d%d", op, t, v[1], v[2], v[3]) end,
}
family("VADDL","vaddl",INT_TYPES,LONG); family("VSUBL","vsubl",INT_TYPES,LONG)
family("VABAL","vabal",INT_TYPES,LONG); family("VABDL","vabdl",INT_TYPES,LONG)
family("VADDW","vaddw",INT_TYPES,WIDE); family("VSUBW","vsubw",INT_TYPES,WIDE)

-- ---- Compare aliases (VCLE/VCLT = VCGE/VCGT with Vn/Vm swapped) -------------
-- Dd, Dn, Dm  ==  VCGE Dd, Dm, Dn  -> enc swaps to {VD, VM, VN}.
local CMP_D = {
	ops = "{.DPR, .DPR, .DPR, .NONE}", enc = "{.VD_D, .VM_D, .VN_D, .NONE}", maxes = {31,31,31},
	asm = function(op,t,v) return string.format("%s.%s d%d, d%d, d%d", op, t, v[1], v[2], v[3]) end,
}
local CMP_Q = {
	ops = "{.QPR, .QPR, .QPR, .NONE}", enc = "{.VD_Q, .VM_Q, .VN_Q, .NONE}", maxes = {15,15,15},
	asm = function(op,t,v) return string.format("%s.%s q%d, q%d, q%d", op, t, v[1], v[2], v[3]) end,
}
local CMP_TYPES = {"s8","s16","s32","u8","u16","u32","f32"}
for _, it in ipairs({{"VCLE","vcle"},{"VCLT","vclt"}}) do
	local forms = {}
	for _, t in ipairs(CMP_TYPES) do
		forms[#forms+1] = {ops=CMP_D.ops, enc=CMP_D.enc, maxes=CMP_D.maxes, asm=function(v) return CMP_D.asm(it[2],t,v) end}
		forms[#forms+1] = {ops=CMP_Q.ops, enc=CMP_Q.enc, maxes=CMP_Q.maxes, asm=function(v) return CMP_Q.asm(it[2],t,v) end}
	end
	block(it[1], forms)
end
-- absolute compare (f32 only)
for _, it in ipairs({{"VACLE","vacle"},{"VACLT","vaclt"}}) do
	block(it[1], {
		{ops=CMP_D.ops, enc=CMP_D.enc, maxes=CMP_D.maxes, asm=function(v) return CMP_D.asm(it[2],"f32",v) end},
		{ops=CMP_Q.ops, enc=CMP_Q.enc, maxes=CMP_Q.maxes, asm=function(v) return CMP_Q.asm(it[2],"f32",v) end},
	})
end

-- ---- Shift by vector (VRSHL/VQRSHL): Dd, Dm, Dn (value, shift) --------------
-- asm Dm -> Vm, asm Dn -> Vn  -> enc {VD, VM, VN}.
local SHL_D = {
	ops = "{.DPR, .DPR, .DPR, .NONE}", enc = "{.VD_D, .VM_D, .VN_D, .NONE}", maxes = {31,31,31},
	asm = function(op,t,v) return string.format("%s.%s d%d, d%d, d%d", op, t, v[1], v[2], v[3]) end,
}
local SHL_Q = {
	ops = "{.QPR, .QPR, .QPR, .NONE}", enc = "{.VD_Q, .VM_Q, .VN_Q, .NONE}", maxes = {15,15,15},
	asm = function(op,t,v) return string.format("%s.%s q%d, q%d, q%d", op, t, v[1], v[2], v[3]) end,
}
for _, it in ipairs({{"VQRSHL","vqrshl"}}) do
	local forms = {}
	for _, t in ipairs(SHIFT_TYPES) do
		forms[#forms+1] = {ops=SHL_D.ops, enc=SHL_D.enc, maxes=SHL_D.maxes, asm=function(v) return SHL_D.asm(it[2],t,v) end}
		forms[#forms+1] = {ops=SHL_Q.ops, enc=SHL_Q.enc, maxes=SHL_Q.maxes, asm=function(v) return SHL_Q.asm(it[2],t,v) end}
	end
	block(it[1], forms)
end

-- ---- splice into the SoT ---------------------------------------------------
local region = "\t// SPECGEN:BEGIN\n" .. table.concat(sections, "\n") .. "\n\t// SPECGEN:END"
local fh = assert(io.open(TABLE, "r")); local src = fh:read("*a"); fh:close()
local new, n = src:gsub("\t// SPECGEN:BEGIN.-\t// SPECGEN:END", (region:gsub("%%", "%%%%")))
if n ~= 1 then io.stderr:write("FATAL: expected one SPECGEN region, found "..n.."\n"); os.exit(1) end
local wh = assert(io.open(TABLE, "w")); wh:write(new); wh:close()
io.write(string.format("specgen(arm32): wrote %d mnemonics / %d forms\n", n_mnem, n_forms))
if #skips > 0 then io.write("  skipped "..#skips.." form(s)\n") end
