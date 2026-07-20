// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//
// Regression tests for narrow-width (8/16-bit) operand-size encoding.
//
// These lock in three encoder fixes:
//
//   1. MOVSX/MOVZX derived the 66h operand-size prefix from the *source* operand
//      instead of the destination, so `movsx eax, ax` was mis-encoded as
//      `movsx ax, ax` (66 0F BF C0 instead of 0F BF C0). These are widening
//      moves: the source r/m width is fixed by the opcode and must NOT drive the
//      operand-size prefix -- only the destination does.
//
//   2/3. CBW/CWD and the 16-bit string ops (MOVSW/CMPSW/SCASW/LODSW/STOSW) carry
//      no GPR16 operand to trigger the operand-size prefix, so they emitted no
//      66h and aliased their 32-bit siblings (CBW==CWDE, CWD==CDQ, MOVSW==MOVSD,
//      ...). This broke, e.g., 16-bit signed division (CWD -> CDQ sign-extends
//      the wrong width). They now carry an explicit `opsize_16` encoding flag.
//
// Every expected byte string below is llvm-mc ground truth
// (`llvm-mc -triple=x86_64 --show-encoding`). CRC32 is included as a guard: it
// legitimately takes 66h from a 16-bit *source*, so the MOVSX fix must not touch
// it.

package rexcode_x86_tests

import x86 "../"
import "core:fmt"

@(private="file")
Case :: struct {
	name:   string,
	inst:   x86.Instruction,
	expect: []u8,
}

@(private="file")
bytes_equal :: proc(a, b: []u8) -> bool {
	if len(a) != len(b) { return false }
	for i in 0 ..< len(a) { if a[i] != b[i] { return false } }
	return true
}

@(private="file")
hexs :: proc(b: []u8) -> string {
	s: string
	for x, i in b { s = fmt.tprintf("%s%s%02X", s, i > 0 ? " " : "", x) }
	return s
}

// Byte-exact single-instruction encode assertion. Rolls into the shared suite
// stats (g_stats) exactly like run_test, so it shows up in the final summary.
@(private="file")
expect_encoding :: proc(name: string, inst: x86.Instruction, expected: []u8) {
	code:   [16]u8
	relocs: [dynamic]x86.Relocation
	errs:   [dynamic]x86.Error
	defer delete(relocs)
	defer delete(errs)

	insts := []x86.Instruction{inst}
	n, ok := x86.encode(insts, nil, code[:], &relocs, &errs)
	got := code[:n]

	if !ok {
		fmt.printf("%s[FAIL]%s %s - encode failed\n", RED, RESET, name)
		g_stats.failed += 1
		return
	}
	if !bytes_equal(got, expected) {
		fmt.printf("%s[FAIL]%s %s - got [%s] want [%s]\n", RED, RESET, name, hexs(got), hexs(expected))
		g_stats.failed += 1
		return
	}
	g_stats.passed += 1
}

@(private="file")
rep_of :: proc(mnemonic: x86.Mnemonic, rep: x86.Rep) -> x86.Instruction {
	inst := x86.inst_none(mnemonic)
	inst.flags.rep = rep
	return inst
}

