<!-- rexcode  ·  Brendan Punsky (dotbmp@github), original author -->

# rexcode — IR API Design

> Why the rexcode IR family (`wasm`, and the planned `spirv`, `llvm`, with
> `air` / `dxil` as LLVM dialects) gets its own API layer (`core:rexcode/ir`)
> **parallel** to the ISA layer (`core:rexcode/isa`) — sharing the ISA layer's
> spirit and as much of its shape as honestly survives, while conceding exactly
> the three places an IR is not an ISA.

Read [cross_arch_design.md](cross_arch_design.md) first; this document is its
sibling and assumes its vocabulary.

---

## The guiding principle

The ISA layer's rule was *“share the bookkeeping, specialize the bytes.”* The IR
layer keeps it and adds one clause:

> **Share the bookkeeping *and the structure*, specialize the dialect and the codec.**

An ISA only ever shares bookkeeping because its *content* (registers, operands,
the bit-twiddling) diverges maximally per arch. An IR shares **more** — the whole
`Module → Function → Block → Operation` structure and the operand/type model are
genuinely the same problem on every IR — because SSA and a type system regularize
what ISAs leave ad hoc. So `ir/` is a richer shared core than `isa/`: it owns the
*structural model*, not just labels and errors. What stays per-IR is the *opcode
set*, the *codec* (the wire format), and the *dialect* (intrinsic/metadata
conventions).

---

## 0. First: how many IRs are there really?

Fewer than the list suggests. **AIR and DXIL are not peers of LLVM — they are
LLVM bitcode.** AIR is LLVM bitcode + a Metal dialect; DXIL is LLVM ~3.7 bitcode
+ a DirectX dialect inside a DXContainer. So the field is **three codec
families**, not five:

| family | members | wire format |
|---|---|---|
| WASM | wasm | byte stream + LEB128, one form per opcode |
| SPIR-V | spirv | 32-bit words, uniform `wordCount<<16 \| opcode` header |
| LLVM bitstream | llvm, **air**, **dxil** | self-describing block/record/abbreviation bitstream |

The implementation cost is therefore *3 codecs + N dialects*, and `air`/`dxil`
should reuse the `llvm` codec wholesale. That single fact shapes the package
tree: `ir/llvm/`, `ir/llvm/air/`, `ir/llvm/dxil/`.

---

## 1. The universal IR shape

Strip away specifics and every IR needs these — the same checklist `isa` has,
shifted up one level of structure:

| # | Concept | `ir` type |
|---|---|---|
| 1 | A **type** = (kind, width/elem/fields) | `Type`, `Type_Ref` |
| 2 | An **operand** = literal \| entity-ref \| type | `Operand`, `Operand_Kind` |
| 3 | An **operation** = opcode + operands + *optional result* | `Operation` |
| 4 | An **opcode** enum | per-IR `Opcode` (u16, INVALID=0) |
| 5 | **References** to entities by id (+ named symbols) | `Id`, `Ref`, `Symbol_Table` |
| 6 | **Relocations** for object-file symbol fixups | per-IR `Relocation` |
| 7 | `encode(Module) -> bytes (+relocs +errors)` | per-IR `encode()` |
| 8 | `decode(bytes) -> Module (+errors)` | per-IR `decode()` |
| 9 | `print(Module) -> text (+tokens)` | per-IR `print()`/`tprint()` |
| + | A **structured module** of functions→blocks→operations | `Module`/`Function`/`Block` |
| + | A **dataflow discipline** (stack or SSA) | `Dataflow` |

Items 1–9 are item-for-item the ISA's nine, re-aimed: *type* generalizes the
ISA's implicit-width; *operand* keeps the kind tag; *operation* is `Instruction`
+ a `Result`; *opcode* is `Mnemonic`; *references* replace *labels*. The two `+`
rows are the genuinely new structure (§3).

---

## 2. Where IRs diverge from ISAs

Three real divergences, then a long tail of things that *look* different but are
the same shape.

### The three real concessions

1. **The unit of work is a structured `Module`, not a flat `[]Instruction`.**
   An ISA program is a byte-addressed instruction stream; an IR program is a
   typed graph: `Module → []Function → []Block → []Operation`, where an op may
   define an SSA value that later ops use. So `decode` is a *structured parse*,
   not a linear scan, and `ir` owns `Module`/`Function`/`Block` where `isa` owns
   no `Instruction`. `Operation.operands` is **variable-arity** (`[]Operand`) —
   the ISA `Instruction`'s fixed `[4]Operand` is the one leaf shape that does not
   survive (calls, `switch`, `phi`).

