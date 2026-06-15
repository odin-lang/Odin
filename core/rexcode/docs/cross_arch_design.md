<!-- rexcode  ·  Brendan Punsky (dotbmp@github), original author -->

# rexcode — Cross-Architecture Design

> Why the rexcode family (`x86`, `arm32`, `arm64`, `mips`, `riscv`, `ppc`,
> `ppc_vle`, `rsp`, `mos6502`, `mos65816`) shares one shape **without**
> flattening every ISA to a lowest common denominator and **without** adding
> runtime overhead to the single-target hot path.

---

## The guiding principle

> **Share the bookkeeping, specialize the bytes.**

An encoder/decoder is two things stitched together:

1. **Orchestration & bookkeeping** — labels, relocations, the two-pass
   encode/decode loops, error/result reporting, the print framework, and the
   table-gen tooling pattern. This is *the same problem on every ISA*.
2. **The instruction model & the bytes** — what a register/memory/operand
   *is*, what the encoding tables look like, and the actual bit/byte-twiddling
   of `encode_one`/`decode_one`. This is *irreducibly per-architecture* and
   must stay native and zero-cost.

We do **not** invent one `Instruction` type that fits all ISAs — that path
forces x86's `segment`/SIB, ARM's writeback, and RISC-V's split immediates into
one bloated struct. Instead each arch owns its concrete types, and uniformity
comes from a **naming contract** (§4) plus a small **shared core** (§3).

---

## 1. The universal shape

Strip away the specifics and every target needs the same nine things:

| # | Concept | x86 example |
|---|---|---|
| 1 | A **register** = (class, hw number, size) | `Register` distinct u16 |
| 2 | **Operands** tagged reg / mem / imm / relative | `Operand` + `Operand_Kind` |
| 3 | An **instruction** = mnemonic + operands + flags | `Instruction` |
| 4 | A **mnemonic** enum | `Mnemonic` (u16, INVALID=0) |
| 5 | **Labels** + forward refs + named labels | `Label_Definition`, `Label_Map` |
| 6 | **Relocations** left over after local resolution | `Relocation` |
| 7 | `encode([]Inst) -> bytes (+relocs +errors)` | `encode()` |
| 8 | `decode(bytes) -> []Inst (+info +labels +errors)` | `decode()` |
| 9 | `print([]Inst) -> text (+tokens)` | `print()`/`tprint()`/… |

The *shape* of items 5–9 (their signatures and the types they pass around) is
architecture-independent. That is the surface the naming contract standardizes.

---

## 2. Where architectures actually diverge

Ranked from "diverges hardest" to "barely diverges":

- **Encoding mechanics — maximal.** x86 is 1–15 B variable (prefixes → REX/VEX/
  EVEX → escape → opcode → ModRM → SIB → disp → imm); RISC-V/ARM64/MIPS/PPC are
  fixed 4 B bitfield packs; the 6502/65816 are 1–N B opcode + operand bytes.
  `encode_one`/`decode_one` and the `Encoding` schema do **not** generalize.
- **Memory addressing — high.** x86 `[base+index*scale+disp32]` + segment +
  addr-size; RISC-V `disp12(base)`; MIPS `imm16(base)`; ARM adds writeback and
  extend/shift. `Memory` is per-arch; only the *role* (a `MEMORY`-kind operand
  carrying an arch-defined payload) generalizes.
- **Immediates / operand size — moderate.** The *value* (`i64`) generalizes; the
  *encoding* (split B/J immediates, bitmask-imm) lives inside `encode_one`. x86
  carries an explicit `size`; RISC-V/ARM bake width into the mnemonic.
- **Relocations — moderate, structurally aligned.** The `Relocation` struct
  (offset, label, addend, type, size) mirrors ELF `rela` and is universal in
  *shape*; the **type enum** is per-arch (larger on RISC-V/PPC for paired
  PC-relative forms).
