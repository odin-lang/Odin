#+build amd64
package test_issue_asm_named_register_clobbers

import "core:testing"

// Writes registers which have no clobber bit of their own, so they must be clobbered by name
trash :: asm() [
	#volatile,
] {
	mov %r8,  0
	mov %r9,  0
	mov %r10, 0
	mov %r12, 0
	mov %r13, 0
	mov %r14, 0
	mov %r15, 0
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
}

// Enough values are live across the template that some are kept in the registers it writes
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
	trash()
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

// The input is pinned to r9, which the template overwrites
add_one_r9 :: asm(x: u64) -> (r: u64) [
	x = %r9,
] {
	add %r9, 1
	mov r, %r9
}

// x is used again afterwards, so it must not be assumed to still be in r9
add_one_keep :: #force_no_inline proc "contextless" (x: u64) -> (r, x_after: u64) {
	r = add_one_r9(x)
	x_after = x
	return
}

@(test)
test_named_register_clobbers :: proc(t: ^testing.T) {
	next :: proc(s: ^u64) -> u64 {
		s^ = s^*6364136223846793005 + 1442695040888963407
		return s^
	}

	s := u64(0x9e37_79b9_7f4a_7c15)
	for _ in 0..<1_000 {
		x := next(&s)
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

		r, x_after := add_one_keep(x)
		if r != x + 1 || x_after != x {
			testing.expectf(t, false, "add_one_keep(%v) gave (%v, %v)", x, r, x_after)
			return
		}
	}
}
