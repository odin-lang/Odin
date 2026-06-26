// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "core:rexcode/ir"

// =============================================================================
// SECTION: Module  (the SPIR-V module -- ir core + SPIR-V's own sections)
// =============================================================================
//
// `spirv.Module` is the `ir.Module` SSA core (types / globals / functions /
// symbols, dataflow = .SSA) plus the SPIR-V module-level sections the shared core
// has no slot for. A concrete IR carries those "alongside the core" per
// docs/ir_design.md §3; here that is literal -- `using base: ir.Module` embeds
// the core so `m.types`, `m.functions`, ... read straight through.
//
// SPIR-V is a *flat* stream of OpXxx, each defining an <id>. `decode` lowers it
// into this structure -- OpTypeXxx -> base.types, OpVariable(global) ->
// base.globals, OpFunction -> base.functions, OpConstant* -> the constant pool,
// and the preamble / debug / annotations -> the sections below -- and `encode`
// flattens it back in the spec's required section order.
Module :: struct {
	using base: ir.Module,    // types, globals, functions, symbols, dataflow, target

	// --- Header ---
	version:   u32,           // see version(); a default is supplied on encode if 0
	generator: u32,           // GENERATOR if 0
	bound:     u32,           // exclusive upper bound on every <id>; recomputed on encode

	// --- Preamble (in spec section order) ---
	capabilities: []Capability,
	extensions:   []string,
	ext_imports:  []Ext_Import,
	addressing:   Addressing_Model,
	memory:       Memory_Model,
	entry_points: []Entry_Point,
	exec_modes:   []Exec_Mode,

	// --- Constant pool ---
	// SPIR-V constants are module-level value definitions, each a result <id>
	// referenced like any other value (an op_value / .CONSTANT ref).
	constants: []Constant,

	// --- Debug + annotations ---
	debug:       Debug,
	decorations: []Decoration_Inst,

	// --- <id> side tables ---
	// SPIR-V has one flat <id> space (types, constants, globals, functions, and
	// SSA results all draw from it), but ir.Type/Global/Function carry no id of
	// their own. These parallel the ir core arrays and hold each entity's wire
	// <id>, so decode->encode preserves them. (Results carry their own id in
	// Result.id / Constant.result.id; only these three need a side table.)
	type_ids:     []Id,   // parallel to base.types
	global_ids:   []Id,   // parallel to base.globals
	function_ids: []Id,   // parallel to base.functions
}

// Member index sentinel: a whole-target decoration / name (OpDecorate / OpName)
// rather than a struct member one (OpMemberDecorate / OpMemberName).
MEMBER_NONE :: u32(0xFFFF_FFFF)

// -----------------------------------------------------------------------------
// Section element types
// -----------------------------------------------------------------------------

// OpExtInstImport: an extended instruction set, e.g. "GLSL.std.450".
Ext_Import :: struct {
	result: Id,
	name:   string,
}

// OpEntryPoint: an execution entry into the module.
Entry_Point :: struct {
	model:     Execution_Model,
	function:  Id,
	name:      string,
	interface: []Id,    // the OpVariable <id>s forming the entry's interface
}

// OpExecutionMode / OpExecutionModeId: a mode set on an entry point.
Exec_Mode :: struct {
	entry:    Id,
	mode:     Execution_Mode,
	operands: []u32,    // literal operands (e.g. LocalSize x, y, z)
	is_id:    bool,     // OpExecutionModeId: `operands` are <id>s, not literals
}

// A module-level constant: OpConstant / OpConstant{True,False,Null} / OpConstantComposite.
Constant :: struct {
	result:   Result,   // <id> + type
	opcode:   Opcode,   // which OpConstant* form produced it
	value:    u64,      // scalar bit pattern (OpConstant); width comes from the type
	elements: []Id,     // OpConstantComposite member <id>s
}

// OpDecorate / OpMemberDecorate: an annotation on an <id> (or one of its members).
Decoration_Inst :: struct {
	target:     Id,
	decoration: Decoration,
	member:     u32,      // OpMemberDecorate member index; MEMBER_NONE for OpDecorate
	operands:   []u32,    // decoration literal operands (Location = N, Binding = N, ...)
}

// The debug section.
Debug :: struct {
	source_language: u32,
	source_version:  u32,
	source_file:     Id,      // an OpString <id>, or ID_NONE
	names:           []Name,  // OpName / OpMemberName
	strings:         []Str,   // OpString
}

// OpName / OpMemberName.
Name :: struct {
	target: Id,
	member: u32,      // OpMemberName member index; MEMBER_NONE for OpName
	text:   string,
}

// OpString.
Str :: struct {
	result: Id,
	text:   string,
}

// SPIR-V is always SSA; a freshly-made module declares it so the shared verbs
// and printer pick the SSA path.
@(require_results)
make_module :: proc "contextless" () -> Module {
	m: Module
	m.base.dataflow = .SSA
	m.version       = VERSION_1_5
	m.addressing    = .Logical
	m.memory        = .GLSL450
	return m
}
