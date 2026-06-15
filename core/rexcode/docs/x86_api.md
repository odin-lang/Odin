<!-- rexcode  ·  Brendan Punsky (dotbmp@github), original author -->

# rexcode `x86` — Complete API Extraction

> Snapshot of the entire public surface of the `x86` subpackage
> (`rexcode/x86/`), grouped by module. This is the reference the
> cross-architecture design ([cross_arch_design.md](cross_arch_design.md))
> is built against.

The package is **table-driven**: a hand-written master encoding table
(`ENCODING_TABLE`, in `tablegen/`) is the single source of truth, from which the
encode/decode tables (committed binary blobs, `#load`ed into `@(rodata)`) and the
typed builder procedures are *generated*. The runtime is zero-allocation (caller
owns every buffer) and the hot paths are fully inlined.

```
                       ENCODING_TABLE  (hand-written, source of truth)
                              │
              ┌───────────────┼────────────────┐
        tablegen (2-stage)          gen_mnemonic_builders
              │                              │
       tables/*.bin → tables.odin   mnemonic_builders.odin
       (#loaded into @(rodata))      (typed inst_*/emit_* helpers)
```

Pipeline at a glance:

```
[]Instruction ──encode()──▶ []u8 (+ []Relocation, []Error)
        ▲                          │
        │                          ▼
     builders                  decode()
        │                          │
   inst_*/emit_*                   ▼
                          []Instruction + []Instruction_Info + []Label_Definition
                                   │
                                   ▼
                            print()/tprint()/… ──▶ text (+ []Token)
```

---

## 1. Registers (`registers.odin`)

### Core type

```odin
Register :: distinct u16   // bit layout: 0b_0000_CCCC_EEEN_NNNN
//   NNNNN = hardware register number (0–31)
//   E     = needs REX/VEX .B/.R/.X extension (hw >= 8)
//   EE    = needs EVEX (hw 16–31)
//   CCCC  = register class (high byte)
```

### Class constants (high byte)

`REG_NONE`, `REG_GPR64`, `REG_GPR32`, `REG_GPR16`, `REG_GPR8`, `REG_GPR8H`
(legacy AH/CH/DH/BH), `REG_XMM`, `REG_YMM`, `REG_ZMM`, `REG_K` (opmask),
`REG_SEG`, `REG_CR` (control), `REG_DR` (debug), `REG_BND` (MPX), `REG_MM`
(MMX), `REG_ST` (x87).

### Sentinels

`NONE :: Register(0xFFFF)`, `RIP :: Register(0xFFFE)`.

### Typed register enums (compile-time safety, value == hardware number)

`GPR64`, `GPR32`, `GPR16`, `GPR8`, `GPR8H` (`AH=4..BH=7`), `XMM`, `YMM`,
`ZMM` (each 0–31), `KREG` (K0–K7), `SREG` (ES,CS,SS,DS,FS,GS), `MM`
(MM0–7), `CREG` (CR0,2,3,4,8), `DREG` (DR0–3,6,7), `ST` (ST0–7), `BND`
(BND0–3).

### Named register constants

Every register has a package-level constant: `RAX`…`R15`, `EAX`…`R15D`,
`AX`…`R15W`, `AL`…`R15B`, `AH/CH/DH/BH`, `XMM0`…`XMM31`, `YMM0`…`YMM31`,
`ZMM0`…`ZMM31`, `K0`…`K7`, `ES/CS/SS/DS/FS/GS`, `CR0/2/3/4/8`,
`DR0/1/2/3/6/7`, `BND0`…`BND3`, `MM0`…`MM7`, `ST0`…`ST7`, plus `RIP`.

### Utility functions (all branchless, `contextless`)

