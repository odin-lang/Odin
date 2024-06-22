package uuid

import "core:crypto/legacy/md5"
import "core:crypto/legacy/sha1"
import "core:math/rand"
import "core:mem"
import "core:time"

/*
Generate a version 1 UUID.

Inputs:
- clock_seq: The clock sequence, a number which must be initialized to a random number once in the lifetime of a system.
- node: An optional 48-bit spatially unique identifier, specified to be the IEEE 802 address of the system.
  If one is not provided or available, 48 bits of random state will take its place.

Returns:
- result: The generated UUID.
*/
generate_v1 :: proc(clock_seq: u16, node: Maybe([6]u8) = nil) -> (result: Identifier) {
	assert(clock_seq <= 0x3FFF, "The clock sequence can only hold 14 bits of data; no number greater than 16,383.")
	unix_time_in_hns_intervals := time.to_unix_nanoseconds(time.now()) / 100
	timestamp := cast(u64le)(HNS_INTERVALS_BETWEEN_GREG_AND_UNIX + unix_time_in_hns_intervals)
	timestamp_octets := transmute([8]u8)timestamp

	result[0] = timestamp_octets[0]
	result[1] = timestamp_octets[1]
	result[2] = timestamp_octets[2]
	result[3] = timestamp_octets[3]
	result[4] = timestamp_octets[4]
	result[5] = timestamp_octets[5]

	result[6] = timestamp_octets[6] >> 4
	result[7] = timestamp_octets[6] << 4 | timestamp_octets[7]

	if realized_node, ok := node.?; ok {
		mutable_node := realized_node
		mem.copy_non_overlapping(&result[10], &mutable_node[0], 6)
	} else {
		bytes_generated := rand.read(result[10:])
		assert(bytes_generated == 6, "RNG failed to generate 6 bytes for UUID v1.")
	}

	result[VERSION_BYTE_INDEX] |= 0x10
	result[VARIANT_BYTE_INDEX] |= 0x80

	result[8] |= cast(u8)(clock_seq & 0x3F00 >> 8)
	result[9]  = cast(u8)clock_seq

	return
}

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
Generate a version 6 UUID.

Inputs:
- clock_seq: The clock sequence from version 1, now made optional.
  If unspecified, it will be replaced with random bits.
- node: An optional 48-bit spatially unique identifier, specified to be the IEEE 802 address of the system.
  If one is not provided or available, 48 bits of random state will take its place.

Returns:
- result: The generated UUID.
*/
generate_v6 :: proc(clock_seq: Maybe(u16) = nil, node: Maybe([6]u8) = nil) -> (result: Identifier) {
	unix_time_in_hns_intervals := time.to_unix_nanoseconds(time.now()) / 100

	timestamp := cast(u128be)(HNS_INTERVALS_BETWEEN_GREG_AND_UNIX + unix_time_in_hns_intervals)

	result |= transmute(Identifier)(timestamp & 0x0FFFFFFF_FFFFF000 << 68)
	result |= transmute(Identifier)(timestamp & 0x00000000_00000FFF << 64)

	if realized_clock_seq, ok := clock_seq.?; ok {
		assert(realized_clock_seq <= 0x3FFF, "The clock sequence can only hold 14 bits of data, therefore no number greater than 16,383.")
		result[8] |= cast(u8)(realized_clock_seq & 0x3F00 >> 8)
		result[9]  = cast(u8)realized_clock_seq
	} else {
		temporary: [2]u8
		bytes_generated := rand.read(temporary[:])
		assert(bytes_generated == 2, "RNG failed to generate 2 bytes for UUID v1.")
		result[8] |= cast(u8)temporary[0] & 0x3F
		result[9]  = cast(u8)temporary[1]
	}

	if realized_node, ok := node.?; ok {
		mutable_node := realized_node
		mem.copy_non_overlapping(&result[10], &mutable_node[0], 6)
	} else {
		bytes_generated := rand.read(result[10:])
		assert(bytes_generated == 6, "RNG failed to generate 6 bytes for UUID v1.")
	}

	result[VERSION_BYTE_INDEX] |= 0x60
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
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
