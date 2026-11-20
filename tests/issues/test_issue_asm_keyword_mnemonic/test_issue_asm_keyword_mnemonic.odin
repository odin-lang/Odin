#+build amd64
package test_issue_asm_keyword_mnemonic

// Built as an object with -target:linux_amd64.
// No ';' is inserted after a keyword ending a line. A bare `in` took the next line as its operands.

read :: asm(port: u16) -> (r: u8, s: u8) [
	port = %dx,
	r    = %al,
	#volatile,
] {
	in
	mov s, %al
	in // with a comment
	mov s, %al
}

main :: proc() {
	_, _ = read(0x60)
}