| Proc | Signature | Purpose |
|---|---|---|
| `reg_hw` | `(Register) -> u8` | hardware number (low 5 bits) |
| `reg_class` | `(Register) -> u16` | class (high byte) |
| `reg_needs_rex` | `(Register) -> bool` | hw >= 8 |
| `reg_needs_rex_ext` | `(Register) -> bool` | hw >= 8 and class < K |
| `reg_needs_evex` | `(Register) -> bool` | hw >= 16 |
| `reg_is_gpr` | `(Register) -> bool` | any GPR class |
| `reg_is_vector` | `(Register) -> bool` | XMM/YMM/ZMM |
| `reg_is_high_byte` | `(Register) -> bool` | AH/CH/DH/BH |
| `reg_size` | `(Register) -> u16` | size in **bits** |

### Register-from-number constructors

`gpr64_from_num`, `gpr32_from_num`, `gpr16_from_num` `(u8) -> Register`;
`gpr8_from_num(num: u8, has_rex: bool) -> Register` (handles AH↔SPL
aliasing); `xmm_from_num`, `ymm_from_num`, `zmm_from_num`,
`mm_from_num`. Each returns `NONE` if out of range. Pure casts, no table.

---

## 2. Operands (`operands.odin`)

### Operand kind

```odin
Operand_Kind :: enum u8 { NONE, REGISTER, MEMORY, IMMEDIATE, RELATIVE }
```

### Memory operand (packed)

```odin
Memory :: bit_field u64 {
	base_hw:            u8   | 5,
	base_ext:           bool | 1,
	index_hw:           u8   | 5,
	index_ext:          bool | 1,
	scale_enc:          u8   | 2,
	displacement:       i32  | 32,
	segment:            u8   | 3,
	addr_size_override: bool | 1,
	base_class:         u8   | 5,
	index_class:        u8   | 5,
}
MEM_BASE_RIP :: 30   MEM_BASE_NONE :: 31   MEM_INDEX_NONE :: 31
```

**Constructor:** `mem_make(base, index: Register, scale: u8, displacement: i32, segment: Register) -> Memory`

**Convenience constructors** (current names after the in-tree refactor):
`mem_base_only(base)`, `mem_base_disp(base, disp)`,
`mem_base_index(base, index, scale)`,
`mem_base_index_disp(base, index, scale, disp)`, `mem_rip_disp(disp)`.

> ⚠️ `mem_base` is an **accessor** (returns the base `Register`), not a
> constructor — use `mem_base_only` for the no-displacement case.

**Accessors:** `mem_scale`, `mem_is_rip_relative`, `mem_has_base`,
`mem_has_index` `(Memory) -> …`; `mem_base`, `mem_index` `(Memory) -> Register`.

### The unified operand

```odin
Operand :: struct #packed {              // 16 bytes
	using _: struct #raw_union {
		reg:       Register,
		mem:       Memory,
		immediate: i64,
		relative:  i64,      // offset or label id
	},
	kind:  Operand_Kind,
	size:  u8,               // operand size in bytes (1,2,4,8,16,32,64)
	flags: Operand_Flags,
	_:     [4]u8,
}

Broadcast :: enum u8 { NONE, B1TO2, B1TO4, B1TO8, B1TO16 }   // EVEX

Operand_Flags :: bit_field u16 {   // EVEX-specific
	mask:      u8        | 3,   // opmask K1–K7
	zeroing:   bool      | 1,   // merge vs zero masking
	broadcast: Broadcast | 3,
	er_sae:    u8        | 2,   // embedded rounding / SAE
}
```

### Generic operand constructors

`op_reg(r)`, `op_mem(m, size)`, `op_mem_from_parts(base, index, scale, disp, size)`,
`op_imm8/16/32/64(v)`, `op_rel8/32(offset)`, `op_label(label_id, size=4)`.

### Typed operand constructors (compile-time class safety)

`op_gpr64`, `op_gpr32`, `op_gpr16`, `op_gpr8`, `op_gpr8h`, `op_xmm`,
`op_ymm`, `op_zmm`, `op_kreg`, `op_sreg`, `op_mm`, `op_creg`, `op_dreg`,
`op_st`, `op_bnd` — each takes the matching typed enum and returns an
`Operand` (e.g. `op_gpr64(.XMM0)` is a *compile error*).

---

