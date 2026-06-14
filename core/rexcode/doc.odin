/*
# rexcode

High-performance multi-architecture instruction encoder/decoder/printer
library written in Odin. Developed by dotbmp/Br.

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
- **Table-driven**: O(1) opcode lookup via precomputed encoding/decoding
  tables.
- **Zero allocations** on the hot path: caller provides all buffers.

The `isa/` package owns the parts that are the same on every ISA — labels,
result/error types, the print framework, token types, and shared
formatting helpers. Each architecture package owns its registers, memory
model, operand types, mnemonics, encoding tables, and the actual
`encode_one`/`decode_one` bytes.

## Performance (x86)

With `-o:speed -microarch:native -no-bounds-check`:
- Encoder: ~17 M instructions/sec (~56 MB/s)
- Decoder: ~16 M instructions/sec (~54 MB/s)

Measured on AMD Ryzen 3950X.

## Usage

```odin
import "x86"

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

## Running Tests

Each package has its own test suite:

```sh
odin run x86/tests
odin run arm32/tests
odin run arm64/tests
odin run mips/tests
odin run mos6502/tests
odin run mos65816/tests
odin run ppc/tests
odin run ppc_vle/tests
odin run riscv/tests
odin run rsp/tests
```

## Verification harnesses

Each arch has a verification harness under `<arch>/tools/`:
- `dump_verify_input.odin` — emits the per-entry hex/asm manifest.
- `verify_against_<tool>.*` — runs the canonical external assembler/
  disassembler and compares. LLVM-mc for the seven modern archs, plus
  `da65`/`ca65`/`armips`/`powerpc-eabivle-as` for retro/embedded ISAs.

## Project Structure

```
rexcode/
	isa/                # shared core: labels, status, print framework, label-inference
	docs/               # cross-arch design + per-arch design docs
	x86/                # x86-64 / i386
	arm32/              # AArch32
	arm64/              # AArch64
	mips/               # MIPS (R1..R6 + ASEs + coprocessors)
	mos6502/            # NMOS 6502 family
	mos65816/           # W65C816S
	ppc/                # PowerPC (Power ISA 3.1)
	ppc_vle/            # Freescale VLE (sibling of ppc)
	riscv/              # RISC-V
	rsp/                # N64 RSP
```

Per-package layout (canonical, enforced by the cross-arch contract):

```
<arch>/
	encoder.odin         # encode() — two-pass, label/reloc-aware
	decoder.odin         # decode()
	printer.odin         # sb/sbln/print/println/aprint/aprintln/tprint/tprintln/bprint/bprintln/fprint/fprintln/wprint/wprintln
	registers.odin       # Register, REG_* classes, typed enums
	operands.odin        # Operand, Memory, Operand_Kind, op_* constructors
	instructions.odin    # Instruction, inst_* builders
	encoding_types.odin  # Encoding, Encoding_Flags, isa re-exports
	encoding_table.odin  # ENCODING_TABLE: [Mnemonic][]Encoding
	decoding_tables.odin # generated dispatch tables
	mnemonics.odin       # Mnemonic enum (u16, INVALID=0)
	reloc.odin           # Relocation_Type + Relocation
	tests/               # smoke, pipeline_smoke, sweep
	tools/               # gen_decode_tables, dump_verify_input, verify_against_*
```

## Cross-architecture API design

See [docs/cross_arch_design.md](docs/cross_arch_design.md) for the
naming contract every arch package follows.
*/
package rexcode