// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ir

// =============================================================================
// TYPE MODEL
// =============================================================================
//
// The second genuine divergence from the ISA API: IRs have a *first-class type
// system*. An ISA bakes width into the mnemonic (`ADD` vs `ADDB`); operands are
// just bit patterns. An IR carries an explicit type table and operations /
// results reference types by `Type_Ref` (an index into `Module.types`).
//
// `Type_Kind` is the common denominator across the modelled IRs:
//   * WASM:   i32/i64/f32/f64/v128 + funcref/externref  (a *degenerate* table --
//             a handful of primitives, no user structs).
//   * SPIR-V: OpTypeInt / Float / Vector / Pointer / Struct / Function / ...
//   * LLVM:   iN / float / pointer / vector / array / struct / function / opaque.
//
// A concrete IR lowers its wire types onto this set on decode and back on
// encode. Anything a dialect needs beyond the common shape rides in `aux` (e.g.
// pointer address space) or in the concrete IR's own side tables.

Type_Ref :: distinct u32

TYPE_NONE :: Type_Ref(0xFFFFFFFF)

Type_Kind :: enum u8 {
	VOID,
	BOOL,       // a distinct boolean (SPIR-V OpTypeBool, LLVM i1)
	INT,        // `bits` = width (1/8/16/32/64/...); signedness is op-level in most IRs
	FLOAT,      // `bits` = width (16/32/64/128)
	VECTOR,     // `elem` x `count`   (fixed-width SIMD)
	ARRAY,      // `elem` x `count` (literal length) or `elem` x `len_ref` (<id> length)
	POINTER,    // `elem`, address space in `aux`
	STRUCT,     // members in `fields`
	FUNCTION,   // `fields` = params ++ [result]; `count` = param count
	OPAQUE,     // named / forward-declared / abstract handle (images, tokens, ...)
	REF,        // funcref / externref / typed GC reference (`elem` for typed refs)
}

// One node in a module's type table. `fields` (struct members / function
// signature) is caller-owned, like the rest of the decoded module.
Type :: struct {
	fields:  []Type_Ref,   // STRUCT members, or FUNCTION params ++ result
	name:    string,       // OPAQUE / named struct
	elem:    Type_Ref,     // VECTOR / ARRAY / POINTER / typed REF element
	count:   u32,          // VECTOR length, literal ARRAY length, or FUNCTION param count
	len_ref: Id,           // ARRAY length as a constant <id> (id-typed lengths, e.g. SPIR-V)
	bits:    u16,          // INT / FLOAT width
	aux:     u16,          // POINTER address space, packed kind flags, ...
	kind:    Type_Kind,
	_:       [3]u8,
}

@(require_results) type_void  :: #force_inline proc "contextless" ()          -> Type { return Type{kind = .VOID} }
@(require_results) type_bool  :: #force_inline proc "contextless" ()          -> Type { return Type{kind = .BOOL} }
@(require_results) type_int   :: #force_inline proc "contextless" (bits: u16) -> Type { return Type{kind = .INT,   bits = bits} }
@(require_results) type_float :: #force_inline proc "contextless" (bits: u16) -> Type { return Type{kind = .FLOAT, bits = bits} }

@(require_results)
type_array :: #force_inline proc "contextless" (elem: Type_Ref, len_ref: Id) -> Type {
	return Type{kind = .ARRAY, elem = elem, len_ref = len_ref}
}

@(require_results)
type_vector :: #force_inline proc "contextless" (elem: Type_Ref, count: u32) -> Type {
	return Type{kind = .VECTOR, elem = elem, count = count}
}

@(require_results)
type_pointer :: #force_inline proc "contextless" (elem: Type_Ref, address_space: u16 = 0) -> Type {
	return Type{kind = .POINTER, elem = elem, aux = address_space}
}