run_narrow_width_encoding_tests :: proc() {
	before := g_stats.failed

	// --- MOVSX / MOVZX: operand size is the DESTINATION, not the source (fix 1) ---
	// 16-bit register source with a wider destination: must NOT emit 66h.
	expect_encoding("movsx eax, ax",     x86.inst_r_r(.MOVSX, x86.EAX,  x86.AX),   {0x0F, 0xBF, 0xC0})
	expect_encoding("movsx rax, bx",     x86.inst_r_r(.MOVSX, x86.RAX,  x86.BX),   {0x48, 0x0F, 0xBF, 0xC3})
	expect_encoding("movsx r10d, r11w",  x86.inst_r_r(.MOVSX, x86.R10D, x86.R11W), {0x45, 0x0F, 0xBF, 0xD3})
	expect_encoding("movzx eax, bx",     x86.inst_r_r(.MOVZX, x86.EAX,  x86.BX),   {0x0F, 0xB7, 0xC3})
	expect_encoding("movzx rax, bx",     x86.inst_r_r(.MOVZX, x86.RAX,  x86.BX),   {0x48, 0x0F, 0xB7, 0xC3})
	expect_encoding("movzx r8d, r9w",    x86.inst_r_r(.MOVZX, x86.R8D,  x86.R9W),  {0x45, 0x0F, 0xB7, 0xC1})
	// 16-bit destination: SHOULD still emit 66h (unchanged behavior).
	expect_encoding("movsx ax, bl",      x86.inst_r_r(.MOVSX, x86.AX,   x86.BL),   {0x66, 0x0F, 0xBE, 0xC3})
	expect_encoding("movzx ax, bl",      x86.inst_r_r(.MOVZX, x86.AX,   x86.BL),   {0x66, 0x0F, 0xB6, 0xC3})
	// 8-bit source, wider dest: no 66h (unchanged behavior).
	expect_encoding("movsx eax, bl",     x86.inst_r_r(.MOVSX, x86.EAX,  x86.BL),   {0x0F, 0xBE, 0xC3})
	expect_encoding("movsx rax, bl",     x86.inst_r_r(.MOVSX, x86.RAX,  x86.BL),   {0x48, 0x0F, 0xBE, 0xC3})
	expect_encoding("movzx eax, bl",     x86.inst_r_r(.MOVZX, x86.EAX,  x86.BL),   {0x0F, 0xB6, 0xC3})
	// 16-bit MEMORY source with wider dest: already correct (no GPR16), guard it.
	expect_encoding("movsx eax, word [rax]", x86.inst_r_m(.MOVSX, x86.EAX, x86.mem_base_disp(x86.RAX, 0), 2), {0x0F, 0xBF, 0x00})
	expect_encoding("movsx rax, word [rbx]", x86.inst_r_m(.MOVSX, x86.RAX, x86.mem_base_disp(x86.RBX, 0), 2), {0x48, 0x0F, 0xBF, 0x03})
	expect_encoding("movzx eax, byte [rbx]", x86.inst_r_m(.MOVZX, x86.EAX, x86.mem_base_disp(x86.RBX, 0), 1), {0x0F, 0xB6, 0x03})
	// MOVSXD (source is always 32-bit; never a 16-bit trap): guard.
	expect_encoding("movsxd rax, ebx",   x86.inst_r_r(.MOVSXD, x86.RAX, x86.EBX),  {0x48, 0x63, 0xC3})

	// --- CBW/CWD (fix 2): 16-bit variants must carry 66h; 32/64 unchanged ---
	expect_encoding("cbw",  x86.inst_none(.CBW),  {0x66, 0x98})
	expect_encoding("cwde", x86.inst_none(.CWDE), {0x98})
	expect_encoding("cdqe", x86.inst_none(.CDQE), {0x48, 0x98})
	expect_encoding("cwd",  x86.inst_none(.CWD),  {0x66, 0x99})
	expect_encoding("cdq",  x86.inst_none(.CDQ),  {0x99})
	expect_encoding("cqo",  x86.inst_none(.CQO),  {0x48, 0x99})

	// --- 16-bit string ops (fix 3): 66h; 32/64 siblings and 8-bit unchanged ---
	expect_encoding("movsw", x86.inst_none(.MOVSW), {0x66, 0xA5})
	expect_encoding("movsd", x86.inst_none(.MOVSD), {0xA5})
	expect_encoding("movsq", x86.inst_none(.MOVSQ), {0x48, 0xA5})
	expect_encoding("movsb", x86.inst_none(.MOVSB), {0xA4})
	expect_encoding("cmpsw", x86.inst_none(.CMPSW), {0x66, 0xA7})
	expect_encoding("cmpsd", x86.inst_none(.CMPSD), {0xA7})
	expect_encoding("cmpsb", x86.inst_none(.CMPSB), {0xA6})
	expect_encoding("scasw", x86.inst_none(.SCASW), {0x66, 0xAF})
	expect_encoding("scasd", x86.inst_none(.SCASD), {0xAF})
	expect_encoding("lodsw", x86.inst_none(.LODSW), {0x66, 0xAD})
	expect_encoding("lodsd", x86.inst_none(.LODSD), {0xAD})
	expect_encoding("stosw", x86.inst_none(.STOSW), {0x66, 0xAB})
	expect_encoding("stosd", x86.inst_none(.STOSD), {0xAB})

	// REP/REPNE-prefixed 16-bit string ops go through the interpreter path (not
	// the recipe fast path); prefix order must be group-1 then 66h.
	expect_encoding("rep movsw",   rep_of(.MOVSW, .REP),   {0xF3, 0x66, 0xA5})
	expect_encoding("rep stosw",   rep_of(.STOSW, .REP),   {0xF3, 0x66, 0xAB})
	expect_encoding("repne scasw", rep_of(.SCASW, .REPNE), {0xF2, 0x66, 0xAF})

	// --- CRC32 guard: 66h legitimately comes from the 16-bit SOURCE here, so the
	// MOVSX fix must leave this alone. ---
	expect_encoding("crc32 eax, bl",  x86.inst_r_r(.CRC32, x86.EAX, x86.BL),  {0xF2, 0x0F, 0x38, 0xF0, 0xC3})
	expect_encoding("crc32 rax, bl",  x86.inst_r_r(.CRC32, x86.RAX, x86.BL),  {0xF2, 0x48, 0x0F, 0x38, 0xF0, 0xC3})
	expect_encoding("crc32 eax, bx",  x86.inst_r_r(.CRC32, x86.EAX, x86.BX),  {0x66, 0xF2, 0x0F, 0x38, 0xF1, 0xC3})
	expect_encoding("crc32 eax, ebx", x86.inst_r_r(.CRC32, x86.EAX, x86.EBX), {0xF2, 0x0F, 0x38, 0xF1, 0xC3})
	expect_encoding("crc32 rax, rbx", x86.inst_r_r(.CRC32, x86.RAX, x86.RBX), {0xF2, 0x48, 0x0F, 0x38, 0xF1, 0xC3})

	// --- POPCNT/LZCNT/TZCNT: F3-mandatory with a 16-bit operand -> 66 F3 (the
	// operand-size 66h stacks with the mandatory F3; verifies encode + prefix order) ---
	expect_encoding("popcnt ax, bx",   x86.inst_r_r(.POPCNT, x86.AX,  x86.BX),  {0x66, 0xF3, 0x0F, 0xB8, 0xC3})
	expect_encoding("popcnt eax, ebx", x86.inst_r_r(.POPCNT, x86.EAX, x86.EBX), {0xF3, 0x0F, 0xB8, 0xC3})
	expect_encoding("popcnt rax, rbx", x86.inst_r_r(.POPCNT, x86.RAX, x86.RBX), {0xF3, 0x48, 0x0F, 0xB8, 0xC3})
	expect_encoding("lzcnt ax, bx",    x86.inst_r_r(.LZCNT,  x86.AX,  x86.BX),  {0x66, 0xF3, 0x0F, 0xBD, 0xC3})
	expect_encoding("tzcnt ax, bx",    x86.inst_r_r(.TZCNT,  x86.AX,  x86.BX),  {0x66, 0xF3, 0x0F, 0xBC, 0xC3})

	// --- IRET / PUSHF / POPF: operand-less 16-bit forms (like CBW) -> 66h ---
	expect_encoding("iret",   x86.inst_none(.IRET),   {0x66, 0xCF})
	expect_encoding("iretd",  x86.inst_none(.IRETD),  {0xCF})
	expect_encoding("iretq",  x86.inst_none(.IRETQ),  {0x48, 0xCF})
	expect_encoding("pushf",  x86.inst_none(.PUSHF),  {0x66, 0x9C})
	expect_encoding("pushfq", x86.inst_none(.PUSHFQ), {0x9C})
	expect_encoding("popf",   x86.inst_none(.POPF),   {0x66, 0x9D})
	expect_encoding("popfq",  x86.inst_none(.POPFQ),  {0x9D})

	// --- LOCK prefix as a standalone mnemonic; PUSH/POP FS/GS (segment fixed by
	// the opcode); ENTER (two immediates: IMM16 then IMM8). ---
	expect_encoding("lock",    x86.inst_none(.LOCK),        {0xF0})
	expect_encoding("push fs", x86.inst_r(.PUSH, x86.FS),   {0x0F, 0xA0})
	expect_encoding("push gs", x86.inst_r(.PUSH, x86.GS),   {0x0F, 0xA8})
	expect_encoding("pop fs",  x86.inst_r(.POP,  x86.FS),   {0x0F, 0xA1})
	expect_encoding("pop gs",  x86.inst_r(.POP,  x86.GS),   {0x0F, 0xA9})
	enter_8_0 := x86.Instruction{ mnemonic = .ENTER, operand_count = 2 }
	enter_8_0.ops[0] = x86.Operand{kind = .IMMEDIATE, immediate = 8, size = 2}
	enter_8_0.ops[1] = x86.Operand{kind = .IMMEDIATE, immediate = 0, size = 1}
	expect_encoding("enter 8,0", enter_8_0, {0xC8, 0x08, 0x00, 0x00})

	// --- RDRAND/RDSEED: r16 stacks 66h on the mandatory-prefix-less 0F C7 /6,/7
	// (the 66 here is operand-size, NOT the mandatory 66 of VMCLEAR at the same
	// opcode -- the register ModR/M distinguishes them). ---
	expect_encoding("rdrand ax",  x86.inst_r(.RDRAND, x86.AX),  {0x66, 0x0F, 0xC7, 0xF0})
	expect_encoding("rdrand eax", x86.inst_r(.RDRAND, x86.EAX), {0x0F, 0xC7, 0xF0})
	expect_encoding("rdrand rax", x86.inst_r(.RDRAND, x86.RAX), {0x48, 0x0F, 0xC7, 0xF0})
	expect_encoding("rdseed ax",  x86.inst_r(.RDSEED, x86.AX),  {0x66, 0x0F, 0xC7, 0xF8})
	expect_encoding("rdseed eax", x86.inst_r(.RDSEED, x86.EAX), {0x0F, 0xC7, 0xF8})

	failed := g_stats.failed - before
	if failed == 0 {
		fmt.printf("%s[PASS]%s narrow-width encodings (all byte-exact vs llvm-mc)\n", GREEN, RESET)
	}
}