2. **A first-class type system.** Operations and results carry a `Type_Ref` into
   the module's type table. ISAs bake width into the mnemonic and never need
   this. `Type_Kind` is the WASM∪SPIR-V∪LLVM denominator (`INT/FLOAT/VECTOR/
   POINTER/STRUCT/FUNCTION/...`).

3. **Entity references replace PC-relative labels.** ISA branches resolve as
   instruction-index→byte-offset (`isa.Label_Definition`, rewritten by `encode`).
   IR operands reference entities by **`Id`** — SSA results, blocks, functions,
   globals, types — resolved *structurally*, with no PC-relative pass. (Object-
   file *symbol* fixups still produce `Relocation`s for `EXTERNAL` refs.)

### Two axes that sort the IRs

Everything else sorts onto two orthogonal axes. Note the clustering is
counterintuitive — the encoding mates and the model mates are *different* pairs:

| IR | encoding model | dataflow model |
|---|---|---|
| WASM | **table** (byte/LEB, one form per opcode) | **stack** (implicit) |
| SPIR-V | **table** (32-bit words, uniform header) | **SSA** (result ids, typed) |
| LLVM / AIR / DXIL | **bitstream** (data-defined abbreviations) | **SSA** (+ metadata graph) |

- On **encoding**, WASM and SPIR-V are siblings — a static `opcode → operand-
  layout` table, *exactly* the ISA `ENCODING_TABLE` shape. LLVM is the outlier:
  its layout is defined by abbreviation records *in the stream*, so **no static
  table can describe it**.
- On **dataflow**, SPIR-V/LLVM are siblings (SSA + types); **WASM is the
  outlier** — a stack bytecode with no SSA, no named results, minimal types.

So WASM is encoding-kin to SPIR-V but model-kin to nothing, and the one thing
you most want to share (LLVM) breaks the table assumption the others share. The
`Dataflow` trait and the *pluggable codec* (§5) exist precisely to absorb these
two splits without forking the API.

### Divergence summary

| Component | Verdict | Shared (`ir/`) | Per-IR |
|---|---|---|---|
| References / `Id` | ✅ shared | the whole id + symbol model | which `Ref_Space`s exist |
| Error / status | ✅ shared | struct shape (= `isa.Error`) | error-code subset |
| Type model | ✅ shared | `Type`/`Type_Ref`/`Type_Kind` | wire⇄`Type` lowering |
| Operand model | ✅ shared* | `Operand` + kinds (SSA homogenizes it) | dialect `aux` encodings |
| Structural model | ✅ shared | `Module`/`Function`/`Block`/`Operation` | — |
| Printer framework | ◑ split | tokens, options, num-fmt | type/value/block syntax |
| Relocation | ◑ split | struct-shape convention | type enum (per-IR file) |
| `Opcode` | ✗ per-IR | convention (u16, INVALID=0) | the enum |
| Opcode table / codec | ✗ per-IR | codec *strategy* (§5) | schema + data (or bitstream) |
| `encode`/`decode` driver | ✗ per-IR | verb signature | the whole parse/emit |

> *`Operand` is shared here where `isa.Operand` is per-arch. ISA operands diverge
> wildly (ModRM/SIB vs shifted-register vs split immediates); SSA collapses IR
> operands to "a literal, a reference, or a type," uniform enough to define once.
> Dialect-specific encodings (WASM memarg, SPIR-V enum masks) are an *encoding*
> detail carried in `Operand.aux` + the IR's opcode table — not a new shape.

---

## 3. The shared core (`ir/`) and why this much is shared

`ir/` depends on nothing (it does **not** depend on `isa/`) and owns the parts
that are the same problem on every IR:

- `status.odin` — `Error`/`Error_Code`; the `Error` struct is byte-identical to
  `isa.Error` so one tool surfaces both.
- `refs.odin` — `Id`, `Ref`, `Ref_Space`, `Symbol_Table` (the `isa.labels`
  analog, re-cast from byte-offsets to structural ids).
- `types.odin` — `Type`, `Type_Ref`, `Type_Kind` (no ISA analog).
- `module.odin` — `Module`/`Function`/`Block`/`Operation`/`Operand`/`Result`/
  `Dataflow` (the structural model; the heart of the layer).
- `print.odin` — token kinds (with IR-only `TYPE`/`VALUE_REF`/`RESULT`/
  `BLOCK_LABEL`), print options, number-formatting helpers.

Each concrete IR package **re-exports** these (e.g. `wasm.Module`,
`spirv.Operation`) so a consumer sees one namespace, mirroring how arch packages
re-export `isa`.

### The validating precedent and the rejected alternatives

The `Operation`-with-blocks-and-regions spine is exactly **MLIR's** structural
model, which is field-proof that one model cleanly subsumes a CFG (LLVM/SPIR-V),
structured control (WASM, as block regions), *and* a flat ISA (the degenerate
one-block, no-SSA case). We take MLIR's spine, not its open-ended generality
(no region/trait/dialect-registry machinery) — the lean version.

