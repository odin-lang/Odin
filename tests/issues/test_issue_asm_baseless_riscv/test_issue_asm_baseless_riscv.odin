package test_issue_asm_baseless_riscv

// Built as an object with -target:linux_riscv64, so LLVM assembles the templates.
// A memory operand without a base register was written as `16()`, which LLVM rejects.
// The zero register is now the base: `16(zero)` is the absolute address 16.

absolute :: asm() -> (r: u64) {
	ld r, [16]
}

absolute_negative :: asm() -> (r: u64) {
	ld r, [-2048]
}

absolute_immediate :: asm($K: i64) -> (r: u64) {
	ld r, [K]
}

main :: proc() {
	_ = absolute()
	_ = absolute_negative()
	_ = absolute_immediate(2047)
}
