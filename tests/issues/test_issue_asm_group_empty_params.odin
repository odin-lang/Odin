#+build amd64
// A zero-parameter asm template carries a non-null but empty parameter tuple, unlike a
// zero-parameter procedure, so dead code at the end of `are_proc_types_overload_safe` indexed
// `variables[0]` on it and tripped the bounds assertion. The duplicate-signature diagnostic the
// checker was about to print was lost, and the crash arrived with nothing else on stderr.
package test_issues

nop_a :: asm() { nop; }
nop_b :: asm() { nop; }
dup_no_params :: asm { nop_a, nop_b }

out_a :: asm() -> (r: u64) [r = %rax] { nop; }
out_b :: asm() -> (r: u64) [r = %rax] { nop; }
dup_result_only :: asm { out_a, out_b }

three_a :: asm() { nop; }
three_b :: asm() { nop; }
three_c :: asm() { nop; }
dup_three :: asm { three_a, three_b, three_c }

// a group whose members differ in their parameters has to keep resolving cleanly
add32 :: asm(a: u32, b: u32) -> (r: u32) { mov r, a; add r, b; }
add64 :: asm(a: u64, b: u64) -> (r: u64) { mov r, a; add r, b; }
add_ok :: asm { add32, add64 }

use :: proc() {
	_ = add_ok(u32(20), u32(22))
	_ = add_ok(u64(1), u64(2))
}
