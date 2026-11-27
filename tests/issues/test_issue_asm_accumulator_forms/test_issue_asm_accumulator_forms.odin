#+build amd64
package test_issue_asm_accumulator_forms

// An accumulator short form matched an instruction written without the accumulator, e.g. `add 5`.
// LLVM then rejected it: "too few operands for instruction".
// The short forms are no longer matched, so each of these is an error.

add_short :: asm(x: u64) -> (r: u64) [
	x -> r = %rax,
] {
	add 5
}

xchg_short :: asm(a: u32, b: u32) -> (r: u32) [
	a -> r = %rax,
] {
	xchg b
}

mov_absolute :: asm(x: u8) -> (r: u8) [
	x -> r = %al,
] {
	mov [0x1000]:u8
}

movabs_absolute :: asm(x: u64) -> (r: u64) [
	x -> r = %rax,
] {
	movabs [0x1000]:u64
}

// The general forms name the accumulator

add_general :: asm(x: u64) -> (r: u64) [
	x -> r = %rax,
] {
	add r, 5
}

xchg_general :: asm(a: u32, b: u32) -> (r: u32) [
	a -> r = %rax,
] {
	xchg r, b
}

mov_general :: asm() -> (r: u8) [
	r = %al,
] {
	mov r, [0x1000]:u8
}

// IN and OUT keep their accumulator forms: an immediate port has no other

in_port :: asm() -> (r: u8) [
	r = %al,
	#volatile,
] {
	in 0x60
}

out_port :: asm(c: u8) [
	c = %al,
	#volatile,
] {
	out 0x80
}

main :: proc() {
	_ = add_short(1)
	_ = xchg_short(1, 2)
	_ = mov_absolute(1)
	_ = movabs_absolute(1)
	_ = add_general(1)
	_ = xchg_general(1, 2)
	_ = mov_general()
	_ = in_port()
	out_port(1)
}