- **Registers — low/structural.** The `(class, hw_number)`-packed `distinct u16`
  scheme + `reg_hw`/`reg_class` accessors generalize; classes, enums, names, and
  extension semantics (REX/EVEX, ARM's SP/XZR #31) are per-arch.
- **Mnemonics — content differs, shape identical.** Per-arch `enum u16`,
  `INVALID=0`.
- **Labels — no divergence.** Pure bookkeeping; lives in `isa/`.
- **Errors / Result — low.** `Result`/`Error` shapes universal; `Error_Code`
  has a shared core plus arch-specific extras.
- **Printer — framework universal, formatting per-arch.** Tokens, options, and
  the output sinks are shared; `register_name`/`print_memory`/mnemonic
  formatting are per-arch.

### Divergence summary

| Component | Verdict | Shared | Per-arch |
|---|---|---|---|
| Labels | ✅ shared | everything | — |
| Result / Error struct | ✅ shared | struct shapes | error-code extras |
| Printer framework | ◑ split | tokens, options, sinks, num-fmt | reg/mem/mnemonic formatting |
| Relocation | ◑ split | struct shape (convention) | type enum (per-arch file) |
| Register scheme | ◑ split | layout + `reg_hw`/`reg_class` convention | classes, enums, names, ext bits |
| Operand model | ◑ split | kind tag + `size` carrier convention | `Memory`, `flags` payloads |
| `Instruction` | ✗ per-arch | shape convention only | concrete struct |
| `Mnemonic` | ✗ per-arch | convention (u16, INVALID=0) | the enum |
| `Encoding` + tables | ✗ per-arch | codegen *pattern* (§5) | schema + data |
| `encode`/`decode` driver | ✗ per-arch | — | the whole loop |
| `encode_one`/`decode_one` | ✗ per-arch | nothing | all of it |
| Memory addressing | ✗ per-arch | operand *role* | the model |

---

## 3. The shared core (`isa/`) and why nothing else is shared

`isa/` depends on nothing and owns only the parts that are byte-for-byte the
same problem on every ISA:

- `labels.odin` — `Label`, `Label_Definition`, `Label_Map`, resolution
  (parametric over the Instruction type, so it works for any arch unchanged).
- `label_infer.odin` — branch-target → label inference used by `decode`.
- `status.odin` — `Result`, `Error`, the shared `Error_Code` core.
- `print.odin` — `Token`/`Token_Kind`, `Print_Options`, the output sinks, and
  the number-formatting helpers.

Each arch package **re-exports** these (e.g. `x86.Result`, `x86.Label_Map`) so a
consumer sees one coherent namespace and never imports `isa` directly unless
writing arch-generic tooling.

Everything else is deliberately **per-arch**, even where it looks shareable:
registers, the memory model, operands, mnemonics, the `Encoding`/table schema,
the `Relocation` type enum, and — notably — the `encode`/`decode` **driver
loops**. The drivers were left native rather than factored behind a generic hook
because they diverge too much to share cleanly (x86's ~500-line prefix/ModRM/SIB
body vs a fixed-width arch's dozen-line bitfield packer), and the hot path must
not pay for indirection.

### Three unifications we deliberately rejected

1. **One universal `Operand`/`Memory`.** Would force x86 SIB+segment, ARM
   writeback+extend, and RISC-V's nothing into one struct — bloats every operand
   and still can't represent ARM writeback cleanly.
2. **A runtime `interface`/vtable called per instruction.** Adds an indirect
   call to the hottest loop (x86 does ~17 M inst/s) and defeats inlining.
3. **An `any`/tagged-union `Instruction` through a generic `encode`.** Same
   monomorphization loss + runtime type checks in the hot loop.

---

## 4. The naming contract

Every architecture package exposes these names with these signatures. This is
what makes the family feel like one library and what each new ISA is built
against as a checklist.

**Types (concrete per arch, identical names):**
`Register  Memory  Operand  Operand_Kind  Instruction  Mnemonic  Encoding
Instruction_Info`

**Re-exported shared types (from `isa`):**
`Label  Label_Definition  Label_Map  LABEL_UNDEFINED  Relocation
Relocation_Type  Error  Error_Code  Result  Token  Token_Kind  Print_Options
DEFAULT_PRINT_OPTIONS`

**Operand constructors:** `op_reg(r)  op_mem(m, size)  op_imm(v, size)
op_label(id, size)`, an arch-specific `mem_*` set (at minimum `mem_base_disp`),
and `op_<class>(typed)` where the arch has typed register classes.

**Instruction builders & emitters** (operand-kind suffixes spelled out):
`inst_none / inst_r / inst_r_r / inst_r_i / inst_r_m / inst_m_r / …` and
`emit_none / emit_r / emit_rr / emit_ri / …` (concatenated suffixes). x86 also
ships generated typed overloads `inst_<mnemonic>` / `emit_<mnemonic>`; other
arches may add them.

**Entry points (identical signatures across arches):**

```odin
encode(instructions: []Instruction, label_defs: []Label_Definition,
       code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error,
       resolve := true, base_address: u64 = 0) -> Result

decode(data: []u8, relocs: []Relocation,
       instructions: ^[dynamic]Instruction, inst_info: ^[dynamic]Instruction_Info,
       label_defs: ^[dynamic]Label_Definition, errors: ^[dynamic]Error) -> Result

print/println/aprint/tprint/bprint/fprint/wprint(+ln)(
    instructions: []Instruction, inst_info: []Instruction_Info,
    label_defs: []Label_Definition, tokens=nil, options=nil, label_names=nil)
```

**Register/label/print helpers:** `reg_hw  reg_class  reg_size  register_name
mnemonic_to_string  label  label_forward  label_named  label_reserve
label_set`.

> Anything an arch genuinely lacks (e.g. RISC-V has no `mem_base_index`) is
> simply **absent**, not stubbed. Source-portable code stays within the
> intersection; arch-aware code uses the extras.

---

## 5. Tables

The `Encoding` schema and the tables are per-arch, but the table **pipeline** is
a shared pattern. Each arch's hand-written `ENCODING_TABLE` (the single source of
truth) lives in `<arch>/tablegen/`, a two-stage metaprogram flattens it and emits
committed binary blobs, and the library `#load`s them into `@(rodata)` — no table
is compiled into the library. See [table_migration.md](table_migration.md).

---

## 6. One-paragraph summary

Make `isa` own the parts that are the same on every ISA — labels, errors/result,
and the print framework. Make each arch package own its registers, memory model,
operands, mnemonics, encoding tables, and the actual `encode_one`/`decode_one`
bytes. Bind the family together with a strict **naming contract** so packages are
drop-in swappable at source level with zero runtime cost. x86 keeps every cycle
of its performance; each new ISA gets the boring shared vocabulary for free and
writes only the part that is genuinely its own.
