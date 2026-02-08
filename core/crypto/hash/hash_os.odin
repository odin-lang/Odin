#+build !freestanding
#+build !js
package crypto_hash

import "core:io"
import os "core:os/os2"

// `hash_file` will read the file provided by the given handle and return the
// computed digest in a newly allocated slice.
hash_file_by_handle :: proc(
	algorithm:      Algorithm,
	handle:         ^os.File,
	load_at_once := false,
	allocator    := context.allocator,
) -> (
	[]byte,
	io.Error,
) {
	if !load_at_once {
		return hash_stream(algorithm, os.to_stream(handle), allocator)
	}

	buf, err := os.read_entire_file(handle, allocator)
	if err != nil {
		return nil, io.Error.Unknown
	}
	defer delete(buf, allocator)

	return hash_bytes(algorithm, buf, allocator), io.Error.None
}

hash_file_by_name :: proc(
	algorithm:      Algorithm,
	filename:       string,
	load_at_once := false,
	allocator    := context.allocator,
) -> (
	[]byte,
	io.Error,
) {
	handle, err := os.open(filename)
	defer os.close(handle)

	if err != nil {
		return {}, io.Error.Unknown
	}
	return hash_file_by_handle(algorithm, handle, load_at_once, allocator)
}


hash :: proc {
	hash_stream,
	hash_file_by_handle,
	hash_bytes,
	hash_string,
	hash_bytes_to_buffer,
	hash_string_to_buffer,
}