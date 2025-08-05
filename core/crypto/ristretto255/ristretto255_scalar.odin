package ristretto255

import grp "core:crypto/_edwards25519"

// SCALAR_SIZE is the size of a byte-encoded ristretto255 scalar.
SCALAR_SIZE :: 32
// WIDE_SCALAR_SIZE is the size of a wide byte-encoded ristretto255
// scalar.
WIDE_SCALAR_SIZE :: 64

// Scalar is a ristretto255 scalar.  The zero-initialized value is valid,
// and represents `0`.
Scalar :: grp.Scalar

// sc_clear clears sc to the uninitialized state.
sc_clear :: proc "contextless" (sc: ^Scalar) {
	grp.sc_clear(sc)
}

// sc_set sets `sc = a`.
sc_set :: proc "contextless" (sc, a: ^Scalar) {
	grp.sc_set(sc, a)
}

// sc_set_u64 sets `sc = i`.
sc_set_u64 :: proc "contextless" (sc: ^Scalar, i: u64) {
	grp.sc_set_u64(sc, i)
}

// sc_set_bytes sets sc to the result of decoding b as a ristretto255
// scalar, and returns true on success.
@(require_results)
sc_set_bytes :: proc(sc: ^Scalar, b: []byte) -> bool {
	if len(b) != SCALAR_SIZE {
		return false
	}

	return grp.sc_set_bytes(sc, b)
}

// sc_set_wide_bytes sets sc to the result of deriving a ristretto255
// scalar, from a wide (512-bit) byte string by interpreting b as a
// little-endian value, and reducing it mod the group order.
sc_set_bytes_wide :: proc(sc: ^Scalar, b: []byte) {
	ensure(len(b) == WIDE_SCALAR_SIZE, "crypto/ristretto255: invalid wide input size")

	b_ := (^[WIDE_SCALAR_SIZE]byte)(raw_data(b))
	grp.sc_set_bytes_wide(sc, b_)
}

// sc_bytes sets dst to the canonical encoding of sc.
sc_bytes :: proc(sc: ^Scalar, dst: []byte) {
	ensure(len(dst) == SCALAR_SIZE, "crypto/ristretto255: invalid destination size")

	grp.sc_bytes(dst, sc)
}

// sc_add sets `sc = a + b`.
sc_add :: proc "contextless" (sc, a, b: ^Scalar) {
	grp.sc_add(sc, a, b)
}

// sc_sub sets `sc = a - b`.
sc_sub :: proc "contextless" (sc, a, b: ^Scalar) {
	grp.sc_sub(sc, a, b)
}

// sc_negate sets `sc = -a`.
sc_negate :: proc "contextless" (sc, a: ^Scalar) {
	grp.sc_negate(sc, a)
}

// sc_mul sets `sc = a * b`.
sc_mul :: proc "contextless" (sc, a, b: ^Scalar) {
	grp.sc_mul(sc, a, b)
}

// sc_square sets `sc = a^2`.
sc_square :: proc "contextless" (sc, a: ^Scalar) {
	grp.sc_square(sc, a)
}

// sc_cond_assign sets `sc = sc` iff `ctrl == 0` and `sc = a` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
sc_cond_assign :: proc(sc, a: ^Scalar, ctrl: int) {
	grp.sc_cond_assign(sc, a, ctrl)
}

// sc_equal returns 1 iff `a == b`, and 0 otherwise.
@(require_results)
sc_equal :: proc(a, b: ^Scalar) -> int {
	return grp.sc_equal(a, b)
}
