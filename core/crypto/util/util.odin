package util

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Various utility procedures
*/

import "core:mem"
_ :: mem

// @note(bp): this can replace the other two
cast_slice :: #force_inline proc "contextless" ($D: typeid/[]$DE, src: $S/[]$SE) -> D {
    src := src
    dst := (^mem.Raw_Slice)(&src)

    when size_of(DE) < size_of(SE) {
        when size_of(DE) % size_of(SE) == 0 {
            dst.len /= size_of(SE) / size_of(DE)
        } else {
            dst.len *= size_of(SE)
            dst.len /= size_of(DE)
        }
    } else when size_of(DE) > size_of(SE) {
        when size_of(DE) % size_of(SE) == 0 {
            dst.len *= size_of(DE) / size_of(SE)
        } else {
            dst.len *= size_of(SE)
            dst.len /= size_of(DE)
        }
    } else when size_of(DE) != size_of(SE) {
        #assert(size_of(DE) % size_of(SE) == 0, "Different size detected")
        dst.len *= size_of(SE)
        dst.len /= size_of(DE)
    }

    return (^D)(dst)^
}

bytes_to_slice :: #force_inline proc "contextless" ($T: typeid/[]$E, bytes: []byte) -> T {
    s := transmute(mem.Raw_Slice)bytes
    s.len /= size_of(E)
    return transmute(T)s
}

slice_to_bytes :: #force_inline proc "contextless" (slice: $E/[]$T) -> []byte {
    s := transmute(mem.Raw_Slice)slice
    s.len *= size_of(T)
    return transmute([]byte)s
}

ROTL16 :: #force_inline proc "contextless" (a, b: u16) -> u16 {
    return ((a << b) | (a >> (16 - b)))
}

ROTR16 :: #force_inline proc "contextless" (a, b: u16) -> u16 {
    return ((a >> b) | (a << (16 - b)))
}

ROTL32 :: #force_inline proc "contextless"(a: u32, b: int) -> u32 {
    s := uint(b) & 31
    return (a << s) | (a >> (32 - s))
}

ROTR32 :: #force_inline proc "contextless" (a: u32, b: int) -> u32 {
    s := uint(b) & 31
    return (a >> s) | (a << (32 - s))
}

ROTL64 :: #force_inline proc "contextless" (a, b: u64) -> u64 {
    return ((a << b) | (a >> (64 - b)))
}

ROTR64 :: #force_inline proc "contextless" (a, b: u64) -> u64 {
    return ((a >> b) | (a << (64 - b)))
}

ROTL128 :: #force_inline proc "contextless" (a, b, c, d: ^u32, n: uint) {
    a, b, c, d := a, b, c, d
    t := a^ >> (32 - n)
    a^ = ((a^ << n) | (b^ >> (32 - n)))
    b^ = ((b^ << n) | (c^ >> (32 - n)))
    c^ = ((c^ << n) | (d^ >> (32 - n)))
    d^ = ((d^ << n) | t)
}

U32_LE :: #force_inline proc "contextless" (b: []byte) -> u32 {
    return u32(b[0]) | u32(b[1]) << 8 | u32(b[2]) << 16 | u32(b[3]) << 24
}

U64_LE :: #force_inline proc "contextless" (b: []byte) -> u64 {
    return u64(b[0])       | u64(b[1]) << 8  | u64(b[2]) << 16 | u64(b[3]) << 24 |
           u64(b[4]) << 32 | u64(b[5]) << 40 | u64(b[6]) << 48 | u64(b[7]) << 56
}

U64_BE :: #force_inline proc "contextless" (b: []byte) -> u64 {
    return u64(b[7])       | u64(b[6]) << 8  | u64(b[5]) << 16 | u64(b[4]) << 24 |
           u64(b[3]) << 32 | u64(b[2]) << 40 | u64(b[1]) << 48 | u64(b[0]) << 56
}

PUT_U64_LE :: #force_inline proc "contextless" (b: []byte, v: u64) {
    b[0] = byte(v)
    b[1] = byte(v >> 8)
    b[2] = byte(v >> 16)
    b[3] = byte(v >> 24)
    b[4] = byte(v >> 32)
    b[5] = byte(v >> 40)
    b[6] = byte(v >> 48)
    b[7] = byte(v >> 56)
}

PUT_U32_LE :: #force_inline proc "contextless" (b: []byte, v: u32) {
    b[0] = byte(v)
    b[1] = byte(v >> 8)
    b[2] = byte(v >> 16)
    b[3] = byte(v >> 24)
}

PUT_U32_BE :: #force_inline proc "contextless" (b: []byte, v: u32) {
    b[0] = byte(v >> 24)
    b[1] = byte(v >> 16)
    b[2] = byte(v >> 8)
    b[3] = byte(v)
}

PUT_U64_BE :: #force_inline proc "contextless" (b: []byte, v: u64) {
    b[0] = byte(v >> 56)
    b[1] = byte(v >> 48)
    b[2] = byte(v >> 40)
    b[3] = byte(v >> 32)
    b[4] = byte(v >> 24)
    b[5] = byte(v >> 16)
    b[6] = byte(v >> 8)
    b[7] = byte(v)
}

XOR_BUF :: #force_inline proc "contextless" (input, output: []byte) {
    for i := 0; i < len(input); i += 1 {
        output[i] ~= input[i]
    }
}
