# rexcode — Cross-Architecture API Design

> How to grow rexcode from an x86-only encoder/decoder into a multi-target
> library (x86, RISC-V, ARM64, MIPS, …) **without** flattening every
> architecture to a lowest common denominator and **without** adding
> runtime overhead to the single-target hot path.
>
> Companion to [x86_api.md](x86_api.md). Written ahead of the RISC-V
> subpackage.

---

## 0. The guiding principle

> **Share the bookkeeping, specialize the bytes.**

An encoder/decoder is two things stitched together:

1. **Orchestration & bookkeeping** — labels, relocations, the two-pass
   encode/decode loops, error/result reporting, the print framework,
   buffer management, the table-gen tooling pattern. This is *the same
   problem on every ISA* and should be written once.
2. **The instruction model & the bytes** — what a register/memory/operand
   *is*, what the encoding tables look like, and the actual
   bit/byte-twiddling of `encode_one`/`decode_one`. This is *irreducibly
   per-architecture* and must stay native and zero-cost.

Every decision below follows from drawing the line in exactly that place.
We do **not** try to invent one `Instruction` type that fits all ISAs —
that path forces x86's `segment`/SIB and ARM's writeback and RISC-V's
split immediates into one bloated struct, and it is precisely the
"compromise performance/effectiveness" outcome to avoid. Instead, each
arch owns its concrete types, and uniformity comes from a **naming
contract** (§6) plus a small **shared core** (§4) plus **opt-in**
generic glue (§5, §7).

---

## 1. The universal shape

Strip away the x86 specifics and every target needs the same nine things:

| # | Concept | Example in x86 |
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

Plus two cross-cutting concerns: **errors/result** reporting and a
**table-driven core** fed by **codegen tooling**.

The *shape* of items 5–9 (their signatures and the types they pass around)
is architecture-independent. That is the surface we standardize.

---

## 2. Where architectures actually diverge

This is the heart of the analysis. Ranked from "diverges hardest" to
"barely diverges."

### 2.1 Encoding mechanics — **maximal divergence**

| ISA | Width | Mechanism |
|---|---|---|
| x86 | 1–15 B, variable | legacy prefixes → REX/VEX/EVEX → escape → opcode → ModRM → SIB → disp → imm |
| RISC-V | 4 B (2 B for "C") | pack fixed bitfields; ~6 formats (R/I/S/B/U/J) |
| ARM64 | 4 B fixed | pack per-class bitfields; many classes; bitmask-imm encoder |
| MIPS | 4 B fixed | 3 formats (R/I/J), very regular |

`encode()`'s ~500-line body and the whole `Encoding`/`Encoding_Flags`
schema (esc/prefix/vex_*) are **x86-only**. RISC-V's `encode_one` is a
dozen lines of shifts. **Conclusion: the `encode_one`/`decode_one` core
and the `Encoding` struct do not generalize — but the loop that drives
them does (§7).**

### 2.2 Memory addressing — **high divergence**

| ISA | Addressing modes |
|---|---|
| x86 | `[base + index*scale + disp32]`, RIP-relative, segment override, addr-size override |
| RISC-V | `disp12(base)` only — no index, no scale |
| MIPS | `imm16(base)` only |
| ARM64 | `[base]`, `[base,#imm]`, `[base,Xm{,LSL#n}]`, `[base,Wm,SXTW]`, pre/post-index `[base,#imm]!` / `[base],#imm`, PC-rel literal |

The x86 `Memory` bit_field (with `segment`, `addr_size_override`,
index+scale) is deeply x86-flavored. RISC-V's memory is `{base, i32 disp}`.
ARM adds **writeback** (a mode x86 cannot express) and extend/shift on the
index. **Conclusion: `Memory` is per-arch.** What generalizes is only the
*role*: a `MEMORY`-kind operand carrying an arch-defined payload.

### 2.3 Immediates & operand size — **moderate divergence**

- The *value* (an `i64`) generalizes perfectly.
- The *encoding* does not: RISC-V scatters immediate bits across fields
  (B-type, J-type) and shifts them; ARM has bitmask-immediate and shifted
  forms. All of that lives inside `encode_one`; the `Operand` just holds
  the clean value.
