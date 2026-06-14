# MIPS targets and extensions — platform catalog

> What's worth supporting in `rexcode/mips/` (or a sibling subpackage) and
> what isn't, framed around the actual hardware that runs MIPS.

## Mainline consoles (MIPS-family CPUs)

| Platform | CPU | Base ISA | Custom extension | Status |
|---|---|---|---|---|
| **PS1 / PSX** | Sony R3000A | MIPS I (no MMU) | **GTE** (COP2) — geometry transformation engine | ✅ done |
| **PSX IOP / PS3 IOP** | LSI CW33300 / "IOP" | MIPS I | (none — same as PS1 CPU) | ✅ covered by MIPS I |
| **N64** | NEC VR4300i | MIPS III + partial MIPS IV FPU | none on main CPU | ✅ covered by MIPS III + IV + FPU |
| **N64 RSP** | RCP "Reality Signal Processor" | custom MIPS R4000 subset | **VU** (128-bit vector unit, 32 vec regs); also drops mult/div/FPU/TLB | ⚠ **needs its own subpackage** — different ISA |
| **N64 RDP** | (display processor) | not a CPU, command-stream — not in scope |  |  |
| **PS2 EE** | Sony R5900 (Toshiba) | MIPS III + MIPS IV (MOVN/MOVZ) | **MMI** (128-bit packed SIMD via MMI0-3), **LQ/SQ**, second HI/LO, VU0-macro | ✅ done (MMI; VU0-macro forms TBD) |
| **PS2 VU0 / VU1** | "Vector Unit" | not MIPS — VLIW pair (upper + lower microcode) | — | 🚧 **separate ISA** — sibling `vu/` subpackage if needed |
| **PS2 IOP** | (R3000A reused) | MIPS I | — | ✅ covered |
| **PSP** | Sony "Allegrex" | MIPS32 R2 (+ R2 bitfield + rotates + SEB/SEH + BITREV) | **VFPU** (vector FPU, 128 32-bit regs in 8×4×4 matrices), Allegrex-specific BITREV/etc. | ⚠ Mnemonics enumerated, encodings TBD |
| **PSP Media Engine** | (second Allegrex) | same as Allegrex | same VFPU | (covered when PSP CPU is) |
| **PSV / Vita PS1-mode** | Cortex-A9 emulating R3000 | — (host is ARM) | — |  |

## Arcade and other

| Platform | CPU | Base ISA | Extension | Status |
|---|---|---|---|---|
| **SNK Hyper Neo Geo 64** | NEC VR4300 | MIPS III | none | ✅ covered |
| **Konami Hornet** (arcade) | various | MIPS-family | none | ✅ covered |
| **Sega Model 3** step 1.x | MIPS — IDT R5000 | MIPS IV | none | ✅ covered |

## Modern / embedded MIPS with vendor extensions

| Platform | CPU | Base | Extension | Status |
|---|---|---|---|---|
| **Ingenic XBurst** (Jz47xx) — old MP3/Android handhelds | XBurst | MIPS32 R2 | **MXU** (Multimedia Unit, custom SIMD), DSP ASE | 🚧 DSP enumerated, **MXU is XBurst-only** — defer |
| **Broadcom MIPS** (older routers) | bcm473x / bcm63xx | MIPS32 R2/R5 | DSP ASE common | DSP enumerated; encodings TBD |
| **Atheros / Qualcomm** (router SoC) | MIPS32 R2 | MIPS32 R2 | DSP common | as above |
| **MediaTek MIPS** (older routers) | MIPS32 R2 | MIPS32 R2 | DSP | as above |
| **Loongson 2/3** (China desktop) | Loongson | MIPS64 + custom | **Loongson MMI** (note: different from PS2 MMI!), **LSX** (128-bit), **LASX** (256-bit). Modern Loongson uses LoongArch instead. | 🚧 niche, defer |
| **Microchip PIC32** | MIPS M4K / microAptiv | MIPS32 R1/R2 + microMIPS | none | ✅ covered (microMIPS not in scope) |
| **Cavium Octeon** (server) | OCTEON | MIPS64 R2 | **OCTEON specific** (crypto, packet) | defer |

## Workstations (historical)

| Vendor | CPU | ISA | Notes |
|---|---|---|---|
| SGI Indy/Indigo/Octane/Origin | R4000/R5000/R8000/R10000/R12000/R14000 | MIPS III–IV | stock MIPS — ✅ covered |
| DEC station | R3000 / R4000 | MIPS I–III | ✅ covered |
| Various Unix workstations | MIPS family | various | ✅ covered |

## **NOT** MIPS (mentioned because users sometimes ask)

- **GBA / DS / 3DS / Switch** — ARM. Out of scope for `mips/`.
- **Sega Saturn** — dual SH-2. **Dreamcast** — SH-4. Not MIPS.
- **3DO** — ARM60. Not MIPS.
- **Atari Jaguar** — 68k + custom Tom/Jerry RISCs. Not MIPS.
- **Apple PowerBook / Macintosh** — PowerPC / Motorola 68k. Not MIPS.
- **Sega Genesis / Mega Drive** — 68000. **Sega 32X** — SH-2. **Sega CD** — 68k. Not MIPS.

## Recommended priority for `rexcode`

Given typical demand (emulation, decompiling old console games, romhacking, RE):

1. **What's done is the bulk of console value:** PS1, PS2, N64 main CPU, FPU, COP0.
2. **N64 RSP** — high value for N64 emulation/microcode work. Should be `rexcode/rsp/` (separate ISA — see below).
3. **PSP VFPU encodings** — high value for PSP emulation, completes the Allegrex story. Stays inside `mips/`.
4. **DSP ASE encodings** — useful for modern router/embedded reversing. Stays inside `mips/`.
5. **PS2 VU microcode** — distinct from MIPS (VLIW). Worth `rexcode/vu/` only if a real consumer appears.
6. **MSA encodings** — modern MIPS only; some Linux distros for MIPS workstations. Lower priority.
7. **Loongson / Octeon / MXU** — defer until someone needs them.

## Why N64 RSP wants its own subpackage

The RSP is a **subset** of MIPS (no MULT/DIV/FPU/TLB; no doubleword ops) **plus** a heavily custom COP2 vector unit. Trying to share `mips/` with it would mean:

- The shared Mnemonic enum picks up ~60 RSP-only vector ops (VMULF/VMACF/VADDC/VCH/VCL/VCR/VRCP/VRCPL/VRSQ/VRSQL/VRNDP/VRNDN/...) plus vector load/store variants (LBV/LSV/LDV/LQV/LRV/LPV/LUV/LHV/LFV/LWV/LTV + their store equivalents). Polluting the MIPS namespace.
- The RSP's COP2 encoding *collides* with PS1 GTE bit patterns (both use op=0x12 with the CO bit) so a single decode table can't disambiguate without an ISA gate.
- The RSP's vector loads encode element offset + size in the cofun bits in ways that have no MIPS analogue.

Cleaner: `rexcode/rsp/` as a sibling subpackage. It will reuse `isa/` (labels, relocs, errors, print framework) and parallel `mips/`'s shape (registers / operands / instructions / mnemonics / encoding_table / encoder / decoder / printer). Users targeting N64 import either `mips` (for the R4300 main CPU) or `rsp` (for RSP microcode) — or both, side-by-side.
