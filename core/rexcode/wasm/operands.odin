// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// WebAssembly OPERANDS
// =============================================================================
//
// WASM operands are not registers or addressing modes; they are *immediates*
// that follow the opcode in the byte stream:
//
//   i32.const 42          IMMEDIATE   immediate = 42                (signed LEB128)
//   f64.const 3.14        IMMEDIATE   immediate = bits(3.14)        (8 LE bytes)
//   local.get 0           INDEX       index = 0, idx_kind = LOCAL   (unsigned LEB128)
//   call $f               INDEX       index = funcidx, idx_kind = FUNC
//   br 1                  INDEX       index = 1, idx_kind = LABEL   (branch depth)
//   i32.load align=2 off=8 MEMARG     memarg = {align = 2, offset = 8}
//   block (result i32)    BLOCK_TYPE  block_type = .I32
//
// Branching in WASM is *structured*: `br`/`br_if`/`br_table` take a relative
// label depth (an unsigned immediate), not a PC-relative byte offset. There
// are therefore no PC-relative relocations and the isa label-inference path is
// not used; the array-index `Label_Definition` machinery is re-exported for
// contract parity but WASM control flow does not consume it.
//
// Relocations *are* real, but for the object-file index spaces (function /
// global / table / type / data / elem indices that a linker fixes up). An
// INDEX operand flagged `symbolic` carries a label id and is emitted as a
// fixed-width 5-byte LEB placeholder plus a Relocation entry. `op_label`
// (required by the contract) produces exactly such a symbolic function index.

Operand_Kind :: enum u8 {
	NONE,
	IMMEDIATE,   // i32/i64/f32/f64 constant (floats stored as raw bits)
	INDEX,       // LEB128 unsigned index into one of the index spaces
	MEMARG,      // load/store alignment + offset pair
	BLOCK_TYPE,  // block / loop / if signature
}

// Which index space an INDEX operand addresses. Drives matching, relocation
// type selection, and printer annotation.
Index_Kind :: enum u8 {
	NONE,
	LOCAL,
	GLOBAL,
	FUNC,
	TYPE,
	TABLE,
	MEMORY,
	LABEL,    // br / br_if / br_table relative depth
	DATA,
	ELEM,
}

Operand_Flags :: bit_field u8 {
	symbolic: bool | 1,   // INDEX value is a label id needing a relocation
	is_float: bool | 1,   // IMMEDIATE holds float bits (vs a signed integer)
	_:        u8   | 6,
}

// Load/store immediate: alignment hint (log2 bytes) + static offset.
Memarg :: struct #packed {
	offset: u32,
	align:  u32,
}
#assert(size_of(Memarg) == 8)

// Block signature. Negative sentinels are the s33 single-byte forms; a
// non-negative value is a type index encoded as a positive signed LEB128.
Block_Type :: enum i64 {
	EMPTY     = -64,   // 0x40
	I32       = -1,    // 0x7F
	I64       = -2,    // 0x7E
	F32       = -3,    // 0x7D
	F64       = -4,    // 0x7C
	V128      = -5,    // 0x7B
	FUNCREF   = -16,   // 0x70
	EXTERNREF = -17,   // 0x6F
}

Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register,   // REGISTER (vestigial)
		memarg:    Memarg,     // MEMARG
		immediate: i64,        // IMMEDIATE (int value or float bits) / BLOCK_TYPE (s33)
		index:     u32,        // INDEX (value, or label id when symbolic)
	},
	kind:     Operand_Kind,
	idx_kind: Index_Kind,
	size:     u8,             // value width in bytes where meaningful (4/8)
	flags:    Operand_Flags,
}
#assert(size_of(Operand) == 12)

// -----------------------------------------------------------------------------
// Generic constructors (contract surface)
// -----------------------------------------------------------------------------

@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64, size: u8) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}

@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memarg, size: u8 = 0) -> Operand {
	return Operand{memarg = m, kind = .MEMARG, size = size}
}

// Symbolic function reference: emitted as a relocatable funcidx placeholder.
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 5) -> Operand {
	return Operand{index = label_id, kind = .INDEX, idx_kind = .FUNC, size = size, flags = {symbolic = true}}
}

// -----------------------------------------------------------------------------
// Numeric constants
// -----------------------------------------------------------------------------

@(require_results)
op_i32 :: #force_inline proc "contextless" (v: i32) -> Operand {
	return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 4}
}
@(require_results)
op_i64 :: #force_inline proc "contextless" (v: i64) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = 8}
}
@(require_results)
op_f32 :: #force_inline proc "contextless" (v: f32) -> Operand {
	return Operand{immediate = i64(transmute(u32)v), kind = .IMMEDIATE, size = 4, flags = {is_float = true}}
}
@(require_results)
op_f64 :: #force_inline proc "contextless" (v: f64) -> Operand {
	return Operand{immediate = transmute(i64)v, kind = .IMMEDIATE, size = 8, flags = {is_float = true}}
}

// -----------------------------------------------------------------------------
// Memory argument + block type
// -----------------------------------------------------------------------------

@(require_results)
memarg :: #force_inline proc "contextless" (align, offset: u32) -> Memarg {
	return Memarg{align = align, offset = offset}
}
@(require_results)
op_memarg :: #force_inline proc "contextless" (align, offset: u32) -> Operand {
	return Operand{memarg = Memarg{align = align, offset = offset}, kind = .MEMARG}
}

@(require_results)
op_blocktype :: #force_inline proc "contextless" (bt: Block_Type) -> Operand {
	return Operand{immediate = i64(bt), kind = .BLOCK_TYPE}
}
@(require_results)
op_block_typeidx :: #force_inline proc "contextless" (type_index: u32) -> Operand {
	return Operand{immediate = i64(type_index), kind = .BLOCK_TYPE}
}

// -----------------------------------------------------------------------------
// Index-space constructors (one per space; all unsigned LEB128 on the wire)
// -----------------------------------------------------------------------------

@(require_results)
op_index :: #force_inline proc "contextless" (kind: Index_Kind, value: u32) -> Operand {
	return Operand{index = value, kind = .INDEX, idx_kind = kind}
}

@(require_results) op_local  :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.LOCAL,  n) }
@(require_results) op_global :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.GLOBAL, n) }
@(require_results) op_func   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.FUNC,   n) }
@(require_results) op_type   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.TYPE,   n) }
@(require_results) op_table  :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.TABLE,  n) }
@(require_results) op_memory :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.MEMORY, n) }
@(require_results) op_data   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.DATA,   n) }
@(require_results) op_elem   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_index(.ELEM,   n) }

// Branch label depth (number of enclosing blocks to break out of).
@(require_results) op_labelidx :: #force_inline proc "contextless" (depth: u32) -> Operand { return op_index(.LABEL, depth) }

// ref.null heap type (encoded as a single value-type byte).
@(require_results)
op_reftype :: #force_inline proc "contextless" (t: Value_Type) -> Operand {
	return Operand{immediate = i64(t), kind = .IMMEDIATE, size = 1}
}

// SIMD lane index (single byte) for extract_lane / replace_lane / load_lane /
// store_lane operators.
@(require_results)
op_lane :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{immediate = i64(n), kind = .IMMEDIATE, size = 1}
}
