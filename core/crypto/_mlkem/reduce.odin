#+private
package _mlkem

@(require_results)
montgomery_reduce :: #force_inline proc "contextless" (a: i32) -> i16 {
	QINV :: -3327 // q^-1 mod 2^16

	t := i16(a)	* QINV
	return i16((a - i32(t) * Q) >> 16)
}

@(require_results)
barrett_reduce :: #force_inline proc "contextless" (a: i16) -> i16 {
	V : i16 : ((1<<26) + Q / 2) / Q

	t := i16((i32(V)*i32(a) + (1<<25)) >> 26)
	t *= Q
	return a - t
}
