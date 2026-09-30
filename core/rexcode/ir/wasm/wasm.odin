// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

// rexcode/ir/wasm -- the WebAssembly intermediate representation.
//
// WASM is a stack bytecode: a byte stream with LEB128 immediates, one encoding
// form per opcode, over an *implicit value stack* with a minimal type system.
// On the two axes that sort the IR family (docs/ir_design.md §2) it is
// **table-driven** on encoding -- a static `opcode -> operand-layout` table,
// exactly the ISA `ENCODING_TABLE` shape -- and **STACK** on dataflow (the one
// outlier among the modelled IRs; SPIR-V/LLVM are SSA).
//
// So this package is a sibling of the SPIR-V package under `ir/`: it re-exports
// the shared `ir` vocabulary (Module / Function / Block / Operation / Operand /
// Type / Id / ...), owns a `u16` `Opcode` (the WASM opcode set, with the 0xFC/
// 0xFD/0xFE prefix groups folded in), a static `ENCODING_TABLE` that drives a
// byte/LEB codec, the three Module-based verbs (`encode` / `decode` / `print`),
// a `Relocation` for object-file index fixups, and the WASM value-type model.
//
// This is the migration anticipated by docs/ir_design.md §4: WASM was shaped as
// an ISA arch package (`core:rexcode/wasm`); its real `encode`/`decode` already
// dropped the ISA verbs' `label_defs`/`resolve`/`base_address` (WASM has no
// PC-relative pass -- branches carry structured label depths), so moving it onto
// the `ir` Module/Operation/Operand model is a change of *leaf shape*, not of
// codec. The table-driven codec below is carried over intact; what changed is
// the leaf (`ir.Operation` in place of the old fixed-operand `Instruction`), the
// operand model (`ir.Operand`, with WASM memarg/blocktype/lane riding in `aux`),
// and the unit of work (an `ir.Module` of functions->blocks->operations).
package rexcode_wasm

import "core:rexcode/ir"

// =============================================================================
// SECTION: Re-exported shared vocabulary (the IR naming contract, ir_design §4)
// =============================================================================
//
// A consumer sees one namespace -- `wasm.Operation`, `wasm.Operand`, ... -- the
// way an arch package re-exports `isa`. `Module` is NOT re-exported: WASM's
// module carries container sections (types / imports / exports / ...) the shared
// core has no slot for, so it is a superset struct embedding `ir.Module`; see
// module.odin (exactly as `spirv.Module` does).

Function        :: ir.Function
Block           :: ir.Block
Global          :: ir.Global
Operation       :: ir.Operation
Operation_Flags :: ir.Operation_Flags
Operand         :: ir.Operand
Operand_Kind    :: ir.Operand_Kind
Result          :: ir.Result
Type            :: ir.Type
Type_Ref        :: ir.Type_Ref
Type_Kind       :: ir.Type_Kind
Id              :: ir.Id
Ref             :: ir.Ref
Ref_Space       :: ir.Ref_Space
Symbol_Table    :: ir.Symbol_Table
Dataflow        :: ir.Dataflow
Error           :: ir.Error
Error_Code      :: ir.Error_Code
Token           :: ir.Token
Token_Kind      :: ir.Token_Kind
Print_Options   :: ir.Print_Options
Print_Result    :: ir.Print_Result

ID_NONE   :: ir.ID_NONE
TYPE_NONE :: ir.TYPE_NONE
DEFAULT_PRINT_OPTIONS :: ir.DEFAULT_PRINT_OPTIONS

print_hex     :: ir.print_hex
print_decimal :: ir.print_decimal

// Shared operand / type / ref constructors (WASM adds the dialect helpers -- a
// memarg, a blocktype, a lane index -- in operands.odin).
op_int       :: ir.op_int
op_float     :: ir.op_float
op_type      :: ir.op_type
op_ref       :: ir.op_ref
op_value     :: ir.op_value
op_block     :: ir.op_block
operand_id   :: ir.operand_id
operand_type :: ir.operand_type
ref          :: ir.ref

type_void    :: ir.type_void
type_int     :: ir.type_int
type_float   :: ir.type_float
type_vector  :: ir.type_vector
type_pointer :: ir.type_pointer

symbol_table_init    :: ir.symbol_table_init
symbol_table_destroy :: ir.symbol_table_destroy
symbol_define        :: ir.symbol_define
symbol_reserve       :: ir.symbol_reserve
symbol_lookup        :: ir.symbol_lookup

// =============================================================================
// SECTION: Physical format  (WebAssembly core spec §5 -- the byte stream)
// =============================================================================

// The four bytes that begin every module: "\0asm" as a little-endian u32.
WASM_MAGIC   :: u32(0x6d73_6100)
WASM_VERSION :: u32(1)

// Opcode-space prefix bytes. A prefixed opcode is `prefix byte` then an unsigned
// LEB128 sub-opcode (SIMD reaches 0x113, so the sub-opcode can be two bytes).
PREFIX_NONE :: u8(0x00)
PREFIX_MISC :: u8(0xFC)   // saturating truncation, bulk memory / table
PREFIX_SIMD :: u8(0xFD)   // vector (v128)
PREFIX_ATOM :: u8(0xFE)   // threads / atomics
