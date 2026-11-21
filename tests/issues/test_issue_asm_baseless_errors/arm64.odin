#+build arm64
package test_issue_asm_baseless_errors

absolute :: asm() -> (r: u64) {
	ldr r, [16]
}

index_only :: asm(i: u64) -> (r: u64) {
	ldr r, [i * 8]
}