## 3. Instructions (`instructions.odin`)

```odin
Rep :: enum u8 { NONE, REP, REPNE }

Instruction_Flags :: bit_field u8 {
    lock: bool|1, rep: Rep|2, segment: u8|3, addr32: bool|1, data16: bool|1,
}

Instruction :: struct #packed {          // 72 bytes
	ops:           [4]Operand,
	mnemonic:      Mnemonic,
	operand_count: u8,
	flags:         Instruction_Flags,
	length:        u8,        // filled by decoder
	_:             [3]u8,
}
```

### Generic instruction builders (`inst_*`, all `contextless`)

| Builder | Shape |
|---|---|
| `inst_none(m)` | no operands |
| `inst_r(m, r)` | one register |
| `inst_m(m, mem, size)` | one memory |
| `inst_i(m, imm, imm_size)` | one immediate |
| `inst_rel(m, label_id, size=4)` | branch to label |
| `inst_rel_offset(m, offset, size)` | branch to raw offset |
| `inst_r_r(m, dst, src)` | reg, reg |
| `inst_r_m(m, dst, src_mem, size)` | reg, mem |
| `inst_m_r(m, dst_mem, size, src)` | mem, reg |
| `inst_r_i(m, dst, imm, imm_size)` | reg, imm |
| `inst_m_i(m, dst_mem, size, imm, imm_size)` | mem, imm |
| `inst_r_r_r(m, dst, s1, s2)` | 3× reg (VEX/EVEX) |
| `inst_r_r_m(m, dst, s1, m2, size)` | reg, reg, mem |
| `inst_r_r_i(m, dst, src, imm, imm_size)` | reg, reg, imm |
| `inst_r_m_i(m, dst, m, msize, imm, isize)` | reg, mem, imm |
| `inst_m_r_i(m, mem, msize, src, imm, isize)` | mem, reg, imm |
| `inst_r_m_r(m, dst, m1, msize, s2)` | reg, mem, reg |
| `inst_r_r_r_r(m, dst, s1, s2, s3)` | 4× reg |
| `inst_r_r_r_i(m, dst, s1, s2, imm, isize)` | 3 reg + imm |
| `inst_r_r_m_i(m, dst, s1, m2, msize, imm, isize)` | 2 reg + mem + imm |
| `inst_r_r_m_r(m, dst, s1, m2, msize, s3)` | 2 reg + mem + reg |

### Dynamic-array emitters (`emit_*`, in `encoder.odin`)

One `emit_*` per `inst_*` shape: `emit_none, emit_r, emit_rr, emit_ri,
emit_rm, emit_mr, emit_m, emit_mi, emit_rel, emit_rrr, emit_rrm, emit_rri,
emit_rrrr, emit_i, emit_rmi, emit_mri, emit_rel_offset`. Each is
`(instructions: ^[dynamic]Instruction, mnemonic, …)` and appends.

---

## 4. Mnemonics (`mnemonics.odin`, generated)

```odin
Mnemonic :: enum u16 { INVALID = 0, MOV, MOVABS, MOVZX, …, /* ~1176 total */ }
```

Grouped by family (data transfer, arithmetic, logical, …, SSE, AVX,
AVX-512, BMI, FMA, AES, …). `INVALID = 0` is the sentinel.

---

## 5. Labels & references (`labels.odin`)

Lightweight **array-index** model (`Label_Definition`) used by
`encode()`/`decode()`. The label-construction procedures live in
`isa/labels.odin` and are parametric over the Instruction type, so they
work directly for any arch without per-arch wrappers.

### Array-index model (used by encode/decode)

```odin
Label_Definition :: distinct u32          // label_id -> instruction index, then byte offset
LABEL_UNDEFINED  :: Label_Definition(0xFFFFFFFF)
```
`label(labels: ^[dynamic]Label_Definition, instructions: ^[dynamic]Instruction) -> u32`
(define at current position), `label_forward(labels) -> u32` (reserve).

### Named labels

