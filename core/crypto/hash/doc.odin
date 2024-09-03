/*
package hash provides a generic interface to the supported hash algorithms.

A high-level convenience procedure group `hash` is provided to easily
accomplish common tasks.
- `hash_string` - Hash a given string and return the digest.
- `hash_bytes` - Hash a given byte slice and return the digest.
- `hash_string_to_buffer` - Hash a given string and put the digest in
  the third parameter.  It requires that the destination buffer
  is at least as big as the digest size.
- `hash_bytes_to_buffer` - Hash a given string and put the computed
  digest in the third parameter.  It requires that the destination
  buffer is at least as big as the digest size.
- `hash_stream` - Incrementally fully consume a `io.Stream`, and return
  the computed digest.
- `hash_file` - Takes a file handle and returns the computed digest.
  A third optional boolean parameter controls if the file is streamed
  (default), or or read at once.

Example:
	package hash_example

	import "core:crypto/hash"

	main :: proc() {
		input := "Feed the fire."

		// Compute the digest, using the high level API.
		returned_digest := hash.hash(hash.Algorithm.SHA512_256, input)
		defer delete(returned_digest)

		// Variant that takes a destination buffer, instead of returning
		// the digest.
		digest := make([]byte, hash.DIGEST_SIZES[hash.Algorithm.BLAKE2B]) // @note: Destination buffer has to be at least as big as the digest size of the hash.
		defer delete(digest)
		hash.hash(hash.Algorithm.BLAKE2B, input, digest)
	}

A generic low level API is provided supporting the init/update/final interface
that is typical with cryptographic hash function implementations.

Example:
	package hash_example

	import "core:crypto/hash"

	main :: proc() {
		input := "Let the cinders burn."

		// Compute the digest, using the low level API.
		ctx: hash.Context
		digest := make([]byte, hash.DIGEST_SIZES[hash.Algorithm.SHA3_512])
		defer delete(digest)

		hash.init(&ctx, hash.Algorithm.SHA3_512)
		hash.update(&ctx, transmute([]byte)input)
		hash.final(&ctx, digest)
	}
*/
package crypto_hash
