package mldsa

import "core:crypto"
import "core:crypto/_mldsa"

// Parameters are the supported ML-DSA parameter sets.
Parameters :: enum {
	Invalid,
	ML_DSA_44,
	ML_DSA_65,
	ML_DSA_87,
}

// PRIVATE_KEY_SEED_SIZE is the size of a private key in bytes.
PRIVATE_KEY_SEED_SIZE :: _mldsa.SEEDBYTES // 32-bytes

// MAX_CTX_SIZE is the maximum size of the signature context
// (domain separation tag) in bytes.
MAX_CTX_SIZE :: _mldsa.CTXBYTES_MAX // 255-bytes

// PUBLIC_KEY_SIZES are the per-parameter sizes of a public
// key in bytes.
PUBLIC_KEY_SIZES := [Parameters]int {
	.Invalid = 0,
	.ML_DSA_44 = 1312,
	.ML_DSA_65 = 1952,
	.ML_DSA_87 = 2592,
}

// SIGNATURE_SIZES are the per-parameter sizes of a signature
// in byte.
SIGNATURE_SIZES := [Parameters]int {
	.Invalid = 0,
	.ML_DSA_44 = 2420,
	.ML_DSA_65 = 3309,
	.ML_DSA_87 = 4627,
}

@(private="file")
_PARAMS_TO_INTERNAL := [Parameters]^_mldsa.Params {
	.Invalid = nil,
	.ML_DSA_44 = &_mldsa.Params_44,
	.ML_DSA_65 = &_mldsa.Params_65,
	.ML_DSA_87 = &_mldsa.Params_87,
}

// Private_Key is a ML-DSA private key.
Private_Key :: _mldsa.Private_Key

// Public_Key is a ML-DSA public key.
Public_Key :: _mldsa.Public_Key

// private_key_generate uses the system entropy source to generate a new
// Private_Key.  This will only fail if and only if (⟺) the system entropy
// source is missing or broken.
@(require_results)
private_key_generate :: proc(priv_key: ^Private_Key, params: Parameters) -> bool {
	private_key_clear(priv_key)

	if !crypto.HAS_RAND_BYTES {
		return false
	}

	params_ := _PARAMS_TO_INTERNAL[params]
	if params_ == nil {
		return false
	}

	seed: [PRIVATE_KEY_SEED_SIZE]byte = ---
	defer crypto.zero_explicit(&seed, size_of(seed))

	crypto.rand_bytes(seed[:])

	_mldsa.dsa_keygen_internal(priv_key, seed[:], params_)

	return true
}

// private_key_set_bytes decodes a byte-encoded private key in "seed" format,
// and returns true if and only if (⟺) the operation was successful.
@(require_results)
private_key_set_bytes :: proc(priv_key: ^Private_Key, params: Parameters, b: []byte) -> bool {
	private_key_clear(priv_key)

	params_ := _PARAMS_TO_INTERNAL[params]
	if params_ == nil {
		return false
	}
	if len(b) != PRIVATE_KEY_SEED_SIZE {
		return false
	}

	_mldsa.dsa_keygen_internal(priv_key, b, params_)

	return true
}

// private_key_bytes sets dst to byte-encoding of priv_key in the "seed"
// format.
private_key_bytes :: proc(priv_key: ^Private_Key, dst: []byte) {
	ensure(priv_key.params != nil, "crypto/mldsa: uninitialized private key")
	ensure(len(dst) == PRIVATE_KEY_SEED_SIZE, "crypto/mldsa: invalid destination size")

	copy(dst, priv_key.seed[:])
}

// private_key_public_bytes sets dst to the byte-encoding of the public
// key corresponding to priv_key.
private_key_public_bytes :: proc(priv_key: ^Private_Key, dst: []byte) {
	public_key_bytes(&priv_key.pub_key, dst)
}

// private_key_set sets priv_key to src.
private_key_set :: proc(priv_key, src: ^Private_Key) {
	if src == nil || internal_to_params(src.params) == .Invalid {
		private_key_clear(priv_key)
		return
	}

	_mldsa.set_sk(priv_key, src)
}

// private_key_equal returns true if and only if (⟺) the private keys are
// equal, in constant time.
@(require_results)
private_key_equal :: proc(p, q: ^Private_Key) -> bool {
	if p.params != q.params {
		return false
	}
	if p.params == nil {
		return true
	}

	// Just compare the seed that was passed to dsa_keygen_internal,
	// since the process is completely deterministic.
	return crypto.compare_constant_time(p.seed[:], q.seed[:]) == 1
}

// private_key_clear clears priv_key to the uninitialized state.
private_key_clear :: proc "contextless" (priv_key: ^Private_Key) {
	_mldsa.clear_sk(priv_key)
}

// public_key_set_bytes decodes a byte-encoded public key, and returns
// true if and only if (⟺) the operation was successful.
@(require_results)
public_key_set_bytes :: proc(pub_key: ^Public_Key, params: Parameters, b: []byte) -> bool {
	params_ := _PARAMS_TO_INTERNAL[params]
	if params_ == nil {
		return false
	}

	return _mldsa.unpack_pk(pub_key, b, params_)
}