- **Size association differs:** x86 carries an explicit `size: u8` and
  uses it to select an encoding; RISC-V/ARM bake width into the mnemonic
  (`LW` vs `LD`, `W0` vs `X0`). Keep `size` in the shared operand shape as
  a *carrier*; let each arch decide how much it matters.

### 2.4 Relocations — **moderate divergence (structurally aligned)**

The `Relocation` *struct* (offset, symbol/label, addend, type, size)
mirrors ELF `rela` and is universal. The *type enum* is per-arch and much
larger on RISC-V (paired `PCREL_HI20`/`PCREL_LO12`, `CALL`, `BRANCH`,
`JAL`, `HI20`, `LO12_I/S`, …) because PC-relative addressing needs
instruction *pairs* (AUIPC+ADDI). **Conclusion: share the struct shape,
make the type enum a per-arch parameter.**

### 2.5 Registers — **low/structural divergence**

The `(class, hw_number)`-packed `distinct u16` scheme generalizes well.
What differs:
- x86: REX/EVEX extension bits, AH↔SPL aliasing, RIP pseudo-reg.
- RISC-V: clean 5-bit fields, `x0`=hardwired zero, ABI names
  (`zero/ra/sp/gp/tp/t0../s0../a0..`), separate `f`/`v` files.
- ARM64: reg #31 means **SP or XZR depending on instruction** (a
  decode/print-time disambiguation x86 never needs); `w`/`x` and
  `b/h/s/d/q` views.
**Conclusion: share the *layout convention* + `reg_hw`/`reg_class`
accessors; per-arch owns classes, enums, names, and extension semantics.**

### 2.6 Mnemonics — **content differs, shape identical**

Per-arch `enum u16`, `INVALID=0`. Nothing to share but the convention.

### 2.7 Labels — **no divergence**

`labels.odin` is pure bookkeeping. The array-index model
(`Label_Definition`, `label`, `label_forward`, `label_set_at`,
`Label_Map`, `label_named`, `label_reserve`, `label_set`) lives in
`isa/labels.odin` and is parametric over the Instruction type. **Fully
shared.** Each arch's `encode()` rewrites label_defs from instruction
indices to byte offsets between pass 1 and pass 2.

### 2.8 Errors / Result — **low divergence**

`Result` is universal. `Error` is universal in shape. `Error_Code` splits
into a **shared core** (`NONE, BUFFER_OVERFLOW, INVALID_MNEMONIC,
NO_MATCHING_ENCODING, BUFFER_TOO_SHORT, INVALID_OPCODE, LABEL_OUT_OF_RANGE,
…`) and **arch-specific** extras (`INVALID_MODRM/SIB/VEX/EVEX,
TOO_MANY_PREFIXES` on x86; RISC-V would add `MISALIGNED_IMMEDIATE`,
`INVALID_ROUNDING_MODE`, …).

### 2.9 Printer — **framework universal, formatting per-arch**

Shareable: `Token`, `Token_Kind` (the kinds are generic), `Print_Options`,
the builder/number-formatting helpers, and the whole family of output
sinks (`sbprint/print/aprint/tprint/bprint/fprint/wprint` + `ln`). Per-arch:
`register_name`, `print_memory` (syntax differs wildly),
`mnemonic_to_string`, and the size-suffix convention (x86's `.b/.w/.d` is
x86-only; RISC-V puts width in the mnemonic).

### Divergence summary

| Component | Verdict | What's shared | What's per-arch |
|---|---|---|---|
| Labels | ✅ shared | everything | — |
| Result / Error struct | ✅ shared | struct shapes | error-code extras |
| Relocation struct | ✅ shared | struct shape | type enum |
| Printer framework | ◑ split | tokens, options, sinks, num-fmt | reg/mem/mnemonic formatting |
| Register scheme | ◑ split | layout + `reg_hw`/`reg_class` | classes, enums, names, ext bits |
| Operand model | ◑ split | kind tag + union discipline + `size` carrier | `Memory`, `flags` payloads |
| Encode/decode **driver** | ◑ shared via generics | two-pass loops, label/reloc resolution | the per-instruction hook |
| `Instruction` | ✗ per-arch | shape convention only | concrete struct |
| `Mnemonic` | ✗ per-arch | convention (u16, INVALID=0) | the enum |
| `Encoding` + tables | ✗ per-arch | codegen *pattern* | schema + data |
| `encode_one`/`decode_one` | ✗ per-arch | nothing | all of it |
| Memory addressing | ✗ per-arch | operand *role* | the model |