```odin
Label_Map :: struct { labels: [dynamic]Label_Definition, names: map[string]u32 }
```
`label_map_init(^, allocator)`, `label_map_destroy(^)`,
`label_named(^, name, instructions) -> u32`, `label_reserve(^, name) -> u32`,
`label_set(^, name, instructions)`.

---

## 6. Encoding types (`encoding_types.odin`)

These describe **how** an instruction is encoded; they are the schema of
`ENCODING_TABLE` and are shared by encoder and decoder.

```odin
Operand_Type :: enum u8 {            // ~70 values
	NONE, R8,R16,R32,R64, RM8,RM16,RM32,RM64, M,M8..M512,
	IMM8,IMM16,IMM32,IMM64, IMM8SX, REL8,REL32,
	AL_IMPL,AX_IMPL,EAX_IMPL,RAX_IMPL,CL_IMPL,DX_IMPL,ONE_IMPL,
	SREG, CR, DR, XMM,YMM,ZMM, XMM_M32,XMM_M64,XMM_M128,YMM_M256,ZMM_M512,
	MM,MM_M64, ST0_IMPL,STI, XMM0_IMPL, K,K_M8..K_M64,
	MOFFS8..MOFFS64, PTR16_16,PTR16_32,PTR16_64, M16_16,M16_32,M16_64,
}

Operand_Encoding :: enum u8 {        // where an operand's bits go
	NONE, MR, REG, VVVV, OP_R, IB,IW,ID,IQ, IMPL, IS4, AAA,
}

Escape   :: enum u8 { NONE, _0F, _0F38, _0F3A }
VEX_Type :: enum u8 { NONE, VEX, EVEX, XOP }
VEX_W    :: enum u8 { WIG, W0, W1 }
VEX_L    :: enum u8 { LIG, L0, L1, L2 }

Encoding_Flags :: bit_field u32 {
	esc:           Escape   | 2,
	prefix:        u8       | 2,
	vex_type:      VEX_Type | 2,
	vex_w:         VEX_W    | 2,
	vex_l:         VEX_L    | 2,
	default_64:    bool     | 1,
	force_rex_w:   bool     | 1,
	no_rex:        bool     | 1,
	lock_ok:       bool     | 1,
	rep_ok:        bool     | 1,
	modrm_reg_ext: bool     | 1,
	mode_32_only:  bool     | 1,
}

Encoding :: struct #packed {         // 16 bytes — one encoding form
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	opcode:   u8,
	ext:      u8,
	flags:    Encoding_Flags,
}
PREFIX_66 :: 1   PREFIX_F3 :: 2   PREFIX_F2 :: 3
```
Helper: `encoding_flags(esc=…, prefix=…, …) -> Encoding_Flags`.

### Shared status / interop types

```odin
Relocation_Type :: enum u8 { NONE, REL8, REL32, ABS32, ABS64 }
Relocation :: struct #packed {       // 16 bytes (ELF-rela-like)
	offset: u32, label_id: u32, addend: i32,
	type: Relocation_Type, size: u8, inst_idx: u16,
}

Error_Code :: enum u8 {
	NONE,
	// encode
	INVALID_MNEMONIC, NO_MATCHING_ENCODING, OPERAND_MISMATCH,
	IMMEDIATE_OUT_OF_RANGE, BUFFER_OVERFLOW, LABEL_OUT_OF_RANGE,
	INVALID_OPERAND_COUNT,
	// decode
	BUFFER_TOO_SHORT, INVALID_OPCODE, INVALID_MODRM, INVALID_SIB,
	INVALID_PREFIX, INVALID_VEX, INVALID_EVEX, TOO_MANY_PREFIXES,
}
Error  :: struct #packed { inst_idx: u32, code: Error_Code, _pad: [3]u8 }   // 8 bytes
Result :: struct { byte_count: u32, success: bool }
```
Helper: `op_type_to_size(Operand_Type) -> u8`.

---

## 7. Encoder (`encoder.odin`)

