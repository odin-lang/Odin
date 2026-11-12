#+build amd64
// The specification block and body of an `asm` template are checked after its signature, like a procedure body,
// which must still report each of their errors: every `frobnicate` here is one "Unknown mnemonic" error
package test_issue_asm_deferred_errors

// Never used
unused_asm :: asm(a: u64) -> (r: u64) [a -> r] { frobnicate r }

// A duplicate overload, so the group makes its type invalid before its body is checked
dup_a :: asm(a, b: u64) -> (r: u64) [a -> r] { add r, b }
dup_b :: asm(a, b: u64) -> (r: u64) [a -> r] { add r, b; frobnicate r }
dup   :: asm { dup_a, dup_b }

// Not within any procedure body
global_var := asm(a: u64) -> (r: u64) [a -> r] { frobnicate r }(1)

poly :: proc($N: u64) -> u64 {
	return asm(a: u64) -> (r: u64) [a -> r] { add r, N; frobnicate r }(1)
}

main :: proc() {
	unused_local :: asm(a: u64) -> (r: u64) [a -> r] { frobnicate r }
	_ = dup(u64(1), 2)
	_ = poly(2)
}
