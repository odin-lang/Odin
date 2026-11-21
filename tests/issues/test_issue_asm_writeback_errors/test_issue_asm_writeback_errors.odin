package test_issue_asm_writeback_errors

// Checked with -target:linux_arm64.
// #pre and #post could match a form without writeback. `stlr` has no post-indexed form.
// They take only a base register and a constant offset. A missing base crashed the compiler.

no_post_form :: asm(p: [^]u64, a: u64) [
	#volatile,
] {
	stlr a, #post [p]
}

with_index :: asm(p: [^]u64, i: u64, a: u64) [
	#volatile,
] {
	str a, #post [p + i]
}

no_base :: asm(a: u64) [
	#volatile,
] {
	str a, #pre [16]
}

main :: proc() {
	no_post_form(nil, 1)
	with_index(nil, 0, 1)
	no_base(1)
}
