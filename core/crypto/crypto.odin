// A selection of cryptography algorithms and useful helper routines.
package crypto

import "base:intrinsics"
import "base:runtime"
import subtle "core:crypto/_subtle"

// Omit large precomputed tables, trading off performance for size.
COMPACT_IMPLS: bool : #config(ODIN_CRYPTO_COMPACT, false)

// HAS_RAND_BYTES is true iff the runtime provides a cryptographic
// entropy source.
HAS_RAND_BYTES :: runtime.HAS_RAND_BYTES

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
@(optimization_mode="none")
compare_byte_ptrs_constant_time :: proc "contextless" (a, b: ^byte, n: int) -> int {
	x := ([^]byte)(a)[:n]
	y := ([^]byte)(b)[:n]

	v: byte
	for i in 0..<n {
		v |= x[i] ~ y[i]
	}

	// After the loop, v == 0 iff a == b.  The subtraction will underflow
	// iff v == 0, setting the sign-bit, which gets returned.
	return subtle.eq(0, v)
}

// is_zero_constant_time returns 1 iff b is all 0s, 0 otherwise.
is_zero_constant_time :: proc "contextless" (b: []byte) -> int {
	v: byte
	for b_ in b {
		v |= b_
	}

	return subtle.byte_eq(0, v)
}

/*
Set each byte of a memory range to zero.

This procedure copies the value `0` into the `len` bytes of a memory range,
starting at address `data`.

This procedure returns the pointer to `data`.

Unlike the `zero()` procedure, which can be optimized away or reordered by the
compiler under certain circumstances, `zero_explicit()` procedure can not be
optimized away or reordered with other memory access operations, and the
compiler assumes volatile semantics of the memory.
*/
zero_explicit :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	// This routine tries to avoid the compiler optimizing away the call,
	// so that it is always executed.  It is intended to provide
	// equivalent semantics to those provided by the C11 Annex K 3.7.4.1
	// memset_s call.
	intrinsics.mem_zero_volatile(data, len) // Use the volatile mem_zero
	intrinsics.atomic_thread_fence(.Seq_Cst) // Prevent reordering
	return data
}

/*
Set each byte of a memory range to a specific value.

This procedure copies value specified by the `value` parameter into each of the
`len` bytes of a memory range, located at address `data`.

This procedure returns the pointer to `data`.
*/
set :: proc "contextless" (data: rawptr, value: byte, len: int) -> rawptr {
	return runtime.memset(data, i32(value), len)
}

// rand_bytes fills the dst buffer with cryptographic entropy taken from
// the system entropy source.  This routine will block if the system entropy
// source is not ready yet.  All system entropy source failures are treated
// as catastrophic, resulting in a panic.
//
// Support for the system entropy source can be checked with the
// `HAS_RAND_BYTES` boolean constant.
rand_bytes :: proc (dst: []byte) {
	// zero-fill the buffer first
	zero_explicit(raw_data(dst), len(dst))

	runtime.rand_bytes(dst)
}

// random_generator returns a `runtime.Random_Generator` backed by the
// system entropy source.
//
// Support for the system entropy source can be checked with the
// `HAS_RAND_BYTES` boolean constant.
random_generator :: proc() -> runtime.Random_Generator {
	return {
		procedure = proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
			switch mode {
			case .Read:
				rand_bytes(p)
			case .Reset:
				// do nothing
			case .Query_Info:
				if len(p) != size_of(runtime.Random_Generator_Query_Info) {
					return
				}
				info := (^runtime.Random_Generator_Query_Info)(raw_data(p))
				info^ += {.Uniform, .Cryptographic, .External_Entropy}
			}
		},
		data = nil,
	}
}
