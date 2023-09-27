package _sha3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the Keccak hashing algorithm, standardized as SHA3 in <https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf>
    To use the original Keccak padding, set the is_keccak bool to true, otherwise it will use SHA3 padding.
*/

import "../util"

ROUNDS :: 24

Sha3_Context :: struct {
    st: struct #raw_union {
        b: [200]u8,
        q: [25]u64,
    },
    pt:        int,
    rsiz:      int,
    mdlen:     int,
    is_keccak: bool,
}

keccakf :: proc "contextless" (st: ^[25]u64) {
    keccakf_rndc := [?]u64 {
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
        0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
        0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
        0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
        0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
        0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
        0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
    }

    keccakf_rotc := [?]i32 {
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44,
    }

    keccakf_piln := [?]i32 {
        10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1,
    }

    i, j, r: i32 = ---, ---, ---
    t: u64       = ---
    bc: [5]u64   = ---

    when ODIN_ENDIAN != .Little {
        v: uintptr = ---
        for i = 0; i < 25; i += 1 {
            v := uintptr(&st[i])
            st[i] = u64((^u8)(v + 0)^ << 0)  | u64((^u8)(v + 1)^ << 8)  |
                    u64((^u8)(v + 2)^ << 16) | u64((^u8)(v + 3)^ << 24) |
                    u64((^u8)(v + 4)^ << 32) | u64((^u8)(v + 5)^ << 40) |
                    u64((^u8)(v + 6)^ << 48) | u64((^u8)(v + 7)^ << 56)
        }
    }

    for r = 0; r < ROUNDS; r += 1 {
        // theta
        for i = 0; i < 5; i += 1 {
            bc[i] = st[i] ~ st[i + 5] ~ st[i + 10] ~ st[i + 15] ~ st[i + 20]
        }

        for i = 0; i < 5; i += 1 {
            t = bc[(i + 4) % 5] ~ util.ROTL64(bc[(i + 1) % 5], 1)
            for j = 0; j < 25; j += 5 {
                st[j + i] ~= t
            }
        }

        // rho pi
        t = st[1]
        for i = 0; i < 24; i += 1 {
            j = keccakf_piln[i]
            bc[0] = st[j]
            st[j] = util.ROTL64(t, u64(keccakf_rotc[i]))
            t = bc[0]
        }

        // chi
        for j = 0; j < 25; j += 5 {
            for i = 0; i < 5; i += 1 {
                bc[i] = st[j + i]
            }
            for i = 0; i < 5; i += 1 {
                st[j + i] ~= ~bc[(i + 1) % 5] & bc[(i + 2) % 5]
            }
        }

        st[0] ~= keccakf_rndc[r]
    }

    when ODIN_ENDIAN != .Little {
        for i = 0; i < 25; i += 1 {
            v = uintptr(&st[i])
            t = st[i]
            (^u8)(v + 0)^ = (t >> 0)  & 0xff
            (^u8)(v + 1)^ = (t >> 8)  & 0xff
            (^u8)(v + 2)^ = (t >> 16) & 0xff
            (^u8)(v + 3)^ = (t >> 24) & 0xff
            (^u8)(v + 4)^ = (t >> 32) & 0xff
            (^u8)(v + 5)^ = (t >> 40) & 0xff
            (^u8)(v + 6)^ = (t >> 48) & 0xff
            (^u8)(v + 7)^ = (t >> 56) & 0xff
        }
    }
}

init :: proc "contextless" (c: ^Sha3_Context) {
    for i := 0; i < 25; i += 1 {
        c.st.q[i] = 0
    }
    c.rsiz = 200 - 2 * c.mdlen
}

update :: proc "contextless" (c: ^Sha3_Context, data: []byte) {
    j := c.pt
    for i := 0; i < len(data); i += 1 {
        c.st.b[j] ~= data[i]
        j += 1
        if j >= c.rsiz {
            keccakf(&c.st.q)
            j = 0
        }
    }
    c.pt = j
}

final :: proc "contextless" (c: ^Sha3_Context, hash: []byte) {
    if c.is_keccak {
        c.st.b[c.pt] ~= 0x01
    } else {
        c.st.b[c.pt] ~= 0x06
    }
    
    c.st.b[c.rsiz - 1] ~= 0x80
    keccakf(&c.st.q)
    for i := 0; i < c.mdlen; i += 1 {
        hash[i] = c.st.b[i]
    }
}

shake_xof :: proc "contextless" (c: ^Sha3_Context) {
    c.st.b[c.pt]       ~= 0x1F
    c.st.b[c.rsiz - 1] ~= 0x80
    keccakf(&c.st.q)
    c.pt = 0
}

shake_out :: proc "contextless" (c: ^Sha3_Context, hash: []byte) {
    j := c.pt
    for i := 0; i < len(hash); i += 1 {
        if j >= c.rsiz {
            keccakf(&c.st.q)
            j = 0
        }
        hash[i] = c.st.b[j]
        j += 1
    }
    c.pt = j
}
