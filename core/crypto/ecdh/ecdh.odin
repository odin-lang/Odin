package ecdh

import "core:crypto"
import secec "core:crypto/_weierstrass"
import "core:crypto/x25519"
import "core:crypto/x448"
import "core:mem"
import "core:reflect"

// Note: For these primitives scalar size = point size
@(private="file")
X25519_Buf :: [x25519.SCALAR_SIZE]byte
@(private="file")
X448_Buf :: [x448.SCALAR_SIZE]byte

// Curve the curve identifier associated with a given Private_Key
// or Public_Key
Curve :: enum {
	Invalid,
	SECP256R1,
	X25519,
	X448,
}

// CURVE_NAMES is the Curve to curve name string.
CURVE_NAMES := [Curve]string {
	.Invalid   = "Invalid",
	.SECP256R1 = "secp256r1",
	.X25519    = "X25519",
	.X448      = "X448",
}

// PRIVATE_KEY_SIZES is the Curve to private key size in bytes.
PRIVATE_KEY_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = secec.SC_SIZE_P256R1,
	.X25519    = x25519.SCALAR_SIZE,
	.X448      = x448.SCALAR_SIZE,
}

// PUBLIC_KEY_SIZES is the Curve to public key size in bytes.
PUBLIC_KEY_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = 1 + 2 * secec.FE_SIZE_P256R1,
	.X25519    = x25519.POINT_SIZE,
	.X448      = x448.POINT_SIZE,
}

// SHARED_SECRET_SIZES is the Curve to shared secret size in bytes.
SHARED_SECRET_SIZES := [Curve]int {
	.Invalid   = 0,
	.SECP256R1 = secec.FE_SIZE_P256R1,
	.X25519    = x25519.POINT_SIZE,
	.X448      = x448.POINT_SIZE,
}

@(private="file")
_PRIV_IMPL_IDS := [Curve]typeid {
	.Invalid           = nil,
	.SECP256R1         = typeid_of(secec.Scalar_p256r1),
	.X25519            = typeid_of(X25519_Buf),
	.X448              = typeid_of(X448_Buf),
}

@(private="file")
_PUB_IMPL_IDS := [Curve]typeid {
	.Invalid           = nil,
	.SECP256R1         = typeid_of(secec.Point_p256r1),
	.X25519            = typeid_of(X25519_Buf),
	.X448              = typeid_of(X448_Buf),
}

// Private_Key is an ECDH private key.
Private_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Private_Key structure is intended to be opaque).
	_curve: Curve,
	_impl: union {
		secec.Scalar_p256r1,
		X25519_Buf,
		X448_Buf,
	},
	_pub_key: Public_Key,
}

// Public_Key is an ECDH public key.
Public_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Public_Key structure is intended to be opaque).
	_curve: Curve,
	_impl: union {
		secec.Point_p256r1,
		X25519_Buf,
		X448_Buf,
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

		// 384-bits reduced makes the modulo bias insignificant
		b: [48]byte = ---
		defer (mem.zero_explicit(&b, size_of(b)))
		for {
			crypto.rand_bytes(b[:])
			_ = secec.sc_set_bytes(sc, b[:])
			if secec.sc_is_zero(sc) == 0 { // Likely
				break
			}
		}
	case .X25519:
		sc := &priv_key._impl.(X25519_Buf)
		crypto.rand_bytes(sc[:])
	case .X448:
		sc := &priv_key._impl.(X448_Buf)
		crypto.rand_bytes(sc[:])
	case:
		panic("crypto/ecdh: invalid curve")
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
	case .X25519:
		sc := &priv_key._impl.(X25519_Buf)
		copy(sc[:], b)
	case .X448:
		sc := &priv_key._impl.(X448_Buf)
		copy(sc[:], b)
	case:
		panic("crypto/ecdh: invalid curve")
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
	case X25519_Buf:
		pub_key: X25519_Buf = ---
		x25519.scalarmult_basepoint(pub_key[:], sc[:])
		priv_key._pub_key._impl = pub_key
	case X448_Buf:
		pub_key: X448_Buf = ---
		x448.scalarmult_basepoint(pub_key[:], sc[:])
		priv_key._pub_key._impl = pub_key
	case:
		panic("crypto/ecdh: invalid curve")
	}

	priv_key._pub_key._curve = priv_key._curve
}

// private_key_bytes sets dst to byte-encoding of priv_key.
private_key_bytes :: proc(priv_key: ^Private_Key, dst: []byte) {
	ensure(priv_key._curve != .Invalid, "crypto/ecdh: uninitialized private key")
	ensure(len(dst) == PRIVATE_KEY_SIZES[priv_key._curve], "crypto/ecdh: invalid destination size")

	#partial switch priv_key._curve {
	case .SECP256R1:
		sc := &priv_key._impl.(secec.Scalar_p256r1)
		secec.sc_bytes(dst, sc)
	case .X25519:
		sc := &priv_key._impl.(X25519_Buf)
		copy(dst, sc[:])
	case .X448:
		sc := &priv_key._impl.(X448_Buf)
		copy(dst, sc[:])
	case:
		panic("crypto/ecdh: invalid curve")
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
	case .X25519:
		b_p, b_q  := &p._impl.(X25519_Buf), &q._impl.(X25519_Buf)
		return crypto.compare_constant_time(b_p[:], b_q[:]) == 1
	case .X448:
		b_p, b_q  := &p._impl.(X448_Buf), &q._impl.(X448_Buf)
		return crypto.compare_constant_time(b_p[:], b_q[:]) == 1
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
	case .X25519:
		pt := &pub_key._impl.(X25519_Buf)
		copy(pt[:], b)
	case .X448:
		pt := &pub_key._impl.(X448_Buf)
		copy(pt[:], b)
	case:
		panic("crypto/ecdh: invalid curve")
	}

	pub_key._curve = curve

	return true
}