Rejected, for the same reasons the ISA layer rejected its three:

1. **Fold ISAs into the IR API** (ISA = "degenerate IR"). True in theory, but it
   taxes the fast, flat ISA hot path with type/SSA/module machinery it never
   needs. Keep them **siblings**; share only the leaf vocabulary in spirit.
2. **One concrete codec for all IRs.** LLVM's bitstream is not a static table;
   forcing WASM/SPIR-V and LLVM through one table breaks LLVM. The codec is
   *pluggable* behind the verbs (§5).
3. **Bake in SSA** (mandatory results + value-refs). Excludes WASM. `Dataflow`
   + optional `Result.id == ID_NONE` keeps the stack machine first-class.

---

## 4. The naming contract

Every IR package exposes these names with these signatures — the checklist each
new IR is built against.

**Re-exported shared types (from `ir`):**
`Module Function Block Operation Operand Operand_Kind Result Type Type_Ref
Type_Kind Id Ref Ref_Space Symbol_Table Dataflow Error Error_Code Token
Token_Kind Print_Options DEFAULT_PRINT_OPTIONS`

**Per-IR concrete types (identical names):**
`Opcode` (u16, `INVALID = 0`) and `Relocation` / `Relocation_Type`.

**Operand constructors (shared):** `op_int op_float op_type op_ref op_value
op_block`, plus the IR's own dialect helpers where an opcode needs a structured
immediate (e.g. a WASM `op_memarg`).

**Operation builders & emitters** — by *shape*, mnemonic passed in (an IR has
hundreds of opcodes over a handful of shapes, so per-opcode typed builders are
optional, not the default): `op_none(opcode) op_unary(opcode, a)
op_binary(opcode, a, b) op_call(callee, args) op_branch(target) …` and `emit_*`.

**Entry points (identical signatures across IRs):**

```odin
encode(m: Module, code: []u8,
       relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool)

decode(data: []u8, m: ^Module, errors: ^[dynamic]Error,
       allocator := context.allocator) -> (byte_count: u32, ok: bool)

print/tprint/…(m: Module, options := ir.DEFAULT_PRINT_OPTIONS) -> (Print_Result | string)
```

Note the *deliberate* differences from the ISA verbs: they take a **`Module`**,
not `[]Instruction`, and they **drop `label_defs` / `resolve` / `base_address`**
— an IR has no PC-relative resolution pass, so those parameters would be dead.
This is the divergence made explicit rather than carried inert. (It is also why
WASM, currently shaped like an ISA package, will move to `ir/wasm`: its real
`encode`/`decode` already dropped those parameters.)

> Anything an IR genuinely lacks (WASM has no `VALUE` refs; an untyped IR no
> `TYPE` refs) is simply **absent**, not stubbed — same rule as the ISA layer.

---

## 5. Codecs — the one place the strategy, not just the data, differs

For an ISA, every codec is the same *kind* of thing (a bit/byte packer driven by
a static table). For IRs there are **two kinds**, and the API contract is the
verbs (§4), not the table — so a package picks its strategy underneath:

- **Table-driven (WASM, SPIR-V).** A static `OPCODE → [operand layout]` table,
  literally the ISA `ENCODING_TABLE` pattern: hand-written single source of
  truth, O(1) dispatch. WASM's existing `ENCODING_TABLE` and SPIR-V's grammar
  JSON both fit this.
- **Bitstream (LLVM, AIR, DXIL).** A generic block/record/abbreviation engine;
  operand layout is defined by abbreviation records encountered in the stream,
  so there is no static opcode table. This is a real subsystem (shared by the
  three LLVM-family members) that the LLVM IR reader sits on top of.

Both satisfy the same `encode`/`decode` signatures; callers never see which.

---

## 6. One-paragraph summary

Make `ir` own what is the same on every IR — and for IRs that is *more* than for
ISAs: not just errors/refs/printing but the whole typed `Module → Function →
Block → Operation` structure, because SSA and a type system regularize it. Keep
the leaf ISA-shaped (`Operation` = `Instruction` + an optional `Result`, opcode a
u16), keep the three verbs, and make exactly three concessions where an IR is not
an ISA: a structured module instead of a flat stream, a first-class type table,
and id-based entity references instead of PC-relative labels. Let `Dataflow`
host both the stack machine and SSA, and let the codec be pluggable so the LLVM
bitstream and the WASM/SPIR-V tables live under one contract. The result is a
sibling to the ISA API, not a generalization of it: each new IR gets the shared
structure and vocabulary for free and writes only its opcode set, its codec, and
its dialect.
