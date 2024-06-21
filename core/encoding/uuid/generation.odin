package uuid

import "core:crypto/legacy/md5"
import "core:crypto/legacy/sha1"
import "core:math/rand"
import "core:mem"
import "core:time"

/*
Generate a version 3 UUID.

This UUID is generated from a name within a namespace.
MD5 is used to hash the name with the namespace to produce the UUID.

Inputs:
- namespace: Another `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The byte slice used to generate the name on top of the namespace.

Returns:
- result: The generated UUID.
*/
generate_v3_bytes :: proc(
	namespace: Identifier,
	name: []byte,
) -> (
	result: Identifier,
) {
	namespace := namespace

	ctx: md5.Context
	md5.init(&ctx)
	md5.update(&ctx, namespace[:])
	md5.update(&ctx, name)
	md5.final(&ctx, result[:])

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x30

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 3 UUID.

This UUID is generated from a name within a namespace.
MD5 is used to hash the name with the namespace to produce the UUID.

Inputs:
- namespace: Another `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The string used to generate the name on top of the namespace.

Returns:
- result: The generated UUID.
*/
generate_v3_string :: proc(
	namespace: Identifier,
	name: string,
) -> (
	result: Identifier,
) {
	return generate_v3_bytes(namespace, transmute([]byte)name)
}

generate_v3 :: proc {
	generate_v3_bytes,
	generate_v3_string,
}

/*
Generate a version 4 UUID.

This UUID will be pseudorandom, save for 6 pre-determined version and variant bits.

Returns:
- result: The generated UUID.
*/
generate_v4 :: proc() -> (result: Identifier) {
	bytes_generated := rand.read(result[:])
	assert(bytes_generated == 16, "RNG failed to generate 16 bytes for UUID v4.")

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x40

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 5 UUID.

This UUID is generated from a name within a namespace.
SHA1 is used to hash the name with the namespace to produce the UUID.

Inputs:
- namespace: Another `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The byte slice used to generate the name on top of the namespace.

Returns:
- result: The generated UUID.
*/
generate_v5_bytes :: proc(
	namespace: Identifier,
	name: []byte,
) -> (
	result: Identifier,
) {
	namespace := namespace
	digest: [sha1.DIGEST_SIZE]byte

	ctx: sha1.Context
	sha1.init(&ctx)
	sha1.update(&ctx, namespace[:])
	sha1.update(&ctx, name)
	sha1.final(&ctx, digest[:])

	mem.copy_non_overlapping(&result, &digest, 16)

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x50

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 5 UUID.

This UUID is generated from a name within a namespace.
SHA1 is used to hash the name with the namespace to produce the UUID.

Inputs:
- namespace: Another `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The string used to generate the name on top of the namespace.

Returns:
- result: The generated UUID.
*/
generate_v5_string :: proc(
	namespace: Identifier,
	name: string,
) -> (
	result: Identifier,
) {
	return generate_v5_bytes(namespace, transmute([]byte)name)
}

generate_v5 :: proc {
	generate_v5_bytes,
	generate_v5_string,
}

/*
Generate a version 7 UUID.

This UUID will be pseudorandom, save for 6 pre-determined version and variant
bits and a 48 bit timestamp.

It is designed with time-based sorting in mind, such as for database usage, as
the highest bits are allocated from the timestamp of when it is created.

Returns:
- result: The generated UUID.
*/
generate_v7 :: proc() -> (result: Identifier) {
	unix_time_in_milliseconds := time.to_unix_nanoseconds(time.now()) / 1e6

	temporary := cast(u128be)unix_time_in_milliseconds << VERSION_7_TIME_SHIFT

	bytes_generated := rand.read(result[6:])
	assert(bytes_generated == 10, "RNG failed to generate 10 bytes for UUID v7.")

	result |= transmute(Identifier)temporary

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x70

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 7 UUID with an incremented counter.

This UUID will be pseudorandom, save for 6 pre-determined version and variant
bits, a 48 bit timestamp, and 12 bits of counter state.

It is designed with time-based sorting in mind, such as for database usage, as
the highest bits are allocated from the timestamp of when it is created.

This procedure is preferable if you are generating hundreds or thousands of
UUIDs as a batch within the span of a millisecond. Do note that the counter
only has 12 bits of state, thus `counter` cannot exceed the number 4,095.

Example:

	import "core:uuid"

	// Create a batch of UUIDs all at once.
	batch: [dynamic]uuid.Identifier

	for i: u16 = 0; i < 1000; i += 1 {
		my_uuid := uuid.generate_v7_counter(i)
		append(&batch, my_uuid)
	}

Inputs:
- counter: A 12-bit value, incremented each time a UUID is generated in a batch.

Returns:
- result: The generated UUID.
*/
generate_v7_counter :: proc(counter: u16) -> (result: Identifier) {
	assert(counter <= 0x0fff, "This implementation of the version 7 UUID does not support counters in excess of 12 bits (4,095).")
	unix_time_in_milliseconds := time.to_unix_nanoseconds(time.now()) / 1e6

	temporary := cast(u128be)unix_time_in_milliseconds << VERSION_7_TIME_SHIFT
	temporary |= cast(u128be)counter << VERSION_7_COUNTER_SHIFT

	bytes_generated := rand.read(result[8:])
	assert(bytes_generated == 8, "RNG failed to generate 8 bytes for UUID v7.")

	result |= transmute(Identifier)temporary

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x70

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}
