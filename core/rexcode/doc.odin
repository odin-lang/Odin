// rexcode  ·  Brendan Punsky (dotbmp@github), original author

/*
# rexcode

High-performance multi-architecture instruction encoder/decoder/printer
library written in Odin. Original author: Brendan Punsky (dotbmp@github).

## Architectures

| Package    | ISA                                                              | Coverage |
|------------|------------------------------------------------------------------|----------|
| `x86`      | x86-64 + i386 (legacy/SSE/AVX/AVX-512/BMI/FMA/AES-NI)             | LLVM-verified |
| `arm32`    | ARMv8 AArch32 (A32 + T32 + Thumb-1 + VFP + NEON + crypto/CRC)     | LLVM-verified, 100% sweep |
| `arm64`    | ARMv8 AArch64 (base integer + FP scalar; SVE/SME WIP)             | LLVM-verified |
| `mips`     | MIPS I/II/III/IV + R6 + COP1 FPU + COP0 + GTE + PS2 EE MMI + DSP ASE | LLVM-verified |
| `riscv`    | RV32GC / RV64GC                                                  | LLVM-verified |
| `ppc`      | Power ISA 3.1 + AltiVec/VSX/MMA/HTM/DFP/BookE/SPE/SPE2 + Paired Singles + VMX128 | 3327 entries, LLVM-verified |
| `ppc_vle`  | Freescale e200 VLE (sibling to `ppc`)                            | 222 entries, binutils-verified |
| `mos6502`  | NMOS 6502 + undocumented + 65C02 + HuC6280                       | da65-verified |
| `mos65816` | W65C816S (SNES, Apple IIgs)                                      | ca65-verified |
| `rsp`      | N64 RSP (MIPS-derived scalar + vector unit)                      | armips-verified |

Every package follows the same API contract (see `docs/cross_arch_design.md`).

## Design

- **Encoder**: assembles instructions to machine code with label resolution
  and per-arch relocation support.
- **Decoder**: disassembles machine code back to structured instructions.
- **Printer**: emits assembly text output with optional syntax-highlighting
  tokens.
- **Table-driven**: O(1) opcode lookup via precomputed encode/decode tables,
  serialized to committed binary blobs and `#load`ed into `@(rodata)`.
- **Zero allocations** on the hot path: caller provides all buffers.

The `isa/` package owns the parts that are the same on every ISA — labels,
result/error types, the print framework, token types, and shared
formatting helpers. Each architecture package owns its registers, memory
model, operand types, mnemonics, encoding tables, and the actual
`encode_one`/`decode_one` bytes.

## Encoding tables

Each arch's `ENCODING_TABLE` (the hand-written single source of truth) lives in
`<arch>/tablegen/`, not in the library. A two-stage metaprogram flattens it and
emits committed binary blobs that the library `#load`s into `@(rodata)` at
compile time — no table is built during a normal library build:

```sh
odin run isa/<arch>/tablegen            # ENCODING_TABLE -> generated Odin + tables.odin
odin run isa/<arch>/tablegen/generated  # -> isa/<arch>/tables/<arch>.*.bin
```
Regenerate after editing `ENCODING_TABLE`. See `docs/table_migration.md`.

## Usage

```odin
import x86 "core:rexcode/isa/x86"

instructions := []x86.Instruction{
	x86.inst_r_r(.MOV, x86.RAX, x86.RDI),
	x86.inst_r_r(.ADD, x86.RAX, x86.RSI),
	x86.inst_none(.RET),
}

code: [4096]u8
relocs: [dynamic]x86.Relocation
errors: [dynamic]x86.Error
result := x86.encode(instructions[:], nil, code[:], &relocs, &errors)

decoded_insts:  [dynamic]x86.Instruction
decoded_info:   [dynamic]x86.Instruction_Info
decoded_labels: [dynamic]x86.Label_Definition
decode_errors:  [dynamic]x86.Error
x86.decode(code[:result.byte_count], nil, &decoded_insts, &decoded_info, &decoded_labels, &decode_errors)

x86.print(decoded_insts[:], decoded_info[:], decoded_labels[:])
disasm := x86.tprint(decoded_insts[:], decoded_info[:], decoded_labels[:])
```

The same shape works for every other arch — change the import.

## Instruction Builders

```odin
x86.inst_none(.RET)
x86.inst_r(.PUSH, x86.RAX)
x86.inst_r_r(.MOV, x86.RAX, x86.RBX)
x86.inst_r_i(.MOV, x86.EAX, 42, 4)
x86.inst_r_r_r(.VADDPS, x86.XMM0, x86.XMM1, x86.XMM2)
x86.inst_m_r(.MOV, x86.mem_base_only(x86.RSP), 8, x86.RAX)
x86.inst_r_m(.MOV, x86.RAX, x86.mem_base_disp(x86.RBP, -8), 8)
x86.inst_rel(.JMP, label_id, 1)
```

These are hand-written **operand-shape** constructors (one `inst_r_r` serves
every two-register mnemonic). Each package additionally ships **generated,
per-mnemonic typed builders** in `mnemonic_builders.odin` — `inst_<mnemonic>` /
`emit_<mnemonic>` overload sets with the operand types baked in — produced by
`<arch>/tools/gen_mnemonic_builders.odin` and regenerated with
`luajit build.lua --builders`.

## Memory Operands

```odin
x86.mem_base_only(x86.RAX)                        // [RAX]
x86.mem_base_disp(x86.RBP, -16)                   // [RBP - 16]
x86.mem_base_index(x86.RAX, x86.RCX, 4)           // [RAX + RCX*4]
x86.mem_base_index_disp(x86.RAX, x86.RCX, 8, 32)  // [RAX + RCX*8 + 32]
x86.mem_rip_disp(0)                               // [RIP + disp]
```

## Labels

```odin
labels: [dynamic]x86.Label_Definition
instructions: [dynamic]x86.Instruction

loop := x86.label(&labels, &instructions)
x86.emit_r(&instructions, .DEC, x86.RDI)
x86.emit_rel(&instructions, .JNZ, loop)

done := x86.label_forward(&labels)
x86.emit_rel(&instructions, .JMP, done)
labels[done] = x86.Label_Definition(len(instructions))

result := x86.encode(instructions[:], labels[:], code[:], &relocs, &errors)
```

For named labels:

```odin
lm: x86.Label_Map
x86.label_map_init(&lm)
defer x86.label_map_destroy(&lm)

loop := x86.label_named(&lm, "loop", &instructions)
done := x86.label_reserve(&lm, "done")
x86.label_set(&lm, "done", &instructions)

result := x86.encode(instructions[:], lm.labels[:], code[:], &relocs, &errors)

// Printer wants id→name; Label_Map stores name→id, so invert once.
id_to_name := make(map[u32]string, len(lm.names), context.temp_allocator)
for name, id in lm.names { id_to_name[id] = name }
x86.print(decoded_insts[:], decoded_info[:], lm.labels[:], label_names = &id_to_name)
```

## Driver script (`build.lua`)

`build.lua` (LuaJIT) drives the pre-build metaprograms, validations, and tests
across every ISA, with cross-platform gating (Linux / macOS / Windows) and a
clear report. With no flags it prints help, including what's available on the
current platform.

```sh
luajit build.lua                 # help + platform availability
luajit build.lua all             # everything: generate -> builders -> validate -> test
luajit build.lua --gen --isa x86 # only regenerate one ISA's tables
luajit build.lua --builders      # regenerate the typed mnemonic builders (all ISAs)
luajit build.lua --check --test  # validate + test the committed tables
luajit build.lua --verify        # external-tool round-trip where the tool is installed
luajit build.lua --list          # ISA x task availability matrix for this platform
```

Tasks: `--gen` (table metaprograms), `--builders` (regenerate each ISA's
`mnemonic_builders.odin`), `--check` (compile + structural invariants),
`--test` (run the suites), `--verify` (round-trip vs `llvm-mc`/`da65`/`ca65`/
`armips`/…), `--idempotent` (re-gen and confirm byte-stable). Scope with
`--isa <list>`. It uses the in-repo `./odin` — build that first.

> Gating: x86's `--test` JIT-executes x86-64 code, so it runs only on an x86-64
> host; `--verify` needs the matching tool in PATH (retro ISAs use shell scripts,
> skipped on Windows). Anything unavailable is skipped with a note, never fatal.

## Running Tests

Each package has its own test suite:

```sh
odin run isa/x86/tests
odin run isa/arm32/tests
odin run isa/arm64/tests
odin run isa/mips/tests
odin run isa/mos6502/tests
odin run isa/mos65816/tests
odin run isa/ppc/tests
odin run isa/ppc_vle/tests
odin run isa/riscv/tests
odin run isa/rsp/tests
```

## Verification harnesses

Each arch has a verification harness under `isa/<arch>/tools/`:
- `dump_verify_input.odin` — emits the per-entry hex/asm manifest.
- `verify_against_<tool>.*` — runs the canonical external assembler/
  disassembler and compares. LLVM-mc for the seven modern archs, plus
  `da65`/`ca65`/`armips`/`powerpc-eabivle-as` for retro/embedded ISAs.

## Project Structure

```
rexcode/
	isa/                # shared ISA core: labels, status, print framework, label-inference
		x86/            # x86-64 / i386
		arm32/          # AArch32
		arm64/          # AArch64
		mips/           # MIPS (R1..R6 + ASEs + coprocessors)
		mos6502/        # NMOS 6502 family
		mos65816/       # W65C816S
		ppc/            # PowerPC (Power ISA 3.1)
		ppc_vle/        # Freescale VLE (sibling of ppc)
		riscv/          # RISC-V
		rsp/            # N64 RSP
	ir/                 # shared IR core (parallels isa/; see docs/ir_design.md)
	wasm/               # WebAssembly (an IR; destined for ir/wasm once the IR layer settles)
	docs/               # cross-arch design + IR design + per-arch design docs
```

Each ISA is imported as `core:rexcode/isa/<arch>` (e.g. `core:rexcode/isa/x86`); the
shared core is `core:rexcode/isa`. Per-package layout (canonical, enforced by the
cross-arch contract):

```
isa/<arch>/
	encoder.odin         # encode() — two-pass, label/reloc-aware
	decoder.odin         # decode()
	printer.odin         # sb/sbln/print/println/aprint/aprintln/tprint/tprintln/bprint/bprintln/fprint/fprintln/wprint/wprintln
	registers.odin       # Register, REG_* classes, typed enums
	operands.odin        # Operand, Memory, Operand_Kind, op_* constructors
	instructions.odin    # Instruction, inst_* operand-shape builders
	mnemonic_builders.odin # generated: inst_<mnem>/emit_<mnem> typed builders
	encoding_types.odin  # Encoding, Encoding_Flags, isa re-exports
	tables.odin          # generated: #load()s the binary tables into @(rodata) + accessors
	tables/              # committed binary blobs (<arch>.*.bin) the library #loads
	mnemonics.odin       # Mnemonic enum (u16, INVALID=0)
	reloc.odin           # Relocation_Type + Relocation
	tablegen/            # ENCODING_TABLE (source of truth) + gen.odin metaprogram
	tests/               # smoke, pipeline_smoke, sweep
	tools/               # dump_verify_input, verify_against_*, gen_mnemonic_builders
```

## Cross-architecture API design

See [docs/cross_arch_design.md](docs/cross_arch_design.md) for the
naming contract every arch package follows.
*/
package rexcode