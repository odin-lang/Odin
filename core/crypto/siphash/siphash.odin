/*
package siphash Implements the SipHash hashing algorithm.

Use the specific procedures for a certain setup. The generic procedures will default to Siphash 2-4.

See:
- [[ https://github.com/veorq/SipHash ]]
- [[ https://www.aumasson.jp/siphash/siphash.pdf ]]
*/
package siphash

/*
    Copyright 2022 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog:  Initial implementation.
*/

import "core:crypto"
import "core:encoding/endian"
import "core:math/bits"

/*
    High level API
*/

KEY_SIZE :: 16
DIGEST_SIZE :: 8

// sum_string_1_3 will hash the given message with the key and return
// the computed hash as a u64
sum_string_1_3 :: proc(msg, key: string) -> u64 {
	return sum_bytes_1_3(transmute([]byte)(msg), transmute([]byte)(key))
}

// sum_bytes_1_3 will hash the given message with the key and return
// the computed hash as a u64
sum_bytes_1_3 :: proc(msg, key: []byte) -> u64 {
	ctx: Context
	hash: u64
	init(&ctx, key, 1, 3)
	update(&ctx, msg)
	final(&ctx, &hash)
	return hash
}

// sum_string_to_buffer_1_3 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_1_3 :: proc(msg, key: string, dst: []byte) {
	sum_bytes_to_buffer_1_3(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_1_3 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_1_3 :: proc(msg, key, dst: []byte) {
	hash := sum_bytes_1_3(msg, key)
	_collect_output(dst[:], hash)
}

sum_1_3 :: proc {
	sum_string_1_3,
	sum_bytes_1_3,
	sum_string_to_buffer_1_3,
	sum_bytes_to_buffer_1_3,
}

// verify_u64_1_3 will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_u64_1_3 :: proc(tag: u64, msg, key: []byte) -> bool {
	return sum_bytes_1_3(msg, key) == tag
}

// verify_bytes will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_bytes_1_3 :: proc(tag, msg, key: []byte) -> bool {
	derived_tag: [8]byte
	sum_bytes_to_buffer_1_3(msg, key, derived_tag[:])
	return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

verify_1_3 :: proc {
	verify_bytes_1_3,
	verify_u64_1_3,
}

// sum_string_2_4 will hash the given message with the key and return
// the computed hash as a u64
sum_string_2_4 :: proc(msg, key: string) -> u64 {
	return sum_bytes_2_4(transmute([]byte)(msg), transmute([]byte)(key))
}

// sum_bytes_2_4 will hash the given message with the key and return
// the computed hash as a u64
sum_bytes_2_4 :: proc(msg, key: []byte) -> u64 {
	ctx: Context
	hash: u64
	init(&ctx, key, 2, 4)
	update(&ctx, msg)
	final(&ctx, &hash)
	return hash
}

// sum_string_to_buffer_2_4 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_2_4 :: proc(msg, key: string, dst: []byte) {
	sum_bytes_to_buffer_2_4(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_2_4 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_2_4 :: proc(msg, key, dst: []byte) {
	hash := sum_bytes_2_4(msg, key)
	_collect_output(dst[:], hash)
}

sum_2_4 :: proc {
	sum_string_2_4,
	sum_bytes_2_4,
	sum_string_to_buffer_2_4,
	sum_bytes_to_buffer_2_4,
}

sum_string :: sum_string_2_4
sum_bytes :: sum_bytes_2_4
sum_string_to_buffer :: sum_string_to_buffer_2_4
sum_bytes_to_buffer :: sum_bytes_to_buffer_2_4
sum :: proc {
	sum_string,
	sum_bytes,
	sum_string_to_buffer,
	sum_bytes_to_buffer,
}

// verify_u64_2_4 will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_u64_2_4 :: proc(tag: u64, msg, key: []byte) -> bool {
	return sum_bytes_2_4(msg, key) == tag
}

// verify_bytes will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_bytes_2_4 :: proc(tag, msg, key: []byte) -> bool {
	derived_tag: [8]byte
	sum_bytes_to_buffer_2_4(msg, key, derived_tag[:])
	return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

verify_2_4 :: proc {
	verify_bytes_2_4,
	verify_u64_2_4,
}

verify_bytes :: verify_bytes_2_4
verify_u64 :: verify_u64_2_4
verify :: proc {
	verify_bytes,
	verify_u64,
}

// sum_string_4_8 will hash the given message with the key and return
// the computed hash as a u64
sum_string_4_8 :: proc(msg, key: string) -> u64 {
	return sum_bytes_4_8(transmute([]byte)(msg), transmute([]byte)(key))
}

// sum_bytes_4_8 will hash the given message with the key and return
// the computed hash as a u64
sum_bytes_4_8 :: proc(msg, key: []byte) -> u64 {
	ctx: Context
	hash: u64
	init(&ctx, key, 4, 8)
	update(&ctx, msg)
	final(&ctx, &hash)
	return hash
}

// sum_string_to_buffer_4_8 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_4_8 :: proc(msg, key: string, dst: []byte) {
	sum_bytes_to_buffer_4_8(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_4_8 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_4_8 :: proc(msg, key, dst: []byte) {
	hash := sum_bytes_4_8(msg, key)
	_collect_output(dst[:], hash)
}

sum_4_8 :: proc {
	sum_string_4_8,
	sum_bytes_4_8,
	sum_string_to_buffer_4_8,
	sum_bytes_to_buffer_4_8,
}

// verify_u64_4_8 will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_u64_4_8 :: proc(tag: u64, msg, key: []byte) -> bool {
	return sum_bytes_4_8(msg, key) == tag
}

