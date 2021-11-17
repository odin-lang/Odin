package crypto

import "core:mem"

// compare_constant_time returns 1 iff a and b are equal, 0 otherwise.
//
// The execution time of this routine is constant regardless of the contents
// of the slices being compared, as long as the length of the slices is equal.
// If the length of the two slices is different, it will early-return 0.
compare_constant_time :: proc "contextless" (a, b: []byte) -> int {
	// If the length of the slices is different, early return.
	//
	// This leaks the fact that the slices have a different length,
	// but the routine is primarily intended for comparing things
	// like MACS and password digests.
	n := len(a)
	if n != len(b) {
		return 0
	}

	return compare_byte_ptrs_constant_time(raw_data(a), raw_data(b), n)
}

// compare_byte_ptrs_constant_time returns 1 iff the bytes pointed to by
// a and b are equal, 0 otherwise.
//
// The execution time of this routine is constant regardless of the
// contents of the memory being compared.
compare_byte_ptrs_constant_time :: proc "contextless" (a, b: ^byte, n: int) -> int {
	x := mem.slice_ptr(a, n)
	y := mem.slice_ptr(b, n)

	v: byte
	for i in 0..<n {
		v |= x[i] ~ y[i]
	}

	// After the loop, v == 0 iff a == b.  The subtraction will underflow
	// iff v == 0, setting the sign-bit, which gets returned.
	return int((u32(v)-1) >> 31)
}

// rand_bytes fills the dst buffer with cryptographic entropy taken from
// the system entropy source.  This routine will block if the system entropy
// source is not ready yet.  All system entropy source failures are treated
// as catastrophic, resulting in a panic.
rand_bytes :: proc (dst: []byte) {
	// zero-fill the buffer first
	mem.zero_explicit(raw_data(dst), len(dst))

	_rand_bytes(dst)
}