// public_key_set sets pub_key to src.
public_key_set :: proc(pub_key, src: ^Public_Key) {
	if src == nil || internal_to_params(src.params) == .Invalid {
		public_key_clear(pub_key)
		return
	}

	_mldsa.set_pk(pub_key, src)
}

// public_key_set_priv sets pub_key to the public component of priv_key.
public_key_set_priv :: proc(pub_key: ^Public_Key, priv_key: ^Private_Key) {
	ensure(priv_key.params != nil, "crypto/mldsa: uninitialized private key")
	public_key_set(pub_key, &priv_key.pub_key)
}

// public_key_bytes sets dst to byte-encoding of pub_key.
public_key_bytes :: proc(pub_key: ^Public_Key, dst: []byte) {
	ensure(pub_key.params != nil, "crypto/mldsa: uninitialized public key")
	params := internal_to_params(pub_key.params)
	ensure(len(dst) == PUBLIC_KEY_SIZES[params], "crypto/mldsa: invalid destination size")

	_ = _mldsa.pack_pk(dst, pub_key)
}

// public_key_equal returns true if and only if (⟺) the public keys are equal,
// in constant time.
@(require_results)
public_key_equal :: proc(p, q: ^Public_Key) -> bool {
	if p.params != q.params {
		return false
	}
	if p.params == nil {
		return true
	}

	// Comparing the pre-computed hash should be enough, but pack
	// both public keys and do the comparisons.
	PUBLIC_KEY_SIZE_MAX :: 2592

	l := PUBLIC_KEY_SIZES[internal_to_params(p.params)]
	p_buf_, q_buf_: [PUBLIC_KEY_SIZE_MAX]byte = ---, ---
	p_buf, q_buf := p_buf_[:l], q_buf_[:l]

	_ = _mldsa.pack_pk(p_buf, p)
	_ = _mldsa.pack_pk(q_buf, q)

	return crypto.compare_constant_time(p_buf, q_buf) == 1
}

// public_key_clear clears pub_key to the uninitialized state.
public_key_clear :: proc "contextless" (pub_key: ^Public_Key) {
	_mldsa.clear_pk(pub_key)
}

// sign writes the signature by priv_key over (ctx, msg) to sig and
// returns true if and only if (⟺) the signing succeeded.
//
// ctx is an optional domain separation tag and may be omitted (nil).
@(require_results)
sign :: proc(priv_key: ^Private_Key, ctx, msg, sig: []byte, deterministic := !crypto.HAS_RAND_BYTES) -> bool {
	params := internal_to_params(priv_key.params)
	ensure(params != .Invalid, "crypto/mldsa: invalid private key")
	ensure(len(sig) == SIGNATURE_SIZES[params], "crypto/mldsa: invalid destination size")

	if !deterministic && !crypto.HAS_RAND_BYTES {
		return false
	}
	if len(ctx) > MAX_CTX_SIZE {
		return false
	}

	rnd: [_mldsa.RNDBYTES]byte
	defer crypto.zero_explicit(&rnd, size_of(rnd))

	if !deterministic {
		crypto.rand_bytes(rnd[:])
	}

	return _mldsa.dsa_sign_internal(sig, msg, ctx, rnd[:], priv_key)
}

// verify returns true if and only if (⟺) sig is a valid signature by pub_key
// over (ctx, msg).
@(require_results)
verify :: proc(pub_key: ^Public_Key, ctx, msg, sig: []byte) -> bool {
	params := internal_to_params(pub_key.params)
	ensure(params != .Invalid, "crypto/mldsa: invalid public key")

	if len(sig) != SIGNATURE_SIZES[params] {
		return false
	}
	if len(ctx) > MAX_CTX_SIZE {
		return false
	}

	return _mldsa.dsa_verify_internal(sig, msg, ctx, pub_key)
}

// params returns the Parameters used by a Private_Key or Public_Key
// instance.
@(require_results)
params :: proc(k: ^$T) -> Parameters where (T == Private_Key || T == Public_Key) {
	return internal_to_params(k.params)
}

// key_size returns the key size of a Private_Key or Public_Key in bytes.
@(require_results)
key_size :: proc(k: ^$T) -> int where (T == Private_Key || T == Public_Key) {
	when T == Private_Key {
		return PRIVATE_KEY_SEED_SIZE
	} else {
		return PUBLIC_KEY_SIZES[internal_to_params(k.params)]
	}
}

// signature_size returns the key size of a signature in bytes.
@(require_results)
signature_size :: proc(k: ^$T) -> int where (T == Private_Key || T == Public_Key) {
	return SIGNATURE_SIZES[internal_to_params(k.params)]
}

@(private="file",require_results)
internal_to_params :: proc "contextless" (params: ^_mldsa.Params) -> Parameters {
	switch params {
	case &_mldsa.Params_44:
		return .ML_DSA_44
	case &_mldsa.Params_65:
		return .ML_DSA_65
	case &_mldsa.Params_87:
		return .ML_DSA_87
	case:
		return .Invalid
	}
}
