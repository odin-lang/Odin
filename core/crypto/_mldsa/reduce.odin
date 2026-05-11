#+private
package _mldsa

// MONT :: -4186625 // 2^32 % Q

@(require_results)
montgomery_reduce :: proc "contextless" (a: i64) -> i32 {
	QINV :: 58728449 // q^(-1) mod 2^32

	t := i32(i64(i32(a)) * QINV)
	t = i32((a - i64(t) * Q) >> 32)
	return t
}

@(require_results)
reduce32 :: #force_inline proc "contextless" (a: i32) -> i32 {
	t := (a + (1 << 22)) >> 23
	t = a - t * Q
	return t
}

@(require_results)
caddq :: #force_inline proc "contextless" (a: i32) -> i32 {
	a := a
	a += (a >> 31) & Q
	return a
}

// @(require_results)
// freeze :: #force_inline proc "contextless" (a: i32) -> i32 {
// 	a := a
// 	a = reduce32(a)
// 	a = caddq(a)
// 	return a
// }
