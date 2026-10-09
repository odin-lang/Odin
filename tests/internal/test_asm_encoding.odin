#+build amd64
package test_internal

import "core:sys/info"
import "core:testing"

// A spread of mnemonics and operand shapes, so both backends must agree on the encoding
// and on where the operands live: the fast backend encodes these itself.

@(test)
asm_encoding_integer :: proc(t: ^testing.T) {
	add_imm   :: asm(a: u64) -> (r: u64) [a -> r] { add r, 1000 }
	sub_imm8  :: asm(a: i32) -> (r: i32) [a -> r] { sub r, -3 }
	imul3     :: asm(a: i64) -> (r: i64) { imul r, a, 37 }
	movabs    :: asm() -> (r: u64) { mov r, 0x1122334455667788 }
	shl_imm   :: asm(a: u64) -> (r: u64) [a -> r] { shl r, 13 }
	sar_poly  :: asm(a: i64, $n: u8) -> (r: i64) [a -> r] { sar r, n }
	ror32     :: asm(a: u32) -> (r: u32) [a -> r] { ror r, 8 }
	bswap64   :: asm(a: u64) -> (r: u64) [a -> r] { bswap r }
	not16     :: asm(a: u16) -> (r: u16) [a -> r] { not r }
	add16     :: asm(a: u16, b: u16) -> (r: u16) [a -> r] { add r, b }
	xor8      :: asm(a: u8, b: u8) -> (r: u8) [a -> r] { xor r, b }
	neg64     :: asm(a: i64) -> (r: i64) [a -> r] { neg r }
	lea3      :: asm(a: u64, b: u64) -> (r: u64) { lea r, [a + b*4 + 100] }
	cmov      :: asm(a: u64, b: u64) -> (r: u64) { mov r, a; cmp a, b; cmovb r, b }
	bsr64     :: asm(a: u64) -> (r: u64) { bsr r, a }
	popcnt64  :: asm(a: u64) -> (r: u64) { popcnt r, a }
	tzcnt32   :: asm(a: u32) -> (r: u32) { tzcnt r, a }
	andn64    :: asm(a: u64, b: u64) -> (r: u64) { andn r, a, b }
	xchg64    :: asm(a: u64, b: u64) -> (x: u64, y: u64) [a -> x, b -> y] { xchg x, y }
	ext_8_64  :: asm(a: i8) -> (r: i64) { movsx r, a }

	testing.expect_value(t, add_imm(5), u64(1005))
	testing.expect_value(t, sub_imm8(5), i32(8))
	testing.expect_value(t, imul3(-3), i64(-111))
	testing.expect_value(t, movabs(), u64(0x1122334455667788))
	testing.expect_value(t, shl_imm(3), u64(3 << 13))
	testing.expect_value(t, sar_poly(-1024, 3), i64(-128))
	testing.expect_value(t, ror32(0x11223344), u32(0x44112233))
	testing.expect_value(t, bswap64(0x0102030405060708), u64(0x0807060504030201))
	testing.expect_value(t, not16(0x00FF), u16(0xFF00))
	testing.expect_value(t, add16(0xFFFF, 2), u16(1))
	testing.expect_value(t, xor8(0xF0, 0x3C), u8(0xCC))
	testing.expect_value(t, neg64(42), i64(-42))
	testing.expect_value(t, lea3(1, 2), u64(109))
	testing.expect_value(t, cmov(10, 20), u64(20))
	testing.expect_value(t, cmov(30, 20), u64(30))
	testing.expect_value(t, bsr64(1 << 40), u64(40))
	testing.expect_value(t, popcnt64(0xFF00FF), u64(16))
	testing.expect_value(t, tzcnt32(0x80), u32(7))
	testing.expect_value(t, andn64(0x0F, 0xFF), u64(0xF0))
	x, y := xchg64(1, 2)
	testing.expect_value(t, x, u64(2))
	testing.expect_value(t, y, u64(1))
	testing.expect_value(t, ext_8_64(-5), i64(-5))
}

