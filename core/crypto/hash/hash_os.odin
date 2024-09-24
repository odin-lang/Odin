#+build !freestanding
package crypto_hash

import "core:io"
import "core:os"

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
