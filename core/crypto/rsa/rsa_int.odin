#+private
package rsa

import "core:bytes"

Big_Int :: struct($N: int) {
	v: [N]byte,
	v_len: int,
}

Modulus :: Big_Int(MODULUS_MAX_SIZE >> 3)
Factor :: Big_Int(FACTOR_MAX_SIZE >> 3)

@(require_results)
modulus_set_bytes :: proc(n: ^Modulus, b: []byte) -> bool {
	b_ := bytes.trim_left(b, []byte{0x00})
	b_len := len(b_)

	if b_len > size_of(n.v) || b_len == 0 {
		return false
	}

	copy(n.v[:], b_)
	n.v_len = b_len

	return true
}

modulus_set :: proc "contextless" (n, other: ^Modulus) {
	// Copy the full thing.
	copy(n.v[:], other.v[:])
	n.v_len = other.v_len
}

@(require_results)
modulus_bytes :: #force_inline proc "contextless" (n: ^Modulus) -> []byte {
	return n.v[:n.v_len]
}

@(require_results)
modulus_len :: #force_inline proc "contextless" (n: ^Modulus) -> int {
	return n.v_len
}

@(require_results)
modulus_copyout :: proc(n: ^Modulus, dst: []byte) -> (n_len: int) {
	if n_len = modulus_len(n); n_len == 0 {
		return
	}

	if len(dst) > 0 {
		ensure(len(dst) >= n_len, "crypto/rsa: insufficent buffer size")
		copy(dst, modulus_bytes(n))
	}

	return
}

@(require_results)
modulus_is_odd :: proc "contextless" (n: ^Modulus) -> bool {
	if n.v_len == 0 || n.v[n.v_len-1] & 1 == 0 {
		return false
	}
	return true
}

@(require_results)
factor_set_bytes :: proc(n: ^Factor, b: []byte) -> bool {
	b_ := bytes.trim_left(b, []byte{0x00})
	b_len := len(b_)

	if b_len > size_of(n.v) || b_len == 0 {
		return false
	}

	copy(n.v[:], b_)
	n.v_len = b_len

	return true
}

factor_set :: proc "contextless" (n, other: ^Factor) {
	// Copy the full thing.
	copy(n.v[:], other.v[:])
	n.v_len = other.v_len
}

@(require_results)
factor_bytes :: #force_inline proc "contextless" (n: ^Factor) -> []byte {
	return n.v[:n.v_len]
}

@(require_results)
factor_len :: #force_inline proc "contextless" (n: ^Factor) -> int {
	return n.v_len
}

@(require_results)
factor_copyout :: proc(n: ^Factor, dst: []byte) -> (n_len: int) {
	if n_len = factor_len(n); n_len == 0 {
		return
	}

	if len(dst) > 0 {
		ensure(len(dst) >= n_len, "crypto/rsa: insufficent buffer size")
		copy(dst, factor_bytes(n))
	}

	return
}
