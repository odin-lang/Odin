#+build !bedrock
package runtime

@(private)
_udiv128by64_amd64 :: asm(u1, u0, v: u64) -> (q, r: u64) [
	u0 -> q = %rax,
	u1 -> r = %rdx,
] {
	div v
}
