#+build amd64
package test_issue_asm_call_clobbers

import "core:testing"

// A callee with no calling convention: it zeroes every register but the stack and frame pointers,
// including the ones every C calling convention preserves
trash_everything :: proc "naked" () {
	trash :: asm() -> ! [
		#volatile,
	] {
		xor %eax, %eax
		xor %ebx, %ebx
		xor %ecx, %ecx
		xor %edx, %edx
		xor %esi, %esi
		xor %edi, %edi
		xor %r8d,  %r8d
		xor %r9d,  %r9d
		xor %r10d, %r10d
		xor %r11d, %r11d
		xor %r12d, %r12d
		xor %r13d, %r13d
		xor %r14d, %r14d
		xor %r15d, %r15d
		xorps %xmm0,  %xmm0
		xorps %xmm1,  %xmm1
		xorps %xmm2,  %xmm2
		xorps %xmm3,  %xmm3
		xorps %xmm4,  %xmm4
		xorps %xmm5,  %xmm5
		xorps %xmm6,  %xmm6
		xorps %xmm7,  %xmm7
		xorps %xmm8,  %xmm8
		xorps %xmm9,  %xmm9
		xorps %xmm10, %xmm10
		xorps %xmm11, %xmm11
		xorps %xmm12, %xmm12
		xorps %xmm13, %xmm13
		xorps %xmm14, %xmm14
		xorps %xmm15, %xmm15
		ret
	}
	trash()
}

call_out :: asm(f: proc "naked" ()) [
	#volatile,
	#align_stack,
] {
	call f
}

// Enough values are live across the call that some are kept in registers the callee zeroes
mix :: #force_no_inline proc "contextless" (s: u64, f: f64) -> (before, after: u64, fbefore, fafter: f64) {
	a := s * 0x9e37_79b9_7f4a_7c15
	b := a ~ (a >> 29)
	c := b * 0xbf58_476d_1ce4_e5b9
	d := c ~ (c >> 32)
	e := d * 0x94d0_49bb_1331_11eb
	g := e ~ (e >> 31)
	h := g + a
	i := h * 3
	j := i ~ b
	k := j + c
	l := k * 5
	m := l ~ d

	fa := f * 1.5
	fb := fa + 2.25
	fc := fb * 0.75
	fd := fc - 1.125
	fe := fd * 3.5
	fg := fe + fa

	before  = a + b + c + d + e + g + h + i + j + k + l + m
	fbefore = fa + fb + fc + fd + fe + fg
	call_out(trash_everything)
	after  = a ~ b ~ c ~ d ~ e ~ g ~ h ~ i ~ j ~ k ~ l ~ m
	fafter = fa * fb + fc * fd + fe * fg
	return
}

mix_reference :: #force_no_inline proc "contextless" (s: u64, f: f64) -> (before, after: u64, fbefore, fafter: f64) {
	a := s * 0x9e37_79b9_7f4a_7c15
	b := a ~ (a >> 29)
	c := b * 0xbf58_476d_1ce4_e5b9
	d := c ~ (c >> 32)
	e := d * 0x94d0_49bb_1331_11eb
	g := e ~ (e >> 31)
	h := g + a
	i := h * 3
	j := i ~ b
	k := j + c
	l := k * 5
	m := l ~ d

	fa := f * 1.5
	fb := fa + 2.25
	fc := fb * 0.75
	fd := fc - 1.125
	fe := fd * 3.5
	fg := fe + fa

	before  = a + b + c + d + e + g + h + i + j + k + l + m
	fbefore = fa + fb + fc + fd + fe + fg
	after   = a ~ b ~ c ~ d ~ e ~ g ~ h ~ i ~ j ~ k ~ l ~ m
	fafter  = fa * fb + fc * fd + fe * fg
	return
}

// The operands are pinned for the template, which keeps the sum on the stack across the call
sum_across_call :: asm(f: proc "naked" (), a, b: u64) -> (r: u64) [
	#volatile,
	#align_stack,
] {
	mov r, a
	add r, b
	push r
	call f
	pop r
}

sum_keep :: #force_no_inline proc "contextless" (a, b: u64) -> (r, a_after, b_after: u64) {
	r = sum_across_call(trash_everything, a, b)
	a_after = a
	b_after = b
	return
}

@(test)
test_call_clobbers :: proc(t: ^testing.T) {
	next :: proc(s: ^u64) -> u64 {
		s^ = s^*6364136223846793005 + 1442695040888963407
		return s^
	}

	s := u64(0x9e37_79b9_7f4a_7c15)
	for _ in 0..<1_000 {
		x := next(&s)
		y := next(&s)
		f := f64(x >> 11)

		got_before,  got_after,  got_fbefore,  got_fafter  := mix(x, f)
		want_before, want_after, want_fbefore, want_fafter := mix_reference(x, f)
		if got_before  != want_before  ||
		   got_after   != want_after   ||
		   got_fbefore != want_fbefore ||
		   got_fafter  != want_fafter {
			testing.expectf(t, false, "mix(%v, %v) gave (%v, %v, %v, %v), want (%v, %v, %v, %v)",
			                x, f,
			                got_before,  got_after,  got_fbefore,  got_fafter,
			                want_before, want_after, want_fbefore, want_fafter)
			return
		}

		r, x_after, y_after := sum_keep(x, y)
		if r != x + y || x_after != x || y_after != y {
			testing.expectf(t, false, "sum_keep(%v, %v) gave (%v, %v, %v)", x, y, r, x_after, y_after)
			return
		}
	}
}