// public_key_set_priv sets pub_key to the public component of priv_key.
public_key_set_priv :: proc(pub_key: ^Public_Key, priv_key: ^Private_Key) {
	ensure(priv_key._curve != .Invalid, "crypto/ecdh: uninitialized private key")
	public_key_clear(pub_key)
	pub_key^ = priv_key._pub_key
}

// public_key_bytes sets dst to byte-encoding of pub_key.
public_key_bytes :: proc(pub_key: ^Public_Key, dst: []byte) {
	ensure(pub_key._curve != .Invalid, "crypto/ecdh: uninitialized public key")
	ensure(len(dst) == PUBLIC_KEY_SIZES[pub_key._curve], "crypto/ecdh: invalid destination size")

	#partial switch pub_key._curve {
	case .SECP256R1:
		// Invariant: Unless the caller is manually building pub_key
		// `Z = 1`, so we can skip the rescale.
		pt := &pub_key._impl.(secec.Point_p256r1)

		dst[0] = secec.SEC_PREFIX_UNCOMPRESSED
		secec.fe_bytes(dst[1:1+secec.FE_SIZE_P256R1], &pt.x)
		secec.fe_bytes(dst[1+secec.FE_SIZE_P256R1:], &pt.y)
	case .X25519:
		pt := &pub_key._impl.(X25519_Buf)
		copy(dst, pt[:])
	case .X448:
		pt := &pub_key._impl.(X448_Buf)
		copy(dst, pt[:])
	case:
		panic("crypto/ecdh: invalid curve")
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
	case .X25519:
		b_p, b_q  := &p._impl.(X25519_Buf), &q._impl.(X25519_Buf)
		return crypto.compare_constant_time(b_p[:], b_q[:]) == 1
	case .X448:
		b_p, b_q  := &p._impl.(X448_Buf), &q._impl.(X448_Buf)
		return crypto.compare_constant_time(b_p[:], b_q[:]) == 1
	case:
		panic("crypto/ecdh: invalid curve")
	}
}

// public_key_clear clears pub_key to the uninitialized state.
public_key_clear :: proc "contextless" (pub_key: ^Public_Key) {
	mem.zero_explicit(pub_key, size_of(Public_Key))
}

// ecdh performs an Elliptic Curve Diffie-Hellman key exchange betwween
// the Private_Key and Public_Key, writing the shared secret to dst.
//
// The neutral element is rejected as an error.
@(require_results)
ecdh :: proc(priv_key: ^Private_Key, pub_key: ^Public_Key, dst: []byte) -> bool {
	ensure(priv_key._curve == pub_key._curve, "crypto/ecdh: curve mismatch")
	ensure(pub_key._curve != .Invalid, "crypto/ecdh: uninitialized public key")
	ensure(len(dst) == SHARED_SECRET_SIZES[priv_key._curve], "crypto/ecdh: invalid shared secret size")

	#partial switch priv_key._curve {
	case .SECP256R1:
		sc, pt := &priv_key._impl.(secec.Scalar_p256r1), &pub_key._impl.(secec.Point_p256r1)
		ss: secec.Point_p256r1
		defer secec.pt_clear(&ss)

		secec.pt_scalar_mul(&ss, pt, sc)
		return secec.pt_bytes(dst, nil, &ss)
	case .X25519:
		sc, pt := &priv_key._impl.(X25519_Buf), &pub_key._impl.(X25519_Buf)
		x25519.scalarmult(dst, sc[:], pt[:])
	case .X448:
		sc, pt := &priv_key._impl.(X448_Buf), &pub_key._impl.(X448_Buf)
		x448.scalarmult(dst, sc[:], pt[:])
	case:
		panic("crypto/ecdh: invalid curve")
	}

	// X25519/X448 check for all zero digest.
	return crypto.is_zero_constant_time(dst) == 0
}

// curve returns the Curve used by a Private_Key or Public_Key instance.
curve :: proc(k: ^$T) -> Curve where(T == Private_Key || T == Public_Key) {
	return k._curve
}

// key_size returns the key size of a Private_Key or Public_Key in bytes.
key_size :: proc(k: ^$T) -> int where(T == Private_Key || T == Public_Key) {
	when T == Private_Key {
		return PRIVATE_KEY_SIZES[k._curve]
	} else {
		return PUBLIC_KEY_SIZES[k._curve]
	}
}

// shared_secret_size returns the shared secret size of a key exchange
// in bytes.
shared_secret_size :: proc(k: ^$T) -> int  where(T == Private_Key || T == Public_Key) {
	return SHARED_SECRET_SIZES[k._curve]
}
