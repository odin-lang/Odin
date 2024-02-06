package crypto_hash

import "core:crypto/blake2b"
import "core:crypto/blake2s"
import "core:crypto/sha2"
import "core:crypto/sha3"
import "core:crypto/sm3"
import "core:crypto/legacy/keccak"
import "core:crypto/legacy/md5"
import "core:crypto/legacy/sha1"

import "core:reflect"

// MAX_DIGEST_SIZE is the maximum size digest that can be returned by any
// of the Algorithms supported via this package.
MAX_DIGEST_SIZE :: 64
// MAX_BLOCK_SIZE is the maximum block size used by any of Algorithms
// supported by this package.
MAX_BLOCK_SIZE :: sha3.BLOCK_SIZE_224

// Algorithm is the algorithm identifier associated with a given Context.
Algorithm :: enum {
	Invalid,
	BLAKE2B,
	BLAKE2S,
	SHA224,
	SHA256,
	SHA384,
	SHA512,
	SHA512_256,
	SHA3_224,
	SHA3_256,
	SHA3_384,
	SHA3_512,
	SM3,
	Legacy_KECCAK_224,
	Legacy_KECCAK_256,
	Legacy_KECCAK_384,
	Legacy_KECCAK_512,
	Insecure_MD5,
	Insecure_SHA1,
}

// ALGORITHM_NAMES is the Algorithm to algorithm name string.
ALGORITHM_NAMES := [Algorithm]string {
	.Invalid           = "Invalid",
	.BLAKE2B           = "BLAKE2b",
	.BLAKE2S           = "BLAKE2s",
	.SHA224            = "SHA-224",
	.SHA256            = "SHA-256",
	.SHA384            = "SHA-384",
	.SHA512            = "SHA-512",
	.SHA512_256        = "SHA-512/256",
	.SHA3_224          = "SHA3-224",
	.SHA3_256          = "SHA3-256",
	.SHA3_384          = "SHA3-384",
	.SHA3_512          = "SHA3-512",
	.SM3               = "SM3",
	.Legacy_KECCAK_224 = "Keccak-224",
	.Legacy_KECCAK_256 = "Keccak-256",
	.Legacy_KECCAK_384 = "Keccak-384",
	.Legacy_KECCAK_512 = "Keccak-512",
	.Insecure_MD5      = "MD5",
	.Insecure_SHA1     = "SHA-1",
}

// DIGEST_SIZES is the Algorithm to digest size in bytes.
DIGEST_SIZES := [Algorithm]int {
	.Invalid           = 0,
	.BLAKE2B           = blake2b.DIGEST_SIZE,
	.BLAKE2S           = blake2s.DIGEST_SIZE,
	.SHA224            = sha2.DIGEST_SIZE_224,
	.SHA256            = sha2.DIGEST_SIZE_256,
	.SHA384            = sha2.DIGEST_SIZE_384,
	.SHA512            = sha2.DIGEST_SIZE_512,
	.SHA512_256        = sha2.DIGEST_SIZE_512_256,
	.SHA3_224          = sha3.DIGEST_SIZE_224,
	.SHA3_256          = sha3.DIGEST_SIZE_256,
	.SHA3_384          = sha3.DIGEST_SIZE_384,
	.SHA3_512          = sha3.DIGEST_SIZE_512,
	.SM3               = sm3.DIGEST_SIZE,
	.Legacy_KECCAK_224 = keccak.DIGEST_SIZE_224,
	.Legacy_KECCAK_256 = keccak.DIGEST_SIZE_256,
	.Legacy_KECCAK_384 = keccak.DIGEST_SIZE_384,
	.Legacy_KECCAK_512 = keccak.DIGEST_SIZE_512,
	.Insecure_MD5      = md5.DIGEST_SIZE,
	.Insecure_SHA1     = sha1.DIGEST_SIZE,
}