```odin
MAX_INST_SIZE :: 15

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,  // in: inst index; MODIFIED to byte offsets
	code:         []u8,                 // output machine code
	relocs:       ^[dynamic]Relocation, // unresolved relocations appended
	errors:       ^[dynamic]Error,
	resolve:      bool = true,          // patch resolvable relocs in place
	base_address: u64  = 0,             // for ABS relocations
) -> Result
```

Two-pass: (1) encode each instruction into `code`, recording byte offsets
and emitting pending relocations; (1.5) rewrite `label_defs` from
instruction indices to byte offsets; (2) resolve relocations, appending
the unresolvable ones to `relocs`. Pure / no shared state →
trivially parallelizable.

Buffer-sizing helpers: `encode_max_code_size(n) -> int` (`n*15`),
`encode_max_relocation_count(n) -> int` (`n`).

Internal matcher (file-local, inlined): `encoding_matches_inline`,
`operand_matches_inline`, `reg_matches_inline`, `mem_matches_inline`,
`imm_matches_inline`, `implicit_operand_matches`, `is_implicit_op_inline`,
`get_user_op_inline`.

---

## 8. Decoder (`decoder.odin`)

```odin
Instruction_Info :: struct {     // parallel metadata, one per decoded inst
	offset: u32,
	rex: u8, has_lock: bool, rep: Rep, segment: Register,
	vex_type: VEX_Type, vex_l: VEX_L, vex_w: VEX_W,
	evex_b: bool, evex_z: bool, opmask: u8,
}

decode :: proc(
	data:         []u8,
	relocs:       []Relocation,             // optional in: name labels
	instructions: ^[dynamic]Instruction,    // out
	inst_info:    ^[dynamic]Instruction_Info, // out (parallel)
	label_defs:   ^[dynamic]Label_Definition, // out: inferred branch labels
	errors:       ^[dynamic]Error,
) -> Result
```

Two-pass: (1) decode each instruction (prefixes → opcode → operands),
collecting branch targets; (2) infer labels for in-region branch targets,
reusing IDs from `relocs` when available.

`Decoder_State` (file-internal) holds prefix/VEX/EVEX decode state. The
decoder relies on the generated tables in §10. Mostly file-internal procs:
`decode_prefixes`, `decode_vex2/3`, `decode_evex`, `decode_opcode(_vex)`,
`decode_operands(_vex)`, `decode_single_operand(_vex)`,
`decode_memory_operand`, `decode_register`, `decode_implicit_operand`.

---

## 9. Printer (`printer.odin`)

Modified Intel syntax: size suffix on the mnemonic (`.b .w .d .q .x .y
.z`) instead of `PTR`, clean `[base + index*scale + disp]` memory.

```odin
Token_Kind :: enum u8 { WHITESPACE, NEWLINE, LABEL_DEF, LABEL_REF, OFFSET,
                        MNEMONIC, REGISTER, IMMEDIATE, MEMORY_BRACKET, MEMORY_OPERATOR,
                        MEMORY_DISP, MEMORY_SCALE, PUNCTUATION, COMMENT }

Token :: struct { offset: u32, length: u16, kind: Token_Kind, instruction_index: u16 }

Print_Options :: struct {
	uppercase: bool, hex_prefix: string, hex_lowercase: bool,
	label_prefix: string, show_offsets: bool, indent: string,
	separator: string, space_after_comma: bool,
}
DEFAULT_PRINT_OPTIONS :: Print_Options{ … }

Print_Result :: struct { text: string, tokens: []Token }
```

Helpers: `mnemonic_to_string(m, lowercase) -> string`,
`register_name(r, lowercase) -> string`, `token_kind_to_string`,
`size_to_suffix(size) -> u8`.

### Output variants (all share the same trailing param set
`tokens=nil, options=nil, label_names=nil`)

| Family | Sink |
|---|---|
| `sbprint` / `sbprintln` | into a `^strings.Builder` |
| `print` / `println` | stdout |
| `aprint` / `aprintln` | newly allocated string (`allocator` param) |
| `tprint` / `tprintln` | temp-allocator string |
| `bprint` / `bprintln` | caller `[]u8` buffer |
| `fprint` / `fprintln` | `^os.File` |
| `wprint` / `wprintln` | `io.Writer` |

