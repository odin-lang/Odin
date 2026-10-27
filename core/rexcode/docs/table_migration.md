<!-- rexcode  ·  Brendan Punsky (dotbmp@github), original author -->

# rexcode — `#load`ed Table Migration (per-arch checklist)

> Move every arch's encode/decode tables out of the compiled library and into
> committed binary blobs that the library `#load`s into `@(rodata)`. The
> hand-written `ENCODING_TABLE` stays the single source of truth; it just
> moves into a per-arch `tablegen` metaprogram that emits the blobs through a
> human-readable, type-checked intermediate.
>
> **Reference implementations:** `x86/` (CISC, variable-length, 2-D opcode
> index) and `mips/` (fixed-width bits/mask, 1-D bucket index). Read those two
> before doing a new arch — copy whichever paradigm matches.
>
> **Status (2026-06-15): all 10 arches migrated.** This doc now doubles as the
> reference for the table pipeline and for **regenerating** blobs after editing
> an `ENCODING_TABLE` (follow §3, or just the two `odin run` commands in §2).

---

## 0. Prerequisites

- **Use the in-repo compiler**, not the system `odin`. gingerBill's fix that
  lets a `bit_field`-bearing struct const-init under `@(rodata)` across a
  package boundary is in this branch's `src/` but not in master/system odin.
  Build once: `./build_odin.sh release` → use `./odin` for everything.
  (With the system odin, both the original tables *and* the moved SoT fail to
  compile with `@(rodata) must have constant initialization`.)

## 1. End state per arch

```
<arch>/
  encoding_types.odin        UNCHANGED (Encoding, enums, flags, Feature/Mode)
  mnemonics.odin             UNCHANGED
  encoder.odin               1-line edit: ENCODING_TABLE[m] -> encoding_forms(m)
  decoder.odin               x86: 2-D index -> didx(); fixed-width: NO change
  tables.odin                NEW (generated): subsidiary types + #load globals + accessors
  tables/<arch>.*.bin        NEW: committed blobs (raw packed struct images)
  tablegen/                  NEW package rexcode_<arch>_tablegen — exactly two files:
    encoding_table.odin         the SoT, moved here, byte-identical but the package clause
    gen.odin                    Stage A driver (+ package-scope aliases)
    generated/               machine-written subpackage rexcode_<arch>_generated:
      encode_tables.odin        ENCODE_FORMS + ENCODE_RUNS typed literals
      decode_tables.odin        decode entries + index tables typed literals
      writer.odin               Stage B main: serialize the globals to ../../tables/*.bin
  tools/                     gen_decode_tables.odin REMOVED; others rewritten (see §6)
  tests/                     ENCODING_TABLE references rewritten (see §6)
```

Deleted: `encoding_table.odin` (moved), `decoding_tables.odin` (now blobs),
`tools/gen_decode_tables.odin` (superseded by `tablegen/`).

## 2. The two-stage pipeline

```
ENCODING_TABLE (SoT, untouched)
  --Stage A (odin run <arch>/tablegen)-->  generated/*.odin  +  tables.odin
  --Stage B (odin run <arch>/tablegen/generated)-->  tables/<arch>.*.bin
  --#load (library build)-->  @(rodata) globals
```

Stage A emits human-readable, **type-checked** Odin (reusing gingerBill's
`print_enum_buffered`/alignment helpers); Stage B compiles those literals and
dumps their raw bytes. The compiler validates the flattened tables before they
become opaque blobs.

## 3. Step-by-step

1. `mkdir -p <arch>/tablegen/tables` (well, `<arch>/tablegen` and `<arch>/tables`).
2. `git mv <arch>/encoding_table.odin <arch>/tablegen/encoding_table.odin`.
   Change **only** its package clause → `package rexcode_<arch>_tablegen`.
   Keep `@(rodata)` and every encoding row byte-identical.
3. `git rm <arch>/decoding_tables.odin <arch>/tools/gen_decode_tables.odin`.
4. Write `<arch>/tablegen/gen.odin` (§4). It needs package-scope aliases so the
   moved SoT resolves its top-level type names:
   ```odin
   Encoding :: lib.Encoding
   Mnemonic :: lib.Mnemonic
   ```
   **Also alias any package-level constant the SoT references** — grep the SoT:
   `grep -oE "=[A-Za-z_][A-Za-z0-9_]*" tablegen/encoding_table.odin | grep -vE "=true|=false" | sort -u`
   (x86 needed `PREFIX_66/F3/F2`; mips needed none.) Bare `.ENUM` selectors and
   `{field=...}` flag literals need no alias — they infer from field types.
5. Bootstrap so the library compiles before Stage A can run (it imports the
   library for types): create empty blobs `for n in <names>; do : > tables/<arch>.$n.bin; done`
   (a 0-byte file `#load`s as a len-0 slice), and write a first `tables.odin`
   (or let Stage A overwrite a stub). Then `mkdir -p tablegen/generated`.
6. `encoder.odin`: `ENCODING_TABLE[inst.mnemonic]` → `encoding_forms(inst.mnemonic)`.
7. `decoder.odin`: **x86 only** — flatten the `[4][256]` index access
   `T[prefix][opcode]` → `didx(T, prefix, opcode)`. Fixed-width index tables are
   already 1-D, so the decoder is unchanged.
