package _chacha20

import "base:intrinsics"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// KEY_SIZE is the (X)ChaCha20 key size in bytes.
KEY_SIZE :: 32
// IV_SIZE is the ChaCha20 IV size in bytes.
IV_SIZE :: 12
// XIV_SIZE is the XChaCha20 IV size in bytes.
XIV_SIZE :: 24

// MAX_CTR_IETF is the maximum counter value for the IETF flavor ChaCha20.
MAX_CTR_IETF :: 0xffffffff
// BLOCK_SIZE is the (X)ChaCha20 block size in bytes.
BLOCK_SIZE :: 64
// STATE_SIZE_U32 is the (X)ChaCha20 state size in u32s.
STATE_SIZE_U32 :: 16
// Rounds is the (X)ChaCha20 round count.
ROUNDS :: 20

// SIGMA_0 is sigma[0:4].
SIGMA_0: u32 : 0x61707865
// SIGMA_1 is sigma[4:8].
SIGMA_1: u32 : 0x3320646e
// SIGMA_2 is sigma[8:12].
SIGMA_2: u32 : 0x79622d32
// SIGMA_3 is sigma[12:16].
SIGMA_3: u32 : 0x6b206574

// Context is a ChaCha20 or XChaCha20 instance.
Context :: struct {
	_s:              [STATE_SIZE_U32]u32,
	_buffer:         [BLOCK_SIZE]byte,
	_off:            int,
	_is_ietf_flavor: bool,
	_is_initialized: bool,
}

// init inititializes a Context for ChaCha20 with the provided key and
// iv.
//
// WARNING: This ONLY handles ChaCha20.  XChaCha20 sub-key and IV
// derivation is expected to be handled by the caller, so that the
// HChaCha call can be suitably accelerated.
init :: proc "contextless" (ctx: ^Context, key, iv: []byte, is_xchacha: bool) {
	if len(key) != KEY_SIZE || len(iv) != IV_SIZE {
		intrinsics.trap()
	}

	k, n := key, iv

	ctx._s[0] = SIGMA_0
	ctx._s[1] = SIGMA_1
	ctx._s[2] = SIGMA_2
	ctx._s[3] = SIGMA_3
	ctx._s[4] = endian.unchecked_get_u32le(k[0:4])
	ctx._s[5] = endian.unchecked_get_u32le(k[4:8])
	ctx._s[6] = endian.unchecked_get_u32le(k[8:12])
	ctx._s[7] = endian.unchecked_get_u32le(k[12:16])
	ctx._s[8] = endian.unchecked_get_u32le(k[16:20])
	ctx._s[9] = endian.unchecked_get_u32le(k[20:24])
	ctx._s[10] = endian.unchecked_get_u32le(k[24:28])
	ctx._s[11] = endian.unchecked_get_u32le(k[28:32])
	ctx._s[12] = 0
	ctx._s[13] = endian.unchecked_get_u32le(n[0:4])
	ctx._s[14] = endian.unchecked_get_u32le(n[4:8])
	ctx._s[15] = endian.unchecked_get_u32le(n[8:12])

	ctx._off = BLOCK_SIZE
	ctx._is_ietf_flavor = !is_xchacha
	ctx._is_initialized = true
}

// seek seeks the (X)ChaCha20 stream counter to the specified block.
seek :: proc(ctx: ^Context, block_nr: u64) {
	assert(ctx._is_initialized)

	if ctx._is_ietf_flavor {
		if block_nr > MAX_CTR_IETF {
			panic("crypto/chacha20: attempted to seek past maximum counter")
		}
	} else {
		ctx._s[13] = u32(block_nr >> 32)
	}
	ctx._s[12] = u32(block_nr)
	ctx._off = BLOCK_SIZE
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	mem.zero_explicit(&ctx._s, size_of(ctx._s))
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))

	ctx._is_initialized = false
}

check_counter_limit :: proc(ctx: ^Context, nr_blocks: int) {
	// Enforce the maximum consumed keystream per IV.
	//
	// While all modern "standard" definitions of ChaCha20 use
	// the IETF 32-bit counter, for XChaCha20 most common
	// implementations allow for a 64-bit counter.
	//
	// Honestly, the answer here is "use a MRAE primitive", but
	// go with "common" practice in the case of XChaCha20.

	ERR_CTR_EXHAUSTED :: "crypto/chacha20: maximum (X)ChaCha20 keystream per IV reached"

	if ctx._is_ietf_flavor {
		if u64(ctx._s[12]) + u64(nr_blocks) > MAX_CTR_IETF {
			panic(ERR_CTR_EXHAUSTED)
		}
	} else {
		ctr := (u64(ctx._s[13]) << 32) | u64(ctx._s[12])
		if _, carry := bits.add_u64(ctr, u64(nr_blocks), 0); carry != 0 {
			panic(ERR_CTR_EXHAUSTED)
		}
	}
}
