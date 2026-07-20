// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// SECTION: Operands  (WASM immediates expressed as ir.Operand)
// =============================================================================
//
// The old ISA-shaped WASM package had its own `Operand` (a #raw_union of
// immediate / index / memarg / blocktype). Under the IR contract the operand
// model is *shared* -- `ir.Operand` is one discriminated value (LIT_INT /
// LIT_FLOAT / REF / TYPE / ATTRIBUTE) -- and a dialect's structured immediates
// "ride in `aux` + the IR's opcode table" (docs/ir_design.md §2). So WASM maps
// its immediates onto `ir.Operand` like this:
//
//   i32.const / i64.const value   -> LIT_INT       (op_int)
//   f32.const / f64.const         -> LIT_FLOAT     (op_float, aux = width)
//   an index (local/func/...)     -> REF           (op_wasm_index; space is the
//                                                    best-fit ir.Ref_Space, and
//                                                    the exact WASM Index_Kind is
//                                                    kept in `aux`, losslessly)
//   a branch label depth          -> REF (.BLOCK)  (op_labelidx)
//   a blocktype (s33)             -> ATTRIBUTE     (op_blocktype)
//   a memarg (align, offset)      -> ATTRIBUTE     (op_memarg; both packed in imm)
//   a ref.null heap type          -> ATTRIBUTE     (op_reftype)
//   a SIMD lane index             -> ATTRIBUTE     (op_lane)
//   a v128 literal / shuffle mask -> two ATTRIBUTE (op_v128 -> lo, hi halves)
//
// Nothing needs an inline byte blob: the one 16-byte immediate (v128.const,
// i8x16.shuffle) is carried as two 64-bit ATTRIBUTE halves. `br_table`'s label
// vector is not a special field either -- with `ir.Operation.operands` now being
// variable-arity, it is just `[default, case0, case1, ...]`, every entry a BLOCK
// ref (see builder.odin / the encoder's BR_TABLE case).

// Which WASM index space an index immediate addresses. Drives the on-wire
// encoding, relocation-type selection, and printer annotation. Kept in
// `ir.Operand.aux` for every REF operand so the exact space always round-trips,
// even where the shared `ir.Ref_Space` has no dedicated member (TABLE/DATA/ELEM).
Index_Kind :: enum u16 {
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

// The `ir.Operand.aux` tag for the ATTRIBUTE-kind WASM immediates. (REF operands
// instead put an `Index_Kind` in `aux`; the opcode's ENCODING_TABLE form always
// says which of the two an operand slot is, so the two uses never collide.)
Attr :: enum u16 {
	NONE,
	BLOCKTYPE,
	MEMARG,
	REFTYPE,
	LANE,
	V128_LO,   // low 8 bytes of a v128 literal / shuffle mask
	V128_HI,   // high 8 bytes
}

// `ir.Operand.flags` bit: a REF whose index is a symbol id the linker fixes up
// (emitted as a fixed-width 5-byte LEB placeholder plus a Relocation).
FLAG_SYMBOLIC :: u32(1)

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

// -----------------------------------------------------------------------------
// Index_Kind <-> ir.Ref_Space
// -----------------------------------------------------------------------------

// Best-fit shared space for a WASM index space (used for printer annotation and
// generic ir tooling). The exact `Index_Kind` still lives in `aux`, so spaces
// the shared enum lacks (TABLE/DATA/ELEM) map to NONE here without loss.
@(require_results)
ref_space_for :: #force_inline proc "contextless" (k: Index_Kind) -> Ref_Space {
	switch k {
	case .LOCAL:  return .VALUE   // a local / value-stack slot (ir_design: VALUE)
	case .GLOBAL: return .GLOBAL
	case .FUNC:   return .FUNCTION
	case .TYPE:   return .TYPE
	case .MEMORY: return .MEMORY
	case .LABEL:  return .BLOCK
	case .TABLE, .DATA, .ELEM: return .NONE
	case .NONE:   return .NONE
	}
	return .NONE
}

// -----------------------------------------------------------------------------
// Numeric constants
// -----------------------------------------------------------------------------

@(require_results) op_i32 :: #force_inline proc "contextless" (v: i32) -> Operand { return op_int(i64(v)) }
@(require_results) op_i64 :: #force_inline proc "contextless" (v: i64) -> Operand { return op_int(v) }
@(require_results) op_f32 :: #force_inline proc "contextless" (v: f32) -> Operand { return op_float(u64(transmute(u32)v), 32) }
@(require_results) op_f64 :: #force_inline proc "contextless" (v: f64) -> Operand { return op_float(transmute(u64)v, 64) }

// -----------------------------------------------------------------------------
// Index-space constructors (one per space; all unsigned LEB128 on the wire)
// -----------------------------------------------------------------------------

