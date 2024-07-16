package crypto_hash

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "core:io"
import "core:mem"
import "core:os"

// hash_bytes will hash the given input and return the computed digest
// in a newly allocated slice.
hash_string :: proc(algorithm: Algorithm, data: string, allocator := context.allocator) -> []byte {
	return hash_bytes(algorithm, transmute([]byte)(data), allocator)
}

// hash_bytes will hash the given input and return the computed digest
// in a newly allocated slice.
hash_bytes :: proc(algorithm: Algorithm, data: []byte, allocator := context.allocator) -> []byte {
	dst := make([]byte, DIGEST_SIZES[algorithm], allocator)
	hash_bytes_to_buffer(algorithm, data, dst)
	return dst
}

// hash_string_to_buffer will hash the given input and assign the
// computed digest to the third parameter.  It requires that the
// destination buffer is at least as big as the digest size.  The
// provided destination buffer is returned to match the behavior of
// `hash_string`.
hash_string_to_buffer :: proc(algorithm: Algorithm, data: string, hash: []byte) -> []byte {
	return hash_bytes_to_buffer(algorithm, transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer will hash the given input and write the
// computed digest into the third parameter.  It requires that the
// destination buffer is at least as big as the digest size.  The
// provided destination buffer is returned to match the behavior of
// `hash_bytes`.
hash_bytes_to_buffer :: proc(algorithm: Algorithm, data, hash: []byte) -> []byte {
	ctx: Context

	init(&ctx, algorithm)
	update(&ctx, data)
	final(&ctx, hash)

	return hash
}

// hash_stream will incrementally fully consume a stream, and return the
// computed digest in a newly allocated slice.
hash_stream :: proc(
	algorithm: Algorithm,
	s: io.Stream,
	allocator := context.allocator,
) -> (
	[]byte,
	io.Error,
) {
	ctx: Context

	buf: [MAX_BLOCK_SIZE * 4]byte
	defer mem.zero_explicit(&buf, size_of(buf))

	init(&ctx, algorithm)

	loop: for {
		n, err := io.read(s, buf[:])
		if n > 0 {
			// XXX/yawning: Can io.read return n > 0 and EOF?
			update(&ctx, buf[:n])
		}
		#partial switch err {
		case .None:
		case .EOF:
			break loop
		case:
			return nil, err
		}
	}

	dst := make([]byte, DIGEST_SIZES[algorithm], allocator)
	final(&ctx, dst)

	return dst, io.Error.None
}

// hash_file will read the file provided by the given handle and return the
// computed digest in a newly allocated slice.
hash_file :: proc(
	algorithm: Algorithm,
	hd: os.Handle,
	load_at_once := false,
	allocator := context.allocator,
) -> (
	[]byte,
	io.Error,
) {
	if !load_at_once {
		return hash_stream(algorithm, os.stream_from_handle(hd), allocator)
	}

	buf, ok := os.read_entire_file(hd, allocator)
	if !ok {
		return nil, io.Error.Unknown
	}
	defer delete(buf, allocator)

	return hash_bytes(algorithm, buf, allocator), io.Error.None
}

hash :: proc {
	hash_stream,
	hash_file,
	hash_bytes,
	hash_string,
	hash_bytes_to_buffer,
	hash_string_to_buffer,
}
