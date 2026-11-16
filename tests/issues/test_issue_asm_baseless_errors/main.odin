package test_issue_asm_baseless_errors

// Checked with -target:linux_arm64 and -target:linux_riscv64.
// AArch64 has no absolute addressing: a memory operand without a base register reached LLVM as `[, #16]`.
// A RISC-V displacement must fit 12 signed bits. A larger one reached LLVM, with or without a base.

main :: proc() {
}
