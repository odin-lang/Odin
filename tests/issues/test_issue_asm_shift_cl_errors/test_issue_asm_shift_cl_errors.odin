#+build amd64
package test_issue_asm_shift_cl_errors

// The count of a shift or rotate by %cl is %cl itself, or an 8-bit operand pinned to %rcx

// Pinned to %rcx, but 64 bits wide: view it as `cb: u8 = c`
wide_pin :: asm(x: u64, c: u64) -> (r: u64) [
	x -> r,
	c = %rcx,
] {
	shr r, c
}

unpinned :: asm(x: u64, c: u8) -> (r: u64) [
	x -> r,
] {
	shl r, c
}

wrong_width :: asm(x: u64, c: u64) -> (r: u64) [
	x -> r,
	c = %rcx,
] {
	sar r, %ecx
}

high_byte :: asm(x: u64, c: u64) -> (r: u64) [
	x -> r,
	c = %rcx,
] {
	rol r, %ch
}

pinned_elsewhere :: asm(x: u64, c: u8) -> (r: u64) [
	x -> r,
	c = %dl,
] {
	ror r, c
}

// A double shift names its count too
shld_without_count :: asm(a: u64, b: u64) -> (r: u64) [
	a -> r,
] {
	shld r, b
}

// A bare shift is by one, so the input pinned to %rcx is never used
by_one :: asm(x: u64, c: u64) -> (r: u64) [
	x -> r,
	c = %rcx,
] {
	shr r
}

main :: proc() {
	_ = wide_pin(1, 1)
	_ = unpinned(1, 1)
	_ = wrong_width(1, 1)
	_ = high_byte(1, 1)
	_ = pinned_elsewhere(1, 1)
	_ = shld_without_count(1, 1)
	_ = by_one(1, 1)
}