// BLOCK_SIZES is the Algoritm to block size in bytes.
BLOCK_SIZES := [Algorithm]int {
	.Invalid           = 0,
	.BLAKE2B           = blake2b.BLOCK_SIZE,
	.BLAKE2S           = blake2s.BLOCK_SIZE,
	.SHA224            = sha2.BLOCK_SIZE_256,
	.SHA256            = sha2.BLOCK_SIZE_256,
	.SHA384            = sha2.BLOCK_SIZE_512,
	.SHA512            = sha2.BLOCK_SIZE_512,
	.SHA512_256        = sha2.BLOCK_SIZE_512,
	.SHA3_224          = sha3.BLOCK_SIZE_224,
	.SHA3_256          = sha3.BLOCK_SIZE_256,
	.SHA3_384          = sha3.BLOCK_SIZE_384,
	.SHA3_512          = sha3.BLOCK_SIZE_512,
	.SM3               = sm3.BLOCK_SIZE,
	.Legacy_KECCAK_224 = keccak.BLOCK_SIZE_224,
	.Legacy_KECCAK_256 = keccak.BLOCK_SIZE_256,
	.Legacy_KECCAK_384 = keccak.BLOCK_SIZE_384,
	.Legacy_KECCAK_512 = keccak.BLOCK_SIZE_512,
	.Insecure_MD5      = md5.BLOCK_SIZE,
	.Insecure_SHA1     = sha1.BLOCK_SIZE,
}

// Context is a concrete instantiation of a specific hash algorithm.
Context :: struct {
	_algo: Algorithm,
	_impl: union {
		blake2b.Context,
		blake2s.Context,
		sha2.Context_256,
		sha2.Context_512,
		sha3.Context,
		sm3.Context,
		keccak.Context,
		md5.Context,
		sha1.Context,
	},
}

@(private)
_IMPL_IDS := [Algorithm]typeid {
	.Invalid           = nil,
	.BLAKE2B           = typeid_of(blake2b.Context),
	.BLAKE2S           = typeid_of(blake2s.Context),
	.SHA224            = typeid_of(sha2.Context_256),
	.SHA256            = typeid_of(sha2.Context_256),
	.SHA384            = typeid_of(sha2.Context_512),
	.SHA512            = typeid_of(sha2.Context_512),
	.SHA512_256        = typeid_of(sha2.Context_512),
	.SHA3_224          = typeid_of(sha3.Context),
	.SHA3_256          = typeid_of(sha3.Context),
	.SHA3_384          = typeid_of(sha3.Context),
	.SHA3_512          = typeid_of(sha3.Context),
	.SM3               = typeid_of(sm3.Context),
	.Legacy_KECCAK_224 = typeid_of(keccak.Context),
	.Legacy_KECCAK_256 = typeid_of(keccak.Context),
	.Legacy_KECCAK_384 = typeid_of(keccak.Context),
	.Legacy_KECCAK_512 = typeid_of(keccak.Context),
	.Insecure_MD5      = typeid_of(md5.Context),
	.Insecure_SHA1     = typeid_of(sha1.Context),
}

