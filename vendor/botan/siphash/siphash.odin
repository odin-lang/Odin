package siphash

/*
    Copyright 2022 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog:  Initial implementation.

    Interface for the SipHash hashing algorithm.
    The hash will be computed via bindings to the Botan crypto library

    Use the specific procedures for a certain setup. The generic procdedures will default to Siphash 2-4
*/

import "core:crypto"
import "core:crypto/util"

import botan "../bindings"

KEY_SIZE    :: 16
DIGEST_SIZE :: 8

// sum_string_1_3 will hash the given message with the key and return
// the computed hash as a u64
sum_string_1_3 :: proc(msg, key: string) -> u64 {
    return sum_bytes_1_3(transmute([]byte)(msg), transmute([]byte)(key))
}

// sum_bytes_1_3 will hash the given message with the key and return
// the computed hash as a u64
sum_bytes_1_3 :: proc (msg, key: []byte) -> u64 {
    dst: [8]byte
    ctx: botan.mac_t
    init(&ctx, key[:], 1, 3)
    update(&ctx, msg[:])
    final(&ctx, dst[:])
    return util.U64_LE(dst[:])
}

// sum_string_to_buffer_1_3 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_1_3 :: proc(msg, key: string, dst: []byte) {
    sum_bytes_to_buffer_1_3(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_1_3 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_1_3 :: proc(msg, key, dst: []byte) {
    assert(len(dst) >= DIGEST_SIZE, "vendor/botan: Destination buffer needs to be at least of size 8")
    ctx: botan.mac_t
    init(&ctx, key[:], 1, 3)
    update(&ctx, msg[:])
    final(&ctx, dst[:])
}

sum_1_3 :: proc {
    sum_string_1_3,
    sum_bytes_1_3,
    sum_string_to_buffer_1_3,
    sum_bytes_to_buffer_1_3,
}

// verify_u64_1_3 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_u64_1_3 :: proc (tag: u64 msg, key: []byte) -> bool {
    return sum_bytes_1_3(msg, key) == tag
}

// verify_bytes_1_3 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_bytes_1_3 :: proc (tag, msg, key: []byte) -> bool {
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
sum_bytes_2_4 :: proc (msg, key: []byte) -> u64 {
    dst: [8]byte
    ctx: botan.mac_t
    init(&ctx, key[:])
    update(&ctx, msg[:])
    final(&ctx, dst[:])
    return util.U64_LE(dst[:])
}

// sum_string_to_buffer_2_4 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_2_4 :: proc(msg, key: string, dst: []byte) {
    sum_bytes_to_buffer_2_4(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_2_4 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_2_4 :: proc(msg, key, dst: []byte) {
    assert(len(dst) >= DIGEST_SIZE, "vendor/botan: Destination buffer needs to be at least of size 8")
    ctx: botan.mac_t
    init(&ctx, key[:])
    update(&ctx, msg[:])
    final(&ctx, dst[:])
}

sum_2_4 :: proc {
    sum_string_2_4,
    sum_bytes_2_4,
    sum_string_to_buffer_2_4,
    sum_bytes_to_buffer_2_4,
}

sum_string           :: sum_string_2_4
sum_bytes            :: sum_bytes_2_4
sum_string_to_buffer :: sum_string_to_buffer_2_4
sum_bytes_to_buffer  :: sum_bytes_to_buffer_2_4
sum :: proc {
    sum_string,
    sum_bytes,
    sum_string_to_buffer,
    sum_bytes_to_buffer,
}


// verify_u64_2_4 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_u64_2_4 :: proc (tag: u64 msg, key: []byte) -> bool {
    return sum_bytes_2_4(msg, key) == tag
}

// verify_bytes_2_4 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_bytes_2_4 :: proc (tag, msg, key: []byte) -> bool {
    derived_tag: [8]byte
    sum_bytes_to_buffer_2_4(msg, key, derived_tag[:])
    return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

verify_2_4 :: proc {
    verify_bytes_2_4,
    verify_u64_2_4,
}

verify_bytes :: verify_bytes_2_4
verify_u64   :: verify_u64_2_4
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
sum_bytes_4_8 :: proc (msg, key: []byte) -> u64 {
    dst: [8]byte
    ctx: botan.mac_t
    init(&ctx, key[:], 4, 8)
    update(&ctx, msg[:])
    final(&ctx, dst[:])
    return util.U64_LE(dst[:])
}

// sum_string_to_buffer_4_8 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_string_to_buffer_4_8 :: proc(msg, key: string, dst: []byte) {
    sum_bytes_to_buffer_2_4(transmute([]byte)(msg), transmute([]byte)(key), dst)
}

// sum_bytes_to_buffer_4_8 will hash the given message with the key and write
// the computed hash into the provided destination buffer
sum_bytes_to_buffer_4_8 :: proc(msg, key, dst: []byte) {
    assert(len(dst) >= DIGEST_SIZE, "vendor/botan: Destination buffer needs to be at least of size 8")
    ctx: botan.mac_t
    init(&ctx, key[:], 4, 8)
    update(&ctx, msg[:])
    final(&ctx, dst[:])
}

sum_4_8 :: proc {
    sum_string_4_8,
    sum_bytes_4_8,
    sum_string_to_buffer_4_8,
    sum_bytes_to_buffer_4_8,
}

// verify_u64_4_8 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_u64_4_8 :: proc (tag: u64 msg, key: []byte) -> bool {
    return sum_bytes_4_8(msg, key) == tag
}

// verify_bytes_4_8 will check if the supplied tag matches with the output you 
// will get from the provided message and key
verify_bytes_4_8 :: proc (tag, msg, key: []byte) -> bool {
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

Context :: botan.mac_t

init :: proc(ctx: ^botan.mac_t, key: []byte, c_rounds := 2, d_rounds := 4) {
    assert(len(key) == KEY_SIZE, "vendor/botan: Invalid key size, want 16")
    is_valid_setting := (c_rounds == 1 && d_rounds == 3) ||
                        (c_rounds == 2 && d_rounds == 4) ||
                        (c_rounds == 4 && d_rounds == 8) 
    assert(is_valid_setting, "vendor/botan: Incorrect rounds set up. Valid pairs are (1,3), (2,4) and (4,8)")
    if c_rounds == 1 && d_rounds == 3 {
        botan.mac_init(ctx, botan.MAC_SIPHASH_1_3, 0)
    } else if c_rounds == 2 && d_rounds == 4 {
        botan.mac_init(ctx, botan.MAC_SIPHASH_2_4, 0)
    } else if c_rounds == 4 && d_rounds == 8 {
        botan.mac_init(ctx, botan.MAC_SIPHASH_4_8, 0)
    }
    botan.mac_set_key(ctx^, len(key) == 0 ? nil : &key[0], uint(len(key)))
}

update :: proc "contextless" (ctx: ^botan.mac_t, data: []byte) {
    botan.mac_update(ctx^, len(data) == 0 ? nil : &data[0], uint(len(data)))
}

final :: proc "contextless" (ctx: ^botan.mac_t, dst: []byte) {
    botan.mac_final(ctx^, &dst[0])
    reset(ctx)
}

reset :: proc(ctx: ^botan.mac_t) {
    botan.mac_destroy(ctx^)
}