// Byte-level round-trip: encode -> decode -> re-encode must reproduce the exact
// bytes. Alias-immune (aliases share bytes), so it directly guards the decoder's
// operand-size / mandatory-prefix disambiguation for the size-variant forms and
// the F2/F3-mandatory ops (which previously mis-decoded or doubled their prefix).
@(private="file")
expect_roundtrip :: proc(name: string, inst: x86.Instruction) {
	code1: [16]u8
	r1: [dynamic]x86.Relocation; e1: [dynamic]x86.Error
	defer delete(r1); defer delete(e1)
	insts := []x86.Instruction{inst}
	n1, ok1 := x86.encode(insts, nil, code1[:], &r1, &e1)
	if !ok1 || n1 == 0 {
		fmt.printf("%s[FAIL]%s %s - encode failed\n", RED, RESET, name); g_stats.failed += 1; return
	}

	di: [dynamic]x86.Instruction; info: [dynamic]x86.Instruction_Info
	dl: [dynamic]x86.Label_Definition; de: [dynamic]x86.Error
	defer delete(di); defer delete(info); defer delete(dl); defer delete(de)
	norels: []x86.Relocation
	x86.decode(code1[:n1], norels, &di, &info, &dl, &de)
	if len(di) != 1 {
		fmt.printf("%s[FAIL]%s %s - decoded %d instructions (want 1) from [%s]\n",
			RED, RESET, name, len(di), hexs(code1[:n1])); g_stats.failed += 1; return
	}

	code2: [16]u8
	r2: [dynamic]x86.Relocation; e2: [dynamic]x86.Error
	defer delete(r2); defer delete(e2)
	insts2 := []x86.Instruction{di[0]}
	n2, ok2 := x86.encode(insts2, nil, code2[:], &r2, &e2)
	if !ok2 || !bytes_equal(code1[:n1], code2[:n2]) {
		fmt.printf("%s[FAIL]%s %s - round-trip [%s] -> %v -> [%s]\n",
			RED, RESET, name, hexs(code1[:n1]), di[0].mnemonic, hexs(code2[:n2])); g_stats.failed += 1; return
	}
	g_stats.passed += 1
}

