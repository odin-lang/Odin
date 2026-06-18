// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "core:rexcode/isa"

// =============================================================================
// WebAssembly ENCODING FUNDAMENTALS
// =============================================================================
//
// An instruction is:  [prefix?] opcode  immediate*
//
//   * `prefix`  is 0 for the single-byte core opcodes, or one of 0xFC (misc),
//     0xFD (SIMD), 0xFE (threads). When present, the *sub*-opcode that
//     follows is an unsigned LEB128 (so SIMD's 0..275 fit).
//   * Integer immediates use LEB128 (unsigned for indices/alignment, signed
//     for i32.const/i64.const and the s33 blocktype).
//   * Float constants are raw little-endian IEEE-754 (4 or 8 bytes).
//
// There is at most one encoding form per mnemonic, so dispatch is a direct
// `ENCODING_TABLE[mnemonic]` lookup (O(1)) rather than the operand-shape
// scan the variable-form arches (x86) need. The immediate layout is described
// declaratively by `imm: [2]Imm_Kind`, walked in order by the encoder and
// decoder.

Error            :: isa.Error
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED

// Relocation / Relocation_Type live in reloc.odin (per-arch by design).

// Opcode-space prefix bytes.
PREFIX_NONE :: u8(0x00)
PREFIX_MISC :: u8(0xFC)   // saturating truncation, bulk memory/table
PREFIX_SIMD :: u8(0xFD)   // vector (v128)
PREFIX_ATOM :: u8(0xFE)   // threads / atomics

Encoding_Flags :: bit_field u8 {
	control: bool | 1,   // structured control flow (block/loop/if/else/end/br*)
	memory:  bool | 1,   // touches linear memory
	_:       u8   | 6,
}

// How one immediate field is laid down after the opcode.
Imm_Kind :: enum u8 {
	NONE,
	BLOCKTYPE,    // signed LEB128 s33 (negative valtype byte, or type index)
	I32,          // signed LEB128 (i32.const)
	I64,          // signed LEB128 (i64.const)
	F32,          // 4 little-endian bytes
	F64,          // 8 little-endian bytes
	IDX,          // unsigned LEB128 index (space comes from the operand)
	MEMARG,       // unsigned LEB128 align, then unsigned LEB128 offset
	REFTYPE,      // single value-type byte (ref.null)
	BR_TABLE,     // unsigned LEB128 count, that many label depths, default depth
	ZERO_BYTE,    // a single reserved 0x00 byte (memidx placeholders)
	LANE,         // single byte lane index (SIMD extract/replace/load/store lane)
	LANES16,      // sixteen raw bytes (v128.const value / i8x16.shuffle mask), from Instruction.bytes
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,       // 2 -- redundant w/ table index, kept for parity
	prefix:   u8,             // 1 -- PREFIX_NONE / PREFIX_MISC / PREFIX_SIMD / PREFIX_ATOM
	opcode:   u16,            // 2 -- primary opcode, or sub-opcode within a prefix group (SIMD reaches 0x113)
	imm:      [2]Imm_Kind,    // 2 -- immediate layout, walked in order
	flags:    Encoding_Flags, // 1
	inputs:   i8,             // 1 -- stack operands consumed (the arity in);  -1 when it varies
	outputs:  i8,             // 1 -- stack results produced  (the arity out); -1 when it varies
}
#assert(size_of(Encoding) == 10)

// `inputs`/`outputs` give the fixed stack arity of an instruction: how many
// values it pops and how many it pushes. They are -1 when the count is not a
// constant of the opcode -- i.e. it depends on a type/blocktype immediate or on
// the surrounding control frame. That covers `call`/`call_indirect` (the callee
// or referenced signature), the structured control ops `block`/`loop`/`if`
// (their blocktype) plus `else`/`end`, the branches `br`/`br_if`/`br_table` and
// `return` (the target/result types, and stack-polymorphism), and the
// stack-polymorphic `unreachable`. Everything else is a fixed (inputs, outputs).

