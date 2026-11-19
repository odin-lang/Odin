#+build riscv64
package test_issue_asm_baseless_errors

absolute_too_far :: asm() -> (r: u64) {
	ld r, [4096]
}

offset_too_far :: asm(p: [^]u64) -> (r: u64) {
	ld r, [p + 2048]
}
