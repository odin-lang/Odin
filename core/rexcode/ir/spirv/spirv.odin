// rexcode  ·  Brendan Punsky (dotbmp@github), original author

// rexcode/ir/spirv -- the SPIR-V intermediate representation.
//
// SPIR-V is the Khronos binary IR for shaders and compute kernels: a stream of
// 32-bit words, each instruction headed by a `wordCount<<16 | opcode` word, over
// an SSA value model with a first-class type system (OpTypeInt, OpConstant,
// OpFunction, ...). On the two axes that sort the IR family (docs/ir_design.md
// §2) it is **table-driven** on encoding -- a static `opcode -> operand-layout`
// grammar, exactly the ISA `ENCODING_TABLE` shape -- and **SSA** on dataflow,
// like LLVM and unlike WASM.
//
// So this package is built as a sibling of the ISA arch packages: it re-exports
// the shared `ir` vocabulary (Module / Function / Block / Operation / Operand /
// Type / Id / ...), owns a `u16` `Opcode` (the SPIR-V opcode values), a static
// operand-layout table that drives a word-level codec, the three Module-based
// verbs (`encode` / `decode` / `print`), a `Relocation` for linkage fixups, and
// the SPIR-V <-> `ir.Type` lowering. No PC-relative label pass exists; operands
// reference entities (results, types, functions) by `Id`, resolved structurally.
package rexcode_spirv

import "core:rexcode/ir"

// =============================================================================
// SECTION: Re-exported shared vocabulary (the IR naming contract, ir_design §4)
// =============================================================================
//
// A consumer sees one namespace -- `spirv.Operation`, `spirv.Type`, ... -- the
// way an arch package re-exports `isa`. These are the IR's leaf model; the
// concrete additions (Opcode, Relocation, the codec) live in the sibling files.

// `Module` is NOT re-exported -- SPIR-V's module carries dialect sections the
// shared core has no slot for (capabilities, entry points, decorations, ...), so
// it is a superset struct embedding `ir.Module`; see module.odin.
Function      :: ir.Function
Block         :: ir.Block
Global        :: ir.Global
Operation     :: ir.Operation
Operation_Flags :: ir.Operation_Flags
Operand       :: ir.Operand
Operand_Kind  :: ir.Operand_Kind
Result        :: ir.Result
Type          :: ir.Type
Type_Ref      :: ir.Type_Ref
Type_Kind     :: ir.Type_Kind
Id            :: ir.Id
Ref           :: ir.Ref
Ref_Space     :: ir.Ref_Space
Symbol_Table  :: ir.Symbol_Table
Dataflow      :: ir.Dataflow
Error         :: ir.Error
Error_Code    :: ir.Error_Code
Token         :: ir.Token
Token_Kind    :: ir.Token_Kind
Print_Options :: ir.Print_Options
Print_Result  :: ir.Print_Result

ID_NONE   :: ir.ID_NONE
TYPE_NONE :: ir.TYPE_NONE
DEFAULT_PRINT_OPTIONS :: ir.DEFAULT_PRINT_OPTIONS

// Operand / type / ref constructors (shared; SSA makes them uniform).
op_int    :: ir.op_int
op_float  :: ir.op_float
op_type   :: ir.op_type
op_ref    :: ir.op_ref
op_value  :: ir.op_value
op_block  :: ir.op_block
operand_id   :: ir.operand_id
operand_type :: ir.operand_type
ref          :: ir.ref

type_void    :: ir.type_void
type_int     :: ir.type_int
type_float   :: ir.type_float
type_vector  :: ir.type_vector
type_pointer :: ir.type_pointer

// =============================================================================
// SECTION: Physical format  (SPIR-V spec §2.3 -- the 32-bit word stream)
// =============================================================================

// SPIR-V is a stream of 32-bit words in the module's declared endianness.
Word :: u32

// The first word of every module.
MAGIC :: u32(0x0723_0203)

// Version word layout: 0x00 <major> <minor> 0x00.
@(require_results)
version :: #force_inline proc "contextless" (major, minor: u8) -> u32 {
	return (u32(major) << 16) | (u32(minor) << 8)
}

VERSION_1_0 :: u32(0x0001_0000)
VERSION_1_1 :: u32(0x0001_0100)
VERSION_1_2 :: u32(0x0001_0200)
VERSION_1_3 :: u32(0x0001_0300)
VERSION_1_4 :: u32(0x0001_0400)
VERSION_1_5 :: u32(0x0001_0500)
VERSION_1_6 :: u32(0x0001_0600)

// Generator's magic number, registered in the SPIR-V Registry. 0 = unregistered.
GENERATOR :: u32(0)

// The 5-word module header that precedes the instruction stream.
Header :: struct {
	magic:     u32,   // == MAGIC
	version:   u32,   // see version()
	generator: u32,
	bound:     u32,   // exclusive upper bound on every <id> (i.e. max id + 1)
	schema:    u32,   // reserved; 0
}
#assert(size_of(Header) == 20)

HEADER_WORDS :: 5

// An instruction's first word packs its total word count (including this word)
// in the high 16 bits and the opcode in the low 16.
@(require_results) inst_word_count :: #force_inline proc "contextless" (w: u32) -> u32 { return w >> 16 }
@(require_results) inst_opcode     :: #force_inline proc "contextless" (w: u32) -> u16 { return u16(w & 0xFFFF) }
@(require_results) inst_head       :: #force_inline proc "contextless" (word_count: u32, opcode: Opcode) -> u32 {
	return (word_count << 16) | u32(u16(opcode))
}
