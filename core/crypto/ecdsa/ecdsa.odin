package ecdsa

import "core:crypto"
import secec "core:crypto/_weierstrass"
import "core:mem"
import "core:reflect"

// Curve the curve identifier associated with a given Private_Key
// or Public_Key
Curve :: enum {
	Invalid,
	SECP256R1,
	SECP384R1,
}

// CURVE_NAMES is the Curve to curve name string.
CURVE_NAMES := [Curve]string {
	.Invalid   = "Invalid",
	.SECP256R1 = "secp256r1",
	.SECP384R1 = "secp384r1",
}

// PRIVATE_KEY_SIZES is the Curve to private key size in bytes.
PRIVATE_KEY_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = secec.SC_SIZE_P256R1,
	.SECP384R1 = secec.SC_SIZE_P384R1,
}

// PUBLIC_KEY_SIZES is the Curve to public key size in bytes.
PUBLIC_KEY_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = 1 + 2 * secec.FE_SIZE_P256R1,
	.SECP384R1 = 1 + 2 * secec.FE_SIZE_P384R1,
}

// RAW_SIGNATURE_SIZES is the Curve to "raw" signature size in bytes.
RAW_SIGNATURE_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = 2 * secec.SC_SIZE_P256R1,
	.SECP384R1 = 2 * secec.SC_SIZE_P384R1,
}

@(private="file")
_PRIV_IMPL_IDS := [Curve]typeid {
	.Invalid           = nil,
	.SECP256R1         = typeid_of(secec.Scalar_p256r1),
	.SECP384R1         = typeid_of(secec.Scalar_p384r1),
}

@(private="file")
_PUB_IMPL_IDS := [Curve]typeid {
	.Invalid           = nil,
	.SECP256R1         = typeid_of(secec.Point_p256r1),
	.SECP384R1         = typeid_of(secec.Point_p384r1),
}

// Private_Key is an ECDSA private key.
Private_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Private_Key structure is intended to be opaque).
	_curve: Curve,
	_impl: union {
		secec.Scalar_p256r1,
		secec.Scalar_p384r1,
	},
	_pub_key: Public_Key,
}

// Public_Key is an ECDSA public key.
Public_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Public_Key structure is intended to be opaque).
	_curve: Curve,
	_impl: union {
		secec.Point_p256r1,
		secec.Point_p384r1,
	},
}

// private_key_generate uses the system entropy source to generate a new
// Private_Key.  This will only fail iff the system entropy source is
// missing or broken.
private_key_generate :: proc(priv_key: ^Private_Key, curve: Curve) -> bool {
	private_key_clear(priv_key)

	if !crypto.HAS_RAND_BYTES {
		return false
	}

	reflect.set_union_variant_typeid(
		priv_key._impl,
		_PRIV_IMPL_IDS[curve],
	)

	#partial switch curve {
	case .SECP256R1:
		sc := &priv_key._impl.(secec.Scalar_p256r1)
		secec.sc_set_random(sc)
	case .SECP384R1:
		sc := &priv_key._impl.(secec.Scalar_p384r1)
		secec.sc_set_random(sc)
	case:
		panic("crypto/ecdsa: invalid curve")
	}

	priv_key._curve = curve
	private_key_generate_public(priv_key)

	return true
}

// private_key_set_bytes decodes a byte-encoded private key, and returns
// true iff the operation was successful.
private_key_set_bytes :: proc(priv_key: ^Private_Key, curve: Curve, b: []byte) -> bool {
	private_key_clear(priv_key)

	if len(b) != PRIVATE_KEY_SIZES[curve] {
		return false
	}

	reflect.set_union_variant_typeid(
		priv_key._impl,
		_PRIV_IMPL_IDS[curve],
	)

	#partial switch curve {
	case .SECP256R1:
		sc := &priv_key._impl.(secec.Scalar_p256r1)
		did_reduce := secec.sc_set_bytes(sc, b)
		is_zero := secec.sc_is_zero(sc) == 1

		// Reject `0` and scalars that are not less than the
		// curve order.
		if did_reduce || is_zero {
			private_key_clear(priv_key)
			return false
		}
	case .SECP384R1:
		sc := &priv_key._impl.(secec.Scalar_p384r1)
		did_reduce := secec.sc_set_bytes(sc, b)
		is_zero := secec.sc_is_zero(sc) == 1

		// Reject `0` and scalars that are not less than the
		// curve order.
		if did_reduce || is_zero {
			private_key_clear(priv_key)
			return false
		}
	case:
		panic("crypto/esa: invalid curve")
	}

	priv_key._curve = curve
	private_key_generate_public(priv_key)

	return true
}

@(private="file")
private_key_generate_public :: proc(priv_key: ^Private_Key) {
	switch &sc in priv_key._impl {
	case secec.Scalar_p256r1:
		pub_key: secec.Point_p256r1 = ---
		secec.pt_scalar_mul_generator(&pub_key, &sc)
		secec.pt_rescale(&pub_key, &pub_key)
		priv_key._pub_key._impl = pub_key
	case secec.Scalar_p384r1:
		pub_key: secec.Point_p384r1 = ---
		secec.pt_scalar_mul_generator(&pub_key, &sc)
		secec.pt_rescale(&pub_key, &pub_key)
		priv_key._pub_key._impl = pub_key
	case:
		panic("crypto/ecdsa: invalid curve")
	}

	priv_key._pub_key._curve = priv_key._curve
}

