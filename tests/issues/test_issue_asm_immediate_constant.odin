#+build amd64
// An `asm` template's `$` parameter is encoded as an immediate, but a runtime value passed to
// one was accepted by the checker and only died in the backend, with an unlocated LLVM error.
package test_issues

shl_imm :: asm(a: i32, $n: i32) -> (r: i32) { mov r, a; shl r, n; }

opaque :: proc() -> i32 {
	return 5
}

K :: 3

bad :: proc(v: i32) {
	x: i32 = 2
	_ = shl_imm(1, x)
	_ = shl_imm(1, v)
	_ = shl_imm(1, opaque())
	_ = shl_imm(1, x + 1)
}

good :: proc(a: i32) {
	_ = shl_imm(a, 2)
	_ = shl_imm(a, K)
	_ = shl_imm(a, 1 + 1)
}