8. `odin run <arch>/tablegen` (Stage A) then `odin run <arch>/tablegen/generated`
   (Stage B). Stage A should print form/entry counts matching the old
   `decoding_tables.odin` array sizes.
9. Rewrite tool/test consumers of the (formerly public) `ENCODING_TABLE` (§6).
10. `odin run <arch>/tests` → green. Confirm idempotence (re-run Stage A+B; the
    committed files must not change).

## 4. `gen.odin` anatomy (copy from x86 or mips)

A single `BLOBS` manifest drives both the loader's `#load` lines and the
writer's dumps, so they can't drift:
```odin
Blob :: struct { global, file, typ: string }
BLOBS := [?]Blob{ {"ENCODE_FORMS","<arch>.encode_forms.bin","Encoding"}, ... }
```
Emitters:
- `emit_encode_tables` — identical on every arch: walk `ENCODING_TABLE` in
  `Mnemonic` order → `ENCODE_FORMS: [N]lib.Encoding` + `ENCODE_RUNS:
  [lib.Mnemonic]lib.Encode_Run` (run = `{start, count}` into ENCODE_FORMS).
- `emit_decode_tables` — **arch-specific**; port the bucketing from the arch's
  old `tools/gen_decode_tables.odin` (Entry struct, sort key, index ranges).
- `emit_writer` — identical: `raw(&G, size_of(G))` → `os.write_entire_file`.
- `emit_loader` — identical shape: emit the subsidiary type defs + a `#load`
  line per blob + the accessors.
Use `#directory`-relative output paths so it runs from anywhere.

`Encode_Run :: struct { start: u32, count: u32 }` (8 B; same footprint as a
padded `{u16,u16}`, no caps). The `encoding_forms`/`didx` accessors are
`@(private, require_results)` — **keep them private**; consumers outside the
package use the public `ENCODE_FORMS`/`ENCODE_RUNS` globals instead.

## 5. The three decode paradigms

| Paradigm | Arches | Index tables | decoder.odin | Reference |
|---|---|---|---|---|
| CISC variable | `x86` | 2-D `[4][256]` → load flat `[]Decode_Index`, `didx` | flatten 2-D→`didx` | **x86 (done)** |
| Fixed-width bits/mask | `arm32 arm64 mips riscv ppc ppc_vle rsp` | 1-D bucket arrays | unchanged | **mips (done)** |
| 8-bit opcode/length | `mos6502 mos65816` | 256-entry opcode→entry | unchanged | none yet — by analogy |

For fixed-width, `Decode_Entry` == `Encoding` shape, so one `write_row` helper
serves both ENCODE_FORMS and DECODE_ENTRIES. Each arch's bucket structure
differs (mips: primary + SPECIAL/REGIMM/COP1/SPECIAL2/SPECIAL3; ppc: primary
+ sub(16384) + bucket_list + form_idx; arm/riscv/rsp/ppc_vle: read their gen).

## 6. Consumers of the (formerly public) `ENCODING_TABLE`

`ENCODING_TABLE` was public API. Every `<pkg>.ENCODING_TABLE[m]` outside the
library becomes:
```odin
_run := <pkg>.ENCODE_RUNS[u16(m)]
forms := <pkg>.ENCODE_FORMS[_run.start:][:_run.count]
```
Sweep with `grep -rn "ENCODING_TABLE\[" <arch>` and hit:
- `tools/dump_verify_input.odin` (every arch), `tools/gen_mnemonic_builders.odin`
  + `tools/verify_tables.odin` (x86).
- `tests/smoke.odin`, `tests/sweep.odin`, `tests/full_sweep.odin`,
  `tests/decode_sweep.odin` (varies by arch).
Watch for two traps the recompile exposes:
- **2-D index access in tools** (x86 `verify_tables`): `T[prefix][opcode]` →
  `T[(int(prefix) << 8) | int(opcode)]` (didx is private).
- **stale field names** (mips `dump_verify_input` used `f.isa`; the field is
  `f.feature`) — pre-existing rot, just fix it.

## 7. `.gitignore`

The repo ignores `*.bin`, so blobs need a negation (added once, covers all):
```
!core/rexcode/*/tables/*.bin
```
`x86/` additionally hits the broad VS-style `x86/` rule, so it also needs
`!/core/rexcode/x86/`. No other arch needs the directory negation.

## 8. Tests — pre-existing bugs the suite hits once it runs further

Only **x86** JIT-executes its encoded output, so only x86 needed these (both
fixed in the x86 pass; reuse if another arch adds execution):
- `tests/test.odin alloc_exec` mapped memory R/W only on Linux — add
  `virtual.protect(..., {.Read,.Write,.Execute})` so the page is executable.
- `printer.odin` dereferenced a nil `label_names` (`label_names^[k]`); guard
  `if label_names != nil`. Check each arch's printer for the same pattern.

## 9. Done-criteria per arch

- `<arch>/` contains `tables.odin` and **no** `encoding_table.odin` /
  `decoding_tables.odin`; `tablegen/` has exactly `encoding_table.odin` + `gen.odin`.
- Stage A counts == old `decoding_tables.odin` array sizes; Stage B blob sizes
  == count × `size_of(struct)`.
- `odin run <arch>/tests` green; all `tools/*.odin` compile (`odin build T.odin -file`).
- Re-running Stage A+B produces no diff (idempotent).

> `doc.odin`, `cross_arch_design.md`, and `x86_api.md` were updated to this
> layout when the migration completed.