---

## 3. Why not the "obvious" unifications

Three tempting designs that **violate** the no-compromise rule:

1. **One universal `Operand`/`Memory` for all ISAs.** Forces the union of
   x86 SIB+segment, ARM writeback+extend, and RISC-V's nothing into a
   single struct. Bloats every operand, leaks `segment` into RISC-V, and
   still can't represent ARM writeback cleanly. ✗

2. **A runtime `interface`/vtable the encoder calls per instruction.**
   Adds an indirect call to the hottest loop (x86 does ~17 M inst/s — a
   per-instruction `proc` pointer is a measurable tax) and defeats
   inlining. ✗ on the default path.

3. **`any`/tagged-union `Instruction` passed through a generic `encode`.**
   Same monomorphization loss + runtime type checks in the hot loop. ✗

The design instead gets uniformity from **compile-time** mechanisms
(naming contract + parametric polymorphism), and reserves runtime dispatch
for an **opt-in** facade (§5.3) that only multi-target *tools* pay for.

---

## 4. Proposed package layout

```
rexcode/
  isa/                     # shared, architecture-independent core
    labels.odin            #   Label, Label_Definition, Label_Map, resolution
    reloc.odin             #   Relocation (type field is generic/u8)
    status.odin            #   Result, Error, shared Error_Code core
    print.odin             #   Token, Token_Kind, Print_Options, sinks, num-fmt
    register.odin          #   distinct-u16 layout convention + reg_hw/reg_class
    pipeline.odin          #   parametric encode_stream/decode_stream (§7)
    target.odin            #   optional runtime Target vtable (§5.3)

  x86/                     # exists today; refactor to import isa
    registers.odin operands.odin instructions.odin mnemonics.odin
    encoding_types.odin encoder.odin decoder.odin printer.odin
    encoding_table.odin decoding_tables.odin mnemonic_builders.odin
    tests/  tools/

  riscv/                   # next: same shape as x86/
    registers.odin operands.odin instructions.odin mnemonics.odin
    encoding_types.odin encoder.odin decoder.odin printer.odin
    encoding_table.odin decoding_tables.odin mnemonic_builders.odin
    tests/  tools/

  arm64/  mips/  …         # future, same template
```

- **`isa` depends on nothing.** Each arch package depends on `isa` and
  **re-exports** the shared types (e.g. `x86.Result`, `x86.Label_Map`)
  so a consumer of `x86` sees one coherent namespace and never imports
  `isa` directly unless writing arch-generic tooling.
- Each arch package is **self-contained** (its own tests/tools), matching
  the move already done for x86.

---

## 5. Three layers of generality (pick per use case)

### 5.1 Layer A — direct single-arch use (default, zero overhead)

```odin
import "rexcode/x86"
code: [4096]u8
res := x86.encode(insts[:], labels[:], code[:], &relocs, &errors)
```
Fully static, fully inlined, exactly as fast as today. **99% of consumers
live here.**

### 5.2 Layer B — source-portable code via the naming contract

Because every arch package exposes the *same names with the same
signatures* (§6), code that only touches the shared vocabulary
(`Label_Map`, `encode`, `tprint`, `Result`, `Relocation`) can be written
against `import arch "rexcode/x86"` and re-pointed at `rexcode/riscv` by
changing one import — as long as the arch-specific operand construction is
isolated (e.g. behind your own per-arch helper). Still 100% compile-time,
zero overhead.

### 5.3 Layer C — runtime multi-target facade (opt-in, for tools)

For a disassembler or JIT that selects the arch *at runtime*, `isa`
provides a vtable populated by each arch:

```odin
// isa/target.odin
Target :: struct {
    name:       string,
    decode:     proc(data: []u8, out: ^Decoded) -> Result,   // bytes → generic Decoded
    print:      proc(d: ^Decoded, opts: ^Print_Options) -> string,
    inst_align: u32,   // 1 for x86, 4 for riscv/arm64/mips
    max_inst:   u32,   // 15 for x86, 4 for riscv (8 for C-pairs), 4 for arm64
}
// each arch: x86.TARGET: isa.Target = { … }
```
This boundary trades in **bytes and a generic `Decoded` view**, not the
concrete `Instruction`, so it never forces a unified instruction struct.
It carries a proc-pointer indirection — acceptable for a tool that has
already paid a `switch arch` somewhere, and never on Layer A's path.

