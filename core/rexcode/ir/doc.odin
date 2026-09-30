// rexcode  ·  Brendan Punsky (dotbmp@github), original author

/*
# rexcode/ir — the IR API layer

`core:rexcode/ir` is to the intermediate representations (WASM, SPIR-V, LLVM
bitcode, and the LLVM dialects AIR / DXIL) what `core:rexcode/isa` is to the
machine ISAs: the **shared core** every concrete IR package builds on. It holds
the parts that are the same for every IR, and defines the contract each IR
package follows. It implements **no specific IR** — the concrete packages
(`core:rexcode/ir/wasm`, `.../spirv`, `.../llvm`, …) are added separately.

See `docs/ir_design.md` for the full design rationale and the ISA↔IR comparison.

## Why a sibling, not a generalization of `isa`

The ISA API works because every arch follows one *shape contract*
(`Mnemonic` / `Instruction` / `Operand` / `encode` / `decode` / `print`) while
the shared `isa` package carries only the universal bookkeeping. The IR API
keeps that spirit, with three honest concessions where IRs truly diverge:

  1. **A structured module replaces the flat instruction stream.** The unit of
     work is a `Module` (`Module → []Function → []Block → []Operation`), not a
     `[]Instruction`. So `ir` owns the *structural model* (module/function/block/
     operation), where `isa` owns no `Instruction`.

  2. **A first-class type system.** Operations and results reference a
     module-level type table by `Type_Ref`. ISAs bake width into the mnemonic.

  3. **Entity references replace PC-relative labels.** Operands reference SSA
     values / blocks / functions / globals / types by `Id`, resolved
     structurally — there is no instruction-index→byte-offset rewrite. (Object-
     file *symbol* fixups still produce Relocations, defined per-IR.)

Everything else is deliberately ISA-shaped: the leaf `Operation` is
`isa.Instruction` + an optional typed `Result`, `opcode` is a u16 just like
`isa.Mnemonic`, `Operand` is one discriminated value, and the verbs are the same
three. `Dataflow` lets one model host both an implicit value stack (WASM) and
explicit SSA (SPIR-V/LLVM) without baking in either.

## What this package provides (shared)

  * `status.odin` — `Error` / `Error_Code` (shape-identical to `isa.Error`).
  * `refs.odin`   — `Id` / `Ref` / `Ref_Space` / `Symbol_Table` (the label analog).
  * `types.odin`  — `Type` / `Type_Ref` / `Type_Kind` (the type table).
  * `module.odin` — `Module` / `Function` / `Block` / `Operation` / `Operand` /
                    `Result` / `Dataflow` (the structural model).
  * `print.odin`  — token kinds, print options, number-formatting helpers.

## What a concrete IR package provides (the contract)

Each `core:rexcode/ir/<name>` package supplies, mirroring an arch package:

  * `Opcode` — the IR's operation enum (`u16`, `INVALID = 0`), stored in
    `Operation.opcode`. (Analogous to a `Mnemonic`.)
  * A **codec** — the wire format. Two strategies cover the field:
      - *table-driven* (WASM byte/LEB, SPIR-V 32-bit words): a static
        `OPCODE → operand-layout` table, exactly like an ISA `ENCODING_TABLE`.
      - *bitstream* (LLVM bitcode, and thus AIR / DXIL): a block/record/
        abbreviation engine; the operand layout is data-defined, so there is no
        static table. The codec is pluggable behind the verbs below.
  * The three verbs, on a `Module` (vs the ISA verbs' `[]Instruction`):

        encode :: proc(m:    Module,
                       code:  []u8,
                       relocs: ^[dynamic]Relocation,
                       errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool)

        decode :: proc(data: []u8,
                       m:    ^Module,
                       errors: ^[dynamic]Error,
                       allocator := context.allocator) -> (byte_count: u32, ok: bool)

        print  :: proc(m: Module, options := ir.DEFAULT_PRINT_OPTIONS) -> ir.Print_Result
        tprint :: proc(m: Module, options := ir.DEFAULT_PRINT_OPTIONS) -> string

    (`encode`/`decode` deliberately *drop* the ISA verbs' `label_defs` /
    `resolve` / `base_address` — there is no PC-relative resolution pass — and
    take a `Module` rather than an instruction array. That is the whole point of
    the divergence, made explicit rather than left inert.)

  * `Relocation` / `Relocation_Type` — per-IR (the linker fixups for `EXTERNAL`
    references), exactly as each arch owns its `reloc.odin`.
  * Type lowering — how the IR's wire types map to/from `ir.Type`.

A *dialect* (AIR over LLVM, DXIL over LLVM) reuses its base IR's codec wholesale
and adds only the intrinsic/metadata conventions and any container wrapper.
*/
package rexcode_ir