// =============================================================================
// LEB128 + little-endian primitives (shared by encoder and decoder)
// =============================================================================

// Unsigned LEB128. Advances `*offset`. Caller guarantees buffer space.
write_uleb :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: u64) {
	v := value
	for {
		b := u8(v & 0x7F)
		v >>= 7
		if v != 0 {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
		if v == 0 {
			break
		}
	}
}

// Signed LEB128. Advances `*offset`.
write_sleb :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: i64) {
	v := value
	for {
		b := u8(v & 0x7F)
		v >>= 7 // arithmetic shift on signed value sign-extends
		done := (v == 0 && (b & 0x40) == 0) || (v == -1 && (b & 0x40) != 0)
		if !done {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
		if done {
			break
		}
	}
}

// Fixed 5-byte unsigned LEB128 (relocatable placeholder for 32-bit indices).
write_uleb_padded5 :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: u64) {
	v := value
	for i := 0; i < 5 && offset^ < u32(len(code)); i += 1 {
		b := u8(v & 0x7F)
		v >>= 7
		if i != 4 {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
	}
}

uleb_size :: #force_inline proc "contextless" (value: u64) -> u32 {
	v := value
	n: u32 = 1
	for /**/; v >= 0x80; n += 1 {
		v >>= 7
	}
	return n
}

sleb_size :: #force_inline proc "contextless" (value: i64) -> u32 {
	v := value
	n: u32 = 0
	for {
		b := u8(v & 0x7F)
		v >>= 7
		n += 1
		if (v == 0 && (b & 0x40) == 0) || (v == -1 && (b & 0x40) != 0) {
			break
		}
	}
	return n
}

// Read unsigned LEB128 starting at `*offset`; advances it. `ok` is false on
// truncation. Reads at most `max` bytes (10 covers u64).
@(require_results)
read_uleb :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (value: u64, ok: bool) {
	shift: uint = 0
	for i := 0; i < 10 && offset^ < u32(len(data)); i += 1 {
		b := data[offset^]
		offset^ += 1
		value |= u64(b & 0x7F) << shift
		if b & 0x80 == 0 {
			return value, true
		}
		shift += 7
	}
	return 0, false
}

// Read signed LEB128 starting at `*offset`; advances it.
@(require_results)
read_sleb :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (value: i64, ok: bool) {
	shift: uint = 0
	b: u8 = 0
	for i := 0; i < 10 && offset^ < u32(len(data)); i += 1 {
		b = data[offset^]
		offset^ += 1
		value |= i64(b & 0x7F) << shift
		shift += 7
		if b & 0x80 == 0 {
			break
		}
	}
	if shift < 64 && (b & 0x40) != 0 {
		value |= -(i64(1) << shift)
	}
	ok = true
	return
}

write_u32_block :: #force_inline proc(code: []u8, offset: ^u32, v: u32) {
	assert(offset^+ 4 <= u32(len(code)))
	code[offset^+0] = u8(v)
	code[offset^+1] = u8(v >> 8)
	code[offset^+2] = u8(v >> 16)
	code[offset^+3] = u8(v >> 24)
	offset^ += 4
}

write_u64_block :: #force_inline proc(code: []u8, offset: ^u32, v: u64) {
	assert(offset^+ 8 <= u32(len(code)))
	for i in u32(0)..<8 {
		code[offset^+i] = u8(v >> (8 * i))
	}
	offset^ += 8
}

@(require_results)
read_u32_block :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (u32, bool) {
	if offset^ + 4 > u32(len(data)) {
		return 0, false
	}
	v := u32(data[offset^+0])     |
	     u32(data[offset^+1])<<8  |
	     u32(data[offset^+2])<<16 |
	     u32(data[offset^+3])<<24
	offset^ += 4
	return v, true
}

@(require_results)
read_u64_block :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (u64, bool) {
	if offset^ + 8 > u32(len(data)) {
		return 0, false
	}
	v: u64 = 0
	for i in u32(0)..<8 {
		v |= u64(data[offset^+i]) << (8 * i)
	}
	offset^ += 8
	return v, true
}
