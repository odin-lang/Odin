package crypto_hash

import "core:crypto/blake2b"
import "core:crypto/blake2s"
import "core:crypto/sha2"
import "core:crypto/sha3"
import "core:crypto/sm3"
import "core:crypto/legacy/keccak"
import "core:crypto/legacy/md5"
import "core:crypto/legacy/sha1"

import "core:mem"

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
		^blake2b.Context,
		^blake2s.Context,
		^sha2.Context_256,
		^sha2.Context_512,
		^sha3.Context,
		^sm3.Context,
		^keccak.Context,
		^md5.Context,
		^sha1.Context,
	},
	_allocator: mem.Allocator,
}

// init initializes a Context with a specific hash Algorithm.
//
// Warning: Internal state is allocated, and resources must be freed
// either implicitly via a call to final, or explicitly via calling reset.
init :: proc(ctx: ^Context, algorithm: Algorithm, allocator := context.allocator) {
	if ctx._impl != nil {
		reset(ctx)
	}

	switch algorithm {
	case .BLAKE2B:
		impl := new(blake2b.Context, allocator)
		blake2b.init(impl)
		ctx._impl = impl
	case .BLAKE2S:
		impl := new(blake2s.Context, allocator)
		blake2s.init(impl)
		ctx._impl = impl
	case .SHA224:
		impl := new(sha2.Context_256, allocator)
		sha2.init_224(impl)
		ctx._impl = impl
	case .SHA256:
		impl := new(sha2.Context_256, allocator)
		sha2.init_256(impl)
		ctx._impl = impl
	case .SHA384:
		impl := new(sha2.Context_512, allocator)
		sha2.init_384(impl)
		ctx._impl = impl
	case .SHA512:
		impl := new(sha2.Context_512, allocator)
		sha2.init_512(impl)
		ctx._impl = impl
	case .SHA512_256:
		impl := new(sha2.Context_512, allocator)
		sha2.init_512_256(impl)
		ctx._impl = impl
	case .SHA3_224:
		impl := new(sha3.Context, allocator)
		sha3.init_224(impl)
		ctx._impl = impl
	case .SHA3_256:
		impl := new(sha3.Context, allocator)
		sha3.init_256(impl)
		ctx._impl = impl
	case .SHA3_384:
		impl := new(sha3.Context, allocator)
		sha3.init_384(impl)
		ctx._impl = impl
	case .SHA3_512:
		impl := new(sha3.Context, allocator)
		sha3.init_512(impl)
		ctx._impl = impl
	case .SM3:
		impl := new(sm3.Context, allocator)
		sm3.init(impl)
		ctx._impl = impl
	case .Legacy_KECCAK_224:
		impl := new(keccak.Context, allocator)
		keccak.init_224(impl)
		ctx._impl = impl
	case .Legacy_KECCAK_256:
		impl := new(keccak.Context, allocator)
		keccak.init_256(impl)
		ctx._impl = impl
	case .Legacy_KECCAK_384:
		impl := new(keccak.Context, allocator)
		keccak.init_384(impl)
		ctx._impl = impl
	case .Legacy_KECCAK_512:
		impl := new(keccak.Context, allocator)
		keccak.init_512(impl)
		ctx._impl = impl
	case .Insecure_MD5:
		impl := new(md5.Context, allocator)
		md5.init(impl)
		ctx._impl = impl
	case .Insecure_SHA1:
		impl := new(sha1.Context, allocator)
		sha1.init(impl)
		ctx._impl = impl
	case .Invalid:
		panic("crypto/hash: uninitialized algorithm")
	case:
		panic("crypto/hash: invalid algorithm")
	}

	ctx._algo = algorithm
	ctx._allocator = allocator
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	switch impl in ctx._impl {
	case ^blake2b.Context:
		blake2b.update(impl, data)
	case ^blake2s.Context:
		blake2s.update(impl, data)
	case ^sha2.Context_256:
		sha2.update(impl, data)
	case ^sha2.Context_512:
		sha2.update(impl, data)
	case ^sha3.Context:
		sha3.update(impl, data)
	case ^sm3.Context:
		sm3.update(impl, data)
	case ^keccak.Context:
		keccak.update(impl, data)
	case ^md5.Context:
		md5.update(impl, data)
	case ^sha1.Context:
		sha1.update(impl, data)
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
	switch impl in ctx._impl {
	case ^blake2b.Context:
		blake2b.final(impl, hash, finalize_clone)
	case ^blake2s.Context:
		blake2s.final(impl, hash, finalize_clone)
	case ^sha2.Context_256:
		sha2.final(impl, hash, finalize_clone)
	case ^sha2.Context_512:
		sha2.final(impl, hash, finalize_clone)
	case ^sha3.Context:
		sha3.final(impl, hash, finalize_clone)
	case ^sm3.Context:
		sm3.final(impl, hash, finalize_clone)
	case ^keccak.Context:
		keccak.final(impl, hash, finalize_clone)
	case ^md5.Context:
		md5.final(impl, hash, finalize_clone)
	case ^sha1.Context:
		sha1.final(impl, hash, finalize_clone)
	case:
		panic("crypto/hash: uninitialized algorithm")
	}

	if !finalize_clone {
		reset(ctx)
	}
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context, allocator := context.allocator) {
	// XXX/yawning: Maybe these cases should panic, because both cases,
	// are probably bugs.
	if ctx == other {
		return
	}
	if ctx._impl != nil {
		reset(ctx)
	}

	ctx._algo = other._algo
	ctx._allocator = allocator

	switch src_impl in other._impl {
	case ^blake2b.Context:
		impl := new(blake2b.Context, allocator)
		blake2b.clone(impl, src_impl)
		ctx._impl = impl
	case ^blake2s.Context:
		impl := new(blake2s.Context, allocator)
		blake2s.clone(impl, src_impl)
		ctx._impl = impl
	case ^sha2.Context_256:
		impl := new(sha2.Context_256, allocator)
		sha2.clone(impl, src_impl)
		ctx._impl = impl
	case ^sha2.Context_512:
		impl := new(sha2.Context_512, allocator)
		sha2.clone(impl, src_impl)
		ctx._impl = impl
	case ^sha3.Context:
		impl := new(sha3.Context, allocator)
		sha3.clone(impl, src_impl)
		ctx._impl = impl
	case ^sm3.Context:
		impl := new(sm3.Context, allocator)
		sm3.clone(impl, src_impl)
		ctx._impl = impl
	case ^keccak.Context:
		impl := new(keccak.Context, allocator)
		keccak.clone(impl, src_impl)
		ctx._impl = impl
	case ^md5.Context:
		impl := new(md5.Context, allocator)
		md5.clone(impl, src_impl)
		ctx._impl = impl
	case ^sha1.Context:
		impl := new(sha1.Context, allocator)
		sha1.clone(impl, src_impl)
		ctx._impl = impl
	case:
		panic("crypto/hash: uninitialized algorithm")
	}
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	switch impl in ctx._impl {
	case ^blake2b.Context:
		blake2b.reset(impl)
		free(impl, ctx._allocator)
	case ^blake2s.Context:
		blake2s.reset(impl)
		free(impl, ctx._allocator)
	case ^sha2.Context_256:
		sha2.reset(impl)
		free(impl, ctx._allocator)
	case ^sha2.Context_512:
		sha2.reset(impl)
		free(impl, ctx._allocator)
	case ^sha3.Context:
		sha3.reset(impl)
		free(impl, ctx._allocator)
	case ^sm3.Context:
		sm3.reset(impl)
		free(impl, ctx._allocator)
	case ^keccak.Context:
		keccak.reset(impl)
		free(impl, ctx._allocator)
	case ^md5.Context:
		md5.reset(impl)
		free(impl, ctx._allocator)
	case ^sha1.Context:
		sha1.reset(impl)
		free(impl, ctx._allocator)
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