// verify_bytes will check if the supplied tag matches with the output you
// will get from the provided message and key
verify_bytes_4_8 :: proc(tag, msg, key: []byte) -> bool {
	derived_tag: [8]byte
	sum_bytes_to_buffer_4_8(msg, key, derived_tag[:])
	return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

verify_4_8 :: proc {
	verify_bytes_4_8,
	verify_u64_4_8,
}

/*
    Low level API
*/

init :: proc(ctx: ^Context, key: []byte, c_rounds, d_rounds: int) {
	ensure(len(key) == KEY_SIZE,"crypto/siphash; invalid key size")
	ctx.c_rounds = c_rounds
	ctx.d_rounds = d_rounds
	is_valid_setting :=
		(ctx.c_rounds == 1 && ctx.d_rounds == 3) ||
		(ctx.c_rounds == 2 && ctx.d_rounds == 4) ||
		(ctx.c_rounds == 4 && ctx.d_rounds == 8)
	ensure(is_valid_setting, "crypto/siphash: incorrect rounds set up")
	ctx.k0 = endian.unchecked_get_u64le(key[:8])
	ctx.k1 = endian.unchecked_get_u64le(key[8:])
	ctx.v0 = 0x736f6d6570736575 ~ ctx.k0
	ctx.v1 = 0x646f72616e646f6d ~ ctx.k1
	ctx.v2 = 0x6c7967656e657261 ~ ctx.k0
	ctx.v3 = 0x7465646279746573 ~ ctx.k1

	ctx.last_block = 0
	ctx.total_length = 0

	ctx.is_initialized = true
}

update :: proc(ctx: ^Context, data: []byte) {
	ensure(ctx.is_initialized)

	data := data
	ctx.total_length += len(data)
	if ctx.last_block > 0 {
		n := copy(ctx.buf[ctx.last_block:], data)
		ctx.last_block += n
		if ctx.last_block == BLOCK_SIZE {
			block(ctx, ctx.buf[:])
			ctx.last_block = 0
		}
		data = data[n:]
	}
	if len(data) >= BLOCK_SIZE {
		n := len(data) &~ (BLOCK_SIZE - 1)
		block(ctx, data[:n])
		data = data[n:]
	}
	if len(data) > 0 {
		ctx.last_block = copy(ctx.buf[:], data)
	}
}

final :: proc(ctx: ^Context, dst: ^u64) {
	ensure(ctx.is_initialized)

	tmp: [BLOCK_SIZE]byte
	copy(tmp[:], ctx.buf[:ctx.last_block])
	tmp[7] = byte(ctx.total_length & 0xff)
	block(ctx, tmp[:])

	ctx.v2 ~= 0xff

	for _ in 0 ..< ctx.d_rounds {
		_compress(ctx)
	}

	dst^ = ctx.v0 ~ ctx.v1 ~ ctx.v2 ~ ctx.v3

	reset(ctx)
}

reset :: proc(ctx: ^Context) {
	ctx.k0, ctx.k1 = 0, 0
	ctx.v0, ctx.v1 = 0, 0
	ctx.v2, ctx.v3 = 0, 0
	ctx.last_block = 0
	ctx.total_length = 0
	ctx.c_rounds = 0
	ctx.d_rounds = 0
	ctx.is_initialized = false
}

BLOCK_SIZE :: 8

Context :: struct {
	v0, v1, v2, v3: u64, // State values
	k0, k1:         u64, // Split key
	c_rounds:       int, // Number of message rounds
	d_rounds:       int, // Number of finalization rounds
	buf:            [BLOCK_SIZE]byte, // Provided data
	last_block:     int, // Offset from the last block
	total_length:   int,
	is_initialized: bool,
}

@(private)
block :: proc "contextless" (ctx: ^Context, buf: []byte) {
	buf := buf

	for len(buf) >= BLOCK_SIZE {
		m := endian.unchecked_get_u64le(buf)

		ctx.v3 ~= m
		for _ in 0 ..< ctx.c_rounds {
			_compress(ctx)
		}

		ctx.v0 ~= m

		buf = buf[BLOCK_SIZE:]
	}
}

@(private)
_get_byte :: #force_inline proc "contextless" (byte_num: byte, into: u64) -> byte {
	return byte(into >> (((~byte_num) & (size_of(u64) - 1)) << 3))
}

@(private)
_collect_output :: #force_inline proc(dst: []byte, hash: u64) {
	ensure(len(dst) >= DIGEST_SIZE, "crypto/siphash: invalid tag size")

	dst[0] = _get_byte(7, hash)
	dst[1] = _get_byte(6, hash)
	dst[2] = _get_byte(5, hash)
	dst[3] = _get_byte(4, hash)
	dst[4] = _get_byte(3, hash)
	dst[5] = _get_byte(2, hash)
	dst[6] = _get_byte(1, hash)
	dst[7] = _get_byte(0, hash)
}

@(private)
_compress :: #force_inline proc "contextless" (ctx: ^Context) {
	ctx.v0 += ctx.v1
	ctx.v1 = bits.rotate_left64(ctx.v1, 13)
	ctx.v1 ~= ctx.v0
	ctx.v0 = bits.rotate_left64(ctx.v0, 32)
	ctx.v2 += ctx.v3
	ctx.v3 = bits.rotate_left64(ctx.v3, 16)
	ctx.v3 ~= ctx.v2
	ctx.v0 += ctx.v3
	ctx.v3 = bits.rotate_left64(ctx.v3, 21)
	ctx.v3 ~= ctx.v0
	ctx.v2 += ctx.v1
	ctx.v1 = bits.rotate_left64(ctx.v1, 17)
	ctx.v1 ~= ctx.v2
	ctx.v2 = bits.rotate_left64(ctx.v2, 32)
}