// private_key_bytes sets dst to byte-encoding of priv_key.
private_key_bytes :: proc(priv_key: ^Private_Key, dst: []byte) {
	ensure(priv_key._curve != .Invalid, "crypto/ecdsa: uninitialized private key")
	ensure(len(dst) == PRIVATE_KEY_SIZES[priv_key._curve], "crypto/ecdsa: invalid destination size")

	#partial switch priv_key._curve {
	case .SECP256R1:
		sc := &priv_key._impl.(secec.Scalar_p256r1)
		secec.sc_bytes(dst, sc)
	case .SECP384R1:
		sc := &priv_key._impl.(secec.Scalar_p384r1)
		secec.sc_bytes(dst, sc)
	case:
		panic("crypto/ecdsa: invalid curve")
	}
}

// private_key_equal returns true iff the private keys are equal,
// in constant time.
private_key_equal :: proc(p, q: ^Private_Key) -> bool {
	if p._curve != q._curve {
		return false
	}

	#partial switch p._curve {
	case .SECP256R1:
		sc_p, sc_q := &p._impl.(secec.Scalar_p256r1), &q._impl.(secec.Scalar_p256r1)
		return secec.sc_equal(sc_p, sc_q) == 1
	case .SECP384R1:
		sc_p, sc_q := &p._impl.(secec.Scalar_p384r1), &q._impl.(secec.Scalar_p384r1)
		return secec.sc_equal(sc_p, sc_q) == 1
	case:
		return false
	}
}

// private_key_clear clears priv_key to the uninitialized state.
private_key_clear :: proc "contextless" (priv_key: ^Private_Key) {
	mem.zero_explicit(priv_key, size_of(Private_Key))
}

// public_key_set_bytes decodes a byte-encoded public key, and returns
// true iff the operation was successful.
public_key_set_bytes :: proc(pub_key: ^Public_Key, curve: Curve, b: []byte) -> bool {
	public_key_clear(pub_key)

	if len(b) != PUBLIC_KEY_SIZES[curve] {
		return false
	}

	reflect.set_union_variant_typeid(
		pub_key._impl,
		_PUB_IMPL_IDS[curve],
	)

	#partial switch curve {
	case .SECP256R1:
		if b[0] != secec.SEC_PREFIX_UNCOMPRESSED {
			return false
		}

		pt := &pub_key._impl.(secec.Point_p256r1)
		ok := secec.pt_set_sec_bytes(pt, b)
		if !ok || secec.pt_is_identity(pt) == 1 {
			return false
		}
	case .SECP384R1:
		if b[0] != secec.SEC_PREFIX_UNCOMPRESSED {
			return false
		}

		pt := &pub_key._impl.(secec.Point_p384r1)
		ok := secec.pt_set_sec_bytes(pt, b)
		if !ok || secec.pt_is_identity(pt) == 1 {
			return false
		}
	case:
		panic("crypto/ecdsa: invalid curve")
	}

	pub_key._curve = curve

	return true
}

// public_key_set_priv sets pub_key to the public component of priv_key.
public_key_set_priv :: proc(pub_key: ^Public_Key, priv_key: ^Private_Key) {
	ensure(priv_key._curve != .Invalid, "crypto/ecdsa: uninitialized private key")
	public_key_clear(pub_key)
	pub_key^ = priv_key._pub_key
}

// public_key_bytes sets dst to byte-encoding of pub_key.
public_key_bytes :: proc(pub_key: ^Public_Key, dst: []byte) {
	ensure(pub_key._curve != .Invalid, "crypto/ecdsa: uninitialized public key")
	ensure(len(dst) == PUBLIC_KEY_SIZES[pub_key._curve], "crypto/ecdsa: invalid destination size")

	#partial switch pub_key._curve {
	case .SECP256R1:
		// Invariant: Unless the caller is manually building pub_key
		// `Z = 1`, so we can skip the rescale.
		pt := &pub_key._impl.(secec.Point_p256r1)

		dst[0] = secec.SEC_PREFIX_UNCOMPRESSED
		secec.fe_bytes(dst[1:1+secec.FE_SIZE_P256R1], &pt.x)
		secec.fe_bytes(dst[1+secec.FE_SIZE_P256R1:], &pt.y)
	case .SECP384R1:
		// Invariant: Unless the caller is manually building pub_key
		// `Z = 1`, so we can skip the rescale.
		pt := &pub_key._impl.(secec.Point_p384r1)

		dst[0] = secec.SEC_PREFIX_UNCOMPRESSED
		secec.fe_bytes(dst[1:1+secec.FE_SIZE_P384R1], &pt.x)
		secec.fe_bytes(dst[1+secec.FE_SIZE_P384R1:], &pt.y)
	case:
		panic("crypto/ecdsa: invalid curve")
	}
}

// public_key_equal returns true iff the public keys are equal,
// in constant time.
public_key_equal :: proc(p, q: ^Public_Key) -> bool {
	if p._curve != q._curve {
		return false
	}

	#partial switch p._curve {
	case .SECP256R1:
		pt_p, pt_q := &p._impl.(secec.Point_p256r1), &q._impl.(secec.Point_p256r1)
		return secec.pt_equal(pt_p, pt_q) == 1
	case .SECP384R1:
		pt_p, pt_q := &p._impl.(secec.Point_p384r1), &q._impl.(secec.Point_p384r1)
		return secec.pt_equal(pt_p, pt_q) == 1
	case:
		panic("crypto/ecdsa: invalid curve")
	}
}

// public_key_clear clears pub_key to the uninitialized state.
public_key_clear :: proc "contextless" (pub_key: ^Public_Key) {
	mem.zero_explicit(pub_key, size_of(Public_Key))
}