@(test)
asm_encoding_memory :: proc(t: ^testing.T) {
	load_off   :: asm(p: ^u64) -> (r: u64) { mov r, [p + 8] }
	load_idx   :: asm(p: [^]u32, i: u64) -> (r: u32) { mov r, [p + i*4] }
	load_shift :: asm(p: [^]u64, i: u64) -> (r: u64) { mov r, [p + i<<3 - 8] }
	store      :: asm(p: ^u64, v: u64) { mov [p], v }
	store16    :: asm(p: ^u16) { mov [p]:u16, 0x1234 }
	add_mem    :: asm(p: ^u32, v: u32) { add [p], v }
	inc_mem8   :: asm(p: ^u8) { inc [p]:u8 }
	xadd_lock  :: asm(p: ^u64, v: u64) -> (old: u64) [v -> old] { lock; xadd [p], old }
	far_disp   :: asm(p: [^]u8) -> (r: u8) { mov r, [p + 1000] }

	a := [4]u64{1, 2, 3, 4}
	testing.expect_value(t, load_off(&a[0]), u64(2))
	b := [4]u32{10, 20, 30, 40}
	testing.expect_value(t, load_idx(raw_data(b[:]), 3), u32(40))
	testing.expect_value(t, load_shift(raw_data(a[:]), 2), u64(2))
	store(&a[1], 99)
	testing.expect_value(t, a[1], u64(99))
	h: u16
	store16(&h)
	testing.expect_value(t, h, u16(0x1234))
	add_mem(&b[0], 5)
	testing.expect_value(t, b[0], u32(15))
	c: u8 = 255
	inc_mem8(&c)
	testing.expect_value(t, c, u8(0))
	n: u64 = 7
	testing.expect_value(t, xadd_lock(&n, 3), u64(7))
	testing.expect_value(t, n, u64(10))
	buf: [1024]u8
	buf[1000] = 77
	testing.expect_value(t, far_disp(raw_data(buf[:])), u8(77))
}