All take `(instructions: []Instruction, inst_info: []Instruction_Info,
label_defs: []Label_Definition, …)`.

---

## 10. Tables & builders

### `tablegen/encoding_table.odin` (hand-written master — the source of truth)

```odin
ENCODING_TABLE: [Mnemonic][]Encoding = { .MOV = { …forms… }, … }
```
Lives in `x86/tablegen/` (a metaprogram package), **not** in the library. A
two-stage pipeline flattens it and serializes committed binary blobs
(`odin run x86/tablegen` → generated Odin + `tables.odin`; then
`odin run x86/tablegen/generated` → `tables/x86.*.bin`). See
[table_migration.md](table_migration.md).

### `tables.odin` (generated — `#load`s the blobs into `@(rodata)`)

The library compiles no table body; `tables.odin` `#load`s `tables/x86.*.bin`
and defines the subsidiary types + accessors:

```odin
Encode_Run       :: struct { start: u32, count: u32 }   // run into ENCODE_FORMS
ModRM_Info       :: struct #packed { mod, reg, rm: u8, has_sib: bool, disp_size: u8 }
SIB_Info         :: struct #packed { scale, index, base: u8 }
Decode_Entry     :: struct { esc: Escape, prefix, opcode, ext: u8,
                             mnemonic: Mnemonic, ops: [4]Operand_Type,
                             enc: [4]Operand_Encoding, flags: Encoding_Flags }
VEX_Decode_Entry :: struct { …Decode_Entry fields + vex_w: VEX_W, vex_l: VEX_L }
Decode_Index     :: struct { start: u16, count: u8 }    // range into entries

ENCODE_FORMS: []Encoding,  ENCODE_RUNS: []Encode_Run     // encode via encoding_forms(m)
MODRM_TABLE, SIB_TABLE,  LEGACY/VEX/EVEX_DECODE_ENTRIES (1270/667/418)
DECODE_INDEX_* / VEX_INDEX_* / EVEX_INDEX_*  ([]Decode_Index, flat 4×256)
```
`encode()` does `encoding_forms(mnemonic)` (a run into `ENCODE_FORMS`) then
linear-scans the forms via `encoding_matches_inline`. `decode()` does
`didx(table, prefix, opcode) -> Decode_Index` for O(1) opcode resolution; the
small `count` range is scanned for ModR/M-ext, operand-size, or VEX.W/L
disambiguation.

### `mnemonic_builders.odin` (generated, ~7,477 procs + ~2,338 overload groups)

Typed memory wrappers `Mem8 … Mem512` (distinct structs over `Memory`)
with constructors `mem8 … mem512`. Per-form typed procs like
`inst_mov_r64_r64(dst: GPR64, src: GPR64) -> Instruction`, each grouped
into an overload set:

```odin
inst_mov :: proc{ inst_mov_r8_r8, inst_mov_r64_r64, inst_mov_r64_imm64, … }
emit_mov :: proc{ emit_mov_r8_r8, … }
```
So `x86.inst_mov(.RAX, .RBX)` resolves the right encoding at compile time
with full type checking, no runtime dispatch.

---

## 11. Tools (`x86/tools/`)

| File | Package | Role |
|---|---|---|
| `tablegen/gen.odin` | `main` | flatten `ENCODING_TABLE` → generated Odin → `tables/*.bin` (2-stage) |
| `tools/gen_mnemonic_builders.odin` | `main` (`-file`) | walk the encode forms → emit `mnemonic_builders.odin` |
| `tools/verify_tables.odin` | `main`, imports `x86 "../"` | check decode tables consistent with the encode forms |
| `tools/dump_verify_input.odin`, `verify_against_llvm.odin` | `main` | LLVM-mc verification harness |

Tests live in `x86/tests/test.odin` (`package x86_tests`, `import x86 "../"`),
run with `odin run x86/tests`.
