package md2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the MD2 hashing algorithm, as defined in RFC 1319 <https://datatracker.ietf.org/doc/html/rfc1319>
*/

import "core:os"
import "core:io"

/*
    High level API
*/

DIGEST_SIZE :: 16

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [DIGEST_SIZE]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [DIGEST_SIZE]byte {
	hash: [DIGEST_SIZE]byte
	ctx: Md2_Context
    // init(&ctx) No-op
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer :: proc(data: string, hash: []byte) {
	hash_bytes_to_buffer(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer :: proc(data, hash: []byte) {
	assert(len(hash) >= DIGEST_SIZE, "Size of destination buffer is smaller than the digest size")
    ctx: Md2_Context
    // init(&ctx) No-op
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([DIGEST_SIZE]byte, bool) {
	hash: [DIGEST_SIZE]byte
	ctx: Md2_Context
	// init(&ctx) No-op
	buf := make([]byte, 512)
	defer delete(buf)
	read := 1
	for read > 0 {
	    read, _ = s->impl_read(buf)
	    if read > 0 {
			update(&ctx, buf[:read])
	    } 
	}
	final(&ctx, hash[:])
	return hash, true
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE]byte, bool) {
	if !load_at_once {
        return hash_stream(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes(buf[:]), ok
        }
    }
    return [DIGEST_SIZE]byte{}, false
}

hash :: proc {
    hash_stream,
    hash_file,
    hash_bytes,
    hash_string,
    hash_bytes_to_buffer,
    hash_string_to_buffer,
}

/*
    Low level API
*/

@(warning="Init is a no-op for MD2")
init :: proc(ctx: ^Md2_Context) {
	// No action needed here
}

update :: proc(ctx: ^Md2_Context, data: []byte) {
	for i := 0; i < len(data); i += 1 {
		ctx.data[ctx.datalen] = data[i]
		ctx.datalen += 1
		if (ctx.datalen == DIGEST_SIZE) {
			transform(ctx, ctx.data[:])
			ctx.datalen = 0
		}
	}
}

final :: proc(ctx: ^Md2_Context, hash: []byte) {
	to_pad := byte(DIGEST_SIZE - ctx.datalen)
    for ctx.datalen < DIGEST_SIZE {
        ctx.data[ctx.datalen] = to_pad
		ctx.datalen += 1
    }
	transform(ctx, ctx.data[:])
	transform(ctx, ctx.checksum[:])
    for i := 0; i < DIGEST_SIZE; i += 1 {
        hash[i] = ctx.state[i]
    }
}

/*
    MD2 implementation
*/

Md2_Context :: struct {
    data:     [DIGEST_SIZE]byte,
    state:    [DIGEST_SIZE * 3]byte,
    checksum: [DIGEST_SIZE]byte,
    datalen:  int,
}

PI_TABLE := [?]byte {
	41,  46,  67,  201, 162, 216, 124, 1,   61,  54,  84,  161, 236, 240, 6,
	19,  98,  167, 5,   243, 192, 199, 115, 140, 152, 147, 43,  217, 188, 76,
	130, 202, 30,  155, 87,  60,  253, 212, 224, 22,  103, 66,  111, 24,  138, 
	23,  229, 18,  190, 78,  196, 214, 218, 158, 222, 73,  160, 251, 245, 142,
	187, 47,  238, 122, 169, 104, 121, 145, 21,  178, 7,   63,  148, 194, 16,
	137, 11,  34,  95,  33,  128, 127, 93,  154, 90,  144, 50,  39,  53,  62, 
	204, 231, 191, 247, 151, 3,   255, 25,  48,  179, 72,  165, 181, 209, 215,
	94,  146, 42,  172, 86,  170, 198, 79,  184, 56,  210, 150, 164, 125, 182,
	118, 252, 107, 226, 156, 116, 4,   241, 69,  157, 112, 89,  100, 113, 135,
	32,  134, 91,  207, 101, 230, 45,  168, 2,   27,  96,  37,  173, 174, 176,
	185, 246, 28,  70,  97,  105, 52,  64,  126, 15,  85,  71,  163, 35,  221,
	81,  175, 58,  195, 92,  249, 206, 186, 197, 234, 38,  44,  83,  13,  110,
	133, 40,  132, 9,   211, 223, 205, 244, 65,  129, 77,  82,  106, 220, 55,
	200, 108, 193, 171, 250, 36,  225, 123, 8,   12,  189, 177, 74,  120, 136,
	149, 139, 227, 99,  232, 109, 233, 203, 213, 254, 59,  0,   29,  57,  242,
	239, 183, 14,  102, 88,  208, 228, 166, 119, 114, 248, 235, 117, 75,  10,
	49,  68,  80,  180, 143, 237, 31,  26,  219, 153, 141, 51,  159, 17,  131,
	20,
}

transform :: proc(ctx: ^Md2_Context, data: []byte) {
    j,k,t: byte
	for j = 0; j < DIGEST_SIZE; j += 1 {
		ctx.state[j + DIGEST_SIZE] = data[j]
		ctx.state[j + DIGEST_SIZE * 2] = (ctx.state[j + DIGEST_SIZE] ~ ctx.state[j])
	}
	t = 0
	for j = 0; j < DIGEST_SIZE + 2; j += 1 {
		for k = 0; k < DIGEST_SIZE * 3; k += 1 {
			ctx.state[k] ~= PI_TABLE[t]
			t = ctx.state[k]
		}
		t = (t + j) & 0xff
	}
	t = ctx.checksum[DIGEST_SIZE - 1]
	for j = 0; j < DIGEST_SIZE; j += 1 {
		ctx.checksum[j] ~= PI_TABLE[data[j] ~ t]
		t = ctx.checksum[j]
	}
}