@(test)
asm_encoding_vector :: proc(t: ^testing.T) {
	addss0  :: asm(a: f32, b: f32) -> (r: f32) [a -> r] { addss r, b }
	sqrtsd0 :: asm(a: f64) -> (r: f64) { sqrtsd r, a }
	addps0  :: asm(a: #simd[4]f32, b: #simd[4]f32) -> (r: #simd[4]f32) [a -> r] { addps r, b }
	shufps0 :: asm(a: #simd[4]f32) -> (r: #simd[4]f32) [a -> r] { shufps r, r, 0x1B }
	pshufd0 :: asm(a: #simd[4]u32) -> (r: #simd[4]u32) { pshufd r, a, 0x1B }
	cvt     :: asm(a: i64) -> (r: f64) { cvtsi2sd r, a }
	cvtt    :: asm(a: f64) -> (r: i64) { cvttsd2si r, a }
	movq0   :: asm(a: u64) -> (r: #simd[2]u64) { movq r, a }

	vadd3   :: asm(a: #simd[4]f32, b: #simd[4]f32) -> (r: #simd[4]f32) { vaddps r, a, b }
	vfma    :: asm(a: #simd[4]f32, b: #simd[4]f32, c: #simd[4]f32) -> (r: #simd[4]f32) [a -> r] { vfmadd231ps r, b, c }
	vblend  :: asm(a: #simd[4]f32, b: #simd[4]f32, m: #simd[4]f32) -> (r: #simd[4]f32) { vblendvps r, a, b, m }

	testing.expect_value(t, addss0(1.5, 2), f32(3.5))
	testing.expect_value(t, sqrtsd0(16), f64(4))
	testing.expect_value(t, addps0({1, 2, 3, 4}, {10, 20, 30, 40}), #simd[4]f32{11, 22, 33, 44})
	testing.expect_value(t, shufps0({1, 2, 3, 4}), #simd[4]f32{4, 3, 2, 1})
	testing.expect_value(t, pshufd0({1, 2, 3, 4}), #simd[4]u32{4, 3, 2, 1})
	testing.expect_value(t, cvt(-7), f64(-7))
	testing.expect_value(t, cvtt(-7.9), i64(-7))
	testing.expect_value(t, movq0(0xABCD), #simd[2]u64{0xABCD, 0})
	testing.expect_value(t, vadd3({1, 2, 3, 4}, {1, 1, 1, 1}), #simd[4]f32{2, 3, 4, 5})
	testing.expect_value(t, vfma(1, 2, 3), #simd[4]f32{7, 7, 7, 7})
	testing.expect_value(t, vblend({1, 2, 3, 4}, {5, 6, 7, 8}, {-1, 0, -1, 0}), #simd[4]f32{5, 2, 7, 4})
}

@(test)
asm_encoding_pinned :: proc(t: ^testing.T) {
	cpuid0 :: asm(leaf: u32, sub: u32) -> (a: u32, b: u32, c: u32, d: u32) [leaf -> a = %eax, sub -> c = %ecx, b = %ebx, d = %edx] { cpuid }
	rdtsc0 :: asm() -> (lo: u32, hi: u32) [lo = %eax, hi = %edx, #volatile] { rdtsc }
	divmod :: asm(lo: u64, hi: u64, d: u64) -> (q: u64, r: u64) [lo -> q = %rax, hi -> r = %rdx] { div d }
	wide   :: asm(a: u64, b: u64) -> (lo: u64, hi: u64) [a -> lo = %rax, hi = %rdx] { mul b }
	copy   :: asm(dst: rawptr, src: rawptr, n: u64) [dst = %rdi, src = %rsi, n = %rcx, #clobber %rdi, #clobber %rsi, #clobber %rcx, #clobber memory] { cld; rep; movsb }
	via_rbx :: asm(a: u64, b: u64) -> (r: u64) [#clobber %rbx] { mov %rbx, a; add %rbx, b; mov r, %rbx }
	pushpop :: asm(a: u64) -> (r: u64) { push a; pop r }

	a, b, c, d := cpuid0(0, 0)
	testing.expect(t, a > 0)
	// the vendor string is the same through either backend
	testing.expect(t, b != 0 && c != 0 && d != 0)
	lo, hi := rdtsc0()
	testing.expect(t, lo != 0 || hi != 0)
	q, r := divmod(100, 0, 7)
	testing.expect_value(t, q, u64(14))
	testing.expect_value(t, r, u64(2))
	l, h := wide(1 << 63, 4)
	testing.expect_value(t, l, u64(0))
	testing.expect_value(t, h, u64(2))
	src := [5]u8{1, 2, 3, 4, 5}
	dst: [5]u8
	copy(&dst, &src, 5)
	testing.expect_value(t, dst, src)
	testing.expect_value(t, via_rbx(40, 2), u64(42))
	testing.expect_value(t, pushpop(1234), u64(1234))
}

@(test)
asm_encoding_flags_scratch :: proc(t: ^testing.T) {
	is_zero  :: asm(a: u64) -> (z: bool) [z = %flags.z] { test a, a }
	carry    :: asm(a: u64, b: u64) -> (s: u64, c: bool) [a -> s, c = %flags.c] { add s, b }
	sign     :: asm(a: i32) -> (s: bool) [s = %flags.s] { cmp a, 0 }
	triple   :: asm(a: u64) -> (r: u64) [t0: u64, t1: u64] { mov t0, a; mov t1, a; add t0, t1; add t0, a; mov r, t0 }
	low_byte :: asm(a: u64) -> (r: u64) [a8: u8 = a] { movzx r, a8 }
	setb     :: asm(a: u64, b: u64) -> (r: u8) { cmp a, b; setb r }

	testing.expect_value(t, is_zero(0), true)
	testing.expect_value(t, is_zero(1), false)
	s, c := carry(max(u64), 2)
	testing.expect_value(t, s, u64(1))
	testing.expect_value(t, c, true)
	testing.expect_value(t, sign(-1), true)
	testing.expect_value(t, sign(1), false)
	testing.expect_value(t, triple(5), u64(15))
	testing.expect_value(t, low_byte(0x1234), u64(0x34))
	testing.expect_value(t, setb(1, 2), u8(1))
	testing.expect_value(t, setb(2, 1), u8(0))
}

@(test)
asm_encoding_many_operands :: proc(t: ^testing.T) {
	// more operands than caller saved registers, so callee saved ones are used too
	sum12 :: asm(a: u64, b: u64, c: u64, d: u64, e: u64, f: u64, g: u64, h: u64, i: u64, j: u64, k: u64) -> (r: u64) {
		mov r, a; add r, b; add r, c; add r, d; add r, e; add r, f; add r, g; add r, h; add r, i; add r, j; add r, k
	}
	// locals in loops can live in callee saved registers, which the template must not disturb
	total: u64
	for n in u64(0)..<10 {
		total += sum12(n, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	}
	testing.expect_value(t, total, u64(10*55 + 45))
}

@(test)
asm_encoding_branches :: proc(t: ^testing.T) {
	// the loop body is too long for a short backward jump
	far_loop :: asm(n: u64) -> (r: u64) [n -> r] {
	.top:
		#nop 200
		dec r
		jnz .top
	}
	// and the forward jump too long for a short one
	far_skip :: asm(n: u64) -> (r: u64) [n -> r] {
		test r, r
		jz .out
		#nop 300
		add r, 1
	.out:
		nop
	}
	count_bits :: asm(a: u64) -> (r: u64) [t: u64] {
		xor r, r
		mov t, a
	.loop:
		test t, t
		jz .done
		mov a, t
		sub a, 1
		and t, a
		inc r
		jmp .loop
	.done:
	}
	raw_bytes :: asm() -> (r: u32) { mov r, 0; #byte 0x90, 0x90; add r, 2 }

	testing.expect_value(t, far_loop(3), u64(0))
	testing.expect_value(t, far_skip(0), u64(0))
	testing.expect_value(t, far_skip(5), u64(6))
	testing.expect_value(t, count_bits(0xF0F0), u64(8))
	testing.expect_value(t, raw_bytes(), u32(2))
}

@(test)
asm_encoding_avx512 :: proc(t: ^testing.T) {
	features := info.cpu_features()
	if .avx512f not_in features || .avx512vl not_in features {
		return
	}
	// EVEX forms, registers 16..31, opmask registers and scaled disp8s
	tern    :: asm(a: #simd[4]u32, b: #simd[4]u32, c: #simd[4]u32) -> (r: #simd[4]u32) [a -> r] { vpternlogd r, b, c, 0x96 }
	rol     :: asm(a: #simd[4]u32) -> (r: #simd[4]u32) { vprold r, a, 8 }
	upper   :: asm(a: #simd[4]u32, b: #simd[4]u32) -> (r: #simd[4]u32) [#clobber %xmm20, #clobber %xmm31] {
		vmovdqu32 %xmm20, a; vmovdqu32 %xmm31, b; vpternlogd %xmm20, %xmm31, %xmm31, 0x3C; vmovdqu32 r, %xmm20
	}
	xor512  :: asm(p: ^[16]u32, q: ^[32]u32) [#clobber %zmm1, #clobber %zmm17, #clobber memory] {
		vmovdqu32 %zmm1, [p]; vmovdqu32 %zmm17, [q + 64]; vpternlogd %zmm1, %zmm17, %zmm17, 0x3C; vmovdqu32 [p], %zmm1
	}
	eq_mask :: asm(a: #simd[4]u32, b: #simd[4]u32) -> (r: u32) [#clobber %k1] { vpcmpd %k1, a, b, 0; kmovw r, %k1 }
	knot    :: asm(a: u32) -> (r: u32) [#clobber %k2, #clobber %k3] { kmovw %k2, a; knotw %k3, %k2; kmovw r, %k3 }
	compress :: asm(p: [^]u32, a: #simd[4]u32) [#clobber memory] { vpcompressd [p + 8], a }
	narrow  :: asm(p: [^]u8, a: #simd[2]u64) [#clobber memory] { vpmovqb [p + 6], a }

	testing.expect_value(t, tern({1, 2, 4, 8}, {3, 3, 3, 3}, {5, 5, 5, 5}), #simd[4]u32{7, 4, 2, 14})
	testing.expect_value(t, rol({0x11223344, 1, 0x80000000, 0}), #simd[4]u32{0x22334411, 0x100, 0x80, 0})
	testing.expect_value(t, upper({1, 2, 3, 4}, {1, 1, 1, 1}), #simd[4]u32{0, 3, 2, 5})
	p: [16]u32
	q: [32]u32
	for i in 0..<16 {
		p[i] = u32(i)
		q[16 + i] = 1
	}
	xor512(&p, &q)
	testing.expect_value(t, p[0], u32(1))
	testing.expect_value(t, p[15], u32(14))
	testing.expect_value(t, eq_mask({1, 2, 3, 4}, {1, 0, 3, 0}), u32(0b0101))
	testing.expect_value(t, knot(0x00F0), u32(0xFF0F))
	buf: [8]u32
	compress(raw_data(buf[:]), {7, 8, 9, 10})
	testing.expect_value(t, buf, [8]u32{0, 0, 7, 8, 9, 10, 0, 0})
	bytes: [10]u8
	narrow(raw_data(bytes[:]), {0x1FF, 0x2EE})
	testing.expect_value(t, bytes, [10]u8{0, 0, 0, 0, 0, 0, 0xFF, 0xEE, 0, 0})
}

@(test)
asm_encoding_layout :: proc(t: ^testing.T) {
	aligned   :: asm() -> (r: u64) { lea r, [.here]; #nop 3; #align 64; .here: }
	aligned2  :: asm(a: u64) -> (r: u64) [a -> r] { add r, 1; #align 16; add r, 2; #align 32; add r, 3 }
	table     :: asm(i: u64) -> (r: u32) [t: u64] { lea t, [.tbl]; mov r, [t + i*4]:u32; jmp .out; .tbl: #byte 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0; .out: }
	data      :: asm() -> (r: u64) { mov r, [.d + 2]:u64; jmp .o; .d: #byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10; .o: }
	at_offset :: asm(p: [^]u64, $n: int) -> (r: u64) { mov r, [p + n] }
	below     :: asm(p: [^]u64, $n: int) -> (r: u64) { mov r, [p - n + 24] }

	testing.expect_value(t, aligned() % 64, u64(0))
	testing.expect_value(t, aligned2(0), u64(6))
	testing.expect_value(t, table(2), u32(3))
	testing.expect_value(t, data(), u64(0x0A09080706050403))
	a := [4]u64{1, 2, 3, 4}
	testing.expect_value(t, at_offset(raw_data(a[:]), 16), u64(3))
	testing.expect_value(t, below(raw_data(a[:]), 8), u64(3))
}

@(test)
asm_encoding_high_byte :: proc(t: ^testing.T) {
	add_high :: asm(a: u8, b: u8) -> (r: u8) [a -> r = %ah, b = %bh] { add r, b }
	read_ch  :: asm(a: u8) -> (r: u32) [a = %ch] { movzx r, a }
	write_dh :: asm() -> (r: u8) [r = %dh] { mov r, 9 }

	testing.expect_value(t, add_high(3, 4), u8(7))
	testing.expect_value(t, read_ch(200), u32(200))
	testing.expect_value(t, write_dh(), u8(9))
}

@(test)
asm_encoding_frame_registers :: proc(t: ^testing.T) {
	// the template moves rsp itself, and puts it back
	own_stack :: asm(a: u64) -> (r: u64) [s: u64] {
		lea s, [%rsp - 64]; mov %rsp, s; push a; pop r; lea s, [%rsp + 64]; mov %rsp, s; cmp s, %rsp
	}
	// rbp holds the frame, so it is saved around the template
	via_rbp :: asm(a: u64) -> (r: u64) [#clobber %rbp] { mov %rbp, a; add %rbp, 5; mov r, %rbp }

	total: u64
	for i in u64(0)..<4 {
		total += own_stack(i) + via_rbp(i)
	}
	testing.expect_value(t, total, u64(2*6 + 4*5))
}