@(require_results)
op_wasm_index :: #force_inline proc "contextless" (kind: Index_Kind, value: u32, symbolic := false) -> Operand {
	o := op_ref(ref_space_for(kind), Id(value))
	o.aux = u16(kind)
	if symbolic { o.flags |= FLAG_SYMBOLIC }
	return o
}

@(require_results) op_local  :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.LOCAL,  n) }
@(require_results) op_global :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.GLOBAL, n) }
@(require_results) op_func   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.FUNC,   n) }
@(require_results) op_typeidx:: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.TYPE,   n) }
@(require_results) op_table  :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.TABLE,  n) }
@(require_results) op_memory :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.MEMORY, n) }
@(require_results) op_data   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.DATA,   n) }
@(require_results) op_elem   :: #force_inline proc "contextless" (n: u32) -> Operand { return op_wasm_index(.ELEM,   n) }

// Branch label depth (number of enclosing blocks to break out of).
@(require_results) op_labelidx :: #force_inline proc "contextless" (depth: u32) -> Operand { return op_wasm_index(.LABEL, depth) }

// Symbolic function reference: emitted as a relocatable funcidx placeholder.
@(require_results) op_label :: #force_inline proc "contextless" (label_id: u32) -> Operand { return op_wasm_index(.FUNC, label_id, symbolic = true) }

// -----------------------------------------------------------------------------
// Dialect ATTRIBUTE immediates
// -----------------------------------------------------------------------------

@(require_results)
memarg :: #force_inline proc "contextless" (align, offset: u32) -> Memarg {
	return Memarg{align = align, offset = offset}
}

@(require_results)
op_memarg :: #force_inline proc "contextless" (ma: Memarg) -> Operand {
	packed := i64(u64(ma.offset) | (u64(ma.align) << 32))
	return Operand{kind = .ATTRIBUTE, imm = packed, aux = u16(Attr.MEMARG)}
}

@(require_results)
op_blocktype :: #force_inline proc "contextless" (bt: Block_Type) -> Operand {
	return Operand{kind = .ATTRIBUTE, imm = i64(bt), aux = u16(Attr.BLOCKTYPE)}
}

@(require_results)
op_block_typeidx :: #force_inline proc "contextless" (type_index: u32) -> Operand {
	return Operand{kind = .ATTRIBUTE, imm = i64(type_index), aux = u16(Attr.BLOCKTYPE)}
}

@(require_results)
op_reftype :: #force_inline proc "contextless" (t: Value_Type) -> Operand {
	return Operand{kind = .ATTRIBUTE, imm = i64(t), aux = u16(Attr.REFTYPE)}
}

@(require_results)
op_lane :: #force_inline proc "contextless" (n: u8) -> Operand {
	return Operand{kind = .ATTRIBUTE, imm = i64(n), aux = u16(Attr.LANE)}
}

// A 16-byte v128 literal (v128.const) or shuffle mask (i8x16.shuffle), as two
// little-endian 64-bit ATTRIBUTE halves.
@(require_results)
op_v128 :: #force_inline proc "contextless" (bytes: [16]u8) -> (lo, hi: Operand) {
	l, h: u64
	for i in 0..<8 { l |= u64(bytes[i + 0]) << u64(i * 8) }
	for i in 0..<8 { h |= u64(bytes[i + 8]) << u64(i * 8) }
	lo = Operand{kind = .ATTRIBUTE, imm = i64(l), aux = u16(Attr.V128_LO)}
	hi = Operand{kind = .ATTRIBUTE, imm = i64(h), aux = u16(Attr.V128_HI)}
	return
}

// -----------------------------------------------------------------------------
// Accessors (reconstruct the WASM payload carried by an ir.Operand)
// -----------------------------------------------------------------------------

@(require_results) operand_index      :: #force_inline proc "contextless" (o: Operand) -> u32        { return u32(o.imm) }
@(require_results) operand_index_kind :: #force_inline proc "contextless" (o: Operand) -> Index_Kind { return Index_Kind(o.aux) }
@(require_results) operand_symbolic   :: #force_inline proc "contextless" (o: Operand) -> bool       { return o.flags & FLAG_SYMBOLIC != 0 }
@(require_results) operand_attr       :: #force_inline proc "contextless" (o: Operand) -> Attr       { return Attr(o.aux) }

@(require_results)
operand_memarg :: #force_inline proc "contextless" (o: Operand) -> Memarg {
	u := u64(o.imm)
	return Memarg{offset = u32(u), align = u32(u >> 32)}
}

// v128 bytes from a lo/hi ATTRIBUTE pair.
@(require_results)
operand_v128 :: #force_inline proc "contextless" (lo, hi: Operand) -> (bytes: [16]u8) {
	l, h := u64(lo.imm), u64(hi.imm)
	for i in 0..<8 { bytes[i + 0] = u8(l >> u64(i * 8)) }
	for i in 0..<8 { bytes[i + 8] = u8(h >> u64(i * 8)) }
	return
}
