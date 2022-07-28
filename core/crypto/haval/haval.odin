package haval

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation for the HAVAL hashing algorithm as defined in <https://web.archive.org/web/20150111210116/http://labs.calyptix.com/haval.php>
*/

import "core:mem"
import "core:os"
import "core:io"

import "../util"

/*
    High level API
*/

DIGEST_SIZE_128 :: 16
DIGEST_SIZE_160 :: 20
DIGEST_SIZE_192 :: 24
DIGEST_SIZE_224 :: 28
DIGEST_SIZE_256 :: 32

// hash_string_128_3 will hash the given input and return the
// computed hash
hash_string_128_3 :: proc(data: string) -> [DIGEST_SIZE_128]byte {
    return hash_bytes_128_3(transmute([]byte)(data))
}

// hash_bytes_128_3 will hash the given input and return the
// computed hash
hash_bytes_128_3 :: proc(data: []byte) -> [DIGEST_SIZE_128]byte {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_128_3 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_128_3 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_128_3(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_128_3 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_128_3 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_128, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_128_3 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128_3 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 3
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_128_3 will read the file provided by the given handle
// and compute a hash
hash_file_128_3 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_128]byte, bool) {
    if !load_at_once {
        return hash_stream_128_3(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128_3(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_128]byte{}, false
}

hash_128_3 :: proc {
    hash_stream_128_3,
    hash_file_128_3,
    hash_bytes_128_3,
    hash_string_128_3,
    hash_bytes_to_buffer_128_3,
    hash_string_to_buffer_128_3,
}

// hash_string_128_4 will hash the given input and return the
// computed hash
hash_string_128_4 :: proc(data: string) -> [DIGEST_SIZE_128]byte {
    return hash_bytes_128_4(transmute([]byte)(data))
}

// hash_bytes_128_4 will hash the given input and return the
// computed hash
hash_bytes_128_4 :: proc(data: []byte) -> [DIGEST_SIZE_128]byte {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_128_4 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_128_4 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_128_4(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_128_4 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_128_4 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_128, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_128_4 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128_4 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 4
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_128_4 will read the file provided by the given handle
// and compute a hash
hash_file_128_4 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_128]byte, bool) {
    if !load_at_once {
        return hash_stream_128_4(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128_4(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_128]byte{}, false
}

hash_128_4 :: proc {
    hash_stream_128_4,
    hash_file_128_4,
    hash_bytes_128_4,
    hash_string_128_4,
    hash_bytes_to_buffer_128_4,
    hash_string_to_buffer_128_4,
}

// hash_string_128_5 will hash the given input and return the
// computed hash
hash_string_128_5 :: proc(data: string) -> [DIGEST_SIZE_128]byte {
    return hash_bytes_128_5(transmute([]byte)(data))
}

// hash_bytes_128_5 will hash the given input and return the
// computed hash
hash_bytes_128_5 :: proc(data: []byte) -> [DIGEST_SIZE_128]byte {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_128_5 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_128_5 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_128_5(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_128_5 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_128_5 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_128, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_128_5 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128_5 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: Haval_Context
    ctx.hashbitlen = 128
    ctx.rounds = 5
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_128_5 will read the file provided by the given handle
// and compute a hash
hash_file_128_5 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_128]byte, bool) {
    if !load_at_once {
        return hash_stream_128_5(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128_5(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_128]byte{}, false
}

hash_128_5 :: proc {
    hash_stream_128_5,
    hash_file_128_5,
    hash_bytes_128_5,
    hash_string_128_5,
    hash_bytes_to_buffer_128_5,
    hash_string_to_buffer_128_5,
}

// hash_string_160_3 will hash the given input and return the
// computed hash
hash_string_160_3 :: proc(data: string) -> [DIGEST_SIZE_160]byte {
    return hash_bytes_160_3(transmute([]byte)(data))
}

// hash_bytes_160_3 will hash the given input and return the
// computed hash
hash_bytes_160_3 :: proc(data: []byte) -> [DIGEST_SIZE_160]byte {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_160_3 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_160_3 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_160_3(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_160_3 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_160_3 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_160, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_160_3 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160_3 :: proc(s: io.Stream) -> ([DIGEST_SIZE_160]byte, bool) {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 3
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_160_3 will read the file provided by the given handle
// and compute a hash
hash_file_160_3 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_160]byte, bool) {
    if !load_at_once {
        return hash_stream_160_3(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_160_3(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_160]byte{}, false
}

hash_160_3 :: proc {
    hash_stream_160_3,
    hash_file_160_3,
    hash_bytes_160_3,
    hash_string_160_3,
    hash_bytes_to_buffer_160_3,
    hash_string_to_buffer_160_3,
}

// hash_string_160_4 will hash the given input and return the
// computed hash
hash_string_160_4 :: proc(data: string) -> [DIGEST_SIZE_160]byte {
    return hash_bytes_160_4(transmute([]byte)(data))
}

// hash_bytes_160_4 will hash the given input and return the
// computed hash
hash_bytes_160_4 :: proc(data: []byte) -> [DIGEST_SIZE_160]byte {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_160_4 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_160_4 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_160_4(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_160_4 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_160_4 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_160, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_160_4 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160_4 :: proc(s: io.Stream) -> ([DIGEST_SIZE_160]byte, bool) {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 4
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_160_4 will read the file provided by the given handle
// and compute a hash
hash_file_160_4 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_160]byte, bool) {
    if !load_at_once {
        return hash_stream_160_4(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_160_4(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_160]byte{}, false
}

hash_160_4 :: proc {
    hash_stream_160_4,
    hash_file_160_4,
    hash_bytes_160_4,
    hash_string_160_4,
    hash_bytes_to_buffer_160_4,
    hash_string_to_buffer_160_4,
}

// hash_string_160_5 will hash the given input and return the
// computed hash
hash_string_160_5 :: proc(data: string) -> [DIGEST_SIZE_160]byte {
    return hash_bytes_160_5(transmute([]byte)(data))
}

// hash_bytes_160_5 will hash the given input and return the
// computed hash
hash_bytes_160_5 :: proc(data: []byte) -> [DIGEST_SIZE_160]byte {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_160_5 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_160_5 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_160_5(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_160_5 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_160_5 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_160, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_160_5 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160_5 :: proc(s: io.Stream) -> ([DIGEST_SIZE_160]byte, bool) {
    hash: [DIGEST_SIZE_160]byte
    ctx: Haval_Context
    ctx.hashbitlen = 160
    ctx.rounds = 5
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_160_5 will read the file provided by the given handle
// and compute a hash
hash_file_160_5 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_160]byte, bool) {
    if !load_at_once {
        return hash_stream_160_5(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_160_5(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_160]byte{}, false
}

hash_160_5 :: proc {
    hash_stream_160_5,
    hash_file_160_5,
    hash_bytes_160_5,
    hash_string_160_5,
    hash_bytes_to_buffer_160_5,
    hash_string_to_buffer_160_5,
}

// hash_string_192_3 will hash the given input and return the
// computed hash
hash_string_192_3 :: proc(data: string) -> [DIGEST_SIZE_192]byte {
    return hash_bytes_192_3(transmute([]byte)(data))
}

// hash_bytes_192_3 will hash the given input and return the
// computed hash
hash_bytes_192_3 :: proc(data: []byte) -> [DIGEST_SIZE_192]byte {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_192_3 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_192_3 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_192_3(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_192_3 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_192_3 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_192, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_192_3 will read the stream in chunks and compute a
// hash from its contents
hash_stream_192_3 :: proc(s: io.Stream) -> ([DIGEST_SIZE_192]byte, bool) {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 3
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_192_3 will read the file provided by the given handle
// and compute a hash
hash_file_192_3 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_192]byte, bool) {
    if !load_at_once {
        return hash_stream_192_3(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_192_3(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_192]byte{}, false
}

hash_192_3 :: proc {
    hash_stream_192_3,
    hash_file_192_3,
    hash_bytes_192_3,
    hash_string_192_3,
    hash_bytes_to_buffer_192_3,
    hash_string_to_buffer_192_3,
}

// hash_string_192_4 will hash the given input and return the
// computed hash
hash_string_192_4 :: proc(data: string) -> [DIGEST_SIZE_192]byte {
    return hash_bytes_192_4(transmute([]byte)(data))
}

// hash_bytes_192_4 will hash the given input and return the
// computed hash
hash_bytes_192_4 :: proc(data: []byte) -> [DIGEST_SIZE_192]byte {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_192_4 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_192_4 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_192_4(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_192_4 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_192_4 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_192, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_192_4 will read the stream in chunks and compute a
// hash from its contents
hash_stream_192_4 :: proc(s: io.Stream) -> ([DIGEST_SIZE_192]byte, bool) {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 4
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_192_4 will read the file provided by the given handle
// and compute a hash
hash_file_192_4 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_192]byte, bool) {
    if !load_at_once {
        return hash_stream_192_4(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_192_4(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_192]byte{}, false
}

hash_192_4 :: proc {
    hash_stream_192_4,
    hash_file_192_4,
    hash_bytes_192_4,
    hash_string_192_4,
    hash_bytes_to_buffer_192_4,
    hash_string_to_buffer_192_4,
}

// hash_string_192_5 will hash the given input and return the
// computed hash
hash_string_192_5 :: proc(data: string) -> [DIGEST_SIZE_192]byte {
    return hash_bytes_192_5(transmute([]byte)(data))
}

// hash_bytes_2DIGEST_SIZE_192_5 will hash the given input and return the
// computed hash
hash_bytes_192_5 :: proc(data: []byte) -> [DIGEST_SIZE_192]byte {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_192_5 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_192_5 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_192_5(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_192_5 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_192_5 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_192, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_192_5 will read the stream in chunks and compute a
// hash from its contents
hash_stream_192_5 :: proc(s: io.Stream) -> ([DIGEST_SIZE_192]byte, bool) {
    hash: [DIGEST_SIZE_192]byte
    ctx: Haval_Context
    ctx.hashbitlen = 192
    ctx.rounds = 5
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_192_5 will read the file provided by the given handle
// and compute a hash
hash_file_192_5 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_192]byte, bool) {
    if !load_at_once {
        return hash_stream_192_5(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_192_5(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_192]byte{}, false
}

hash_192_5 :: proc {
    hash_stream_192_5,
    hash_file_192_5,
    hash_bytes_192_5,
    hash_string_192_5,
    hash_bytes_to_buffer_192_5,
    hash_string_to_buffer_192_5,
}

// hash_string_224_3 will hash the given input and return the
// computed hash
hash_string_224_3 :: proc(data: string) -> [DIGEST_SIZE_224]byte {
    return hash_bytes_224_3(transmute([]byte)(data))
}

// hash_bytes_224_3 will hash the given input and return the
// computed hash
hash_bytes_224_3 :: proc(data: []byte) -> [DIGEST_SIZE_224]byte {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_224_3 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_224_3 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_224_3(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_224_3 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224_3 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224_3 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224_3 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 3
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_224_3 will read the file provided by the given handle
// and compute a hash
hash_file_224_3 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_224]byte, bool) {
    if !load_at_once {
        return hash_stream_224_3(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_224_3(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_224]byte{}, false
}

hash_224_3 :: proc {
    hash_stream_224_3,
    hash_file_224_3,
    hash_bytes_224_3,
    hash_string_224_3,
    hash_bytes_to_buffer_224_3,
    hash_string_to_buffer_224_3,
}

// hash_string_224_4 will hash the given input and return the
// computed hash
hash_string_224_4 :: proc(data: string) -> [DIGEST_SIZE_224]byte {
    return hash_bytes_224_4(transmute([]byte)(data))
}

// hash_bytes_224_4 will hash the given input and return the
// computed hash
hash_bytes_224_4 :: proc(data: []byte) -> [DIGEST_SIZE_224]byte {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_224_4 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_224_4 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_224_4(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_224_4 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224_4 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224_4 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224_4 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 4
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_224_4 will read the file provided by the given handle
// and compute a hash
hash_file_224_4 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_224]byte, bool) {
    if !load_at_once {
        return hash_stream_224_4(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_224_4(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_224]byte{}, false
}

hash_224_4 :: proc {
    hash_stream_224_4,
    hash_file_224_4,
    hash_bytes_224_4,
    hash_string_224_4,
    hash_bytes_to_buffer_224_4,
    hash_string_to_buffer_224_4,
}

// hash_string_224_5 will hash the given input and return the
// computed hash
hash_string_224_5 :: proc(data: string) -> [DIGEST_SIZE_224]byte {
    return hash_bytes_224_5(transmute([]byte)(data))
}

// hash_bytes_224_5 will hash the given input and return the
// computed hash
hash_bytes_224_5 :: proc(data: []byte) -> [DIGEST_SIZE_224]byte {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_224_5 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_224_5 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_224_5(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_224_5 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224_5 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224_5 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224_5 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Haval_Context
    ctx.hashbitlen = 224
    ctx.rounds = 5
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_224_5 will read the file provided by the given handle
// and compute a hash
hash_file_224_5 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_224]byte, bool) {
    if !load_at_once {
        return hash_stream_224_5(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_224_5(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_224]byte{}, false
}

hash_224_5 :: proc {
    hash_stream_224_5,
    hash_file_224_5,
    hash_bytes_224_5,
    hash_string_224_5,
    hash_bytes_to_buffer_224_5,
    hash_string_to_buffer_224_5,
}

// hash_string_256_3 will hash the given input and return the
// computed hash
hash_string_256_3 :: proc(data: string) -> [DIGEST_SIZE_256]byte {
    return hash_bytes_256_3(transmute([]byte)(data))
}

// hash_bytes_256_3 will hash the given input and return the
// computed hash
hash_bytes_256_3 :: proc(data: []byte) -> [DIGEST_SIZE_256]byte {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_256_3 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_256_3 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_256_3(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_256_3 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256_3 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 3
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_256_3 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256_3 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 3
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_256_3 will read the file provided by the given handle
// and compute a hash
hash_file_256_3 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_256]byte, bool) {
    if !load_at_once {
        return hash_stream_256_3(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_256_3(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_256]byte{}, false
}

hash_256_3 :: proc {
    hash_stream_256_3,
    hash_file_256_3,
    hash_bytes_256_3,
    hash_string_256_3,
    hash_bytes_to_buffer_256_3,
    hash_string_to_buffer_256_3,
}

// hash_string_256_4 will hash the given input and return the
// computed hash
hash_string_256_4 :: proc(data: string) -> [DIGEST_SIZE_256]byte {
    return hash_bytes_256_4(transmute([]byte)(data))
}

// hash_bytes_256_4 will hash the given input and return the
// computed hash
hash_bytes_256_4 :: proc(data: []byte) -> [DIGEST_SIZE_256]byte {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_256_4 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_256_4 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_256_4(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_256_4 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256_4 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 4
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_256_4 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256_4 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 4
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_256_4 will read the file provided by the given handle
// and compute a hash
hash_file_256_4 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_256]byte, bool) {
    if !load_at_once {
        return hash_stream_256_4(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_256_4(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_256]byte{}, false
}

hash_256_4 :: proc {
    hash_stream_256_4,
    hash_file_256_4,
    hash_bytes_256_4,
    hash_string_256_4,
    hash_bytes_to_buffer_256_4,
    hash_string_to_buffer_256_4,
}

// hash_string_256_5 will hash the given input and return the
// computed hash
hash_string_256_5 :: proc(data: string) -> [DIGEST_SIZE_256]byte {
    return hash_bytes_256_5(transmute([]byte)(data))
}

// hash_bytes_256_5 will hash the given input and return the
// computed hash
hash_bytes_256_5 :: proc(data: []byte) -> [DIGEST_SIZE_256]byte {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_256_5 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_256_5 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_256_5(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_256_5 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256_5 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 5
    init(&ctx)
    ctx.str_len = u32(len(data))
    update(&ctx, data)
    final(&ctx, hash)
}


// hash_stream_256_5 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256_5 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Haval_Context
    ctx.hashbitlen = 256
    ctx.rounds = 5
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        ctx.str_len = u32(len(buf[:read]))
        if read > 0 {
            update(&ctx, buf[:read])
        } 
    }
    final(&ctx, hash[:])
    return hash, true
}

// hash_file_256_5 will read the file provided by the given handle
// and compute a hash
hash_file_256_5 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_256]byte, bool) {
    if !load_at_once {
        return hash_stream_256_5(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_256_5(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_256]byte{}, false
}

hash_256_5 :: proc {
    hash_stream_256_5,
    hash_file_256_5,
    hash_bytes_256_5,
    hash_string_256_5,
    hash_bytes_to_buffer_256_5,
    hash_string_to_buffer_256_5,
}

/*
    Low level API
*/

init :: proc(ctx: ^Haval_Context) {
    assert(ctx.hashbitlen == 128 || ctx.hashbitlen == 160 || ctx.hashbitlen == 192 || ctx.hashbitlen == 224 || ctx.hashbitlen == 256, "hashbitlen must be set to 128, 160, 192, 224 or 256")
    assert(ctx.rounds == 3 || ctx.rounds == 4 || ctx.rounds == 5, "rounds must be set to 3, 4 or 5")
    ctx.fingerprint[0] = 0x243f6a88
    ctx.fingerprint[1] = 0x85a308d3
    ctx.fingerprint[2] = 0x13198a2e
    ctx.fingerprint[3] = 0x03707344
    ctx.fingerprint[4] = 0xa4093822
    ctx.fingerprint[5] = 0x299f31d0
    ctx.fingerprint[6] = 0x082efa98
    ctx.fingerprint[7] = 0xec4e6c89
}

// @note(zh): Make sure to set ctx.str_len to the remaining buffer size before calling this proc - e.g. ctx.str_len = u32(len(data))
update :: proc(ctx: ^Haval_Context, data: []byte) {
    i: u32
    rmd_len  := u32((ctx.count[0] >> 3) & 0x7f)
    fill_len := 128 - rmd_len
    str_len  := ctx.str_len

    ctx.count[0] += str_len << 3
    if ctx.count[0] < (str_len << 3) {
        ctx.count[1] += 1
    }
    ctx.count[1] += str_len >> 29

    when ODIN_ENDIAN == .Little {
        if rmd_len + str_len >= 128 {
            copy(util.slice_to_bytes(ctx.block[:])[rmd_len:], data[:fill_len])
            block(ctx, ctx.rounds)
            for i = fill_len; i + 127 < str_len; i += 128 {
                copy(util.slice_to_bytes(ctx.block[:]), data[i:128])
                block(ctx, ctx.rounds)
            }
            rmd_len = 0
        } else {
            i = 0
        }
        copy(util.slice_to_bytes(ctx.block[:])[rmd_len:], data[i:])
    } else {
        if rmd_len + str_len >= 128 {
            copy(ctx.remainder[rmd_len:], data[:fill_len])
            CH2UINT(ctx.remainder[:], ctx.block[:])
            block(ctx, ctx.rounds)
            for i = fill_len; i + 127 < str_len; i += 128 {
                copy(ctx.remainder[:], data[i:128])
                CH2UINT(ctx.remainder[:], ctx.block[:])
                block(ctx, ctx.rounds)
            }
            rmd_len = 0
        } else {
            i = 0
        }
        copy(ctx.remainder[rmd_len:], data[i:])
    }
}

final :: proc(ctx: ^Haval_Context, hash: []byte) {
    pad_len: u32
    tail: [10]byte

    tail[0] = byte(ctx.hashbitlen & 0x3) << 6 | byte(ctx.rounds & 0x7) << 3 | (VERSION & 0x7)
    tail[1] = byte(ctx.hashbitlen >> 2) & 0xff

    UINT2CH(ctx.count[:], util.slice_to_bytes(tail[2:]), 2)
    rmd_len := (ctx.count[0] >> 3) & 0x7f
    if rmd_len < 118 {
        pad_len = 118 - rmd_len
    } else {
        pad_len = 246 - rmd_len
    }

    ctx.str_len = pad_len
    update(ctx, PADDING[:])
    ctx.str_len = 10
    update(ctx, tail[:])
    tailor(ctx, ctx.hashbitlen)
    UINT2CH(ctx.fingerprint[:], hash, ctx.hashbitlen >> 5)

    mem.set(ctx, 0, size_of(ctx))
}

/*
    HAVAL implementation
*/

VERSION :: 1

Haval_Context :: struct {
    count:       [2]u32,
    fingerprint: [8]u32,
    block:       [32]u32,
    remainder:   [128]byte,
    rounds:      u32,
    hashbitlen:  u32,
    str_len:     u32,
}

PADDING := [128]byte {
   0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
}

F_1 :: #force_inline proc "contextless" (x6, x5, x4, x3, x2, x1, x0: u32) -> u32 {
    return ((x1) & ((x0) ~ (x4)) ~ (x2) & (x5) ~ (x3) & (x6) ~ (x0))
}

F_2 :: #force_inline proc "contextless" (x6, x5, x4, x3, x2, x1, x0: u32) -> u32 {
    return ((x2) & ((x1) & ~(x3) ~ (x4) & (x5) ~ (x6) ~ (x0)) ~ (x4) & ((x1) ~ (x5)) ~ (x3) & (x5) ~ (x0))
}

F_3 :: #force_inline proc "contextless" (x6, x5, x4, x3, x2, x1, x0: u32) -> u32 {
    return ((x3) & ((x1) & (x2) ~ (x6) ~ (x0)) ~ (x1) & (x4) ~ (x2) & (x5) ~ (x0))
}

F_4 :: #force_inline proc "contextless" (x6, x5, x4, x3, x2, x1, x0: u32) -> u32 {
    return ((x4) & ((x5) & ~(x2) ~ (x3) & ~(x6) ~ (x1) ~ (x6) ~ (x0)) ~ (x3) & ((x1) & (x2) ~ (x5) ~ (x6)) ~ (x2) & (x6) ~ (x0))
}

F_5 :: #force_inline proc "contextless" (x6, x5, x4, x3, x2, x1, x0: u32) -> u32 {
    return ((x0) & ((x1) & (x2) & (x3) ~ ~(x5)) ~ (x1) & (x4) ~ (x2) & (x5) ~ (x3) & (x6))
}

FPHI_1 :: #force_inline proc(x6, x5, x4, x3, x2, x1, x0, rounds: u32) -> u32 {
    switch rounds {
        case 3: return F_1(x1, x0, x3, x5, x6, x2, x4)
        case 4: return F_1(x2, x6, x1, x4, x5, x3, x0)
        case 5: return F_1(x3, x4, x1, x0, x5, x2, x6)
        case: assert(rounds < 3 || rounds > 5, "Rounds count not supported!")
    }
    return 0
}

FPHI_2 :: #force_inline proc(x6, x5, x4, x3, x2, x1, x0, rounds: u32) -> u32 {
    switch rounds {
        case 3: return F_2(x4, x2, x1, x0, x5, x3, x6)
        case 4: return F_2(x3, x5, x2, x0, x1, x6, x4)
        case 5: return F_2(x6, x2, x1, x0, x3, x4, x5)
        case: assert(rounds < 3 || rounds > 5, "Rounds count not supported!")
    }
    return 0
}

FPHI_3 :: #force_inline proc(x6, x5, x4, x3, x2, x1, x0, rounds: u32) -> u32 {
    switch rounds {
        case 3: return F_3(x6, x1, x2, x3, x4, x5, x0)
        case 4: return F_3(x1, x4, x3, x6, x0, x2, x5)
        case 5: return F_3(x2, x6, x0, x4, x3, x1, x5)
        case: assert(rounds < 3 || rounds > 5, "Rounds count not supported!")
    }
    return 0
}

FPHI_4 :: #force_inline proc(x6, x5, x4, x3, x2, x1, x0, rounds: u32) -> u32 {
    switch rounds {
        case 4: return F_4(x6, x4, x0, x5, x2, x1, x3)
        case 5: return F_4(x1, x5, x3, x2, x0, x4, x6)
        case: assert(rounds < 4 || rounds > 5, "Rounds count not supported!")
    }
    return 0
}

FPHI_5 :: #force_inline proc(x6, x5, x4, x3, x2, x1, x0, rounds: u32) -> u32 {
    switch rounds {
        case 5: return F_5(x2, x5, x0, x6, x4, x3, x1)
        case: assert(rounds != 5, "Rounds count not supported!")
    }
    return 0
}

FF_1 :: #force_inline proc(x7, x6, x5, x4, x3, x2, x1, x0, w, rounds: u32) -> u32 {
    tmp := FPHI_1(x6, x5, x4, x3, x2, x1, x0, rounds)
    x8 := util.ROTR32(tmp, 7) + util.ROTR32(x7, 11) + w
    return x8
}

FF_2 :: #force_inline proc(x7, x6, x5, x4, x3, x2, x1, x0, w, c, rounds: u32) -> u32 {
    tmp := FPHI_2(x6, x5, x4, x3, x2, x1, x0, rounds)
    x8 := util.ROTR32(tmp, 7) + util.ROTR32(x7, 11) + w + c
    return x8
}

FF_3 :: #force_inline proc(x7, x6, x5, x4, x3, x2, x1, x0, w, c, rounds: u32) -> u32 {
    tmp := FPHI_3(x6, x5, x4, x3, x2, x1, x0, rounds)
    x8 := util.ROTR32(tmp, 7) + util.ROTR32(x7, 11) + w + c
    return x8
}

FF_4 :: #force_inline proc(x7, x6, x5, x4, x3, x2, x1, x0, w, c, rounds: u32) -> u32 {
    tmp := FPHI_4(x6, x5, x4, x3, x2, x1, x0, rounds)
    x8 := util.ROTR32(tmp, 7) + util.ROTR32(x7, 11) + w + c
    return x8
}

FF_5 :: #force_inline proc(x7, x6, x5, x4, x3, x2, x1, x0, w, c, rounds: u32) -> u32 {
    tmp := FPHI_5(x6, x5, x4, x3, x2, x1, x0, rounds)
    x8 := util.ROTR32(tmp, 7) + util.ROTR32(x7, 11) + w + c
    return x8
}

CH2UINT :: #force_inline proc "contextless" (str: []byte, word: []u32) {
    for _, i in word[:32] {
        word[i] = u32(str[i*4+0]) << 0 | u32(str[i*4+1]) << 8 | u32(str[i*4+2]) << 16 | u32(str[i*4+3]) << 24
    }
}

UINT2CH :: #force_inline proc "contextless" (word: []u32, str: []byte, wlen: u32) {
    for _, i in word[:wlen] {
        str[i*4+0] = byte(word[i] >> 0) & 0xff
        str[i*4+1] = byte(word[i] >> 8) & 0xff
        str[i*4+2] = byte(word[i] >> 16) & 0xff
        str[i*4+3] = byte(word[i] >> 24) & 0xff
    }
}

block :: proc(ctx: ^Haval_Context, rounds: u32) {
    t0, t1, t2, t3 := ctx.fingerprint[0], ctx.fingerprint[1], ctx.fingerprint[2], ctx.fingerprint[3]
    t4, t5, t6, t7 := ctx.fingerprint[4], ctx.fingerprint[5], ctx.fingerprint[6], ctx.fingerprint[7]
    w := ctx.block

    t7 = FF_1(t7, t6, t5, t4, t3, t2, t1, t0, w[ 0], rounds)
    t6 = FF_1(t6, t5, t4, t3, t2, t1, t0, t7, w[ 1], rounds)
    t5 = FF_1(t5, t4, t3, t2, t1, t0, t7, t6, w[ 2], rounds)
    t4 = FF_1(t4, t3, t2, t1, t0, t7, t6, t5, w[ 3], rounds)
    t3 = FF_1(t3, t2, t1, t0, t7, t6, t5, t4, w[ 4], rounds)
    t2 = FF_1(t2, t1, t0, t7, t6, t5, t4, t3, w[ 5], rounds)
    t1 = FF_1(t1, t0, t7, t6, t5, t4, t3, t2, w[ 6], rounds)
    t0 = FF_1(t0, t7, t6, t5, t4, t3, t2, t1, w[ 7], rounds)

    t7 = FF_1(t7, t6, t5, t4, t3, t2, t1, t0, w[ 8], rounds)
    t6 = FF_1(t6, t5, t4, t3, t2, t1, t0, t7, w[ 9], rounds)
    t5 = FF_1(t5, t4, t3, t2, t1, t0, t7, t6, w[10], rounds)
    t4 = FF_1(t4, t3, t2, t1, t0, t7, t6, t5, w[11], rounds)
    t3 = FF_1(t3, t2, t1, t0, t7, t6, t5, t4, w[12], rounds)
    t2 = FF_1(t2, t1, t0, t7, t6, t5, t4, t3, w[13], rounds)
    t1 = FF_1(t1, t0, t7, t6, t5, t4, t3, t2, w[14], rounds)
    t0 = FF_1(t0, t7, t6, t5, t4, t3, t2, t1, w[15], rounds)

    t7 = FF_1(t7, t6, t5, t4, t3, t2, t1, t0, w[16], rounds)
    t6 = FF_1(t6, t5, t4, t3, t2, t1, t0, t7, w[17], rounds)
    t5 = FF_1(t5, t4, t3, t2, t1, t0, t7, t6, w[18], rounds)
    t4 = FF_1(t4, t3, t2, t1, t0, t7, t6, t5, w[19], rounds)
    t3 = FF_1(t3, t2, t1, t0, t7, t6, t5, t4, w[20], rounds)
    t2 = FF_1(t2, t1, t0, t7, t6, t5, t4, t3, w[21], rounds)
    t1 = FF_1(t1, t0, t7, t6, t5, t4, t3, t2, w[22], rounds)
    t0 = FF_1(t0, t7, t6, t5, t4, t3, t2, t1, w[23], rounds)

    t7 = FF_1(t7, t6, t5, t4, t3, t2, t1, t0, w[24], rounds)
    t6 = FF_1(t6, t5, t4, t3, t2, t1, t0, t7, w[25], rounds)
    t5 = FF_1(t5, t4, t3, t2, t1, t0, t7, t6, w[26], rounds)
    t4 = FF_1(t4, t3, t2, t1, t0, t7, t6, t5, w[27], rounds)
    t3 = FF_1(t3, t2, t1, t0, t7, t6, t5, t4, w[28], rounds)
    t2 = FF_1(t2, t1, t0, t7, t6, t5, t4, t3, w[29], rounds)
    t1 = FF_1(t1, t0, t7, t6, t5, t4, t3, t2, w[30], rounds)
    t0 = FF_1(t0, t7, t6, t5, t4, t3, t2, t1, w[31], rounds)

    t7 = FF_2(t7, t6, t5, t4, t3, t2, t1, t0, w[ 5], 0x452821e6, rounds)
    t6 = FF_2(t6, t5, t4, t3, t2, t1, t0, t7, w[14], 0x38d01377, rounds)
    t5 = FF_2(t5, t4, t3, t2, t1, t0, t7, t6, w[26], 0xbe5466cf, rounds)
    t4 = FF_2(t4, t3, t2, t1, t0, t7, t6, t5, w[18], 0x34e90c6c, rounds)
    t3 = FF_2(t3, t2, t1, t0, t7, t6, t5, t4, w[11], 0xc0ac29b7, rounds)
    t2 = FF_2(t2, t1, t0, t7, t6, t5, t4, t3, w[28], 0xc97c50dd, rounds)
    t1 = FF_2(t1, t0, t7, t6, t5, t4, t3, t2, w[ 7], 0x3f84d5b5, rounds)
    t0 = FF_2(t0, t7, t6, t5, t4, t3, t2, t1, w[16], 0xb5470917, rounds)

    t7 = FF_2(t7, t6, t5, t4, t3, t2, t1, t0, w[ 0], 0x9216d5d9, rounds)
    t6 = FF_2(t6, t5, t4, t3, t2, t1, t0, t7, w[23], 0x8979fb1b, rounds)
    t5 = FF_2(t5, t4, t3, t2, t1, t0, t7, t6, w[20], 0xd1310ba6, rounds)
    t4 = FF_2(t4, t3, t2, t1, t0, t7, t6, t5, w[22], 0x98dfb5ac, rounds)
    t3 = FF_2(t3, t2, t1, t0, t7, t6, t5, t4, w[ 1], 0x2ffd72db, rounds)
    t2 = FF_2(t2, t1, t0, t7, t6, t5, t4, t3, w[10], 0xd01adfb7, rounds)
    t1 = FF_2(t1, t0, t7, t6, t5, t4, t3, t2, w[ 4], 0xb8e1afed, rounds)
    t0 = FF_2(t0, t7, t6, t5, t4, t3, t2, t1, w[ 8], 0x6a267e96, rounds)

    t7 = FF_2(t7, t6, t5, t4, t3, t2, t1, t0, w[30], 0xba7c9045, rounds)
    t6 = FF_2(t6, t5, t4, t3, t2, t1, t0, t7, w[ 3], 0xf12c7f99, rounds)
    t5 = FF_2(t5, t4, t3, t2, t1, t0, t7, t6, w[21], 0x24a19947, rounds)
    t4 = FF_2(t4, t3, t2, t1, t0, t7, t6, t5, w[ 9], 0xb3916cf7, rounds)
    t3 = FF_2(t3, t2, t1, t0, t7, t6, t5, t4, w[17], 0x0801f2e2, rounds)
    t2 = FF_2(t2, t1, t0, t7, t6, t5, t4, t3, w[24], 0x858efc16, rounds)
    t1 = FF_2(t1, t0, t7, t6, t5, t4, t3, t2, w[29], 0x636920d8, rounds)
    t0 = FF_2(t0, t7, t6, t5, t4, t3, t2, t1, w[ 6], 0x71574e69, rounds)

    t7 = FF_2(t7, t6, t5, t4, t3, t2, t1, t0, w[19], 0xa458fea3, rounds)
    t6 = FF_2(t6, t5, t4, t3, t2, t1, t0, t7, w[12], 0xf4933d7e, rounds)
    t5 = FF_2(t5, t4, t3, t2, t1, t0, t7, t6, w[15], 0x0d95748f, rounds)
    t4 = FF_2(t4, t3, t2, t1, t0, t7, t6, t5, w[13], 0x728eb658, rounds)
    t3 = FF_2(t3, t2, t1, t0, t7, t6, t5, t4, w[ 2], 0x718bcd58, rounds)
    t2 = FF_2(t2, t1, t0, t7, t6, t5, t4, t3, w[25], 0x82154aee, rounds)
    t1 = FF_2(t1, t0, t7, t6, t5, t4, t3, t2, w[31], 0x7b54a41d, rounds)
    t0 = FF_2(t0, t7, t6, t5, t4, t3, t2, t1, w[27], 0xc25a59b5, rounds)

    t7 = FF_3(t7, t6, t5, t4, t3, t2, t1, t0, w[19], 0x9c30d539, rounds)
    t6 = FF_3(t6, t5, t4, t3, t2, t1, t0, t7, w[ 9], 0x2af26013, rounds)
    t5 = FF_3(t5, t4, t3, t2, t1, t0, t7, t6, w[ 4], 0xc5d1b023, rounds)
    t4 = FF_3(t4, t3, t2, t1, t0, t7, t6, t5, w[20], 0x286085f0, rounds)
    t3 = FF_3(t3, t2, t1, t0, t7, t6, t5, t4, w[28], 0xca417918, rounds)
    t2 = FF_3(t2, t1, t0, t7, t6, t5, t4, t3, w[17], 0xb8db38ef, rounds)
    t1 = FF_3(t1, t0, t7, t6, t5, t4, t3, t2, w[ 8], 0x8e79dcb0, rounds)
    t0 = FF_3(t0, t7, t6, t5, t4, t3, t2, t1, w[22], 0x603a180e, rounds)

    t7 = FF_3(t7, t6, t5, t4, t3, t2, t1, t0, w[29], 0x6c9e0e8b, rounds)
    t6 = FF_3(t6, t5, t4, t3, t2, t1, t0, t7, w[14], 0xb01e8a3e, rounds)
    t5 = FF_3(t5, t4, t3, t2, t1, t0, t7, t6, w[25], 0xd71577c1, rounds)
    t4 = FF_3(t4, t3, t2, t1, t0, t7, t6, t5, w[12], 0xbd314b27, rounds)
    t3 = FF_3(t3, t2, t1, t0, t7, t6, t5, t4, w[24], 0x78af2fda, rounds)
    t2 = FF_3(t2, t1, t0, t7, t6, t5, t4, t3, w[30], 0x55605c60, rounds)
    t1 = FF_3(t1, t0, t7, t6, t5, t4, t3, t2, w[16], 0xe65525f3, rounds)
    t0 = FF_3(t0, t7, t6, t5, t4, t3, t2, t1, w[26], 0xaa55ab94, rounds)

    t7 = FF_3(t7, t6, t5, t4, t3, t2, t1, t0, w[31], 0x57489862, rounds)
    t6 = FF_3(t6, t5, t4, t3, t2, t1, t0, t7, w[15], 0x63e81440, rounds)
    t5 = FF_3(t5, t4, t3, t2, t1, t0, t7, t6, w[ 7], 0x55ca396a, rounds)
    t4 = FF_3(t4, t3, t2, t1, t0, t7, t6, t5, w[ 3], 0x2aab10b6, rounds)
    t3 = FF_3(t3, t2, t1, t0, t7, t6, t5, t4, w[ 1], 0xb4cc5c34, rounds)
    t2 = FF_3(t2, t1, t0, t7, t6, t5, t4, t3, w[ 0], 0x1141e8ce, rounds)
    t1 = FF_3(t1, t0, t7, t6, t5, t4, t3, t2, w[18], 0xa15486af, rounds)
    t0 = FF_3(t0, t7, t6, t5, t4, t3, t2, t1, w[27], 0x7c72e993, rounds)

    t7 = FF_3(t7, t6, t5, t4, t3, t2, t1, t0, w[13], 0xb3ee1411, rounds)
    t6 = FF_3(t6, t5, t4, t3, t2, t1, t0, t7, w[ 6], 0x636fbc2a, rounds)
    t5 = FF_3(t5, t4, t3, t2, t1, t0, t7, t6, w[21], 0x2ba9c55d, rounds)
    t4 = FF_3(t4, t3, t2, t1, t0, t7, t6, t5, w[10], 0x741831f6, rounds)
    t3 = FF_3(t3, t2, t1, t0, t7, t6, t5, t4, w[23], 0xce5c3e16, rounds)
    t2 = FF_3(t2, t1, t0, t7, t6, t5, t4, t3, w[11], 0x9b87931e, rounds)
    t1 = FF_3(t1, t0, t7, t6, t5, t4, t3, t2, w[ 5], 0xafd6ba33, rounds)
    t0 = FF_3(t0, t7, t6, t5, t4, t3, t2, t1, w[ 2], 0x6c24cf5c, rounds)

    if rounds >= 4 {
        t7 = FF_4(t7, t6, t5, t4, t3, t2, t1, t0, w[24], 0x7a325381, rounds)
        t6 = FF_4(t6, t5, t4, t3, t2, t1, t0, t7, w[ 4], 0x28958677, rounds)
        t5 = FF_4(t5, t4, t3, t2, t1, t0, t7, t6, w[ 0], 0x3b8f4898, rounds)
        t4 = FF_4(t4, t3, t2, t1, t0, t7, t6, t5, w[14], 0x6b4bb9af, rounds)
        t3 = FF_4(t3, t2, t1, t0, t7, t6, t5, t4, w[ 2], 0xc4bfe81b, rounds)
        t2 = FF_4(t2, t1, t0, t7, t6, t5, t4, t3, w[ 7], 0x66282193, rounds)
        t1 = FF_4(t1, t0, t7, t6, t5, t4, t3, t2, w[28], 0x61d809cc, rounds)
        t0 = FF_4(t0, t7, t6, t5, t4, t3, t2, t1, w[23], 0xfb21a991, rounds)

        t7 = FF_4(t7, t6, t5, t4, t3, t2, t1, t0, w[26], 0x487cac60, rounds)
        t6 = FF_4(t6, t5, t4, t3, t2, t1, t0, t7, w[ 6], 0x5dec8032, rounds)
        t5 = FF_4(t5, t4, t3, t2, t1, t0, t7, t6, w[30], 0xef845d5d, rounds)
        t4 = FF_4(t4, t3, t2, t1, t0, t7, t6, t5, w[20], 0xe98575b1, rounds)
        t3 = FF_4(t3, t2, t1, t0, t7, t6, t5, t4, w[18], 0xdc262302, rounds)
        t2 = FF_4(t2, t1, t0, t7, t6, t5, t4, t3, w[25], 0xeb651b88, rounds)
        t1 = FF_4(t1, t0, t7, t6, t5, t4, t3, t2, w[19], 0x23893e81, rounds)
        t0 = FF_4(t0, t7, t6, t5, t4, t3, t2, t1, w[ 3], 0xd396acc5, rounds)

        t7 = FF_4(t7, t6, t5, t4, t3, t2, t1, t0, w[22], 0x0f6d6ff3, rounds)
        t6 = FF_4(t6, t5, t4, t3, t2, t1, t0, t7, w[11], 0x83f44239, rounds)
        t5 = FF_4(t5, t4, t3, t2, t1, t0, t7, t6, w[31], 0x2e0b4482, rounds)
        t4 = FF_4(t4, t3, t2, t1, t0, t7, t6, t5, w[21], 0xa4842004, rounds)
        t3 = FF_4(t3, t2, t1, t0, t7, t6, t5, t4, w[ 8], 0x69c8f04a, rounds)
        t2 = FF_4(t2, t1, t0, t7, t6, t5, t4, t3, w[27], 0x9e1f9b5e, rounds)
        t1 = FF_4(t1, t0, t7, t6, t5, t4, t3, t2, w[12], 0x21c66842, rounds)
        t0 = FF_4(t0, t7, t6, t5, t4, t3, t2, t1, w[ 9], 0xf6e96c9a, rounds)

        t7 = FF_4(t7, t6, t5, t4, t3, t2, t1, t0, w[ 1], 0x670c9c61, rounds)
        t6 = FF_4(t6, t5, t4, t3, t2, t1, t0, t7, w[29], 0xabd388f0, rounds)
        t5 = FF_4(t5, t4, t3, t2, t1, t0, t7, t6, w[ 5], 0x6a51a0d2, rounds)
        t4 = FF_4(t4, t3, t2, t1, t0, t7, t6, t5, w[15], 0xd8542f68, rounds)
        t3 = FF_4(t3, t2, t1, t0, t7, t6, t5, t4, w[17], 0x960fa728, rounds)
        t2 = FF_4(t2, t1, t0, t7, t6, t5, t4, t3, w[10], 0xab5133a3, rounds)
        t1 = FF_4(t1, t0, t7, t6, t5, t4, t3, t2, w[16], 0x6eef0b6c, rounds)
        t0 = FF_4(t0, t7, t6, t5, t4, t3, t2, t1, w[13], 0x137a3be4, rounds)
    }

    if rounds == 5 {
        t7 = FF_5(t7, t6, t5, t4, t3, t2, t1, t0, w[27], 0xba3bf050, rounds)
        t6 = FF_5(t6, t5, t4, t3, t2, t1, t0, t7, w[ 3], 0x7efb2a98, rounds)
        t5 = FF_5(t5, t4, t3, t2, t1, t0, t7, t6, w[21], 0xa1f1651d, rounds)
        t4 = FF_5(t4, t3, t2, t1, t0, t7, t6, t5, w[26], 0x39af0176, rounds)
        t3 = FF_5(t3, t2, t1, t0, t7, t6, t5, t4, w[17], 0x66ca593e, rounds)
        t2 = FF_5(t2, t1, t0, t7, t6, t5, t4, t3, w[11], 0x82430e88, rounds)
        t1 = FF_5(t1, t0, t7, t6, t5, t4, t3, t2, w[20], 0x8cee8619, rounds)
        t0 = FF_5(t0, t7, t6, t5, t4, t3, t2, t1, w[29], 0x456f9fb4, rounds)

        t7 = FF_5(t7, t6, t5, t4, t3, t2, t1, t0, w[19], 0x7d84a5c3, rounds)
        t6 = FF_5(t6, t5, t4, t3, t2, t1, t0, t7, w[ 0], 0x3b8b5ebe, rounds)
        t5 = FF_5(t5, t4, t3, t2, t1, t0, t7, t6, w[12], 0xe06f75d8, rounds)
        t4 = FF_5(t4, t3, t2, t1, t0, t7, t6, t5, w[ 7], 0x85c12073, rounds)
        t3 = FF_5(t3, t2, t1, t0, t7, t6, t5, t4, w[13], 0x401a449f, rounds)
        t2 = FF_5(t2, t1, t0, t7, t6, t5, t4, t3, w[ 8], 0x56c16aa6, rounds)
        t1 = FF_5(t1, t0, t7, t6, t5, t4, t3, t2, w[31], 0x4ed3aa62, rounds)
        t0 = FF_5(t0, t7, t6, t5, t4, t3, t2, t1, w[10], 0x363f7706, rounds)

        t7 = FF_5(t7, t6, t5, t4, t3, t2, t1, t0, w[ 5], 0x1bfedf72, rounds)
        t6 = FF_5(t6, t5, t4, t3, t2, t1, t0, t7, w[ 9], 0x429b023d, rounds)
        t5 = FF_5(t5, t4, t3, t2, t1, t0, t7, t6, w[14], 0x37d0d724, rounds)
        t4 = FF_5(t4, t3, t2, t1, t0, t7, t6, t5, w[30], 0xd00a1248, rounds)
        t3 = FF_5(t3, t2, t1, t0, t7, t6, t5, t4, w[18], 0xdb0fead3, rounds)
        t2 = FF_5(t2, t1, t0, t7, t6, t5, t4, t3, w[ 6], 0x49f1c09b, rounds)
        t1 = FF_5(t1, t0, t7, t6, t5, t4, t3, t2, w[28], 0x075372c9, rounds)
        t0 = FF_5(t0, t7, t6, t5, t4, t3, t2, t1, w[24], 0x80991b7b, rounds)

        t7 = FF_5(t7, t6, t5, t4, t3, t2, t1, t0, w[ 2], 0x25d479d8, rounds)
        t6 = FF_5(t6, t5, t4, t3, t2, t1, t0, t7, w[23], 0xf6e8def7, rounds)
        t5 = FF_5(t5, t4, t3, t2, t1, t0, t7, t6, w[16], 0xe3fe501a, rounds)
        t4 = FF_5(t4, t3, t2, t1, t0, t7, t6, t5, w[22], 0xb6794c3b, rounds)
        t3 = FF_5(t3, t2, t1, t0, t7, t6, t5, t4, w[ 4], 0x976ce0bd, rounds)
        t2 = FF_5(t2, t1, t0, t7, t6, t5, t4, t3, w[ 1], 0x04c006ba, rounds)
        t1 = FF_5(t1, t0, t7, t6, t5, t4, t3, t2, w[25], 0xc1a94fb6, rounds)
        t0 = FF_5(t0, t7, t6, t5, t4, t3, t2, t1, w[15], 0x409f60c4, rounds)
    }

    ctx.fingerprint[0] += t0
    ctx.fingerprint[1] += t1
    ctx.fingerprint[2] += t2
    ctx.fingerprint[3] += t3
    ctx.fingerprint[4] += t4
    ctx.fingerprint[5] += t5
    ctx.fingerprint[6] += t6
    ctx.fingerprint[7] += t7
}

tailor :: proc(ctx: ^Haval_Context, size: u32) {
    temp: u32
    switch size {
        case 128:
            temp = (ctx.fingerprint[7] & 0x000000ff) | 
                   (ctx.fingerprint[6] & 0xff000000) | 
                   (ctx.fingerprint[5] & 0x00ff0000) | 
                   (ctx.fingerprint[4] & 0x0000ff00)
            ctx.fingerprint[0] += util.ROTR32(temp, 8)

            temp = (ctx.fingerprint[7] & 0x0000ff00) | 
                   (ctx.fingerprint[6] & 0x000000ff) | 
                   (ctx.fingerprint[5] & 0xff000000) | 
                   (ctx.fingerprint[4] & 0x00ff0000)
            ctx.fingerprint[1] += util.ROTR32(temp, 16)

            temp = (ctx.fingerprint[7] & 0x00ff0000) | 
                   (ctx.fingerprint[6] & 0x0000ff00) | 
                   (ctx.fingerprint[5] & 0x000000ff) | 
                   (ctx.fingerprint[4] & 0xff000000)
            ctx.fingerprint[2] += util.ROTR32(temp, 24)

            temp = (ctx.fingerprint[7] & 0xff000000) | 
                   (ctx.fingerprint[6] & 0x00ff0000) | 
                   (ctx.fingerprint[5] & 0x0000ff00) | 
                   (ctx.fingerprint[4] & 0x000000ff)
            ctx.fingerprint[3] += temp
        case 160:
            temp = (ctx.fingerprint[7] & u32(0x3f)) | 
                   (ctx.fingerprint[6] & u32(0x7f << 25)) |  
                   (ctx.fingerprint[5] & u32(0x3f << 19))
            ctx.fingerprint[0] += util.ROTR32(temp, 19)

            temp = (ctx.fingerprint[7] & u32(0x3f <<  6)) | 
                   (ctx.fingerprint[6] & u32(0x3f)) |  
                   (ctx.fingerprint[5] & u32(0x7f << 25))
            ctx.fingerprint[1] += util.ROTR32(temp, 25)

            temp = (ctx.fingerprint[7] & u32(0x7f << 12)) | 
                   (ctx.fingerprint[6] & u32(0x3f <<  6)) |  
                   (ctx.fingerprint[5] & u32(0x3f))
            ctx.fingerprint[2] += temp

            temp = (ctx.fingerprint[7] & u32(0x3f << 19)) | 
                   (ctx.fingerprint[6] & u32(0x7f << 12)) |  
                   (ctx.fingerprint[5] & u32(0x3f <<  6))
            ctx.fingerprint[3] += temp >> 6

            temp = (ctx.fingerprint[7] & u32(0x7f << 25)) | 
                   (ctx.fingerprint[6] & u32(0x3f << 19)) |  
                   (ctx.fingerprint[5] & u32(0x7f << 12))
            ctx.fingerprint[4] += temp >> 12
        case 192:
            temp = (ctx.fingerprint[7] & u32(0x1f)) | 
                   (ctx.fingerprint[6] & u32(0x3f << 26))
            ctx.fingerprint[0] += util.ROTR32(temp, 26)

            temp = (ctx.fingerprint[7] & u32(0x1f <<  5)) | 
                   (ctx.fingerprint[6] & u32(0x1f))
            ctx.fingerprint[1] += temp

            temp = (ctx.fingerprint[7] & u32(0x3f << 10)) | 
                   (ctx.fingerprint[6] & u32(0x1f <<  5))
            ctx.fingerprint[2] += temp >> 5

            temp = (ctx.fingerprint[7] & u32(0x1f << 16)) | 
                   (ctx.fingerprint[6] & u32(0x3f << 10))
            ctx.fingerprint[3] += temp >> 10

            temp = (ctx.fingerprint[7] & u32(0x1f << 21)) | 
                   (ctx.fingerprint[6] & u32(0x1f << 16))
            ctx.fingerprint[4] += temp >> 16

            temp = (ctx.fingerprint[7] & u32(0x3f << 26)) | 
                   (ctx.fingerprint[6] & u32(0x1f << 21))
            ctx.fingerprint[5] += temp >> 21
        case 224:
            ctx.fingerprint[0] += (ctx.fingerprint[7] >> 27) & 0x1f
            ctx.fingerprint[1] += (ctx.fingerprint[7] >> 22) & 0x1f
            ctx.fingerprint[2] += (ctx.fingerprint[7] >> 18) & 0x0f
            ctx.fingerprint[3] += (ctx.fingerprint[7] >> 13) & 0x1f
            ctx.fingerprint[4] += (ctx.fingerprint[7] >>  9) & 0x0f
            ctx.fingerprint[5] += (ctx.fingerprint[7] >>  4) & 0x1f
            ctx.fingerprint[6] +=  ctx.fingerprint[7]        & 0x0f                
    }
}