run_narrow_width_roundtrip_tests :: proc() {
	before := g_stats.failed
	cases := []Case{
		// Operand-less size variants: decode must select by 66h/REX.W state (not by
		// peeking a nonexistent ModR/M) and honor the mode default (PUSHFQ/POPFQ).
		{"cbw",  x86.inst_none(.CBW),  {}}, {"cwde", x86.inst_none(.CWDE), {}}, {"cdqe", x86.inst_none(.CDQE), {}},
		{"cwd",  x86.inst_none(.CWD),  {}}, {"cdq",  x86.inst_none(.CDQ),  {}}, {"cqo",  x86.inst_none(.CQO),  {}},
		{"iret", x86.inst_none(.IRET), {}}, {"iretd", x86.inst_none(.IRETD), {}}, {"iretq", x86.inst_none(.IRETQ), {}},
		{"pushf", x86.inst_none(.PUSHF), {}}, {"pushfq", x86.inst_none(.PUSHFQ), {}},
		{"popf",  x86.inst_none(.POPF),  {}}, {"popfq",  x86.inst_none(.POPFQ),  {}},
		{"movsw", x86.inst_none(.MOVSW), {}}, {"movsd", x86.inst_none(.MOVSD), {}}, {"movsq", x86.inst_none(.MOVSQ), {}},
		{"stosw", x86.inst_none(.STOSW), {}}, {"scasw", x86.inst_none(.SCASW), {}},
		// Mandatory F2/F3 + operand size: decode must keep the right opcode (not
		// alias to MOVBE/BSR/BSF), pick the right width, and NOT re-emit F2/F3 as REP.
		{"popcnt ax,bx",   x86.inst_r_r(.POPCNT, x86.AX,  x86.BX),  {}},
		{"popcnt eax,ebx", x86.inst_r_r(.POPCNT, x86.EAX, x86.EBX), {}},
		{"popcnt rax,rbx", x86.inst_r_r(.POPCNT, x86.RAX, x86.RBX), {}},
		{"lzcnt ax,bx",    x86.inst_r_r(.LZCNT,  x86.AX,  x86.BX),  {}},
		{"tzcnt ax,bx",    x86.inst_r_r(.TZCNT,  x86.AX,  x86.BX),  {}},
		{"crc32 eax,bl",   x86.inst_r_r(.CRC32,  x86.EAX, x86.BL),  {}},
		{"crc32 eax,bx",   x86.inst_r_r(.CRC32,  x86.EAX, x86.BX),  {}},
		{"crc32 eax,ebx",  x86.inst_r_r(.CRC32,  x86.EAX, x86.EBX), {}},
		{"crc32 rax,rbx",  x86.inst_r_r(.CRC32,  x86.RAX, x86.RBX), {}},

		// --- x87: ST(i) register forms, fixed no-operand forms, and constants ---
		{"fadd st0,st1", x86.inst_r_r(.FADD, x86.ST0, x86.ST1), {}},
		{"fmul st0,st3", x86.inst_r_r(.FMUL, x86.ST0, x86.ST3), {}},
		{"fxch st2",     x86.inst_r(.FXCH, x86.ST2), {}},
		{"fnop",  x86.inst_none(.FNOP),  {}},
		{"fchs",  x86.inst_none(.FCHS),  {}},
		{"fcos",  x86.inst_none(.FCOS),  {}},   // D9 FF: fixed byte 0xFF (sentinel collision)
		{"fldz",  x86.inst_none(.FLDZ),  {}},
		{"fsqrt", x86.inst_none(.FSQRT), {}},

		// --- fixed-ModR/M system / control ops (0F 01 / 0F AE / 0F 1E groups) ---
		{"vmcall",  x86.inst_none(.VMCALL),  {}},
		{"rdtscp",  x86.inst_none(.RDTSCP),  {}},
		{"xgetbv",  x86.inst_none(.XGETBV),  {}},
		{"lfence",  x86.inst_none(.LFENCE),  {}},
		{"mfence",  x86.inst_none(.MFENCE),  {}},
		{"endbr64", x86.inst_none(.ENDBR64), {}},

		// --- MOV to/from control & debug registers (decoded as CR/DR, not GPR) ---
		{"mov rax,cr0", x86.inst_r_r(.MOV, x86.RAX, x86.CR0), {}},
		{"mov cr0,rax", x86.inst_r_r(.MOV, x86.CR0, x86.RAX), {}},
		{"mov rax,dr0", x86.inst_r_r(.MOV, x86.RAX, x86.DR0), {}},

		// --- accumulator short forms (decode leaves the accumulator implicit) ---
		{"add al,5",       x86.inst_r_i(.ADD, x86.AL,  5,      1), {}},
		{"add eax,100000", x86.inst_r_i(.ADD, x86.EAX, 100000, 4), {}},
		{"test al,5",      x86.inst_r_i(.TEST, x86.AL, 5,      1), {}},

		// --- NOP vs XCHG rax,rax / xchg ax,ax (0x90 disambiguation) ---
		{"nop",         x86.inst_none(.NOP),                  {}},
		{"xchg rax,rax", x86.inst_r_r(.XCHG, x86.RAX, x86.RAX), {}},
		{"xchg ax,ax",   x86.inst_r_r(.XCHG, x86.AX,  x86.AX),  {}},

		// LOCK prefix standalone; PUSH/POP FS vs GS (opcode-fixed segment).
		{"lock",    x86.inst_none(.LOCK),      {}},
		{"push fs", x86.inst_r(.PUSH, x86.FS), {}},
		{"push gs", x86.inst_r(.PUSH, x86.GS), {}},
		{"pop fs",  x86.inst_r(.POP,  x86.FS), {}},
		{"pop gs",  x86.inst_r(.POP,  x86.GS), {}},

		// RDRAND/RDSEED r16/r32/r64 (66-operand-size vs 66-mandatory VMCLEAR).
		{"rdrand ax",  x86.inst_r(.RDRAND, x86.AX),  {}},
		{"rdrand eax", x86.inst_r(.RDRAND, x86.EAX), {}},
		{"rdrand rax", x86.inst_r(.RDRAND, x86.RAX), {}},
		{"rdseed ax",  x86.inst_r(.RDSEED, x86.AX),  {}},
		{"rdseed eax", x86.inst_r(.RDSEED, x86.EAX), {}},
	}
	for c in cases { expect_roundtrip(c.name, c.inst) }

	// ENTER carries two immediates (IMM16, IMM8); built directly.
	enter := x86.Instruction{ mnemonic = .ENTER, operand_count = 2 }
	enter.ops[0] = x86.Operand{kind = .IMMEDIATE, immediate = 8, size = 2}
	enter.ops[1] = x86.Operand{kind = .IMMEDIATE, immediate = 0, size = 1}
	expect_roundtrip("enter 8,0", enter)
	if g_stats.failed == before {
		fmt.printf("%s[PASS]%s narrow-width round-trips (encode->decode->encode stable)\n", GREEN, RESET)
	}
}