---

## 6. The naming contract (the most important artifact)

Every architecture package **MUST** expose these names with these
signatures. This is what makes the family feel like one library and what
the RISC-V implementation is built against as a checklist.

### Types (concrete per arch, identical names)

```
Register      Memory        Operand       Operand_Kind
Instruction   Mnemonic      Encoding      Instruction_Info
```

### Re-exported shared types (from `isa`)

```
Label  Label_Definition  Label_Map  LABEL_UNDEFINED
Relocation  Relocation_Type   Error  Error_Code  Result
Token  Token_Kind  Print_Options  DEFAULT_PRINT_OPTIONS
```

### Operand constructors

```
op_reg(r) op_mem(m, size) op_imm(v, size) op_label(id, size)
mem_*(…)            # arch-specific set; at minimum mem_base_disp
                    # (mem_base in x86 is an accessor, not a constructor;
                    # use mem_base_only for the no-displacement case)
op_<class>(typed)   # typed safe constructors where the arch has classes
```

### Instruction builders & emitters

Builder names spell out each operand kind separated by underscores
(matches x86's existing convention):

```
inst_none / inst_r / inst_r_r / inst_r_i / inst_r_m / inst_m_r / …
emit_none / emit_r / emit_rr / emit_ri / emit_rm / emit_mr / …
            # NB: emit_* uses concatenated suffixes (legacy x86 spelling)
inst_<mnemonic>(…) / emit_<mnemonic>(…)   # generated typed overloads
```

### Entry points (identical signatures across arches)

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

### Register/label/print helpers

```
reg_hw  reg_class  reg_size  register_name  mnemonic_to_string
label  label_forward  label_named  label_reserve  label_set
```

> Anything an arch genuinely lacks (e.g. RISC-V has no `mem_base_index`)
> is simply **absent**, not stubbed. Portable (Layer B) code stays within
> the intersection; arch-aware code uses the extras.

---

## 7. Zero-cost code reuse via parametric polymorphism

The encode/decode **drivers** are arch-independent control flow. Factor
them into `isa` as procedures generic over the instruction type `$I`,
parameterized by an arch-provided per-instruction hook. Odin monomorphizes
these at compile time → **no runtime cost, real code sharing.**

```odin
// isa/pipeline.odin  (sketch)
encode_stream :: proc(
    instructions: []$I,
    label_defs:   []Label_Definition,
    code:         []u8,
    relocs:       ^[dynamic]Relocation,
    errors:       ^[dynamic]Error,
    encode_one:   proc(inst: ^I, out: []u8, code_pos: u32,
                       relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (n: u32, ok: bool),
    resolve := true, base_address: u64 = 0,
) -> Result {
    // PASS 1: for each inst → record offset, call encode_one, advance
    // PASS 1.5: rewrite label_defs inst-index → byte-offset   (identical on every arch)
    // PASS 2: resolve relocations / patch / spill unresolved   (identical on every arch)
}
```

x86's current `encode()` becomes a thin wrapper that passes its
`encode_one` (the prefix/ModRM/SIB body); RISC-V's wrapper passes its
12-line bitfield packer. The label/relocation machinery — the part that's
easy to get subtly wrong — is written and tested **once**.

Caveats (arch-specific passes that stay out of the shared driver):
- **RISC-V pseudo-ops** (`li`, `call`, `la`, `j`) expand to 1–2 real
  instructions; needs an arch pre-lowering pass.
- **Branch relaxation** (short↔long form) is arch-specific.
- **ARM literal pools / constant islands** are an extra emission phase.

These plug in *around* the shared driver, not inside it.

---

## 8. Concrete RISC-V mapping (RV64GC as the first target)

What each contract item becomes, to validate the design before coding:

| Contract item | RISC-V realization |
|---|---|
| `Register` | `distinct u16`, classes `REG_X` (x0–31), `REG_F` (f0–31), `REG_V` (v0–31). No REX/EVEX bits. `x0` semantic = zero. |
| typed enums | `XREG{ZERO,RA,SP,GP,TP,T0,T1,T2,S0,S1,A0..A7,S2..S11,T3..T6}`, `FREG`, `VREG` |
| `Memory` | `struct { base: Register, disp: i32 }` — no index/scale/segment |
| `mem_*` | `mem_base(base)`, `mem_base_disp(base, disp)` only |
| `Operand` | same kind-tagged shape; `size` mostly informational (width is in the mnemonic) |
| `Mnemonic` | `enum u16` — RV32I/64I + M,A,F,D,C,V (`ADDI, LW, LD, BEQ, JAL, AUIPC, FADD_D, …`) |
| `Encoding` | `struct { format: Format, opcode, funct3, funct7: u8, … }`, `Format{R,I,S,B,U,J,R4,…}` |
| `encode_one` | switch on `format`, pack fields, scatter immediate bits |
| `Encoding_Flags` | tiny (e.g. `is_compressible`, `rounding_ok`) vs x86's 11 fields |
| `Relocation_Type` | `R_RISCV_BRANCH, JAL, CALL, PCREL_HI20, PCREL_LO12_I/S, HI20, LO12_I/S, RVC_BRANCH/JUMP, …` |
| `Instruction_Info` | `offset`, `is_compressed: bool`, rounding mode — no prefix/VEX fields |
| printer | `register_name` uses ABI names; `print_memory` emits `disp(base)`; width lives in the mnemonic (no `.b/.w` suffix) |
| tables | `gen_decode_tables` becomes near-trivial: a fixed-field instruction decodes by `(opcode, funct3, funct7)` keys |
| `MAX_INST_SIZE` | `4` (or `8` to cover a compressed pair); `inst_align` = 2 |

Notable RISC-V-only concerns the design already accommodates:
- **Split immediates** → hidden in `encode_one`; operand stays a clean value.
- **Paired PC-relative relocs** (AUIPC+ADDI) → expressed via the shared
  `Relocation` struct with RISC-V's type enum; resolution of the *pair* is
  a RISC-V detail layered on the shared reloc list.
- **Compressed (C) extension** → variable 2/4-byte width handled by
  `decode_one` returning a length, exactly like x86's variable length —
  the shared decode driver already threads instruction length.

If RISC-V slots cleanly into the contract (it does above), the contract is
sound for the regular fixed-width ISAs (ARM64, MIPS) too.

---

## 9. Recommended next steps

1. **Stabilize x86 first.** Resolve the constructor-rename drift noted in
   [x86_api.md](x86_api.md#known-drift) (tests/README vs `operands.odin`)
   so x86 is the clean reference the contract is extracted from.
2. **Extract `isa`** by lifting the *already-arch-independent* files:
   `labels.odin`, the `Relocation`/`Error`/`Result` types, and the printer
   framework (tokens/options/sinks/number-formatting). Make `x86`
   re-export them. This is a low-risk refactor that proves the split.
3. **Add the parametric `encode_stream`/`decode_stream`** to `isa` and
   reduce x86's `encode`/`decode` to wrappers. Validate against the
   existing test suite (same bytes out).
4. **Write the RISC-V package against the contract** (§6) and the mapping
   (§8), reusing `isa` wholesale. Build its `encoding_table.odin` by hand,
   then port the two generators.
5. **Only if a runtime-multi-target tool appears**, add the `Target`
   vtable (§5.3). Don't build it speculatively.

The deliverable order matters: every step is independently shippable, and
x86 keeps working (and keeps its performance) throughout.

---

## 10. One-paragraph summary

Make `isa` own the parts that are the same on every ISA — labels,
relocations, errors/result, the print framework, and (via Odin
parametric polymorphism) the encode/decode driver loops. Make each arch
package own its registers, memory model, operands, mnemonics, encoding
tables, and the actual `encode_one`/`decode_one` bytes. Bind the family
together with a strict **naming contract** so packages are drop-in
swappable at source level with zero runtime cost, and reserve a single
opt-in runtime `Target` vtable for the rare tool that needs to choose an
architecture dynamically. x86 keeps every cycle of its current
performance; RISC-V (and later ARM/MIPS) gets the boring 60% for free and
writes only the 40% that is genuinely its own.