// init initializes a Context with a specific hash Algorithm.
init :: proc(ctx: ^Context, algorithm: Algorithm) {
	if ctx._impl != nil {
		reset(ctx)
	}

	// Directly specialize the union by setting the type ID (save a copy).
	reflect.set_union_variant_typeid(
		ctx._impl,
		_IMPL_IDS[algorithm],
	)
	switch algorithm {
	case .BLAKE2B:
		blake2b.init(&ctx._impl.(blake2b.Context))
	case .BLAKE2S:
		blake2s.init(&ctx._impl.(blake2s.Context))
	case .SHA224:
		sha2.init_224(&ctx._impl.(sha2.Context_256))
	case .SHA256:
		sha2.init_256(&ctx._impl.(sha2.Context_256))
	case .SHA384:
		sha2.init_384(&ctx._impl.(sha2.Context_512))
	case .SHA512:
		sha2.init_512(&ctx._impl.(sha2.Context_512))
	case .SHA512_256:
		sha2.init_512_256(&ctx._impl.(sha2.Context_512))
	case .SHA3_224:
		sha3.init_224(&ctx._impl.(sha3.Context))
	case .SHA3_256:
		sha3.init_256(&ctx._impl.(sha3.Context))
	case .SHA3_384:
		sha3.init_384(&ctx._impl.(sha3.Context))
	case .SHA3_512:
		sha3.init_512(&ctx._impl.(sha3.Context))
	case .SM3:
		sm3.init(&ctx._impl.(sm3.Context))
	case .Legacy_KECCAK_224:
		keccak.init_224(&ctx._impl.(keccak.Context))
	case .Legacy_KECCAK_256:
		keccak.init_256(&ctx._impl.(keccak.Context))
	case .Legacy_KECCAK_384:
		keccak.init_384(&ctx._impl.(keccak.Context))
	case .Legacy_KECCAK_512:
		keccak.init_512(&ctx._impl.(keccak.Context))
	case .Insecure_MD5:
		md5.init(&ctx._impl.(md5.Context))
	case .Insecure_SHA1:
		sha1.init(&ctx._impl.(sha1.Context))
	case .Invalid:
		panic("crypto/hash: uninitialized algorithm")
	case:
		panic("crypto/hash: invalid algorithm")
	}

	ctx._algo = algorithm
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	switch &impl in ctx._impl {
	case blake2b.Context:
		blake2b.update(&impl, data)
	case blake2s.Context:
		blake2s.update(&impl, data)
	case sha2.Context_256:
		sha2.update(&impl, data)
	case sha2.Context_512:
		sha2.update(&impl, data)
	case sha3.Context:
		sha3.update(&impl, data)
	case sm3.Context:
		sm3.update(&impl, data)
	case keccak.Context:
		keccak.update(&impl, data)
	case md5.Context:
		md5.update(&impl, data)
	case sha1.Context:
		sha1.update(&impl, data)
	case:
		panic("crypto/hash: uninitialized algorithm")
	}
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	switch &impl in ctx._impl {
	case blake2b.Context:
		blake2b.final(&impl, hash, finalize_clone)
	case blake2s.Context:
		blake2s.final(&impl, hash, finalize_clone)
	case sha2.Context_256:
		sha2.final(&impl, hash, finalize_clone)
	case sha2.Context_512:
		sha2.final(&impl, hash, finalize_clone)
	case sha3.Context:
		sha3.final(&impl, hash, finalize_clone)
	case sm3.Context:
		sm3.final(&impl, hash, finalize_clone)
	case keccak.Context:
		keccak.final(&impl, hash, finalize_clone)
	case md5.Context:
		md5.final(&impl, hash, finalize_clone)
	case sha1.Context:
		sha1.final(&impl, hash, finalize_clone)
	case:
		panic("crypto/hash: uninitialized algorithm")
	}

	if !finalize_clone {
		reset(ctx)
	}
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	// XXX/yawning: Maybe these cases should panic, because both cases,
	// are probably bugs.
	if ctx == other {
		return
	}
	if ctx._impl != nil {
		reset(ctx)
	}

	ctx._algo = other._algo

	reflect.set_union_variant_typeid(
		ctx._impl,
		reflect.union_variant_typeid(other._impl),
	)
	switch &src_impl in other._impl {
	case blake2b.Context:
		blake2b.clone(&ctx._impl.(blake2b.Context), &src_impl)
	case blake2s.Context:
		blake2s.clone(&ctx._impl.(blake2s.Context), &src_impl)
	case sha2.Context_256:
		sha2.clone(&ctx._impl.(sha2.Context_256), &src_impl)
	case sha2.Context_512:
		sha2.clone(&ctx._impl.(sha2.Context_512), &src_impl)
	case sha3.Context:
		sha3.clone(&ctx._impl.(sha3.Context), &src_impl)
	case sm3.Context:
		sm3.clone(&ctx._impl.(sm3.Context), &src_impl)
	case keccak.Context:
		keccak.clone(&ctx._impl.(keccak.Context), &src_impl)
	case md5.Context:
		md5.clone(&ctx._impl.(md5.Context), &src_impl)
	case sha1.Context:
		sha1.clone(&ctx._impl.(sha1.Context), &src_impl)
	case:
		panic("crypto/hash: uninitialized algorithm")
	}
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	switch &impl in ctx._impl {
	case blake2b.Context:
		blake2b.reset(&impl)
	case blake2s.Context:
		blake2s.reset(&impl)
	case sha2.Context_256:
		sha2.reset(&impl)
	case sha2.Context_512:
		sha2.reset(&impl)
	case sha3.Context:
		sha3.reset(&impl)
	case sm3.Context:
		sm3.reset(&impl)
	case keccak.Context:
		keccak.reset(&impl)
	case md5.Context:
		md5.reset(&impl)
	case sha1.Context:
		sha1.reset(&impl)
	case:
	// Unlike clone, calling reset repeatedly is fine.
	}

	ctx._algo = .Invalid
	ctx._impl = nil
}

// algorithm returns the Algorithm used by a Context instance.
algorithm :: proc(ctx: ^Context) -> Algorithm {
	return ctx._algo
}

// digest_size returns the digest size of a Context instance in bytes.
digest_size :: proc(ctx: ^Context) -> int {
	return DIGEST_SIZES[ctx._algo]
}

// block_size returns the block size of a Context instance in bytes.
block_size :: proc(ctx: ^Context) -> int {
	return BLOCK_SIZES[ctx._algo]
}