// End-to-end proof: a 16-bit signed division. This is exactly what the sigil
// backend reported broken -- it needs CWD to sign-extend AX into DX:AX before
// `idiv r/m16`, then MOVSX to widen the quotient for the 64-bit return. With the
// pre-fix encoder, CWD emitted as CDQ (sign-extending the wrong width) and
// `movsx rax, ax` picked up a stray 66h, so the results were wrong. If either
// fix regresses, these cases fail (or fault).
run_narrow_width_exec_tests :: proc() {
	run_test(Test{
		name = "16-bit signed idiv via CWD + MOVSX (11 cases)",
		instructions = {
			x86.inst_r_r(.MOV, x86.AX, x86.DI),      // ax = (i16)dividend
			x86.inst_none(.CWD),                     // dx:ax = sign_extend(ax)   [fix 2]
			x86.inst_r(.IDIV, x86.SI),               // ax = dx:ax / si  (signed 16-bit)
			x86.inst_r_r(.MOVSX, x86.RAX, x86.AX),   // rax = (i64)(i16)ax        [fix 1]
			x86.inst_none(.RET),
		},
		test_type = .R64R64_R64,
		cases = {
			case_ii(-100,   7,  -14),
			case_ii( 100,   7,   14),
			case_ii(-100,  -7,   14),
			case_ii( 100,  -7,  -14),
			case_ii( 32000, 3,  10666),
			case_ii(-32000, 3, -10666),
			case_ii( 32767, 3,  10922),
			case_ii(-32768, 7,  -4681),
			case_ii( 7,     3,   2),
			case_ii( 1,     1,   1),
			case_ii(-1,    -1,   1),
		},
	})
}
